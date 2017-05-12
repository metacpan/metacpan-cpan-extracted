use strict;
use warnings;

use Test::More 'tests' => 7;

use File::Copy qw(copy);

use_ok( 'IO::YAML' );

my $test_r = 't/sandbox/read.yaml';
my $test_w = 't/sandbox/write.yaml';
my $test_a = 't/sandbox/append.yaml';

copy( 't/one.yaml', $test_r );

my $io;

ok( $io = IO::YAML->new($test_r),       'new($file)' );
isa_ok( $io, 'IO::YAML' );

ok( $io = IO::YAML->new(\*STDIN),       'new(\*STDIN)' );
isa_ok( $io, 'IO::YAML' );

ok( $io = IO::YAML->new(\*STDOUT, '>'), q{new(\*STDOUT, '>')} );
isa_ok( $io, 'IO::YAML' );


