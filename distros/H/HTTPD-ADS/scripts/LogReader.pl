#/usr/bin/perl -wT
use 5.006;
use strict;
use warnings;
use HTTPD::ADS;
use IO::Socket::UNIX;
use HTTPD::Log::Filter;
use Compress::Zlib;

#do not run this as root, I specifically split root-privileged code into another module.
#you MUST run this as your Postgresql database username
BEGIN {
  use CGI::Carp qw(cluck  carpout);
  my $logfile="/tmp/LogReader.log";
  die "cannot open log file $logfile for write" if (-e $logfile && ! (-w $logfile));
  open(LOG, ">>$logfile") or die "carp could not open log";
  carpout(\*LOG);
}


our $VERSION = '0.02';

#daemon process waits for events to come in, then puts them in database and analyzes and takes action

my $IDSDatabase="wwwads";
my $IDSDataUser="";
my $IDSDataPassword="";
my $line;

my $gz;
my $loopcount;
my $bytesread;
my $rv;
my %args;
my $apacheids = HTTPD::ADS->new (
				 IDSDataUser => $IDSDataUser,
				 IDSDataPassword   => $IDSDataPassword,
				 IDSDatabase => $IDSDatabase,
				 IDSTimeWindowSize => 7801920
				);
my $logfilter= HTTPD::Log::Filter->new(
				       format              => 'ELF',
				       capture => [ qw(
    host
    ident
    authexclude
    date
    request
    status
    bytes
    referer
    agent
)]);

my $linenumber=0;
my $filename;

#foreach $loopcount ('33'..'86') {
#    $filename = "/var/log/httpd/inside.slavelucy.com-access_log.$loopcount.gz";
foreach $loopcount ('1'..'15') {
  $filename = "/var/log/httpd/www.maturebelles.com-access_log.$loopcount".($loopcount > 1?".gz":"");

  $gz = gzopen($filename, "rb") || die "could not open log file";
  print "$linenumber lines\n";
  print "process $filename\n ";
  for ($bytesread=$gz->gzreadline($line),$linenumber=0; $bytesread > 0; $bytesread=$gz->gzreadline($line),$linenumber++) {
    $rv=$logfilter->filter($line);
    if (!defined $rv) {
      my $time = scalar localtime;
      carp "$time: Invalid log format  in $filename at line $linenumber $!  \n";
      next ;
    }
    
    
    #1st is to put the event in the  database.
    # then can decide what to do  about it.
    # One may think access to protected page w/o specifying username is innocent. Maybe. but it could
    # be that someone trys and then failing to get in launches a brute force attack. So while blank
    # username on its own might be innocent it could be counted with failed login attempts
    # as grounds for "termination with extreme prejuidice" of some hacker
    # or blackholing his ip anyway. But you need data on which to make a decision.
    next unless ($logfilter->status >= 400 && $logfilter->status < 500);
    $apacheids->event_recorder(
			       #				   ip => gethostbyname($logfilter->host),
			       ip => $logfilter->host,
			       request => $logfilter->request,
			       status =>$logfilter->status,
			       referer =>$logfilter->referer,
			       user =>$logfilter->authexclude,
			       time =>$logfilter->date
			      );
    print "$linenumber completed\r";
  }
  ;
}


1;
__END__



=head1 AUTHOR

  Dana Hudes, E<lt>dhudes@networkengineer.bizE<gt>

=head1 SEE ALSO

  L<perl>.

=cut
