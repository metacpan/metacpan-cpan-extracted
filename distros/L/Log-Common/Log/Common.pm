# Log::Common - write log file entries in the httpd common log formats
# $Id: Common.pm,v 1.2 1998/10/16 17:37:04 martin Exp $

# Copyright (c) 1998 Martin Hamilton and Jon Knight.  All rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Log::Common;

use strict;
use vars qw($VERSION);
use Carp;

$VERSION = "1.00";


sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;
    my ($a, $v, $access_fd, $error_fd);
    my ($self) = {};

    while(($a, $v) = each %args) { $self->{$a} = $v; }
    bless $self, $class;

    if ($args{access}) {
      open(ACCESS_FD, ">>$args{access}");
      $access_fd = *ACCESS_FD;
      flock($access_fd, 2);
    }

    if ($args{error}) {
      open(ERROR_FD, ">>$args{error}");
      $error_fd = *ERROR_FD;
      flock($error_fd, 2);
    }

    $self->{access_fd} = $access_fd;
    $self->{error_fd} = $error_fd;
    $self->{class} = $args{class} if $args{class};
    $self->{no_stderr} = $args{no_stderr} if $args{no_stderr};
    return $self;
}


# write "error" log file entry in httpd server common log format
sub error {
    my ($self, %args) = @_;
    my ($class) = ($args{class} || $self->{class}) || undef;
    my ($no_stderr) = ($args{no_stderr} || $self->{no_stderr}) || 0;
    my ($message) = ($args{message} || $self->{message}) || "nada";
    my ($info) = ($args{info} || $self->{info}) || undef;
    my ($LOG);

    # don't send the error message to STDERR if we're running as a
    # CGI program, or in harness to one
    if (!defined($ENV{"GATEWAY_INTERFACE"}) || !$no_stderr) {
	my $msg = "";
	$msg = "$class: " if defined($class);
	$msg .= $message;
	$msg .= " ($info)" if defined($info);

	warn "$msg\n";
    }

    $LOG = $self->{error_fd};
    flock($LOG, 2); # lock prior to writing

    # what we came here for in the first place
    print $LOG "[" . gmtime(time) . "] ";
    print $LOG "$class: " if defined($class);
    print $LOG $message;
    # supplementary info if available
    print $LOG "($info)" if defined($info);
    print $LOG "\n";

    flock(LOG, 8); # unlock after writing
    croak($args{fatal}) if defined($args{fatal});
}


