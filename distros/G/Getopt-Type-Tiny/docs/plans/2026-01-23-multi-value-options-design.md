# Multi-Value Options Auto-Inference Design

## Overview

Add automatic inference of GetOpt::Long repeat modifiers (`=s@`, `=i@`, etc.) from Type::Tiny `ArrayRef` and `HashRef` types.

**Before:**
```perl
'servers=s@' => { isa => ArrayRef[Str], default => sub { [] } }
```

**After:**
```perl
servers => { isa => ArrayRef[Str] }
```

## Type-to-Spec Mapping

When `get_opts` encounters an `ArrayRef[X]` or `HashRef[X]` type without explicit GetOpt::Long syntax:

1. Extract the inner type parameter `X`
2. Check if `X` is a subtype of `Int`, `Num`, `Str`, or `Any` (in that order)
3. Map to the appropriate GetOpt::Long modifier:

| Type | Modifier |
|------|----------|
| `ArrayRef[Int or subtype]` | `=i@` |
| `ArrayRef[Num or subtype]` | `=f@` |
| `ArrayRef[Str or subtype]` | `=s@` |
| `ArrayRef[Any or Item]` | `=s@` |
| `HashRef[Int or subtype]` | `=i%` |
| `HashRef[Num or subtype]` | `=f%` |
| `HashRef[Str or subtype]` | `=s%` |
| `HashRef[Any or Item]` | `=s%` |

**Detection method:** Use Type::Tiny's `is_a_type_of()` method to check ancestry.

## Error Handling for Unsupported Types

`croak` immediately during `get_opts` processing when:

- `ArrayRef` or `HashRef` has no type parameter (e.g., bare `ArrayRef`)
- Inner type is not a subtype of `Str`, `Int`, `Num`, or `Any`
- Wrapped types like `Maybe[ArrayRef[Str]]`

**Error message format:**

```
Unsupported type 'ArrayRef[HashRef[Str]]' for option 'servers'.

GetOpt::Long only supports ArrayRef and HashRef with inner types that are
subtypes of Str, Int, or Num.

To fix this, either:
  1. Use explicit GetOpt::Long syntax: 'servers=s@' => { isa => ArrayRef[HashRef[Str]] }
  2. Simplify your type to ArrayRef[Str], ArrayRef[Int], or ArrayRef[Num]
```

For bare `ArrayRef`/`HashRef` without a parameter:

```
Unsupported type 'ArrayRef' for option 'servers'.

ArrayRef and HashRef require a type parameter (e.g., ArrayRef[Str]).

To fix this, either:
  1. Use explicit GetOpt::Long syntax: 'servers=s@' => { isa => ArrayRef }
  2. Specify the inner type: ArrayRef[Str], ArrayRef[Int], or ArrayRef[Num]
```

## Mismatch Warnings and `nowarn` Option

If user provides explicit GetOpt::Long syntax AND an `isa` type where we can infer a different modifier:

```perl
'servers=s@' => { isa => ArrayRef[Int] }  # Would infer =i@, but user specified =s@
```

**Warning message:**

```
Option 'servers' has explicit spec '=s@' but type 'ArrayRef[Int]' suggests '=i@'.
Type::Tiny will still validate the values. Use 'nowarn => 1' to suppress this warning.
```

**Suppressing the warning:**

```perl
'servers=s@' => { isa => ArrayRef[Int], nowarn => 1 }
```

## Auto-Defaults for ArrayRef and HashRef

When `isa` is `ArrayRef[...]` or `HashRef[...]` and no `default` is specified:

- `ArrayRef` types auto-default to `sub { [] }`
- `HashRef` types auto-default to `sub { {} }`

Using a coderef internally to avoid shared reference issues if `get_opts` is called multiple times.

User can still override:

```perl
servers => { isa => ArrayRef[Str], default => sub { ['localhost'] } }
```

If user doesn't want a default, they can use `required => 1`.

## Implementation Structure

### New helper function `_infer_getopt_modifier($type)`

Returns the GetOpt::Long modifier (`=s@`, `=i%`, etc.) or `undef` if not inferrable.

```perl
sub _infer_getopt_modifier($type) {
    my $name = $type->name;

    # Check if it's ArrayRef or HashRef
    return undef unless $name =~ /^(ArrayRef|HashRef)/;

    my $container = $1;
    my $suffix = $container eq 'ArrayRef' ? '@' : '%';

    # Get inner type parameter
    my $param = $type->type_parameter;
    return undef unless $param;  # Bare ArrayRef/HashRef - will error later

    # Check ancestry (order matters: Int before Num since Int is subtype of Num)
    my $sigil = $param->is_a_type_of(Int) ? 'i'
              : $param->is_a_type_of(Num) ? 'f'
              : $param->is_a_type_of(Str) ? 's'
              : $param->is_a_type_of(Any) ? 's'
              : undef;

    return undef unless $sigil;
    return "=$sigil$suffix";
}
```

