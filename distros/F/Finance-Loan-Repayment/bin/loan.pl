#!/usr/bin/perl
use warnings;
use strict;

# ABSTRACT: A simple loan calculator
# PODNAME: loan.pl

use Getopt::Long;
use Pod::Usage;
use Config::Any;
use File::Spec::Functions qw(catfile);
use Finance::Loan::Repayment;

my %opts = (
    help      => 0,
    config    => catfile($ENV{HOME}, qw (.config finance-loan-repayment loan.conf)),
);

{
    local $SIG{__WARN__};
    my $ok = eval {
        GetOptions(
            \%opts, qw(help rate=s loan=s
                total=s principal=s interest=s duration=i interest-only no_pay=i config=s)
        );
    };
    if (!$ok) {
        die($@);
    }
}

pod2usage(0) if ($opts{help});

if (-f $opts{config}) {
    my $config = Config::Any->load_files({ 
            files => [$opts{config}],
            use_ext => 1,
            flatten_hash => 1,

        })->[0]{$opts{config}};

    foreach (keys %opts) {
        delete $config->{$_};
    }

    foreach (keys %$config) {
        $opts{$_} ||= $config->{$_};
    }
}

my @required = qw(loan rate);
foreach (@required) {
    if (!defined $opts{$_} || $opts{$_} <= 0) {
        pod2usage(1);
    }
}

my $ok = 0;
my @optional = qw(total principal interest interest-only);
foreach (@optional) {
    if (defined $opts{$_} && $opts{$_} > 0) {
        $ok++;
    }
}
if (!$ok) {
    pod2usage(1);
}

my %args = (
    rate => $opts{rate},
    loan => $opts{loan},
);

if ($opts{'interest-only'}) {
    my $calc = Finance::Loan::Repayment->new(%args);

    printf("Loan: %.2f\tRate: %.2f\tInterest: %.2f\n",
        $calc->loan, $calc->rate, $calc->interest_per_month);

    exit 0;
}

if ($opts{principal}) {
    $args{principal_payment} = $opts{principal};
}
elsif ($opts{interest}) {
    $args{interest_off} = $opts{interest};
}
elsif ($opts{total}) {
    $args{total_payment} = $opts{total};
}
my $calc = Finance::Loan::Repayment->new(%args);

my $loan            = $calc->loan;
my $total_interest  = 0;
my $total_payments  = 0;
my $total_principal = 0;
my $payment         = 0;
my $principal       = 0;
my $interest        = 0;
my $orig_loan       = $loan;
my $counter         = 0;
my $duration        = $opts{duration};

while ($calc->loan > 0) {

    $interest  = $calc->interest_per_month($loan);
    $principal = $calc->principal_per_month($loan);
    $payment   = $interest + $principal;

    $total_interest  += $interest;
    $total_payments  += $payment;
    $total_principal += $payment;
    $loan            -= $principal;

    printf("Loan: %.2f\tInterest: %.2f\tPrincipal: %.2f\tPay per month: %.2f\n",
        $calc->loan, $interest, $principal, $payment);

    $calc->loan($loan);

    $counter++;
    last if ($duration && $counter >= $duration);
    printf("Year passed\n") if $counter % 12 == 0;
}

print "\n";
if ($duration) {
    printf("Duration: %dm\tInterest: %.2f\tPrincipal: %.2f\tPaid in total: %.2f\n",
        $counter,
        $total_interest,
        $total_principal,
        $total_payments,
    );
}
else {
    if ($counter / 12 > 1) {
        printf("%.2f years\tInterest: %.2f\tPrincipal: %.2f\tPaid in total: %.2f\n",
            $counter / 12,
            $total_interest,
            $total_principal,
            $total_payments,
        );
    }
    else {
        printf("%d months\tInterest: %.2f\tPrincipal: %.2f\tPaid in total: %.2f\n",
            $counter,
            $total_interest,
            $total_principal,
            $total_payments,
        );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

loan.pl - A simple loan calculator

=head1 VERSION

version 1.1

=head1 SYNOPSIS

loan.pl --loan 50000 --rate 4.15 [ OPTIONS ]

=head1 OPTIONS

=over

=item loan

The outstanding loan amount

=item rate

The interest rate of the loan

=item interest-only

Only show the interest for the loan

=item duration

Only show x months of payments

=item config

Define where your configuration file is located, defaults to
C<$HOME/.config/finance-loan-repayment/loan.conf>. In here you can
change the defaults for all of the command line options. Command line
options take preference over the configuration file options.

=back

The following options will dictate how you pay back your loan.
Each option differs in how your interest, principal and total payment
amount will be after each payment.

=over

=item principal

The principal payment you want to pay each month on the loan.
This is what happens with a liniar payback of the loan.
Makes your total payment per month variable.

=item interest

The amount you want to pay off your interest each month.
This will make your principal payment steady, with a variable total.

=item total

The amount you want to pay off each month.
This is the same as a installment payment scheme.

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Wesley Schwengle.

This is free software, licensed under:

  The MIT (X11) License

=cut
