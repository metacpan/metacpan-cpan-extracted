package HTTPD::ADS;
use strict;
use warnings;
use vars qw ($VERSION @ISA );
$VERSION     = 0.8;
use base qw/ Class::Constructor Class::Accessor /;
use HTTPD::ADS::DBI;
use HTTPD::ADS::Times;		#time-related subroutines
use CLASS;
use CGI::Carp qw(cluck  carpout);
use IO::Socket::UNIX;
use HTTP::Date qw/str2time time2isoz/ ;

use constant MAX_REQUEST_STRING_LENGTH =>64;
use constant MAX_REQUEST_STRING_COLUMN => 63;

BEGIN {
  #this is supposed to have been done by use base...
  use vars qw ( @ISA);
  require Class::Accessor;
  require Class::Constructor;
  push @ISA, 'Class::Accessor','Class::Constructor';
}
########################################### main pod documentation begin ##
# Below is the documentation for this module.


=head1 NAME

HTTPD::ADS - Perl module for Abuse Detection and Prevention System 

=head1 SYNOPSIS

    use HTTPD::ADS



=head1 DESCRIPTION

    Abuse Detection System


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Dana Hudes
    CPAN ID: DHUDES
    dhudes@hudes.org
  http://www.hudes.org

=head1 COPYRIGHT

    This program is free software licensed under the...

    The General Public License (GPL)
    Version 2, June 1991

    The full text of the license can be found in the
    LICENSE file included with this module.


=head1 SEE ALSO

    perl(1).

=cut

############################################# main pod documentation end ##

my @Accessors = qw (
			IDSDatabase
			IDSDataUser
			IDSDataPassword
			IDSEventsThresholdLevel
			IDSTimeWindowSize
			normalizedIDSTimeWindowSize
			msgQ

			);
CLASS->mk_accessors(@Accessors);
CLASS->mk_constructor(
                      Name => 'new',
                      Auto_Init => \@Accessors,
                      Init_Methods => '_init',
		      Disable_Case_Mangling => 1
		     );
################################################ subroutine header begin ##

=head2 _init

    Usage     : private function 
    Purpose   : for initializing the object
    Returns   : nothing direct, normalizedIDSTimeWindowSize by side effect
    Argument  : IDSTimeWindowSize, ISDEventThresholdLevel
    Throws    : nothing
    Comments: called by mk_constructor 


    See Also   :

=cut

################################################## subroutine header end ##
use Date::Calc qw(Normalize_DHMS);
sub _init {
  #_init sets up the db connection and prepares the SQL we'll need for insert and retrieve
  my $self = shift;


  $self->IDSTimeWindowSize(defined $self->IDSTimeWindowSize? -$self->IDSTimeWindowSize: -300);
  $self->IDSEventsThresholdLevel(10) unless defined $self->IDSEventsThresholdLevel;
  $self->normalizedIDSTimeWindowSize( \[0,0,Normalize_DHMS(0,0,0,$self->IDSTimeWindowSize)] );


}


use HTTPD::ADS::AbuseNotify;
################################################ subroutine header begin ##

=head2 event_recorder

    Usage     : $ads->event_recorder(%args}
    Purpose   : for recording an event and dispatching based on status code
    Returns   : nothing direct, lots of side effects such as on the database
    Argument  : time,ip,username, request_string, status code
    Throws    : die if parameters missing/invalid
    Comments:  main entry for driving the ADS 


    See Also   :

=cut

