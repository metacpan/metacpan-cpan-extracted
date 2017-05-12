#!perl -T

use Test::More tests => 26;

BEGIN {
    use_ok( 'Devel::TypeCheck' );
    use_ok( 'B::TypeCheck' );

    for my $helper ( qw( Environment Glob2type Pad2type Sym2type Type Util ) ) {
        use_ok( "Devel::TypeCheck::$helper" );
    }

    for my $type ( qw( Chi Dv Eta Io Iv Kappa Mu Nu Omicron Pv Rho TRef TSub TTerm TVar Upsilon Zeta Var ) ) {
        use_ok( "Devel::TypeCheck::Type::$type" );
    }
}

diag( "Testing Devel::TypeCheck $Devel::TypeCheck::VERSION, Perl $], $^X" );
