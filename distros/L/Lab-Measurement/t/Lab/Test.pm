package Lab::Test;
use 5.010;
use warnings;
use strict;
use File::Slurper 'read_binary';
use Scalar::Util qw/looks_like_number/;
use Text::Diff 'diff';
use PDL qw/any/;
use PDL::Core 'topdl';
use parent 'Test::Builder::Module';
use MooseX::Params::Validate 'validated_list';
use Test::More import => ['is'];

our @EXPORT_OK = qw/
    file_ok
    file_filter_ok
    file_ok_crlf
    compare_ok
    is_relative_error
    is_num
    is_float
    is_absolute_error
    looks_like_number_ok
    skip_on_broken_printf
    is_pdl
    set_get_test
    scpi_set_get_test
    /;

my $class = __PACKAGE__;

=head1 NAME

Lab::Test -- Shared test routines for Lab::Measurement.

=head1 SYNOPSIS

 use Lab::Test import => [qw/file_ok compare_ok .../];

 file_ok($filename, "file contents", "contents are equal");

 file_filter_ok($filename, "line 1\nline 2\n", qr/ *$/m,
     "contents equal after removing trailing ws from each line");

 compare_ok($file1, $file2, "files have same contents");

 is_relative_error(10, 11, 0.2, "relative error of 10 and 11 is smaller than 20 percent");
 
 is_num(0.7, 0.7, "numbers are equal");
 
 is_float(1, 1.000000000000001, "floating point numbers are almost equal");
 
 is_absolute_error(10, 11, 2, "absolute error of 10 and 11 is smaller than 2");

 looks_like_number_ok("100e2", "'100e2' looks like a number");

 set_get_test(
     instr => $instr,
     getter => 'get_amplitude',
     setter => 'set_amplitude',
     cache => 'cached_amplitude',
     values => [0.1, 1, 10],
 );

 scpi_set_get_test(
     instr => $instr,
     func => 'sense_sweep_points',
     values => [1, 100, 10000],
 );


=head1 DESCRIPTION

Collection of testing routines. This module can be used together with other
L<Test::Builder>-based modules like L<Test::More>.

=cut

my $DBL_MIN = 2.2250738585072014e-308;

sub round_to_dbl_min {
    my $x = shift;
    return abs($x) < $DBL_MIN ? $DBL_MIN : $x;
}

sub relative_error {
    my $a = shift;
    my $b = shift;

    # Avoid division by zero.
    $a = round_to_dbl_min($a);
    $b = round_to_dbl_min($b);

    return abs( ( $b - $a ) / $b );
}

=head1 Functions

All functions are exported only on request. 

=head2 file_ok($file, $expected_contents, $name)

Succeed if C<$file> exists and it's contents are equal to
C<$expected_contents>. Uses binary comparison and C<$expected_contents> may not
have the unicode flag set.

=cut

sub file_ok {
    my ( $file, $expected, $name ) = @_;
    my $tb = $class->builder();
    if ( not -f $file ) {
        return $tb->ok( 0, "-f $file" )
            || $tb->diag("file '$file' does not exist");
    }
    my $contents = read_binary($file);

    if ( $tb->ok( $contents eq $expected, $name ) ) {
        return 1;
    }

    # Fail.
    my $diff = get_text_diff( $contents, $expected, $file );
    return $tb->diag($diff);
}

=head2 file_filter_ok($file, $expected_contents, $filter, $name)

Like file_ok but filter the contents of C<$file> with C<s/$filter//g> before
comparing with C<expected_contents>.

=cut

sub file_filter_ok {
    my ( $file, $expected, $filter, $name ) = @_;

    # If it was a string, make it a regex ref.
    $filter = qr/$filter/;

    my $tb = $class->builder();
    if ( not -f $file ) {
        return $tb->ok( 0, "-f $file" )
            || $tb->diag("file '$file' does not exist");
    }

    my $contents = read_binary($file);

    $contents =~ s/$filter//g;

    if ( $tb->ok( $contents eq $expected, $name ) ) {
        return 1;
    }

    # Fail.
    my $diff = get_text_diff( $contents, $expected, $file );
    return $tb->diag($diff);
}

sub get_text_diff {
    my $contents = shift;
    my $expected = shift;
    my $filename = shift;

    return diff(
        \$contents,
        \$expected,
        {
            STYLE      => 'Table',
            FILENAME_A => $filename,
            FILENAME_B => 'expected',
        }
    );
}

