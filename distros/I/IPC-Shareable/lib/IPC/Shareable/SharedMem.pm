package IPC::Shareable::SharedMem;

use warnings;
use strict;

use Carp qw(carp croak confess);
use Config;
use Errno qw(EEXIST EPERM);
use IPC::SysV qw(IPC_RMID IPC_STAT);

our $VERSION = '1.16';

use constant {
    DEFAULT_SEG_SIZE    => 1024,
    DEFAULT_SEG_FLAGS   => 0000,
    DEFAULT_SEG_MODE    => 0666,
};

{
    package IPC::Shareable::SharedMem::stat;

    use Class::Struct qw(struct);

    struct 'IPC::Shareable::SharedMem::stat' => [
        uid     => '$',
        gid     => '$',
        cuid    => '$',
        cgid    => '$',
        mode    => '$',
        segsz   => '$',
        lpid    => '$',
        cpid    => '$',
        nattch  => '$',
        atime   => '$',
        dtime   => '$',
        ctime   => '$',
    ];
}

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    if (defined $params{key} && $params{key} =~ /^0x[0-9a-fA-F]+$/i) {
        $params{key} = hex($params{key});
    }

    if (! defined $params{key} || $params{key} !~ /^\d+$/) {
        croak "new() requires a 'key' parameter with an integer value";
    }

    $self->key($params{key});
    $self->key_hex($self->key);

    $self->size($params{size} || DEFAULT_SEG_SIZE);

    $self->mode($params{mode} || DEFAULT_SEG_MODE);
    $self->flags(($params{flags} || DEFAULT_SEG_FLAGS) | $self->mode);

    $self->type($params{type});

    my $id = shmget($self->key, $self->size, $self->flags);

    defined $id or do {
        my $key = $self->key_hex;

        if ($!) {
            if ($!{EEXIST} || $!{EPERM}) {
                croak "\nERROR: IPC::Shareable::SharedMem: shmget $key: $!\n\n" .
                    "Are you using exclusive, but trying to create multiple " .
                    "instances?\n\n";
            }

            return undef;
        }
    };

    $self->id($id);

    return $self;
}
sub id {
    my ($self, $id) = @_;

    if (defined $id) {
        if ($self->{id}) {
            warn "Can't set id() after object already instantiated";
            return $self->{id};
        }
        $self->{id} = $id;
    }
    return $self->{id};
}
sub key {
    my ($self, $key) = @_;

    if (defined $key) {
        if ($self->id) {
            croak "Can't set the 'key' attribute after object is already established";
        }

        $self->{key} = $key;
    }

    return $self->{key};
}
sub key_hex {
    my ($self, $key_int) = @_;

    if (defined $key_int) {
        $self->{key_hex} = sprintf "0x%08x", $key_int;
    }

    return $self->{key_hex};
}
sub flags {
    my ($self, $flags) = @_;

    if (defined $flags) {
        if ($self->id) {
            warn "Can't set flags() after object already instantiated";
            return $self->{flags};
        }

        $self->{flags} = $flags;
    }
    return $self->{flags};
}
sub mode {
    my ($self, $mode) = @_;

    if (defined $mode) {
        if ($self->id) {
            warn "Can't set mode() after object already instantiated";
            return $self->{mode};
        }

        $self->{mode} = $mode;
    }

    return $self->{mode};
}
sub size {
    my ($self, $size) = @_;

    if (defined $size) {
        if ($self->id) {
            warn "Can't set size() after object already instantiated";
            return $self->{size};
        }
        if ($size !~ /^\d+$/) {
            croak "size() requires an integer as parameter";
        }

        $self->{size} = $size;
    }
    return $self->{size};
}
sub type {
    my ($self, $type) = @_;

    if (defined $type) {
        if ($self->id) {
            warn "Can't set type() after object already instantiated";
            return $self->{type};
        }

        $self->{type} = $type;
    }

    return $self->{type};
}
sub data {
    my ($self) = @_;

    my $data = $self->shmread;

    return if ! defined $data;

    my $pos = index($data, "\x00");
    $data = $pos >= 0 ? substr($data, 0, $pos) : $data;

    return $data;
}
sub stat {
    my ($self) = @_;
    my $data = '';
    shmctl($self->id, IPC_STAT, $data) or return undef;

    my %values;

    if ($^O eq 'linux') {
        if ($Config{longsize} == 8) {
            # 64-bit Linux: ipc64_perm is 48 bytes.
            #   ipc64_perm: key(4) uid(4) gid(4) cuid(4) cgid(4) mode(4)
            #               seq(2) pad2(2) [4-byte align-pad] unused1(8) unused2(8)
            # shmid_ds: segsz(8) atime(8) dtime(8) ctime(8) cpid(4) lpid(4) nattch(8)

            @values{qw(uid gid cuid cgid mode segsz atime dtime ctime cpid lpid nattch)}
                = unpack('x[4] L L L L L x[24] Q q q q l l Q', $data);
        }
        else {
            # 32-bit Linux: ipc64_perm is 36 bytes (unsigned long = 4 bytes).
            #   ipc64_perm: key(4) uid(4) gid(4) cuid(4) cgid(4) mode(4)
            #               seq(2) pad2(2) unused1(4) unused2(4)
            # shmid_ds: segsz(4) atime(4) atime_nsec(4) dtime(4) dtime_nsec(4)
            #           ctime(4) ctime_nsec(4) cpid(4) lpid(4) nattch(4)

            @values{qw(uid gid cuid cgid mode segsz atime dtime ctime cpid lpid nattch)}
                = unpack('x[4] L L L L L x[12] L L x[4] L x[4] L x[4] l l L', $data);
        }
    }
    elsif ($^O eq 'freebsd' && $Config{longsize} == 8) {
        # 64-bit FreeBSD: ipc_perm is 32 bytes.
        # ipc_perm: cuid(4) cgid(4) uid(4) gid(4) mode(2) _seq(2) pad(4) _key(8)
        # shmid_ds: segsz(8) lpid(4) cpid(4) nattch(8) atime(8) dtime(8) ctime(8)
        # (key_t = long = 8 bytes on FreeBSD 64-bit, with 4 bytes of alignment padding)

        @values{qw(cuid cgid uid gid mode segsz lpid cpid nattch atime dtime ctime)}
            = unpack('L L L L S x[14] Q l l Q q q q', $data);
    }
    elsif ($^O eq 'solaris') {
        if ($Config{longsize} == 8) {
            # 64-bit Solaris/illumos _LP64 shmid_ds (136 bytes on OmniOS r151058):
            #   ipc_perm (28 bytes): uid(4) gid(4) cuid(4) cgid(4) mode(4) seq(4) key(4)
            #   [pad 4] segsz(8) [gap 8] lkcnt(2) [pad 2] lpid(4) cpid(4)
            #   [pad 4] nattch(8) cnattch(8) atime(8) dtime(8) ctime(8)
            #   shmatt_t = 8 bytes  mode_t = uint_t = 4 bytes
            #   Offsets verified on OmniOS r151058 via offsetof().

            @values{qw(uid gid cuid cgid mode segsz lpid cpid nattch atime dtime ctime)}
                = unpack('L L L L L x[12] Q x[12] l l x[4] Q x[8] q q q', $data);
        }
        else {
            # 32-bit Solaris/illumos shmid_ds (108 bytes):
            #   ipc_perm (44 bytes): uid(4) gid(4) cuid(4) cgid(4) mode(4) seq(4) key(4) pad[4](16)
            #   segsz(4) lpid(4) cpid(4) lkcnt(2) [pad 2] nattch(4) cnattch(4)
            #   atime(4) pad1(4) dtime(4) pad2(4) ctime(4) pad3(4) pad4[4](16)
            #   mode_t = uint_t = 4 bytes

            @values{qw(uid gid cuid cgid mode segsz lpid cpid nattch atime dtime ctime)}
                = unpack('L4 L x[24] L l l x[4] L x[4] l x[4] l x[4] l x[20]', $data);
        }
    }
    elsif ($^O eq 'openbsd' && $Config{longsize} == 8) {
        # 64-bit OpenBSD shmid_ds (104 bytes), struct layout from sys/shm.h:
        #   ipc_perm (32 bytes): uid(4) gid(4) cuid(4) cgid(4) mode(4/int)
        #             +12 bytes (key/seq/pad)
        #   segsz(4/int) lpid(4/pid_t) cpid(4/pid_t) nattch(2/shmatt_t) [pad 2]
        #   atime(8/time_t) __shm_atimensec(8/long)
        #   dtime(8/time_t) __shm_dtimensec(8/long)
        #   ctime(8/time_t) __shm_ctimensec(8/long)
        #   shm_internal(8/ptr)

        @values{qw(uid gid cuid cgid mode segsz lpid cpid nattch atime dtime ctime)}
            = unpack('L L L L L x[12] L l l S x[2] q x[8] q x[8] q', $data);
    }
    elsif ($^O eq 'dragonfly' && $Config{longsize} == 8) {
        # 64-bit DragonFly BSD shmid_ds (sys/sys/shm.h, sys/sys/ipc.h).
        # ipc_perm (28 bytes):
        #   uid(4) gid(4) cuid(4) cgid(4) mode(4) _seq(2) [2 pad] _key(4)
        # [4 pad to align segsz]
        # shmid_ds:
        #   segsz(8) lpid(4) cpid(4) nattch(8)
        #   atime(8) [atimensec(8)?] dtime(8) [dtimensec(8)?] ctime(8)
        #
        # Some DragonFly versions include __shm_*timensec fields (108 bytes
        # total), others omit them (88 bytes).  Detect via data length.

        if (length($data) > 96) {
            @values{qw(uid gid cuid cgid mode segsz lpid cpid nattch atime dtime ctime)}
                = unpack('L L L L L x[12] Q l l Q q x[8] q x[8] q', $data);
        }
        else {
            @values{qw(uid gid cuid cgid mode segsz lpid cpid nattch atime dtime ctime)}
                = unpack('L L L L L x[12] Q l l Q q q q', $data);
        }
    }
    else {
        # macOS shmid_ds / ipc_perm layout (XNU kernel):
        #
        # ipc_perm (24 bytes): uid(4) gid(4) cuid(4) cgid(4) mode(2/ushort) seq(2) key(4)
        # shmid_ds: segsz(8) lpid(4) cpid(4) nattch(2/ushort) [pad 2] atime(8) dtime(8) ctime(8)
        #
        # Fields happen to match stat_list() order, so a linear unpack works.

        @values{stat_list()} = unpack('L L L L S x[6] Q l l S x[2] q q q', $data);
    }

    my @struct_initializers;
    for (stat_list()) {
        my $value = $values{$_};
        if ($_ eq 'mode') {
            $value = $value & 0777;
            push @struct_initializers, $_ => sprintf("%#o", $value);
        }
        else {
            push @struct_initializers, $_ => $value;
        }
    }

    return IPC::Shareable::SharedMem::stat->new(@struct_initializers);
}
sub stats {
    my ($self) = @_;
    my @stat_list = stat_list();

    my $stat = $self->stat;

    my %stats;

    for (@stat_list) {
        $stats{$_} = $stat->$_;
    }

    return \%stats;
}
sub stat_list {
    return qw(
        uid
        gid
        cuid
        cgid
        mode
        segsz
        lpid
        cpid
        nattch
        atime
        dtime
        ctime
    );
}

