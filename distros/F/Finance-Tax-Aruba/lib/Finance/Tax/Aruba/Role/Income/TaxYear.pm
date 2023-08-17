package Finance::Tax::Aruba::Role::Income::TaxYear;
our $VERSION = '0.009';
use Moose::Role;

# ABSTRACT: A role that implements income tax logic

requires qw(
    _build_tax_bracket
    is_year
);

has children => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has dependents => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has children_study_abroad => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

# Child (<18) not going to school
has child_deduction_amount => (
    is      => 'ro',
    isa     => 'Num',
    default => 700,
);

# School going > 16 < 27 with severe handicap which is unable
# to work
has dependent_deduction_amount => (
    is      => 'ro',
    isa     => 'Num',
    default => 1200,
);

has additional_deduction_amount => (
    is      => 'ro',
    isa     => 'Num',
    default => 3800,
);

has pension_employee_perc => (
    is      => 'ro',
    isa     => 'Num',
    default => 3,
);

has pension_employer_perc => (
    is      => 'ro',
    isa     => 'Num',
    default => 3,
);

has income => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has yearly_income => (
    is        => 'ro',
    isa       => 'Num',
    lazy      => 1,
    builder   => '_build_yearly_income',
    predicate => 'has_yearly_income',
    init_arg  => undef,
);

has pension_employee => (
    is        => 'ro',
    isa       => 'Num',
    lazy      => 1,
    builder   => '_build_pension_employee',
    predicate => 'has_pension_employee',
    init_arg  => undef,
);

has pension_employer => (
    is        => 'ro',
    isa       => 'Num',
    lazy      => 1,
    builder   => '_build_pension_employer',
    predicate => 'has_pension_employer',
    init_arg  => undef,
);

has bonus => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
);

has fringe => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
);

has tax_free => (
    is      => 'ro',
    isa     => 'Num',
    default => 0,
);

has yearly_income_gross => (
    is        => 'ro',
    isa       => 'Num',
    lazy      => 1,
    builder   => '_build_yearly_income_gross',
    predicate => 'has_yearly_income_gross',
);

has months => (
    is      => 'ro',
    isa     => 'Int',
    default => 12,
);

has wervingskosten_max => (
    is      => 'ro',
    isa     => 'Num',
    default => 1500,
);

has wervingskosten_percentage => (
    is      => 'ro',
    isa     => 'Num',
    default => 3,
);

has wervingskosten => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_wervingskosten',
);

has aov_max => (
    is      => 'ro',
    isa     => 'Num',
    default => 85_000,
);

has azv_max => (
    is      => 'ro',
    isa     => 'Num',
    default => 85_000,
);

has taxfree_max => (
    is      => 'ro',
    isa     => 'Num',
    default => 28_861,
);

has taxfree_amount => (
    is      => 'ro',
    isa     => 'Num',
    builder => '_build_taxfree_amount',
    lazy    => 1,
);

has aov_percentage_employer => (
    is      => 'ro',
    isa     => 'Num',
    default => 10.5,
);

has aov_percentage_employee => (
    is      => 'ro',
    isa     => 'Num',
    default => 5,
);

has aov_yearly_income => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_get_aov_yearly_income',
);

has azv_max => (
    is      => 'ro',
    isa     => 'Num',
    default => 85_000,
);

has azv_percentage_employee => (
    is      => 'ro',
    isa     => 'Num',
    default => 1.6,
);

has azv_percentage_employer => (
    is      => 'ro',
    isa     => 'Num',
    default => 8.9,
);

has azv_yearly_income => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_get_aov_yearly_income',
);

has tax_brackets => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_tax_bracket',
);

has tax_bracket => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_get_tax_bracket',
);

has tax_rate => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_get_tax_rate',
);

has tax_fixed => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_get_tax_fixed',
);

has tax_minimum => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_get_tax_minimum',
);

has tax_maximum => (
    is      => 'ro',
    isa     => 'Defined',
    lazy    => 1,
    builder => '_get_tax_maximum',
);

has tax_variable => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_get_tax_variable',
);

has taxable_amount => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_get_taxable_amount',
);

