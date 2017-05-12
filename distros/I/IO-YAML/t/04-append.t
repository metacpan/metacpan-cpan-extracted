use Test::More 'tests' => 8;

use YAML::XS;
use File::Copy qw(copy);

use_ok( 'IO::YAML' );

my $test_file = 't/sandbox/append.yaml';

copy('t/append.yaml', $test_file) or die "Copy failed: $!";

my $test_file_modtime = -M $test_file;

my $io = IO::YAML->new;

isa_ok( $io, 'IO::YAML' );

ok( $io->open($test_file, '>>'), 'open' );

ok( -e $test_file, "open for append shouldn't delete an existing file" );
is( -M $test_file, $test_file_modtime, "open for append shouldn't modify an existing file" );

my @values = YAML::XS::LoadFile($test_file);

my @more_values = YAML::XS::LoadFile('t/read.yaml');

ok( $io->print(@more_values), 'append more values' );

ok( $io->close, 'close after append' );

is_deeply( [ YAML::XS::LoadFile($test_file) ], [ @values, @more_values ], 'resulting contents' );

unlink $test_file;

