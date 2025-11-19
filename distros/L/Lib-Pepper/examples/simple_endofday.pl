#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.42;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 0.1;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---


# Enable UTF-8 output for terminal
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use lib '../lib';
use Lib::Pepper::Simple;
use Lib::Pepper::Constants qw(:all);

=head1 NAME

simple_endofday.pl - End-of-day settlement with Lib::Pepper::Simple

=head1 DESCRIPTION

This example demonstrates how to perform end-of-day settlement (batch close)
using the Lib::Pepper::Simple high-level API. Settlement is CRITICAL - without
it, you will NOT receive payment for the day's transactions!

=head1 SYNOPSIS

    # Perform end-of-day settlement
    perl simple_endofday.pl

=head1 WHAT IS SETTLEMENT?

Settlement (also called "batch close") is the process that:

- Finalizes ALL transactions from the business day
- Submits the batch to the payment processor
- Triggers actual money transfer to your merchant account
- Prints settlement reports on the terminal
- Clears the transaction buffer in the terminal

B<CRITICAL>: Without settlement, transactions remain pending and you do NOT
receive payment! Settlement must be run at least once per business day.

=head1 WHEN TO RUN SETTLEMENT

- At the end of each business day (before midnight)
- After all transactions for the day are complete
- Before the payment processor's cutoff time
- Some high-volume merchants run settlement 2-3 times per day

=head1 IMPORTANT NOTES

After settlement completes:

- VOID operations no longer work for settled transactions
- Use REFUND instead (takes 3-5 business days)
- The terminal is ready for the next business day
- Settlement reports should be kept for reconciliation

=cut

print "=== End-of-Day Settlement Example ===\n" . "\n";

# Configuration
my $TERMINAL_IP = '192.168.1.163:20008';  # GP PAY terminal
my $TERMINAL_TYPE = PEP_TERMINAL_TYPE_GENERIC_ZVT;

print "Terminal: GP PAY" . "\n";
print "Address: $TERMINAL_IP" . "\n";
print "" . "\n";

# Load license file
my $licenseXml;
my $licensePath = '/home/cavac/src/pepperclient/pepper_license_8v5r22cg.xml';
if(-f $licensePath) {
    open(my $fh, '<', $licensePath);
    $licenseXml = do { local $/; <$fh> };
    close($fh);
    print "✓ License loaded" . "\n";
} else {
    die "ERROR: License file not found at $licensePath\n";
}

# Load config file
my $configXml;
my $configPath = './config/pepper_config.xml';
if(!-f $configPath && -f './config/pepper_config.xml.example') {
    print "Copying config from example..." . "\n";
    system('cp', './config/pepper_config.xml.example', './config/pepper_config.xml');
}

if(-f $configPath) {
    open(my $fh, '<', $configPath);
    $configXml = do { local $/; <$fh> };
    close($fh);
    print "✓ Config loaded (CARDTYPES_AUTODETECT handled automatically)" . "\n";
} else{
    die "ERROR: Config file not found. See examples/README.md for setup.\n";
}

# Create Pepper Simple instance
print "\n--- Initializing Payment System ---" . "\n";

my $pepper;
eval {
    $pepper = Lib::Pepper::Simple->new(
        terminal_type    => $TERMINAL_TYPE,
        terminal_address => $TERMINAL_IP,
        config_xml       => $configXml,
        license_xml      => $licenseXml,
        library_path     => (-f '../libpepcore.so' ? do {
            require Cwd;
            my $devDir = Cwd::abs_path('..');
            "$devDir/libpepcore.so";
        } : ''),
        pos_number       => '0001',
        merchant_password => '000000',
        language         => PEP_LANGUAGE_ENGLISH,
    );
};

if($EVAL_ERROR) {
    print "✗ Initialization failed: $EVAL_ERROR" . "\n";
    exit 1;
}

print "✓ Payment system initialized and ready\n" . "\n";

# Check status
my $status = $pepper->checkStatus();
print "--- System Status ---" . "\n";
print "  Initialized: " . ($status->{library_initialized} ? "YES" : "NO") . "\n";
print "  Configured: " . ($status->{instance_configured} ? "YES" : "NO") . "\n";
print "  Connection Open: " . ($status->{connection_open} ? "YES" : "NO") . "\n";
print "  Ready: " . ($status->{ready_for_transactions} ? "YES" : "NO") . "\n";
print "" . "\n";

if(!$status->{ready_for_transactions}) {
    print "✗ System not ready for settlement" . "\n";
    exit 1;
}

