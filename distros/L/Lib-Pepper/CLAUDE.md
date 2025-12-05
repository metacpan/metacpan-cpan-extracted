# Lib::Pepper - Claude AI Assistant Guide

## Overview

Perl XS wrapper for Pepper payment terminal C library (v25.2.43.51975) from treibauf AG. Processes payments via ZVT protocol.

**Terminals**: Generic ZVT (Type 118), Hobex ZVT (Type 120), GP PAY

## Structure

```
lib/Lib/Pepper/
  Simple.pm      # HIGH-LEVEL (recommended)
  Instance.pm    # MID-LEVEL OO wrapper
  Constants.pm   # 200+ constants
  Exception.pm   # Error handling
  OptionList.pm  # Parameter handling
Pepper.xs        # XS bindings
examples/        # Usage examples
t/               # Tests
config/          # XML templates
```

## Module Levels

| Level | Module | Complexity | Use Case |
|-------|--------|------------|----------|
| High | `Lib::Pepper::Simple` | Low | Recommended for most users |
| Mid | `Lib::Pepper::Instance` | Medium | OO wrapper, multi-step workflows |
| Low | `Lib::Pepper` (XS) | High | Direct C API access |

## Quick Start

```perl
use Lib::Pepper::Simple;
use Lib::Pepper::Constants qw(:all);

my $pepper = Lib::Pepper::Simple->new(
    terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
    terminal_address => '192.168.1.163:20008',
    config_xml       => $config_xml,
    license_xml      => $license_xml,
);

my $result = $pepper->doPayment(100);  # 1.00 EUR
if($result->{authorized}) {  # CRITICAL: check authorized, not success!
    save_to_db({
        trace_number     => $result->{trace_number},
        reference_number => $result->{reference_number},  # Required for refunds!
    });
}

$pepper->endOfDay();  # Run daily - or you won't get paid!
```

## Critical Concepts

### 1. Authorization vs API Success
```perl
# WRONG: if($result->{success}) { ... }
# CORRECT:
if($result->{authorized}) { complete_order(); }
```
- `iFunctionResultValue` = API call status (0 = succeeded)
- `iTransactionResultValue` = Payment status (0 = authorized)

### 2. Card-Not-Present Refunds
Store BOTH `trace_number` AND `reference_number` from original payment:
```perl
$pepper->cancelPayment($trace, $amount, reference_number => $ref);
```
- Uses Type 12 (VoidGoodsPayment) with reference - works before AND after settlement
- Without reference_number, customer must swipe card again

### 3. Settlement (End of Day)
**CRITICAL**: Without daily `endOfDay()`, you won't receive payment!

### 4. Never-Finalize Design
Library never calls `pepFinalize()` - stays loaded until process exit. Allows unlimited create/destroy cycles. See `NEVER_FINALIZE_DESIGN.md`.

## Multi-Terminal Support (v0.3+)

Multiple terminals coexist in one process with shared library initialization.

**Requirements**:
- All terminals MUST use identical `license_xml`, `config_xml`, `library_path`
- Each terminal CAN have different `terminal_address`, `terminal_type`, `pos_number`

```perl
my $termA = Lib::Pepper::Simple->new(terminal_address => '192.168.1.163:20008', ...);
my $termB = Lib::Pepper::Simple->new(terminal_address => '192.168.1.164:20008', ...);

my $status = Lib::Pepper::Simple->library_status();  # Process-wide status
```

**Limitations**: Not thread-safe. Cannot mix different licenses in same process.

## Tip Support (Gratuity)

The `tip_enabled` option and tip-related constants exist but **do NOT work with GlobalPayments ZVT terminals**.

### Tested (All Failed on GP ZVT)

| Approach | Result |
|----------|--------|
| Transaction Type 13 (GoodsPaymentWithTip) | Error -1402 (not supported) |
| Transaction Type 61 (TipOnlyPayment) | Error -1102 (not supported) |
| iServiceByteValue=8 (tippable flag) | Completes but no tip dialog shown |

### Workarounds

1. **Contact GlobalPayments** - Ask them to enable tip prompting in your terminal's configuration (terminal-side setting)
2. **Implement tips in your POS** (Recommended):
   ```perl
   my $bill = 5000;      # 50.00 EUR
   my $tip = 500;        # 5.00 EUR tip (entered by customer in your POS UI)
   my $total = $bill + $tip;
   my $result = $pepper->doPayment($total);
   ```
