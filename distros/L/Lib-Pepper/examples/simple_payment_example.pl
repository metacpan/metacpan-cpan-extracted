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

###############################################################################
# Reporting Handler (Reph) - Simple logging implementation
###############################################################################

package Reph;

sub new($proto, %config) {
    my $class = ref($proto) || $proto;
    my $self = bless \%config, $class;
    return $self;
}

sub debuglog($self, @parts) {
    print 'REPH: ', join('', @parts), "\n";
    return;
}

package main;

###############################################################################

=head1 NAME

simple_payment_example.pl - Simple payment processing with Lib::Pepper::Simple

=head1 DESCRIPTION

This example demonstrates the easiest way to process payments using the
Lib::Pepper::Simple high-level API. All the complexity of initialization,
configuration, connection management, and recovery is handled automatically.

B<Note about printer control>: The --terminal-print flag controls the software
setting for terminal printing. However, some terminals (including GP PAY) may
ignore this setting due to firmware-level configuration. If your terminal
continues to print despite not using --terminal-print, you will need to disable
the printer in the terminal's admin menu. See PRINTER_CONTROL_NOTES.md for
detailed troubleshooting.

=head1 SYNOPSIS

    # Process a single payment
    perl simple_payment_example.pl

    # Process custom amount (in cents)
    AMOUNT=500 perl simple_payment_example.pl  # 5.00 EUR

    # Enable terminal printing (default: disabled to save paper)
    perl simple_payment_example.pl --terminal-print

    # Cancel a payment (requires reference number from original payment)
    perl simple_payment_example.pl --cancel <trace_number> <amount> --reference <reference_number>

=cut

# Check for cancellation mode
my $cancelMode = 0;
my $cancelTraceNumber;
my $cancelAmount;
my $cancelReferenceNumber;

# Check if --cancel appears anywhere in arguments
if(contains('--cancel', \@ARGV)) {
    # Check for --reference flag
    my $hasReference = contains('--reference', \@ARGV);

    # Determine expected argument count based on flags
    my $expectedArgs = 3 + ($hasReference ? 2 : 0);

    # Validate proper usage
    if(@ARGV == $expectedArgs && $ARGV[0] eq '--cancel' && $ARGV[1] && $ARGV[2] =~ /^\d+$/) {
        # Correct usage
        $cancelMode = 1;
        $cancelTraceNumber = $ARGV[1];
        $cancelAmount = $ARGV[2];

        # Parse --reference if present
        if($hasReference) {
            # Find --reference position and get the value after it
            for(my $i = 0; $i < @ARGV; $i++) {
                if($ARGV[$i] eq '--reference' && defined $ARGV[$i + 1]) {
                    $cancelReferenceNumber = $ARGV[$i + 1];
                    last;
                }
            }
        }
    } else {
        # Incorrect usage
        print "Usage: $0 --cancel <trace_number> <amount> --reference <reference_number>" . "\n";
        print "" . "\n";
        print "Arguments:" . "\n";
        print "  trace_number      - Transaction trace number from original payment" . "\n";
        print "  amount            - Transaction amount in cents (must match original)" . "\n";
        print "  reference_number  - Transaction reference number from original payment" . "\n";
        print "" . "\n";
        print "IMPORTANT: Both trace_number AND reference_number must be stored" . "\n";
        print "           when processing the original payment!" . "\n";
        print "" . "\n";
        print "Examples:" . "\n";
        print "  $0 --cancel 5005 100 --reference 59" . "\n";
        exit 1;
    }
}

# Check for terminal printing flag
my $terminalPrint = contains('--terminal-print', \@ARGV) ? 1 : 0;

print "=== Simple Payment Processing Example ===\n" . "\n";

# Configuration
my $TERMINAL_IP = '192.168.1.163:20008';  # GP PAY terminal
my $TERMINAL_TYPE = PEP_TERMINAL_TYPE_GENERIC_ZVT;
my $TEST_AMOUNT = $ENV{AMOUNT} // 100;  # Default: 1.00 EUR

