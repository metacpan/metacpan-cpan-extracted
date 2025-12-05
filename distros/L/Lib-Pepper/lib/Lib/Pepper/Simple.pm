package Lib::Pepper::Simple;
#---AUTOPRAGMASTART---
use v5.42;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 0.5;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---


use Lib::Pepper;
use Lib::Pepper::Instance;
use Lib::Pepper::OptionList;
use Lib::Pepper::Constants qw(:all);

# Package-level state for multi-terminal support
# These variables track the library initialization state across all instances
our $LIBRARY_INITIALIZED = 0;           # Boolean: Library initialized in this process?
our $INSTANCE_COUNT = 0;                # Integer: Number of active instances
our $INIT_LIBRARY_PATH = '';            # String: Library path used for initialization
our $INIT_CONFIG_XML = undef;           # String: Config XML used for initialization
our $INIT_LICENSE_XML = undef;          # String: License XML used for initialization
our %INSTANCE_ID_COUNTERS = ();         # Hash: terminal_type => next_available_id

# High-level wrapper for Lib::Pepper providing simple payment terminal operations

sub new($proto, %params) {
    my $class = ref($proto) || $proto;

    # Validate required parameters
    if(!defined $params{terminal_type}) {
        croak("new: terminal_type parameter is required");
    }
    if(!defined $params{terminal_address}) {
        croak("new: terminal_address parameter is required");
    }

    # Handle config: accept either config_file OR config_xml
    my $configXml;
    if(defined $params{config_xml}) {
        $configXml = $params{config_xml};
    } elsif(defined $params{config_file}) {
        # Load config from file
        if(!-f $params{config_file}) {
            croak("new: config_file '$params{config_file}' does not exist");
        }
        open(my $fh, '<', $params{config_file}) or croak("new: cannot open config_file '$params{config_file}': $ERRNO");
        $configXml = do { local $INPUT_RECORD_SEPARATOR = undef; <$fh> };
        close($fh);
    } else {
        croak("new: either config_xml or config_file parameter is required");
    }

    # Handle license: accept either license_file OR license_xml
    my $licenseXml;
    if(defined $params{license_xml}) {
        $licenseXml = $params{license_xml};
    } elsif(defined $params{license_file}) {
        # Load license from file
        if(!-f $params{license_file}) {
            croak("new: license_file '$params{license_file}' does not exist");
        }
        open(my $fh, '<', $params{license_file}) or croak("new: cannot open license_file '$params{license_file}': $ERRNO");
        $licenseXml = do { local $INPUT_RECORD_SEPARATOR = undef; <$fh> };
        close($fh);
    } else {
        croak("new: either license_xml or license_file parameter is required");
    }

    # Create object with default values
    my $self = bless {
        # Library state
        initialized      => 0,
        library_path     => $params{library_path} // '',
        config_xml       => $configXml,
        license_xml      => $licenseXml,

        # Instance state
        instance         => undef,
        terminal_type    => $params{terminal_type},
        terminal_address => $params{terminal_address},
        configured       => 0,

        # Configuration
        pos_number           => $params{pos_number} // '0001',
        merchant_password    => $params{merchant_password} // '000000',
        language             => $params{language} // PEP_LANGUAGE_ENGLISH,
        ticket_width         => $params{ticket_width} // 40,
        ticket_printing_mode => $params{ticket_printing_mode} // 0,  # Default: POS prints (disables terminal printer)
        tip_enabled          => $params{tip_enabled} // 0,         # Default: no tip dialog

        # Callback handling
        callback         => $params{callback},
        userdata         => $params{userdata} // {},

        # Logging
        reph             => $params{reph},  # Optional reporting handler with debuglog() method

        # State tracking
        connection_open  => 0,
        last_error       => undef,
        last_transaction => undef,

        # Multi-instance support: Track if this instance was counted
        _instance_counted => 0,  # Set to 1 only after successful initialization
    }, $class;

    # Set config_byte based on ticket_printing_mode if not explicitly provided
    # Mode 1 (EFT prints) = PEP_CONFIG_BYTE_NORMAL (normal operation)
    # Mode 0 (POS prints) = PEP_CONFIG_BYTE_DISABLE_PRINTER (disable terminal printer)
    # Other modes = PEP_CONFIG_BYTE_NORMAL (normal operation)
    if(exists $params{config_byte}) {
        # User explicitly provided config_byte, use it
        $self->{config_byte} = $params{config_byte};
    } else {
        # Auto-calculate based on ticket_printing_mode
        $self->{config_byte} = ($self->{ticket_printing_mode} == 0)
            ? PEP_CONFIG_BYTE_DISABLE_PRINTER
            : PEP_CONFIG_BYTE_NORMAL;
    }

    # Handle CARDTYPES_AUTODETECT placeholder if present
    if($self->{config_xml} =~ /CARDTYPES_AUTODETECT/) {
        my $cardtypesPath = Lib::Pepper->cardtypesFile();
        if(!defined $cardtypesPath) {
            croak("Could not find installed pepper_cardtypes.xml file");
        }
        $self->{config_xml} =~ s/CARDTYPES_AUTODETECT/$cardtypesPath/g;
    }

    # Attempt full initialization
    my $success = 0;
    my $needsInitialization = !$LIBRARY_INITIALIZED;  # Declared before eval for error handling

    eval {

        # ========================================
        # MULTI-INSTANCE SUPPORT: Library initialization
        # ========================================
        # Initialize Pepper library only if not already initialized
        # This allows multiple terminals to share the same library instance

        if($needsInitialization) {
            # First instance - initialize library
            Lib::Pepper->initialize(
                library_path => $self->{library_path},
                config_xml   => $self->{config_xml},
                license_xml  => $self->{license_xml},
            );

            # Store initialization parameters for validation of subsequent instances
            $INIT_LIBRARY_PATH = $self->{library_path};
            $INIT_CONFIG_XML = $self->{config_xml};
            $INIT_LICENSE_XML = $self->{license_xml};
            $LIBRARY_INITIALIZED = 1;

            $self->{initialized} = 1;
        } else {
            # Library already initialized - validate config compatibility
            if(!_validate_config($self->{library_path}, $self->{config_xml}, $self->{license_xml})) {
                croak("Configuration mismatch: Lib::Pepper library already initialized with different config. " .
                      "All Lib::Pepper::Simple instances in the same process must use identical " .
                      "library_path, config_xml, and license_xml parameters.");
            }
            $self->{initialized} = 1;  # Library is already initialized
        }

        # ========================================
        # MULTI-INSTANCE SUPPORT: Instance ID allocation
        # ========================================
        # Allocate instance_id automatically if not provided by user
        # Instance IDs are managed per terminal_type
        my $instanceId = $params{instance_id};
        if(!defined $instanceId) {
            $instanceId = _allocate_instance_id($self->{terminal_type});
        }
        # Store instance_id in object for status reporting
        $self->{instance_id} = $instanceId;

        # Create instance
        $self->{instance} = Lib::Pepper::Instance->new(
            terminal_type => $self->{terminal_type},
            instance_id   => $instanceId,
            reph          => $self->{reph},  # Pass reporting handler down
        );

        # Configure instance
        my $configResult = $self->{instance}->configure(
            callback => $self->{callback} // \&_defaultCallback,
            options  => {
                sHostName                => $self->{terminal_address},
                iLanguageValue           => $self->{language},
                sPosIdentificationString => $self->{pos_number},
                iTicketWidthValue        => $self->{ticket_width},
                iConfigByteValue         => $self->{config_byte},
                sMerchantPasswordString  => $self->{merchant_password},
                iTicketPrintingModeValue => $self->{ticket_printing_mode},
            },
            userdata => $self->{userdata},
        );
        $self->{configured} = 1;

        # Check and handle recovery flag automatically
        if(defined $configResult) {
            my $configData = $configResult->toHashref();
            my $recoveryFlag = $configData->{iRecoveryFlag} // 0;

            if($recoveryFlag) {
                # Perform recovery operation automatically
                my $recoveryOptions = Lib::Pepper::OptionList->new();

                my ($op1, $out1) = $self->{instance}->prepareOperation(PEP_OPERATION_RECOVERY, $recoveryOptions);
                my ($op2, $out2) = $self->{instance}->startOperation(PEP_OPERATION_RECOVERY, $recoveryOptions);
                my ($op3, $out3) = $self->{instance}->executeOperation(PEP_OPERATION_RECOVERY, $recoveryOptions);
                my ($op4, $out4) = $self->{instance}->finalizeOperation(PEP_OPERATION_RECOVERY, $recoveryOptions);

                my $recoveryStatus = $self->{instance}->operationStatus($op4, 1);
                if(!$recoveryStatus) {
                    croak("Recovery operation did not complete successfully");
                }
            }
        }

        # Open connection (required for ZVT terminals)
        my $openResult = $self->{instance}->openConnection(
            options => {
                sOperatorIdentificationString => $params{operator_id} // 'OPERATOR01',
            }
        );

        # Wait for OPEN to complete if pending
        if(!$openResult->{status}) {
            my $opHandle = $openResult->{operation_handle};
            my $waitStatus = $self->{instance}->operationStatus($opHandle, 1);
            if(!$waitStatus) {
                croak("OPEN operation did not complete successfully");
            }
        }
        $self->{connection_open} = 1;

        $success = 1;
    };

    if(!$success) {
        my $error = $EVAL_ERROR;

        # ========================================
        # MULTI-INSTANCE SUPPORT: Cleanup on failure
        # ========================================
        # Note: We do NOT finalize the library on failure.
        # The library stays initialized, allowing retry attempts.
        # Instance counter was NOT incremented yet, so nothing to decrement.
        # This is consistent with our never-finalize design.

        croak("Failed to initialize Lib::Pepper::Simple: $error");
    }

    # ========================================
    # MULTI-INSTANCE SUPPORT: Increment instance counter
    # ========================================
    # Only increment after successful initialization
    # This ensures the counter stays accurate even if initialization fails
    $INSTANCE_COUNT++;
    $self->{_instance_counted} = 1;  # Mark that this instance was counted

    return $self;
}

