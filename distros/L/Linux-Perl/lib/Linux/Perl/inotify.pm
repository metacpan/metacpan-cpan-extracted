package Linux::Perl::inotify;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::Perl::inotify

=head1 SYNOPSIS

    my $inf = Linux::Perl::inotify->new();

    my $wd = $inf->add( path => $path, events => ['CREATE', 'ONLYDIR'] );

    my @events = $inf->read();

    $inf->remove($wd);

=head1 DESCRIPTION

This is an interface to Linux’s “inotify” feature.

=cut

use Linux::Perl;
use Linux::Perl::Constants::Fcntl;
use Linux::Perl::EasyPack;
use Linux::Perl::ParseFlags;

use parent 'Linux::Perl::Base';

*_flag_CLOEXEC = \*Linux::Perl::Constants::Fcntl::flag_CLOEXEC;
*_flag_NONBLOCK = \*Linux::Perl::Constants::Fcntl::flag_NONBLOCK;

use constant _simple_event_num => {
    ACCESS => 1,
    MODIFY => 2,
    ATTRIB => 4,
    CLOSE_WRITE => 8,
    CLOSE_NOWRITE => 16,
    OPEN => 32,
    MOVED_FROM => 64,
    MOVED_TO => 128,
    CREATE => 256,
    DELETE => 512,
    DELETE_SELF => 1024,
    MOVE_SELF => 2048,
};

use constant _read_only_event_num => (
    UNMOUNT => 0x2000,
    Q_OVERFLOW => 0x4000,
    IGNORED => 0x8000,
    ISDIR => 0x40000000,
);

use constant _shorthand_event_num => (
    CLOSE => _simple_event_num()->{'CLOSE_WRITE'} | _simple_event_num()->{'CLOSE_NOWRITE'},
    MOVE => _simple_event_num()->{'MOVED_FROM'} | _simple_event_num()->{'MOVED_TO'},
);

use constant _event_input_opts => {
    %{ _simple_event_num() },
    _shorthand_event_num(),

    ALL_EVENTS => do {
        my $num = 0;
        $num |= $_ for values %{ _simple_event_num() };
        $num;
    },
};

use constant _event_opts => {
    ONLYDIR => 0x01000000,
    DONT_FOLLOW => 0x02000000,
    EXCL_UNLINK => 0x04000000,
    MASK_CREATE => 0x10000000,
    MASK_ADD => 0x20000000,
    ONESHOT => 0x80000000,
};

=head1 METHODS

=head2 I<CLASS>->EVENT_NUMBER()

A hash reference of event names to numeric values. The member keys
are:

=over

=item * C<ACCESS>, C<MODIFY>, C<ATTRIB>

=item * C<OPEN>, C<CLOSE>, C<CLOSE_WRITE>, C<CLOSE_NOWRITE>

=item * C<MOVE>, C<MOVED_FROM>, C<MOVED_TO>, C<MOVE_SELF>

=item * C<CREATE>, C<DELETE>, C<DELETE_SELF>

=item * C<UNMOUNT>, C<Q_OVERFLOW>, C<IGNORED>, C<ISDIR>

=back

See C<man 7 inotify> for details of what these mean. This is
useful to parse the return from C<read()> (below).

=cut

use constant EVENT_NUMBER => {
    %{ _simple_event_num() },
    _read_only_event_num(),
    _shorthand_event_num(),
};

=head2 I<CLASS>->new( %OPTS )

Instantiates a new inotify instance.

%OPTS is:

=over

=item * C<flags> - Optional, an array reference of either or both of
C<NONBLOCK> and/or C<CLOEXEC>.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    $class = $class->_get_arch_module();

    my $flags = Linux::Perl::ParseFlags::parse( $class, $opts{'flags'} );

    my $fn = 'NR_inotify_init';
    $fn .= '1' if $flags;

    my $fd = Linux::Perl::call(
        $class->$fn(),
        $flags,
    );

    local $^F = 1000 if $flags & _flag_CLOEXEC();

    open my $fh, '+<&=', $fd;

    return bless [$fd, $fh], $class;
}

#----------------------------------------------------------------------

=head2 $wd = I<OBJ>->add( %OPTS )

