# $Id: Luka.pm,v 1.12 2006/07/17 22:02:44 toni Exp $
package Luka;
use strict;
use warnings;
use Socket;
use Sys::Syslog;
use Sys::Hostname;
use Sys::Hostname::Long;
use Luka::Mailer;
use Luka::Exceptions;
use Luka::Error;
use Luka::Conf;
use Error qw(:try);
use Data::Dumper;

push @Exception::Class::Base::ISA, 'Error'
    unless Exception::Class::Base->isa('Error'); 

use Carp;
use Exporter;
our (@ISA, @EXPORT_OK, @EXPORT, @modes, %error_str );

@ISA = qw(Exporter);
@EXPORT_OK = qw(report_error);

our $VERSION = "1.07";
our $LukaDebug = "LukaDebug";

use Class::Std; 

{
    # config definition of the script handled
    my %script_about : ATTR( :get<script_about>  :set<script_about> );

    #-----------------------------------
    # captured error/report properties
    #-----------------------------------
    my %error      : ATTR( :get<error>      :set<error> ); # error object
    my %id         : ATTR( :get<id>         :set<id> );
    my %line       : ATTR( :get<line>       :set<line> );
    my %stacktrace : ATTR( :get<stacktrace> :set<stacktrace> );
    my %text       : ATTR( :get<text>       :set<text> );    # error string
    my %severity   : ATTR( :get<severity>   :set<severity> );
    my %args       : ATTR( :get<args>       :set<args> );
    my %context    : ATTR( :get<context>    :set<context> );

    # config file location (for tests)
    my %conf       : ATTR( :get<conf>       :set<conf> );  

    # captured script properties
    my %path     : ATTR( :get<path>      :set<path> );
    my %filename : ATTR( :get<filename>  :set<filename> );

    # captured device state
    my %ipaddr          : ATTR( :get<ipaddr>           :set<ipaddr> );
    my %hostname        : ATTR( :get<hostname>         :set<hostname> );
    my %hostname_long   : ATTR( :get<hostname_long>    :set<hostname_long> );
    my %local_date_time : ATTR( :get<local_date_time>  :set<local_date_time> );
    my %syslogd         : ATTR( :get<syslogd>          :set<syslogd> );

    # captured process state
    my %pid  : ATTR( :get<pid>   :set<pid>  );
    my %uid  : ATTR( :get<uid>   :set<uid>  );
    my %euid : ATTR( :get<euid>  :set<euid> );
    my %gid  : ATTR( :get<gid>   :set<gid>  );
    my %egid : ATTR( :get<egid>  :set<egid> );

    # global config options
    my %doc_base : ATTR( :get<doc_base> :set<doc_base> );
    my %debug    : ATTR( :get<debug>    :set<debug> );
    my %nomail   : ATTR( :get<nomail>   :set<nomail> );
    my %state_code_error           : ATTR( :get<state_code_error>           :set<state_code_error> );
    my %state_code_success         : ATTR( :get<state_code_success>         :set<state_code_success> );
    my %default_state_code_error   : ATTR( :get<default_state_code_error>   :set<deafult_state_code_error> );
    my %default_state_code_success : ATTR( :get<default_state_code_success> :set<deafult_state_code_success> );

    # reporting [delivery:email]
    my %send_to             : ATTR( :get<send_to>              :set<send_to> );
    my %send_cc             : ATTR( :get<send_cc>              :set<send_cc> );
    my %send_from           : ATTR( :get<send_from>            :set<send_from> );
    my %send_subj_success   : ATTR( :get<send_subj_success>    :set<send_subj_success> );
    my %report_body_error   : ATTR( :get<report_body_error>    :set<report_body_error> );
    my %report_body_success : ATTR( :get<report_body_success>  :set<report_body_success> );

    # syslog logging options
    my %syslogopt : ATTR( :get<syslogopt>  :set<syslogopt> );
    my %syslogfacility : ATTR( :get<syslogfacility>  :set<syslogfacility> );

    @modes = qw( error success );
    $error_str{"modes"} = "Unknown mode 'ARG'. Available modes: " . join(",",@modes);
    $error_str{"unknown_method"} = "Unknown method 'ARG' can not be called on " . 
	__PACKAGE__ . " objects.";

    sub validate_modes : PRIVATE {
	my ($self, $mode) = @_;
	if (!grep {/^$mode$/} @modes ) {
	    throw Luka::Exception::Program
		( error => $self->get_error_str("modes",$mode), show_trace =>1 );
	}
    }

    sub get_error_str : PRIVATE {
	my ($self, $type, $arg) = @_; 
	if (exists $error_str{$type}) {
	    my $str = $error_str{$type};
	    $str =~ s/ARG/$arg/;
	    return $str;
	} else {
	    throw Luka::Exception::Program
		( error => "Error type '$type', isn't defined", show_trace =>1 );
	}
    }

    sub get : PRIVATE {
	my ($self, $val, $mode) = @_; 
	#print "val=$val,mode=$mode\n";
	$self->validate_modes($mode);
    	my $method = "get_" . $val . "_" . $mode;  
	if ( $self->can($method) ) {
	    #print "method=$method\n";
	    return $self->$method;
	} else {
	    throw Luka::Exception::Program
		( error => $self->get_error_str("unknown_method",$method), show_trace =>1 );
	}
    }

    sub BUILD {
	my ($self, $ident, $arg_ref) = @_; 

	my $luka_conf;
	# capture device and process state
	my $unknown = "unknown";
	$hostname{$ident} = hostname(); 
	$hostname_long{$ident} = hostname_long();
	$pid{$ident}     = $$;
	$uid{$ident}     = $<;
	$euid{$ident}    = $>;
	$gid{$ident}     = $(;
	$egid{$ident}    = $);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(CORE::time());
	$local_date_time{$ident} = 
	    sprintf("%s-%s-%sT%s:%s:%s",$year + 1900,$mon + 1,$mday,$hour,$min,$sec);
	$hostname{$ident}      = hostname() || $unknown;
	$hostname_long{$ident} = hostname_long() || $unknown;

	# error/report properties
	if (defined $arg_ref->{'error'}) { 

	    my $E = $arg_ref->{'error'};

 	    $filename{$ident} = $arg_ref->{'filename'};
 	    #$filename{$ident}  = $E->file;
	    $id{$ident}        = $E->id || "generic";
	    $severity{$ident}  = $E->can("severity") ? $E->severity : $unknown;
	    $args{$ident}      = $E->can("args")     ? 
		(defined($E->args) ? $E->args : $unknown) : $unknown;
	    $context{$ident}   = $E->can("context")  ? $E->context  : $unknown;
	    $line{$ident}      = $E->line;
	    $path{$ident}      = $E->path;
	    $conf{$ident}      = $E->conf ? $E->conf : undef;

	    if ( ref($E) eq "Error::Simple" or ref($E) eq "Luka::Error" ) {

		$text{$ident}       = $E->text       || $unknown;
		$stacktrace{$ident} = $E->stacktrace || $unknown;

	    } else {

		$text{$ident}       = $E->error || $unknown;
		$stacktrace{$ident} = $E->trace || $unknown;
		
	    }

	    # do we have syslogd running or not?
	    try {
	    #eval {
		#local $SIG{'__DIE__'}; # see "perldoc -f eval"
		openlog($filename{$ident}, "pid,noname", "daemon")
		    || die;
		syslog('info', "Luka initiating...") || die;
		$syslogd{$ident} = 1;
		open(BLA, '>> /tmp/log');
		print BLA "test try \n";
		close BLA;
	    #};
	    } catch Error with {
	    #if ($@ or $!) {
		my $e = shift;
		my $bla = Dumper $e;
		open(BLA2, '>> /tmp/log');
		print BLA2 "test catch\n";
		close BLA2;
		die "oops";
		$syslogd{$ident} = undef;
	    }

	    #===========================================================
	    # we had to delay seting of IP address, because of config
	    # object dependecy on possible optional 'conf' value passed
	    # to thrown Luka execptions.
	    #==========================================================
	    $luka_conf = Luka::Conf->new( conf => $conf{$ident}, syslogd => $syslogd{$ident} );
	    $ipaddr{$ident} = $unknown;
	    my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($hostname{$ident});
	    # of all interfaces, use closest match to IP from the config 
	    my $expected_ip = $luka_conf->get_conf('global','expected_ip');
	    for(0..$#addrs) {
		$addrs[$_] = inet_ntoa($addrs[$_]);
		# print $addrs[$_] . "\n";
		$ipaddr{$ident} = $addrs[$_] if $addrs[$_] =~ $expected_ip; 
	    }

	} else { # success

	    my $caller = (caller(1))[1];
	    my ($vol,$dir,$file) = File::Spec->splitpath($caller);
	    $arg_ref->{'filename'} = $file;
 	    $filename{$ident} = $arg_ref->{'filename'};

	    # do we have syslogd running or not?
	    eval {
		openlog($filename{$ident}, "pid,noname", "daemon");
		syslog('info', "Luka initiating...");
	    };
	    if ($@) {
		$syslogd{$ident} = undef;
	    } else {
		$syslogd{$ident} = 1;
	    }

	    #===========================================================
	    # we had to delay seting of IP address, because of config
	    # object dependecy on possible optional 'conf' value passed
	    # to thrown Luka execptions.
	    #==========================================================
	    $luka_conf = Luka::Conf->new( syslogd => $syslogd{$ident} );
	    $ipaddr{$ident} = $unknown;
	    my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($hostname{$ident});

	    # of all interfaces, use closest match to IP from the config 
	    my $expected_ip = $luka_conf->get_conf('global','expected_ip');
	    for(0..$#addrs) {
		$addrs[$_] = inet_ntoa($addrs[$_]);
		# print $addrs[$_] . "\n";
		$ipaddr{$ident} = $addrs[$_] if $addrs[$_] =~ $expected_ip; 
	    }
 	    
	    $text{$ident} = $luka_conf->get_conf( $arg_ref->{'filename'},'about' );
	}

	# reporting [delivery:email]
	$send_subj_success{$ident} = $luka_conf->get_conf( $arg_ref->{'filename'}, 'on_success');

	$send_to{$ident}     = $arg_ref->{'filename'} . 
	    "@" . $luka_conf->get_conf('global','email_domain');

	$send_cc{$ident}     = $luka_conf->get_conf( $arg_ref->{'filename'}, 'cc');

	$send_from{$ident}   = $luka_conf->get_conf( $arg_ref->{'filename'}, 'from') ||
	    "root@" . $hostname_long{$ident};

	$doc_base{$ident}    = $luka_conf->get_conf('global','doc_base') . "/" .
	    $luka_conf->get_conf($arg_ref->{'filename'},'doc');

	if (defined $arg_ref->{'error'}) { 
	    $doc_base{$ident} .=  "#" . $self->get_id;
	    $report_body_error{$ident} .= sprintf("%s=%s\n","host",$self->get_hostname_long eq "localhost" ?
						  $self->get_hostname : $self->get_hostname_long);
	    $report_body_error{$ident} .= sprintf("%s=%s\n","hosterr",$self->get_syslogd ? "" : "syslogd");
	    $report_body_error{$ident} .= sprintf("%s=%s\n","ipaddr",$self->get_ipaddr);
	    $report_body_error{$ident} .= sprintf("%s=%s\n","time",$self->get_local_date_time);
	    $report_body_error{$ident} .= sprintf("%s=%s\n","script",$arg_ref->{'filename'});
	    $report_body_error{$ident} .= sprintf("%s=%s\n","path", $self->get_path);
	    $report_body_error{$ident} .= sprintf("%s=%s\n","line",$self->get_line);
	    $report_body_error{$ident} .= sprintf("%s=%s\n","pid",$self->get_pid); 
	    $report_body_error{$ident} .= sprintf("%s=%s\n","severity",$self->get_severity); 
	    $report_body_error{$ident} .= sprintf("%s=%s\n","context",$self->get_context); 
	    $report_body_error{$ident} .= sprintf("%s=%s\n","args",$self->get_args); 
	    $report_body_error{$ident} .= sprintf("%s=%s\n","id",$self->get_id);
	    $report_body_error{$ident} .= sprintf("%s=%s\n\n","error",$self->get_text);
	    $report_body_error{$ident} .= sprintf("%s\n",$self->get_stacktrace);
	} else {
	    $report_body_success{$ident} .= sprintf("%s=%s\n","host",$self->get_hostname_long eq "localhost" ?
						    $self->get_hostname : $self->get_hostname_long)
	        . sprintf("%s=%s\n","hosterr",$self->get_syslogd ? "" : "syslogd")
		. sprintf("%s=%s\n","ipaddr",$self->get_ipaddr)
		. sprintf("%s=%s\n","time",$self->get_local_date_time)
		. sprintf("%s=%s\n","script",$arg_ref->{'filename'})
		. sprintf("%s=%s\n","pid",$self->get_pid);
	}

	$default_state_code_error{$ident}   = "E";
	$default_state_code_success{$ident} = "I";
	$state_code_error{$ident}           = 
	    $luka_conf->get_conf('global','single_char_error_code');
	$state_code_success{$ident}         = 
	    $luka_conf->get_conf('global','single_char_success_code');

	$debug{$ident}          = $luka_conf->get_conf('global','debug');
	$nomail{$ident}         = $luka_conf->get_conf($arg_ref->{'filename'},'nomail');
	$script_about{$ident}   = $luka_conf->get_conf($arg_ref->{'filename'},'about');
	$syslogopt{$ident}      = $luka_conf->get_conf('global','syslogopt');
	$syslogfacility{$ident} = $luka_conf->get_conf('global','syslogfacility');

	# what are the underlining Error class and text
	if ($debug{$ident} eq 1 && defined $arg_ref->{'error'} and defined($syslogd{$ident})) {
	    openlog( $filename{$ident}, $syslogopt{$ident}, $syslogfacility{$ident});
	    syslog('warning', "[$LukaDebug][class] %s", ref($arg_ref->{'error'}));
	    syslog('warning', "[$LukaDebug][text] %s", $self->get_text);
	    syslog('warning', "[$LukaDebug][context] %s", $self->get_context);
	    syslog('warning', "[$LukaDebug][args] %s", $self->get_args);
	    syslog('warning', "[$LukaDebug][id] %s", $self->get_id);
	    syslog('warning', "[$LukaDebug][hostname] %s", $self->get_hostname);
	    syslog('warning', "[$LukaDebug][ipaddres] %s", $self->get_ipaddr);
	    syslog('warning', "[$LukaDebug][hostname_long] %s", $self->get_hostname_long);
	}
	
    } # BUILD

    #======================
    # PUBLIC interface
    #======================
    sub report_error {
	my ($self,$message) = @_;
	$self->report("error",$message);
    }

    sub report_success {
	my ($self,$message) = @_;
	$self->report("success",$message);
    }
    #========================
    # PUBLIC interface ENDS
    #========================

    sub report : PRIVATE {
	my ($self,$mode,$message) = @_;

	openlog( $self->get_filename, $self->get_syslogopt, $self->get_syslogfacility )
	    if $self->get_syslogd;

	if ($mode eq "error" ) { # error mode

	    syslog('warning', "Error at line %s: %s", $self->get_line, $self->get_text)
		if $self->get_syslogd;

	} else { 	         # success mode

	    if ($message) {
		$self->set_text($message);
	    } else {
		$self->set_text($self->get_send_subj_success);
	    }

	}

	if (not $self->get_nomail) {

	    my $mess = Luka::Mailer->new
		( to         => $self->get_send_to,
		  cc         => $self->get_send_cc,
		  subject    => sprintf("[%s][%s][%s] %s", 
					$self->get_hostname,
					$self->get_local_date_time,
					$self->get("state_code",$mode) ||
					$self->get("default_state_code",$mode),  
 					    $self->get_text),
		  from       => $self->get_send_from,
		  body       => $self->get_script_about . "\n\n" . 
		  $self->get_doc_base . "\n\n" . 
		  $self->get("report_body",$mode) . "\n\n",
		  );    
	    
	    if (not $mess->send("Report emailed to recepients.\n")) {

		if ($self->get_syslogd) {

		    syslog('warning', "Couldn't report by email: to: %s, cc: %s, from: %s",
			   $self->get_send_to, $self->get_send_cc, $self->get_send_from);
		    syslog('warning', "Mail system reported: %s", $mess->error);

		}

		warn( "Couldn't report by email to:" . $self->get_send_to . ";cc:" . 
		      $self->get_send_cc . ";from:" . $self->get_send_from  . "\n");
	    } else {

		syslog( 'info', ucfirst($mode) . " report sent to " . 
			$self->get_send_to . ","  . $self->get_send_cc )
		    if $self->get_syslogd;

	    }

	} # if nomail
	
	closelog() if $self->get_syslogd;
	
    } # sub _report

}