################################################################################
# END-OF-DAY SETTLEMENT
################################################################################

print "=" x 70 . "\n";
print "END-OF-DAY SETTLEMENT (BATCH CLOSE)" . "\n";
print "=" x 70 . "\n";
print "" . "\n";
print "⚠  WARNING: This will finalize ALL transactions for today!" . "\n";
print "" . "\n";
print "What this does:" . "\n";
print "  - Finalizes all pending transactions" . "\n";
print "  - Submits batch to payment processor" . "\n";
print "  - Triggers money transfer to merchant account" . "\n";
print "  - Prints settlement reports on terminal" . "\n";
print "  - Clears transaction buffer" . "\n";
print "" . "\n";
print "After settlement:" . "\n";
print "  - VOID no longer works for today's transactions" . "\n";
print "  - Must use REFUND for any cancellations" . "\n";
print "  - Terminal ready for next business day" . "\n";
print "" . "\n";

# Confirmation prompt
print "Proceed with settlement? (yes/no): ";
my $confirm = <STDIN>;
chomp($confirm);

if($confirm !~ /^y(es)?$/i) {
    print "\nSettlement cancelled by user." . "\n";
    print "⚠  Transactions remain pending!" . "\n";
    print "⚠  You will NOT receive payment until settlement is completed!" . "\n";
    exit 0;
}

print "" . "\n";
print "Processing settlement..." . "\n";
print "This may take 30-60 seconds, please wait..." . "\n";
print "" . "\n";

my $result;
eval {
    $result = $pepper->endOfDay();
};

if($EVAL_ERROR) {
    print "\n" . ("=" x 70) . "\n";
    print "[ERROR] Settlement Failed" . "\n";
    print "=" x 70 . "\n";
    print $EVAL_ERROR . "\n";
    print "" . "\n";
    print "⚠  CRITICAL: Transactions remain pending!" . "\n";
    print "⚠  You will NOT receive payment until settlement succeeds!" . "\n";
    print "" . "\n";
    print "Possible actions:" . "\n";
    print "  1. Check terminal display for error messages" . "\n";
    print "  2. Verify network connectivity to payment processor" . "\n";
    print "  3. Ensure terminal has power and is responsive" . "\n";
    print "  4. Retry settlement operation" . "\n";
    print "  5. Contact payment processor support if problem persists" . "\n";
    print "" . "\n";
    print "DO NOT assume transactions are settled until this succeeds!" . "\n";
    exit 1;
}

# Display results
print "\n" . ("=" x 70) . "\n";
print "[SETTLEMENT RESULT]" . "\n";
print "=" x 70 . "\n";

if($result->{success}) {
    print "\n✓✓✓ SETTLEMENT SUCCESSFUL ✓✓✓" . "\n";
    print "" . "\n";
    print "Status: Settlement completed successfully" . "\n";

    # Display settlement details if available
    if($result->{transaction_count}) {
        print "\n--- Settlement Summary ---" . "\n";
        print "Transactions Processed: $result->{transaction_count}" . "\n";

        if($result->{total_amount}) {
            print "Total Amount: " . sprintf("%.2f EUR", $result->{total_amount} / 100) . "\n";
        }

        if($result->{settlement_date}) {
            print "Settlement Date: $result->{settlement_date}" . "\n";
        }

        if($result->{settlement_time}) {
            print "Settlement Time: $result->{settlement_time}" . "\n";
        }
    }

    print "\n--- What Happened ---" . "\n";
    print "✓ All transactions finalized" . "\n";
    print "✓ Batch submitted to payment processor" . "\n";
    print "✓ Money transfer initiated to merchant account" . "\n";
    print "✓ Settlement reports printed on terminal" . "\n";
    print "✓ Transaction buffer cleared" . "\n";

    print "\n--- Next Steps ---" . "\n";
    print "✓ Keep settlement reports for reconciliation" . "\n";
    print "✓ Verify transaction counts match your records" . "\n";
    print "✓ Terminal is ready for next business day" . "\n";
    print "⚠  VOID no longer works for today's transactions" . "\n";
    print "⚠  Use REFUND for any returns from today onwards" . "\n";

    print "\n--- Payment Transfer ---" . "\n";
    print "✓ Payment transfer has been initiated" . "\n";
    print "✓ Funds typically arrive in 1-3 business days" . "\n";
    print "✓ Check your merchant account statement" . "\n";

} else {
    print "\n✗✗✗ SETTLEMENT FAILED ✗✗✗" . "\n";
    print "" . "\n";

    if($result->{status_text}) {
        print "Status: $result->{status_text}" . "\n";
    }

    if($result->{error}) {
        print "Error: $result->{error}" . "\n";
    }

    print "" . "\n";
    print "⚠  CRITICAL: Transactions remain pending!" . "\n";
    print "⚠  You will NOT receive payment until settlement succeeds!" . "\n";
    print "" . "\n";
    print "Common causes:" . "\n";
    print "  - Network connectivity issues" . "\n";
    print "  - Payment processor temporarily unavailable" . "\n";
    print "  - Terminal configuration problems" . "\n";
    print "  - No transactions to settle" . "\n";
    print "" . "\n";
    print "Recommended actions:" . "\n";
    print "  1. Verify terminal is online and responsive" . "\n";
    print "  2. Check network connectivity" . "\n";
    print "  3. Review terminal display for messages" . "\n";
    print "  4. Retry settlement operation" . "\n";
    print "  5. Contact support if problem persists" . "\n";
}

