# Lib::Pepper - Claude AI Assistant Guide

## Project Overview

**Lib::Pepper** is a Perl XS wrapper around the Pepper payment terminal C library (version 25.2.43.51975) from treibauf AG. It provides both low-level bindings and high-level object-oriented interfaces for processing payments through ZVT (Zentraler Kreditausschuss) payment terminals.

**Purpose**: Enable Perl applications to integrate with payment terminals for card payments (credit/debit cards).

**Target Terminals**:
- Generic ZVT (Terminal Type 118) - Standard protocol
- Hobex ZVT (Terminal Type 120) - Hobex-specific
- GP PAY and other ZVT-compliant terminals

## Project Structure

```
Lib-Pepper/
├── lib/
│   └── Lib/
│       └── Pepper/
│           ├── Simple.pm           # HIGH-LEVEL: Easiest API (NEW)
│           ├── Instance.pm         # MID-LEVEL: OO wrapper
│           ├── Constants.pm        # 200+ constants
│           ├── Exception.pm        # Error handling
│           └── OptionList.pm       # Parameter handling
├── Pepper.xs                       # XS bindings to C library
├── examples/
│   ├── simple_payment_example.pl   # Simple module usage (NEW)
│   ├── simple_daily_workflow.pl    # Complete workflow (NEW)
│   ├── simple_endofday.pl          # End-of-day settlement (NEW)
│   ├── real_terminal_test.pl       # Real terminal testing
│   ├── void_payment.pl             # Payment cancellation
│   └── end_of_day_settlement.pl    # Settlement operation
├── t/
│   ├── Lib-Pepper.t                # Basic tests
│   ├── 02-instance.t               # Instance tests
│   └── 03-simple.t                 # Simple module tests (NEW)
└── config/
    ├── pepper_config.xml.example   # Configuration template
    └── pepper_cardtypes.xml        # Card type database
```

## Module Architecture (3 Levels)

### Level 1: XS Bindings (Low-Level)
**Module**: `Lib::Pepper` (Pepper.xs)
**Usage**: Direct C API access
**Complexity**: High - manual handle management, no OO interface
**Example**:
```perl
use Lib::Pepper qw(:all);
my ($result, $handle) = pepCreateInstance($termType, $id);
```

### Level 2: Instance Wrapper (Mid-Level)
**Module**: `Lib::Pepper::Instance`
**Usage**: Object-oriented interface
**Complexity**: Medium - still requires multi-step workflows
**Example**:
```perl
use Lib::Pepper::Instance;
my $instance = Lib::Pepper::Instance->new(...);
$instance->configure(...);
my $result = $instance->transaction(...);
```

### Level 3: Simple API (High-Level) **NEW**
**Module**: `Lib::Pepper::Simple`
**Usage**: Single-constructor, automatic everything
**Complexity**: Low - easiest for end users
**Example**:
```perl
use Lib::Pepper::Simple;
my $pepper = Lib::Pepper::Simple->new(...);  # Everything initialized
my $result = $pepper->doPayment($amount);    # One call
```

## Multi-Terminal Support (NEW - v0.3)

**Lib::Pepper::Simple supports multiple payment terminals in the same process!**

### Overview

Multiple terminals can now coexist in a single process (e.g., PageCamel payment worker), sharing one library initialization while maintaining independent transaction state.

**Before v0.3**: Only ONE terminal per process (second terminal would fail with error -101)
**After v0.3**: UNLIMITED terminals per process (automatic library singleton management)

### How It Works

```perl
# Process-level singleton management with reference counting
# ┌─────────────────────────────────────────────────────────┐
# │                    Process Level                         │
# │  ┌────────────────────────────────────────────────┐    │
# │  │     Lib::Pepper (Singleton - ONE per process)  │    │
# │  │  - Initialized when first terminal created     │    │
# │  │  - Finalized when last terminal destroyed      │    │
# │  └────────────────────────────────────────────────┘    │
# │                     │                                    │
# │       ┌─────────────┼─────────────────┐                 │
# │       ▼             ▼                 ▼                 │
# │  ┌──────────┐  ┌──────────┐      ┌──────────┐         │
# │  │Terminal A│  │Terminal B│      │Terminal C│         │
# │  │ ID: 1    │  │ ID: 2    │      │ ID: 1    │         │
# │  │ .163:008 │  │ .164:008 │      │ .165:001 │         │
# │  │ Type 118 │  │ Type 118 │      │ Type 120 │         │
# │  └──────────┘  └──────────┘      └──────────┘         │
# │   Independent     Independent        Independent        │
# │   transactions    transactions       transactions       │
# └─────────────────────────────────────────────────────────┘
```

### Requirements

**All terminals MUST use:**
- ✅ Identical `license_xml` (or `license_file`)
- ✅ Identical `config_xml` (or `config_file`)
- ✅ Identical `library_path` (if specified)

**Each terminal CAN have:**
- ✅ Different `terminal_address` (IP:port) - **REQUIRED** for different physical terminals
- ✅ Different `terminal_type` (Generic ZVT, Hobex ZVT, etc.)
- ✅ Different per-terminal config (`pos_number`, `merchant_password`, etc.)
- ✅ Different `instance_id` (automatically allocated if not specified)

