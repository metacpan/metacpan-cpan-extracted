use Test;
BEGIN { plan tests => 33 };
use File::Format::RIFF;
ok( 1 );


my ( $l ) = new File::Format::RIFF::List;
ok( $l->id, 'LIST' );
ok( $l->type, '    ' );
ok( $l->numChunks, 0 );
$l->type( 'abcd' );
ok( $l->type, 'abcd' );
ok( $l->size, 0 );
ok( $l->total_size, 12 );

my ( @data ) = ( $l );
push( @data, new File::Format::RIFF::Chunk( abcd => 'datadata' ) );
my ( $l2 ) = new File::Format::RIFF::List( xyzw => \@data );
ok( $l2->id, 'LIST' );
ok( $l2->type, 'xyzw' );
ok( $l2->numChunks, 2 );
ok( $l2->size, 28 );
ok( $l2->total_size, 40 );

my ( @stuff ) = $l2->data;
ok( $stuff[ 1 ]->data, 'datadata' );
ok( $l2->at( 1 )->data, 'datadata' );

my ( $c ) = $l2->addChunk( a123 => 'foo' );
ok( $c->id, 'a123' );
ok( $c->data, 'foo' );
$c->data( 'changed' );
ok( $l2->at( 2 )->data, 'changed' );

$c = new File::Format::RIFF::Chunk( asdf => 'qwerty' );
$l2->at( 0, $c );
ok( $l2->at( 0 )->id, 'asdf' );
ok( $l2->at( 0 )->data, 'qwerty' );
ok( $l2->numChunks, 3 );

$c = new File::Format::RIFF::Chunk( asdf => 'zxcv' );
my ( $l3 ) = $l2->addList( 'jkl;', [ $c ] );
ok( $l3->numChunks, 1 );
ok( $l2->numChunks, 4 );
ok( $l2->at( 3 )->type, 'jkl;' );
ok( $l2->at( 3 )->at( 0 )->data, 'zxcv' );
ok( $l2->size, 70 );
ok( $l2->total_size, 82 );

$c = $l2->pop;
ok( $c->type, 'jkl;' );
$l2->unshift( $c );
ok( $l2->at( 0 )->type, 'jkl;' );
$c = $l2->shift;
ok( $c->type, 'jkl;' );
$l2->push( $c );
ok( $l2->at( 3 )->type, 'jkl;' );

@data = ( );
push( @data, new File::Format::RIFF::Chunk( aaaa => 'a' ) );
push( @data, new File::Format::RIFF::Chunk( bbbb => 'b' ) );
push( @data, new File::Format::RIFF::Chunk( cccc => 'c' ) );
my ( @replaced ) = $l2->splice( 1, 2, @data );
ok( $replaced[ 1 ]->data, 'changed' );
ok( $l2->at( 2 )->id, 'bbbb' );
ok( $l2->at( 3 )->data, 'c' );