sub checkStatus($self) {
    my $status = {
        # Instance-level status
        library_initialized   => $self->{initialized},
        instance_configured   => $self->{configured},
        connection_open       => $self->{connection_open},
        terminal_type         => $self->{terminal_type},
        terminal_address      => $self->{terminal_address},
        instance_id           => $self->{instance_id},
        ready_for_transactions => 0,
        last_error            => $self->{last_error},

        # Process-level status (multi-terminal support)
        process_instance_count       => $INSTANCE_COUNT,
        process_library_initialized  => $LIBRARY_INITIALIZED,
    };

    # Ready if all critical components are initialized
    $status->{ready_for_transactions} = (
        $status->{library_initialized} &&
        $status->{instance_configured} &&
        $status->{connection_open}
    );

    return $status;
}

sub doPayment($self, $amount, %options) {
    # Validate state
    if(!$self->{connection_open}) {
        croak("doPayment: connection not open");
    }
    if(!$self->{configured}) {
        croak("doPayment: instance not configured");
    }

    # Validate amount
    if(!defined $amount || $amount !~ /^\d+$/ || $amount <= 0) {
        croak("doPayment: amount must be a positive integer (cents)");
    }

    # Build transaction parameters
    my $transactionType = $options{transaction_type} // PEP_TRANSACTION_TYPE_GOODS_PAYMENT;

    # Convert string transaction types to constants
    if(defined $transactionType && $transactionType !~ /^\d+$/) {
        if($transactionType eq 'goods') {
            $transactionType = PEP_TRANSACTION_TYPE_GOODS_PAYMENT;
        } else {
            croak("doPayment: invalid transaction_type '$transactionType' (use 'goods' or numeric constant)");
        }
    }

    my $currency = $options{currency};

    # Build additional options for the transaction
    my $txnOptions = $options{options} // {};

    # Tip support via Pepper API:
    # - Transaction type 13 (GoodsPaymentWithTip): NOT supported by GlobalPayments ZVT (returns -1402)
    # - iServiceByteValue bit 3 (tippable): Transaction completes but tip dialog depends on terminal config
    # - The tip prompt/dialog must be enabled at the TERMINAL level by your payment processor
    # - If you need tips, either:
    #   1. Contact GlobalPayments to enable tip prompting on your terminal
    #   2. Collect tip amount in your POS and pass it via doPayment(..., options => {iTipAmount => $tip})
    if($self->{tip_enabled}) {
        if(!exists $txnOptions->{iServiceByteValue}) {
            $txnOptions->{iServiceByteValue} = 8;  # Bit 3 = tippable
        } else {
            $txnOptions->{iServiceByteValue} |= 8;
        }
    }

    # Execute transaction
    my $result;
    my $success = 0;
    eval {
        $result = $self->{instance}->transaction(
            amount           => $amount,
            transaction_type => $transactionType,
            (defined $currency ? (currency => $currency) : ()),
            (keys %{$txnOptions} ? (options => $txnOptions) : ()),
        );
        $success = 1;
    };

    if(!$success) {
        $self->{last_error} = $EVAL_ERROR;
        return {
            success    => 0,
            authorized => 0,
            error      => $EVAL_ERROR,
        };
    }

    # Parse result output
    my $outputData = {};
    if(defined $result->{output}) {
        $outputData = $result->{output}->toHashref();
    }

    # Extract transaction result - CRITICAL: check iTransactionResultValue, not iFunctionResultValue!
    my $transactionResult = $outputData->{iTransactionResultValue} // -999;
    my $transactionText = $outputData->{sTransactionText} || '';

    # Build response
    my $response = {
        success            => $result->{status} ? 1 : 0,
        authorized         => ($transactionResult == 0) ? 1 : 0,
        amount_charged     => ($transactionResult == 0) ? $amount : 0,
        transaction_result => $transactionResult,
        transaction_text   => $transactionText,
        trace_number       => $outputData->{sTraceNumberString} || undef,
        authorization_code => $outputData->{sAuthorizationNumberString} || undef,
        reference_number   => $outputData->{sTransactionReferenceNumberString} || undef,
        terminal_id        => $outputData->{sTerminalIdentificationString} || undef,
        card_type          => $outputData->{sCardNameString} || undef,
        card_number        => $outputData->{sCardNumberString} || undef,
        transaction_date   => $outputData->{sTransactionDate} || undef,
        transaction_time   => $outputData->{sTransactionTime} || undef,
        raw_output         => $outputData,
    };

    # Store last transaction details
    $self->{last_transaction} = $response;
    $self->{last_error} = undef;

    return $response;
}