### Basic Example

```perl
use Lib::Pepper::Simple;
use Lib::Pepper::Constants qw(:all);

# Load config/license (shared by all terminals)
my $license_xml = read_file('/etc/pepper/license.xml');
my $config_xml  = read_file('/etc/pepper/config.xml');

# Create Terminal A (Front counter)
my $terminalA = Lib::Pepper::Simple->new(
    terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    terminal_address => '192.168.1.163:20008',
    license_xml      => $license_xml,  # SAME for all
    config_xml       => $config_xml,   # SAME for all
    pos_number       => '0001',        # Different per terminal
);

# Create Terminal B (Drive-through)
my $terminalB = Lib::Pepper::Simple->new(
    terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    terminal_address => '192.168.1.164:20008',
    license_xml      => $license_xml,  # SAME for all
    config_xml       => $config_xml,   # SAME for all
    pos_number       => '0002',        # Different per terminal
);

# Check process-wide status
my $status = Lib::Pepper::Simple->library_status();
say "Active terminals: $status->{instance_count}";  # 2

# Process payments independently
my $payment1 = $terminalA->doPayment(1000);  # Terminal A
my $payment2 = $terminalB->doPayment(2000);  # Terminal B

# Transactions are completely isolated!
```

### Instance ID Allocation

Instance IDs are **automatically allocated per terminal_type**:

```perl
# Generic ZVT terminals (type 118)
my $t1 = Lib::Pepper::Simple->new(terminal_type => 118, ...);  # instance_id = 1
my $t2 = Lib::Pepper::Simple->new(terminal_type => 118, ...);  # instance_id = 2

# Hobex ZVT terminals (type 120)
my $t3 = Lib::Pepper::Simple->new(terminal_type => 120, ...);  # instance_id = 1

# Manual override (advanced)
my $t4 = Lib::Pepper::Simple->new(
    terminal_type => 118,
    instance_id   => 42,  # Manual ID
    ...
);
```

**Different terminal types maintain separate instance_id sequences.**

### Library Lifecycle (Never-Finalize Design)

**IMPORTANT**: The library is NEVER finalized once initialized!

1. **First terminal created** → Library initialized, counter = 1
2. **Additional terminals created** → Reuse library, counter increments
3. **Terminals destroyed** → Counter decrements, library stays loaded
4. **Last terminal destroyed** → Counter = 0, **library stays initialized**
5. **Process exits** → OS reclaims memory, library unloaded

```perl
my $t1 = Lib::Pepper::Simple->new(...);  # Library INITIALIZED
my $t2 = Lib::Pepper::Simple->new(...);  # Library REUSED

undef $t1;  # Counter = 1, library still active
undef $t2;  # Counter = 0, library STILL ACTIVE (never finalized!)

# Can immediately create new terminals!
my $t3 = Lib::Pepper::Simple->new(...);  # ✓ Works! Counter = 1
```

**Why Never Finalize?**
The Pepper C library has a critical limitation: once `pepFinalize()` is called, `pepInitialize()` returns error -103 (LIBRARY_ALREADY_FINALIZED) and cannot be called again in the same process. See "Never-Finalize Design" in Critical Concepts below.

### Configuration Validation

Second terminal MUST match first terminal's config:

```perl
my $t1 = Lib::Pepper::Simple->new(license_xml => $license1, ...);  # ✅ OK

my $t2 = Lib::Pepper::Simple->new(license_xml => $license2, ...);  # ❌ FAILS!
# Error: Configuration mismatch: Lib::Pepper library already initialized
#        with different config
```

This prevents configuration conflicts and unpredictable behavior.

### Monitoring Status

**Process-wide status** (class method):
```perl
my $status = Lib::Pepper::Simple->library_status();
# Returns:
# {
#     initialized    => 1,        # Library initialized?
#     instance_count => 3,        # Number of active terminals
#     library_path   => '',       # Library path used
#     instance_ids   => {         # Next ID per terminal type
#         118 => 4,
#         120 => 2,
#     },
# }
```

**Per-terminal status** (instance method):
```perl
my $status = $terminalA->checkStatus();
# Returns (includes process-level info):
# {
#     instance_id              => 1,  # This terminal's ID
#     terminal_address         => '192.168.1.163:20008',
#     ready_for_transactions   => 1,
#     process_instance_count   => 3,  # Total active terminals
#     process_library_initialized => 1,
#     ...
# }
```

### Database Schema Recommendation

Store terminal identification with each transaction:

```sql
CREATE TABLE payment_transactions (
    id SERIAL PRIMARY KEY,
    terminal_id VARCHAR(20) NOT NULL,        -- 'terminal_a', 'terminal_b', etc.
    instance_id INTEGER NOT NULL,            -- From checkStatus()->{instance_id}
    order_id INTEGER NOT NULL,
    trace_number VARCHAR(20) NOT NULL,
    reference_number VARCHAR(50) NOT NULL,   -- CRITICAL for card-not-present refunds!
    amount INTEGER NOT NULL,
    transaction_date TIMESTAMP DEFAULT NOW(),

    INDEX idx_terminal (terminal_id),
    INDEX idx_trace (trace_number),
    UNIQUE (terminal_id, trace_number)
);
```

