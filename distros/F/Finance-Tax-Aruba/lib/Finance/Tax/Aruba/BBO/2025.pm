package Finance::Tax::Aruba::BBO::2025;
our $VERSION = '0.016';
use Moose;
use namespace::autoclean;

# ABSTRACT: BBO calculator for the year 2025

with qw(
    Finance::Tax::Aruba::Role::BBO::TaxYear
);

has '+bbo_at_border' => (
    default => 1,
);

sub is_year {
    my $self = shift;
    my $year = shift;
    return 1 if $year == 2025;
    return 1 if $year == 2026;
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba::BBO::2025 - BBO calculator for the year 2025

=head1 VERSION

version 0.016

=head1 DESCRIPTION

BBO calculator for the year 2025 (and, until a later year class is added,
2026 onward -- same catch-all convention as
L<Finance::Tax::Aruba::Income::2025>).

=head1 METHODS

=head2 is_year

Year selector method.

=head1 SEE ALSO

This class implements the L<Finance::Tax::Aruba::Role::BBO::TaxYear> role.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
