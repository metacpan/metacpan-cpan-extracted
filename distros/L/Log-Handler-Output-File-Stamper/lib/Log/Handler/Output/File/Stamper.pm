=head1 NAME

Log::Handler::Output::File::Stamper - Log messages to a file(with stamp in the filename).


=head1 SYNOPSIS

    use Log::Handler::Output::File::Stamper;

    my $log = Log::Handler::Output::File::Stamper->new(
        filename => "foo%d{yyyyMMdd}.log",
    );

    $log->log(message => 'log message'); # => foo20130113.log


=head1 DESCRIPTION

This module is subclasses C<Log::Handler::Output::File> for logging to date/time/pid
stamped files. See L<Log::Handler::Output::File> for instructions on usage.

This module differs only on the following points:

=over 4

=item fork()-safe

This module will close and re-open the logfile after a fork.
Instead, there are no C<mode>s to open a log file. It is C<append> mode only.
And C<reopen> option was removed(It is always set 1:enabled).

=item multitasking-safe

This module uses flock() to lock the file while writing to it.
Then also C<filelock> option was removed(means always set 1:enabled).

=item stamped filenames

This module supports a special tag in the filename that will expand to
the current date/time/pid. See also L<Log::Stamper>

=back


=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::File::Stamper object.

=head2 log()

Call C<log()> if you want to log messages to the log file(with stamp).

You can check other methods in L<Log::Handler::Output::File> document.


=head1 REPOSITORY

Log::Handler::Output::File::Stamper is hosted on github
<http://github.com/bayashi/Log-Handler-Output-File-Stamper>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>

Source codes of this module were borrowed from below modules, very very thanks.

L<Log::Dispatch::File::Rolling>, L<Log::Dispatch::File::Stamped>


=head1 SEE ALSO

L<Log::Handler>, L<Log::Handler::Output::File>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

package Log::Handler::Output::File::Stamper;
use strict;
use warnings;
use Carp qw/croak/;
use Log::Handler::Output::File;
use Fcntl qw( :flock O_WRONLY O_APPEND O_TRUNC O_EXCL O_CREAT );
use Log::Stamper;

our @ISA = qw/Log::Handler::Output::File/;

our $VERSION = '0.03';
our $ERRSTR  = "";

our $TIME_HIRES_AVAILABLE = undef;
BEGIN {
    eval { require Time::HiRes; };
    if ($@) {
        $TIME_HIRES_AVAILABLE = 0;
    } else {
        $TIME_HIRES_AVAILABLE = 1;
    }
}

sub new {
    my $class = shift;
    my $opts  = $class->_validate(@_);

    my $self  = bless $opts, $class;

    # force options
    $self->{mode}     = O_WRONLY | O_APPEND | O_CREAT; # append
    $self->{reopen}   = 1;
    $self->{filelock} = 1;

    # split pathname into path, basename, extension
    if ($self->{filename} =~ /^(.*)\%d\{([^\}]*)\}(.*)$/) {
        $self->{_stamper_filename_prefix}  = $1;
        $self->{_stamper_filename_postfix} = $3;
        $self->{_stamper_filename_format}  = Log::Stamper->new($2);
        $self->{filename} = $self->_create_file_name();
    }
    elsif ($self->{filename} =~ /^(.*)(\.[^\.]+)$/) {
        $self->{_stamper_filename_prefix}  = $1;
        $self->{_stamper_filename_postfix} = $2;
        $self->{_stamper_filename_format}  = Log::Stamper->new('-yyyy-MM-dd');
        $self->{filename} = $self->_create_file_name();
    }
    else {
        $self->{_stamper_filename_prefix}  = $self->{filename};
        $self->{_stamper_filename_postfix} = '';
        $self->{_stamper_filename_format}  = Log::Stamper->new('.yyyy-MM-dd');
        $self->{filename} = $self->_create_file_name();
    }

    # open the log file permanent
    if ($self->{fileopen}) {
        $self->_open
            or croak $self->errstr;
    }

    return $self;
}

sub log {
    my $self = shift;

    $self->_file_stamp;
    $self->_fork_safe or return;

    $self->SUPER::log(@_);
}

#
# private stuff
#
sub _open {
    my $self = shift;

    $self->SUPER::_open(@_) or return;
    $self->{_stamper_fh_pid} = $$;
    return 1;
}

sub _fork_safe {
    my $self = shift;

    if ($self->{fileopen}) {
        my $pid = $$;
        if ( $self->{_stamper_fh_pid} !~ m!^$pid$! ) {
            $self->close or return;
            $self->_open or return;
        }
    }

    return 1;
}

sub _file_stamp {
    my $self = shift;

    my $filename = $self->_create_file_name;
    if ($filename ne $self->{filename}) {
        $self->{filename} = $filename;
        $self->{_stamper_fh_pid} = 'x' # force reopen
    }

    return 1;
}

sub _create_file_name {
    my $self = shift;

    return $self->{_stamper_filename_prefix}
            . $self->_format()
            . $self->{_stamper_filename_postfix};
}

sub _format {
    my $self = shift;

    my $result = $self->{_stamper_filename_format}->format($self->_current_time);
    $result =~ s/(\$+)/sprintf('%0'.length($1).'.'.length($1).'u', $$)/eg;
    return $result;
}

sub _current_time {
    if($TIME_HIRES_AVAILABLE) {
        return(Time::HiRes::gettimeofday());
    }
    else {
        return(time(), 0);
    }
}

1;