Adds to an inotify instance and returns a watch descriptor.
See C<man 2 inotify_add_watch> for more information.

%OPTS is:

=over

=item * C<path> - The filesystem path to monitor.

=item * C<events> - An array reference of events to monitor for.
Recognized events are:

=over

=item * C<ACCESS>, C<MODIFY>, C<ATTRIB>

=item * C<OPEN>, C<CLOSE>, C<CLOSE_WRITE>, C<CLOSE_NOWRITE>

=item * C<MOVE>, C<MOVED_FROM>, C<MOVED_TO>, C<MOVE_SELF>

=item * C<CREATE>, C<DELETE>, C<DELETE_SELF>

=item * C<UNMOUNT>, C<Q_OVERFLOW>, C<IGNORED>, C<ISDIR>

=item * C<ALL_EVENTS>

=item * C<ONLYDIR>, C<DONT_FOLLOW>, C<EXCL_UNLINK>, C<MASK_CREATE>,
C<MASK_ADD>, C<ONESHOT>

=back

Note that your kernel may not recognize all of these.

=back

=cut

sub add {
    my ($self, %opts) = @_;

    my $path = $opts{'path'};
    if (!defined $path || !length $path) {
        die 'Need path!';
    }

    my $events_mask = Linux::Perl::EventFlags::events_flags_to_num(
        $opts{'events'},
        _event_input_opts(),
        _event_opts(),
    );

    return Linux::Perl::call(
        $self->NR_inotify_add_watch(),
        0 + $self->[0],
        $path,
        0 + $events_mask,
    );
}

#----------------------------------------------------------------------

=head2 I<OBJ>->fileno()

Returns the inotify instance’s file descriptor number.

=cut

sub fileno { return $_[0][0] }

#----------------------------------------------------------------------

my ($inotify_keys_ar, $inotify_pack, $inotify_sizeof);
BEGIN {
    ($inotify_keys_ar, $inotify_pack) = Linux::Perl::EasyPack::split_pack_list(
        wd => 'i!',     #int
        mask => 'L',    #uint32_t
        cookie => 'L',  #uint32_t
        name => 'L/a',  #uint32_t & char[]
    );

    $inotify_sizeof = length pack $inotify_pack;
}

=head2 @events = I<OBJ>->read()

Reads events from the inotify instance. Each event is returned as
a hash reference with members C<wd>, C<mask>, C<cookie>, and C<name>.
See C<man 7 inotify> for details about what these mean. (Use the
members of C<EVENT_NUMBER()> above to parse C<mask>.)

Note that if the underlying inotify object is not set C<NONBLOCK>
then this call will block until there is an inotify event to read.

In scalar context this returns the number of events that happened.

An empty return here indicates a read failure; C<$!> will contain the
usual information about the failure.

=cut

sub read {
    my ($self) = @_;

    my @events;

    my $res = sysread $self->[1], my $buf, 65536;

    if (defined $res) {
        while (my @els = unpack $inotify_pack, $buf) {
            my %evt;
            @evt{ @$inotify_keys_ar } = @els;

            substr( $buf, 0, $inotify_sizeof + length $els[-1] ) = q<>;

            $evt{'name'} =~ tr<\0><>d if $evt{'name'};

            push @events, \%evt;

            # Perl 5.16 and previous choke with:
            #
            #   '/' must follow a numeric type in unpack
            #
            # » unless we avoid unpack() on an empty string.
            last if !$buf;
        }
    }

    return @events;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->remove( $WD )

Analogous to C<man 2 inotify_rm_watch>.

=cut

sub remove {
    my ($self, $wd) = @_;

    Linux::Perl::call(
        $self->NR_inotify_rm_watch(),
        0 + $self->[0],
        0 + $wd,
    );

    return $self;
}

#----------------------------------------------------------------------

package Linux::Perl::EventFlags;

sub events_flags_to_num {
    my ($input_ar, @names_to_nums) = @_;

    my $mask = 0;

  EVENT:
    for my $evt (@$input_ar) {
        for my $name_to_num_hr (@names_to_nums) {
            my $num = $name_to_num_hr->{$evt} or next;
            $mask |= $num;
            next EVENT;
        }

        die "Unknown event or flag: $evt";
    }

    return $mask;
}

1;
