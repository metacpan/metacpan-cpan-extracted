use Test::More;

my @values = (
    [],
    {},
    undef,
);

plan 'tests' => 6 + scalar @values;


# --- Clean up in case previous tests died

my $test_file = 't/sandbox/write.yaml';

unlink $test_file if -e $test_file;

use YAML::XS;

use_ok( 'IO::YAML' );

my $io = IO::YAML->new;

isa_ok( $io, 'IO::YAML' );

ok( $io->open($test_file, '>'), 'open' );
ok( -e $test_file, 'file created' );

foreach (@values) {
    my $result = print $io $_;
    my $dump = YAML::XS::Dump($_);
    $dump =~ s/^---\s+//;
    ok( $result, "print $dump" );
}

ok( $io->close, 'close' );

is_deeply( [YAML::XS::LoadFile($test_file)], \@values, 'write' );

# --- Clean up for later tests

unlink $test_file if -e $test_file;