sub _get_max {
    my ($max, $value) = @_;
    return $value > $max ? $max : $value;
}

sub _build_pension_employee {
    my $self = shift;
    return $self->get_cost($self->yearly_income_gross - $self->fringe - $self->bonus,
        $self->pension_employee_perc);
}

sub _build_pension_employer {
    my $self = shift;
    return $self->get_cost($self->yearly_income_gross - $self->fringe - $self->bonus,
        $self->pension_employer_perc);
}

sub _build_yearly_income_gross {
    my $self = shift;
    return $self->income + $self->fringe + $self->bonus;
}

sub _build_yearly_income {
    my $self = shift;
    return $self->yearly_income_gross - $self->wervingskosten
        - $self->pension_employee;
}

sub _get_tax_bracket {
    my $self = shift;

    foreach (@{ $self->tax_brackets }) {
        return $_ if $self->taxable_wage < $_->{max};
    }
}

sub _get_tax_rate {
    my $self = shift;
    return $self->tax_bracket->{rate};
}

sub _get_tax_fixed {
    my $self = shift;
    return $self->tax_bracket->{fixed};
}

sub _get_tax_minimum {
    my $self = shift;
    return $self->tax_bracket->{min};
}

sub _get_tax_maximum {
    my $self = shift;
    return $self->tax_bracket->{max} * 1;
}

sub _get_taxable_amount {
    my $self = shift;
    return _format_perc($self->taxable_wage - $self->tax_minimum);
}

sub _get_tax_variable {
    my $self = shift;
    return $self->get_cost($self->taxable_amount, $self->tax_rate);
}

sub income_tax {
    my $self = shift;
    return int($self->tax_variable + $self->tax_fixed);
}

sub _build_wervingskosten {
    my $self           = shift;
    my $wervingskosten = $self->get_cost($self->yearly_income_gross,
        $self->wervingskosten_percentage);
    return _get_max($self->wervingskosten_max, $wervingskosten);
}

sub get_cost {
    my ($self, $costs, $perc) = @_;
    return _format_perc($costs * ($perc / 100));
}

sub _format_perc {
    return sprintf("%.02f", shift) + 0;
}

sub _build_taxfree_amount {
    my $self = shift;

    if ($self->zuiver_jaarloon < $self->taxfree_max) {
        return $self->zuiver_jaarloon * ($self->months / 12);
    }
    return $self->taxfree_max * ($self->months / 12);
}

sub _get_aov_yearly_income {
    my $self = shift;
    return _get_max($self->aov_max, $self->yearly_income);
}

sub aov_employee {
    my $self = shift;
    return $self->get_cost($self->aov_yearly_income,
        $self->aov_percentage_employee);
}

sub aov_employer {
    my $self = shift;
    return $self->get_cost($self->aov_yearly_income,
        $self->aov_percentage_employer);
}

sub pension_premium {
    my $self = shift;
    return $self->get_cost($self->yearly_income_gross - $self->fringe - $self->bonus,
        $self->pension_employee_perc + $self->pension_employer_perc);
}

sub aov_premium {
    my $self = shift;
    return $self->get_cost($self->aov_yearly_income,
        $self->aov_percentage_employee + $self->aov_percentage_employer);
}

sub azv_premium {
    my $self = shift;
    return $self->get_cost($self->azv_yearly_income,
        $self->azv_percentage_employee + $self->azv_percentage_employer);
}

sub _get_azv_yearly_income {
    my $self = shift;
    return _get_max($self->azv_max, $self->yearly_income);
}

sub azv_employee {
    my $self = shift;
    return $self->get_cost($self->azv_yearly_income,
        $self->azv_percentage_employee);
}

sub azv_employer {
    my $self = shift;
    return $self->get_cost($self->azv_yearly_income,
        $self->azv_percentage_employer);
}

sub net_yearly_income {
    my $self = shift;
    return $self->zuiver_jaarloon;
}

sub child_deductions {
    my $self = shift;

    return
          ($self->children * $self->child_deduction_amount)
        + ($self->dependents * $self->dependent_deduction_amount)
        + ($self->children_study_abroad * $self->additional_deduction_amount);
}

