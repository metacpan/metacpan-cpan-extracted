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

This class inherits from L<Linux::Perl::Base::TimerEventFD>.

=cut

use strict;
use warnings;

use parent (
    'Linux::Perl::Base',
    'Linux::Perl::Base::TimerEventFD',
);

use Module::Load;

use Linux::Perl;

use Linux::Perl::Endian;
use Linux::Perl::ParseFlags;

use constant {
    _flag_SEMAPHORE => 1,
};

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

    my $arch_module = $class->_get_arch_module();

    my $initval = 0 + ( $opts{'initval'} || 0 );

    my $flags = Linux::Perl::ParseFlags::parse($arch_module, $opts{'flags'});

    my $call = 'NR_' . ($flags ? 'eventfd2' : 'eventfd');

    my $fd = Linux::Perl::call( 0 + $arch_module->$call(), $initval, $flags || () );

    #Force CLOEXEC if the flag was given.
    local $^F = 0 if $flags & $arch_module->_flag_CLOEXEC();

    open my $fh, '+<&=' . $fd;

    return bless [$fh], $arch_module;
}

#----------------------------------------------------------------------

=head2 $val = I<OBJ>->read()

Reads a value from the eventfd instance. Sets C<$!> and returns undef
on error.

=cut

*read = __PACKAGE__->can('_read');

#----------------------------------------------------------------------

=head2 I<OBJ>->add( NUMBER )

Adds NUMBER to the counter. Returns undef and sets C<$!> on failure.

=cut

my $packed;

sub add {
    if ($_[0]->_PERL_CAN_64BIT()) {
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