sub shmread {
    my ($self) = @_;

    my $data = '';
    shmread($self->id, $data, 0, $self->size) or return;
    return $data;
}
sub shmwrite {
    my($self, $data) = @_;
    return shmwrite($self->id, $data, 0, $self->size);
}
sub remove {
    my ($self) = @_;
    my $os_return_value = shmctl($self->id, IPC_RMID, 0);

    if (defined $os_return_value && ($os_return_value eq '0 but true' || $os_return_value == 1)) {
        return 1;
    }
    else {
        return 0;
    }
}

1;

=head1 NAME

IPC::Shareable::SharedMem - Allows access to a shared memory segment via an
object oriented interface.

=head1 DESCRIPTION

This module provides object oriented access to a shared memory segment. Although
it can be used standalone, it was designed for use specifically within the
L<< IPC::Shareable >> library.

=for html
<a href="https://github.com/stevieb9/ipc-shareable/actions"><img src="https://github.com/stevieb9/ipc-shareable/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/ipc-shareable?branch=master'><img src='https://coveralls.io/repos/stevieb9/ipc-shareable/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use IPC::Shareable::SharedMem;

    my $seg = IPC::Shareable::SharedMem->new(
        key  => 1234,
        size => 65536,
    );

    $seg->shmwrite($data);

    my $data = $seg->data;

