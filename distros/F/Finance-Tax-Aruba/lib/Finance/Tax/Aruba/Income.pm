package Finance::Tax::Aruba::Income;
our $VERSION = '0.010';
use warnings;
use strict;

# ABSTRACT: Income tax calculations for Aruba

use Carp qw(croak);
use List::Util qw(first);

use Module::Pluggable
    require     => 1,
    sub_name    => '_plugins',
    search_path => 'Finance::Tax::Aruba::Income',
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

Finance::Tax::Aruba::Income - Income tax calculations for Aruba

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Finance::Tax::Aruba::Income;

    # For all the options, please see
    # Finance::Tax::Aruba::Role::Income::TaxYear
    my %opts = (
        income => 7000
    );

    my $calc = Finance::Tax::Aruba::Income->tax_year(2020, %opts);

=head1 DESCRIPTION

Factory for tax calculations

=head1 SUPPORTED YEARS

All the years from 2020 up to 2023 are supported.

=head1 METHODS

=head2 tax_year

Factory method to create the correct calculator for a given tax year

=head1 SEE ALSO

L<Finance::Tax::Aruba::Role::Income::TaxYear>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