=head2 file_ok_crlf($file, $expected_contents, $name)

Succeed if C<$file> exists and it's contents are equal to
C<$expected_contents>. On reading the file, convert CR-LF to LF. Uses binary
comparison and C<$expected_contents> may not have the unicode flag set. 

Should be only needed to test legacy code. New code should always use binary
files, not text files (Set binmode on your handles).

=cut

sub file_ok_crlf {
    my ( $file, $expected, $name ) = @_;
    my $tb = $class->builder();
    if ( not -f $file ) {
        return $tb->ok( 0, "-f $file" )
            || $tb->diag("file '$file' does not exist");
    }

    my $contents = read_binary($file);
    $contents =~ s/\r\n/\n/g;

    if ( $tb->ok( $contents eq $expected, $name ) ) {
        return 1;
    }

    # Fail.
    my $diff = diff(
        \$contents,
        \$expected,
        {
            STYLE      => 'Table',
            FILENAME_A => $file,
            FILENAME_B => 'expected',
        }
    );

    return $tb->diag($diff);
}

=head2 compare_ok($filename1, $filename2, $name)

Succeed if both files exists and their contents are equal.

=cut

sub compare_ok {
    my ( $file1, $file2, $name ) = @_;
    my $tb = $class->builder();

    for my $file ( $file1, $file2 ) {
        if ( not -f $file ) {
            return $tb->ok( 0, "-f $file" )
                || $tb->diag("file '$file' does not exist");
        }
    }

    my $contents1 = read_binary($file1);
    my $contents2 = read_binary($file2);

    if ( $tb->ok( $contents1 eq $contents2, $name ) ) {
        return 1;
    }

    # Fail.
    my $diff = diff(
        \$contents1,
        \$contents2,
        {
            STYLE      => 'Table',
            FILENAME_A => $file1,
            FILENAME_B => $file2,
        }
    );
    return $tb->diag($diff);
}

=head2 is_relative_error($got, $expect, $error, $name)

Succeed if the relative error between C<$got> and C<$expect> is smaller or
equal than C<$error>. Relative error is defined as
C<abs(($got - $expect) / $expect)>.

If the absolute value of C<$got> or C<$expect> is smaller than DBL_MIN, that
number replaced with DBL_MIN before computing the relative error. This is done
to avoid division by zero. Two denormals will always compare equal.

=cut

sub is_relative_error {
    my ( $got, $expect, $error, $name ) = @_;
    my $tb = $class->builder;
    my $test = relative_error( $got, $expect ) <= $error;
    return $tb->ok( $test, $name )
        || $tb->diag(
        "relative error is greater than $error.\n",
        "Got: ", sprintf( "%.17g", $got ),
        "\n", "Expected: ", sprintf( "%.17g", $expect )
        );
}

=head2 is_num($got, $expect, $name)

Check for C<$got == $expect>. This is unlike C<Test::More::is>, which tests for C<$got eq $expect>.

=cut

sub is_num {
    my ( $got, $expect, $name ) = @_;
    my $tb = $class->builder;
    return $tb->ok( $got == $expect, $name )
        || $tb->diag(
        "Numbers not equal.\n",
        "Got: ", sprintf( "%.17g", $got ),
        "\n", "Expected: ", sprintf( "%.17g", $expect )
        );
}

=head2 is_float($got, $expect, $name)

Compare floating point numbers.

Equivalent to C<is_relative_error($got, $expect, 1e-14, $name)>.

C<1e-14> is about 100 times bigger than DBL_EPSILON. 
The test will succeed even if the numbers are tainted by multiple rounding
operations.  

=cut

