#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use FabForce::DBDesigner4::DBIC;
use FindBin;

my $bin         = $FindBin::Bin;
my $file        = $bin . '/test.xml';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test';

my $foo = FabForce::DBDesigner4::DBIC->new;
$foo->namespace( $namespace );
$foo->output_path( $output_path );
$foo->input_file( $file );

$foo->prefix( 'belongs_to'   => 'test1' );
$foo->prefix( 'has_many'     => 'test2' );
$foo->prefix( 'many_to_many' => 'test3' );
$foo->prefix( 'has_one'      => 'test4' );

is( $foo->prefix( 'belongs_to' ),   'test1', 'belongs_to'   );
is( $foo->prefix( 'has_many' ),     'test2', 'has_many'     );
is( $foo->prefix( 'many_to_many' ), 'test3', 'many_to_many' );
is( $foo->prefix( 'has_one' ),      'test4', 'has_one'      );
