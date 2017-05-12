use Test::More tests => 12;

BEGIN { use_ok('Lazy::Bool') }

subtest "test package" => sub {
    plan tests => 2;

    require_ok('Lazy::Bool');
    new_ok( 'Lazy::Bool' => [ sub { } ] );
};

subtest "test lzb helper" => sub {
    plan tests => 4;

    ok( !__PACKAGE__->can('lzb'), 'module should not export lzb() by default' );

    isa_ok( Lazy::Bool::lzb { 1 }, 'Lazy::Bool' );

    ok( Lazy::Bool::lzb { pass("should be called"); 1 }, 'should be true' );
};

subtest "should be lazy" => sub {
    plan tests => 1;

    Lazy::Bool->new(
        sub {
            fail("should not be called");
        }
    );

    my $x = !Lazy::Bool->new(
        sub {
            fail("should not be called");
        }
    );

    if (
        Lazy::Bool->new(
            sub {
                pass("should be called");
            }
        )
      )
    {
    }
};

subtest "should act as a boolean" => sub {
    plan tests => 6;

    ok( Lazy::Bool->new( sub { 1 } ), "should be true using sub" );
    ok( Lazy::Bool->new(1), "should be true using literal" );
    ok( Lazy::Bool->true,   "should be true using helper" );

    ok( !Lazy::Bool->new( sub { 0 } ), "should be false using sub" );
    ok( !Lazy::Bool->new(0), "should be false using literal" );
    ok( !Lazy::Bool->false,  "should be false using helper" );
};

subtest "should be lazy in and/or operations" => sub {
    plan tests => 1;

    my $a = Lazy::Bool->new( sub { fail("should not be called") } );
    my $b = Lazy::Bool->new( sub { fail("should not be called") } );

    my $c = $a & $b;    # operations using lazy - lazy
    my $d = $a | $b;

    my $e = $a & 1;     # operations using lazy - literal
    my $f = $a | 0;

    pass("ok");
};

subtest "should act as a boolean in and/or operations" => sub {
    plan tests => 10;
    my $true  = Lazy::Bool->new( sub { 1 } );
    my $false = Lazy::Bool->new( sub { 0 } );

    ok( $true & $true,        "test -> true  & true" );
    ok( !( $false & $true ),  "test -> false & true" );
    ok( !( $true & $false ),  "test -> true  & false" );
    ok( !( $false & $false ), "test -> false & false" );

    ok( $true | $true,        "test -> true  | true" );
    ok( $false | $true,       "test -> false | true" );
    ok( $true | $false,       "test -> true  | false" );
    ok( !( $false | $false ), "test -> false | false" );

    my $a = Lazy::Bool->new( sub { 1 } );
    $a |= Lazy::Bool->new( sub { 0 } );

    ok( $a, "test -> a |= false" );

    my $b = Lazy::Bool->new( sub { 1 } );
    $b &= Lazy::Bool->new( sub { 0 } );

    ok( !$b, "test -> b &= false" );
};

subtest "should act as a boolean in and/or operations with non-lazy values" =>
  sub {
    plan tests => 16;
    my $true  = Lazy::Bool->new( sub { 1 } );
    my $false = Lazy::Bool->new( sub { 0 } );

    ok( $true & 1,       "test -> true  & 1" );
    ok( !( $false & 1 ), "test -> false & 1" );
    ok( !( $true & 0 ),  "test -> true  & 0" );
    ok( !( $false & 0 ), "test -> false & 0" );

    ok( $true | 1,       "test -> true  | 1" );
    ok( $false | 1,      "test -> false | 1" );
    ok( $true | 0,       "test -> true  | 0" );
    ok( !( $false | 0 ), "test -> false | 0" );

    my $a = Lazy::Bool->new( sub { 1 } );
    $a |= 0;

    ok( $a, "test -> a=true; a |= 0" );
    isa_ok( $a, 'Lazy::Bool' );

    my $b = Lazy::Bool->new( sub { 1 } );

    $b &= 0;

    ok( !$b, "test -> b=true; b &= 0" );
    isa_ok( $b, 'Lazy::Bool' );

    my $c = 1;

    $c |= Lazy::Bool->new( sub { 0 } );

    ok( $c, "test -> c=1; c |= false" );
    isa_ok( $c, 'Lazy::Bool' );

    my $d = 0;

    $d &= Lazy::Bool->new( sub { 0 } );

    ok( !$d, "test -> d=0; d |= false" );
    isa_ok( $d, 'Lazy::Bool' );
  };

subtest "complex test lazy" => sub {
    plan tests => 1;
    my $true  = Lazy::Bool->new( sub { fail("should be lazy") } );
    my $false = Lazy::Bool->new( sub { fail("should be lazy") } );

    my $result1 = ( $true | $false ) & ( !( $false & !$false ) );
    my $result2 = !!$true;
    my $result3 = !!!$false;
    pass("ok");
};

subtest "complex test" => sub {
    plan tests => 3;
    my $true = Lazy::Bool->new( sub { 6 > 4 } );
    my $false = Lazy::Bool->false;

    my $result = ( $true | $false ) & ( !( $false & !$false ) );

    ok( $result,   "complex expression should be true" );
    ok( !!$true,   "double negation of true value should be true" );
    ok( !!!$false, "truple negation of false value should be true" );
};

subtest "should not be short-circuit" => sub {
    plan tests => 2;

    ok(
        Lazy::Bool->true | Lazy::Bool->new(
            sub {
                fail("should not be call");
                1;
            }
        ),
        "expression should be true"
    );
    ok(
        !(
            Lazy::Bool->false & Lazy::Bool->new(
                sub {
                    fail("should not be call");
                    1;
                }
            )
        ),
        "expression should be true"
    );
};

subtest "test NOT caching" => sub {
    plan tests => 1;
    my $i = 0;
    my $x = Lazy::Bool->new(
        sub {
            $i++;
        }
    );

    if ($x) { }
    if ($x) { }

    is( $i, 2, "should call twice" );
  }
