# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BitPay-API.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;

# Set this if you want to run private requests. (your found here: https://bitpay.com/api-keys)
use constant API_KEY     => '';

use constant DEBUG       => 0;
use constant TEST_LEDGER => 0;

use constant INVOICE_COLUMNS => qw(
    expirationTime 
    btcPrice 
    status 
    invoiceTime 
    rate 
    currency 
    currentTime 
    btcPaid 
    exceptionStatus 
    url 
    id 
    price
);

use constant LEDGER_COLUMNS => qw(
    code
    amount
    timestamp
    description
    txType
    exRates
    buyerFields
    invoiceId
    sourceType
    orderId
);

use constant CURRENCY_COLUMNS => qw(
    code
    name
    rate
);

BEGIN { 
    use_ok('Finance::BitPay::API');
};

use Data::Dumper;

main->new->go;

sub new { bless {} => shift }
sub go {
    my $self = shift;
    $self->test_count(1);

    can_ok('Finance::BitPay::API', qw(new invoice_create invoice_get rates ledger));
    $self->inc_tests;

    if (API_KEY) {
        $self->bitpay(Finance::BitPay::API->new(key => $self->key));

        isa_ok($self->bitpay, 'Finance::BitPay::API');
        $self->inc_tests;

        #########################
        $self->invoice($self->bitpay->invoice_create(price => '1.00', currency => 'USD'));

        ok($self->invoice, 'New Invoice');
        $self->inc_tests;

        if ($self->invoice) {
            print Data::Dumper->Dump([$self->invoice],['Invoice']) if DEBUG;
            is_deeply([sort {$a cmp $b} keys %{$self->invoice}],[sort {$a cmp $b} INVOICE_COLUMNS],'Valid Invoice data structure');
            $self->inc_tests;

            #########################
            # try to retrieve this invoice again...
            #########################
            my $invoice_copy = $self->bitpay->invoice_get(id => $self->invoice->{id});
            ok($invoice_copy, 'Retrieved Invoice');
            $self->inc_tests;

            if ($invoice_copy) {
                print Data::Dumper->Dump([$invoice_copy],['Retrieved Invoice']) if DEBUG;
                #is_deeply($invoice_copy, $self->invoice, 'Retrieved copy matches the original Invoice');
                is_deeply([sort {$a cmp $b} keys %{$invoice_copy}],[sort {$a cmp $b} INVOICE_COLUMNS],'Valid Invoice data structure');
                $self->inc_tests;
                # Structures begin differing at: currentTime
                foreach my $column (INVOICE_COLUMNS) {
                    next if $column eq 'currentTime';
                    #ok(exists $self->invoice->{$column}, sprintf('column %s exists', $column));
                    #$self->inc_tests;
                    is($invoice_copy->{$column}, $self->invoice->{$column}, sprintf('retrieved "%s" col matches original', $column));
                    $self->inc_tests;
                }
            }
            else {
                diag "Could Not Request the a copy of the new Invoice";
                printf Data::Dumper->Dump([$self->bitpay->error],['Error']) if DEBUG;
            }
        }
        else {
            diag "Could Not Request the creation of a new Invoice";
            printf Data::Dumper->Dump([$self->bitpay->error],['Error']) if DEBUG;
        }


        #########################
        $self->invoice($self->bitpay->invoice_create(currency => 'CAD'));
        is($self->invoice, undef, 'insuficient data for invoice [good]');
        $self->inc_tests;
        if ($self->invoice) {
            print Data::Dumper->Dump([$self->invoice],['Invoice']) if DEBUG;
        }
        else {
            printf Data::Dumper->Dump([$self->bitpay->error],['Error']) if DEBUG;
        }

    }
    else {
        diag "SKIP: private requests. Add your key to into t/BitPay-API.t to run all tests"
    }

    #$self->bitpay(Finance::BitPay::API->new);

    # Test the rates()
    $self->rates($self->bitpay->rates);
    ok($self->rates, 'Rates Retrieved');
    $self->inc_tests;
    warn Data::Dumper->Dump([$self->rates],['Rates']) if DEBUG;
    ok(scalar @{$self->rates}, sprintf('Got a list of %s currency rates', scalar @{$self->rates}));
    $self->inc_tests;
    is_deeply([sort {$a cmp $b} keys %{$self->rates->[0]}],[sort {$a cmp $b} CURRENCY_COLUMNS],'Valid rate structure');
    $self->inc_tests;

    if (TEST_LEDGER) {
        # Test the ledger()
        my $currency = 'USD';
        my $start    = '2014-01-01';
        my $end      = '2014-01-02';
        $self->ledger($self->bitpay->ledger(c => $currency, startDate => $start, endDate => $end));
        ok($self->ledger, sprintf('Ledger Retrieved for %s between %s and %s', $currency, $start, $end));
        $self->inc_tests;
        if ($self->ledger) {
            warn Data::Dumper->Dump([$self->ledger],['Ledger']) if DEBUG;
            ok(scalar @{$self->ledger}, sprintf('Got a list of %s ledger entries', scalar @{$self->ledger}));
            $self->inc_tests;
            is_deeply([sort {$a cmp $b} keys %{$self->ledger->[0]}],[sort {$a cmp $b} LEDGER_COLUMNS],'Valid rate structure');
            $self->inc_tests;
        }
        else {
            diag 'Error: ' . $self->bitpay->error;
        }
    }
}

sub key        { API_KEY     }
sub bitpay     { get_set(@_) }
sub invoice    { get_set(@_) }
sub rates      { get_set(@_) }
sub ledger     { get_set(@_) }
sub test_count { get_set(@_) }
sub inc_tests  {
    my $self = shift;
    return $self->test_count($self->test_count + 1);
}

sub get_set {
    my $self      = shift;
    my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
    $self->{$attribute} = shift if scalar @_;
    return $self->{$attribute};
}

sub DESTROY {
    my $self = shift;
    done_testing($self->test_count || 0);
}

