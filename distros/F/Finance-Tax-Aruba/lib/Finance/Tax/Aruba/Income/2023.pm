package Finance::Tax::Aruba::Income::2023;
our $VERSION = '0.006';
use Moose;
use namespace::autoclean;

# ABSTRACT: Income tax calculator for the year 2021

with qw(
    Finance::Tax::Aruba::Role::Income::TaxYear
);

has '+wervingskosten_max' => (
    default  => 1500,
);

has '+wervingskosten_percentage' => (
    default  => 3,
);

has '+aov_max' => (
    default  => 85_000,
);

has '+azv_max' => (
    default  => 85_000,
);

has '+taxfree_max' => (
    default  => 30_000,
);

has '+aov_percentage_employer' => (
    default  => 10.5,
);

has '+aov_percentage_employee' => (
    default  => 5,
);

has '+azv_max' => (
    default  => 85_000,
);

has '+azv_percentage_employee' => (
    default  => 1.6,
);

has '+azv_percentage_employer' => (
    default  => 8.9,
);

has tax_bracket => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_get_tax_bracket',
);

sub _build_tax_bracket {
    return [
        { min => 0, max => 34930, fixed => 0, rate => 12 },
        {
            min   => 34930,
            max   => 63904,
            fixed => 3493,
            rate  => 21,
        },
        {
            min   => 63904,
            max   => 135527,
            fixed => 9577.50,
            rate  => 42
        },
        {
            min   => 135527,
            max   => 'inf' * 1,
            fixed => 39659.20,
            rate  => 52
        },
    ];
}

sub is_year {
    my $self = shift;
    my $year = shift;
    return 1 if $year == 2023;
    return 0;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba::Income::2023 - Income tax calculator for the year 2021

=head1 VERSION

version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

Calculate your taxes and other social premiums for the year 2021 and 2022.

=head1 METHODS

=head2 is_year

Year selector method

    if ($module->is_year(2020)) {
        return "year is 2020";
    }

=head1 SEE ALSO

This class implements the L<Finance::Tax::Aruba::Role::Income::TaxYear> role.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
