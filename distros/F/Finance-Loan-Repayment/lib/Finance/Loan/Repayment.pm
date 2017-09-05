package Finance::Loan::Repayment;
use Moose;

# ABSTRACT: Play with loans, rates and repayment options
our $VERSION = '1.1';

has loan => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
);

has rate => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has principal_payment => (
    is  => 'ro',
    isa => 'Num',
);

has interest_off => (
    is  => 'ro',
    isa => 'Num',
);

has total_payment => (
    is  => 'ro',
    isa => 'Num',
);

sub interest_per_month {
    my $self = shift;
    my $loan = shift // $self->loan;
    return $loan * ($self->rate / 100 / 12);
}

sub principal_per_month {
    my $self = shift;
    my $loan = shift // $self->loan;

    my $interest = $self->interest_per_month($loan);

    if ($self->principal_payment) {
        return $self->_check_payment_vs_loan($self->principal_payment, $loan);
    }
    elsif ($self->total_payment) {
        if ($self->total_payment < $interest) {
            return $interest + .01;
        }
        return $self->_check_payment_vs_loan(
            $self->total_payment - $interest,
            $loan
        );
    }
    elsif ($self->interest_off) {
        my $new_loan = (($interest - $self->interest_off) * 12)
            / ($self->rate / 100);
        return $self->_check_payment_vs_loan($loan - $new_loan, $loan);
    }
    return 0;
}

sub _check_payment_vs_loan {
    my ($self, $payment, $loan) = @_;
    return ($payment > $loan) ? $loan : $payment;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Loan::Repayment - Play with loans, rates and repayment options

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Finance::Loan::Repayment;

    my $calc = Finance::Loan::Repayment->new(
        loan => 100,
        rate => 5,

        # The following parameters are optional
        # Reduce interest by 1 each month
        interest_off => 1

        # Principal payment per month
        principal_payment => 30

        # Total amount to pay per month
        total_payment => 30

    );

=head1 DESCRIPTION

A module to calculate interest per month and principal payments per month

=head1 ATTRIBUTES

=head2 loan

The loan amount, required.

=head2 rate

The interest rate of the loan, required.

=head1 Attributes changing the way the C<principal_payment_per_month> functions works

The following attributes will alter how the principal payment per month
function will work.

=head2 principal_payment

The amount you want to pay off your loan each month. This changes the
total costs per month and the interest you pay.

=head2 interest_off

The amount you want to pay off your interest each month. This changes the
total costs per month and the interest you pay. This will make your
additional payment steady.

=head2 total_payment

The amount you want to pay off each month. This will influence the interest
you pay and the principal payment.

=head1 METHODS

=head2 interest_per_month

    $calc->interest_per_month();
    $calc->interest_per_month(1000);

Calculates the interest amount per month on the loan. An optional loan
parameter can be used.

=head2 principal_per_month()

    $calc->principal_per_month();
    $calc->principal_per_month(1000);

Calculates the principal payments per month based on the constructor
arguments. An optional loan parameter can be used.

=head1 SEE ALSO

=over

=item L<Finance::Amortization>

This does more or less the same thing as this module

=item L<Finance::Loan>

=item L<Finance::Loan::Private>

=back

=head1 AUTHOR

Wesley Schwengle

=head1 LICENSE and COPYRIGHT

Wesley Schwengle, 2017.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Wesley Schwengle.

This is free software, licensed under:

  The MIT (X11) License

=cut
