use Test::More tests => 32;
use strict;

my $m = 'Lemonldap::NG::Common::Combination::Parser';

use_ok($m);

my $authMods = {};

foreach (qw(A B C)) {
    $authMods->{$_} = [ LLNG::Auth->new($_), LLNG::Auth->new($_) ];
}

# Verify structure
ok( ref( $m->parse( $authMods, '[A]' ) ) eq 'CODE', 'First level is a sub' );
ok( ref( $m->parse( $authMods, '[A]' )->() ) eq 'ARRAY',
    'Second level is an array ("or" list)' );
ok( ref( $m->parse( $authMods, '[A]' )->()->[0] ) eq 'ARRAY',
    'Third level is an array (auth,userDB)' );
ok( ref( $m->parse( $authMods, '[A]' )->()->[0]->[0] ) eq 'CODE',
    'Fourth level is a sub' );

my @tests = (
    '[A]',                                               'A', 'A',
    '[A,B]',                                             'A', 'B',
    'if(1) then [A,B] else [B,C]',                       'A', 'B',
    'if(0) then [A,B] else [B,C]',                       'B', 'C',
    'if(0) then [A,B] else if(1) then [B,C] else [B,A]', 'B', 'C',
    'if(0) then [A,B] else if(0) then [B,C] else [B,A]', 'B', 'A',
    'if($env->{test}) then [A,B] else [B,C]',            'A', 'B',
    'if($env->{false}) then [A,B] else [B,C]',           'B', 'C',
    '[A,B] or [B,C]',                                    'A', 'B',
    'if(1) then [A,B] or [C,A] else [B,C]',              'A', 'B',
);

while ( my $expr = shift @tests ) {
    my $auth = shift @tests;
    my $udb  = shift @tests;
    ok( authName($expr) eq $auth, qq{"$expr" returns $auth as auth module} )
      or print STDERR "Expect $auth, get " . authName($expr) . "\n";
    ok( userDBName($expr) eq $udb, qq{"$expr" returns $udb as userDB module} )
      or print STDERR "Expect $udb, get " . userDBName($expr) . "\n";
}

# Test "or"
ok(
    _call( '[A,B] or [B,C]', 'name', 0, 1 ) eq 'B',
    '"[A,B] or [B,C]" returns 2 elements'
);

ok(
    _call( 'if(1) then [A,B] or [C,A] else [B,C]', 'name', 0, 1 ) eq 'C',
    '"if(1) then [A,B] or [C,A] else [B,C]" returns 2 elements'
);

# Test "and"

@tests = (
    '[A and B, A]',
    '[A,B] and [B,C]',
    'if(0) then [A,B] else [A,B] and [B,C]'
);

while ( my $expr = shift @tests ) {
    ok( [ getok($expr) ]->[0] == 0, qq{"$expr" returns PE_OK as auth result} )
      or print STDERR "Expect 0, get " . getok($expr) . "\n";
}

# Test bad expr
@tests = ( 'if(1) then {if(1) then [A] else [B]} else [C]', '[A,B or C]', );

foreach (@tests) {
    ok( !eval { authName($_) }, qq'Bad expr "$_"' );
}

sub getok {
    my ( $expr, $ind ) = @_;
    return _call( $expr, 'ok', 0, 0 );
}

sub authName {
    my ( $expr, $ind ) = @_;
    return _call( $expr, 'name', 0, 0 );
}

sub userDBName {
    my ( $expr, $ind ) = @_;
    return _call( $expr, 'name', 1, 0 );
}

sub _call {
    my ( $expr, $name, $type, $ind ) = @_;
    $ind //= 0;
    return $m->parse( $authMods, $expr )->( { test => 1 } )->[$ind]->[$type]
      ->($name);
}

package LLNG::Auth;

sub new {
    return bless { name => $_[1] }, $_[0];
}

sub name {
    $_[0]->{name};
}

sub ok {
    return 0;    # PE_OK
}
