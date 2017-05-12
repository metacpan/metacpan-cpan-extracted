use Test::More;

use YAML::XS;

my $test_file = 't/read.yaml';
my @expected = YAML::XS::LoadFile($test_file);

plan 'tests' => 9 + 2 * scalar @expected;

use_ok( 'IO::YAML' );

my $test_file_modtime = -M $test_file;

my $io = IO::YAML->new($test_file);

is( $io->mode, '<', 'default mode' );

ok( -e $test_file, "opening a file for reading shouldn't delete it" );
is( -M $test_file, $test_file_modtime, "opening a file for reading shouldn't modify it" );

my $doc;

$io->auto_load(1);
for(0..$#expected) {
    $doc = <$io>;
    is_deeply( $doc, $expected[$_], "<\$io> with auto_load $_" );
}

ok( $io->seek(0, 0), 'seek to beginning' );

$io->auto_load(1);
is_deeply( [$io->getlines], \@expected, 'getlines' );

ok( $io->seek(0, 0), 'seek to beginning again' );

my @docs = <$io>;
is_deeply( \@docs, \@expected, '<$io> in list context' );

ok( $io->seek(0, 0), 'seek to beginning again' );

$io->auto_load(0);
for(0..$#expected) {
    $doc = <$io>;
    my $doccopy = $doc;
    $doccopy =~ s/\A---\s+//;
    $doccopy =~ s/\n.*//g;
    is_deeply( YAML::XS::Load($doc), $expected[$_], "<\$io> without auto_load $doccopy" );
}

