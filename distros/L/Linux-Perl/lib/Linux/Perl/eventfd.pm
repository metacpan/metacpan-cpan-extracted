package Linux::Perl::eventfd;

=encoding utf-8

=head1 NAME

Linux::Perl::eventfd

=head1 SYNOPSIS

    my $efd = Linux::Perl::eventfd->new(
        initval => 4,
        flags => [ 'NONBLOCK', 'CLOEXEC' ], #only on 2.6.27+
    );

    #or, e.g., Linux::Perl::eventfd::x86_64

    my $fd = $efd->fileno();

    $efd->add(12);

    my $read = $efd->read();

=head1 DESCRIPTION

This is an interface to the C<eventfd>/C<eventfd2> system call.
(C<eventfd2> is only called if the given parameters require it.)

=cut

use strict;
use warnings;

use Module::Load;

use Linux::Perl;
use Linux::Perl::Constants;
use Linux::Perl::Constants::Fcntl;
use Linux::Perl::Endian;

use constant {
    flag_SEMAPHORE => 1,
    PERL_CAN_64BIT => !!do { local $@; eval { pack 'Q', 1 } },
};

*flag_CLOEXEC = *Linux::Perl::Constants::Fcntl::flag_CLOEXEC;
*flag_NONBLOCK = *Linux::Perl::Constants::Fcntl::flag_NONBLOCK;

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

%OPTS is:

=over

=item * C<initval> - Optional, as described in the eventfd documentation.
Defaults to 0.

=item * C<flags> - Optional, an array reference of any or all of:
C<NONBLOCK>, C<CLOEXEC>, C<SEMAPHORE>. See C<man 2 eventfd> for
more details.

Note that, in conformity with Perl convention, this module honors
the $^F variable, which in its default configuration causes CLOEXEC
even if the flag is not given. To have a non-CLOEXEC eventfd instance,
then, set $^F to a high enough value that the eventfd file descriptor
will not be an “OS” filehandle, e.g.:

    my $eventfd = do {
        local $^F = 1000;
        Linux::Perl::eventfd->new();
    };

=back

=cut

sub new {
    my ($class, %opts) = @_;

    local ($!, $^E);

    my $arch_module = $class->can('NR_eventfd') && $class;
    $arch_module ||= do {
        require Linux::Perl::ArchLoader;
        Linux::Perl::ArchLoader::get_arch_module($class);
    };

    my $initval = 0 + ( $opts{'initval'} || 0 );

    my $is_cloexec;

    my $flags = 0;
    if ( $opts{'flags'} ) {
        for my $fl ( @{ $opts{'flags'} } ) {
            my $val_cr = $arch_module->can("flag_$fl") or do {
                die "unknown flag: “$fl”";
            };
            $flags |= $val_cr->();

            $is_cloexec = 1 if $fl eq 'CLOEXEC';
        }
    }

    my $call = 'NR_' . ($flags ? 'eventfd2' : 'eventfd');

    my $fd = Linux::Perl::call( 0 + $arch_module->$call(), $initval, $flags || () );

    #Force CLOEXEC if the flag was given.
    local $^F = 0 if $is_cloexec;

    open my $fh, '+<&=' . $fd;

    return bless [$fh], $arch_module;
}

=head2 I<OBJ>->fileno()

Returns the file descriptor number.

=cut

sub fileno { fileno $_[0][0] }

=head2 $val = I<OBJ>->read()

Reads a value from the eventfd instance. Sets C<$!> and returns undef
on error.

=cut

my ($big, $low);

sub read {
    return undef if !sysread $_[0][0], my $buf, 8;

    if (PERL_CAN_64BIT) {
        ($big, $low) = (0, unpack('Q', $buf));
    }
    else {
        if (Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN) {
            ($big, $low) = unpack 'NN', $buf;
        }
        else {
            ($low, $big) = unpack 'VV', $buf;
        }

        #TODO: Need to test what happens on a 32-bit Perl.
        die "No 64-bit support! (high=$big, low=$low)" if $big;
    }

    return $low;
}

=head2 I<OBJ>->add( NUMBER )

Adds NUMBER to the counter.

=cut

my $packed;

sub add {
    if (PERL_CAN_64BIT) {
        $packed = pack 'Q', $_[1];
    }
    elsif (Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN) {
        $packed = pack 'x4N', $_[1];
    }
    else {
        $packed = pack 'Vx4', $_[1];
    }

    return syswrite( $_[0][0], $packed ) && 1;
}

1;
