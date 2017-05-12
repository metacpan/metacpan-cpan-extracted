# Exception::Class::TryCatch
use strict;

use Test::More tests => 45;

use Exception::Class::TryCatch qw( try catch caught );
use Exception::Class 'My::Exception::Class', 'My::Other::Exception';

package My::Exception::Class;
# check for bug when some Exception class stringifies to empty string
use overload
  q{""}    => sub { return '' },
  fallback => 1;

package main;

my $e;

#--------------------------------------------------------------------------#
# Test basic catching of Exception::Class thrown errors
#--------------------------------------------------------------------------#

eval { My::Exception::Class->throw('error1') };
$e = catch;
ok( $e, "Caught My::Exception::Class error1" );
isa_ok( $e, 'Exception::Class::Base' );
isa_ok( $e, 'My::Exception::Class' );
is( $e->error, 'error1', "Exception is 'error1'" );

eval { My::Exception::Class->throw('error2'); };
$e = catch;
ok( $e, "Caught My::Exception::Class error2" );
isa_ok( $e, 'My::Exception::Class' );
is( $e->error, 'error2', "Exception is 'error2'" );

#--------------------------------------------------------------------------#
# Test handling of normal die (not Exception::Class throw() )
#--------------------------------------------------------------------------#

eval { die "error3" };
$e = catch;
ok( $e, "Caught 'die error3'" );
isa_ok( $e, 'Exception::Class::Base' );
like( $e->error, qr/^error3 at/, "Exception is 'error3 at...'" );

eval { die 0 };
$e = catch;
ok( $e, "Caught 'die 0'" );
isa_ok( $e, 'Exception::Class::Base' );
like( $e->error, qr/^0 at/, "Exception is '0 at...'" );

eval { die };
$e = catch;
ok( $e, "Caught 'die'" );
isa_ok( $e, 'Exception::Class::Base' );
like( $e->error, qr/^Died at/, "Exception is 'Died at...'" );

#--------------------------------------------------------------------------#
# Test handling of non-dying evals
#--------------------------------------------------------------------------#

eval { 1 };
$e = catch;
is( $e, undef, "Didn't catch eval of 1" );

eval { 0 };
$e = catch;
is( $e, undef, "Didn't catch eval of 0" );

#--------------------------------------------------------------------------#
# Test catch (my e) syntax-- pass by reference
#--------------------------------------------------------------------------#

eval { My::Exception::Class->throw('error'); };
catch my $err;
is( $err->error, 'error', "catch X syntax worked" );

#--------------------------------------------------------------------------#
# Test caught synonym
#--------------------------------------------------------------------------#

undef $err;
eval { My::Exception::Class->throw("error") };
caught $err;
is( $err->error, 'error', "caught synonym worked" );

#--------------------------------------------------------------------------#
# Test catch setting error variable to undef if no error
#--------------------------------------------------------------------------#

eval { My::Exception::Class->throw("error") };
catch $err;
eval { 1 };
catch $err;
is( $err, undef, "catch undefs a passed error variable if no error" );

#--------------------------------------------------------------------------#
# Test try passing through results of eval
#--------------------------------------------------------------------------#

my $test_val = 23;
my @test_vals = ( 1, 2, 3 );

my $rv = try eval { return $test_val };
is( $rv, $test_val, "try in scalar context passes through result of eval" );

$rv = try eval { return \@test_vals };
is( $rv, \@test_vals, "try in scalar context passes an array ref as is" );

my @rv = try [ eval { return @test_vals } ];
is_deeply( \@rv, \@test_vals,
    "try in list context dereferences an array ref passed to it" );

@rv = try eval { return $test_val };
is_deeply( \@rv, [$test_val], "try in list context passes through a scalar return" );

#--------------------------------------------------------------------------#
# Test simple try/catch
#--------------------------------------------------------------------------#

$rv = try eval { My::Exception::Class->throw("error") };
catch $err;
is( $rv,         undef,   "try gets undef on exception" );
is( $err->error, 'error', "simple try/catch works" );

#--------------------------------------------------------------------------#
# Test try/catch to array
#--------------------------------------------------------------------------#

$rv = try eval { My::Exception::Class->throw("error") };
my @err = catch;
is( scalar @err,    1,       '@array = catch' );
is( $err[0]->error, 'error', 'array catch works' );

#--------------------------------------------------------------------------#
# Test try/catch to array -- no error
#--------------------------------------------------------------------------#

$rv = try eval { 42 };
@err = catch;
is( scalar @err, 0, 'array catch with no error returns empty array' );

#--------------------------------------------------------------------------#
# Test multiple try/catch with double error
#--------------------------------------------------------------------------#

my $inner_err;
my $outer_err;

for my $out ( 0, 1 ) {
    for my $in ( 0, 1 ) {
        try eval { $out ? My::Exception::Class->throw("outer") : 1 };
        try eval { $in  ? My::Exception::Class->throw("inner") : 1 };
        catch $inner_err;
        catch $outer_err;
        if ($in) {
            is( $inner_err->error, "inner", "Inner try caught correctly in case ($out,$in)" );
        }
        else {
            is( $inner_err, undef, "Inner try caught correctly in case ($out,$in)" );
        }
        if ($out) {
            is( $outer_err->error, "outer", "Outer try caught correctly in case ($out,$in)" );
        }
        else {
            is( $outer_err, undef, "Outer try caught correctly in case ($out,$in)" );
        }
    }
}

#--------------------------------------------------------------------------#
# Test catch rethrowing unless a list is matched -- one argument version
#--------------------------------------------------------------------------#

{

    try eval {
        try eval { My::Exception::Class->throw("error") };
        $err = catch( ['My::Other::Exception'] );
        diag(   "Shouldn't be here because \$err is a "
              . ref($err)
              . " not a My::Other::Exception." );
    };

    catch $outer_err;
}
ok(
    UNIVERSAL::isa( $outer_err, 'My::Exception::Class' ),
    "catch not matching list should rethrow -- single arg version"
);

eval {
    eval { My::Exception::Class->throw("error") };
    $err = catch( ['My::Exception::Class'] );
};
is( $@, q{}, "catch matching list lives -- single arg version" );

eval { 1 };
$e = catch ['My::Exception::Class'];
is( $e, undef, "catch returns undef if no error -- single arg version" );

#--------------------------------------------------------------------------#
# Test catch rethrowing unless a list is matched -- two argument version
#--------------------------------------------------------------------------#

{

    try eval {
        try eval { My::Exception::Class->throw("error") };
        catch( $err, ['My::Other::Exception'] );
        diag( "Shouldn't be here unless " . ref($err) . " is a My::Other::Exception." );
    };

    catch $outer_err;
}
ok(
    UNIVERSAL::isa( $outer_err, 'My::Exception::Class' ),
    "catch not matching list should rethrow -- two arg version"
);

eval {
    eval { My::Exception::Class->throw("error") };
    catch( $err, ['My::Exception::Class'] );
};
is( $@, q{}, "catch matching list lives -- two arg version" );

eval { 1 };
$e = catch $err, ['My::Exception::Class'];
is( $e, undef, "catch returns undef if no error -- two arg version" );
is( $err, undef,
    "catch undefs a passed error variable if no error -- two arg version" );

