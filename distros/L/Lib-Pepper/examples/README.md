# Lib::Pepper Examples

This directory contains example scripts demonstrating how to use the Lib::Pepper module for payment terminal integration.

## Setup Instructions

### 1. Install the Module

First, build and install the Lib::Pepper module:

```bash
cd /path/to/Lib-Pepper
perl Makefile.PL
make
make test
sudo make install  # Or install to local::lib
```

This will install:
- Perl modules to the standard library location
- Shared libraries (libpepperc.so, libpepcore.so) to `auto/Lib/Pepper/`

### 2. Configure the Examples

#### a. Copy the Configuration Template

```bash
cd examples/
cp config/pepper_config.xml.example config/pepper_config.xml
```

The configuration file uses relative paths and is already set up for the examples directory structure.

#### b. Verify Directory Structure

The following directories should exist (created automatically if missing):

```
examples/
├── config/
│   ├── pepper_config.xml           # Your config (copied from .example)
│   ├── pepper_config.xml.example   # Template
│   └── pepper_cardtypes.xml        # Card types database
├── data/
│   ├── logging/
│   │   └── archive/
│   └── runtime/
└── *.pl                            # Example scripts
```

#### c. Obtain a License File

Contact your Pepper library vendor (treibauf AG) to obtain a license file. The license file path should be specified in the examples or passed as an XML string.

Default license location expected by examples:
```
/home/cavac/src/pepperclient/pepper_license_8v5r22cg.xml
```

You can modify this path in each example script.

### 3. Run the Examples

#### Simple Transaction Example

Demonstrates the high-level API with automatic transaction workflow:

```bash
cd examples/
perl simple_transaction.pl
```

**What it does**:
- Initializes Pepper library with config and license
- Creates a mock terminal instance (for testing)
- Configures the instance with callbacks
- Demonstrates transaction and settlement operations

#### Manual Workflow Example

Demonstrates the low-level 4-step operation workflow:

```bash
cd examples/
perl manual_workflow.pl
```

**What it does**:
- Shows manual control over prepare/start/execute/finalize steps
- Demonstrates callback event handling
- Provides detailed logging of each operation phase

## Example Scripts

### simple_transaction.pl

**Purpose**: Quick start example using high-level API

**Key Features**:
- High-level `transaction()` and `settlement()` methods
- Automatic operation workflow management
- Callback handling with output display
- Error handling examples

**Terminal Type**: Mock terminal (PEP_TERMINAL_TYPE_MOCK)

### manual_workflow.pl

**Purpose**: Advanced example with full control over operation steps

**Key Features**:
- Manual 4-step workflow (prepare → start → execute → finalize)
- Operation status checking
- Detailed callback event logging
- Transaction options handling

**Terminal Type**: Mock terminal (PEP_TERMINAL_TYPE_MOCK)

### real_terminal_test.pl

**Purpose**: Test payment processing with a real payment terminal (GP PAY)

**Key Features**:
- Real terminal connection via Generic ZVT protocol
- Complete payment workflow with actual card transactions
- Transaction ID capture and display
- Detailed success/failure reporting with payment authorization checking
- Recovery operation handling
- **Displays all transaction identifiers needed for void operations**

**Terminal Type**: Generic ZVT (PEP_TERMINAL_TYPE_GENERIC_ZVT)

**Usage**:
```bash
# Test a 1.00 EUR payment
perl real_terminal_test.pl

# Or specify custom amount in cents
AMOUNT=500 perl real_terminal_test.pl  # 5.00 EUR
```

**What it returns on success**:
- Trace Number (critical for void operations)
- Authorization Code
- Transaction Reference Number
- Terminal ID
- Transaction Date/Time
- Card information

### void_payment.pl

**Purpose**: Intelligently cancel a payment (automatically handles VOID or REFUND)

**Key Features**:
- **Automatically tries VOID first** (instant cancellation for same-day)
- **Auto-retries as REFUND** if VOID fails (for settled transactions)
- Works seamlessly for both same-day and next-day cancellations
- **Shows detailed success/failure analysis**
- No need to manually choose between VOID and REFUND
- Explains the operation performed and why