sub cancelPayment($self, $traceNumber, $amount, %options) {
    # Validate state
    if(!$self->{connection_open}) {
        croak("cancelPayment: connection not open");
    }
    if(!$self->{configured}) {
        croak("cancelPayment: instance not configured");
    }

    # Validate parameters
    if(!defined $traceNumber) {
        croak("cancelPayment: trace_number parameter is required");
    }
    if(!defined $amount || $amount !~ /^\d+$/ || $amount <= 0) {
        croak("cancelPayment: amount must be a positive integer (cents)");
    }
    if(!exists $options{reference_number} || !defined $options{reference_number}) {
        croak("cancelPayment: reference_number parameter is required for card-not-present refunds");
    }

    my $response = {
        success          => 0,
        trace_number     => undef,
        amount_refunded  => 0,
        transaction_text => '',
        raw_output       => {},
    };

    # Perform VOID (Transaction Type 12 - VoidGoodsPayment)
    # Using sTransactionReferenceNumberString for referenced void
    #
    # IMPORTANT: Despite being called "VOID", this works AFTER settlement when using
    # the reference number. This is the correct ZVT method for card-not-present refunds.
    # Transaction Type 41 (Credit) would require card swipe even with reference number.
    #
    # This discovery is not documented in Pepper docs but confirmed working on GP PAY
    # terminals with Generic ZVT protocol.
    my $refundResult;
    my $refundSuccess = 0;

    eval {
        # Build options for referenced void (no card required)
        my $refundOptions = {
            sTransactionReferenceNumberString => $options{reference_number},
        };

        if($ENV{DEBUG_PEPPER}) {
            $self->_log("=== VOID/REFUND Parameters ===");
            $self->_log("Transaction Type: VoidGoodsPayment (12)");
            $self->_log("Amount: $amount");
            for my $key (sort keys %{$refundOptions}) {
                $self->_log("$key: $refundOptions->{$key}");
            }
        }

        $refundResult = $self->{instance}->transaction(
            amount           => $amount,
            transaction_type => PEP_TRANSACTION_TYPE_VOID_GOODS_PAYMENT,
            options          => $refundOptions,
        );
        $refundSuccess = 1;
    };

    if(!$refundSuccess) {
        $self->{last_error} = "REFUND failed: $EVAL_ERROR";
        return $response;
    }

    if($ENV{DEBUG_PEPPER}) {
        $self->_log("=== REFUND Result Check ===");
        $self->_log("refundSuccess = $refundSuccess");
        $self->_log("refundResult defined = " . (defined $refundResult ? 'YES' : 'NO'));
        if(defined $refundResult) {
            $self->_log("refundResult->{output} defined = " . (defined $refundResult->{output} ? 'YES' : 'NO'));
        }
    }

    if(defined $refundResult->{output}) {
        my $refundData = $refundResult->{output}->toHashref();
        my $refundTransResult = $refundData->{iTransactionResultValue} // -999;
        my $refundTransText = $refundData->{sTransactionText} || '';

        if($ENV{DEBUG_PEPPER}) {
            $self->_log("iTransactionResultValue: $refundTransResult");
            $self->_log("sTransactionText: '$refundTransText'");
        }

        $response->{transaction_text} = $refundTransText;
        $response->{raw_output} = $refundData;

        if($refundTransResult == 0) {
            # REFUND succeeded!
            $response->{success} = 1;
            $response->{trace_number} = $refundData->{sTraceNumberString} || undef;
            $response->{amount_refunded} = $amount;

            $self->{last_error} = undef;
            return $response;
        } else {
            # REFUND failed
            $self->{last_error} = "REFUND failed: $refundTransText";
            return $response;
        }
    }

    $self->{last_error} = "REFUND failed: no output data";
    return $response;
}

