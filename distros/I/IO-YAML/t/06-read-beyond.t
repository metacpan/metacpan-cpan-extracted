use Test::More 'tests' => 8;

my $test_file = 't/read-beyond.yaml';

use_ok( 'IO::YAML' );

my $test_file_modtime = -M $test_file;

my $io = IO::YAML->new($test_file);

is( $io->mode, '<', 'default mode' );

ok( -e $test_file, "opening a file for reading shouldn't delete it" );
is( -M $test_file, $test_file_modtime, "opening a file for reading shouldn't modify it" );

$io->auto_load(1);

my (@docs, @remainder);

for (1..3) {
    ok( !$io->eof, "not eof $_" );
    my $value = <$io>;
    push @docs, $value;
}

my $fh = $io->handle;
while (<$fh>) {
    chomp;
    push @remainder, $_;
}

is_deeply( [ \@docs, \@remainder ], [ [1,2,3], [4,5,6] ], 'read past eof' );
