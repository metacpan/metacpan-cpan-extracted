###########################################################################
#
#   File.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use strict;
require Log::Agent::Channel;
require Log::Agent::Prefixer;

########################################################################
package Log::Agent::Channel::File;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Channel Log::Agent::Prefixer);

use Symbol;
use Fcntl;
use Log::Agent::Stamping;

#
# ->make        -- defined
#
# Creation routine.
#
# Attributes (and switches that set them):
#
# prefix        the application name
# stampfmt      stamping format ("syslog", "date", "own", "none") or closure
# showpid       whether to show pid after prefix in []
# filename      file name to open (magical open needs -magic_open)
# fileperm      permissions to open file with
# magic_open    flag to tell whether ">>file" or "|proc" are allowed filenames
# rotate        rotating policy for this file
# share         true implies that non-magic filenames share the same fd object
# no_ucfirst    don't capitalize first letter of message when no prefix
# no_prefixing  don't prefix logs
# no_newline    never append any newline character at the end of messages
#
# Other attributes:
#
# fd            records Log::Agent::File::* objects
# crlf          the new-line marker for this OS ("\n" on UNIX)
# warned        records calls made to hardwired warn() to only do them once
#
sub make {
    my $self = bless {}, shift;
    my (%args) = @_;

    my %set = (
        -prefix       => \$self->{'prefix'},
        -stampfmt     => \$self->{'stampfmt'},
        -showpid      => \$self->{'showpid'},
        -magic_open   => \$self->{'magic_open'},
        -filename     => \$self->{'filename'},
        -fileperm     => \$self->{'fileperm'},
        -rotate       => \$self->{'rotate'},
        -no_ucfirst   => \$self->{'no_ucfirst'},
        -no_prefixing => \$self->{'no_prefixing'},
        -no_newline   => \$self->{'no_newline'},
        -share        => \$self->{'share'},
    );

    while (my ($arg, $val) = each %args) {
        my $vset = $set{lc($arg)};
        unless (ref $vset) {
            require Carp;
            Carp::croak("Unknown switch $arg");
        }
        $$vset = $val;
    }

    #
    # Initialize proper time-stamping routine.
    #

    $self->{'stampfmt'} = stamping_fn($self->stampfmt)
        unless ref $self->stampfmt eq 'CODE';

    $self->{'fd'} = undef;
    $self->{'crlf'} = $^O =~ /^dos|win/i ? "\r\n" : "\n";
    $self->{'warned'} = {};

    if ($self->rotate) {
        eval {
            require Log::Agent::File::Rotate;
        };
        if ($@) {
            warn $@;
            require Carp;
            Carp::croak("Must install Log::Agent::Rotate to use rotation");
        }
    }

    return $self;
}

#
# Attribute access
#

sub magic_open { $_[0]->{'magic_open'} }
sub rotate     { $_[0]->{'rotate'}     }
sub filename   { $_[0]->{'filename'}   }
sub fileperm   { $_[0]->{'fileperm'}   }
sub fd         { $_[0]->{'fd'}         }
sub share      { $_[0]->{'share'}      }
sub warned     { $_[0]->{'warned'}     }

#
# ->write            -- defined
#
# Write logstring to the file.
# Priority is ignored by this channel.
#
sub write {
    my $self = shift;
    my ($priority, $logstring) = @_;

    #
    # This routine is called often...
    # Bypass the attribute access routines.
    #

    my $fd = $self->{fd};
    $fd = $self->open unless $fd;
    return unless ref $fd;

    my $prefix = '';
    $prefix = $self->prefixing_string(\$logstring)
        unless $self->{no_prefixing};

    my $crlf = '';
    $crlf = $self->{crlf} unless $self->{no_newline};

    #
    # The innocent-looking ->print statement below is NOT a polymorphic call.
    #
    # It can be targetted on various Log::Agent::File::* objects, which
    # all happen to provide a print() feature with the same signature.
    # However, those clases have no inheritance relationship because Perl
    # is not typed, and the ancestor would be a deferred class anyway.
    #

    $fd->print($prefix, $logstring, $crlf);
    return;
}

