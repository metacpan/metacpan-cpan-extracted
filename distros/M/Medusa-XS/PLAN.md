# Plan: Medusa::XS with Custom Ops

## TL;DR

Create `Medusa::XS` - a separate CPAN distribution using **custom ops** (like Legba) to eliminate subroutine call overhead entirely. Inject C-level auditing directly into the Perl optree. Targets all bottlenecks: high-volume logging, deep stacks, and large parameters. Expected 5-10x speedup.

## Current Architecture

Medusa wraps functions with `:Audit` attribute. Per-call overhead:
1. **Caller stack walking** — iterative `caller()` loop (O(n) where n = stack depth)
2. **FORMAT_MESSAGE** — timestamp, GUID, Data::Dumper + 3 regex subs, sprintf loops
3. **Wrapper closure** — subroutine call overhead on every audited invocation

## Steps

### Phase 1: Distribution Setup

1. Create `Medusa-XS/` distribution structure:
   - `Makefile.PL` — WriteMakefile with XS configuration
   - `ppport.h` — generate via `perl -MDevel::PPPort -e 'Devel::PPPort::WriteFile()'`
   - `lib/Medusa/XS.pm` — thin loader with `XSLoader::load()`
   - `XS.xs` — main XS file
   - Copy test framework from `../Medusa/t/`

### Phase 2: Custom Op Infrastructure *(parallel with step 1)*

2. **Define XOP structures** in XS.xs — modeled on `../Legba/Legba.xs`:
   - `XOP medusa_xop_audit_enter` — fires on wrapped function entry
   - `XOP medusa_xop_audit_leave` — fires on wrapped function exit
   - `XOP medusa_xop_caller_stack` — collects caller chain
   - `XOP medusa_xop_format_log` — assembles log message

3. **Create custom op structs** with embedded data:
   ```c
   typedef struct {
       BASEOP
       SV *method_name;    /* audited function name */
       SV *log_config;     /* pointer to %LOG hash */
   } AUDITOP;
   ```

### Phase 3: Core pp Functions (Critical Path)

4. **`pp_medusa_caller_stack`** — *replaces caller() loop* (*depends on step 2*)
   - Walk `cx_stack` / `PL_curstackinfo` directly in C
   - Build `Pkg1:Line1->Pkg2:Line2` string without Perl API overhead
   - Return pre-allocated SV (avoid sv_setpv per iteration)
   - Reference: `../Medusa/lib/Medusa.pm` lines 146-151

5. **`pp_medusa_format_log`** — *replaces FORMAT_MESSAGE* (*parallel with step 4*)
   - C-level timestamp: `gettimeofday()` + custom `strftime`
   - Inline GUID generation (reject libuuid dep, use pure C)
   - Single-pass Dumper output cleanup (no regex engine)
   - Direct string building with pre-sized buffer
   - Reference: `../Medusa/lib/Medusa.pm` lines 48-100

6. **`pp_medusa_audit_enter`** and **`pp_medusa_audit_leave`** (*depends on steps 4-5*):
   - Capture `@_` efficiently via `MARK/SP`
   - Record `Time::HiRes::time` equivalent via `gettimeofday()`
   - Call `pp_medusa_caller_stack` and `pp_medusa_format_log` inline
   - Write to logger (file handle cached in op struct)

### Phase 4: Checker Hook for :Audit Attribute

7. **Implement `MODIFY_CODE_ATTRIBUTES` in XS** (*depends on step 6*):
   - Intercept `:Audit` attribute at compile time
   - Use `cv_set_call_checker()` (Perl 5.14+) to inject custom ops
   - Replace CV's start op with audit wrapper optree
   - Preserve original code for execution within wrapper
   - Reference: `../Legba/Legba.xs` import handling

8. **Optree injection utilities**:
   - `make_audit_op()` — allocate and initialize AUDITOP
   - `inject_audit_wrapper()` — splice ops before/after original CV body
   - Register ops with `Perl_custom_op_register()` for 5.14+

### Phase 5: C Utility Functions ✅ COMPLETE

9. **`medusa_clean_dumper(char* src, STRLEN len)`** — single-pass cleanup: ✅
   - Skip `$VAR1 = ` prefix (first 9 chars if present)
   - State machine for whitespace collapse outside quotes
   - Strip trailing `;\n`
   - Return new SV* with cleaned data

10. **`medusa_generate_guid()`** — pure C UUID v4: ✅
    - Use `/dev/urandom` or `arc4random()` for randomness
    - Format directly to string buffer
    - No external library dependency

11. **`medusa_format_time(char* buf, size_t buflen, bool gmtime, char* fmt)`**: ✅
    - `gettimeofday()` for microseconds
    - `strftime()` for formatting
    - Custom `%ms` placeholder handling

**Tests**: t/01-xs-functions.t (11 subtests) + t/05-utilities-edge.t (9 subtests)

### Phase 6: Perl-Level Integration ✅ COMPLETE

