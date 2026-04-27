package Func::Util;

use strict;
use warnings;
our $VERSION = '0.03';

# DynaLoader with RTLD_GLOBAL so our C API symbols (funcutil_register_export_xs,
# funcutil_register_predicate_xs, etc.) are visible to other XS modules that
# link against us at runtime. XSLoader on older Perls doesn't honour dl_load_flags.
use DynaLoader;
our @ISA = ('DynaLoader');
sub dl_load_flags { 0x01 }
__PACKAGE__->bootstrap($VERSION);
1;

__END__

=head1 NAME

Func::Util - Functional programming utilities with XS/OP acceleration

=head1 SYNOPSIS

    use Func::Util qw(
        memo pipeline compose partial lazy force dig tap clamp identity always
        noop stub_true stub_false stub_array stub_hash stub_string stub_zero
        nvl coalesce first any all none
        first_gt first_lt first_ge first_le first_eq first_ne
        final final_gt final_lt final_ge final_le final_eq final_ne
        any_gt any_lt any_ge any_le any_eq any_ne
        all_gt all_lt all_ge all_le all_eq all_ne
        none_gt none_lt none_ge none_le none_eq none_ne
        uniq partition pick omit pluck defaults count replace_all negate once
        is_ref is_array is_hash is_code is_defined is_string
        is_empty starts_with ends_with trim ltrim rtrim
        is_true is_false bool
        is_num is_int is_blessed is_scalar_ref is_regex is_glob
        is_positive is_negative is_zero
        is_even is_odd is_between
        is_empty_array is_empty_hash array_len hash_size
        array_first array_last
        maybe sign min2 max2
    );

    # Type predicates - compile-time optimized
    if (is_array($data)) { ... }
    if (is_hash($config)) { ... }
    if (is_code($callback)) { ... }
    if (is_defined($value)) { ... }

    # Boolean/Truthiness predicates
    if (is_true($value)) { ... }   # Perl truth semantics
    if (is_false($value)) { ... }  # Perl false semantics
    my $normalized = bool($value); # Normalize to 1 or ''

    # Extended type predicates
    if (is_num($value)) { ... }        # Numeric value or looks like number
    if (is_int($value)) { ... }        # Integer value
    if (is_blessed($obj)) { ... }      # Blessed reference
    if (is_scalar_ref($ref)) { ... }   # Scalar reference
    if (is_regex($qr)) { ... }         # Compiled regex (qr//)
    if (is_glob(*FH)) { ... }          # Glob

    # Numeric predicates
    if (is_positive($num)) { ... }     # > 0
    if (is_negative($num)) { ... }     # < 0
    if (is_zero($num)) { ... }         # == 0
    if (is_even($num)) { ... }         # n & 1 == 0
    if (is_odd($num)) { ... }          # n & 1 == 1
    if (is_between($n, 1, 10)) { ... } # Range check (inclusive)

    # Collection predicates - direct AvFILL/HvKEYS access
    if (is_empty_array($aref)) { ... }
    if (is_empty_hash($href)) { ... }
    my $len = array_len($aref);        # Direct AvFILL access
    my $size = hash_size($href);       # Direct HvKEYS access
    my $first = array_first($aref);    # Without slice overhead
    my $last = array_last($aref);      # Without slice overhead

    # String predicates - direct SvPV/SvCUR access
    if (is_empty($str)) { ... }
    if (starts_with($filename, '/')) { ... }
    if (ends_with($filename, '.txt')) { ... }

    # Memoization - cache function results
    my $fib = memo(sub {
        my $n = shift;
        return $n if $n < 2;
        return $fib->($n-1) + $fib->($n-2);
    });

    # Pipelines - chain transformations
    my $result = pipeline($data,
        \&fetch,
        \&transform,
        \&process
    );

    # Lazy evaluation - defer computation
    my $expensive = lazy { heavy_computation() };
    my $result = force($expensive);

    # Safe navigation - no exceptions
    my $val = dig($hash, qw(deep nested key));

    # Null coalescing
    my $val = nvl($maybe_undef, $default);
    my $val = coalesce($a, $b, $c);  # First defined

    # List operations with callbacks
    my $found = first(sub { $_->{active} }, \@users);
    if (any(sub { $_ > 10 }, \@numbers)) { ... }
    if (all(sub { $_->{valid} }, \@records)) { ... }

    # Specialized predicates - pure C, no callback overhead
    my $large = first_gt(\@numbers, 100);              # first > 100
    my $adult = first_ge(\@users, 'age', 18);          # first user age >= 18
    my $last_minor = final_lt(\@users, 'age', 18);     # last user age < 18
    if (any_gt(\@values, $threshold)) { ... }          # any > threshold
    if (all_ge(\@scores, 60)) { ... }                  # all >= 60
    if (none_lt(\@ages, 18)) { ... }                   # no minors

    # Debugging helper - execute side effect, return original
    my $result = tap(sub { print "Got: $_\n" }, $value);

    # Constrain value to range
    my $clamped = clamp($value, $min, $max);

    # Identity function - returns argument unchanged
    my $same = identity($x);

    # Constant function factory
    my $get_zero = always(0);
    my $get_config = always({ debug => 1 });
    $get_zero->();  # Always returns 0