print "\n" . ("=" x 70) . "\n";
print "" . "\n";

# Cleanup happens automatically when $pepper goes out of scope
print "✓ Cleanup completed" . "\n";
print "\n=== Settlement Example Completed ===\n" . "\n";

__END__

=head1 SETTLEMENT WORKFLOW

A typical end-of-day workflow:

=head2 1. Complete All Transactions

Ensure all customer transactions for the day are finished before starting
settlement. No new transactions should be initiated during settlement.

=head2 2. Run Settlement

Execute this script or call C<endOfDay()> in your application:

    my $result = $pepper->endOfDay();

=head2 3. Verify Success

Check the C<success> field in the result:

    if($result->{success}) {
        log_settlement($result->{transaction_count}, $result->{total_amount});
    }

=head2 4. Keep Reports

The terminal will print settlement reports. Keep these for:

- Reconciliation with your records
- Accounting purposes
- Dispute resolution
- Audit trail

=head2 5. Monitor Payment Transfer

- Funds typically arrive in 1-3 business days
- Check your merchant account statement
- Contact processor if payment doesn't arrive

=head1 TROUBLESHOOTING

=head2 Settlement Fails

If settlement fails:

1. Check terminal display for error messages
2. Verify network connectivity
3. Ensure payment processor is available
4. Check terminal time/date settings
5. Retry the operation

B<DO NOT> assume transactions are settled until you receive success confirmation!

=head2 No Transactions to Settle

If there were no transactions today, settlement may return an error or success
with zero transaction count. This is normal.

=head2 Settlement Takes Too Long

Settlement typically takes 30-60 seconds. If it takes longer:

- Check network connection speed
- Verify processor is responding
- Terminal may be processing large batch
- Contact support if consistently slow

=head1 MULTIPLE SETTLEMENTS PER DAY

High-volume merchants may run settlement multiple times per day:

- Morning batch (overnight transactions)
- Afternoon batch (lunch rush)
- Evening batch (final settlement)

Benefits:

- Faster payment processing
- Smaller batches process faster
- Better cash flow management
- Reduced risk of large batch failures

=head1 INTEGRATION WITH YOUR APPLICATION

Example integration in a point-of-sale system:

    # At end of business day
    sub close_business_day {
        my $pepper = Lib::Pepper::Simple->new(...);

        my $result = $pepper->endOfDay();

        if($result->{success}) {
            # Update database
            $dbh->do(
                "INSERT INTO daily_settlements (date, transaction_count, total_amount)
                 VALUES (?, ?, ?)",
                undef,
                DateTime->now->ymd,
                $result->{transaction_count},
                $result->{total_amount}
            );

            # Send notification
            send_email_notification($result);

            return 1;
        } else {
            # Alert staff
            alert_manager("Settlement failed: " . $result->{error});
            return 0;
        }
    }

=head1 WARNING: AI USE

Warning, this file was generated with the help of the 'Claude' AI (an LLM/large
language model by the USA company Anthropic PBC) in November 2025. It was not
reviewed line-by-line by a human, only on a functional level. It is therefore
not up to the usual code quality and review standards. Different copyright laws
may also apply, since the program was not created by humans but mostly by a machine,
therefore the laws requiring a human creative process may or may not apply. Laws
regarding AI use are changing rapidly. Before using the code provided in this
file for any of your projects, make sure to check the current version of your
local laws.

=head1 SEE ALSO

- L<Lib::Pepper::Simple> - Module documentation
- simple_payment_example.pl - Payment processing example
- simple_daily_workflow.pl - Complete daily workflow including settlement
- real_terminal_test.pl - Low-level API example

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=cut