# write "access" log file entry in httpd common log format
sub access {
    my ($self, %args) = @_;
    my $host = (($args{host}  || $ENV{REMOTE_HOST})  || $ENV{REMOTE_ADDR})
	|| "0.0.0.0";
    my $ident = ($args{ident}  || $ENV{REMOTE_IDENT}) || "-";
    my $user = ($args{user}   || $ENV{REMOTE_USER})  || "-";
    my $message = $args{message} || "nada";
    my $code = $args{code}  || 0,
    my $count = $args{count}  || 0;

    my(@MON) = ('Dummy', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
	    'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    my ($gsec,$gmin,$ghour,$gmday,$gmon,$gyear,$gwday,$gyday,$gisdst)
	= gmtime;
    my ($LOG);

    my $offset = $hour - $ghour;
    $year += 1900; # enough of a Y2K fix ?

    my $datestr = sprintf("%02d/%s/%4d:%02d:%02d:%02d %s%02d00", $mday, 
		       $MON[$mon + 1], $year, $hour, $min, $sec, 
		       $offset >= 0 ? '+' : '-', $offset);

    $LOG = $self->{access_fd};
    flock($LOG, 2); # lock prior to writing

    # what we came here for
    printf $LOG "%s %s %s [%s] \"%s\" %d %d\n",
      $host, $ident, $user, $datestr, $message, $code, $count;

    flock($LOG, 8); # unlock after writing
    croak($args{fatal}) if defined($args{fatal});
}

1;
__END__


=head1 NAME

Log::Common - log messages in the httpd access and error log styles

=head1 SYNOPSIS

  use Log::Common;

  $l = new Log::Common(access => "/var/log/search-hits",
                       error  => "/usr/local/log/error_log",
                       no_stderr => 1,
                       class => "debug");

  $l->error(message => "Uh-oh... :-(", fatal => 1);
  $l->access(user => "martin", message => "$query_string",
	       code => 200);

=head1 DESCRIPTION

This class defines two methods which may be used to write messages to
I<httpd> common log file style access and error log files, such as
those maintained by the Apache and NCSA WWW servers.  The log file is
locked whilst being written to avoid corruption when multiple
processes attempt to write to the same file at the same time.  For
convenience both methods support a parameter which, if specified,
results in "exit" being called to bomb out of the program.

If the environmental variable GATEWAY_INTERFACE isn't set, error
messages are also sent to STDERR - though this behaviour can be
overridden if undesired.  This is so that Perl programs which use this
class can trivially dump out messages both to their end user and to a
system log file at the same time.

Error log file entries are written with a leading UTC timestamp, in
the common HTTP server usage.

=head1 METHODS

=over 4

=item access( [ OPTIONS ] );

=item error( [ OPTIONS ] );

=back

=head1 PARAMETERS

When creating a Log::Common object:

=over 4

=item I<access> => B<access_log_filename>

This is the filename to use when logging via the B<access> method.

=item I<error> => B<error_log_filename>

This is the filename to use when logging via the B<error> method.

=item I<class> => B<class_name>

The default class of error log messages.  You can use this to
distinguish between debugging info, security related info, messages
from WWW servers, messages from the mail system, and so on.  This
default value can be overridden in an individual call to the B<error>
logging method.

=item I<no_stderr> => B<0> or B<1>

Suppress the printing of the message to STDERR if set to 1, defaults
to 0.  This can be overridden when the B<error> method is invoked.

=back

Common to both methods:

=over 4

=item I<fatal> => B<exit_code>

This indicates that whatever happened was a fatal error, and causes
the program to B<croak> after the log file entry has been written.
The value given will be used as the program's exit code.

=item I<message> => B<message_string>

The actual message to write to the log file.

=back

For the B<access> method only:

=over 4

=item I<count> => B<number>

Normally the number of bytes transferred - I<0> if not supplied.

=item I<code> => B<response_code>

Normally the number of bytes transferred - I<0> if not supplied.

=item I<host> => B<host_name>

The domain name or IP address of the calling/client host.  If not
supplied, the process environment will be checked for REMOTE_HOST and
REMOTE_ADDR (as set by CGI) in turn.  If neither of these is present
this field in the log file will be set to I<0.0.0.0>.

=item I<ident> => B<value_of_ident_lookup>

Normally the result of an IDENT (AUTH) lookup on the calling host and
port.  If not supplied, the value of REMOTE_IDENT in the process
environment will be used, or "-".

=item I<user> => B<authenticated_user_name>

Normally the user name which has been authenticated, e.g. using basic
HTTP authentication.  If not supplied, the value of REMOTE_USER in the
process environment will be used instead, or "-".

=back

For the B<error> method only:

=over 4

=item I<class> => B<class_name>

Overrides default setting for this invocation - see above.

=item I<info> => B<info_string>

Additional info - this will be rendered enclosed in round brackets
at the end of this line in the log file.

=item I<no_stderr> => B<0> or B<1>

Overrides default setting for this invocation - see above.

=back

=head1 FILE FORMATS

Note that these are the common field usages - you don't have to put
the same things in the same fields, though it would probably make life
easier if you were planning to process these log files through
existing HTTP server log file analysis tools.

The error log file is structured as follows :-

=over 4

=item I<the date>

This is prettyprinted in GMT (UTC) using the B<gmtime> function and
enclosed in square brackets.  It's always generated for you.

=item I<the class of message>

This will be followed by a colon character ':'.  Taken from the
I<class> parameter.  This overrides any default value set for the
object as a whole.

=item I<any supplementary information>

Taken from the I<info> parameter.  This will be enclosed in round
brackets.

=back

The access log file is structured as follows :-

=over 4

=item I<client host name/IP address>

Taken from the I<host> parameter.

=item I<remote user name>

Taken from the I<ident> parameter.  This is normally found via the
AUTH/IDENT protocol - RFC 1413, RFC 931.

=item I<remote user name>

Taken from the I<user> parameter.  This is normally from HTTP
authentication.

=item I<timestamp>

Generated using B<localtime>, with a GMT (UTC) offset.  This will be
enclosed in square brackets, and will always be generated
automatically for you.

=item I<the message itself>

Taken from the I<message> parameter.

=item I<response status code>

Taken from the I<code> parameter.  This is normally numeric.

=item I<bytes transferred count>

Taken from the I<count> parameter.  This is normally numeric.

=back

=head1 BUGS

None ? :-)

=head1 TODO

Extended log file format (dump variable X as field Y in the log file
entry?) might be useful.

=head1 COPYRIGHT

Copyright (c) 1998 Martin Hamilton <martinh@gnu.org> and Jon Knight
<jon@net.lut.ac.uk>.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.

It was developed by the Department of Computer Studies at Loughborough
University of Technology, as part of the ROADS project.  This work was
funded by the Joint Information Systems Committee (JISC) of the Higher
Education Funding Councils under the UK Electronic Libraries Programme
(eLib), the European Commission DESIRE project, and the TERENA
development programme.

=head1 AUTHORS

  Jon Knight <jon@net.lut.ac.uk>
  Martin Hamilton <martinh@gnu.org>
