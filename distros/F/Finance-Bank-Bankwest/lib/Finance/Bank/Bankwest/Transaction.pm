package Finance::Bank::Bankwest::Transaction;
# ABSTRACT: representation of an account transaction
$Finance::Bank::Bankwest::Transaction::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Transaction is dirty {

    use MooseX::StrictConstructor; # no exports

    for (
        [ date          => 'Str'        ],
        [ narrative     => 'Str'        ],
        [ cheque_num    => 'Maybe[Str]' ],
        [ amount        => 'Maybe[Num]' ],
        [ type          => 'Maybe[Str]' ],
    ) {
        my ($attr, $type) = @$_;
        has $attr => ( isa => $type, is => 'ro', required => 1 );
    }

    has 'date_dt' => (
        init_arg    => undef,
        isa         => 'DateTime',
        is          => 'ro',
        lazy_build  => 1,
    );
    method _build_date_dt {
        require DateTime;
        my ($dd, $mm, $yyyy)
            = shift->date =~ m( ^ (\d\d) / (\d\d) / (\d\d\d\d) $ )x;
        return DateTime->new(
            day     => $dd,
            month   => $mm,
            year    => $yyyy,
        );
    }


    method equals(Finance::Bank::Bankwest::Transaction $other) {
        for (qw{ date narrative cheque_num amount type }) {
            next if not defined $self->$_ and not defined $other->$_;
            return if defined $self->$_ and not defined $other->$_;
            return if defined $other->$_ and not defined $self->$_;
            return if $self->$_ ne $other->$_;
        }
        return 1;
    }

    clean;
    use overload 'eq' => sub { shift->equals(shift) };
    use overload 'ne' => sub { not shift->equals(shift) };
}

__END__

=pod

=for :stopwords Alex Peters authorisation enquiry BPAY CHQ CRI DAU DIC DEP DFD DRI DRR
EFTPOS ENQ NAR POS PPA TAC TFC TFD TFN WDC WDI WDL

=head1 NAME

Finance::Bank::Bankwest::Transaction - representation of an account transaction

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 SYNOPSIS

    $transaction->date;         # '31/12/2012'
    $transaction->date_dt;      # a DateTime instance
    $transaction->narrative;    # '1 BANK CHEQUE FEE - BWA CUSTOMER'
    $transaction->cheque_num;   # undef
    $transaction->amount;       # -10.00
    $transaction->type;         # 'FEE'

    SAME_TRANSACTION if $this_txn->equals($other_txn);
    SAME_TRANSACTION if $this_txn eq $other_txn;
    DIFFERENT_TRANSACTION if $this_txn ne $other_txn;

=head1 DESCRIPTION

Instances of this module are returned by
L<Finance::Bank::Bankwest::Session/transactions>.

=head1 ATTRIBUTES

=head2 date

A string in C<DD/MM/YYYY> format representing the date of the
transaction.

=head2 date_dt

I<Added in v1.2.0.>

The L</date> as a L<DateTime> instance with a floating time zone.

I<require>-s the DateTime module when used.  C<use DateTime> in any
code that relies on this attribute to prevent runtime failures caused
by the DateTime module not being installed.

=head2 narrative

A description of the transaction.

=head2 cheque_num

The cheque number for cheque withdrawals, or C<undef> if not applicable.

=head2 amount

A positive or negative value representing the credit or debit value of
the transaction respectively, or C<undef> if not applicable (such as
for fee notices or declined transactions).

=head2 type

The transaction "type."  Defined for every transaction in savings
accounts (e.g. Zero Transaction).  Not defined for every transaction in
credit card accounts.

If defined, may be one of the following values (although Bankwest may
not always assign the most relevant code to a particular transaction):

=over 6

=item CHQ

I<withdrawal (cheque)>

=item CRI

I<credit interest>

=item DAT

I<ATM deposit>

=item DAU

I<debit authorisation> (i.e. "Authorisation Only" transactions)

=item DEC

I<Express Commercial Deposit>

=item DEP

I<deposit> (includes EFTPOS refunds)

=item DFD

I<Fast Deposit Box deposit>

=item DIC

I<dishonoured credit>

=item DID

I<dishonoured debit> (e.g. bounced cheques)

=item DRI

I<debit interest>

=item DRR

I<debit reversal>

=item ENQ

I<balance enquiry> (includes declined transactions)

=item FEE

I<fee raising> (e.g. bank cheque fees)

=item FER

I<fee refund>

=item NAR

I<narrative> (information only, e.g. notification of ATM fees paid by
Bankwest, breakdown of foreign currency conversion fees included in
another transaction)

=item PAD

I<ATM deposit>

=item PAY

I<payroll> (i.e. salary deposits)

=item PEN

I<pension>

=item PPA

I<POS payment authorisation>

=item TAC

I<government tax adjustment (credit)>

=item TAX

I<government tax raising>

=item TFC

I<transfer (credit)>

=item TFD

I<transfer (debit)> (includes BPAY payments)

=item TFN

I<TFN raising>

=item WDC

I<Debit MasterCard withdrawal (Australia)>

=item WDI

I<Debit MasterCard withdrawal (international)>

=item WDL

I<withdrawal> (includes direct debits and ATM, EFTPOS and "pay anyone"
withdrawals)

=back

=head1 METHODS

=head2 equals

I<Added in v1.1.0.>

    if ($this_txn->equals($other_txn)) {
        # $this_txn and $other_txn represent the exact same transaction
        ...
    }

True if both this transaction and the specified one represent an
identical transaction; false otherwise.

Perl's C<eq> and C<ne> operators are also L<overload>-ed for
Transaction objects, allowing the following code to work as expected:

    if ($this_txn eq $other_txn) {
        # $this_txn and $other_txn represent the exact same transaction
        ...
    }

    if ($this_txn ne $other_txn) {
        # $this_txn and $other_txn DO NOT represent the exact same transaction
        ...
    }

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Session/transactions>

=back

=head1 AUTHOR

Alex Peters <lxp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
