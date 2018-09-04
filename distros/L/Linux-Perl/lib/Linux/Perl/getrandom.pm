package Linux::Perl::getrandom;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::Perl::getrandom

=head1 SYNOPSIS

    my $numbytes = Linux::Perl::getrandom::x86_64->getrandom(
        buffer => \$buffer,
        flags => [ 'RANDOM', 'NONBLOCK' ],
    );

    # … or, platform-neutral:
    my $numbytes = Linux::Perl::getrandom->getrandom(
        buffer => \$buffer,
        flags => [ 'RANDOM', 'NONBLOCK' ],
    );

=head1 DESCRIPTION

This is an interface to Linux’s C<getrandom> system call. This system
call is documented only for kernel 3.17 and after; however, it appears
to be present in some earlier kernel versions.

=cut

use Linux::Perl;
use Linux::Perl::Pointer;

use parent 'Linux::Perl::Base';

my %FLAG_VALUE = (
    NONBLOCK => 1,
    RANDOM => 2,
);

sub getrandom {
    my ($class, %opts) = @_;

    $class = $class->_get_arch_module();

    my $flags = 0;
    if ($opts{'flags'}) {
        for my $f ( @{ $opts{'flags'} } ) {
            $flags |= $FLAG_VALUE{$f} || do {
                die "Invalid flag: “$f”!";
            };
        }
    }

    if ('SCALAR' ne ref $opts{'buffer'}) {
        die "“buffer” must be a scalar reference, not “$opts{'buffer'}”!";
    }

    return Linux::Perl::call(
        $class->NR_getrandom(),
        Linux::Perl::Pointer::get_address( ${ $opts{'buffer'} } ),
        length( ${ $opts{'buffer'} } ),
        0 + $flags,
    );
}

1;
