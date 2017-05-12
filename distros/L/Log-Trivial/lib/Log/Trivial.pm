#    $Id: Trivial.pm 61 2014-05-23 11:04:17Z adam $

package Log::Trivial;

use 5.010;
use utf8;
use strict;
use warnings;
use Fcntl qw(:DEFAULT :flock :seek);
use Carp;

our $VERSION = '0.40';

#
#    NEW
#

sub new {
    my $class  = shift;
    my %args   = @_;
    my $object = bless {
        _log_tag => $args{log_tag}
          || q{},            # Variable to tag this instance in the log file
        _mode    => 1,       # File logging mode 1=multi thread, 0=single
        _handle  => undef,   # File Handle if in single mode
        _o_sync  => 1,       # Use POSIX O_SYNC for writing, 1=on (default), 0=off
        _file          => $args{log_file} || q{},    # The Log File
        _level         => $args{log_level} || '3',   # Logging level
        _error_message => q{},                       # Store error messages here
        _debug         => undef,                     # debug flag
        _no_date_tag   => $args{no_date_tag}         # Date tagging? (1=off, 0=on)
    }, $class;

    return $object;
}

sub set_log_file {
    my $self     = shift;
    my $log_file = shift;
    if ( $self->_check_file($log_file) ) {
        $self->{_file} = $log_file;
        $self->{_self} = 0;
        return $self;
    }
    else {
        return;
    }
}

sub set_log_mode {
    my $self = shift;
    my $mode = shift;

    if ( $mode =~ /m/imx ) {
        $self->{_mode} = 1;
    }
    else {
        $self->{_mode} = 0;
    }

    return $self;
}

sub set_log_level {
    my $self  = shift;
    my $level = shift;

    $self->{_level} = $level if defined $level;

    return $self;
}

sub set_write_mode {
    my $self = shift;
    my $mode = shift;

    if ( $mode =~ /s/imx ) {
        $self->{_o_sync} = 1;
    }
    else {
        $self->{_o_sync} = 0;
    }
    return $self;
}

sub set_no_date_tag {
    my $self = shift;
    my $mode = shift;

    if ( $mode ) {
        $self->{_no_date_tag} = 1;
    }
    else {
        $self->{_no_date_tag} = 0;
    }
    return $self;
}

sub mark {
    my $self = shift;

    return $self->write( '-- MARK --' );
}

sub write {
    my $self = shift;
    my $message;
    if ( @_ > 1 ) {
        my %args  = @_;
        my $level = $args{level};
        return if $level && $self->{_level} < $level;
        $message = $args{comment} || q{.};
    }
    else {
        $message = shift;
    }

    return $self->_raise_error( 'Nothing message sent to log' )
        unless $message;

    $message = $self->{_log_tag} . "\t" . $message
      if $self->{_log_tag};

    $message = localtime() . "\t" . $message
      unless  $self->{_no_date_tag};

    my $file = $self->{_file};
    return $self->_raise_error( 'No Log file specified yet' ) unless $file;

    if ( -e $file && !-w _ ) {
        return $self->_raise_error(
            "Insufficient permissions to write to: $file" );
    }

    if ( $self->{_mode} ) {
        my $log = $self->_open_log_file( $file );
        if ( $log ) {
            $self->_write_log( $log, $message );
            close $log;
        }
        else {
            return $self->_raise_error( $self->get_error( ) );
        }
    }
    else {
        if ( !$self->{_handle} ) {
            $self->{_handle} = $self->_open_log_file( $file );
        }
        $self->_write_log( $self->{_handle}, $message );
    }
    return $message;
}

sub get_error {
    my $self = shift;
    return $self->{_error_message};
}

#
#    Private Stuff
#

sub _check_file {
    my $self = shift;
    my $file = shift;
    return $self->_raise_error( 'File error: No file name supplied' )
        unless $file;
    return $self;
}

sub _open_log_file {
    my $self = shift;
    my $file = shift;
    my $log;

    if ( $self->{_o_sync} ) {
        sysopen $log, $file, O_WRONLY | O_CREAT | O_SYNC | O_APPEND
            or return $self->_raise_error( "Unable to open Log File: $file" );
    }
    else {
        sysopen $log, $file, O_WRONLY | O_CREAT | O_APPEND
            or return $self->_raise_error( "Unable to open Log File: $file" );
    }
    flock $log, LOCK_EX
        or return $self->_raise_error( "Unable to flock Log file: $file" );

    return $log;

}

sub _write_log {
    my $self   = shift;
    my $handle = shift;
    my $string = shift() . "\n";

    my $bytes = length $string;
    sysseek $handle, 0, SEEK_END;
    syswrite $handle, $string, $bytes;
    return $self->_raise_error( 'Write Error' ) unless $bytes == length $string;
    return $bytes;
}

sub _raise_error {
    my $self    = shift;
    my $message = shift;
    carp $message if $self->{_debug};    # DEBUG:  warn with the message
    $self->{_error_message} = $message;  # NORMAL: set the message
    return;
}

1;

__END__


=head1 NAME