### Complete Workflow Example

```perl
use Lib::Pepper::Simple;
use Lib::Pepper::Constants qw(:all);

# Morning: Initialize multiple terminals
my $frontCounter = Lib::Pepper::Simple->new(
    terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    terminal_address => '192.168.1.163:20008',
    license_file     => '/etc/pepper/license.xml',
    config_file      => '/etc/pepper/config.xml',
    pos_number       => '0001',
);

my $driveThrough = Lib::Pepper::Simple->new(
    terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    terminal_address => '192.168.1.164:20008',
    license_file     => '/etc/pepper/license.xml',  # SAME!
    config_file      => '/etc/pepper/config.xml',   # SAME!
    pos_number       => '0002',
);

# Check system ready
my $libStatus = Lib::Pepper::Simple->library_status();
say "Active terminals: $libStatus->{instance_count}";

# During day: Process payments independently
my $payment1 = $frontCounter->doPayment(10_000);
if($payment1->{authorized}) {
    save_to_db({
        terminal_id      => 'front_counter',
        instance_id      => $frontCounter->checkStatus()->{instance_id},
        trace_number     => $payment1->{trace_number},
        reference_number => $payment1->{reference_number},  # CRITICAL!
        amount           => $payment1->{amount_charged},
    });
}

my $payment2 = $driveThrough->doPayment(15_000);
if($payment2->{authorized}) {
    save_to_db({
        terminal_id      => 'drive_through',
        instance_id      => $driveThrough->checkStatus()->{instance_id},
        trace_number     => $payment2->{trace_number},
        reference_number => $payment2->{reference_number},  # CRITICAL!
        amount           => $payment2->{amount_charged},
    });
}

# If customer cancels (before or after settlement)
my $stored = get_from_db($order_id);
my $terminal = ($stored->{terminal_id} eq 'front_counter')
    ? $frontCounter : $driveThrough;

my $cancel = $terminal->cancelPayment(
    $stored->{trace_number},
    $stored->{amount},
    reference_number => $stored->{reference_number}  # Required!
);

# Evening: Settlement (each terminal independently)
my $eod1 = $frontCounter->endOfDay();
my $eod2 = $driveThrough->endOfDay();

if($eod1->{success} && $eod2->{success}) {
    say "Front counter: $eod1->{transaction_count} transactions";
    say "Drive-through: $eod2->{transaction_count} transactions";
}

# Cleanup (automatic when $frontCounter and $driveThrough destroyed)
```

### Use Cases

1. **Retail with Multiple Checkout Lanes**
   - Each lane has its own terminal
   - All managed by single POS application

2. **Drive-Through + Counter Service**
   - Fast food restaurant
   - Drive-through terminal + counter terminal

3. **Multi-Location Kiosks**
   - Self-service kiosks at different locations
   - Managed by central application

4. **Backup Terminal**
   - Primary terminal with automatic failover to backup

### Limitations

1. **Thread Safety**: Not thread-safe. Don't create instances from different threads simultaneously. Use mutex if threading is required.

2. **Configuration Flexibility**: All terminals must use identical license and config. Cannot mix different licenses in same process.

3. **Manual Instance IDs**: When manually specifying `instance_id`, you are responsible for avoiding conflicts.

### Testing

```bash
# Run multi-terminal tests
make test TEST_FILES="t/04-multi-terminal.t"

# Try the example
cd examples
perl multi_terminal_example.pl --help
perl multi_terminal_example.pl --terminal-a=192.168.1.163:20008 \
                                --terminal-b=192.168.1.164:20008
```

### API Reference

**New class method:**
- `Lib::Pepper::Simple->library_status()` - Check process-wide library state

**Enhanced instance method:**
- `$pepper->checkStatus()` - Now includes `instance_id`, `process_instance_count`, `process_library_initialized`

**New parameter:**
- `instance_id => $id` - Optional parameter to `new()` for manual instance ID

---

## Critical Concepts

### 1. Payment Authorization vs API Success

**CRITICAL**: The most important distinction in payment processing!

```perl
# WRONG - Only checks if API call succeeded
if($result->{status}) {
    # This only means the API call worked!
    # Customer may NOT have been charged!
}

# CORRECT - Check actual payment authorization
my $outputData = $result->{output}->toHashref();
my $transactionResult = $outputData->{iTransactionResultValue} // -999;

if($transactionResult == 0) {
    # Payment AUTHORIZED - customer WAS charged
} else {
    # Payment DECLINED/ABORTED - customer NOT charged
}
```

**Key Fields**:
- `iFunctionResultValue` = API call status (0 = call succeeded)
- `iTransactionResultValue` = Payment status (0 = authorized, -1 = declined/aborted)

### 2. Card-Not-Present Refunds (CRITICAL DISCOVERY)

**IMPORTANT**: For card-not-present refunds (customer does not need to swipe card again), use:

**Transaction Type 12 (VoidGoodsPayment) with sTransactionReferenceNumberString**

```perl
$pepper->cancelPayment(
    $trace_number,
    $amount,
    reference_number => $reference_number  # CRITICAL!
);
```