1;

__END__

=head1 NAME

Luka - Exception handling and reporting framework

=head1 SYNOPSIS

    use Error qw(:try);
    use Luka;
  
    try {

        $ftp->login("someuser", "somepass") ||
            throw Luka::Exception::External
                ( error => $ftp->message . $@, id => "login",
	          context => "FTP error: couldn't login", severity => 3,
	          args => "user=someuser,pass=somepass" );
	
    } catch Luka::Exception with {

 	my $e = shift;
 	$e->report;
 	return 17;

    } catch Error with {

 	my $e = shift;
 	$e->report;
 	return 18;	

    };

=head1 DESCRIPTION

Luka is an exception handling and reporting framework. It's useful to
look at it as an event handling framework.

It comes from operational understanding of networks. 

Scenario that Luka is addressing is following: on a network with
multiple hosts running multiple applications, it is very difficult to
track operational status of all the functionality that those
applications and hosts are meant to deliver. In order to make it
easier, we decided to specify the error handling and reporting data
model that each component delivering functionality has to conform
to. What is a component? In most cases, it is a script, often run from
cronjob, in some cases it is a class in an application. In all cases,
a component has to successfully complete a task on which functionality
of an application, or entire network, relies on.

It is common practice that programmers choose their way of handling
errors and reporting. Luka is an attempt to standardize that
process. Its primary goal is to make it easier for smaller number of
people to keep larger number of applications and networks running.