Log::Trivial - Very simple tool for writing very simple log files

=head1 SYNOPSIS

  use Log::Trivial;
  my $logger = Log::Trivial->new( log_file => 'path/to/my/file.log' );
  $logger->set_level( 3 );
  $logger->write(comment => 'foo' );

=head1 DESCRIPTION

Use this module when you want use "Yet Another" very simple, light
weight log file writer.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor can be called empty or with a number of optional
parameters.

  $logger = Log::Trivial->new();

or

  $logger = Log::Trivial->new(
    log_file    => '/my/config/file',
    log_tag     => $$,
    no_date_tag => 1,
    log_level   => 2);

The log_tag is an optional string that is written to every log event
between the date at the comment, and is intended to help separate logging
events in environments when multiple applictions are simultaneously
writing to the same log file. For example you could pass the PID of
the applications, as shown in the example above. The no_date_tag will
supress the default date printing feature in the log file.

=head2 set_log_file

The log file can be set after the constructor has been called.
Simply set the path to the file you want to use as the log file.

  $logger->set_log_file( '/path/to/log.file' );

=head2 set_log_mode

Log::Trivial runs in two modes. The default mode is Multi mode: in
this mode the file will be opened and closed for each log file write.
This may be slower but allows multiple applications to write to the log
file at the same time. The alternative mode is called single mode:
once you start to write to the log no other application honouring
flock will write to the log. Single mode is potentially faster, and
may be appropriate if you know that only one copy of your application
can should be writing to the log at any given point in time.

WARNING: Not all system honour flock.

  $logger->set_log_mode( 'multi' );    # Sets multi mode (the default)

or

  $logger->set_log_mode( 'single' );    # Sets single mode

=head2 set_log_level

Log::Trivial uses very simple arbitrary logging level logic. Level 0
is the highest priority log level, the lowest is the largest number
possible in Perl on your platform. You set the global log level for
your application using this function, and only log events of this
level or higher priority will be logged. The default level is 3.

  $logger->set_log_level( 4 );

=head2 set_write_mode

Log::Trivial write log enteries using the POSIX synchronous mode
by default. This mode ensures that the data has actually been
written to the disk. This feature is not supported in all
operating systems and will slow down the disk write. By default
this mode is enabled, in future it may be disabled by default.

  $logger->set_write_mode( 's' );     # sets synchronous (default)
  $logger->set_write_mode( 'a' );     # sets asynchronous

=head2 set_no_date_tag

By default Log::Trivial will include the current time and date of
each individual log entry. You can turn this feature off with this
method. Time and date logging is on by default.

  $logger->set_no_date_tag( 1 );   # Turns off date tagging

=head2 mark

If you just want to put a time stamp in the log stream this option
will send '-- MARK --' to the log. It probably only makes sense if
you have the time and date loggin option on.

  $logger->mark( );

=head2 write

Write a log file entry.

  $logger->write(
    comment => 'My comment to be logged',
    level   => 3);

or

  $logger->write( 'My comment to be logged' );

It will fail if the log file hasn't be defined, or isn't
writable. It will return the string written on success.

If you don't specify a log level, it will default to the current
log level and therefore log the event. Therefore if you always
wish to log something either specify a level of 0 or never
specify a log level.

Log file entries are time stamped and have a newline carriage
return added automatically.

=head2 get_error

In normal operation the module should never die. All errors are
non-fatal. If an error occurs it will be stored internally within
the object and the method will return undef. The error can be read
with the get_error method. Only the most recent error is stored.

  $logger->write( 'Log this' ) || say $logger->get_error( );

=head1 LOG FORMAT

The log file format is very simple and fixed:

Time & date [tab] Your log comment [carriage return new line]

If you have enabled a log_tag then the log format will have an extra
element inserted in it.

Time & date [tab] log_tag [tab] Your log comment [carriage return new line]

If you set the no_date_tag then the Time & date and the first tab will be
supressed.

=head2 DEPENDENCIES

At the moment the module only uses core modules. The test suite optionally uses
C<Pod::Coverage>, C<Test::Pod::Coverage> and C<Test::Pod>, which will be skipped
if you don't have them.

=head2 History

See Changes file.

=head1 BUGS AND LIMITATIONS

By default log write are POSIX synchronous, it is very unlikely that it will run
on any OS that does not support POSIX synchronous file writing, this means it
probably won't run on a VAX, Windows or other antique system. It does run under
Windows/Cygwin. To use non-POSIX systems you need to turn off synchronous write.

Patches Welcome... ;-)

=head2 To Do

=over

=item *

Much better test suite.

=item *

See if it's possible to work on non-POSIX like systems automatically

=back

=head1 EXPORT

None.

=head1 AUTHOR

Adam Trickett, E<lt>atrickett@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<Log::Agent>, L<Log::Log4perl>, L<Log::Dispatch>, L<Log::Simple>

=head1 LICENSE AND COPYRIGHT

This version as C<Log::Trivial>, Copyright Adam John Trickett 2005-2014

OSI Certified Open Source Software.
Free Software Foundation Free Software.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