**Key Discovery** (not documented in Pepper/ZVT docs):
- Despite being called "VOID", Type 12 works AFTER settlement when using `sTransactionReferenceNumberString`
- Does NOT require customer's card to be present
- This is the ONLY way to refund without card swipe on Generic ZVT terminals
- Transaction Type 41 (Credit) ALWAYS requires card, even with reference number

**Requirements**:
- MUST store `sTransactionReferenceNumberString` from original payment
- MUST store `sTraceNumberString` from original payment
- Amount must match original transaction exactly

**How It Works**:
- Before settlement: Instant reversal, no money moves
- After settlement: Refund processes, money returned in 3-5 days
- Customer never needs to be present for either case

### 3. Settlement (Batch Close)

**CRITICAL**: Without settlement, you will NOT receive payment!

**What is Settlement**:
- Finalizes all transactions from the business day
- Triggers actual money transfer to merchant account
- Clears terminal transaction buffer
- After settlement, VOID becomes REFUND

**When to Run**: End of each business day (before midnight)

**Example**:
```perl
my $result = $pepper->endOfDay();
```

### 4. Transaction Identifiers

**CRITICAL FOR REFUNDS - MUST STORE BOTH**:

**Trace Number** (sTraceNumberString):
- Transaction identifier
- Required for cancellation operations
- ALWAYS store in database with order

**Reference Number** (sTransactionReferenceNumberString):
- **CRITICAL FOR CARD-NOT-PRESENT REFUNDS**
- Required to avoid card swipe during refund
- MUST store in database with order
- Without this, terminal will ask for card during refund

**Other IDs**:
- Authorization Code (sAuthorizationNumberString)
- Terminal ID (sTerminalIdentificationString)

### 5. Recovery Operations

**Recovery Flag** (iRecoveryFlag):
- Set when terminal has incomplete operation from previous session
- MUST be handled before new operations
- `Lib::Pepper::Simple` handles automatically

**Manual Recovery**:
```perl
if($configData->{iRecoveryFlag}) {
    # Perform 4-step recovery workflow
    $instance->prepareOperation(PEP_OPERATION_RECOVERY, ...);
    $instance->startOperation(PEP_OPERATION_RECOVERY, ...);
    $instance->executeOperation(PEP_OPERATION_RECOVERY, ...);
    $instance->finalizeOperation(PEP_OPERATION_RECOVERY, ...);
}
```

### 6. Hungarian Notation in Field Names

All Pepper API fields use Hungarian notation prefixes:
- `s` = String (sHostName, sTraceNumberString)
- `i` = Integer (iAmount, iCurrency)
- `h` = Handle (hOptionList)

This is used for type detection in `OptionList->fromHashref()`.

### 7. 4-Step Operation Workflow

For manual control (low-level API):
1. **Prepare**: Validate parameters, allocate resources
2. **Start**: Begin operation, send to terminal
3. **Execute**: Process callbacks, handle I/O
4. **Finalize**: Complete operation, get final result

High-level methods (`transaction()`, `settlement()`) wrap this automatically.

### 8. Never-Finalize Design (CRITICAL - v0.3)

**Lib::Pepper::Simple NEVER calls `pepFinalize()` - the library stays loaded in memory for the process lifetime.**

#### The Problem

The Pepper C library has a critical design flaw:

```c
pepInitialize();  // ✓ Works
pepFinalize();    // ✓ Works

pepInitialize();  // ✗ Returns -103 (LIBRARY_ALREADY_FINALIZED)
// Cannot reinitialize after finalization!
```

**Impact**: Before v0.3, you could only create terminals once. After destroying all terminals, creating a new one would fail with error -103.

#### The Solution

We **never call `pepFinalize()`**:

```perl
sub DESTROY($self) {
    # Clean up instance resources
    undef $self->{instance};

    # Decrement counter
    $INSTANCE_COUNT--;

    # ⚠️ DESIGN DECISION: Never call pepFinalize()
    # Library stays loaded forever

    return;
}
```

#### Benefits

✅ **Unlimited Create/Destroy Cycles**
```perl
# This works perfectly!
for(1..1000) {
    my $terminal = Lib::Pepper::Simple->new(...);  # ✓ Always works
    $terminal->doPayment(100);
    undef $terminal;  # ✓ Clean destroy
    # Can create again immediately!
}
```

✅ **No More -103 Errors**
- Never see "LIBRARY_ALREADY_FINALIZED"
- Can destroy all instances freely
- Create new instances anytime

✅ **Comprehensive Testing Possible**
- Stress tests work (100+ iterations)
- Leak detection across iterations
- Unit tests can create/destroy freely

#### Trade-Offs

**Memory Overhead** (~1-2 MB):
- Library code stays in RAM from first `new()` until process exit
- Instance resources ARE cleaned up properly
- Negligible for long-running processes (POS, workers, daemons)

**Cannot Change Configuration**:
```perl
my $t1 = Lib::Pepper::Simple->new(license_file => $license1, ...);  # ✓
undef $t1;

# Cannot change to different license without process restart
my $t2 = Lib::Pepper::Simple->new(license_file => $license2, ...);  # ✗
# Error: Configuration mismatch
```

**Solution**: Restart process to change library configuration.

#### What IS Cleaned Up

