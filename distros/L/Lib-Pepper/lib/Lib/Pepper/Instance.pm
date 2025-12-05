package Lib::Pepper::Instance;
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
use Lib::Pepper::Exception;
use Lib::Pepper::OptionList;
use Lib::Pepper::Constants qw(:all);

sub new($class, %params) {
    my $terminalType = $params{terminal_type};
    my $instanceId = $params{instance_id} || 1;

    if(!defined $terminalType) {
        croak('new: terminal_type parameter is required');
    }

    my $self = {
        handle         => undef,
        terminal_type  => $terminalType,
        instance_id    => $instanceId,
        configured     => 0,
        callback       => undef,
        userdata       => undef,
        reph           => $params{reph},  # Optional reporting handler
    };

    bless $self, $class;

    # Create the instance
    my ($result, $handle) = Lib::Pepper::pepCreateInstance($terminalType, $instanceId);
    Lib::Pepper::Exception->checkResult($result, 'pepCreateInstance');

    $self->{handle} = $handle;

    return $self;
}

sub getHandle($self) {
    return $self->{handle};
}

sub isConfigured($self) {
    return $self->{configured};
}

sub configure($self, %params) {
    if(!defined $self->{handle}) {
        croak('configure: instance not initialized');
    }

    my $callback = $params{callback};
    my $options = $params{options} || {};
    my $userdata = $params{userdata};

    if(!defined $callback || ref($callback) ne 'CODE') {
        croak('configure: callback parameter must be a code reference');
    }

    # Create option list manually to handle callback values properly
    my $inputOptions = Lib::Pepper::OptionList->new();

    # Add callback configuration (mandatory for pepConfigure)
    # Default to receiving both output and input callbacks with all options
    my $callbackEvent = $options->{iCallbackEventValue} //
        (PEP_CALLBACK_EVENT_OUTPUT | PEP_CALLBACK_EVENT_INPUT);
    my $callbackOption = $options->{iCallbackOptionValue} //
        (PEP_CALLBACK_OPTION_INTERMEDIATE_STATUS | PEP_CALLBACK_OPTION_OPERATION_FINISHED |
         PEP_CALLBACK_OPTION_INTERMEDIATE_TICKET |
         PEP_CALLBACK_OPTION_SELECTION_LIST | PEP_CALLBACK_OPTION_NUMERICAL_INPUT |
         PEP_CALLBACK_OPTION_ALPHANUMERICAL_INPUT | PEP_CALLBACK_OPTION_COMPLEX_INPUT);

    $inputOptions->addInt('iCallbackEventValue', $callbackEvent);
    $inputOptions->addInt('iCallbackOptionValue', $callbackOption);

    # Add other options
    for my $key (keys %{$options}) {
        next if $key eq 'iCallbackEventValue';
        next if $key eq 'iCallbackOptionValue';

        my $value = $options->{$key};
        if(!defined $value) {
            next;
        } elsif(ref($value) eq 'HASH') {
            my $childList = Lib::Pepper::OptionList->fromHashref($value);
            $inputOptions->addChild($key, $childList);
        } elsif(ref($value) eq '') {
            # Use key prefix to determine type: i=int, s=string, h=handle/child
            if($key =~ /^i/) {
                $inputOptions->addInt($key, $value);
            } else {
                $inputOptions->addString($key, $value);
            }
        }
    }

    # Store callback and userdata
    $self->{callback} = $callback;
    $self->{userdata} = $userdata;

    # Configure with callback
    my ($result, $outputOptions) = Lib::Pepper::pepConfigureWithCallback(
        $self->{handle},
        $inputOptions->getHandle(),
        $callback,
        $userdata
    );

    Lib::Pepper::Exception->checkResult($result, 'pepConfigure');

    $self->{configured} = 1;

    # Return output options as OptionList object
    if(defined $outputOptions) {
        return Lib::Pepper::OptionList->new($outputOptions);
    }

    return;
}

