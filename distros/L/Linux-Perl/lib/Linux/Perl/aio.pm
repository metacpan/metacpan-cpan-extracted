package Linux::Perl::aio;

=encoding utf-8

=head1 NAME

Linux:Perl::aio - asynchronous I/O

=head1 SYNOPSIS

    #Platform-specific invocation uses e.g.:
    #   Linux::Perl::aio::x86_64->new(...)
    #   Linux::Perl::aio::Control::x86_64->new(...)

    my $aio = Linux::Perl::aio->new(16);

    my $ctrl = Linux::Perl::aio::Control->new(
        $filehandle,
        \$buffer,
        lio_opcode => 'PREAD',
    );

    #Multiple $ctrl objects can be submitted in a list.
    $aio->submit($ctrl);

    my @events = $aio->getevents( $min, $max, $timeout );

=head1 DESCRIPTION

This module provides support for the kernel-level AIO interface.

DESTROY handlers are provided for automatic reaping of unused
instances/contexts.

This module is EXPERIMENTAL. For now only the C<x86_64> architecture
is supported; others may follow, though 32-bit architectures would
take a bit more work.

=cut

use strict;
use warnings;

use Linux::Perl;
use Linux::Perl::EasyPack;
use Linux::Perl::TimeSpec;

use parent qw(
    Linux::Perl::Base
    Linux::Perl::Base::BitsTest
);

my ($io_event_keys_ar, $io_event_pack, $io_event_size);

BEGIN {
    my @_io_event_src = (
        data => __PACKAGE__->_PACK_u64(),
        obj  => __PACKAGE__->_PACK_u64(),
        res  => __PACKAGE__->_PACK_i64(),
        res2 => __PACKAGE__->_PACK_i64(),
    );

    ($io_event_keys_ar, $io_event_pack) = Linux::Perl::EasyPack::split_pack_list(@_io_event_src);
    $io_event_size = length pack $io_event_pack;
}

=head1 METHODS

=head2 I<CLASS>->new( NR_EVENTS )

Calls C<io_setup> with the referred number of events to create
an AIO context. An object of CLASS is returned.

=cut

sub new {
    my ( $class, $nr_events ) = @_;

    die "Need number of events!" if !$nr_events;

    $class = $class->_get_arch_module();

    my $context = "\0" x 8;

    Linux::Perl::call( $class->NR_io_setup(), 0 + $nr_events, $context );

    $context = unpack $class->_PACK_u64(), $context;

    return bless \$context, $class;
}

=head2 I<CLASS>->create_control( FILEHANDLE, BUFFER_SR, %OPTS )

Returns an instance of the relevant L<Linux::Perl::aio::Control>
subclass for your architecture.

FILEHANDLE is a Perl filehandle object, and BUFFER_SR is a reference
to the buffer string. This buffer must be pre-initialized to at least
the needed/desired length.

%OPTS is:

=over

=item * C<lio_opcode>: Required, one of: C<PREAD>, C<PWRITE>, C<FSYNC>,
C<FDSYNC>, C<NOOP>, C<PREADV>, C<PWRITEV>.

=item * C<buffer_offset>: The byte offset in BUFFER_SR at which to start
the I/O operation. Defaults to 0.

=item * C<nbytes>: The number of bytes on which to operate. This value
plus C<buffer_offset> must be less than the length of BUFFER_SR. Defaults
to length(BUFFER_SR) minus C<buffer_offset>.

=item * C<rw_flags>: Optional, an array reference of any or all of: C<HIPRI>,
C<DSYNC>, C<SYNC>, C<NOWAIT>, C<APPEND>. Not supported in all kernel versions;
in fact, support seems more the exception than the rule!
See the kernel documentation (e.g., C<RWF_HIPRI>) for details on
what these flags mean and whether your system supports them.

=item * C<reqprio>: Optional. See the kernel’s documentation.

=item * C<eventfd>: Optional, an eventfd file descriptor
(i.e., unsigned integer) to receive updates when aio events are finished.
(See L<Linux::Perl::eventfd> for one way of making this work.)