When terminals are destroyed:
- ✅ Instance handles (`pepDestroyInstance` called)
- ✅ Network connections
- ✅ Terminal state
- ✅ Perl objects and memory
- ✗ Library code (~1-2 MB stays loaded)

#### Process Lifetime

```
Process Start
    ↓
First new() → pepInitialize() called → Library loaded
    ↓
[Instances created and destroyed unlimited times]
    ↓
Process Exit → OS reclaims all memory → Library unloaded
```

#### Use Cases

**✅ Perfect For:**
1. Long-running processes (POS systems, PageCamel workers, daemons, web servers)
2. Development & testing (unit tests, stress tests, leak detection)
3. Dynamic terminal management (add/remove terminals at runtime)

**⚠️ Consider Alternatives If:**
1. Very short-lived processes (< 1 second lifetime) - Library init overhead ~100ms
2. Need to change license/config at runtime - Must restart process
3. Extremely memory-constrained (< 10 MB available) - Library uses 1-2 MB

#### Documentation

See `NEVER_FINALIZE_DESIGN.md` for complete details and rationale.

## Lib::Pepper::Simple API (Recommended)

### new() - Full Initialization

```perl
my $pepper = Lib::Pepper::Simple->new(
    terminal_type        => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    terminal_address     => '192.168.1.163:20008',  # IP:port
    config_xml           => $config_xml,            # Required
    license_xml          => $license_xml,           # Required
    library_path         => '',                     # Empty = installed
    pos_number           => '0001',                 # Optional
    merchant_password    => '000000',               # Optional
    language             => PEP_LANGUAGE_ENGLISH,   # Optional
    ticket_printing_mode => 0,                      # Optional (0-4, default: 0 = POS prints)
    callback             => sub { ... },            # Optional
    userdata             => { ... },                # Optional
    reph                 => $logging_handler,       # Optional reporting handler for audit logs
);
```

**What it does automatically**:
- Loads and initializes Pepper library
- Creates instance
- Configures terminal
- Checks and performs recovery if needed
- Opens connection

**Printer Control (ticket_printing_mode)**:

Controls where transaction receipts are printed. Default is 0 (POS prints) which disables the terminal's built-in printer and indicates that your POS/cash register will handle receipt printing. This reduces paper waste when the cash register already prints transaction details on invoices.

**Available Modes**:
- `0` - PEP_TICKET_PRINTING_MODE_POS: **Cash register/POS prints (DEFAULT - disables terminal printer)**
- `1` - PEP_TICKET_PRINTING_MODE_EFT: Terminal prints
- `2` - PEP_TICKET_PRINTING_MODE_CLIENT_ONLY_EFT: Client receipt on terminal only
- `3` - PEP_TICKET_PRINTING_MODE_NONE: No printing at all
- `4` - PEP_TICKET_PRINTING_MODE_ECR_AND_TERMINAL: Both terminal and POS print

**Example** - Enable terminal printing:
```perl
my $pepper = Lib::Pepper::Simple->new(
    ...
    ticket_printing_mode => PEP_TICKET_PRINTING_MODE_EFT,  # Enable terminal printer
);
```

**Command-line Example** - simple_payment_example.pl:
```bash
perl simple_payment_example.pl --terminal-print  # Enable terminal printing (mode 1)
perl simple_payment_example.pl                   # Disable terminal printing (mode 0, default)
```

**IMPORTANT LIMITATION**: Some terminals (including GP PAY) may ignore the software `ticket_printing_mode` setting and continue printing regardless. This is because:
- Many terminals have firmware-level printer settings that override software commands
- The ZVT protocol's print control is advisory, not mandatory
- Terminal firmware may require printing for compliance/audit reasons

**If the terminal still prints despite setting mode 0**:

1. **Access the terminal's admin menu** (most reliable method):
   - GP PAY: Usually accessed via special key combination like `* + 0 + 0 + 0 + 0 + #` (consult manual)
   - Navigate to "Configuration" → "Receipt Printer" settings
   - Set to "Disabled" or "Off"
   - Save and reboot the terminal (change persists across power cycles)

2. **Contact terminal manufacturer**:
   - GP PAY support: https://www.gp-pay.de/support
   - Check firmware version and configuration manual
   - Consider firmware update if available

**Implementation Note**: When `ticket_printing_mode => 0` is set, the module automatically
sets `config_byte => PEP_CONFIG_BYTE_DISABLE_PRINTER` (0x06) internally, which helps disable
the terminal printer on many devices. You don't need to set `config_byte` manually - this is
handled automatically.

**Audit Logging (reph parameter)**:

The `reph` (reporting handler) parameter allows you to provide a custom logging object for audit trails.
The handler must implement a `debuglog(@parts)` method:

```perl
package MyLogger;
sub new { bless {}, shift }
sub debuglog {
    my ($self, @parts) = @_;
    # Log to file, database, syslog, etc.
    print LOG join('', @parts), "\n";
}

my $logger = MyLogger->new();
my $pepper = Lib::Pepper::Simple->new(
    ...
    reph => $logger,  # All internal debug logging goes through this
);
```

If no `reph` is provided, debug output (when enabled via `$ENV{DEBUG_PEPPER}`) falls back to STDERR.
The `reph` handler is automatically passed down to all lower-level Lib::Pepper classes.