sub zuiver_jaarloon {
    my $self = shift;

    return $self->yearly_income - $self->aov_employee - $self->azv_employee
        - $self->child_deductions;
}

sub taxable_wage {
    my $self         = shift;
    my $taxable_wage = $self->zuiver_jaarloon - $self->taxfree_amount;
    return $taxable_wage < 0 ? 0 : $taxable_wage;
}

sub employee_income_deductions {
    my $self = shift;
    return $self->aov_employee + $self->azv_employee + $self->income_tax;
}

sub pension_total {
    my $self = shift;
    return $self->pension_premium;
}

sub tax_free_wage {
    my $self = shift;
    return
          $self->yearly_income
        - $self->employee_income_deductions
        - $self->taxfree_amount
        - $self->fringe;
}

sub net_income {
    my $self = shift;
    return
          $self->tax_free_wage
        + $self->taxfree_amount
        + $self->wervingskosten
        + $self->tax_free;
}

sub company_costs {
    my $self = shift;
    return
        $self->yearly_income_gross
         + $self->aov_employer
         + $self->azv_employer
         + $self->pension_employer;
}

sub government_costs {
    my $self = shift;
    return $self->aov_premium + $self->azv_premium + $self->income_tax
}

sub social_costs {
    my $self = shift;
    return $self->government_costs + $self->pension_total;
}

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    foreach (qw(income fringe tax-free)) {
        next unless exists $args{$_};
        $args{$_} *= ($args{months} // 12);
    }

    if ($args{as_np}) {
        $args{pension_employer_perc} = 0;
        $args{pension_employee_perc} = 0;

        $self->_offset_values('aov_percentage_employer', 0,
            'aov_percentage_employee', \%args);
        $self->_offset_values('azv_percentage_employer', 0,
            'azv_percentage_employee', \%args);
        return $self->$orig(%args);
    }

    if ($args{premiums_employer}) {
        $self->_offset_values('aov_percentage_employee', 0,
            'aov_percentage_employer', \%args);
        $self->_offset_values('azv_percentage_employee', 0,
            'azv_percentage_employer', \%args);
        $args{pension_by_employer} = 1;
    }
    else {
        if ($args{azv_by_employer}) {
            $self->_offset_values(
                'azv_percentage_employee', 0,
                'azv_percentage_employer', \%args
            );
        }

        if ($args{aov_by_employer}) {
            $self->_offset_values(
                'aov_percentage_employee', 0,
                'aov_percentage_employer', \%args
            );
        }
    }

    if ($args{no_pension}) {
        $args{pension_employer_perc} = 0;
        $args{pension_employee_perc} = 0;
    }
    elsif ($args{pension_by_employer}) {
            $self->_offset_values(
                'pension_employee_perc', 0,
                'pension_employer_perc', \%args
            );
    }
    elsif (exists $args{pension_employee_perc}) {
            $self->_offset_values('pension_employee_perc',
                $args{pension_employee_perc},
                'pension_employer_perc', \%args);
    }
    elsif (exists $args{pension_employer_perc}) {
        $self->_offset_values('pension_employer_perc',
            $args{pension_employer_perc},
            'pension_employee_perc', \%args);
    }

    return $self->$orig(%args);

};

sub _offset_values {
    my $self   = shift;
    my $source = $self->meta->find_attribute_by_name(shift);
    my $value  = shift;
    my $target = $self->meta->find_attribute_by_name(shift);
    my $args   = shift;

    my $diff = $value - $source->default;
    my $t    = $target->default + (-1 * $diff);

    $args->{ $source->name } = $value;
    $args->{ $target->name } = $t;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba::Role::Income::TaxYear - A role that implements income tax logic

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    package Aruba::Tax::Income::XXXX;
    use Moose;

    with qw(Finance::Tax::Aruba::Role::Income::TaxYear);

    sub _build_tax_bracket {
        return [],
    }

    sub is_year {
        ...;
    }

=head1 DESCRIPTION

Consumers of this role must implements the following methods:

=head2 _build_tax_bracket

This should be an array reference containing the information about each
bracket.

    [
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

=head2 is_year

This function should return true if the year is supported by the plugin

=head1 ATTRIBUTES

TODO: Add more documentation

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