12. **`Medusa::XS::wrap_sub($coderef)`** — XSUB wrapper for dynamic auditing: ✅
    - XS implementation available
    - Also Perl-level MODIFY_CODE_ATTRIBUTES for :Audit attribute

13. **Backward-compatible import interface**: ✅
    ```perl
    use Medusa::XS (
        LOG_FILE => 'audit.log',
        LOG_LEVEL => 'info',
    );
    ```
    - Same configuration as Medusa (%LOG hash)
    - Drop-in replacement (log_message, FORMAT_MESSAGE, :Audit)
    - Medusa::Logger included

**Tests**: t/11-import.t, t/12-audit-attribute-compat.t, t/14-custom-logger.t

### Phase 7: Testing & Validation ✅ COMPLETE

14. **Port tests** from `../Medusa/t/` — verify identical behavior: ✅
    - t/10-logger.t (11 tests) - Medusa::Logger
    - t/11-import.t (8 tests) - import configuration
    - t/12-audit-attribute-compat.t (5 tests) - :Audit compatibility
    - t/13-log-message.t (6 tests) - log_message function
    - t/14-custom-logger.t (8 tests) - custom logger classes
    - t/15-elapsed.t (4 tests) - elapsed time tracking
    - t/16-format-message.t (10 tests) - FORMAT_MESSAGE
    - t/17-custom-format.t (6 tests) - custom FORMAT_MESSAGE

15. **Output parity tests**: ✅
    - FORMAT_MESSAGE produces same output structure
    - Same QUOTE character, timestamp format, parameter formatting

16. **All 115 tests pass** across 17 test files

## Relevant Files

- `../Medusa/lib/Medusa.pm` — `FORMAT_MESSAGE` (lines 48-100), caller loop (lines 146-151), `MODIFY_CODE_ATTRIBUTES` (lines 117-185)
- `../Medusa/lib/Medusa/Logger.pm` — file logger with flock (I/O bound, low XS priority)
- `../Legba/Legba.xs` — **primary reference** for custom ops pattern, XOP registration, SLOTOP struct
- `../Tlaloc/Tlaloc.xs` — MAGIC vtable pattern (useful if we add per-sub metadata)
- `../Legba/lib/Legba.pm` — minimal XSLoader wrapper pattern

## XS Performance Results

Benchmark results from `bench/xs_benchmark.pl`:

| Operation | Pure Perl | XS | Speedup |
|-----------|-----------|-----|---------|
| GUID Generation | 244K/s | 5M/s | **20x** |
| Timestamp Format | 500K/s | 3.3M/s | **6.7x** |
| Dumper Cleanup | 556K/s | 5M/s | **9x** |
| Caller Stack | 122K/s | 122K/s | 1x (XS call overhead) |

The :Audit wrapper uses XS utilities for:
- `generate_guid()` — Pure C UUID v4 with arc4random
- `format_time()` — Direct gettimeofday + strftime
- `clean_dumper()` — Single-pass C state machine (no regex)
- `collect_caller_stack()` — cx_stack walk (marginal gain)

## Verification

1. **Compile test**: `perl Makefile.PL && make && make test` passes on Perl 5.14, 5.20, 5.32, 5.38
2. **Output parity**: For identical input, XS produces byte-identical log output vs pure Perl
3. **Caller accuracy**: `xs_caller_stack` matches Perl's `caller()` chain exactly
4. **Thread safety**: Tests pass under `use threads; threads->create(...)` workloads
5. **Benchmark**: `perl -Mblib bench/xs_benchmark.pl` shows ≥5x improvement:
   - GUID: 20x faster
   - Timestamp: 6.7x faster
   - Dumper cleanup: 9x faster
6. **Memory check**: `valgrind --leak-check=full perl t/*.t` reports no leaks
7. **Edge cases**: Unicode method names, empty `@_`, `wantarray` context preserved, recursive audited calls

## Decisions

- **Separate distribution**: `Medusa-XS` on CPAN, not bundled — keeps pure-Perl Medusa available for no-compiler environments
- **Minimum Perl**: 5.14 (required for XOP API and `cv_set_call_checker`)
- **Custom ops over XSUBs**: Eliminates sub-call overhead (~100ns per call saved)
- **Pure C GUID**: Avoid libuuid dependency; use `/dev/urandom` + format (portable, ~50 lines)
- **Data::Dumper retained initially**: Custom serializer is scope creep; focus on formatting cleanup
- **No MAGIC on CVs**: Unlike Tlaloc, we don't need persistent per-scalar state; custom ops carry context

## Further Considerations

1. **Optree debugging**: How to show injected ops? *Recommend*: Add `Medusa::XS::dump_ops($cv)` wrapper around `B::Concise`
2. **Hot-patching existing subs**: Support `Medusa::XS::audit($pkg, 'method_name')` without recompilation? *Recommend*: Yes, but Phase 2 — requires runtime optree manipulation
3. **Logger optimization**: Should we also XS the file I/O? *Recommend*: No — `flock` + `print` are already C-level via Perl; bottleneck is formatting, not I/O