### checkStatus() - System Readiness

```perl
my $status = $pepper->checkStatus();

# Returns hashref:
{
    library_initialized   => 1,              # Library initialized
    instance_configured   => 1,              # Terminal configured
    connection_open       => 1,              # Connection established
    ready_for_transactions => 1,             # Ready for transactions
    terminal_type         => 118,            # Terminal type code
    terminal_address      => '192.168.1.163:20008',
    last_error            => undef,          # Last error message
}
```

### doPayment() - Process Payment

```perl
my $result = $pepper->doPayment(
    $amount,                            # Required: amount in cents
    transaction_type => 'goods',        # Optional: 'goods' or numeric constant
    currency         => PEP_CURRENCY_EUR,  # Optional
);

# Returns hashref:
{
    success           => 1,             # API call succeeded
    authorized        => 1,             # Payment authorized (CRITICAL!)
    amount_charged    => 100,           # Amount actually charged
    trace_number      => '1007',        # STORE THIS! For cancellation
    authorization_code => 'AUTH123',
    reference_number  => 'REF456',
    terminal_id       => 'TID789',
    transaction_date  => '2025-11-11',
    transaction_time  => '14:30:00',
    card_name         => 'VISA',
    card_number       => '************1234',
    card_expiry       => '12/26',
    status_text       => 'APPROVED',
    transaction_result => 0,            # 0 = authorized
    operation_handle  => 12345,
}
```

**CRITICAL**: Check `authorized` field, not just `success`!

**Note**: The `transaction_type` parameter accepts user-friendly strings:
- `'goods'` → automatically converted to `PEP_TRANSACTION_TYPE_GOODS_PAYMENT`
- Numeric constants can also be passed directly for other transaction types

### cancelPayment() - Card-Not-Present Refund

```perl
my $result = $pepper->cancelPayment(
    $trace_number,                      # Required: from doPayment()
    $amount,                            # Required: must match original
    reference_number => $reference_number,  # Required: from doPayment()
);

# Returns hashref:
{
    success          => 1,              # Refund succeeded
    trace_number     => '1007',         # New trace number for refund
    amount_refunded  => 100,            # Amount refunded
    transaction_text => 'APPROVED',     # Status text
    raw_output       => {...},          # Complete output
}
```

**Behavior**:
- Uses Transaction Type 12 (VoidGoodsPayment) with `sTransactionReferenceNumberString`
- Works BEFORE and AFTER settlement
- Does NOT require customer's card to be present
- Requires BOTH trace_number AND reference_number from original payment

### endOfDay() - Settlement

```perl
my $result = $pepper->endOfDay();

# Returns hashref:
{
    success            => 1,
    transaction_count  => 15,           # Number of transactions
    total_amount       => 45000,        # Total in cents
    settlement_date    => '2025-11-11',
    settlement_time    => '23:59:00',
    status_text        => 'BATCH COMPLETE',
    function_result    => 0,
    operation_handle   => 67890,
}
```

### DESTROY - Automatic Cleanup

Cleanup happens automatically when object goes out of scope:
- Closes connection
- Destroys instance
- Decrements instance counter
- **Does NOT finalize library** (stays loaded - see "Never-Finalize Design")

## Complete Workflow Example

```perl
use Lib::Pepper::Simple;
use Lib::Pepper::Constants qw(:all);

# 1. Initialize (once at start of day)
my $pepper = Lib::Pepper::Simple->new(
    terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    terminal_address => '192.168.1.163:20008',
    config_xml       => $config_xml,
    license_xml      => $license_xml,
);

# 2. Check system ready
my $status = $pepper->checkStatus();
die "Not ready" unless $status->{ready};

# 3. Process payments
my $result = $pepper->doPayment(100);  # 1.00 EUR
if($result->{authorized}) {
    # Store BOTH trace_number AND reference_number in database
    save_to_db({
        trace_number     => $result->{trace_number},
        reference_number => $result->{reference_number},  # CRITICAL!
        amount           => $result->{amount_charged},
    });
} else {
    # Payment declined
    log_error($result->{status_text});
}

# 4. Refund if needed (works before or after settlement)
my $stored = get_from_db($order_id);
my $cancel = $pepper->cancelPayment(
    $stored->{trace_number},
    $stored->{amount},
    reference_number => $stored->{reference_number}  # Required!
);
if($cancel->{success}) {
    update_db_status('refunded');
}

# 5. End of day settlement (CRITICAL!)
my $eod = $pepper->endOfDay();
if($eod->{success}) {
    log_settlement($eod->{transaction_count}, $eod->{total_amount});
}

# 6. Cleanup (automatic when $pepper destroyed)
```

## Database Schema Recommendation

```sql
CREATE TABLE payment_transactions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,                    -- In cents
    trace_number VARCHAR(20) NOT NULL UNIQUE,   -- Required for refunds
    reference_number VARCHAR(50) NOT NULL,      -- CRITICAL for card-not-present refunds!
    authorization_code VARCHAR(20),
    terminal_id VARCHAR(20),
    card_name VARCHAR(50),
    card_number VARCHAR(20),
    card_expiry VARCHAR(10),
    transaction_date DATE,
    transaction_time TIME,
    status VARCHAR(20) DEFAULT 'completed',     -- completed, refunded
    refunded_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),

    INDEX idx_trace (trace_number),
    INDEX idx_reference (reference_number),
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_date (transaction_date)
);

-- CRITICAL: Without reference_number, refunds will require customer to swipe card again!
```