=head1 DESCRIPTION

C<Func::Util> provides functional programming utilities implemented in XS/C.

B<Custom ops> (compile-time optimization, no function call overhead):

=over 4

=item * C<identity> - eliminated entirely at compile time

=item * C<is_ref>, C<is_array>, C<is_hash>, C<is_code>, C<is_defined> - single SV flag check

=item * C<is_true>, C<is_false>, C<bool> - direct SvTRUE check

=item * C<is_num>, C<is_int>, C<is_blessed>, C<is_scalar_ref>, C<is_regex>, C<is_glob> - extended type checks

=item * C<is_positive>, C<is_negative>, C<is_zero> - numeric comparisons

=item * C<is_even>, C<is_odd> - single bitwise AND

=item * C<is_between> - range check (two comparisons)

=item * C<is_empty_array>, C<is_empty_hash> - direct AvFILL/HvKEYS check

=item * C<array_len>, C<hash_size> - direct AvFILL/HvKEYS access

=item * C<array_first>, C<array_last> - direct av_fetch without slice overhead

=item * C<is_empty>, C<starts_with>, C<ends_with> - direct SvPV/SvCUR string access

=item * C<trim>, C<ltrim>, C<rtrim> - whitespace trimming

=item * C<maybe> - conditional return (if defined)

=item * C<sign> - return -1/0/1 based on sign

=item * C<min2>, C<max2> - two-value min/max

=item * C<clamp> - inlined numeric comparison

=back

B<XS functions> (faster than pure Perl, but still have call overhead):

=over 4

=item * C<memo>, C<force>, C<dig> - memoization and safe navigation

=item * C<nvl>, C<coalesce> - null coalescing

=item * C<first>, C<any>, C<all>, C<none> - short-circuit list operations

=item * C<pipeline>, C<compose> - micro improvements (~15-20%)

=item * C<lazy>, C<tap>, C<always> - deferred evaluation and debugging

=back

Functions that call arbitrary Perl coderefs (C<pipeline>, C<compose>, C<tap>,
C<first>, C<any>, C<all>, C<none>) are limited by C<call_sv()> overhead and
cannot achieve the same performance as pure data operations.

=head1 FUNCTIONS

=head2 memo

    my $cached = memo(\&expensive_function);
    my $result = $cached->($arg);

Returns a memoized version of the given function. Results are cached
based on arguments, so repeated calls with the same arguments return
instantly from the cache.

=head2 pipeline

    my $result = pipeline($initial_value, \&fn1, \&fn2, \&fn3);

Pipes a value through a series of functions, passing the result of each
function as the argument to the next. Equivalent to C<fn3(fn2(fn1($value)))>
but more readable.

=head2 compose

    my $pipeline = compose(\&fn3, \&fn2, \&fn1);
    my $result = $pipeline->($value);

