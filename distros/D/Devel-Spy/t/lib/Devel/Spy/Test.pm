package NSA;

sub new {
    my $class = shift @_;
    return bless {}, $class;
}

sub phone {
    return 'Hello from the NSA!';
}

BEGIN { $INC{'NSA.pm'} = __FILE__ }

package Devel::Spy::Test;
use strict;
use warnings;
use Test::Class;
BEGIN { our @ISA = 'Test::Class' }
use Test::More;

use Devel::Spy;

{
    package XXX::Test;
    sub TIEHANDLE { bless [], shift }
    sub PRINT { push @{$_[0]}, @_[ 1 .. $#_ ] }
    sub DESTROY {}
    sub contents { join '', @{$_[0]} }
}

sub tattler :Test(1) {
    my $logger = Devel::Spy->make_tattler;
    my $logged = tie *STDOUT, 'XXX::Test';

    local $SIG{__DIE__} = sub { $DB::signal = 1 };
    my @inner;
    my $outer = Devel::Spy->new( \ @inner, $logger );
    $outer->[52] = 'Go go Pony';

    my $contents = $logged->contents;

    like( $contents, qr/Go go Pony/, '->make_tattler logs to STDOUT' );
}

sub hash_value : Test(8) {
    my @log;
    my $logger;
    $logger = sub { push @log, "@_"; return $logger };

    my %inside;
    my %outside;
    my $obj = tie %outside, 'Devel::Spy::TieHash', \%inside, $logger;
    isa_ok( $obj, 'Devel::Spy::TieHash', 'tie' );

    is( $obj->[Devel::Spy::TieHash::PAYLOAD],
         \%inside, 'Found wrapped variable inside wrapper' );
    
    is( "@log", '', 'Log is empty' );
    
    is( keys %inside, 0, 'Storage is initially unchanged' );

    $outside{foo} = 42;
    is( $inside{foo}, 42, 'Wrapped hash got assignment' );
    like( "@log", qr/^->{foo} = 42/m, 'Log reflects the STORE' );

    is( $outside{foo}, 42, 'Wrapper reflects the assignment' );
    like( "@log", qr/->{foo} -> 42/m, 'Log reflects the fetch' );

    # Clean up circular reference
    undef $logger;
}

# sub hash_undef : Test(2) {
#     my ( undef, $logger ) = Devel::Spy->make_eventlog;
#
#     my $x = Devel::Spy->new( {}, $logger );
#     warning_like { my $y = $x->{ undef() } } qr/uninitialized/;
#     warning_like { $x->{ undef() } = 42 } qr/uninitialized/;
# }

sub scalar_value : Test(8) {
    my @log;
    local $" = "\n";

    my $logger;
    $logger = sub { push @log, "@_"; return $logger };

    my $inside;
    my $outside;
    my $obj = tie $outside, 'Devel::Spy::TieScalar', \ $inside, $logger;
    isa_ok( $obj, 'Devel::Spy::TieScalar', 'tie' );

    is( $obj->[Devel::Spy::TieScalar::PAYLOAD],
        \$inside, 'Found wrapped variable inside wrapper' );

    is( "@log", '', 'Log is empty' );

    is( $inside, undef, 'Storage is initially unchanged' );

    $outside = 42;
    is( $inside, 42, 'Stored 42 ok' );
    like( "@log", qr/^= 42/m, 'Log reflects the STORE' );

    is( $outside, 42, 'Fetched 42 ok' );
    like( "@log", qr/^-> 42/m, 'Log reflects the fetch' );
}

sub obj_overload : Test(6) {
    my $value = 42;

    my $logger = Devel::Spy->make_null_eventlog;
    my $obj = Devel::Spy->new( $value, $logger );
    ok( overload::Overloaded($obj),
        overload::StrVal($obj) . ' is overloaded' );

    ok( overload::Method( $obj, $_ ), "$_ operator is overloaded" )
        for split ' ', $overload::ops{dereferencing};
}

sub obj_tied_hash : Test(6) {
    my %guts;;
    my $logger = Devel::Spy->make_null_eventlog;
    my $obj  = Devel::Spy->new( \ %guts, $logger );


    my $thing;
    {
        # "Come from" inside Devel::Spy::_obj so the code knows to not be a proxy but actually do the right thing
        package Devel::Spy::_obj;
        $thing = $obj->[Devel::Spy::UNTIED_PAYLOAD];
    }

    ok( !overload::Method( $thing, '%{}' ), q[Payload isn't overloaded] );
    ok( overload::Method( $obj, '%{}' ), q[Wrapper overloads %{}] );

    # These tests will fail with pseudo-hash errors if $thing isn't
    # properly blessed.
TODO: {
        local $TODO = q['' is returned instead];
        my $result = $obj->{foo};
        ok( ! defined $result, q[Uninitialized hash entries are undef] );
    }

    $obj->{foo} = 42;
    is( $obj->{foo}, 42, q[Values can be stored and retrieved] );
}

sub obj_method : Test(1) {
    my ( $log, $logger ) = Devel::Spy->make_eventlog;

    # Snoop on the NSA.
    my $nsa = Devel::Spy->new( NSA->new, $logger );

    my $bitbucket = !!$nsa->phone;

    like(
        "@$log",
        qr/
            ^
            \ \$->phone\(\)\ ->Hello\ from\ the\ NSA!\ ->\(!Hello\ from\ the\ NSA!\)\ ->\ ->\(!\)\ ->1
        /mx
    );
}

1;