#
# ->open
#
# Open channel, and return the opened file descriptor.
# Also record opened file within $self->fd.
#
sub open {
    my $self = shift;
    my $filename = $self->filename;

    require Log::Agent::File::Native;

    my $fobj;
    my $note;

    #
    # They may use ">file" or "|proc" as channel files if -magic_open
    #

    if ($filename =~ /^\s*[>|]/ && $self->magic_open) {

        # restrict the permissions
        my $mask = umask;
        umask($mask | 0666 ^ $self->fileperm) if defined $self->fileperm;

        # open the file
        my $h = gensym;
        $fobj = Log::Agent::File::Native->make($h) if open($h, $filename);

        # restore the permissions
        umask $mask;

    } else {
        #
        # If the file is already opened, and the current channel can be
        # shared, do not re-open it: share the same Log::Agent::File::* object,
        # along with its rotation policy.
        #

        my $rotate = $self->rotate;                # A Log::Agent::Rotate object
        my $pool;

        if ($self->share) {
            require Log::Agent::File_Pool;
            $pool = Log::Agent::File_Pool::file_pool();
            my ($eobj, $erot) = $pool->get($filename);

            if (defined $eobj) {
                $fobj = $eobj;            # Reuse same object
                $note = "rotation for '$filename' may be wrong" .
                    " (shared with distinct policies)" if
                        defined $erot && defined $rotate &&
                        !$erot->is_same($rotate);
            }
        }

        unless (defined $fobj) {
            if (defined $rotate) {
                $fobj = Log::Agent::File::Rotate->make($filename, $rotate);
            } else {
                my $h = gensym;
                $fobj = Log::Agent::File::Native->make($h)
                        if sysopen($h, $filename, O_CREAT|O_APPEND|O_WRONLY,
                        defined $self->fileperm ? $self->fileperm : 0666);
            }
        }

        #
        # Record object in pool if shared, even if already present.
        # We maintain a refcount of all the shared items.
        #

        $pool->put($filename, $fobj, $rotate)
            if defined $fobj && $self->share;
    }

    #
    # If an error occurred, we have no choice but to emit a warning via warn().
    # Otherwise, the error would disappear, and we know they don't want to
    # silence us, or they would not try to open a logfile.
    #
    # Warn only once per filename though.
    #

    unless (defined $fobj) {
        my $prefix = $self->prefixing_string() || "$0: ";
        warn "${prefix}can't open logfile \"$filename\": $!\n"
            unless $self->warned->{$filename}++;
        return undef;
    }

    $self->{fd} = $fobj || 1;    # Avoid recursion in open if not defined

    #
    # Print the note, using ->write() now that $self->fd is recorded.
    #

    if (defined $note) {
        $note .= $self->crlf if $self->no_newline;
        $self->write(undef, $note);
    }

    return $fobj;
}

#
# ->close            -- defined
#
sub close {
    my $self = shift;
    my $fd = $self->fd;
    return unless ref $fd;

    $self->{fd} = 1;            # Prevents further opening from ->write
    unless ($self->share) {
        $fd->close;
        return;
    }

    #
    # A shared file is physically closed only when the last reference
    # to it is removed.
    #

    my $pool = Log::Agent::File_Pool::file_pool();
    $fd->close if $pool->remove($self->filename);
    return;
}

1;    # for require
__END__

=head1 NAME

Log::Agent::Channel::File - file logging channel for Log::Agent

=head1 SYNOPSIS

 require Log::Agent::Channel::File;

 my $driver = Log::Agent::Channel::File->make(
     -prefix     => "prefix",
     -stampfmt   => "own",
     -showpid    => 1,
     -magic_open => 0,
     -filename   => "/tmp/output.err",
     -fileperm   => 0640,
     -share      => 1,
 );

=head1 DESCRIPTION