### New helper function `_validate_multi_value_type($name, $type)`

Validates that ArrayRef/HashRef types are supported, croaks with helpful message if not.

```perl
sub _validate_multi_value_type($name, $type) {
    my $type_name = $type->name;

    # Only validate ArrayRef and HashRef
    return unless $type_name =~ /^(ArrayRef|HashRef)/;

    my $param = $type->type_parameter;

    unless ($param) {
        croak <<"END_ERROR";
Unsupported type '$type_name' for option '$name'.

ArrayRef and HashRef require a type parameter (e.g., ArrayRef[Str]).

To fix this, either:
  1. Use explicit GetOpt::Long syntax: '$name=s\@' => { isa => $type_name }
  2. Specify the inner type: ArrayRef[Str], ArrayRef[Int], or ArrayRef[Num]
END_ERROR
    }

    my $is_supported = $param->is_a_type_of(Int)
                    || $param->is_a_type_of(Num)
                    || $param->is_a_type_of(Str)
                    || $param->is_a_type_of(Any);

    unless ($is_supported) {
        my $inner_name = $param->name;
        my $suffix = $type_name eq 'ArrayRef' ? '@' : '%';
        croak <<"END_ERROR";
Unsupported type '$type_name' for option '$name'.

GetOpt::Long only supports ArrayRef and HashRef with inner types that are
subtypes of Str, Int, or Num.

To fix this, either:
  1. Use explicit GetOpt::Long syntax: '$name=s$suffix' => { isa => $type_name }
  2. Simplify your type to ArrayRef[Str], ArrayRef[Int], or ArrayRef[Num]
END_ERROR
    }
}
```

### Changes to `get_opts` main loop

1. After extracting `isa`, call `_validate_multi_value_type` to check for unsupported types
2. Call `_infer_getopt_modifier` to get the modifier
3. If modifier inferred and no explicit modifier in spec → append it
4. If modifier inferred and explicit modifier exists but differs → warn (unless `nowarn`)
5. If ArrayRef/HashRef type and no default specified → auto-default to `[]` or `{}`

## Test Cases

### Auto-inference happy path

- `ArrayRef[Str]` → parses `--opt=a --opt=b` into `['a', 'b']`
- `ArrayRef[Int]` → parses `--opt=1 --opt=2` into `[1, 2]`
- `ArrayRef[Num]` → parses `--opt=1.5 --opt=2.5` into `[1.5, 2.5]`
- `HashRef[Str]` → parses `--opt=k1=v1 --opt=k2=v2` into `{k1 => 'v1', k2 => 'v2'}`
- `HashRef[Int]` → parses `--opt=k1=1 --opt=k2=2` into `{k1 => 1, k2 => 2}`
- `HashRef[Num]` → parses `--opt=k1=1.5 --opt=k2=2.5` into `{k1 => 1.5, k2 => 2.5}`

### Subtype support

- `ArrayRef[PositiveInt]` → infers `=i@`, Type::Tiny validates positivity
- `ArrayRef[NonEmptyStr]` → infers `=s@`, Type::Tiny validates non-empty

### Any/Item support

- `ArrayRef[Any]` → infers `=s@`
- `HashRef[Item]` → infers `=s%`

### Auto-defaults

- `ArrayRef[Str]` with no args → returns `[]`
- `HashRef[Str]` with no args → returns `{}`
- User-specified default overrides auto-default

### Error cases

- `ArrayRef` (bare) → croaks with helpful message
- `HashRef` (bare) → croaks with helpful message
- `ArrayRef[HashRef[Str]]` → croaks with helpful message
- `Maybe[ArrayRef[Str]]` → croaks with helpful message

### Warning cases

- `'opt=s@' => { isa => ArrayRef[Int] }` → warns about mismatch
- `'opt=s@' => { isa => ArrayRef[Int], nowarn => 1 }` → no warning

### Backwards compatibility

- `'opt=s@' => { isa => ArrayRef[Str] }` → works as before, no warning (matches)

## Documentation Updates

- Remove "LIMITATIONS" section from README and POD
- Add new section explaining auto-inference behavior
- Document supported types (`ArrayRef[Str]`, `ArrayRef[Int]`, `ArrayRef[Num]`, etc.)
- Document `HashRef` support
- Document the `nowarn` option
- Document auto-defaults behavior