Policy on script error handling that Luka suggests:

=over 4

=item NO ERROR CODES are used, instead exceptions are thrown

Already a common practice, especially in applications/components that are not small.

=item Standard set of error english names is established (network connection error)

As opposed to each network library, for example, having it's own way to report connection error.

=item  Page for each component (script/class) documenting relevant details

Already a common practice. Luka suggests that link to page describing
all possible errors, along with dependencies and schedules (for
components that run regularly), should exist. It is part of the Luka
event data model.

=item EACH time an error occurs following MUST be attempted:

=over 4

=item 1. Capture defined data set

=item 2. Log summary to to system log

=item 3. attempt delivery to end points

=back

=back

=head2 Example config

  [global]
  debug=0
  single_char_error_code=E
  single_char_success_code=I
  doc_base=http://localhost/
  email_domain=lists.mydomain.org
  syslogopt=pid,nowait
  syslogfacility=daemon
  expected_ip=10.1.8

  [myscript.pl]
  on_success=Task completed
  doc=LukaTests
  about=this library does something useful
  from=root@localhost
  cc=me@mydomain.org
  nomail=0

=head2 Example of error report

On an error caught, in syslog:

  Feb 26 15:34:39 localhost myscript.pl[1298]: Luka initiating... 
  Feb 26 15:34:39 localhost myscript.pl[1298]: Error at line 20: Net::FTP: Bad hostname 'bla.org' at myscript.pl line 324.  
  Feb 26 15:34:39 localhost myscript.pl[1298]: Error report sent to myscript.pl@lists.mydomain.org,me@mydomain.org

