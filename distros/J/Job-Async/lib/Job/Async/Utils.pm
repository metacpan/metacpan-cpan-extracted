package Job::Async::Utils;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

=head1 NAME

Job::Async::Utils - helper functions for L<Job::Async>

=head1 DESCRIPTION

Provides a few functions used in other modules.

=cut

use Math::Random::Secure;

=head2 uuid

Generates a random (v4) UUID, returning it as a string.

e.g.

 $ perl -le'use Job::Async::Utils; print Job::Async::Utils::uuid()'
 5d2a5619-fb7b-44e5-048e-76adc9660c0a

=cut

sub uuid {
    # UUIDv4 (random)
    my $v = sprintf('%08x-%08x-%08x%08x',
        Math::Random::Secure::irand(2**32),
        (Math::Random::Secure::irand(2**32) & 0xFFFF0FFF) | 0x4000,
        Math::Random::Secure::irand(2**32) & 0xBFFFFFFF,
        Math::Random::Secure::irand(2**32)
    );
    substr $v, 13, 0, '-';
    substr $v, 23, 0, '-';
    return $v;
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2017. Licensed under the same terms as Perl itself.