**Terminal Type**: Generic ZVT (PEP_TERMINAL_TYPE_GENERIC_ZVT)

**Usage**:
```bash
# Interactive mode (prompts for input)
perl void_payment.pl

# Command line mode
perl void_payment.pl <trace_number> <amount_in_cents>

# Example: Cancel transaction with trace 1007, amount 1.00 EUR
# Works for both same-day (VOID) and next-day (REFUND) cancellations
perl void_payment.pl 1007 100
```

**How It Works**:
1. Attempts **VOID** (instant, no money moves)
2. If VOID fails because transaction is settled → **Automatically tries REFUND**
3. Shows clear results: which operation was used and outcome

**Important Notes**:
- **Same-day cancellation**: Uses VOID (instant, no charge)
- **Next-day cancellation**: Automatically uses REFUND (3-5 days to process)
- Amount must match the original transaction
- Get trace number from real_terminal_test.pl output

**Example Output**:
```
⚠  VOID failed because: transaction already settled
↻  AUTOMATICALLY RETRYING AS REFUND...

✓✓✓ REFUND SUCCESSFUL - MONEY WILL BE RETURNED ✓✓✓
✓ Customer will receive refund in 3-5 business days.
```

**Workflow**:
1. Run `real_terminal_test.pl` to make a payment → Note the Trace Number
2. Run `void_payment.pl` with that trace number → Automatically cancels (VOID or REFUND)
3. Check output to see which operation was used

### void_transaction_DOCUMENTATION.pl

**Purpose**: Documentation and code examples for void operations

**Key Features**:
- Explains VOID vs REFUND
- Database schema examples
- Code patterns for storing transaction IDs
- Best practices for payment cancellation

**This is documentation only** - use `void_payment.pl` for actual void operations.

### end_of_day_settlement.pl

**Purpose**: Perform end-of-day settlement (batch close)

**Key Features**:
- Finalizes ALL transactions from the current business day
- Triggers actual money transfer to merchant account
- Generates settlement reports and totals
- Clears terminal transaction buffer
- **CRITICAL: Without settlement, you will NOT receive payment!**

**Terminal Type**: Generic ZVT (PEP_TERMINAL_TYPE_GENERIC_ZVT)

**Usage**:
```bash
# Run at end of business day
perl end_of_day_settlement.pl
```

**What Settlement Does**:
1. ✓ Finalizes all authorized payments
2. ✓ Submits batch to payment processor
3. ✓ Initiates fund transfer to your bank account
4. ✓ Prints settlement reports (keep for reconciliation!)
5. ✓ Clears terminal's transaction buffer
6. ⚠ After settlement, VOID operations become REFUND operations

**When to Run**:
- **Daily**: At end of each business day (before midnight)
- **After transactions**: When all daily transactions are complete
- **Before void deadline**: VOID only works before settlement
- **Multiple times**: Some merchants settle 2-3 times per day

**Settlement Reports Show**:
- Total number of transactions
- Total amount by card type
- Merchant copy
- Bank/customer copy

**IMPORTANT**: Keep settlement reports for accounting and reconciliation!

## Complete Daily Workflow

Here's the typical daily payment workflow:

**Morning - Start of Day:**
```bash
# Optional: Check terminal is ready
perl check_terminal_connection.pl
```

**During the Day - Processing Payments:**
```bash
# For each customer payment
perl real_terminal_test.pl

# If customer cancels (same day only!):
perl void_payment.pl <trace_number> <amount>
```

**Evening - End of Day:**
```bash
# CRITICAL: Finalize all transactions
perl end_of_day_settlement.pl
```

**After Settlement:**
- Transactions are final
- Money transfer initiated
- VOID no longer works (use REFUND for next-day returns)
- Ready for new business day

## Configuration Details

### pepper_config.xml

The configuration file controls:

- **Logging**: Where log files are stored and rotation settings
- **CardTypes**: Path to card types database (maps card numbers to brands)
- **Working Directory**: Runtime data and temporary files

All paths in the example config are relative to the `examples/` directory.

### Logging