Email headers:

  From: root@localhost
  To: myscript.pl@lists.mydomain.org
  Cc: me@mydomain.org
  Subject: [galeb][2006-2-26T15:34:42][E] Net::FTP: Bad hostname 'bla.org'

Event (used verbatim in email body):

  this library does something useful

  http://localhost/LukaTests#ftp_object_creation

  host=galeb
  hosterr=
  ipaddr=10.1.8.18
  time=2006-2-26T15:34:42
  script=myscript.pl
  path=/home/toni/dev/cvs/perl/modules/luka
  line=245
  pid=1298
  severity=3
  context=FTP error: couldn't create object
  args=ftp.false
  id=ftp_object_creation
  error=Net::FTP: Bad hostname 'bla.org' 

  Trace begun at myscript.pl line 245
  main::__ANON__ at /usr/local/share/perl/5.8.7/Error.pm line 372
  eval {...} at /usr/local/share/perl/5.8.7/Error.pm line 371
  Error::subs::try at myscript.pl line 255
  main::ftp_luka_catch at myscript.pl line 123
  main::__ANON__ at /usr/local/share/perl/5.8.7/Test/Exception.pm line 281
  eval {...} at /usr/local/share/perl/5.8.7/Test/Exception.pm line 281
  Test::Exception::lives_and at myscript.pl line 124