=back

For more information, consult the definition and documentation
for struct C<iocb>. (cf. F<include/linux/aio_abi.h>)

=cut

sub create_control {
    my $self = shift;

    return Linux::Perl::aio::Control->new(@_);
}

=head2 $num = I<OBJ>->submit( CTRL1, CTRL2, .. )

Calls C<io_submit>. Each CTRL* is an instance of
L<Linux::Perl::aio::Control> and represets an I/O request.

The return value is the number of control objects submitted.

=cut


sub submit {
    my ( $self, @control_objs ) = @_;

    my $ptrs = join( q<>, map { $_->pointer() } @control_objs );

    return Linux::Perl::call( $self->NR_io_submit(), 0 + $$self, 0 + @control_objs, $ptrs );
}

=head2 @events = I<OBJ>->getevents( MIN, MAX, TIMEOUT )

Calls C<io_getevents> with the relevant minimum, maximum, and timeout
values. (TIMEOUT can be a float.)

If more than one event is requested (i.e., MAX > 1), then list
context is required.

The return is a list of hash references; each hash reference has the following
values as in the kernel C<io_event> struct:

=over

=item * C<data>

=item * C<obj> (corresponds to the Control instance C<id()>)

=item * C<res>

=item * C<res2>

=back

=cut

sub getevents {
    my ( $self, $min_events, $max_events, $timeout ) = @_;

    #If they only asked for one, then allow scalar context.
    if ($max_events > 1) {
        require Call::Context;
        Call::Context::must_be_list();
    }

    if (!$max_events) {
        die '$max_events must be >0!';
    }

    my $buf = "\0" x ( $max_events * $io_event_size );

    my $evts = Linux::Perl::call(
        $self->NR_io_getevents(),
        $$self,
        0 + $min_events,
        0 + $max_events,
        $buf,
        Linux::Perl::TimeSpec::from_float($timeout),
    );

    my @events;
    for my $idx ( 0 .. ( $evts - 1 ) ) {
        my @data = unpack $io_event_pack, substr( $buf, $idx * $io_event_size, $io_event_size );
        my %event;
        @event{ @$io_event_keys_ar } = @data;
        push @events, \%event;
    }

    return wantarray ? @events : $events[0];
}

sub DESTROY {
    my ($self) = @_;

    Linux::Perl::call( $self->NR_io_destroy(), 0 + $$self);

    return;
}

#----------------------------------------------------------------------

package Linux::Perl::aio::Control;

use Linux::Perl::EasyPack;
use Linux::Perl::Endian;

=encoding utf-8

=head1 NAME

Linux::Perl::aio::Control

=head1 SYNOPSIS

    my $ctrl = Linux::Perl::aio::Control->new(
        $filehandle,
        \$buffer,
        lio_opcode => 'PREAD',
        buffer_offset => 4,
        nbytes => 2,
    );

=head1 DESCRIPTION

This class encapsulates a kernel C<iocb> struct, i.e., an I/O request.

You should not instantiate it directly; instead, use
L<Linux::Perl::aio>’s C<create_control()> method.

=cut

use parent -norequire => 'Linux::Perl::Base::BitsTest';

use Linux::Perl::Pointer ();

use constant {
    _RWF_HIPRI  => 1,
    _RWF_DSYNC  => 2,
    _RWF_SYNC   => 4,
    _RWF_NOWAIT => 8,
    _RWF_APPEND => 16,

    _IOCB_CMD_PREAD  => 0,
    _IOCB_CMD_PWRITE => 1,
    _IOCB_CMD_FSYNC  => 2,
    _IOCB_CMD_FDSYNC => 3,

    #experimental
    #_IOCB_CMD_PREADX => 4,
    #_IOCB_CMD_POLL => 5,

    _IOCB_CMD_NOOP    => 6,
    _IOCB_CMD_PREADV  => 7,
    _IOCB_CMD_PWRITEV => 8,

    _IOCB_FLAG_RESFD => 1,
};

