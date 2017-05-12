use Test::More 'tests' => 7;

my @values = (1..3);
my @lines    = map { "$_\n" } (4..6);
my @expected = map { "$_\n" } (
    "--- 1",
    "--- 2",
    "--- 3",
    "...",
    "4",
    "5",
    "6",
);

# --- Clean up in case previous tests died

my $test_file = 't/sandbox/write-beyond.yaml';

unlink $test_file if -e $test_file;

use YAML::XS;

use_ok( 'IO::YAML' );

my $io = IO::YAML->new;

isa_ok( $io, 'IO::YAML' );

ok( $io->open($test_file, '>'), 'open' );
ok( -e $test_file, 'file created' );

print $io @values;
$io->terminate;
my $fh = $io->handle;
print $fh @lines;

ok( $io->close, 'close' );

my @contents = do { open(my $fh, $test_file) or die; <$fh> };

for (0..2) {

}

is_deeply( [ map { Load($_) } @contents[0..2] ], [1..3], 'written contents' );
is_deeply( [ @contents[3..6] ], [ map { "$_\n" } qw(... 4 5 6) ], 'more contents' );

# --- Clean up for later tests

unlink $test_file if -e $test_file;

