package Karel::Util;

=head1 NAME

Karel::Util

=head1 DESCRITPTION

Helper functions for other packages.

=head1 FUNCTIONS

=over 4

=item m_to_n($i, $m, $n)

Checks whether the integer C<$i> lies between C<$m> and C<$n>
inclusive.

=item positive_int($i)

Checks whether C<$i> is a positive integer, i.e. C<m_to_n($i, 1, $i)>.

=back

=cut

use warnings;
use strict;

use Carp;
use parent qw( Exporter );
our @EXPORT_OK = qw{ positive_int m_to_n };


sub m_to_n {
    my ($i, $m, $n) = @_;
    defined && /^[0-9]+$/
        or croak +($_ // 'undef') . ' should be non negative integer'
        for $i, $m, $n;
    $m <= $i && $i <= $n or croak "$i not between $m and $n";
}


sub positive_int {
    my $i = shift;
    m_to_n($i, 1, $i)
}


__PACKAGE__
