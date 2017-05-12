use strict;
use Test::More tests => 3;

use Rose::DB::Object::Util 'has_modified_columns';

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use Form::Artist;

my $db = NewDB->new();

$db->init();

my $form = Form::Artist->new();

ok( $form->validate( { name => 'tom' } ) );

my $artist = $form->update_from_form();
$artist->save();

$form = Form::Artist->new( $artist );
$form->validate( { name => 'tom' } );
$form->update_from_form( $artist );
is( has_modified_columns( $artist ), 0 );

$form = Form::Artist->new( $artist );
$form->validate( { name => 'to' } );
$form->update_from_form();
ok( has_modified_columns( $artist ) );
$artist->save();

$artist->delete(cascade => 1);