=head2 Example of success report

On a captured report, in syslog:

  Feb 26 15:34:22 localhost myscript.pl[1273]: Luka initiating... 
  Feb 26 15:34:22 localhost myscript.pl[1273]: Success report sent to myscript.pl@lists.mydomain.org,me@mydomain.org

Email headers:

  From: root@localhost
  To: myscript.pl@lists.mydomain.org
  Cc: me@mydomain.org
  Subject: [galeb][2006-2-26T15:34:22][I] Task completed

Event (used verbatim in email body):

  this library does something useful

  http://localhost/LukaTests

  host=galeb
  hosterr=
  ipaddr=10.1.8.18
  time=2006-2-26T15:34:22
  script=myscript.pl
  pid=1273

=head1 LUKA EVENT DATA MODEL

=head2 Structure

  ABOUT COMPONENT
  \n
  DOC
  \n
  attribute=value
  attribute=value
  attribute=value
  attribute=attribute=value,attribute=value
  attribute=value
  \n
  \n
  STACKTRACE

=head2 Fields

=over 4

B<ABOUT COMPONENT> Comes from config file component section.

B<DOC> Location of the documentation. Can be URL, or some other
protocol address. Can be specific to the error reported, or component
general. Comes from config file component section.

B<host> - Name of the host where the event originates from. Collected.