Logs are written to `./data/logging/` and include:
- Library initialization and finalization
- Instance creation and configuration
- Operation workflows and state transitions
- Callback invocations
- Error conditions

Check logs if examples fail to understand what went wrong.

## Terminal Types

The examples use mock terminals for demonstration. For production use, change to real terminal types:

### Generic ZVT Terminal (Type 118)

```perl
my $instance = Lib::Pepper::Instance->new(
    terminal_type => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    instance_id   => 1,
);

$instance->configure(
    callback => $callback,
    options  => {
        sHostName                => '192.168.1.100:20007',  # Terminal IP:port
        iLanguageValue           => PEP_LANGUAGE_ENGLISH,
        sPosIdentificationString => '1234',
        iTicketWidthValue        => 40,
    },
);
```

### Hobex ZVT Terminal (Type 120)

```perl
my $instance = Lib::Pepper::Instance->new(
    terminal_type => PEP_TERMINAL_TYPE_HOBEX_ZVT,
    instance_id   => 1,
);
```

Configuration is similar to Generic ZVT.

## Mock Terminal Limitations

**IMPORTANT**: The mock terminal (TT999) has limited functionality:

⚠️ **Mock terminals are designed primarily for card recognition testing and configuration validation**

What works with mock terminals:
- ✅ Library initialization
- ✅ Instance creation
- ✅ Configuration with callbacks
- ✅ OPEN operation (with proper options)

What does NOT work with mock terminals:
- ❌ TRANSACTION operations (state transition error -1301)
- ❌ SETTLEMENT operations
- ❌ Full payment workflows

**For transaction testing, use real ZVT terminals** (Generic or Hobex).

The state transition errors you may see with mock terminals are expected behavior and do not indicate a problem with the Lib::Pepper module.

## Troubleshooting

### "Config file not found" Error

**Solution**: Copy the example config:
```bash
cp config/pepper_config.xml.example config/pepper_config.xml
```

### "Library initialization failed with code: -103"

**Possible causes**:
- License file not found or invalid
- Config paths don't exist
- Logging/working directories not created

**Solution**:
1. Check license file path
2. Ensure all directories in config exist
3. Check data/logging/ and data/runtime/ are writable

### "Invalid state transition (code: -1301)" During Transactions

**Cause**: Mock terminal limitation

**Solution**:
- For testing configuration: This is expected, mock terminal is working correctly
- For testing transactions: Use a real Generic ZVT or Hobex ZVT terminal

### "Cannot load library"

**Cause**: Shared libraries not found

**Solution**:
1. Run `make install` to install libraries
2. Verify library_path is set to `''` (empty string) in examples
3. Check RPATH configuration: `ldd /path/to/Pepper.so`

### Permission Errors in data/

**Cause**: Directories not writable

**Solution**:
```bash
chmod -R 755 data/
```

## Real-World Usage

For production payment processing:

1. **Obtain proper hardware**: Generic ZVT or Hobex ZVT terminal
2. **Connect terminal**: Via serial port, USB, or TCP/IP
3. **Configure connection**: Set `sHostName` to terminal address
4. **Test with small amounts**: Verify terminal responds correctly
5. **Implement proper error handling**: Handle all callback events
6. **Log transactions**: For compliance and debugging

## Support

### Pepper Library Support

Contact treibauf AG for Pepper library support:
- Web: https://www.treibauf.ch/support/integration/contact
- Ticketing: https://www.treibauf.ch/support/integration/ticketing

### Lib::Pepper Module Issues

For issues with the Perl module itself:
- Check documentation: `perldoc Lib::Pepper::Instance`
- Review logs in data/logging/
- Consult IMPLEMENTATION_STATUS.md in module root

## Additional Resources

- **Module Documentation**: `perldoc Lib::Pepper`
- **Constants Reference**: `perldoc Lib::Pepper::Constants`
- **Error Handling**: `perldoc Lib::Pepper::Exception`
- **Option Lists**: `perldoc Lib::Pepper::OptionList`

## License

The examples are provided as part of the Lib::Pepper distribution.
Pepper library license terms apply for production use.
