use Test::More 'tests' => 2;

use_ok( 'IO::YAML' );

my $obj = IO::YAML->new;

isa_ok( $obj, 'IO::YAML' );