sub endOfDay($self, %options) {
    # Validate state
    if(!$self->{connection_open}) {
        croak("endOfDay: connection not open");
    }
    if(!$self->{configured}) {
        croak("endOfDay: instance not configured");
    }

    # Execute settlement operation
    my $result;
    my $success = 0;
    eval {
        $result = $self->{instance}->settlement(
            options => $options{options} // {},
        );
        $success = 1;
    };

    if(!$success) {
        $self->{last_error} = $EVAL_ERROR;
        return {
            success => 0,
            error   => $EVAL_ERROR,
        };
    }

    # Parse settlement output
    my $outputData = {};
    if(defined $result->{output}) {
        $outputData = $result->{output}->toHashref();
    }

    # Check settlement result (use iFunctionResultValue for settlement)
    my $functionResult = $outputData->{iFunctionResultValue} // -999;
    my $functionText = $outputData->{sFunctionText} || '';

    # Build response
    my $response = {
        success           => ($functionResult == 0) ? 1 : 0,
        function_result   => $functionResult,
        function_text     => $functionText,
        transaction_count => $outputData->{iNumberOfTransactions} || 0,
        total_amount      => $outputData->{iTotalAmount} || 0,
        settlement_date   => $outputData->{sSettlementDate} || undef,
        settlement_time   => $outputData->{sSettlementTime} || undef,
        raw_output        => $outputData,
    };

    $self->{last_error} = ($functionResult == 0) ? undef : $functionText;

    return $response;
}

# Allocate a unique instance_id for the given terminal_type
# Instance IDs are managed per terminal type (e.g., Generic ZVT terminals get IDs 1, 2, 3, ...)
sub _allocate_instance_id($terminal_type) {
    # Initialize counter for this terminal type if not exists
    $INSTANCE_ID_COUNTERS{$terminal_type} //= 1;

    # Get current ID and increment for next time
    my $id = $INSTANCE_ID_COUNTERS{$terminal_type};
    $INSTANCE_ID_COUNTERS{$terminal_type}++;

    return $id;
}

# Validate that library initialization parameters match the first instance
# Returns 1 if valid, 0 if mismatch detected
sub _validate_config($library_path, $config_xml, $license_xml) {
    # If library not initialized yet, any config is valid (this is first instance)
    return 1 if !$LIBRARY_INITIALIZED;

    # Validate library_path matches
    if($library_path ne $INIT_LIBRARY_PATH) {
        return 0;
    }

    # Validate config_xml matches (strict - must be identical)
    if($config_xml ne $INIT_CONFIG_XML) {
        return 0;
    }

    # Validate license_xml matches
    if($license_xml ne $INIT_LICENSE_XML) {
        return 0;
    }

    return 1;
}

# Class method to check process-wide library status
# Returns hashref with library state information
sub library_status($class) {
    return {
        initialized     => $LIBRARY_INITIALIZED,
        instance_count  => $INSTANCE_COUNT,
        library_path    => $INIT_LIBRARY_PATH,
        instance_ids    => { %INSTANCE_ID_COUNTERS },
    };
}

sub DESTROY($self) {
    # Cleanup instance resources
    if($self->{instance}) {
        eval {
            # Connection cleanup handled by Instance destructor
            undef $self->{instance};
        };
    }

    # ========================================
    # MULTI-INSTANCE SUPPORT: Reference counting
    # ========================================
    # CRITICAL: Only decrement if this instance was actually counted!
    # If constructor failed before incrementing, don't decrement
    return unless $self->{_instance_counted};

    # Decrement the instance counter
    $INSTANCE_COUNT--;

    # ========================================
    # DESIGN DECISION: Never finalize the library
    # ========================================
    # The Pepper C library has a critical limitation: once pepFinalize() is called,
    # pepInitialize() cannot be called again in the same process (returns error -103).
    #
    # SOLUTION: We never call pepFinalize(), keeping the library loaded in memory.
    # This allows creating new instances even after all previous instances are destroyed.
    #
    # Trade-offs:
    #   PRO: Can create instances → destroy all → create new instances ✓
    #   PRO: No -103 errors, can run unlimited test iterations ✓
    #   PRO: Simpler lifecycle management ✓
    #   CON: Library stays in memory until process exit (~few MB)
    #   CON: Cannot reset library state without restarting process
    #
    # Note: Instance-level resources (connections, handles) are still properly cleaned up.
    #       Only the library initialization state persists.

    return;
}

# Internal logging helper - uses reph if available, falls back to STDERR
sub _log($self, @parts) {
    if($self->{reph} && $self->{reph}->can('debuglog')) {
        $self->{reph}->debuglog(@parts);
    } else {
        # Fallback to STDERR if no reph provided
        print STDERR join('', @parts), "\n";
    }
    return;
}

# Default callback if user doesn't provide one
sub _defaultCallback {
    # Silent default callback - user can provide their own for logging/debugging
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

Lib::Pepper::Simple - High-level payment terminal interface

=head1 SYNOPSIS

    use Lib::Pepper::Simple;
    use Lib::Pepper::Constants qw(:all);

    # Initialize connection to terminal
    my $pepper = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.163:20008',
        license_file     => '/path/to/license.xml',
        config_file      => '/path/to/config.xml',
    );

    # Check terminal status
    my $status = $pepper->checkStatus();
    if($status->{ready_for_transactions}) {
        print "Terminal ready!"\n";
    }

    # Process a payment (100.50 EUR)
    my $payment = $pepper->doPayment(10_050);
    if($payment->{authorized}) {
        print "Payment authorized!"\n";
        print "Trace: $payment->{trace_number}"\n";
        print "Auth: $payment->{authorization_code}"\n";

        # Store trace number for potential cancellation
        my $trace = $payment->{trace_number};
        my $amount = $payment->{amount_charged};
    }

    # Cancel a payment (automatically handles VOID or REFUND)
    my $cancel = $pepper->cancelPayment($trace, $amount);
    if($cancel->{success}) {
        print "Cancellation successful via $cancel->{method_used}"\n";
    }

    # End of day settlement
    my $settlement = $pepper->endOfDay();
    if($settlement->{success}) {
        print "Settled $settlement->{transaction_count} transactions"\n";
        print ""Total: " . sprintf("%.2f", $settlement->{total_amount} / 100)\n";
    }

    # MULTI-TERMINAL SUPPORT: Multiple terminals in same process
    my $terminal1 = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.163:20008',
        license_file     => $license,  # Must be SAME as terminal2
        config_file      => $config,   # Must be SAME as terminal2
    );

    my $terminal2 = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.164:20008',
        license_file     => $license,  # Must be SAME as terminal1
        config_file      => $config,   # Must be SAME as terminal1
    );

    # Check process-wide status
    my $libStatus = Lib::Pepper::Simple->library_status();
    print "Active terminals: $libStatus->{instance_count}"\n";

    # Process independent payments
    my $payment1 = $terminal1->doPayment(1000);
    my $payment2 = $terminal2->doPayment(2000);

