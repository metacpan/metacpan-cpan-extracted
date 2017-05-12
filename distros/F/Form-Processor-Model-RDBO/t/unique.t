use strict;
use Test::More tests => 3;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use Form::Artist;

my $db = NewDB->new();

$db->init();

my $form = Form::Artist->new();

ok( $form->validate( { name => 'haha' } ) );

my $u = RDBO::Artist->new( name => 'haha' );
$u->save();

$form->clear;
ok( !$form->validate( { name => 'haha' } ) );

$form->clear;
$form = Form::Artist->new( $u );
ok( $form->validate( { name => 'haha' } ) );

$u->delete();