my $printingMode = $terminalPrint ? 1 : 0;
my $printingModeText = $terminalPrint ? "ENABLED (mode 1 - EFT prints)" : "DISABLED (mode 0 - POS handles printing)";

if($cancelMode) {
    print "MODE: Payment Refund" . "\n";
    print "Terminal: GP PAY" . "\n";
    print "Address: $TERMINAL_IP" . "\n";
    print "Trace Number: $cancelTraceNumber" . "\n";
    print "Reference Number: " . ($cancelReferenceNumber // "NOT PROVIDED") . "\n";
    print "Amount: " . sprintf("%.2f EUR", $cancelAmount / 100) . "\n";
    print "Terminal Printing: $printingModeText\n" . "\n";
} else {
    print "Terminal: GP PAY" . "\n";
    print "Address: $TERMINAL_IP" . "\n";
    print "Amount: " . sprintf("%.2f EUR", $TEST_AMOUNT / 100) . "\n";
    print "Terminal Printing: $printingModeText\n" . "\n";
}

# Load license file
my $license_xml;
my $license_path = '/home/cavac/src/pepperclient/pepper_license_8v5r22cg.xml';
if(-f $license_path) {
    open(my $fh, '<', $license_path);
    $license_xml = do { local $/; <$fh> };
    close($fh);
    print "✓ License loaded" . "\n";
} else {
    die "ERROR: License file not found at $license_path\n";
}

# Load config file
my $config_xml;
my $config_path = './config/pepper_config.xml';
if(!-f $config_path && -f './config/pepper_config.xml.example') {
    print "Copying config from example..." . "\n";
    system('cp', './config/pepper_config.xml.example', './config/pepper_config.xml');
}

if(-f $config_path) {
    open(my $fh, '<', $config_path);
    $config_xml = do { local $/; <$fh> };
    close($fh);
    print "✓ Config loaded (CARDTYPES_AUTODETECT handled automatically)" . "\n";
} else {
    die "ERROR: Config file not found. See examples/README.md for setup.\n";
}

# Create Pepper Simple instance
# This single constructor handles:
#   - Library initialization
#   - Instance creation
#   - Terminal configuration
#   - Automatic recovery (if needed)
#   - Connection establishment
print "\n--- Initializing Payment System ---" . "\n";

# Create reporting handler for audit logging
my $reph = Reph->new();

my $pepper;
eval {
    $pepper = Lib::Pepper::Simple->new(
        terminal_type        => $TERMINAL_TYPE,
        terminal_address     => $TERMINAL_IP,
        config_xml           => $config_xml,
        license_xml          => $license_xml,
        library_path         => (-f '../libpepcore.so' ? do {
            require Cwd;
            my $devDir = Cwd::abs_path('..');
            "$devDir/libpepcore.so";
        } : ''),
        pos_number           => '0001',
        merchant_password    => '000000',
        language             => PEP_LANGUAGE_ENGLISH,
        ticket_printing_mode => $printingMode,  # 0=POS prints, 1=EFT prints
        reph                 => $reph,           # Reporting handler for audit logging
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
    print "✗ System not ready for transactions" . "\n";
    exit 1;
}

################################################################################
# CANCELLATION MODE
################################################################################

if($cancelMode) {
    print "=" x 70 . "\n";
    print "REFUNDING PAYMENT" . "\n";
    print "=" x 70 . "\n";
    print "" . "\n";
    print "Trace Number: $cancelTraceNumber" . "\n";
    print "Reference Number: " . ($cancelReferenceNumber // "NOT PROVIDED") . "\n";
    print "Amount: " . sprintf("%.2f EUR", $cancelAmount / 100) . "\n";
    print "" . "\n";
    print "Performing referenced credit (card-not-present refund)..." . "\n";
    print "" . "\n";

    my $result;
    eval {
        $result = $pepper->cancelPayment(
            $cancelTraceNumber,
            $cancelAmount,
            reference_number => $cancelReferenceNumber,
        );
    };

    if($EVAL_ERROR) {
        print "\n" . ("=" x 70) . "\n";
        print "[ERROR] Refund Failed" . "\n";
        print "=" x 70 . "\n";
        print $EVAL_ERROR . "\n";
        exit 1;
    }

    # Display results
    print "\n" . ("=" x 70) . "\n";
    print "[REFUND RESULT]" . "\n";
    print "=" x 70 . "\n";

    if($result->{success}) {
        print "\n✓✓✓ REFUND SUCCESSFUL ✓✓✓" . "\n";
        print "" . "\n";
        print "Amount Refunded: " . sprintf("%.2f EUR", $result->{amount_refunded} / 100) . "\n";
        print "" . "\n";
        print "--- Transaction Details ---" . "\n";
        print "Refund Trace Number: $result->{trace_number}" if $result->{trace_number} . "\n";
        print "Status: $result->{transaction_text}" if $result->{transaction_text} . "\n";
        print "" . "\n";
        print "--- Next Steps ---" . "\n";
        print "✓ Customer will receive refund in 3-5 business days" . "\n";
        print "✓ Original charge will be reversed" . "\n";
        print "✓ Update your order status to 'refunded'" . "\n";

    } else {
        print "\n✗✗✗ REFUND FAILED ✗✗✗" . "\n";
        print "" . "\n";
        print "Status: $result->{transaction_text}" if $result->{transaction_text} . "\n";
        print "" . "\n";
        print "Possible reasons:" . "\n";
        print "  - Transaction not found (check trace/reference numbers)" . "\n";
        print "  - Already refunded" . "\n";
        print "  - Terminal communication error" . "\n";
        print "  - Invalid trace number, reference number, or amount" . "\n";
        print "" . "\n";
        print "Troubleshooting:" . "\n";
        print "  - Verify trace number from original payment" . "\n";
        print "  - Verify reference number from original payment" . "\n";
        print "  - Verify amount matches original payment exactly" . "\n";
    }

    print "\n" . ("=" x 70) . "\n";
    print "" . "\n";

    # Cleanup happens automatically
    print "✓ Cleanup completed" . "\n";
    print "\n=== Cancellation Completed ===\n" . "\n";

    exit 0;
}

################################################################################
# PAYMENT MODE
################################################################################

# Perform payment
print "=" x 70 . "\n";
print "PROCESSING PAYMENT" . "\n";
print "=" x 70 . "\n";
print "" . "\n";
print "Amount: " . sprintf("%.2f EUR", $TEST_AMOUNT / 100) . "\n";
print "" . "\n";
print "Please follow instructions on the terminal screen." . "\n";
print "Insert/swipe your card when prompted." . "\n";
print "" . "\n";

my $result;
eval {
    $result = $pepper->doPayment(
        $TEST_AMOUNT,
        transaction_type => 'goods',
    );
};

if($EVAL_ERROR) {
    print "\n" . ("=" x 70) . "\n";
    print "[ERROR] Payment Failed" . "\n";
    print "=" x 70 . "\n";
    print $EVAL_ERROR . "\n";
    exit 1;
}

# Display results
print "\n" . ("=" x 70) . "\n";
print "[PAYMENT RESULT]" . "\n";
print "=" x 70 . "\n";

print "\nAPI Status: " . ($result->{success} ? "SUCCESS" : "FAILED") . "\n";
print "Payment Status: " . ($result->{authorized} ? "AUTHORIZED" : "DECLINED/ABORTED") . "\n";

if($result->{authorized}) {
    print "\n✓✓✓ PAYMENT SUCCESSFUL ✓✓✓" . "\n";
    print "" . "\n";
    print "Amount Charged: " . sprintf("%.2f EUR", $result->{amount_charged} / 100) . "\n";

    print "\n--- Transaction Details (SAVE THESE!) ---" . "\n";
    print "Trace Number: $result->{trace_number}" if $result->{trace_number} . "\n";
    print "Authorization Code: $result->{authorization_code}" if $result->{authorization_code} . "\n";
    print "Reference Number: $result->{reference_number}" if $result->{reference_number} . "\n";
    print "Terminal ID: $result->{terminal_id}" if $result->{terminal_id} . "\n";
    print "Transaction Date: $result->{transaction_date}" if $result->{transaction_date} . "\n";
    print "Transaction Time: $result->{transaction_time}" if $result->{transaction_time} . "\n";

    print "\n--- Card Information ---" . "\n";
    print "Card Type: $result->{card_name}" if $result->{card_name} . "\n";
    print "Card Number: $result->{card_number}" if $result->{card_number} . "\n";
    print "Card Expiry: $result->{card_expiry}" if $result->{card_expiry} . "\n";

    print "\n--- Next Steps ---" . "\n";
    print "✓ Customer has been charged" . "\n";
    print "✓ Store BOTH Trace Number AND Reference Number in your database" . "\n";
    print "✓ Both are required for refunds" . "\n";
    print "✓ Run end-of-day settlement to receive payment" . "\n";

    # Example cancellation code
    print "\nTo refund this payment:" . "\n";
    print "  perl simple_payment_example.pl --cancel $result->{trace_number} $TEST_AMOUNT --reference $result->{reference_number}" . "\n";

} else {
    print "\n✗✗✗ PAYMENT DECLINED/ABORTED ✗✗✗" . "\n";
    print "" . "\n";
    print "Status Text: $result->{status_text}" if $result->{status_text} . "\n";
    print "Result Code: $result->{transaction_result}" if defined $result->{transaction_result} . "\n";
    print "" . "\n";
    print "Possible reasons:" . "\n";
    print "  - Customer canceled transaction" . "\n";
    print "  - Card declined by issuer" . "\n";
    print "  - Insufficient funds" . "\n";
    print "  - Invalid card" . "\n";
    print "  - Transaction timeout" . "\n";
    print "" . "\n";
    print "✓ NO MONEY WAS CHARGED" . "\n";
}

print "\n" . ("=" x 70) . "\n";
print "" . "\n";

# Cleanup happens automatically when $pepper goes out of scope
print "✓ Cleanup completed" . "\n";
print "\n=== Example Completed ===\n" . "\n";

__END__

=head1 WHAT THIS EXAMPLE DEMONSTRATES

=over 4

=item * Single-constructor initialization

All setup handled in one Lib::Pepper::Simple->new() call

=item * Automatic recovery

If terminal has incomplete operations, they're handled automatically

=item * Simple payment processing

One method call: doPayment()

=item * Clear result structure

Easy access to all transaction details

=item * Automatic cleanup

DESTROY method handles all cleanup when object goes out of scope

=back

=head1 COMPARISON WITH LOW-LEVEL API

Low-level API (Lib::Pepper::Instance):
- Initialize library manually
- Create instance manually
- Configure instance manually
- Check recovery flag manually
- Perform recovery operation manually (4 steps)
- Open connection manually (4 steps or high-level)
- Transaction (4 steps or high-level)
- Manual cleanup

High-level API (Lib::Pepper::Simple):
- new() - everything initialized automatically
- doPayment() - single method call
- Automatic cleanup

=head1 TRANSACTION IDENTIFIERS

The trace_number is the PRIMARY identifier for cancellation operations.
ALWAYS store this in your database alongside the order/transaction record.

Example database schema:

    CREATE TABLE payments (
        id SERIAL PRIMARY KEY,
        order_id INTEGER,
        amount INTEGER NOT NULL,
        trace_number VARCHAR(20) NOT NULL,
        authorization_code VARCHAR(20),
        transaction_date DATE,
        status VARCHAR(20),
        created_at TIMESTAMP DEFAULT NOW()
    );

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
- simple_daily_workflow.pl - Complete daily workflow example
- real_terminal_test.pl - Low-level API example

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=cut