Creates a new function that composes the given functions right-to-left.
C<compose(\&c, \&b, \&a)> creates a function equivalent to C<sub { c(b(a(@_))) }>.

=head2 partial

    my $add5 = partial(\&add, 5);
    my $result = $add5->(3);  # add(5, 3) = 8

Creates a partially applied function with some arguments pre-bound.
The returned function, when called, prepends the bound arguments
to any new arguments.

B<Note:> Creating AND calling a partial is 125% faster than pure Perl.
However, repeatedly calling an already-created partial is ~20% slower
than a hand-written closure. Use partial when you create once and call
many times from different contexts, or for cleaner functional code.

=head2 lazy

    my $deferred = lazy { expensive_computation() };

Creates a lazy value that defers computation until forced. The computation
runs at most once; subsequent forces return the cached result.

=head2 force

    my $result = force($lazy_value);

Forces evaluation of a lazy value, returning the computed result.
If the value has already been forced, returns the cached result.
Non-lazy values pass through unchanged.

=head2 dig

    my $val = dig($hashref, @keys);
    my $val = dig($hashref, 'a', 'b', 'c');  # $hashref->{a}{b}{c}

Safely traverses a nested hash structure. Returns undef if any key
is missing, without throwing an exception.

=head2 tap

    my $result = tap(\&block, $value);
    my $result = tap(sub { print "Debug: $_\n" }, $value);

Executes a side-effect block with the value (setting C<$_> and passing
as argument), then returns the original value unchanged. Useful for
debugging pipelines without affecting data flow.

=head2 clamp

    my $clamped = clamp($value, $min, $max);

Constrains a numeric value to a range. Returns C<$min> if C<$value E<lt> $min>,
C<$max> if C<$value E<gt> $max>, otherwise returns C<$value>.

=head2 identity

    my $same = identity($value);

Returns the argument unchanged. Uses compile-time optimization to
eliminate the function call entirely. Useful as a default transformer
in pipelines or when an API requires a function but you want a no-op.

=head2 always

    my $get_value = always($constant);
    $get_value->();        # Returns $constant
    $get_value->(1,2,3);   # Still returns $constant (args ignored)

Creates a function that always returns the same value, ignoring any arguments.
Useful for callbacks that need to return a fixed value.

=head2 noop

    noop();           # Returns undef
    noop(1, 2, 3);    # Ignores args, returns undef

Does nothing, returns undef. Ignores all arguments. Useful as a default
callback or placeholder.

B<Note:> This returns C<undef> (not empty list) for correct behavior in
map contexts. The standalone C<noop> module returns empty list which is
~45% faster but produces different results in C<map { noop() } @list>.

=head2 stub_true, stub_false

    stub_true();      # Always returns 1
    stub_false();     # Always returns ''

Constant functions that always return true or false. Useful as default
predicates:

    my @all = grep { stub_true() } @items;   # Accepts all
    my @none = grep { stub_false() } @items; # Rejects all

=head2 stub_array, stub_hash

    my $arr = stub_array();   # Returns new []
    my $hash = stub_hash();   # Returns new {}

Factory functions that return new empty arrayrefs or hashrefs.
Each call returns a fresh reference.

=head2 stub_string, stub_zero

    stub_string();    # Returns ''
    stub_zero();      # Returns 0

Return empty string or zero. Unlike C<stub_false>, these return
specific values rather than just falsy values.

=head2 nvl

    my $val = nvl($value, $default);

