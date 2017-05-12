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
require Log::Agent::Driver;

########################################################################
package Log::Agent::Driver::File;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Driver);

#
# ->make        -- defined
#
# Creation routine.
#
# Attributes (and switches that set them):
#
# prefix        the application name
# duperr        whether to duplicate "error" channels to "output"
# stampfmt      stamping format ("syslog", "date", "own", "none") or closure
# showpid       whether to show pid after prefix in []
# channels      where each channel ("error", "output", "debug") goes
# chanperm      what permissions each channel ("error", "output", "debug") has
# magic_open    flag to tell whether ">>file" or "|proc" are allowed filenames
# rotate        default rotating policy for logfiles
#
# Additional switches:
#
# file          sole channel, implies -duperr = 0 and supersedes -channels
# perm          file permissions that supersedes all channel permissions
#
# Other attributes:
#
# channel_obj        opened channel objects
#
sub make {
    my $self = bless {}, shift;
    my (%args) = @_;
    my $prefix;
    my $file;
    my $perm;

    my %set = (
        -prefix     => \$prefix,  # Handled by parent via _init
        -duperr     => \$self->{'duperr'},
        -channels   => \$self->{'channels'},
        -chanperm   => \$self->{'chanperm'},
        -stampfmt   => \$self->{'stampfmt'},
        -showpid    => \$self->{'showpid'},
        -magic_open => \$self->{'magic_open'},
        -file       => \$file,
        -perm       => \$perm,
        -rotate     => \$self->{'rotate'},
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
    # If -file was used, it supersedes -duperr and -channels
    #

    if (defined $file && length $file) {
        $self->{'channels'} = {
            'debug'  => $file,
            'output' => $file,
            'error'  => $file,
        };
        $self->{'duperr'} = 0;
    }

    #
    # and we do something similar for file permissions
    #

    if (defined $perm && length $perm) {
        $self->{chanperm} = {
            debug  => $perm,
            output => $perm,
            error  => $perm
        };
    }

    $self->_init($prefix, 0);  # 1 is the skip Carp penalty for confess

    $self->{channels}    = {} unless $self->channels;  # No defined channels
    $self->{chanperm}    = {} unless $self->chanperm;  # No defined perms
    $self->{channel_obj} = {};                         # No opened files

    #
    # Check for logfile rotation, which can be specified on a global or
    # file by file basis.  Since Log::Agent::Rotate is a separate extension,
    # it may not be installed.
    #

    my $use_rotate = defined($self->rotate) ? 1 : 0;
    unless ($use_rotate) {
        foreach my $chan (keys %{$self->channels}) {
            $use_rotate = 1 if ref $self->channels->{$chan} eq 'ARRAY';
            last if $use_rotate;
        }
    }

    if ($use_rotate) {
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

sub duperr      { $_[0]->{duperr}      }
sub channels    { $_[0]->{channels}    }
sub chanperm    { $_[0]->{chanperm}    }
sub channel_obj { $_[0]->{channel_obj} }
sub stampfmt    { $_[0]->{stampfmt}    }
sub showpid     { $_[0]->{showpid}     }
sub magic_open  { $_[0]->{magic_open}  }
sub rotate      { $_[0]->{rotate}      }

#
# ->prefix_msg  -- defined
#
# NOP: channel handles prefixing for us.
#
sub prefix_msg {
    my $self = shift;
    return $_[0];
}

#
# ->chanfn
#
# Return channel file name.
#
sub chanfn {
    my $self = shift;
    my ($channel) = @_;
    my $filename = $self->channels->{$channel};
    if (ref $filename eq 'ARRAY') {
        $filename = $filename->[0];
    }
    # No channel defined, use 'error'
    $filename = $self->channels->{'error'} unless
            defined $filename && length $filename;
    $filename = '<STDERR>' unless defined $filename;

    return $filename;
}

#
# ->channel_eq  -- defined
#
# Compare two channels.
#
# It's hard to know for certain that two channels are equivalent, so we
# compare filenames.  This is not correct, of course, but it will do for
# what we're trying to achieve here, namely avoid duplicates if possible
# when traces are remapped to Carp::Datum.
#
sub channel_eq {
    my $self = shift;
    my ($chan1, $chan2) = @_;
    my $fn1 = $self->chanfn($chan1);
    my $fn2 = $self->chanfn($chan2);
    return $fn1 eq $fn2;
}

#
# ->write       -- defined
#
sub write {
    my $self = shift;
    my ($channel, $priority, $logstring) = @_;
    my $chan = $self->channel($channel);
    return unless $chan;

    $chan->write($priority, $logstring);
}

#
# ->channel
#
# Return channel object (one of the Log::Agent::Channel::* objects)
#
sub channel {
    my $self = shift;
    my ($name) = @_;
    my $obj = $self->channel_obj->{$name};
    $obj = $self->open_channel($name) unless $obj;
    return $obj;
}


#
# ->open_channel
#
# Open given channel according to the configured channel description and
# return the object file descriptor.
#
# If no channel of that name was defined, use 'error' or STDERR.
#
sub open_channel {
    my $self = shift;
    my ($name) = @_;
    my $filename = $self->channels->{$name};

    #
    # Handle possible logfile rotation, which may be defined globally
    # or on a file by file basis.
    #

    my $rotate;        # A Log::Agent::Rotate object
    if (ref $filename eq 'ARRAY') {
        ($filename, $rotate) = @$filename;
    } else {
        $rotate = $self->rotate;
    }

    my @common_args = (
        -prefix   => $self->prefix,
        -stampfmt => $self->stampfmt,
        -showpid  => $self->showpid,
    );
    my @other_args;
    my $type;

    #
    # No channel defined, use 'error', or revert to STDERR
    #

    $filename = $self->channels->{'error'} unless
            defined $filename && length $filename;

    unless (defined $filename && length $filename) {
        require Log::Agent::Channel::Handle;
        select((select(main::STDERR), $| = 1)[0]);
        $type = "Log::Agent::Channel::Handle";
        @other_args = (-handle => \*main::STDERR);
    } else {
        require Log::Agent::Channel::File;
        $type = "Log::Agent::Channel::File";
        @other_args = (
            -filename   => $filename,
            -magic_open => $self->magic_open,
            -share      => 1,
        );
        push(@other_args, -fileperm   => $self->chanperm->{$name})
                if $self->chanperm->{$name};
        push(@other_args, -rotate => $rotate) if ref $rotate;
    }

    return $self->channel_obj->{$name} =
            $type->make(@common_args, @other_args);
}

#
# ->emit_output
#
# Force error message to the regular 'output' channel with a specified tag.
#
sub emit_output {
    my $self = shift;
    my ($prio, $tag, $str) = @_;
    my $cstr = $str->clone;       # We're prepending tag on a copy
    $cstr->prepend("$tag: ");
    $self->write('output', $prio, $cstr);
}

###
### Redefined routines to handle duperr
###

#
# ->logconfess
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with FATAL.
#
sub logconfess {
    my $self = shift;
    my ($str) = @_;
    $self->emit_output('critical', "FATAL", $str) if $self->duperr;
    $self->SUPER::logconfess($str);    # Carp strips calls within hierarchy
}

#
# ->logxcroak
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with FATAL.
#
sub logxcroak {
    my $self = shift;
    my ($offset, $str) = @_;
    my $msg = Log::Agent::Message->make(
        $self->carpmess($offset, $str, \&Carp::shortmess)
    );
    $self->emit_output('critical', "FATAL", $msg) if $self->duperr;

    #
    # Carp strips calls within hierarchy, so that new call should not show,
    # there's no need to adjust the frame offset.
    #
    $self->SUPER::logdie($msg);
}

#
# ->logdie
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with FATAL.
#
sub logdie {
    my $self = shift;
    my ($str) = @_;
    $self->emit_output('critical', "FATAL", $str) if $self->duperr;
    $self->SUPER::logdie($str);
}

#
# ->logerr
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with ERROR.
#
sub logerr {
    my $self = shift;
    my ($str) = @_;
    $self->emit_output('error', "ERROR", $str) if $self->duperr;
    $self->SUPER::logerr($str);
}

#
# ->logwarn
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with WARNING.
#
sub logwarn {
    my $self = shift;
    my ($str) = @_;
    $self->emit_output('warning', "WARNING", $str) if $self->duperr;
    $self->SUPER::logwarn($str);
}

#
# ->logxcarp
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with WARNING.
#
sub logxcarp {
    my $self = shift;
    my ($offset, $str) = @_;
    my $msg = Log::Agent::Message->make(
        $self->carpmess($offset, $str, \&Carp::shortmess)
    );
    $self->emit_output('warning', "WARNING", $msg) if $self->duperr;
    $self->SUPER::logwarn($msg);
}

#
# ->DESTROY
#
# Close all opened channels, so they may be removed from the common pool.
#
sub DESTROY {
    my $self = shift;
    my $channel_obj = $self->channel_obj;
    return unless defined $channel_obj;
    foreach my $chan (values %$channel_obj) {
        $chan->close if defined $chan;
    }
}

1;        # for require
__END__

=head1 NAME

Log::Agent::Driver::File - file logging driver for Log::Agent

=head1 SYNOPSIS

 use Log::Agent;
 require Log::Agent::Driver::File;

 my $driver = Log::Agent::Driver::File->make(
     -prefix     => "prefix",
     -duperr     => 1,
     -stampfmt   => "own",
     -showpid    => 1,
     -magic_open => 0,
     -channels   => {
        error   => '/tmp/output.err',
        output  => 'log.out',
        debug   => '../appli.debug',
     },
     -chanperm   => {
        error   => 0777,
        output  => 0666,
        debug   => 0644
     }
 );
 logconfig(-driver => $driver);

=head1 DESCRIPTION

The file logging driver redirects logxxx() operations to specified files,
one per channel usually (but channels may go to the same file).

The creation routine make() takes the following arguments:

=over 4

=item C<-channels> => I<hash ref>

Specifies where channels go. The supplied hash maps channel names
(C<error>, C<output> and C<debug>) to filenames. When C<-magic_open> is
set to true, filenames are allowed magic processing via perl's open(), so
this allows things like:

    -channels => {
        'error'   => '>&FILE',
        'output'  => '>newlog',   # recreate each time, don't append
        'debug'  => '|mailx -s whatever user',
    }

If a channel (e.g. 'output') is not specified, it will go to the 'error'
channel, and if that one is not specified either, it will go to STDERR instead.

If you have installed the additional C<Log::Agent::Rotate> module, it is
also possible to override any default rotating policy setup via the C<-rotate>
argument: instead of supplying the channel as a single string, use an array
reference where the first item is the channel file, and the second one is
the C<Log::Agent::Rotate> configuration:

    my $rotate = Log::Agent::Rotate->make(
        -backlog     => 7,
        -unzipped    => 2,
        -max_write   => 100_000,
        -is_alone    => 1,
    );

    my $driver = Log::Agent::Driver::File->make(
        ...
        -channels => {
            'error'  => ['errors', $rotate],
            'output' => ['output, $rotate],
            'debug'  => ['>&FILE, $rotate],    # WRONG
        },
        -magic_open => 1,
        ...
    );

In the above example, the rotation policy for the C<debug> channel will
not be activated, since the channel is opened via a I<magic> method.
See L<Log::Agent::Rotate> for more details.

=item C<-chanperm> => I<hash ref>

Specifies the file permissions for the channels specified by C<-channels>.
The arguemtn is a hash ref, indexed by channel name, with numeric values.
This option is only necessary to override the default permissions used by
Log::Agent::Channel::File.  It is generally better to leave these
permissive and rely on the user's umask.
See L<perlfunc(3)/umask> for more details..

=item C<-duperr> => I<flag>

When true, all messages normally sent to the C<error> channel are also
copied to the C<output> channel with a prefixing made to clearly mark
them as such: "FATAL: " for logdie(), logcroak() and logconfess(),
"ERROR: " for logerr() and "WARNING: " for logwarn().

Note that the "duplicate" is the original error string for logconfess()
and logcroak(), and is not strictly identical to the message that will be
logged to the C<error> channel.  This is a an accidental feature.

Default is false.

=item C<-file> => I<file>

This switch supersedes both C<-duperr> and C<-channels> by defining a
single file for all the channels.

=item C<-perm> => I<perm>

This switch supersedes C<-chanperm> by defining consistent for all
the channels.

=item C<-magic_open> => I<flag>

When true, channel filenames beginning with '>' or '|' are opened using
Perl's open(). Otherwise, sysopen() is used, in append mode.

Default is false.

=item C<-prefix> => I<prefix>

The application prefix string to prepend to messages.

=item C<-rotate> => I<object>

This sets a default logfile rotation policy.  You need to install the
additional C<Log::Agent::Rotate> module to use this switch.

I<object> is the C<Log::Agent::Rotate> instance describing the default
policy for all the channels.  Only files which are not opened via a
so-called I<magic open> can be rotated.

=item C<-showpid> => I<flag>

If set to true, the PID of the process will be appended within square
brackets after the prefix, to all messages.

Default is false.

=item C<-stampfmt> => (I<name> | I<CODE>)

Specifies the time stamp format to use. By default, my "own" format is used.
The following formats are available:

    date      "[Fri Oct 22 16:23:10 1999]"
    none
    own       "99/10/22 16:23:10"
    syslog    "Oct 22 16:23:10".

You may also specify a CODE ref: that routine will be called every time
we need to compute a time stamp. It should not expect any parameter, and
should return a string.

=back

=head1 CHANNELS

All the channels go to the specified files. If a channel is not configured,
it is redirected to 'error', or STDERR if no 'error' channel was configured
either.

Two channels not opened via a I<magic> open and whose logfile name is the
same are effectively I<shared>, i.e. the same file descriptor is used for
both of them. If you supply distinct rotation policies (e.g. by having a
default policy, and supplying another policy to one of the channel only),
then the final rotation policy will depend on which one was opened first.
So don't do that.

=head1 CAVEAT

Beware of chdir().  If your program uses chdir(), you should always specify
logfiles by using absolute paths, otherwise you run the risk of having
your relative paths become invalid: there is no anchoring done at the time
you specify them.  This is especially true when configured for rotation,
since the logfiles are recreated as needed and you might end up with many
logfiles scattered throughout all the directories you chdir()ed to.

Logging channels with the same pathname are shared, i.e. they are only
opened once by C<Log::Agent::Driver::File>.  Therefore, if you specify
different rotation policy to such channels, the channel opening order will
determine which of the policies will be used for all such shared channels.
Such errors are flagged at runtime with the following message:

 Rotation for 'logfile' may be wrong (shared with distinct policies)

emitted in the logs upon subsequent sharing.

=head1 AUTHORS

Originally written by Raphael Manfredi E<lt>Raphael_Manfredi@pobox.comE<gt>,
currently maintained by Mark Rogaski E<lt>mrogaski@cpan.orgE<gt>.

Thanks to Joseph Pepin for suggesting the file permissions arguments
to make().

=head1 LICENSE

Copyright (C) 1999 Raphael Manfredi.
Copyright (C) 2002 Mark Rogaski; all rights reserved.

See L<Log::Agent(3)> or the README file included with the distribution for
license information.

=head1 SEE ALSO

Log::Agent::Driver(3), Log::Agent(3), Log::Agent::Rotate(3).

=cut
