use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Lchmod');
}

diag("Testing Lchmod $Lchmod::VERSION");

ok( defined &lchmod,            'lchmod() exported by default' );
ok( !defined &LCHMOD_AVAILABLE, 'LCHMOD_AVAILABLE() not exported by default' );

if ( !Lchmod::LCHMOD_AVAILABLE ) {
    ok( 1, 'LCHMOD_AVAILABLE() is false when it can not be loaded' );
    done_testing;
    exit;
}

ok( Lchmod::LCHMOD_AVAILABLE, 'LCHMOD_AVAILABLE() is true when it can be loaded' );

{
    no warnings 'redefine';
    local *Lchmod::LCHMOD_AVAILABLE = sub { return };
    local $!;
    is( lchmod(), undef, 'lchmod() returns undef when !LCHMOD_AVAILABLE()' );
    ok( defined $!, 'lchmod() sets $! when !LCHMOD_AVAILABLE()' )
}

our $export;

package Test::A;

use Lchmod ();
$main::export->{none} = !defined &lchmod && !defined &LCHMOD_AVAILABLE ? 1 : 0;

package Test::B;

use Lchmod qw(lchmod);
$main::export->{lchmod} = defined &lchmod && !defined &LCHMOD_AVAILABLE ? 1 : 0;

package Test::C;

use Lchmod qw(LCHMOD_AVAILABLE);
$main::export->{LCHMOD_AVAILABLE} = !defined &lchmod && defined &LCHMOD_AVAILABLE ? 1 : 0;

package Test::D;

use Lchmod qw(lchmod LCHMOD_AVAILABLE);
$main::export->{both} = defined &lchmod && defined &LCHMOD_AVAILABLE ? 1 : 0;

package main;

ok( $export->{none},             'import none == none exported' );
ok( $export->{both},             'import both == both exported' );
ok( $export->{lchmod},           'import lchmod == lchmod exported' );
ok( $export->{LCHMOD_AVAILABLE}, 'import LCHMOD_AVAILABLE == LCHMOD_AVAILABLE exported' );

done_testing;