Returns C<$value> if defined, otherwise returns C<$default>. This is the
null coalescing operator found in many languages (C<??> in C#, C<//> in Perl 5.10+).

=head2 coalesce

    my $val = coalesce($a, $b, $c, ...);

Returns the first defined value from the argument list. If all arguments
are undefined, returns C<undef>.

=head2 first

    my $found = first(sub { $_->{active} }, \@list);

Returns the first element in C<\@list> for which the block returns true.
Sets C<$_> to each element in turn. Returns C<undef> if no element matches.
Short-circuits on first match. Takes an arrayref to avoid stack flattening
overhead (5-6x faster than list-based version for early matches).

=head2 any

    my $bool = any(sub { $_ > 10 }, \@list);

Returns true if the block returns true for any element in C<\@list>.
Short-circuits on first match.

=head2 all

    my $bool = all(sub { $_->{valid} }, \@list);

Returns true if the block returns true for all elements in C<\@list>.
Returns true for an empty list (vacuous truth). Short-circuits on first failure.

=head2 none

    my $bool = none(sub { $_->{error} }, \@list);

Returns true if the block returns false for all elements in C<\@list>.
Equivalent to C<not any { ... } @list>. Short-circuits on first match.

=head1 SPECIALIZED ARRAY PREDICATES

These functions perform pure C comparisons without any Perl callback
overhead.

All functions support two forms:

=over 4

=item * 2-arg: C<first_gt(\@numbers, $threshold)> - array of scalars

=item * 3-arg: C<first_gt(\@users, 'age', $threshold)> - array of hashes

=back

=head2 first_gt, first_ge, first_lt, first_le, first_eq, first_ne

    # Find first element > 500
    my $found = first_gt(\@numbers, 500);

    # Find first user with age >= 18
    my $adult = first_ge(\@users, 'age', 18);

Returns the first element matching the comparison, or undef if none match.

=head2 final, final_gt, final_ge, final_lt, final_le, final_eq, final_ne

    # Find last element > 500 (with callback)
    my $found = final(sub { $_ > 500 }, \@numbers);

    # Find last element > 500 (specialized)
    my $found = final_gt(\@numbers, 500);

    # Find last user with age < 18 (most recent minor)
    my $minor = final_lt(\@users, 'age', 18);

Returns the last element matching the comparison, or undef if none match.
Uses backwards iteration for efficiency - stops as soon as a match is found
from the end of the array.

=head2 any_gt, any_ge, any_lt, any_le, any_eq, any_ne

    # Check if any element > threshold
    if (any_gt(\@numbers, 100)) { ... }

    # Check if any user is under 18
    if (any_lt(\@users, 'age', 18)) { ... }

Returns true if any element matches the comparison.

=head2 all_gt, all_ge, all_lt, all_le, all_eq, all_ne

    # Check if all scores are passing
    if (all_ge(\@scores, 60)) { ... }

    # Check if all users are adults
    if (all_ge(\@users, 'age', 18)) { ... }

Returns true if all elements match the comparison. Returns true for empty arrays.

=head2 none_gt, none_ge, none_lt, none_le, none_eq, none_ne

    # Check if no element exceeds limit
    if (none_gt(\@values, 1000)) { ... }

    # Check if no user is a minor
    if (none_lt(\@users, 'age', 18)) { ... }

Returns true if no element matches the comparison.

=head1 CALLBACK REGISTRY

The callback registry provides named callbacks that can be used with
the C<*_cb> functions. This avoids Perl callback overhead for common
predicates and enables XS modules to register C-level callbacks for
maximum performance.

=head2 Built-in Predicates

All built-in predicates are prefixed with C<:> to distinguish them
from user-registered callbacks:

    :is_defined     - SvOK check
    :is_true        - SvTRUE check  
    :is_false       - !SvTRUE check
    :is_ref         - SvROK check
    :is_array       - Array reference
    :is_hash        - Hash reference
    :is_code        - Code reference
    :is_positive    - Numeric > 0
    :is_negative    - Numeric < 0
    :is_zero        - Numeric == 0
    :is_even        - Integer divisible by 2
    :is_odd         - Integer not divisible by 2
    :is_empty       - Undefined, empty string, empty array, or empty hash
    :is_nonempty    - Defined and non-empty
    :is_string      - Defined, not a reference
    :is_number      - Looks like a number
    :is_integer     - Integer value

=head2 any_cb, all_cb, none_cb

    my $bool = any_cb(\@numbers, ':is_positive');
    my $bool = all_cb(\@numbers, ':is_even');
    my $bool = none_cb(\@numbers, ':is_negative');

Like C<any>, C<all>, and C<none> but use a registered callback by name.
No Perl callback overhead - runs entirely in C.

=head2 first_cb

    my $found = first_cb(\@numbers, ':is_positive');

Returns the first element for which the callback returns true.
Returns undef if no element matches.

=head2 grep_cb

    my @positives = grep_cb(\@numbers, ':is_positive');

Returns all elements for which the callback returns true.

=head2 count_cb

    my $n = count_cb(\@numbers, ':is_positive');

Counts elements for which the callback returns true.

=head2 partition_cb

    my ($pass, $fail) = partition_cb(\@numbers, ':is_positive');

Splits an array into two arrayrefs: the first contains elements
matching the predicate, the second contains non-matching elements.
Returns two arrayrefs.

=head2 final_cb

    my $last = final_cb(\@numbers, ':is_positive');

Returns the last element for which the callback returns true.
Searches from the end of the array for efficiency. Returns undef
if no element matches.

=head2 register_callback

    register_callback('divisible_by_3', sub { $_[0] % 3 == 0 });

Registers a Perl coderef as a named callback. The coderef receives
the element as its first argument. Names cannot start with C<:>
(reserved for built-ins) and cannot re-register existing names.

=head2 has_callback

    if (has_callback('divisible_by_3')) { ... }

Returns true if a callback with the given name is registered.

=head2 list_callbacks

    my $callbacks = list_callbacks();

Returns an arrayref of all registered callback names.

=head2 XS Callback Registration

External XS modules can register C-level callbacks for maximum performance.
Include the header in your XS code:

    #include "funcutil_callbacks.h"

Then register callbacks:

    static bool my_is_valid(pTHX_ SV *elem) {
        return SvOK(elem) && SvIV(elem) > 0;
    }

    BOOT:
        funcutil_register_predicate_xs("my_is_valid", my_is_valid);

The C callback avoids all Perl overhead - no call_sv, no stack manipulation.
See C<xs/util/funcutil_callbacks.h> for the full API.

=head1 DATA MANIPULATION

These functions transform and extract data from arrays and hashes.

=head2 uniq

    my @unique = uniq(@list);

Returns a list with duplicate values removed, preserving order.
The first occurrence of each value is kept. Uses a hash for O(1) lookups.

=head2 partition

    my ($evens, $odds) = partition(sub { $_ % 2 == 0 }, \@numbers);

Splits an array into two arrayrefs based on a predicate. The first
contains elements for which the predicate returns true, the second
contains elements for which it returns false.

=head2 pick

    my $subset = pick(\%hash, @keys);

Returns a new hashref containing only the specified keys from the
source hash. Missing keys are silently ignored.

    my $user_info = pick(\%user, 'name', 'email');

=head2 omit

    my $filtered = omit(\%hash, @keys);

Returns a new hashref with the specified keys removed.
Opposite of C<pick>.

    my $safe = omit(\%user, 'password', 'secret_token');

=head2 pluck

    my @ids = pluck(\@users, 'id');

Extracts a single field from an array of hashes. Returns a list
of values for that field from each hash.

    my @names = pluck(\@employees, 'name');

=head2 defaults

    my $merged = defaults(\%hash, \%defaults);

Returns a new hashref with values from C<%defaults> filled in for
any missing keys in C<%hash>. Does not modify the original hashes.

    my $config = defaults(\%user_config, { timeout => 30, retries => 3 });

=head2 count

    my $n = count(sub { $_ > 10 }, \@numbers);

Counts how many elements in the list satisfy the predicate.
More efficient than C<scalar grep { ... } @list> because it
doesn't build an intermediate list.

=head2 replace_all

    my $result = replace_all($string, $search, $replace);

Replaces all occurrences of C<$search> in C<$string> with C<$replace>.
Faster than C<< $str =~ s/\Q$search\E/$replace/g >> for literal strings
because it avoids regex compilation.

=head2 negate

    my $not_even = negate(sub { $_ % 2 == 0 });

Returns a new function that negates the result of the given predicate.
Useful for inverting filters.

    my @odds = grep { negate(\&is_even)->($_) } @numbers;

=head2 once

    my $init_once = once(\&initialize);
    $init_once->();  # Runs initialize()
    $init_once->();  # Returns cached result, doesn't run again

Wraps a function to ensure it only executes once. Subsequent calls
return the cached result of the first call.

=head1 TYPE PREDICATES

These functions use custom ops and are replaced at compile time with
direct SV flag checks. They have zero function call overhead.

=head2 is_ref

    my $bool = is_ref($value);

Returns true if C<$value> is a reference (any type).

=head2 is_array

    my $bool = is_array($value);

Returns true if C<$value> is an array reference.

=head2 is_hash

    my $bool = is_hash($value);

Returns true if C<$value> is a hash reference.

=head2 is_code

    my $bool = is_code($value);

Returns true if C<$value> is a code reference.

=head2 is_defined

    my $bool = is_defined($value);

Returns true if C<$value> is defined (not C<undef>).

=head2 is_string

    my $bool = is_string($value);

Returns true if C<$value> is a plain scalar (defined and not a reference).
This is useful when you want to check if a value is a simple string or number,
not undef and not a reference to something else.

    is_string("hello");      # true
    is_string(42);           # true
    is_string(undef);        # false
    is_string([1,2,3]);      # false (arrayref)
    is_string({a=>1});       # false (hashref)

=head1 STRING PREDICATES

These functions use custom ops with direct SvPV/SvCUR access.

=head2 is_empty

    my $bool = is_empty($value);

Returns true if C<$value> is undefined or an empty string.

=head2 starts_with

    my $bool = starts_with($string, $prefix);

Returns true if C<$string> starts with C<$prefix>. Uses direct
memcmp. Returns false if either argument is undefined.

=head2 ends_with

    my $bool = ends_with($string, $suffix);

Returns true if C<$string> ends with C<$suffix>. Uses direct
memcmp. Returns false if either argument is undefined.

=head2 trim

    my $trimmed = trim($string);

Removes leading and trailing whitespace from C<$string>.
Returns a new string with whitespace removed. Returns undef
if C<$string> is undefined. Whitespace includes spaces, tabs,
newlines, and other ASCII whitespace characters.

=head2 ltrim

    my $trimmed = ltrim($string);

Removes leading whitespace only from C<$string>.
Trailing whitespace is preserved. Returns undef if C<$string>
is undefined.

=head2 rtrim

    my $trimmed = rtrim($string);

Removes trailing whitespace only from C<$string>.
Leading whitespace is preserved. Returns undef if C<$string>
is undefined.

=head1 CONDITIONAL OPS

These functions use custom ops for conditional operations.

=head2 maybe

    my $result = maybe($value, $then);

Returns C<$then> if C<$value> is defined, otherwise returns undef.
Conditionally returns a value based on
whether another value is defined.

    # Instead of: defined($x) ? $y : undef
    my $result = maybe($x, $y);

    # Useful for safe transformations:
    my $upper = maybe($input, uc($input));

=head1 NUMERIC OPS

These functions use custom ops for numeric operations.

=head2 sign

    my $s = sign($number);

Returns -1 if C<$number> is negative, 0 if zero, 1 if positive.
Returns undef for non-numeric values.

B<Note:> If you only need the comparison result and don't need undef handling,
the spaceship operator C<< $number <=> 0 >> is faster.

=head2 min2

    my $smaller = min2($a, $b);

Returns the smaller of two numeric values.

=head2 max2

    my $larger = max2($a, $b);

Returns the larger of two numeric values.

=head1 BOOLEAN/TRUTHINESS PREDICATES

These functions use custom ops for Perl truth semantics checks.

=head2 is_true

    my $bool = is_true($value);

Returns true if C<$value> is truthy according to Perl semantics.
This means: defined, non-empty string, non-zero number.

=head2 is_false

    my $bool = is_false($value);

Returns true if C<$value> is falsy according to Perl semantics.
This includes: undef, empty string "", string "0", numeric 0.

=head2 bool

    my $normalized = bool($value);

Normalizes C<$value> to a boolean (1 for true, '' for false).
Useful when you need a consistent boolean representation.

=head1 EXTENDED TYPE PREDICATES

These functions use custom ops for extended type checking.

=head2 is_num

    my $bool = is_num($value);

Returns true if C<$value> is numeric (has a numeric value or
looks like a number). Uses C<looks_like_number> for strings.

=head2 is_int

    my $bool = is_int($value);

Returns true if C<$value> is an integer. Returns true for
whole number floats like 5.0.

=head2 is_blessed

    my $bool = is_blessed($value);

Returns true if C<$value> is a blessed reference (an object).
Uses C<sv_isobject>.

=head2 is_scalar_ref

    my $bool = is_scalar_ref($value);

Returns true if C<$value> is a scalar reference (not array/hash/code).

=head2 is_regex

    my $bool = is_regex($value);

Returns true if C<$value> is a compiled regular expression (qr//).

=head2 is_glob

    my $bool = is_glob($value);

Returns true if C<$value> is a glob (like *STDIN, *main::foo).

=head1 NUMERIC PREDICATES

These functions use custom ops for numeric comparisons.
They first check if the value is numeric, then perform the comparison.

=head2 is_positive

    my $bool = is_positive($value);

Returns true if C<$value> is numeric and greater than zero.
Returns false for non-numeric values.

=head2 is_negative

    my $bool = is_negative($value);

Returns true if C<$value> is numeric and less than zero.
Returns false for non-numeric values.

=head2 is_zero

    my $bool = is_zero($value);

Returns true if C<$value> is numeric and equals zero.
Returns false for non-numeric values.

=head2 is_even

    my $bool = is_even($value);

Returns true if C<$value> is an integer and even (divisible by 2).

=head2 is_odd

    my $bool = is_odd($value);

Returns true if C<$value> is an integer and odd (not divisible by 2).

=head2 is_between

    my $bool = is_between($value, $min, $max);

Returns true if C<$value> is numeric and between C<$min> and C<$max>
(inclusive). Returns false for non-numeric values.

=head1 COLLECTION PREDICATES

These functions use custom ops for collection operations
with direct AvFILL/HvKEYS access.

=head2 is_empty_array

    my $bool = is_empty_array($arrayref);

Returns true if C<$arrayref> is an array reference with no elements.
Returns false for non-arrayrefs. Uses direct AvFILL check.

=head2 is_empty_hash

    my $bool = is_empty_hash($hashref);

Returns true if C<$hashref> is a hash reference with no keys.
Returns false for non-hashrefs. Uses direct HvKEYS check.

=head2 array_len

    my $len = array_len($arrayref);

Returns the length of the array using direct AvFILL access.
Returns undef for non-arrayrefs.

=head2 hash_size

    my $size = hash_size($hashref);

Returns the number of keys in the hash using direct HvKEYS access.
Returns undef for non-hashrefs.

=head2 array_first

    my $elem = array_first($arrayref);

Returns the first element of the array without slice overhead.
Returns undef for empty arrays or non-arrayrefs.

=head2 array_last

    my $elem = array_last($arrayref);

Returns the last element of the array without slice overhead.
Returns undef for empty arrays or non-arrayrefs.

=head1 C API FOR XS MODULES

XS modules can register functions with Func::Util's export system by including
C<funcutil_export.h>:

    #include "funcutil_export.h"

=head2 funcutil_register_export_xs

    void funcutil_register_export_xs(pTHX_ const char *name, XSUBADDR_t xs_func);

Register an XS function as a util export. After registration, users can
import the function via C<use Func::Util qw(name)>.

Example (see C<t/xs/funcutil_export_test/> for full working code):

    static XS(xs_my_function) {
        dXSARGS;
        // implementation
        XSRETURN(1);
    }

    BOOT:
        funcutil_register_export_xs(aTHX_ "my_function", xs_my_function);

Users can then:

    use Func::Util qw(my_function is_array);  # Import your function + util's

=head2 Perl API

    Func::Util::register_export($name, \&coderef)  # Register Perl coderef
    Func::Util::has_export($name)                   # Check if registered
    Func::Util::list_exports()                      # List all registered names

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