The file channel performs logging to a file, along with the necessary
prefixing and stamping of the messages.

Internally, the C<Log::Agent::Driver::File> driver creates such objects
for each logging channel defined at driver creation time.

The creation routine make() takes the following arguments:

=over 4

=item C<-filename> => I<file>

The file name where output should go.  The file is opened in append mode
and autoflushing is turned on.  See also the C<-magic_open> flag.

=item C<-fileperm> => I<perm>

The permissions that the file should be opened with (XOR'd with the user's
umask).  Due to the nature of the underlying open() and sysopen(), the value
is limited to less than or equal to 0666.  See L<perlfunc(3)/umask> for more
details.

=item C<-magic_open> => I<flag>

When true, channel filenames beginning with '>' or '|' are opened using
Perl's open(). Otherwise, sysopen() is used, in append mode.

Default is I<false>.

=item C<-no_newline> => I<flag>

When set to I<true>, never append any "\n" (on Unix) or "\r\n" (on Windows)
to log messages.

Internally, Log::Agent relies on the channel to delimit logged lines
appropriately, so this flag is not used.  However, it might be useful
for C<Log::Agent::Logger> users.

Default is I<false>, meaning newline markers are systematically appended.

=item C<-no_prefixing> => I<flag>

When set to I<true>, disable the prefixing logic entirely, i.e. the
following options are ignored completely: C<-prefix>, C<-showpid>,
C<-no_ucfirst>, C<-stampfmt>.

Default is I<false>.

=item C<-no_ucfirst> => I<flag>

When set to I<true>, don't upper-case the first letter of the log message
entry when there's no prefix inserted before the logged line.  When there
is a prefix, a ":" character follows, and therefore the leading letter
of the message should not be upper-cased anyway.

Default is I<false>, meaning uppercasing is performed.

=item C<-prefix> => I<prefix>

The application prefix string to prepend to messages.

=item C<-rotate> => I<object>

This sets a default logfile rotation policy.  You need to install the
additional C<Log::Agent::Rotate> module to use this switch.

I<object> is the C<Log::Agent::Rotate> instance describing the rotating
policy for the channel.  Only files which are not opened via a
so-called I<magic open> can be rotated.

=item C<-share> => I<flag>

When I<true>, this flag records the channel in a global pool indexed by
filenames.  An existing file handle for the same filename may be then
be shared amongst several file channels.

However, you will get this message in the file

 Rotation for 'filename' may be wrong (shared with distinct policies)

when a rotation policy different from the one used during the initial
opening is given.  Which policy will be used is unspecified, on purpose.

=item C<-showpid> => I<flag>

If set to true, the PID of the process will be appended within square
brackets after the prefix, to all messages.

Default is I<false>.

=item C<-stampfmt> => (I<name> | I<CODE>)

Specifies the time stamp format to use. By default, my "own" format is used.
See L<Log::Agent::Stamping> for a description of the available format names.

You may also specify a CODE ref: that routine will be called every time
we need to compute a time stamp. It should not expect any parameter, and
should return a string.

=back

=head1 CAVEAT

Beware of chdir().  If your program uses chdir(), you should always specify
logfiles by using absolute paths, otherwise you run the risk of having
your relative paths become invalid: there is no anchoring done at the time
you specify them.  This is especially true when configured for rotation,
since the logfiles are recreated as needed and you might end up with many
logfiles scattered throughout all the directories you chdir()ed to.

=head1 AUTHORS

Originally written by Raphael Manfredi E<lt>Raphael_Manfredi@pobox.comE<gt>,
currently maintained by Mark Rogaski E<lt>mrogaski@cpan.orgE<gt>.

=head1 LICENSE

Copyright (C) 1999 Raphael Manfredi.
Copyright (C) 2002 Mark Rogaski, mrogaski@cpan.org; all rights reserved.

See L<Log::Agent(3)> or the README file included with the distribution for
license information.

=head1 SEE ALSO

Log::Agent::Logger(3), Log::Agent::Channel(3).

=cut
