#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
	use_ok( 'FabForce::DBDesigner4::DBIC' );
}

my @methods = qw(
    new
    input_file
    namespace
    output_path
    create_scheme
);

can_ok( 'FabForce::DBDesigner4::DBIC', @methods );

my $foo = FabForce::DBDesigner4::DBIC->new;
isa_ok( $foo, 'FabForce::DBDesigner4::DBIC', 'object is type F::D::D' );

my $file = './test.xml';
$foo->input_file( $file );
is( $file, $foo->input_file, 'Checking input_file()' );

my $namespace = 'My::DB';
$foo->namespace( $namespace );
is( $namespace, $foo->namespace, 'Checking namespace()' );

my $output_path = '/any/path';
$foo->output_path( $output_path );
is( $output_path, $foo->output_path, 'Checking output_path()' );

my $bar = FabForce::DBDesigner4::DBIC->new(
    input_file  => $file,
    output_path => $output_path,
    namespace   => $namespace,
);

isa_ok( $bar, 'FabForce::DBDesigner4::DBIC', '$bar is type F::D::D' );
is( $file, $bar->input_file, 'Checking $bar->input_file' );
is( $output_path, $bar->output_path, 'Checking $bar->output_path' );
is( $namespace, $bar->namespace, 'Checking $bar->namespace' );
