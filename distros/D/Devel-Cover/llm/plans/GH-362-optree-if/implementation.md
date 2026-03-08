# Implementation: Perl 5.43.4 Empty If/Else Block Optimization Fix

## Problem

Perl PR #23367 (https://github.com/Perl/perl5/pull/23367) optimizes away empty
`if{}`, `elsif{}`, and `else{}` blocks from the optree. This caused Devel::Cover
to output branch descriptions as `(cond) ? :` instead of `if (cond) { }`.

## Root Cause Analysis

### Optree Changes

The optimization changes the optree structure differently for main-level code vs
subroutines:

| Context      | Perl 5.42 true   | Perl 5.42 false  | Perl 5.43.4 true | Perl 5.43.4 false |
|--------------|------------------|------------------|------------------|-------------------|
| Main program | scope (LISTOP)   | leave (LISTOP)   | scope (LISTOP)   | null (OP)         |
| Subroutine   | scope (LISTOP)   | leave (LISTOP)   | stub (OP)        | NULL (NULL)       |

### Original Condition (lib/Devel/Cover.pm:1080-1085)

```perl
if (!(
     $cx < 1
  && (is_scope($true) && $true->name ne "null")
  && (is_scope($false) || is_ifelse_cont($false))
  && $self->{'expand'} < 7
))
```

This failed because:
- In subroutines: `is_scope($true)` returns false (true is now `stub`, not `scope`)
- In main: `is_scope($false)` returns false (false is now `null (OP)`, not `leave`)

## Solution

Added checks to detect optimized empty branches:

```perl
if (!(
     $cx < 1
  && $self->{'expand'} < 7
  && (
      B::class($false) eq "NULL"  # sub: empty else optimized to NULL
      || $false->name eq "null"   # main: empty else optimized to null op
      || ((is_scope($true) && $true->name ne "null")
          && (is_scope($false) || is_ifelse_cont($false)))
  )
))
```

### Key Insights

1. **`$cx` context is sufficient**: The precedence context passed by B::Deparse
   (`$cx < 1` = statement level) is the primary indicator for if/else vs ternary.

2. **NULL/null check detects optimization**: When `$false` is either:
   - `NULL` class (subroutine case)
   - `null` name with `OP` class (main program case)

   This indicates empty branch(es) were optimized away, which only happens with
   `if/else` statements (not ternary expressions).

3. **No additional context tracking needed**: Initially explored tracking parent
   ops or statement context through `$self`, but the simpler NULL/null check is
   sufficient.

## Test Coverage

### Current Coverage

| Case | Condition | Test Coverage |
|------|-----------|---------------|
| 1 | `B::class($false) eq "NULL"` - sub with empty else | **NOT COVERED** |
| 2 | `$false->name eq "null"` - main with empty else | Covered by `padrange2` |
| 3 | Original is_scope path (both branches have code) | Covered by `tests/if` |

### History of `padrange2` test

- Added in 2017 (commit 06cb6198) to test padrange deparsing issues
- Original issue: `my @x` in conditional showed as `(XXX)` in Perl 5.18-5.22
- Name refers to padrange op, not the empty if/else issue
- Now serves double duty testing both issues

### Proposed new test: `empty_else`

To properly cover both code paths, add new test `tests/empty_else` containing:

```perl
#!/usr/bin/perl

use strict;
use warnings;

# Main level - exercises: $false->name eq "null"
if ($ARGV[0]) {
} else {
}

# Subroutine - exercises: B::class($false) eq "NULL"
sub test_sub {
    my $x = shift;
    if ($x) {
    } else {
    }
}

test_sub(1);
```

## Testing

Verified fix works correctly:
- `tests/padrange2` now produces `if (my(@x) = 'foo' =~ /(.)/) { }` branch output
- All 84 tests pass on Perl 5.43.4
- No regression on older Perl versions
- Manual verification of subroutine case produces correct output

## References

- Perl PR #23367: https://github.com/Perl/perl5/pull/23367
- Commits in PR:
  - 28911dfd8b03: Optimise away empty else{} blocks
  - f50b07049e91: Optimise away empty if{} blocks (uses OPf_SPECIAL flag)
- Original padrange2 commit: 06cb6198 (2017)