B<hosterr> - Name of the services that Luka couldn't use as expected
on the host. Collected. The only possible value is, at the moment,
I<syslogd>.

B<ipaddr> - IP address of the host. Collected. When multiple IPs
present (most cases), regular expression matching one from the
configuration file field C<expected_ip> will be chosen.

B<time> - Timestamp, conforming to RFC3339 "Date and Time on the
Internet: Timestamps", see
L<http://www.ietf.org/rfc/rfc3339.txt>. Example:
C<2006-2-26T15:34:42>. Constructed out of host time.

B<script> - Name of the component that generated event. Collected.

B<pid> - Process ID of the component that generated the
 event. Collected from the host.

B<path> - Path to the component that generated event. Collected. Error
event only.

B<line> - Line number where event generation occurred. Collected. Error
event only. Error event only.

B<severity> - Severity level of the event (ambiguous, see TODO
section). Supplied by the programmer at the location of event
creation. Error event only.

B<context> - Descriptive text, context of the event. Specific to the
functionality that components performs from the user perspective,
rather than from the strictly technical perspective of programming
libraries. Supplied by the programmer at the location of event
creation. Error event only.

B<args> - Arguments relevant for the event generated (passed to the
function, object). Supplied by the programmer at the location of event
creation. Error event only.

B<id> - ID of the event. Supplied by the programmer at the location of
event creation. Matches the documentation for the component. Error
event only.

B<error> - Technical text of the error. Supplied by the programmer at
the location of event creation. Supplement to the C<context> field,
from the technical perspective, can contain error text returned by
used programming library. Error event only.

=back

=head1 METHODS

=head2 report

Luka report to syslog what happens by default.

  Aug 26 11:27:49 localhost myscript.pl[1038]: Error at line 46: Net::FTP: Bad hostname
  'ftp.bla.bla' at myscript.pl line 80.  

  Aug 26 11:27:49 localhost myscript.pl[1038]: Error report sent to myscript.pl@lists.mydomain.org

=head2 report_success( $message )

If the C<$message> is not supplied, value of the field C<on_success>
from the component section of Luka configuration file will be used.

=head1 DIAGNOSTICS

=over

=item C<Luka system not functional for '%s' script. Couldn't read its section '%s' in config file '%s'>

Throws Luka::Exception::Program exception. Luka can not deliver event
if section for given script is missing in given config. Sections are
by default named by the script name.

=item C<Luka system disabled. Couldn't read its config file '%s': %s>

Throws Luka::Exception::Program exception. Luka can not do anything if
its config file is missing or can not be parsed. However, if syslogd
is running, it will place a warning in syslog:

  Feb 26 12:26:59 localhost Luka::Conf[30438]: Luka system disabled. Couldn't read its config file 'bla.txt':
  Failed to open bla.txt: No such file or directory at lib/Luka/Conf.pm line 63

=item C<Couldn't report by email to:%s;cc:%s;from:%s>

Throws Luka::Exception::External. If MTA is not running, or if Luka
can not connect to it, stdout will receive:

  ERROR: Can't connect to localhost:25
  Couldn't report by email to:test@localhost;cc:toni@localhost;from:root@localhost

In the syslog, warning will be:

  Feb 26 13:42:08 localhost myscript.pl[3071]: Couldn't report by email: to: myscript.pl@lists.mydomain.org,
  cc: me@mydomain.org, from: root@localhost 

  Feb 26 13:42:08 localhost myscript.pl[3071]: Mail system reported: ERROR: Can't connect to localhost:25