my ($iocb_keys_ar, $iocb_pack);

BEGIN {
    my @_iocb_src = (
        data => __PACKAGE__->_PACK_u64(),    #aio_data

        (
            Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN()
            ? (
                rw_flags => 'L',
                key => 'L',
            )
            : (
                key => 'L',
                rw_flags => 'L',
            )
        ),

        lio_opcode => 'S',
        reqprio    => 's',
        fildes     => 'L',

        #Would be a P, but we grab the P and do some byte arithmetic on it
        #for the case of a buffer_offset.
        buf => __PACKAGE__->_PACK_u64(),

        nbytes => __PACKAGE__->_PACK_u64(),

        offset => __PACKAGE__->_PACK_i64(),

        reserved2 => 'x8',

        flags => 'L',
        resfd => 'L',
    );

    ($iocb_keys_ar, $iocb_pack) = Linux::Perl::EasyPack::split_pack_list(@_iocb_src);
}

=head1 METHODS

=head2 I<CLASS>->new( FILEHANDLE, BUFFER_SR, %OPTS )

=cut

sub new {
    my ( $class, $fh, $buf_sr, %args ) = @_;

    my $opcode = $args{'lio_opcode'} or do {
        die "Need “lio_opcode”!";
    };

    my $opcode_cr = $class->can("_IOCB_CMD_$opcode") or do {
        die "Unknown “lio_opcode” ($opcode)";
    };

    my %opts;
    @opts{'nbytes', 'buffer_offset'} = @args{'nbytes', 'buffer_offset'};

    $opts{'lio_opcode'} = 0 + $opcode_cr->();
    $opts{'fildes'}     = fileno $fh;
    $opts{'reserved2'} = 0;
    $opts{'reqprio'} = $args{'reqprio'};

    if ($args{'rw_flags'}) {
        my $flag = 0;
        for my $flag_name ( @{ $args{'rw_flags'} } ) {
            my $num = $class->can("_RWF_$flag_name") or do {
                die "Unknown -rw_flags- value ($flag_name)";
            };
            $flag |= 0 + $num->();
        }

        $opts{'rw_flags'} = $flag;
    }

    if (defined $args{'eventfd'}) {
        $opts{'flags'} = _IOCB_FLAG_RESFD;
        $opts{'resfd'} = $args{'eventfd'};
    }

    my $buf_ptr = Linux::Perl::Pointer::get_address($$buf_sr);

    my $buffer_offset = $opts{'buffer_offset'} || 0;

    if ( $opts{'buffer_offset'} ) {
        $opts{'nbytes'} ||= length($$buf_sr) - $opts{'buffer_offset'};

        $buf_ptr += $opts{'buffer_offset'};
    }
    else {
        $opts{'nbytes'} ||= length $$buf_sr;
    }

    if ( $opts{'nbytes'} + $buffer_offset > length $$buf_sr ) {
        die sprintf( "nbytes($opts{'nbytes'}) + buffer_offset($buffer_offset) > buffer_length(%d)", length $$buf_sr );
    }

    $opts{'buf'} = $buf_ptr;

    $_ ||= 0 for @opts{ @$iocb_keys_ar };

    my $packed = pack $iocb_pack, @opts{ @$iocb_keys_ar };
    my $ptr = pack 'P', $packed;

    #We need $packed not to be garbage-collected.
    return bless [ \$packed, $buf_sr, $ptr, unpack( Linux::Perl::Pointer::UNPACK_TMPL(), $ptr) ], $class;
}

=head2 $sref = I<OBJ>->buffer_sr()

Returns the string buffer reference given originally to C<new()>.

=cut

sub buffer_sr { return $_[0][1] }

=head2 $sref = I<OBJ>->pointer()

Returns the internal C<iocb>’s memory address as an octet string.

=cut

sub pointer { return $_[0][2] }

=head2 $sref = I<OBJ>->id()

Returns the internal C<iocb>’s ID.

=cut

sub id { return $_[0][3] }

1;
