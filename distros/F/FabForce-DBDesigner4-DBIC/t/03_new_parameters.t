#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use FabForce::DBDesigner4::DBIC;

my $file        = '/test.xml';
my $namespace   = 'MyApp::DB';
my $output_path = '/Test';

my $foo = FabForce::DBDesigner4::DBIC->new(
  input_file  => $file,
  output_path => $output_path,
  namespace   => $namespace,
);

isa_ok( $foo, 'FabForce::DBDesigner4::DBIC', 'object is type F::D::D' );
is( $foo->input_file, $file, 'input_file' );
is( $foo->output_path, $output_path, 'output_path' );
is( $foo->namespace, $namespace, 'namespace' );