=head1 DESCRIPTION

Lib::Pepper::Simple provides a high-level, easy-to-use interface for payment terminal
operations. It wraps the complexity of the Pepper library into 5 simple methods.

=head2 Key Features

=over 4

=item Automatic Initialization

Single constructor call handles library initialization, instance creation, configuration,
recovery operations, and connection opening.

=item Smart Cancellation

C<cancelPayment()> automatically tries VOID first (same-day instant cancellation), then
falls back to REFUND (settled transaction reversal) if needed.

=item Clear Return Values

All methods return structured hashrefs with clear field names, not raw library objects.

=item Automatic Recovery

Recovery operations are detected and performed automatically during initialization.

=item Production Ready

Comprehensive error handling, state validation, and proper cleanup.

=back

=head1 METHODS

=head2 new(%params)

Creates and fully initializes a payment terminal connection.

B<Required Parameters:>

=over 4

=item terminal_type

Terminal type constant, e.g. C<PEP_TERMINAL_TYPE_GENERIC_ZVT> (118)

=item terminal_address

Terminal IP and port, e.g. C<'192.168.1.163:20008'>

=item license_xml OR license_file

Either the XML content of the license (C<license_xml>) or the path to the license file (C<license_file>).
Use C<license_xml> when storing licenses in a database.

=item config_xml OR config_file

Either the XML content of the configuration (C<config_xml>) or the path to the config file (C<config_file>).
Use C<config_xml> when storing configurations in a database.

=back

B<Optional Parameters:>

=over 4

=item library_path

Path to libpepcore.so (default: empty string for auto-detect)

=item pos_number

POS identification string (default: '0001')

=item merchant_password

Merchant password (default: '000000')

=item language

Language constant (default: C<PEP_LANGUAGE_ENGLISH>)

=item ticket_width

Receipt width in characters (default: 40)

=item config_byte

Terminal config byte. If not specified, automatically calculated based on C<ticket_printing_mode>:

=over 4

=item * Mode 0 (POS prints): C<PEP_CONFIG_BYTE_DISABLE_PRINTER> (0x06 - disables terminal printer)

=item * Mode 1 (EFT prints): C<PEP_CONFIG_BYTE_NORMAL> (0x00 - normal operation)

=item * Other modes: C<PEP_CONFIG_BYTE_NORMAL> (0x00 - normal operation)

=back

You can explicitly provide a C<config_byte> value to override this automatic behavior.
Available constants: C<PEP_CONFIG_BYTE_NORMAL>, C<PEP_CONFIG_BYTE_DISABLE_PRINTER>.

=item ticket_printing_mode

Controls where transaction receipts are printed (default: 0 - POS/cash register handles printing).

Values:

=over 4

=item * 0 - POS/cash register prints (PEP_TICKET_PRINTING_MODE_POS) - B<DEFAULT>

=item * 1 - Terminal prints (PEP_TICKET_PRINTING_MODE_EFT)

=item * 2 - Client receipt on terminal only (PEP_TICKET_PRINTING_MODE_CLIENT_ONLY_EFT)

=item * 3 - No printing at all (PEP_TICKET_PRINTING_MODE_NONE)

=item * 4 - Both terminal and POS (PEP_TICKET_PRINTING_MODE_ECR_AND_TERMINAL)

=back

Default is 0 (POS prints) which disables the terminal's built-in printer and indicates
that the POS/cash register will handle receipt printing. This saves paper waste when your
cash register already prints transaction details on invoices.
Use 1 (EFT) to enable terminal printing if you want the terminal to print receipts.

B<Note>: The module automatically sets the C<config_byte> parameter to
C<PEP_CONFIG_BYTE_DISABLE_PRINTER> (0x06) when mode 0 is used, which helps disable
the terminal printer on many devices. This is handled internally and you don't need
to set C<config_byte> manually.

=item tip_enabled

Controls whether the terminal displays a tip/gratuity dialog during payment transactions
(default: 0 - tip dialog disabled).

Values:

=over 4

=item * 0 - Tip dialog disabled (standard goods payment) - B<DEFAULT>

=item * 1 - Tip dialog enabled (uses payment mode "Tippable")

=back

When C<tip_enabled =E<gt> 1> is set, C<doPayment()> will pass C<iPaymentModeValue =E<gt> 3>
(C<PEP_PAYMENT_MODE_TIPPABLE>) to the transaction, causing the terminal to prompt for a
tip amount during the payment flow.

This is useful for restaurants, bars, taxis, and other businesses where tips are common.

B<Note>: Tip support depends on the terminal and payment processor configuration.
Not all terminals or card types support tipping.

B<Example:>

    my $pepper = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GLOBALPAYMENTS_ZVT,
        terminal_address => '192.168.1.163:20008',
        license_file     => '/etc/pepper/license.xml',
        config_file      => '/etc/pepper/config.xml',
        tip_enabled      => 1,  # Enable tip dialog
    );

    my $payment = $pepper->doPayment(5000);  # Terminal will show tip prompt

=item callback

CODE reference for terminal callbacks (default: silent callback)

=item userdata

Hashref of custom data passed to callbacks (default: {})

=item reph

Optional reporting handler object for audit logging. The object must implement a
C<debuglog(@parts)> method that accepts one or more strings and logs them as a single line.

If not provided, debug output (when enabled) falls back to STDERR.

Example:

    package MyLogger;
    sub new { bless {}, shift }
    sub debuglog {
        my ($self, @parts) = @_;
        print "LOG: ", join('', @parts), "\n";
    }

    my $logger = MyLogger->new();
    my $pepper = Lib::Pepper::Simple->new(
        ...
        reph => $logger,
    );

=item operator_id

Operator identification string (default: 'OPERATOR01')

=back

B<Returns:> Blessed object reference

B<Dies on error:> Throws exception with detailed error message

B<Example using file paths:>

    my $pepper = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.163:20008',
        license_file     => '/etc/pepper/license.xml',
        config_file      => '/etc/pepper/config.xml',
    );

B<Example using XML content (from database):>

    # Load license and config from database
    my $licenseXml = $dbh->selectrow_array(
        "SELECT license_xml FROM terminal_configs WHERE id = ?",
        undef, $terminal_id
    );
    my $configXml = $dbh->selectrow_array(
        "SELECT config_xml FROM terminal_configs WHERE id = ?",
        undef, $terminal_id
    );

    my $pepper = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.163:20008',
        license_xml      => $licenseXml,
        config_xml       => $configXml,
    );

