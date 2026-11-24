package Finance::Tax::Aruba::Income::2026;
our $VERSION = '0.015';
use Moose;
use namespace::autoclean;

# ABSTRACT: Income tax calculator for the year 2026

extends 'Finance::Tax::Aruba::Income::2025';

has '+reparatietoeslag_table' => (
    default => sub {
        [
            { min => 2007.05, max => 2258.00, amount => 175 },
            { min => 2258.00, max => 2300.00, amount => 170 },
            { min => 2300.00, max => 2350.00, amount => 165 },
            { min => 2350.00, max => 2400.00, amount => 160 },
            { min => 2400.00, max => 2450.00, amount => 155 },
            { min => 2450.00, max => 2500.01, amount => 150 },
        ];
    },
);

sub is_year {
    my $self = shift;
    my $year = shift;
    return $year == 2026 ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba::Income::2026 - Income tax calculator for the year 2026

=head1 VERSION

version 0.015

=head1 DESCRIPTION

Calculate your taxes and other social premiums for the year 2026. The brackets
are those of 2025, with the addition of the reparatietoeslag: a monthly tax
credit for gross monthly incomes between 2007.05 and 2500.01.

=head1 METHODS

=head2 is_year

Year selector method

    if ($module->is_year(2026)) {
        return "year is 2026";
    }

=head1 SEE ALSO

This class extends L<Finance::Tax::Aruba::Income::2025>.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
