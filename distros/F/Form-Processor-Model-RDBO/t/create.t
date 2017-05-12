use strict;
use Test::More tests => 2;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use Form::Artist;

my $db = NewDB->new();

$db->init();

my $form = Form::Artist->new();

ok( $form->validate( { name => 'tom' } ) );

my $item = $form->update_from_form();
$item->save();

my $artist = RDBO::Artist->new( name => 'tom' );
$artist->load( speculative => 1 );
is( $artist->not_found, 0 );

$artist->delete();
