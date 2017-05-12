use strict;
use warnings;
use Test::More;

note( 'Regression tests for CPP.pm to assure refactoring breaks nothing.' );

require Inline::CPP;

{
    no warnings 'once';  ## no critic (warnings)
    ok(defined($Inline::CPP::Parser::RecDescent::TYPEMAP_KIND), 'TYPEMAP_KIND defined.');
}

# Test Inline::CPP::register().
subtest 'Inline::CPP::register() tests.'  => sub {
    note 'Testing Inline::CPP::register()';
    plan tests => 12;
    my @ALIASES = qw/ cpp C++ c++ Cplusplus cplusplus CXX cxx /;
    my $rv;
    eval { $rv = Inline::CPP::register(); };
    ok( ! $@, 'Call to Inline::CPP::register() succeeds.' );
    diag 'Failure was: ' . $@ if $@;
    is( $rv->{language}, 'CPP', 'Language CPP properly defined.' );
    is( scalar @{$rv->{aliases}},
        scalar @ALIASES,
        'Got proper number of aliases.' );
    foreach my $alias ( @ALIASES ) {
        ok( ( grep { $_ eq $alias } @{$rv->{aliases}} ),
            "Found alias $alias."                        );
    }
    is( $rv->{type}, 'compiled', 'Proper language type.' );
    ok( defined( $rv->{suffix} ),
        'An extension suffix is defined by $Config{dlext}.' );
    return;
};


# Test const_cast().
subtest 'Inline::CPP::const_cast() tests.' => sub {
    note 'Testing Inline::CPP::const_cast()';
    plan tests => 13;
    my @tests = (
        [ 'THIS->secr(s)', '0', '', 'THIS->secr(s)' ],
        [ 'prn()', '0', '', 'prn()' ],
        [ 'THIS->dat()', '2', 'char *','const_cast<char *>(THIS->dat())' ],
        [ 'THIS->dat(a)', '2', 'char *','const_cast<char *>(THIS->dat(a))' ],
        [ 'THIS->foo(a)', '', 'int', 'THIS->foo(a)' ],
        [ 'THIS->foo(a,b)', '', 'int', 'THIS->foo(a,b)' ],
        [ 'THIS->foo(a,b,c)', '', 'int', 'THIS->foo(a,b,c)' ],
        [ 'THIS->foo2(a,b,c)', '0', 'int', 'THIS->foo2(a,b,c)' ],
        [ 'foo(a)', '', 'int', 'foo(a)' ],
        [ 'new Fizzl(Q)', '', '', 'new Fizzl(Q)' ],
        [ 'new Fizzl(Q,Fooz)', '', '', 'new Fizzl(Q,Fooz)' ],
        [ 'delete Fizzl()', '', '', 'delete Fizzl()' ],
        [ 'THIS->test()', '3', 'int', 'THIS->test()' ],
    );
    foreach my $test ( @tests ) {
        my( $value, $const, $type, $expect ) = @{$test};
        is( Inline::CPP::const_cast( $value, $const, $type ),
            $expect,
            sprintf( "%-45s => %-32s",
                "const_cast('$value','$const','$type')", $expect
            )
        );
    }
    return;
};


# Test call_or_instantiate().
subtest 'Inline::CPP::call_or_instantiate() tests.' => sub {
    note 'Testing Inline::CPP::call_or_instantiate()';
    plan tests => 14;
    my @tests = (
        #   name     ctor dtor class    const type      args
        # output
        [ [ 'secr',  0,   0,   'Foo',   0,    '',       qw( s     ) ],
          'THIS->secr(s);'                                                  ],
        [ [ 'secr',  0,   0,   'Bar',   0,    '',       qw( s     ) ],
          'THIS->secr(s);'                                                  ],
        [ [ 'prn',   0,   0,   '',      0,    '',       qw(       ) ],
          'prn();'                                                          ],
        [ [ 'dat',   0,   0,   'Foo',   2,    'char *', qw(       ) ],
          'const_cast<char *>(THIS->dat());'                                ],
        [ [ 'dat',   0,   0,   'Foo',   2,    'char *', qw( a     ) ],
          'const_cast<char *>(THIS->dat(a));'                               ],
        [ [ 'foo',   0,   0,   'Freak', '',   'int',    qw( a     ) ],
          'THIS->foo(a);'                                                   ],
        [ [ 'foo',   0,   0,   'Freak', '',   'int',    qw( a b   ) ],
          'THIS->foo(a,b);'                                                 ],
        [ [ 'foo',   0,   0,   'Freak', '',   'int',    qw( a b c ) ],
          'THIS->foo(a,b,c);'                                               ],
        [ [ 'foo2',  0,   0,   'Freak', 0,    'int',    qw( a b c ) ],
          'THIS->foo2(a,b,c);'                                              ],
        [ [ 'foo',   0,   0,   '',      '',   'int',    qw( a     ) ],
          'foo(a);'                                                         ],
        [ [ 'Fizzl', 1,   0,   'Fizzl', '',   '',       qw( Q     ) ],
          'new Fizzl(Q);'                                                   ],
        [ [ 'Fizzl', 1,   0,   'Fizzl', '',   '',       qw( Q Fooz) ],
          'new Fizzl(Q,Fooz);'                                              ],
        [ [ 'Fizzl', 0,   1,   'Fizzl', '',   '',       qw(       ) ],
          'delete Fizzl();'                                                 ], # This may exercise unused code.
        [ [ 'test',  0,   0,   'Bar',   3,    'int',    qw(       ) ],
          'THIS->test();'                                                   ],
    );
    foreach my $test ( @tests ) {
        is( Inline::CPP::call_or_instantiate( @{$test->[0]} ),
            $test->[1] . "\n",
            sprintf( "%-65s => %-33s",
                "call_or_instantiate('" . join( "','", @{$test->[0]} ) . "')",
                $test->[1]
            )
        );
    }
    return;
};


done_testing();