## Coding Style Requirements

**CRITICAL**: All code must follow `codingstyle.md`:

### AUTOPRAGMA Block (Lines 3-16)
```perl
#---AUTOPRAGMASTART---
use v5.40;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = '0.01';  # Only in packages
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---
```

### Style Rules
- 4-space indentation (NEVER tabs)
- camelCase for variables and methods
- NO space between keyword and parentheses: `if($x)` not `if ($x)`
- Modern Perl signatures: `sub method($self, $param)`
- Use `croak()` for errors
- English variables: `$EVAL_ERROR` not `$@`

### Code Quality Standards

**All code passes strict quality checks**:

- ✅ **POD Documentation**: 100% coverage for all public methods and functions
- ✅ **Perl::Critic**: All policies pass (severity 2+)
  - Uses `use parent` instead of `@ISA`
  - Proper return statements (no `return undef`)
  - DESTROY methods have explicit `return;`
  - No automatic exports (`@EXPORT`)
  - Proper number formatting (underscores in large numbers)
  - No double-sigil dereferences
- ✅ **Unicode Support**: All POD has `=encoding utf8` directive
- ✅ **Module Endings**: All modules end with `1;` (not `return 1;`)

**Testing**:
```bash
make test                    # Run all unit tests
TEST_POD=1 make test        # Run with POD coverage tests
TEST_CRITIC=1 make test     # Run with Perl::Critic checks
```

**Configuration**: `t/perlcriticrc` contains project-specific policy exceptions

## Common Pitfalls

### 1. Checking Wrong Result Field
❌ **WRONG**:
```perl
if($result->{status}) {
    complete_order();  # MAY BE WRONG! Payment might be declined!
}
```

✅ **CORRECT**:
```perl
if($result->{authorized}) {
    complete_order();  # Payment definitely authorized
}
```

### 2. Forgetting Settlement
❌ **WRONG**: Process payments all day, forget settlement
- Result: You never receive payment!

✅ **CORRECT**: Run `endOfDay()` every evening

### 3. Not Storing Reference Number
❌ **WRONG**: Only save trace_number, forget reference_number
- Result: Refunds will require customer to swipe card!

✅ **CORRECT**: Store BOTH trace_number AND reference_number immediately
```perl
save_to_db({
    trace_number     => $result->{trace_number},
    reference_number => $result->{reference_number},  # CRITICAL!
    amount           => $result->{amount_charged},
});
```

### 4. Not Passing Reference Number to cancelPayment
❌ **WRONG**:
```perl
$pepper->cancelPayment($trace, $amount);  # Will ask for card!
```

✅ **CORRECT**:
```perl
$pepper->cancelPayment($trace, $amount,
    reference_number => $reference);  # Card-not-present!
```

### 5. Mock Terminal for Transactions
❌ **WRONG**: Use PEP_TERMINAL_TYPE_MOCK for payment testing
- Result: State transition errors

✅ **CORRECT**: Use real ZVT terminal or skip transaction tests

## Testing

### Unit Tests
```bash
cd Lib-Pepper
make test
```

**Test Files**:
- `t/Lib-Pepper.t` - Basic module loading
- `t/02-instance.t` - Instance functionality
- `t/03-simple.t` - Simple module (uses SKIP for license-required tests)

### Example Scripts
```bash
cd examples/

# Simple API (easiest)
perl simple_payment_example.pl              # Process a payment
perl simple_payment_example.pl --cancel 1007 100  # Cancel payment
perl simple_daily_workflow.pl               # Complete daily workflow
perl simple_endofday.pl                     # End-of-day settlement

# Low-level API
perl real_terminal_test.pl
perl void_payment.pl
perl end_of_day_settlement.pl
```

**simple_payment_example.pl features**:
- Process payments with automatic initialization
- Cancel payments via `--cancel <trace_number> <amount>`
- Argument validation using Array::Contains
- Shows comprehensive transaction details

**simple_endofday.pl features**:
- Dedicated end-of-day settlement script
- Clear warnings about settlement consequences
- User confirmation prompt before proceeding
- Detailed settlement results and next steps
- Comprehensive error handling and troubleshooting guide

## Terminal Configuration

### Generic ZVT (GP PAY)
```perl
terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
terminal_address => '192.168.1.163:20008',  # IP:port
pos_number       => '0001',                  # Numeric, <= 9999
merchant_password => '000000',               # Default
```

### Required Files
1. **License file**: `pepper_license_XXXXXXXX.xml` (from vendor)
2. **Config file**: `pepper_config.xml` (from template)
3. **Cardtypes file**: `pepper_cardtypes.xml` (bundled)

### Config Placeholder (Automatic)

In config XML, use `CARDTYPES_AUTODETECT` placeholder:
```xml
<CardTypes>
    <path>CARDTYPES_AUTODETECT</path>
</CardTypes>
```