sub is_float {
    my ( $got, $expect, $name ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_relative_error( $got, $expect, 1e-14, $name );
}

=head2 is_abs_error($got, $expect, $error, $name)

Similar to C<is_relative_error>, but uses the absolute error.

=cut

sub is_absolute_error {
    my ( $got, $expect, $error, $name ) = @_;
    my $tb   = $class->builder;
    my $test = abs( $got - $expect ) <= $error;
    return $tb->ok( $test, $name )
        || $tb->diag(
        "absolute error of $got and $expect is greater than $error");
}

=head2 looks_like_number_ok($number, $name)

Checks if Scalar::Util's C<looks_like_number> returns true for C<$number>.

=cut

sub looks_like_number_ok {
    my ( $number, $name ) = @_;
    my $tb = $class->builder;
    return $tb->ok( looks_like_number($number), $name )
        || $tb->diag("'$number' does not look like a number");
}

=head2 skip_on_broken_printf

For formatting of floating point numbers perl's printf function relies on the
system's printf.

On some platforms, most notably MS-W32, it is not compatible with C99.
E.g. you get 1.000000e+001 instead of 1.000000e+01.

This routine skips the test, if a broken printf is detected.

=cut

sub skip_on_broken_printf {
    my $tb = $class->builder();
    if ( printf_is_broken() ) {
        $tb->plan( skip_all => 'System does not have C99 compatible printf' );
    }
}

sub printf_is_broken {
    my $tb         = $class->builder();
    my @test_pairs = (
        [qw/1 1.000000e+00/],
        [qw/10 1.000000e+01/],
        [qw/1e100 1.000000e+100/]
    );
    for my $test (@test_pairs) {
        my $string = sprintf( "%e", $test->[0] );
        if ( $string ne $test->[1] ) {
            $tb->diag( "got: $string, expected: " . $test->[1] );
            return 1;
        }
    }
    return;
}

sub is_pdl {
    my ( $got, $expect, $name ) = @_;
    my $tb = $class->builder();

    $got    = topdl($got);
    $expect = topdl($expect);

    my $got_shape    = $got->shape();
    my $expect_shape = $expect->shape();

    if ( $got_shape->nelem() != $expect_shape->nelem()
        || any( $got_shape != $expect_shape ) ) {
        return $tb->ok( 0, "shapes equal" )
            || $tb->diag("pdl shapes unequal: $got_shape, $expect_shape");
    }

    $tb->ok( all( $got == $expect ), $name )
        || $tb->diag(
        "pdls are not equal:\n" . "got: $got\n" . "expected: $expect" );
}

=head2 set_get_test

 set_get_test(
     instr => $instr,
     getter => 'get_amplitude',
     setter => 'set_amplitude',
     cache => 'cached_amplitude', # optional
     values => [0.1, 1, 10],
     is_numeric => 1, # this is default
 );
 
Try the C<setter>, C<getter> and C<cache> for each value in C<values>. Check
that the C<getter> and C<cache> methods return the correct value.
For non-numeric string values, set C<is_numeric> to 0.

=cut

sub set_get_test {
    my $tb = $class->builder();

    # Report all errors in context of calling test script.
    local $Test::Builder::Level = $Test::Builder::Level + 4;

    $tb->subtest( 'test setter and getter', \&set_get_test_sub, @_ );
}

sub set_get_test_sub {
    my ( $instr, $getter, $setter, $cache, $is_numeric, $values )
        = validated_list(
        \@_,
        instr      => { isa => 'Object' },
        getter     => { isa => 'Str' },
        setter     => { isa => 'Str' },
        cache      => { isa => 'Str', optional => 1 },
        is_numeric => { isa => 'Bool', default => 1 },
        values     => { isa => 'ArrayRef[Str]' },
        );

    # Report all errors in context of calling test script.
    local $Test::Builder::Level = $Test::Builder::Level + 6;

    my $test_func = $is_numeric ? \&is_float : \&is;

    for my $value ( @{$values} ) {
        $instr->$setter( value => $value );

        if ( defined $cache ) {
            $test_func->( $instr->$cache(), $value, "$cache returns $value" );
        }
        $test_func->( $instr->$getter(), $value, "$getter returns $value" );
    }
}

=head2 scpi_set_get_test

 scpi_set_get_test(
     instr => $instr,
     func => 'sense_sweep_points',
     values => [1, 100, 10000],
     is_numeric => 1, # this is default
 );

Like C<set_get_test>, but assume that the getter, setter and cache are called
C<"${func}_query">, C<$func> and C<"cached_$func"> respectively.

=cut

sub scpi_set_get_test {
    my ( $instr, $func, $is_numeric, $values ) = validated_list(
        \@_,
        instr      => { isa => 'Object' },
        func       => { isa => 'Str' },
        is_numeric => { isa => 'Bool', default => 1 },
        values     => { isa => 'ArrayRef[Str]' },
    );

    set_get_test(
        instr      => $instr,
        getter     => "${func}_query",
        setter     => $func,
        cache      => "cached_$func",
        is_numeric => $is_numeric,
        values     => $values,
    );

}

1;