sub prepareOperation($self, $operation, $inputOptions = undef) {
    if(!defined $self->{handle}) {
        croak('prepareOperation: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('prepareOperation: instance not configured');
    }

    my $inputHandle = defined $inputOptions ? $inputOptions->getHandle() : PEP_INVALID_HANDLE;

    my ($result, $operationHandle, $outputHandle) = Lib::Pepper::pepPrepareOperation(
        $self->{handle},
        $operation,
        $inputHandle
    );

    # Provide helpful context for state transition errors
    if($result == -1301) {
        my $termType = $self->{terminal_type} || 'unknown';
        my $opName = $operation == 4 ? 'TRANSACTION' :
                     $operation == 5 ? 'SETTLEMENT' :
                     $operation == 1 ? 'OPEN' :
                     $operation == 2 ? 'CLOSE' : $operation;

        my $extraMsg = '';
        if($termType == 999 || $termType eq PEP_TERMINAL_TYPE_MOCK) {
            $extraMsg = "\n\nNOTE: Mock terminals (TT999) do NOT support transaction operations.\n" .
                       "This is expected behavior. For transaction testing, use:\n" .
                       "  - PEP_TERMINAL_TYPE_GENERIC_ZVT (118) - Generic ZVT terminals\n" .
                       "  - PEP_TERMINAL_TYPE_HOBEX_ZVT (120) - Hobex ZVT terminals\n" .
                       "See examples/README.md and IMPLEMENTATION_STATUS.md for details.";
        }

        croak("pepPrepareOperation: Invalid state transition (code: -1301)\n" .
              "Operation: $opName\n" .
              "Terminal Type: $termType\n" .
              "The instance is not in the correct state for this operation.$extraMsg");
    }

    Lib::Pepper::Exception->checkResult($result, 'pepPrepareOperation');

    return (
        $operationHandle,
        defined $outputHandle ? Lib::Pepper::OptionList->new($outputHandle) : undef
    );
}

sub startOperation($self, $operation, $inputOptions = undef) {
    if(!defined $self->{handle}) {
        croak('startOperation: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('startOperation: instance not configured');
    }

    my $inputHandle = defined $inputOptions ? $inputOptions->getHandle() : PEP_INVALID_HANDLE;

    my ($result, $operationHandle, $outputHandle) = Lib::Pepper::pepStartOperation(
        $self->{handle},
        $operation,
        $inputHandle
    );

    Lib::Pepper::Exception->checkResult($result, 'pepStartOperation');

    return (
        $operationHandle,
        defined $outputHandle ? Lib::Pepper::OptionList->new($outputHandle) : undef
    );
}

sub executeOperation($self, $operation, $inputOptions = undef) {
    if(!defined $self->{handle}) {
        croak('executeOperation: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('executeOperation: instance not configured');
    }

    my $inputHandle = defined $inputOptions ? $inputOptions->getHandle() : PEP_INVALID_HANDLE;

    my ($result, $operationHandle, $outputHandle) = Lib::Pepper::pepExecuteOperation(
        $self->{handle},
        $operation,
        $inputHandle
    );

    Lib::Pepper::Exception->checkResult($result, 'pepExecuteOperation');

    return (
        $operationHandle,
        defined $outputHandle ? Lib::Pepper::OptionList->new($outputHandle) : undef
    );
}

sub finalizeOperation($self, $operation, $inputOptions = undef) {
    if(!defined $self->{handle}) {
        croak('finalizeOperation: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('finalizeOperation: instance not configured');
    }

    my $inputHandle = defined $inputOptions ? $inputOptions->getHandle() : PEP_INVALID_HANDLE;

    my ($result, $operationHandle, $outputHandle) = Lib::Pepper::pepFinalizeOperation(
        $self->{handle},
        $operation,
        $inputHandle
    );

    Lib::Pepper::Exception->checkResult($result, 'pepFinalizeOperation');

    return (
        $operationHandle,
        defined $outputHandle ? Lib::Pepper::OptionList->new($outputHandle) : undef
    );
}

sub operationStatus($self, $operationHandle, $waitForCompletion = 0) {
    if(!defined $self->{handle}) {
        croak('operationStatus: instance not initialized');
    }

    my ($result, $status) = Lib::Pepper::pepOperationStatus(
        $self->{handle},
        $operationHandle,
        $waitForCompletion
    );

    Lib::Pepper::Exception->checkResult($result, 'pepOperationStatus');

    return $status;
}

sub openConnection($self, %params) {
    if(!defined $self->{handle}) {
        croak('openConnection: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('openConnection: instance not configured');
    }

    my $options = $params{options} || {};
    my $inputOptions = Lib::Pepper::OptionList->fromHashref($options);

    # Execute the OPEN operation using the 4-step workflow
    # All 4 steps should be called in sequence, then wait for completion at the end
    my ($opHandle1, $output1) = $self->prepareOperation(PEP_OPERATION_OPEN, $inputOptions);
    my ($opHandle2, $output2) = $self->startOperation(PEP_OPERATION_OPEN, $inputOptions);
    my ($opHandle3, $output3) = $self->executeOperation(PEP_OPERATION_OPEN, $inputOptions);
    my ($opHandle4, $output4) = $self->finalizeOperation(PEP_OPERATION_OPEN, $inputOptions);

    # Wait for the final step to complete
    my $status4 = $self->operationStatus($opHandle4, 1);

    return {
        operation_handle => $opHandle4,
        status          => $status4,
        output          => $output4,
    };
}

sub closeConnection($self, %params) {
    if(!defined $self->{handle}) {
        croak('closeConnection: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('closeConnection: instance not configured');
    }

    my $options = $params{options} || {};
    my $inputOptions = Lib::Pepper::OptionList->fromHashref($options);

    # Execute the CLOSE operation using the 4-step workflow
    # All 4 steps should be called in sequence, then wait for completion at the end
    my ($opHandle1, $output1) = $self->prepareOperation(PEP_OPERATION_CLOSE, $inputOptions);
    my ($opHandle2, $output2) = $self->startOperation(PEP_OPERATION_CLOSE, $inputOptions);
    my ($opHandle3, $output3) = $self->executeOperation(PEP_OPERATION_CLOSE, $inputOptions);
    my ($opHandle4, $output4) = $self->finalizeOperation(PEP_OPERATION_CLOSE, $inputOptions);

    # Wait for the final step to complete
    my $status4 = $self->operationStatus($opHandle4, 1);

    return {
        operation_handle => $opHandle4,
        status          => $status4,
        output          => $output4,
    };
}

sub transaction($self, %params) {
    if(!defined $self->{handle}) {
        croak('transaction: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('transaction: instance not configured');
    }

    my $transactionType = $params{transaction_type} || PEP_TRANSACTION_TYPE_GOODS_PAYMENT;
    my $amount = $params{amount};
    my $currency = $params{currency};
    my $additionalOptions = $params{options} || {};

    if(!defined $amount) {
        croak('transaction: amount parameter is required');
    }

    # Build input options for transaction
    # Real ZVT terminals require transaction parameters in operation options
    my $inputOptions = Lib::Pepper::OptionList->new();

    # Add mandatory transaction parameters
    $inputOptions->addInt('iTransactionTypeValue', $transactionType);
    $inputOptions->addInt('iAmount', $amount);

    # Add currency if specified (some terminals require it, others handle it via config)
    if(defined $currency) {
        $inputOptions->addInt('iCurrency', $currency);
    }

    # Add any additional user-specified options
    for my $key (keys %{$additionalOptions}) {
        my $value = $additionalOptions->{$key};
        next unless defined $value;

        if($key =~ /^i/) {
            $inputOptions->addInt($key, $value);
        } elsif($key =~ /^h/) {
            if(ref($value) && $value->isa('Lib::Pepper::OptionList')) {
                $inputOptions->addChild($key, $value);
            }
        } else {
            $inputOptions->addString($key, $value);
        }
    }

    # Execute the full 4-step workflow
    # All 4 steps should be called in sequence, then wait for completion at the end
    my ($opHandle1, $output1) = $self->prepareOperation(PEP_OPERATION_TRANSACTION, $inputOptions);
    my ($opHandle2, $output2) = $self->startOperation(PEP_OPERATION_TRANSACTION, $inputOptions);
    my ($opHandle3, $output3) = $self->executeOperation(PEP_OPERATION_TRANSACTION, $inputOptions);
    my ($opHandle4, $output4) = $self->finalizeOperation(PEP_OPERATION_TRANSACTION, $inputOptions);

    # Wait for the final step to complete
    my $status4 = $self->operationStatus($opHandle4, 1);

    # CRITICAL: Return value does NOT indicate payment success!
    # Check $output4->getInt('iTransactionResultValue') == 0 for payment authorization
    return {
        operation_handle => $opHandle4,
        status          => $status4,  # API completion status, NOT payment status
        output          => $output4,  # Contains iTransactionResultValue (0=authorized, -1=declined/aborted)
    };
}

sub settlement($self, %params) {
    if(!defined $self->{handle}) {
        croak('settlement: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('settlement: instance not configured');
    }

    my $options = $params{options} || {};

    my $inputOptions = Lib::Pepper::OptionList->fromHashref($options);

    # Execute the full 4-step workflow
    # All 4 steps should be called in sequence, then wait for completion at the end
    my ($opHandle1, $output1) = $self->prepareOperation(PEP_OPERATION_SETTLEMENT, $inputOptions);
    my ($opHandle2, $output2) = $self->startOperation(PEP_OPERATION_SETTLEMENT, $inputOptions);
    my ($opHandle3, $output3) = $self->executeOperation(PEP_OPERATION_SETTLEMENT, $inputOptions);
    my ($opHandle4, $output4) = $self->finalizeOperation(PEP_OPERATION_SETTLEMENT, $inputOptions);

    # Wait for the final step to complete
    my $status4 = $self->operationStatus($opHandle4, 1);

    return {
        operation_handle => $opHandle4,
        status          => $status4,
        output          => $output4,
    };
}

sub utility($self, %params) {
    if(!defined $self->{handle}) {
        croak('utility: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('utility: instance not configured');
    }

    my $options = $params{options} || {};
    my $inputOptions = Lib::Pepper::OptionList->fromHashref($options);

    my ($result, $outputHandle) = Lib::Pepper::pepUtility(
        $self->{handle},
        $inputOptions->getHandle()
    );

    Lib::Pepper::Exception->checkResult($result, 'pepUtility');

    return defined $outputHandle ? Lib::Pepper::OptionList->new($outputHandle) : undef;
}

sub auxiliary($self, %params) {
    if(!defined $self->{handle}) {
        croak('auxiliary: instance not initialized');
    }

    if(!$self->{configured}) {
        croak('auxiliary: instance not configured');
    }

    my $options = $params{options} || {};
    my $inputOptions = Lib::Pepper::OptionList->fromHashref($options);

    my ($result, $operationHandle, $outputHandle) = Lib::Pepper::pepAuxiliary(
        $self->{handle},
        $inputOptions->getHandle()
    );

    Lib::Pepper::Exception->checkResult($result, 'pepAuxiliary');

    return (
        $operationHandle,
        defined $outputHandle ? Lib::Pepper::OptionList->new($outputHandle) : undef
    );
}

sub DESTROY($self) {
    if(defined $self->{handle}) {
        my $result = Lib::Pepper::pepFreeInstance($self->{handle});
        # Don't croak in DESTROY - just warn on failure
        if($result < 0) {
            carp("Warning: pepFreeInstance failed with code: $result");
        }
        $self->{handle} = undef;
    }
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

1;

__END__

=encoding utf8

=head1 NAME

Lib::Pepper::Instance - High-level object-oriented wrapper for Pepper terminal instances

=head1 SYNOPSIS

    use Lib::Pepper;
    use Lib::Pepper::Instance;
    use Lib::Pepper::Constants qw(:all);

    # Initialize the library
    Lib::Pepper->initialize(library_path => '');

    # Create a terminal instance
    my $instance = Lib::Pepper::Instance->new(
        terminal_type => PEP_TERMINAL_TYPE_MOCK,
        instance_id   => 1,
    );

    # Configure with callback
    $instance->configure(
        callback => sub {
            my ($event, $option, $instanceHandle, $outputOptions, $inputOptions, $userData) = @_;
            print "Callback event: $event, option: $option\n";
        },
        options => {
            sHostName      => '192.168.1.100:20007',
            iLanguageValue => PEP_LANGUAGE_ENGLISH,
        },
    );

    # Perform a transaction (high-level method)
    my $result = $instance->transaction(
        transaction_type => PEP_TRANSACTION_TYPE_GOODS_PAYMENT,
        amount          => 10_050,  # 100.50 EUR in cents
        currency        => PEP_CURRENCY_EUR,
    );

    print "Transaction status: $result->{status}\n";

    # Perform settlement
    my $settlement = $instance->settlement(
        options => {},
    );

    # Clean up
    $instance = undef;
    Lib::Pepper->finalize();

=head1 DESCRIPTION

Lib::Pepper::Instance provides a high-level object-oriented interface for managing
Pepper payment terminal instances. It wraps the low-level XS functions and provides
convenient methods for common operations.

This class handles the complete lifecycle of a terminal instance, from creation
through configuration, operations, and cleanup.

=head1 METHODS

=head2 new(%params)

Constructor. Creates a new terminal instance.

    my $instance = Lib::Pepper::Instance->new(
        terminal_type => PEP_TERMINAL_TYPE_MOCK,      # Required
        instance_id   => 1,                           # Optional, default: 1
    );

Parameters:

=over 4

=item terminal_type (required)

Terminal type constant. Common values:

- PEP_TERMINAL_TYPE_MOCK (18) - Mock terminal for testing
- PEP_TERMINAL_TYPE_GENERIC_ZVT (118) - Generic ZVT terminal
- PEP_TERMINAL_TYPE_HOBEX_ZVT (120) - Hobex ZVT terminal

=item instance_id (optional)

Unique instance identifier. Default: 1

=back

Returns: Lib::Pepper::Instance object

Throws: Exception on failure

=head2 getHandle()

Returns the underlying C handle for this instance.

    my $handle = $instance->getHandle();

Returns: Integer handle value

=head2 isConfigured()

Returns true if the instance has been configured with a callback.

    if($instance->isConfigured()) {
        # Ready to perform operations
    }

Returns: Boolean

=head2 configure(%params)

Configures the instance with a callback and connection options.
Must be called before performing any operations.

    $instance->configure(
        callback => sub {
            my ($event, $option, $instanceHandle, $outputOptions, $inputOptions, $userData) = @_;
            # Handle callback events
        },
        options => {
            sHostName      => '192.168.1.100:20007',
            iLanguageValue => PEP_LANGUAGE_ENGLISH,
            iPosNumber     => 1,
        },
        userdata => { custom => 'data' },  # Optional
    );

Parameters:

=over 4

=item callback (required)

Code reference that will be called for events during operations.
Receives 6 parameters: event, option, instanceHandle, outputOptions, inputOptions, userData

=item options (optional)

Hashref of configuration options. Common options:

- sHostName: Terminal address (e.g., '192.168.1.100:20007')
- iLanguageValue: Display language (PEP_LANGUAGE_*)
- iPosNumber: POS terminal number

=item userdata (optional)

Any Perl data structure to pass to callback

=back

Returns: Output options as Lib::Pepper::OptionList object (or undef)

Throws: Exception on failure

=head2 openConnection(%params)

Opens a connection to the payment terminal.
Must be called after configure() and before any transaction operations.

    my $result = $instance->openConnection(
        options => {
            # Optional connection-specific parameters
        },
    );

Parameters:

=over 4

=item options (optional)

Hashref of connection options (terminal-specific parameters)

=back

Returns: Hashref with operation_handle, status, and output

Throws: Exception on failure

=head2 closeConnection(%params)

Closes the connection to the payment terminal.
Should be called when finished with terminal operations.

    my $result = $instance->closeConnection(
        options => {
            # Optional disconnection-specific parameters
        },
    );

Parameters:

=over 4

=item options (optional)

Hashref of disconnection options (terminal-specific parameters)

=back

Returns: Hashref with operation_handle, status, and output

Throws: Exception on failure

=head2 prepareOperation($operation, $inputOptions)

Executes the "prepare" step of the 4-step operation workflow.

    my ($opHandle, $output) = $instance->prepareOperation(
        PEP_OPERATION_TRANSACTION,
        $inputOptions
    );

Parameters:

=over 4

=item $operation

Operation type constant (e.g., PEP_OPERATION_TRANSACTION)

=item $inputOptions

Lib::Pepper::OptionList object with operation parameters (optional)

=back

Returns: List of (operation_handle, output_options)

Throws: Exception on failure

=head2 startOperation($operation, $inputOptions)

Executes the "start" step of the 4-step operation workflow.

    my ($opHandle, $output) = $instance->startOperation(
        PEP_OPERATION_TRANSACTION,
        $inputOptions
    );

See prepareOperation() for parameter details.

=head2 executeOperation($operation, $inputOptions)

Executes the "execute" step of the 4-step operation workflow.

    my ($opHandle, $output) = $instance->executeOperation(
        PEP_OPERATION_TRANSACTION,
        $inputOptions
    );

See prepareOperation() for parameter details.

=head2 finalizeOperation($operation, $inputOptions)

Executes the "finalize" step of the 4-step operation workflow.

    my ($opHandle, $output) = $instance->finalizeOperation(
        PEP_OPERATION_TRANSACTION,
        $inputOptions
    );

See prepareOperation() for parameter details.

=head2 operationStatus($operationHandle, $waitForCompletion)

Checks the status of an operation.

    my $status = $instance->operationStatus($opHandle, 1);

Parameters:

=over 4

=item $operationHandle

Operation handle returned from operation methods

=item $waitForCompletion

Boolean: 1 to wait for completion, 0 to return immediately

=back

Returns: Status boolean (1 = complete, 0 = in progress)

Throws: Exception on failure

=head2 transaction(%params)

High-level method that performs a complete payment transaction.
Executes the full 4-step workflow automatically.

    my $result = $instance->transaction(
        transaction_type => PEP_TRANSACTION_TYPE_GOODS_PAYMENT,
        amount          => 10_050,      # Amount in cents
        currency        => PEP_CURRENCY_EUR,
        options         => { ... },     # Additional options (optional)
    );

    print "Status: $result->{status}\n";
    my $outputData = $result->{output}->toHashref();

Parameters:

=over 4

=item transaction_type (optional)

Transaction type constant. Default: PEP_TRANSACTION_TYPE_GOODS_PAYMENT

=item amount (required)

Transaction amount in smallest currency unit (cents for EUR/USD)

=item currency (optional)

Currency constant. Default: PEP_CURRENCY_EUR

=item options (optional)

Hashref of additional transaction options

=back

Returns: Hashref with keys:

=over 4

=item operation_handle

Final operation handle

=item status

Operation completion status (boolean) - indicates the API call completed successfully.

B<WARNING>: This does NOT indicate payment authorization! See below.

=item output

Output options as Lib::Pepper::OptionList object

=back

B<CRITICAL: Checking Payment Authorization>

The C<status> return value indicates whether the API call completed successfully,
B<NOT> whether the payment was authorized. An aborted or declined payment will
still return C<status =E<gt> 1> because the API call itself succeeded.

To check if a payment was actually authorized, you MUST check the transaction
result in the output data:

    my $outputData = $result->{output}->toHashref();
    my $transactionResult = $outputData->{iTransactionResultValue} // -999;

    if($transactionResult == 0) {
        # Payment was AUTHORIZED - money will be charged
        print "✓ Payment Authorized\n";
        print "Auth Code: $outputData->{sAuthorizationNumberString}\n";
        print "Amount: ", $outputData->{iAmount} / 100, "\n";
    } else {
        # Payment FAILED/DECLINED/ABORTED - no money charged
        print "✗ Payment Failed\n";
        print "Reason: $outputData->{sTransactionText}\n";
    }

B<Key Fields>:

=over 4

=item iTransactionResultValue

Payment authorization status:

  0  = Payment authorized (money will be charged)
  -1 = Payment declined/aborted (no money charged)

=item iFunctionResultValue

API call status (0 = API call succeeded). Do NOT use this to check payment success!

=item sTransactionText

Human-readable transaction status (e.g., "abort via timeout or abort-key")

=item sAuthorizationNumberString

Authorization code (empty if payment not authorized)

=item iAmount

Actual amount charged (0 if payment not authorized)

=back

B<Common Mistake>:

    # WRONG - checks if API call succeeded, not if payment authorized!
    if($result->{status} || $outputData->{iFunctionResultValue} == 0) {
        print "Payment successful\n";  # FALSE! May be declined/aborted!
    }

    # CORRECT - checks if payment was actually authorized
    if($outputData->{iTransactionResultValue} == 0) {
        print "Payment authorized\n";
    }

Throws: Exception on failure

=head2 settlement(%params)

High-level method that performs a settlement operation.
Executes the full 4-step workflow automatically.

    my $result = $instance->settlement(
        options => { ... },  # Settlement options (optional)
    );

Parameters:

=over 4

=item options (optional)

Hashref of settlement options (e.g., terminal-specific settlement parameters)

=back

Returns: Hashref with same structure as transaction()

Throws: Exception on failure

=head2 utility(%params)

Executes a utility operation (synchronous).

    my $output = $instance->utility(
        options => {
            # Terminal-specific utility parameters
        },
    );

Parameters:

=over 4

=item options (optional)

Hashref of utility operation options

=back

Returns: Output options as Lib::Pepper::OptionList object (or undef)

Throws: Exception on failure

=head2 auxiliary(%params)

Executes an auxiliary operation (asynchronous).

    my ($opHandle, $output) = $instance->auxiliary(
        options => {
            # Terminal-specific auxiliary parameters
        },
    );

Parameters:

=over 4

=item options (optional)

Hashref of auxiliary operation options

=back

Returns: List of (operation_handle, output_options)

Throws: Exception on failure

=head1 WORKFLOW

The Pepper library uses a 4-step workflow for asynchronous operations:

1. B<Prepare>: Validates parameters and prepares the operation
2. B<Start>: Initiates communication with the terminal
3. B<Execute>: Performs the main operation
4. B<Finalize>: Completes the operation and retrieves results

For convenience, the transaction() and settlement() methods execute
all 4 steps automatically.

=head1 EXAMPLE: MANUAL 4-STEP WORKFLOW

    # Create and configure instance
    my $instance = Lib::Pepper::Instance->new(
        terminal_type => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    );

    $instance->configure(
        callback => \&myCallback,
        options  => { sHostName => '192.168.1.100:20007' },
    );

    # Build options
    my $options = Lib::Pepper::OptionList->fromHashref({
        iTransactionType => PEP_TRANSACTION_TYPE_GOODS_PAYMENT,
        iAmount          => 5000,  # 50.00 EUR
        iCurrency        => PEP_CURRENCY_EUR,
    });

    # Execute 4-step workflow manually
    my ($op1, $out1) = $instance->prepareOperation(PEP_OPERATION_TRANSACTION, $options);
    my ($op2, $out2) = $instance->startOperation(PEP_OPERATION_TRANSACTION, $options);
    my ($op3, $out3) = $instance->executeOperation(PEP_OPERATION_TRANSACTION, $options);
    my ($op4, $out4) = $instance->finalizeOperation(PEP_OPERATION_TRANSACTION, $options);

    # Wait for completion
    my $status = $instance->operationStatus($op4, 1);

    if($status) {
        print "Transaction completed successfully\n";
        my $result = $out4->toHashref();
        print "Result code: $result->{iResultCode}\n";
    }

=head1 CLEANUP

Instance handles are automatically freed when the object is destroyed.
However, for explicit cleanup:

    $instance = undef;  # Calls DESTROY, frees handle

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

L<Lib::Pepper>, L<Lib::Pepper::OptionList>, L<Lib::Pepper::Constants>,
L<Lib::Pepper::Exception>

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.42.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