################################################## subroutine header end ##
my  %switch = ( 401 => \&HTTPD::ADS::analyze401);
sub event_recorder {
  # put the status, ip address and time into database. If time isn't supplied, use the postgresql now() function
  #If the status is 401, see if we should blacklist this ip address unless it is whitelisted
  my $self=shift;
  my %args=@_;
  my ($eventrecord,$hostentry,$arg_string,$username,$request_string,$whitelist_entry);
  my $max_request_length=64; #not max column number, which is one less 

   

  $args{time}=(defined $args{time}? time2isoz( str2time($args{time})  ):  $self->gmttimestamp );
  my $ip = $args{ip} || confess "no ip address supplied";
  confess "no status supplied" unless defined $args{status};
  my @ipaddr = split /\s+/,$ip,2; #sometimes another field gets stuck on, get rid of it.;
  $ip = $ipaddr[0];
  $args{ip}=$ip;
  $whitelist_entry = HTTPD::ADS::Whitelist->retrieve($ip);
  if (!$whitelist_entry) {
    substr($args{request},MAX_REQUEST_STRING_COLUMN)='' if ((length $args{request})  > MAX_REQUEST_STRING_LENGTH); #a clever way to trim to maximum length	
    $hostentry= HTTPD::ADS::Hosts->find_or_create(ip => $ip);
    #      $arg_string = '-' unless (defined $args{arg_string});
    #     $arg_string = HTTPD::ADS::Arg_strings->find_or_create({arg_string => $args{arg_string}});

    $request_string = HTTPD::ADS::Request_strings->cached_find_or_create({request_string =>$args{request}});
    $username = HTTPD::ADS::Usernames->cached_find_or_create({username => $args{user}});
    $eventrecord = HTTPD::ADS::Eventrecords->create(
						    {
						     ts =>$args{time},
						     ip=> $ip,
						     status => $args{status},
						     userid => $username->userid,
						     requestid => $request_string->requestid,
						     #					     argid => $arg_string->argid

						    }
						   );
    my $handler = $switch{$args{status}};
    &$handler($self, \%args) if defined $handler;#there's gotta be a 'right' way to make this a method call...
  } else {
    use Sys::Syslog;
    my $program = $ARGV[0];
    openlog("$program $$",'pid','local6');
    syslog('warning',"%s event received for whitelisted host %s",$args{status},$args{ip});
    closelog;
  }
}
use HTTPD::ADS::OpenProxyDetector;

sub analyze401 {
  my ($self,$args) = @_;
  #Class::DBI::AbstractSearch format which is to say SQL::AbstractSearch  WHERE   my $eventcount;
  my $open_proxy_test;
  my $proxyrecord;
  my $ip =  $$args{ip};
  my $eventcount =HTTPD::ADS::Eventrecords->count_errors($ip,$self->pgtimewindow);
  if ($eventcount  == 4) {
    my $notify;
    $proxyrecord = HTTPD::ADS::proxy_tested->find_or_create(ip =>$ip);
    unless ($proxyrecord->open_proxy eq 't' || $proxyrecord->open_proxy_tested_at )
      {	  #come back later, think about a time window for retesting...
	$open_proxy_test = HTTPD::ADS::OpenProxyDetector->new($ip);
	print "proxy test for $ip returns ".$open_proxy_test->code."\n";
	$proxyrecord->set(open_proxy =>($open_proxy_test->guilty? 't':'f'), open_proxy_tested_at => gmttimestamp, proxy_test_result => $open_proxy_test-> code);
	$proxyrecord->update;
	$notify = HTTPD::ADS::AbuseNotify->new(ip => $ip,type =>'PROXY') if $open_proxy_test->guilty;
      }
    $self->blacklist(
		     ip=>$ip, first_event => $self->first_eventid($ip),block_reason => 401 
		    )
      if ( $proxyrecord->open_proxy eq 't');
  }

  $self->blacklist(
		   ip=>$ip, first_event => $self->first_eventid($ip),block_reason => 401 
		  )
    if ($eventcount >= $self->IDSEventsThresholdLevel);
}
{
  my %blocked_list;
  sub blacklist {
    my ($self,%args) = @_;
    unless ($blocked_list{$args{ip}}++ > 0) {
      my $fifo = "/tmp/BlackList";
      my $Blacklisted;
      die "socket file $fifo present and I can't write to it" unless(-w $fifo) ;
      my $sock = IO::Socket::UNIX->new(Peer => $fifo) or confess "$!";
      $sock->print("B ".$args{ip}); #we use line-oriented i/o, its simpler...
      $args{active}=  'true';	#true...
      $args{blocked_at}=$self->gmttimestamp;	
      $Blacklisted = HTTPD::ADS::Blacklist->create(\%args) ;
    }
  }
}
sub first_eventid {
  my $self = shift @_;
  my $ip = shift @_;
  my $event= HTTPD::ADS::Eventrecords->first_error_event( $ip, $self->pgtimewindow );
  my $eventid = $event->eventid;
  return $eventid;
}




1; #this line is important and will help the module return a true value
__END__






