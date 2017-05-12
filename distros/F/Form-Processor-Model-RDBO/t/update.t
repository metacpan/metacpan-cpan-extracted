use strict;
use Test::More tests => 2;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use Form::Artist;

my $db = NewDB->new();

$db->init();

my $u = RDBO::Artist->new( name => 'foo' );
$u->save();

my $form = Form::Artist->new( $u );
ok( $form->validate( { name => 'bar' } ) );

diag $form->field('name')->errors;

$form->update_from_form();

is( $u->name, 'bar' );

$u->delete();
