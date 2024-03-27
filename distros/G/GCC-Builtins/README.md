# NAME

GCC::Builtins - access GCC compiler builtin functions via XS

# VERSION

Version 0.04

# SYNOPSIS

This module provides Perl access to GCC C compiler
builtin functions.

    use GCC::Builtins qw/:all/;
    # or use GCC::Builtins qw/ ... clz ... /;
    my $leading_zeros = GCC::Builtins::clz(10);
    # 28

# EXPORT

- `uint16_t bswap16(uint16_t)`
- `uint32_t bswap32(uint32_t)`
- `uint64_t bswap64(uint64_t)`
- `int clrsb(int)`
- `int clrsbl(long)`
- `int clrsbll(long long)`
- `int clz(unsigned int)`
- `int clzl(unsigned long)`
- `int clzll(unsigned long long)`
- `int ctz(unsigned int)`
- `int ctzl(unsigned long)`
- `int ctzll(unsigned long long)`
- `int ffs(int)`
- `int ffsl(long)`
- `int ffsll(long long)`
- `double huge_val()`
- `float huge_valf()`
- `long double huge_vall()`
- `double inf()`
- `_Decimal128 infd128()`
- `_Decimal32 infd32()`
- `_Decimal64 infd64()`
- `float inff()`
- `long double infl()`
- `double nan(const char)`
- `float nanf(const char)`
- `long double nanl(const char)`
- `int parity(unsigned int)`
- `int parityl(unsigned long)`
- `int parityll(unsigned long long)`
- `int popcount(unsigned int)`
- `int popcountl(unsigned long)`
- `int popcountll(unsigned long long)`
- `double powi(double,int)`
- `float powif(float,int)`
- `long double powil(long double,int)`

Export tag `:all` imports **all** exportable functions, like:

    use GCC::Builtins qw/:all/;

# SUBROUTINES

## `uint16_t bswap16(uint16_t)`

Returns x with the order of the bytes reversed; for example,
0xaabb becomes 0xbbaa.  Byte here always means
exactly 8 bits.

## `uint32_t bswap32(uint32_t)`

Similar to \_\_builtin\_bswap16, except the argument and return types
are 32-bit.

## `uint64_t bswap64(uint64_t)`

Similar to \_\_builtin\_bswap32, except the argument and return types
are 64-bit.

## `int clrsb(int)`

Returns the number of leading redundant sign bits in x, i.e. the
number of bits following the most significant bit that are identical
to it.  There are no special cases for 0 or other values. 

## `int clrsbl(long)`

Similar to \_\_builtin\_clrsb, except the argument type is
long.

## `int clrsbll(long long)`

Similar to \_\_builtin\_clrsb, except the argument type is
long long.

## `int clz(unsigned int)`

Returns the number of leading 0-bits in x, starting at the most
significant bit position.  If x is 0, the result is undefined.

## `int clzl(unsigned long)`

Similar to \_\_builtin\_clz, except the argument type is
unsigned long.

## `int clzll(unsigned long long)`

Similar to \_\_builtin\_clz, except the argument type is
unsigned long long.

## `int ctz(unsigned int)`

Returns the number of trailing 0-bits in x, starting at the least
significant bit position.  If x is 0, the result is undefined.

## `int ctzl(unsigned long)`

Similar to \_\_builtin\_ctz, except the argument type is
unsigned long.

## `int ctzll(unsigned long long)`

Similar to \_\_builtin\_ctz, except the argument type is
unsigned long long.

## `int ffs(int)`

Returns one plus the index of the least significant 1-bit of x, or
if x is zero, returns zero.

## `int ffsl(long)`

Similar to \_\_builtin\_ffs, except the argument type is
long.

## `int ffsll(long long)`

Similar to \_\_builtin\_ffs, except the argument type is
long long.

## `double huge_val()`

Returns a positive infinity, if supported by the floating-point format,
else DBL\_MAX.  This function is suitable for implementing the
ISO C macro HUGE\_VAL.

## `float huge_valf()`

Similar to \_\_builtin\_huge\_val, except the return type is float.

## `long double huge_vall()`

Similar to \_\_builtin\_huge\_val, except the return
type is long double.

## `double inf()`

Similar to \_\_builtin\_huge\_val, except a warning is generated
if the target floating-point format does not support infinities.

## `_Decimal128 infd128()`

Similar to \_\_builtin\_inf, except the return type is \_Decimal128.

## `_Decimal32 infd32()`

Similar to \_\_builtin\_inf, except the return type is \_Decimal32.

## `_Decimal64 infd64()`

Similar to \_\_builtin\_inf, except the return type is \_Decimal64.

## `float inff()`

Similar to \_\_builtin\_inf, except the return type is float.
This function is suitable for implementing the ISO C99 macro INFINITY.

## `long double infl()`

Similar to \_\_builtin\_inf, except the return
type is long double.

## `double nan(const char)`

This is an implementation of the ISO C99 function nan.

## `float nanf(const char)`

Similar to \_\_builtin\_nan, except the return type is float.