=head2 checkStatus($self)

Returns comprehensive terminal status information.

B<Returns hashref:>

=over 4

=item library_initialized

Boolean - Pepper library initialized

=item instance_configured

Boolean - Instance configured

=item connection_open

Boolean - Connection to terminal open

=item terminal_type

Terminal type constant

=item terminal_address

Terminal IP:port string

=item instance_id

Integer - This terminal's instance ID

=item ready_for_transactions

Boolean - All checks passed, ready for payments

=item last_error

Last error message or undef

=item process_instance_count

Integer - Total number of active terminals in this process (multi-terminal support)

=item process_library_initialized

Boolean - Library initialized at process level (multi-terminal support)

=back

B<Example:>

    my $status = $pepper->checkStatus();
    if(!$status->{ready_for_transactions}) {
        die "Terminal not ready: $status->{last_error}";
    }

=head2 library_status($class)

Class method to check process-wide library status. Useful for monitoring multi-terminal
systems and debugging initialization issues.

B<Returns hashref:>

=over 4

=item initialized

Boolean - Is the Pepper library initialized in this process?

=item instance_count

Integer - Number of active Lib::Pepper::Simple instances (terminals)

=item library_path

String - Library path used for initialization (empty string for auto-detect)

=item instance_ids

Hashref - Next available instance_id per terminal_type

    {
        118 => 3,  # Next Generic ZVT terminal would get instance_id 3
        120 => 2,  # Next Hobex ZVT terminal would get instance_id 2
    }

=back

B<Example:>

    my $status = Lib::Pepper::Simple->library_status();

    print "Library initialized: $status->{initialized}"\n";
    print "Active terminals: $status->{instance_count}"\n";

    if($status->{instance_count} > 0) {
        print "Library is in use, cannot safely reinitialize"\n";
    }

B<Multi-Terminal Monitoring:>

    # Before creating terminals
    my $before = Lib::Pepper::Simple->library_status();
    die "Library already initialized!" if $before->{initialized};

    # Create terminals
    my $t1 = Lib::Pepper::Simple->new(...);
    my $t2 = Lib::Pepper::Simple->new(...);

    # Check current state
    my $current = Lib::Pepper::Simple->library_status();
    print "Active terminals: $current->{instance_count}"\n";  # 2

    # After cleanup
    undef $t1;
    undef $t2;
    my $after = Lib::Pepper::Simple->library_status();
    print ""Library finalized: " . (!$after->{initialized})\n";  # 1

=head2 doPayment($self, $amount, %options)

Performs a payment transaction.

B<Parameters:>

=over 4

=item $amount (required)

Amount in smallest currency unit (cents for EUR/USD)

=item transaction_type (optional)

Transaction type constant (default: C<PEP_TRANSACTION_TYPE_GOODS_PAYMENT>)

=item currency (optional)

Currency constant (usually from config)

=item options (optional)

Hashref of additional transaction options

=back

B<Returns hashref:>

=over 4

=item success

Boolean - API call succeeded

=item authorized

Boolean - B<Payment was authorized> (check this for actual payment success!)

=item amount_charged

Actual amount charged in cents (0 if not authorized)

=item transaction_result

Raw iTransactionResultValue (0 = authorized, -1 = declined/aborted)

=item transaction_text

Human-readable status text

=item trace_number

Trace number (B<CRITICAL: Store this for cancellations!>)

=item authorization_code

Authorization code from payment processor

=item reference_number

Transaction reference number

=item terminal_id

Terminal identification

=item card_type

Card brand (VISA, MASTERCARD, etc.)

=item card_number

Masked card number

=item transaction_date

Transaction date (YYYY-MM-DD)

=item transaction_time

Transaction time (HH:MM:SS)

=item raw_output

Complete output hashref from library

=back

B<CRITICAL - Payment Authorization Check:>

The C<success> field indicates the API call completed successfully.
The C<authorized> field indicates the B<payment was actually authorized>.

An aborted or declined payment will have C<success =E<gt> 1> but C<authorized =E<gt> 0>!

B<Always check>: C<if($payment-E<gt>{authorized}) { ... }>

B<Example:>

    my $payment = $pepper->doPayment(10_050);  # 100.50 EUR

    if($payment->{authorized}) {
        # Payment AUTHORIZED - money will be charged
        print "Payment successful!"\n";
        print "Trace: $payment->{trace_number}"\n";

        # Store in database for potential cancellation
        store_payment({
            invoice_id => 'INV-123',
            trace      => $payment->{trace_number},
            amount     => $payment->{amount_charged},
            auth_code  => $payment->{authorization_code},
        });
    } else {
        # Payment DECLINED or ABORTED - no money charged
        print "Payment failed: $payment->{transaction_text}"\n";
    }

=head2 cancelPayment($self, $trace_number, $amount, %options)

Refunds a previous payment using referenced void (card-not-present).

This method uses Transaction Type 12 (VoidGoodsPayment) with C<sTransactionReferenceNumberString>
to perform a referenced reversal that does NOT require the customer's card to be present.

B<IMPORTANT>: Despite being called "VOID", this works AFTER settlement when using the
reference number. This is the correct method for card-not-present refunds in ZVT protocol.

B<Parameters:>

=over 4

=item $trace_number (required)

Trace number from original payment (sTraceNumberString)

=item $amount (required)

Amount in cents (must match original transaction amount)

=item reference_number (required)

Reference number from original payment (sTransactionReferenceNumberString).
This is what makes the refund work without requiring card swipe.

B<CRITICAL>: You MUST store this value when processing the original payment!

=back

B<Returns hashref:>

=over 4

=item success

Boolean - Refund succeeded

=item trace_number

New trace number for refund transaction

=item amount_refunded

Amount refunded to customer in cents

=item transaction_text

Status text from terminal

=item raw_output

Complete output hashref from transaction

=back

B<How It Works:>

Performs a B<referenced void> (Transaction Type 12 - VoidGoodsPayment) using the original
transaction's reference number (sTransactionReferenceNumberString). This tells the terminal
to reverse a specific previous transaction without requiring the customer to swipe their
card again.