=back


=head1 CONFIGURATION

=head2 global section

Single section, applies to the host on which Luka runs.

  [global]
  debug=0
  single_char_error_code=E
  single_char_success_code=I
  doc_base=http://localhost/
  email_domain=lists.mydomain.org
  syslogopt=pid,nowait
  syslogfacility=daemon
  expected_ip=10.1.8

Fields:

=over 4

B<debug> - Turns debugging mode on when set to 1.

B<single_char_error_code> - Delivery field. Single character error
code. Default is "E".  In email delivery, part of header SUBJECT
field.

B<single_char_success_code> - Delivery field. Single character success
code. Default is "I".  In email delivery, part of header SUBJECT
field.

B<doc_base> - Event field. Base part of the DOC field in the event
data model.

B<email_domain> Delivery field. Email. Domain part of the header TO
field.

B<syslogopt> I<$logopt> options passed to Sys::Syslog's I<openlog>
function

B<syslogfacility> I<$facility> option passed to Sys::Syslog's
 I<openlog> function

B<expected_ip> Event field. See above IPADDR field in the event data
model. Luka discovers IPs on the host. Since multiple IPs are present
in most cases, regular expression matching one from this configuration
file field I<expected_ip> will be selected. This would be a drawback
on a host with many interfaces, and solution with fixed IP would be a
lot more efficient in that case.

=back

=head2 component sections

One or more sections, applies to components programmed to use Luka.

  [myscript.pl]
  on_success=Task completed
  doc=LukaTests
  about=this library does something useful
  from=root@localhost
  cc=me@mydomain.org
  nomail=0

Fields:

=over 4

B<on_success> - Delivery field. In email delivery, part of header SUBJECT field.

B<doc> - Event field. Component part of the DOC field in the event
data model.

B<about> - Event field. See above COMPONENT field in the event data
model.

B<from> - Delivery field. Email. Header FROM field.

B<cc> - Delivery field. Email. Header CC field.

B<nomail> - If set to 1, event will not be delivered via email.

=back

=head1 DEPENDENCIES

=over

=item *

L<Error> - implementation of try/catch syntax

=item *

L<Exception::Class> - easy definition of hierarchy of exception
classes

=item *

L<Config::IniFiles> - config file handling
	
=item *

L<Sys::Syslog> - writing to syslog
	
=item *

L<Sys::Hostname> - determining hostname
	
=item *

L<Sys::Hostname::Long> - determining hostname
	
=item *

L<Mail::SendEasy> - sending reports by email

=item *

L<Class::Std> - inside/out classes builder

=back

=head1 INCOMPATIBILITIES

Mod-perl, due to use of Class::Std. I wasn't aware of Class::Std
limitations at the time of writing Luka. There are other
implementations of inside-out classes on CPAN that should be used as
replacements in of next releases of Luka. At the moment, best
candidate seems to be L<Object::InsideOut>.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-luka@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over

=item mod-perl compatibility

Migration from Class::Std to Object::InsideOut, or some other
inside-out class.

=item severity definitions

Severity needs defining, according to appropriate existing standard.

=item date-time format, timezone missing

Timezone needs adding to the date-time (RFC 3339) format.

=item report delivery mechanism abstraction

Reporting is also event delivery, and event delivery can be done in
many ways. Currently, email is hardcoded as a delivery
mechanism. Instead, reporting delivery has to be configurable. It
could be done via dynamic loading (from a value in the config) of
class implementing desired mechanism.

=item reporting to syslog config setting

It is default now that Luka method C<report> uses syslog for short
reporting. It should be made optional, in global, and script,
setting. Global config setting should be default; individual script
setting should override it.

=item event delivery on missing component section

When a section for component is missing in the config file, exception
is thrown (see DIAGNOSTICS above). Instead, event should still be
delivered, as long as relevant details about the destination of
delivery are in the global part of the Luka configuration file.

=item improve documentation

Documentation needs careful re-reading and improving. Any comments on
this especially appreciated.

=back

=head1 ACKNOWLEDGEMENTS

Ideas for underlining premises of Luka came out of discussions with
Bill Hulley.

=head1 AUTHOR

Toni Prug <toni@irational.org>

=head1 COPYRIGHT

Copyright (c) 2006. Toni Prug. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

See L<http://www.gnu.org/licenses/gpl.html>

=cut