## `long double nanl(const char)`

Similar to \_\_builtin\_nan, except the return type is long double.

## `int parity(unsigned int)`

Returns the parity of x, i.e. the number of 1-bits in x
modulo 2.

## `int parityl(unsigned long)`

Similar to \_\_builtin\_parity, except the argument type is
unsigned long.

## `int parityll(unsigned long long)`

Similar to \_\_builtin\_parity, except the argument type is
unsigned long long.

## `int popcount(unsigned int)`

Returns the number of 1-bits in x.

## `int popcountl(unsigned long)`

Similar to \_\_builtin\_popcount, except the argument type is
unsigned long.

## `int popcountll(unsigned long long)`

Similar to \_\_builtin\_popcount, except the argument type is
unsigned long long.

## `double powi(double,int)`

Returns the first argument raised to the power of the second.  Unlike the
pow function no guarantees about precision and rounding are made.

## `float powif(float,int)`

Returns the first argument raised to the power of the second.  Unlike the
pow function no guarantees about precision and rounding are made.

## `long double powil(long double,int)`

Returns the first argument raised to the power of the second.  Unlike the
pow function no guarantees about precision and rounding are made.

# UPDATING THE LIST OF FUNCTIONS

The list of functions was extracted from [https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html](https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html)
using the script `sbin/build-gcc-builtins-package.pl` This script is
part of the distribution but it is not installed in the host system.
This file is HTML documenting these functions. I found it easier to parse
this file than to parse GCC header files, mainly because the latter
contain macros and typedef which I could not parse without the help of
the C pre-processor.

And so the list of provided files may not be perfect. Certainly there are some functions
missing. Simply because some functions do not make sense when called from Perl.
For example `FUNCTION()`,
`LINE()` etc. Some others are missing because they
have exotic data types for function arguments and/or return
which I did not know how to implement that in Perl. Others
have reported missing symbols, perhaps they
need a higher C standard (adjusted via the `CFLAGS` in `Makefile.PL`).

If you need another builtin function to be supported please raise
an [issue](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=GCC-Builtins).
Please make sure you provide me with a way to include this function.
What `CFLAGS`, how to `typemap` its return type and arguments. And
also provide a test script to test it (similar to those found in `t/` directory).

# TESTING

For each exported sub there is a corresponding auto-generated
test file. The test goes as far as loading the library and
calling the function from Perl.

However, there may be errors in the expected results
because that was done without verifying with a C test program.

# BENCHMARKS

Counting leading zeros (clz) will be used to
benchmark the GCC builtin `__builtin_clz()`
and a pure Perl implementation as suggested
by Perl Monk [coldr3ality](https://perlmonks.org/?node_id=1232041)
in this [discussion](https://perlmonks.org/?node_id=11158279)

`clz()` operating on the binary representation of a number
counts the zeros starting from the most significant end until
it finds the first bit set (to 1). Which essentially gives the
zero-based index of the MSB set to 1.

The benchmarks favour the GCC builtin `__builtin_clz()`
which is about twice as fast as the pure Perl implementation.

The benchmarks can be run with `make benchmarks`
An easy way to let Perl fetch and unpack the distribution
for you is to use `cpanm` to open a shell

    cpanm --look GCC::Builtins

and then

    perl Makefile.PL && make all && make test && make benchmarks

# CAVEATS

If you observe weird return results or core-dumps it is very likely that
the fault is mine while compiling the `XS typemap`. The file in the distribution
`typemap` was compiled by me to translate C's data types into Perls.
And for some of this I am not sure what the right type is. For example,
is C's `uint_fast16_t` equivalent to Perl's `T_UV`? How about
C's `long double` mapping to Perl's `T_DOUBLE` and `unsigned long long`
to `T_U_LONG`?

Please [report](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=GCC-Builtins) any corrections.

Also note that most parts (pod of subs, list of exported subs) of
the package file, XS code (e.g. XS functions) and test files
were automatically generated
by the procedure mentioned in ["UPDATING THE LIST OF FUNCTIONS"](#updating-the-list-of-functions). It is
possible to contain mistakes.

# AUTHOR

Andreas Hadjiprocopis, `<bliako ta cpan.org / andreashad2 ta gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-gcc-builtins at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=GCC-Builtins](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=GCC-Builtins).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GCC::Builtins

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=GCC-Builtins](https://rt.cpan.org/NoAuth/Bugs.html?Dist=GCC-Builtins)

- Review this module at PerlMonks

    [https://www.perlmonks.org/?node\_id=21144](https://www.perlmonks.org/?node_id=21144)

- Search CPAN

    [https://metacpan.org/release/GCC-Builtins](https://metacpan.org/release/GCC-Builtins)

# ACKNOWLEDGEMENTS

- This module started by this discussion at PerlMonks:

    [Most Significant Set Bit](https://perlmonks.org/?node_id=11158279)

- Hackers of Free Software.
- GNU and the Free Software Foundation, providers of GNU Compiler Collection.

# HUGS

!Almaz!

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Andreas Hadjiprocopis.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