B<Key Discovery>: Although this uses "VoidGoodsPayment", it works BOTH before and after
settlement when you provide the reference number. The ZVT protocol documentation does not
make this clear, but testing confirms this is the correct method for card-not-present refunds.

The refunded amount will appear in the customer's account in 3-5 business days.

B<Important Notes:>

=over 4

=item *

Both C<trace_number> AND C<reference_number> from the original payment must be stored in your database

=item *

The refund amount must match the original transaction amount exactly

=item *

Customer does NOT need to be present or swipe card

=item *

Works before or after end-of-day settlement

=item *

Refund appears in customer account in 3-5 business days

=back

B<Examples:>

    # Store payment details when processing original transaction
    my $payment = $pepper->doPayment($amount);
    if($payment->{authorized}) {
        save_to_database({
            order_id         => $order_id,
            trace_number     => $payment->{trace_number},
            reference_number => $payment->{reference_number},  # CRITICAL!
            amount           => $payment->{amount_charged},
        });
    }

    # Later: Refund the transaction (no card needed)
    my $stored = get_from_database($order_id);
    my $refund = $pepper->cancelPayment(
        $stored->{trace_number},
        $stored->{amount},
        reference_number => $stored->{reference_number}
    );

    if($refund->{success}) {
        print "Refund successful!"\n";
        print "Refund trace: $refund->{trace_number}"\n";
        print "Customer will receive refund in 3-5 business days"\n";

        update_database($order_id, status => 'refunded');
    } else {
        print "Refund failed: $refund->{transaction_text}"\n";
    }

=head2 endOfDay($self, %options)

Performs end-of-day settlement (batch close).

B<Parameters:>

=over 4

=item options (optional)

Hashref of settlement options (terminal-specific)

=back

B<Returns hashref:>

=over 4

=item success

Boolean - Settlement succeeded

=item function_result

Raw function result code

=item function_text

Status text

=item transaction_count

Number of transactions settled

=item total_amount

Total amount in cents

=item settlement_date

Settlement date (YYYY-MM-DD)

=item settlement_time

Settlement time (HH:MM:SS)

=item raw_output

Complete output hashref

=back

B<CRITICAL:> Settlement must be run daily to receive payment!

B<What Settlement Does:>

=over 4

=item 1.

Finalizes all transactions

=item 2.

Triggers money transfer to merchant account

=item 3.

Generates settlement reports

=item 4.

Clears terminal transaction buffer

=item 5.

After settlement, VOID operations become REFUND operations

=back

B<Example:>

    my $settlement = $pepper->endOfDay();

    if($settlement->{success}) {
        print "Settlement successful!"\n";
        print "Transactions: $settlement->{transaction_count}"\n";
        print "Total: " . sprintf("%.2f EUR",
            $settlement->{total_amount} / 100) . "\n";
    } else {
        print "Settlement failed: $settlement->{function_text}"\n";
    }

=head1 COMPLETE WORKFLOW EXAMPLE

    use Lib::Pepper::Simple;
    use Lib::Pepper::Constants qw(:all);

    # Morning - Initialize
    my $pepper = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.163:20008',
        license_file     => '/etc/pepper/license.xml',
        config_file      => '/etc/pepper/config.xml',
    );

    # Check status
    my $status = $pepper->checkStatus();
    die "Not ready" unless $status->{ready_for_transactions};

    # During day - Process payment
    my $payment = $pepper->doPayment(10_000);  # 100.00 EUR

    if($payment->{authorized}) {
        # Store trace number in database
        my $trace = $payment->{trace_number};
        my $amount = $payment->{amount_charged};

        # If customer cancels same day
        my $cancel = $pepper->cancelPayment($trace, $amount);
        if($cancel->{success}) {
            print "Canceled via $cancel->{method_used}"\n";
        }
    }

    # Evening - Settlement (CRITICAL!)
    my $settlement = $pepper->endOfDay();
    if($settlement->{success}) {
        print "Day closed: $settlement->{transaction_count} transactions"\n";
    }

=head1 MULTI-TERMINAL SUPPORT

Lib::Pepper::Simple supports multiple payment terminals in the same process, allowing
a single application (e.g., PageCamel worker) to manage multiple physical terminals
simultaneously.

=head2 How It Works

The Pepper C library is a process-wide singleton that can only be initialized once per
process. Lib::Pepper::Simple handles this automatically using reference counting:

=over 4

=item 1.

First instance created → Library initialized, counter = 1

=item 2.

Additional instances created → Reuse initialized library, counter increments

=item 3.

Instances destroyed → Counter decrements, library stays initialized

=item 4.

Last instance destroyed → Library finalized, counter = 0

=back

=head2 Requirements

All terminals in the same process B<MUST> use:

=over 4

=item *

Identical C<license_xml> (or C<license_file>)

=item *

Identical C<config_xml> (or C<config_file>)

=item *

Identical C<library_path> (if specified)

=back

Each terminal B<CAN> have:

=over 4

=item *

Different C<terminal_address> (IP:port) - B<REQUIRED> for different physical terminals

=item *

Different C<terminal_type> (Generic ZVT, Hobex ZVT, etc.)

=item *

Different per-terminal configuration (pos_number, merchant_password, etc.)

=item *

Different C<instance_id> (automatically allocated if not specified)

=back

=head2 Instance ID Allocation

Instance IDs are automatically allocated per terminal type:

    # Terminal type 118 (Generic ZVT)
    my $t1 = Lib::Pepper::Simple->new(terminal_type => 118, ...);  # instance_id = 1
    my $t2 = Lib::Pepper::Simple->new(terminal_type => 118, ...);  # instance_id = 2

    # Terminal type 120 (Hobex ZVT)
    my $t3 = Lib::Pepper::Simple->new(terminal_type => 120, ...);  # instance_id = 1

Different terminal types maintain separate instance_id sequences.

You can manually specify an C<instance_id>:

    my $t = Lib::Pepper::Simple->new(
        terminal_type => 118,
        instance_id   => 42,  # Manual ID
        ...
    );

B<WARNING>: When manually specifying instance_id, ensure it doesn't conflict with
other instances of the same terminal_type. The library will detect collisions.

=head2 Configuration Validation

