# DESCRIPTION

A module to calculate interest per month and principal payments per month

# SYNOPSIS

    use Finance::Loan::Repayment;

    my $calc = Finance::Loan::Repayment->new(
        loan => 100,
        rate => 5,

        # The following parameters are optional
        # Reduce interest by 1 each month
        interest_off => 1,

        # Principal payment per month
        principal_payment => 30,

        # Total amount to pay per month
        total_payment => 30,

    );

# ATTRIBUTES

## loan

The loan amount, required.

## rate

The interest rate of the loan, required.

# Attributes changing the way the `principal_payment_per_month` functions works

The following attributes will alter how the principal payment per month
function will work.

## principal\_payment

The amount you want to pay off your loan each month. This changes the
total costs per month and the interest you pay.

## interest\_off

The amount you want to pay off your interest each month. This changes the
total costs per month and the interest you pay. This will make your
additional payment steady.

## total\_payment

The amount you want to pay off each month. This will influence the interest
you pay and the principal payment.

# METHODS

## interest\_per\_month

    $calc->interest_per_month();
    $calc->interest_per_month(1000);

Calculates the interest amount per month on the loan. An optional loan
parameter can be used.

## principal\_per\_month()

    $calc->principal_per_month();
    $calc->principal_per_month(1000);

Calculates the principal payments per month based on the constructor
arguments. An optional loan parameter can be used.

# SEE ALSO

- [Finance::Amortization](https://metacpan.org/pod/Finance%3A%3AAmortization)

    This does more or less the same thing as this module

- [Finance::Loan](https://metacpan.org/pod/Finance%3A%3ALoan)
- [Finance::Loan::Private](https://metacpan.org/pod/Finance%3A%3ALoan%3A%3APrivate)
