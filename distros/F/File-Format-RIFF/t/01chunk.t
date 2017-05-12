use Test;
BEGIN { plan tests => 11 };
use File::Format::RIFF;
ok( 1 );


my ( $c ) = new File::Format::RIFF::Chunk;
ok( $c->id, '    ' );
ok( $c->data, '' );
$c->id( 'abcd' );
ok( $c->id, 'abcd' );
$c->data( 'xyz1234' );
ok( $c->data, 'xyz1234' );
ok( $c->size, 7 );
ok( $c->total_size, 16 );

$c = new File::Format::RIFF::Chunk( id12 => 'datadatadata' );
ok( $c->id, 'id12' );
ok( $c->data, 'datadatadata' );
ok( $c->size, 12 );
ok( $c->total_size, 20 );