3. **Two-step process** - Payment first, then separate tip payment (not ideal UX)

### Future Compatibility

The `tip_enabled` flag and constants (`PEP_TRANSACTION_TYPE_TIP_ONLY_PAYMENT`, etc.) are retained for terminals that may support tip prompting natively.

## API Reference (Lib::Pepper::Simple)

### new()
```perl
my $pepper = Lib::Pepper::Simple->new(
    terminal_type        => PEP_TERMINAL_TYPE_GENERIC_ZVT,  # Required
    terminal_address     => '192.168.1.163:20008',          # Required
    config_xml           => $xml,        # or config_file
    license_xml          => $xml,        # or license_file
    library_path         => '',          # Empty = installed
    pos_number           => '0001',
    merchant_password    => '000000',
    language             => PEP_LANGUAGE_ENGLISH,
    ticket_printing_mode => 0,           # 0=POS prints (default), 1=terminal prints
    tip_enabled          => 0,           # See "Tip Support" section for limitations
    callback             => sub { ... },
    reph                 => $logger,     # Must implement debuglog(@parts)
);
```

### checkStatus()
```perl
my $s = $pepper->checkStatus();
# {library_initialized, instance_configured, connection_open, ready_for_transactions, ...}
```

### doPayment()
```perl
my $r = $pepper->doPayment($amount_cents, transaction_type => 'goods');
# {authorized, trace_number, reference_number, amount_charged, card_name, ...}
```

### cancelPayment()
```perl
my $r = $pepper->cancelPayment($trace, $amount, reference_number => $ref);
# {success, trace_number, amount_refunded, ...}
```

### endOfDay()
```perl
my $r = $pepper->endOfDay();
# {success, transaction_count, total_amount, ...}
```

## Database Schema

```sql
CREATE TABLE payment_transactions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    trace_number VARCHAR(20) NOT NULL UNIQUE,
    reference_number VARCHAR(50) NOT NULL,  -- CRITICAL for card-not-present refunds!
    terminal_id VARCHAR(20),
    authorization_code VARCHAR(20),
    card_name VARCHAR(50),
    transaction_date DATE,
    status VARCHAR(20) DEFAULT 'completed'
);
```

## Coding Style

**CRITICAL**: Follow `codingstyle.md`

```perl
#---AUTOPRAGMASTART---
use v5.40;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = '0.01';
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---
```

**Rules**: 4-space indent, camelCase, no space before parens (`if($x)`), modern signatures, `croak()` for errors, `$EVAL_ERROR` not `$@`

**Quality**: All modules pass POD coverage and Perl::Critic (severity 2+). Modules end with `1;`.

## Testing

```bash
make test                    # Unit tests
TEST_POD=1 make test        # POD coverage
TEST_CRITIC=1 make test     # Perl::Critic
```

## Common Pitfalls

1. **Check `authorized`, not `success`** - API success != payment authorized
2. **Run `endOfDay()` daily** - Or you won't receive payment
3. **Store BOTH trace_number AND reference_number** - Both needed for refunds
4. **Pass reference_number to cancelPayment()** - Or customer must swipe card

## Config Files

- License: `pepper_license_XXXXXXXX.xml` (from vendor)
- Config: `pepper_config.xml` (use `CARDTYPES_AUTODETECT` placeholder - auto-replaced)
- Cardtypes: `pepper_cardtypes.xml` (bundled)

## Support

- Pepper: https://www.treibauf.ch/support/integration/ticketing
- Docs: `perldoc Lib::Pepper::Simple`
- Files: `IMPLEMENTATION_STATUS.md`, `NEVER_FINALIZE_DESIGN.md`, `codingstyle.md`

## Version

- **Lib::Pepper**: 0.5 (Production Ready)
- **Pepper C Library**: 25.2.43.51975
- **Perl**: v5.40+
- **v0.5**: Added `tip_enabled` option (note: not functional on GlobalPayments ZVT - see "Tip Support" section)
- **v0.4**: Coding style compliance
- **v0.3**: Multi-terminal support