When creating the second (or subsequent) terminal, Lib::Pepper::Simple validates
that the configuration matches the first instance:

    my $t1 = Lib::Pepper::Simple->new(license_file => $license1, ...);  # OK

    my $t2 = Lib::Pepper::Simple->new(license_file => $license2, ...);  # FAILS!
    # Error: Configuration mismatch: Lib::Pepper library already initialized
    #        with different config

This prevents configuration conflicts that could cause unpredictable behavior.

=head2 Checking Library Status

Class method to check process-wide library status:

    my $status = Lib::Pepper::Simple->library_status();

Returns hashref:

=over 4

=item initialized

Boolean - Library initialized in this process?

=item instance_count

Integer - Number of active terminal instances

=item library_path

String - Library path used for initialization

=item instance_ids

Hashref - Next available instance_id per terminal_type:

    {
        118 => 3,  # Next Generic ZVT would get ID 3
        120 => 2,  # Next Hobex ZVT would get ID 2
    }

=back

Example:

    my $status = Lib::Pepper::Simple->library_status();
    print "Active terminals: $status->{instance_count}"\n";

Instance-level status includes process info:

    my $status = $terminal->checkStatus();
    print "This terminal: instance_id $status->{instance_id}"\n";
    print "Total active:  $status->{process_instance_count} terminals"\n";

=head2 Transaction Isolation

Each terminal maintains completely independent transaction state:

    my $payment1 = $terminal1->doPayment(1000);  # Terminal 1
    my $payment2 = $terminal2->doPayment(2000);  # Terminal 2

    # Different trace numbers, different transactions
    $payment1->{trace_number} ne $payment2->{trace_number}

Cancellations are terminal-specific and use the trace number from the
original terminal:

    # Refund payment from Terminal 1
    $terminal1->cancelPayment($payment1->{trace_number}, 1000,
        reference_number => $payment1->{reference_number});

=head2 Complete Multi-Terminal Example

    use Lib::Pepper::Simple;
    use Lib::Pepper::Constants qw(:all);

    # Initialize multiple terminals
    my $terminalA = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.163:20008',  # Front counter
        license_file     => '/etc/pepper/license.xml',
        config_file      => '/etc/pepper/config.xml',
        pos_number       => '0001',
    );

    my $terminalB = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        terminal_address => '192.168.1.164:20008',  # Drive-through
        license_file     => '/etc/pepper/license.xml',  # SAME!
        config_file      => '/etc/pepper/config.xml',   # SAME!
        pos_number       => '0002',  # Different POS number
    );

    # Check library status
    my $libStatus = Lib::Pepper::Simple->library_status();
    print "Library initialized: $libStatus->{initialized}"\n";
    print "Active terminals: $libStatus->{instance_count}"\n";

    # Process payments independently
    my $paymentA = $terminalA->doPayment(1500);  # Front counter
    if($paymentA->{authorized}) {
        print "Front counter: Payment authorized"\n";
        save_transaction('terminal_a', $paymentA->{trace_number},
                        $paymentA->{reference_number}, 1500);
    }

    my $paymentB = $terminalB->doPayment(2500);  # Drive-through
    if($paymentB->{authorized}) {
        print "Drive-through: Payment authorized"\n";
        save_transaction('terminal_b', $paymentB->{trace_number},
                        $paymentB->{reference_number}, 2500);
    }

    # Each terminal can do end-of-day independently
    my $settlementA = $terminalA->endOfDay();
    my $settlementB = $terminalB->endOfDay();

    # Cleanup (automatic when objects destroyed)
    undef $terminalA;  # Counter = 1, library stays initialized
    undef $terminalB;  # Counter = 0, library finalized

=head2 Database Schema for Multi-Terminal

When storing transactions, include terminal identification:

    CREATE TABLE payment_transactions (
        id SERIAL PRIMARY KEY,
        terminal_id VARCHAR(20) NOT NULL,        -- 'terminal_a', 'terminal_b', etc.
        instance_id INTEGER NOT NULL,            -- From checkStatus()->{instance_id}
        order_id INTEGER NOT NULL,
        trace_number VARCHAR(20) NOT NULL,
        reference_number VARCHAR(50) NOT NULL,   -- For card-not-present refunds
        amount INTEGER NOT NULL,
        transaction_date TIMESTAMP DEFAULT NOW(),

        INDEX idx_terminal (terminal_id),
        INDEX idx_trace (trace_number),
        UNIQUE (terminal_id, trace_number)
    );

This allows you to identify which physical terminal processed each transaction.

=head2 Use Cases

=over 4

=item Retail with Multiple Checkout Lanes

Each checkout lane has its own terminal, all managed by a single POS application.

=item Drive-Through + Counter Service

Fast food restaurant with both drive-through terminal and counter terminal.

=item Multi-Location Kiosks

Self-service kiosks at different locations, managed by a central application.

=item Backup Terminal

Primary terminal with automatic failover to backup terminal on connection loss.

=back

=head2 Limitations

=over 4

=item Thread Safety

Not thread-safe. Do not create instances from different threads simultaneously.
If using threads, protect instance creation with a mutex.

=item Configuration Flexibility

All terminals must use identical license and config. Cannot mix different licenses
or configurations in the same process.

=item Instance ID Management

When manually specifying instance_id, you are responsible for avoiding conflicts.

=back

=head1 ERROR HANDLING

Methods return structured hashrefs with error information rather than throwing
exceptions for operational failures (payment declined, settlement failed, etc.).

Constructor (C<new()>) and parameter validation errors throw exceptions with C<croak()>.

Always check the C<success> field in return values:

    my $payment = $pepper->doPayment($amount);
    if(!$payment->{success}) {
        # API call failed
        die "Payment error: $payment->{error}";
    }

    if(!$payment->{authorized}) {
        # Payment declined/aborted
        print "Payment not authorized: $payment->{transaction_text}"\n";
    }

=head1 AUTOMATIC FEATURES

=over 4

=item Recovery Operations

Automatically detected and performed during initialization if recovery flag is set.

=item VOID→REFUND Fallback

C<cancelPayment()> automatically switches from VOID to REFUND for settled transactions.

=item Connection Management

OPEN operation performed automatically. Connection closed in destructor.

=item State Validation

All operations validate state before execution with clear error messages.

=back

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

=over 4

=item L<Lib::Pepper>

Low-level library interface

=item L<Lib::Pepper::Instance>

Terminal instance management

=item L<Lib::Pepper::Constants>

Constants for terminal types, languages, transaction types, etc.

=back

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
