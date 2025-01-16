package Finance::Tax::Aruba::Income::2020;
our $VERSION = '0.012';
use Moose;
use namespace::autoclean;

# ABSTRACT: Income tax calculator for the year 2020

with qw(
    Finance::Tax::Aruba::Role::Income::TaxYear
);

has '+taxfree_max' => (
    default  => 28_861,
);

sub _build_tax_bracket {
    return [
        { min => 0, max => 34930, fixed => 0, rate => 14 },
        {
            min   => 34930,
            max   => 65904,
            fixed => 4890.2,
            rate  => 25
        },
        {
            min   => 65904,
            max   => 147454,
            fixed => 12633.7,
            rate  => 42
        },
        {
            min   => 147454,
            max   => 'inf' * 1,
            fixed => 46884.7,
            rate  => 52
        },
    ];
}

sub is_year {
    my $self = shift;
    return 1 if shift == 2020;
    return 0;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba::Income::2020 - Income tax calculator for the year 2020

=head1 VERSION

version 0.012

=head1 SYNOPSIS

=head1 DESCRIPTION

Calculate your taxes and other social premiums for the year 2020.

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