=head1 METHODS

=head2 new(%params)

Instantiates and returns an object that represents a shared memory segment.

If for any reason we can't create the shared memory segment, we'll return
C<undef>.

Parameters (must be in key => value pairs):

=head3 key

I<< Mandatory, Integer >>: An integer that references the shared memory segment.

=head3 size

I<Optional, Integer>: An integer representing the size in bytes of the
shared memory segment. The maximum is Operating System independent.

I<Default>: 1024

=head3 flags

I<Optional, Bitwise Mask>: A bitwise mask of options logically OR'd together
with any or all of C<IPC_CREAT> (create segment if it doesn't exist),
C<IPC_EXCL> (exclusive access; if the segment already exists,
we'll C<croak>) and C<IPC_RDONLY> (create a read only segment).

See L<IPC::SysV> for further details.

I<Default>: C<0> (ie. no flags).

=head3 mode

I<Optional, Octal Integer>: An octal number representing the access permissions
for the shared memory segment. Exactly the same as a Unix file system
permissions.

I<Default>: 0666 (User RW, Group RW, World RW).

=head3 type

I<Optional, String>: The type of data that will be stored in the shared memory
segment. L<IPC::Shareable> uses C<SCALAR>, C<ARRAY> or C<HASH>.

=head2 id

Sets/gets the identification number that references the shared memory segment.

A warning will be thrown if you try to set the ID after the object is already
instantiated, and no change will occur.

=head2 key

Sets/gets the key used to identify the shared memory segment.

Setting this attribute should only be done internally. If it is sent in after
the object is already associated with a shared memory segment, we will C<croak>.

See L</key> for further details.

=head2 key_hex($key)

Returns the hex formatted key which appears in C<ipcs> calls.

Parameters:

=head3 $key

I<< Optional, String >>: This is always sent in during initialization.

=head2 size

Sets/gets the size of the shared memory segment in bytes. See L</size> for
further details.

A warning will be thrown if you try to set the size after the object is already
instantiated, and no change will occur.

=head2 flags

Sets/gets the flags that the segment will be created with. See L</flags> for
details.

A warning will be thrown if you try to set the flags after the object is already
instantiated, and no change will occur.

=head2 mode

Sets/gets the access permissions. See L</mode> for further details.

A warning will be thrown if you try to set the mode after the object is already
instantiated, and no change will occur.

=head2 type

Sets/gets the type of data that will be contained in the shared memory segment.
See L</type> for details.

A warning will be thrown if you try to set the type after the object is already
instantiated, and no change will occur.

=head2 data

Returns the data in the shared memory segment, with all NULL pad bytes removed.

Use this method for text data. For binary data where you need all blocks within
the segment, use the L</shmread> method.

=head2 stat

This method has sub methods that display various system-level information about
the memory segment. These sub methods are:

    uid
    gid
    cuid
    cgid
    mode
    segsz
    lpid
    cpid
    nattch
    atime
    dtime
    ctime

Example call:

    my $ctime = $seg->stat->ctime;

=head2 stats

Returns an href of the various system-level stat information:

    {
        uid     => 501,
        gid     => 20,
        cuid    => 501,
        cgid    => 20,
        mode    => 0666,
        segsz   => 65536,
        lpid    => 61270,
        cpid    => 61270,
        nattch  => 0,
        atime   => 1778791348,
        dtime   => 1778791348,
        ctime   => 1778791348,
    }

=head2 stat_list

Returns an array of all the segment's system stat entries. These are what make
up the method names of the C<< $seg->stat >> object.

=head2 shmread

Returns the data (and NULL pad bytes) stored in the shared memory segment.

By default, when data is retrieved from the shared memory segment, the data
is padded to the right by NULL bytes to fill up the entire size of the segment.
This can cause issues when using the space for non serialized data (ie. if you
stored "hello" in a 1024 byte segment, the ASCII text wouldn't match).

Typically this method is used when you want all blocks of the segment, such as
if you've stored binary data.

For text/ASCII data, use the L</data> method which automatically strips NULL
pad bytes.

I<Return>: The data if any is stored, empty string if no data has been stored
yet, and C<undef> if a failure to read occurs.

=head2 shmwrite($data)

Stores the serialized data to the shared memory segment.

Parameters:

    $data

I<Mandatory, String>: Typically, the a serialized data structure.

I<Return>: True on success, false on failure.

=head2 remove

Removes the shared memory segment and returns the resources to the system.

I<Return>: True (C<1>) on success, false (C<0>) on failure.

=head1 AUTHOR

Ben Sugars (bsugars@canoe.ca)

=head1 MAINTAINED BY

Steve Bertrand <steveb@cpan.org>

=head1 SEE ALSO

L<IPC::Shareable>, L<IPC::Shareable::SharedMem>, L<IPC::ShareLite>

=cut
