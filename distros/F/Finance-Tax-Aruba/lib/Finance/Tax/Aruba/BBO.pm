package Finance::Tax::Aruba::BBO;
our $VERSION = '0.015';
use warnings;
use strict;

# ABSTRACT: BBO (turnover tax) calculations for Aruba

use Carp qw(croak);
use List::Util qw(first);

use Module::Pluggable
    require     => 1,
    sub_name    => '_plugins',
    search_path => 'Finance::Tax::Aruba::BBO',
;

our @years;

sub _years {
    return @years if @years;
    @years = shift->_plugins;
    return @years;
}

sub tax_year {
    my $self = shift;
    my $year = shift;

    my @years = $self->_years();
    my $module = first { $_->is_year($year) } @years;
    return $module->new(@_) if $module;
    croak("Unable to find module for year $year");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba::BBO - BBO (turnover tax) calculations for Aruba

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Finance::Tax::Aruba::BBO;

    my $calc = Finance::Tax::Aruba::BBO->tax_year(2024);

    $calc->domestic_tax(2000);   # BBO owed on domestic sales
    $calc->import_tax(1000);     # estimate of the customs BBO invoice
    $calc->net_payable(
        domestic => 2000,
        customs  => [
            { amount => 70, held => 1 },
            { amount => 35, held => 0 },
        ],
    );                          # 70 is offset, the 35 was not forwarded
    $calc->customs_not_forwarded($invoices);

=head1 DESCRIPTION

Factory for BBO (turnover tax) calculations, same shape as
L<Finance::Tax::Aruba::Income>: the rate (and whether import BBO is
creditable against domestic BBO, see L<Finance::Tax::Aruba::Role::BBO::TaxYear/bbo_at_border>)
has changed over time, so this dispatches to a year-specific class rather
than assuming one fixed rate/rule forever.

=head1 METHODS

=head2 tax_year

Factory method to create the correct calculator for a given tax year.

=head1 SEE ALSO

L<Finance::Tax::Aruba::Role::BBO::TaxYear>, L<Finance::Tax::Aruba::Income>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