**Lib::Pepper::Simple automatically handles this placeholder** - you don't need to do any manual replacement. Simply load your config XML and pass it to the constructor. The module will:
1. Detect the `CARDTYPES_AUTODETECT` placeholder
2. Locate the installed `pepper_cardtypes.xml` file
3. Replace the placeholder with the correct absolute path
4. Use the updated config for initialization

**Low-level API users**: If you're using `Lib::Pepper::Instance` or the raw XS bindings directly, you'll need to handle this replacement yourself using `Lib::Pepper->cardtypesFile()`.

## Support Resources

### Pepper Library Support
- Web: https://www.treibauf.ch/support/integration/contact
- Ticketing: https://www.treibauf.ch/support/integration/ticketing

### Documentation
```bash
perldoc Lib::Pepper::Simple
perldoc Lib::Pepper::Instance
perldoc Lib::Pepper::Constants
perldoc Lib::Pepper::Exception
perldoc Lib::Pepper::OptionList
```

### Project Files
- `IMPLEMENTATION_STATUS.md` - Current status, known issues
- `FINAL_STATUS.md` - Completion status
- `NEVER_FINALIZE_DESIGN.md` - Never-finalize design decision and rationale
- `codingstyle.md` - Coding standards (MUST FOLLOW)

## Recent Improvements

### Multi-Terminal Support (2025-11-14 - v0.3)

- ✅ **MAJOR FEATURE**: Multiple payment terminals in same process
  - Process-level singleton management with reference counting
  - Automatic instance_id allocation per terminal_type
  - Strict configuration validation (all terminals must use same config/license)
  - Independent transaction state per terminal
- ✅ **CRITICAL DESIGN**: Never-finalize pattern
  - Library stays loaded in memory after first initialization
  - Unlimited create/destroy cycles without -103 errors
  - Solves Pepper C library reinitialization bug
  - See `NEVER_FINALIZE_DESIGN.md` for complete rationale
- ✅ New class method: `Lib::Pepper::Simple->library_status()`
- ✅ Enhanced `checkStatus()` with process-level information
- ✅ Comprehensive tests: `t/04-multi-terminal.t`, `t/05-stress-test.t`, `t/06-leak-detection.t`
- ✅ Example scripts: `examples/multi_terminal_example.pl`, `examples/test_never_finalize.pl`
- ✅ Full POD documentation with multi-terminal section
- ✅ Updated CLAUDE.md with complete multi-terminal guide and never-finalize design

### Documentation (2025-11-11)
- ✅ Added 100% POD documentation coverage for all modules
- ✅ Added comprehensive POD for 27 low-level functions in Lib::Pepper
- ✅ Added POD for 2 missing methods in Lib::Pepper::Instance
- ✅ Fixed Unicode encoding in POD (added `=encoding utf8` directives)

### Code Quality (Perl::Critic Compliance)
- ✅ All 6 modules now pass Perl::Critic checks (severity 2+)
- ✅ Fixed module endings (`1;` instead of `return 1;`)
- ✅ Modernized inheritance (`use parent` instead of `@ISA`)
- ✅ Fixed return statements (removed explicit `undef`)
- ✅ Added final `return;` to DESTROY methods
- ✅ Fixed number formatting (underscores in large numbers)
- ✅ Fixed double-sigil dereferences
- ✅ Removed automatic exports

### API Improvements
- ✅ Fixed checkStatus() return keys for consistency
  - `library_initialized`, `instance_configured`, `ready_for_transactions`
- ✅ Added string-to-constant conversion in doPayment()
  - `transaction_type => 'goods'` now works correctly
- ✅ Fixed example scripts to use correct status keys

### Example Scripts
- ✅ Implemented `--cancel` functionality in simple_payment_example.pl
- ✅ Added argument validation using Array::Contains
- ✅ Fixed status key mismatches in all examples
- ✅ Created new simple_endofday.pl for end-of-day settlement
- ✅ All examples now work correctly

### Testing
- ✅ All tests pass (58 unit tests)
- ✅ POD coverage tests pass (TEST_POD=1)
- ✅ Perl::Critic tests pass (TEST_CRITIC=1)
- ✅ All modules and examples compile successfully

## Version Information

- **Lib::Pepper Version**: 0.4
- **Pepper C Library**: 25.2.43.51975
- **Perl Requirement**: v5.40+
- **Status**: ✅ Production Ready
- **Last Updated**: 2025-11-14
- **New in v0.4**: Coding style compliance (replaced `say` with `print` throughout codebase, fixed UTF-8 output handling)
- **New in v0.3**: Multi-terminal support (multiple terminals per process)

## Quick Reference

### Most Common Operations

**Initialize System**:
```perl
my $pepper = Lib::Pepper::Simple->new(...);
```

**Check Ready**:
```perl
my $status = $pepper->checkStatus();
die unless $status->{ready_for_transactions};
```

**Process Payment**:
```perl
my $result = $pepper->doPayment($amount);
if($result->{authorized}) {
    save_db($result->{trace_number});
}
```

**Cancel Payment**:
```perl
my $cancel = $pepper->cancelPayment($trace_number, $amount);
```

**End of Day**:
```perl
my $eod = $pepper->endOfDay();
```

---

**Remember**: Always check `authorized` field, store `trace_number`, and run `endOfDay()` settlement!
