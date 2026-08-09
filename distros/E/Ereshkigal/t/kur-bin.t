#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Cwd ();
use lib 't/lib';
use EreshkigalTest qw( test_dir );

if ( $^O eq 'MSWin32' ) {
	plan skip_all => 'fork required';
}

my $dir  = test_dir();
my $root = Cwd::getcwd();
my $kur  = $^X . ' -I' . $root . '/lib ' . $root . '/src_bin/kur';

my $output = `$kur --version 2>&1`;
is( $? >> 8, 255, '--version exits 255' );
like( $output, qr/^kur v\. /, '--version prints the version' );

$output = `$kur --help 2>&1`;
is( $? >> 8, 255, '--help exits 255' );
like( $output, qr/Firewall ban manager worker/, '--help prints the POD' );

$output = `$kur 2>&1`;
isnt( $? >> 8, 0, 'no args exits nonzero' );
like( $output, qr/--name is required/, 'no args complains about the name' );

$output = `$kur --name testy 2>&1`;
isnt( $? >> 8, 0, 'no backend exits nonzero' );
like( $output, qr/--backend is required/, 'no backend complains about the backend' );

$output = `$kur --name testy --backend dummy --option nope 2>&1`;
isnt( $? >> 8, 0, 'malformed --option exits nonzero' );
like( $output, qr/not in the form key=value/, 'malformed --option error message' );

$output = `$kur --name testy --backend nosuchbackend --run $dir/run --cache $dir/cache 2>&1`;
isnt( $? >> 8, 0, 'bogus backend exits nonzero' );
like( $output, qr/Failed to init the backend/, 'bogus backend error message' );

$output = `$kur --name bad.name --backend dummy --run $dir/run --cache $dir/cache 2>&1`;
isnt( $? >> 8, 0, 'bad name exits nonzero' );
like( $output, qr/does not match/, 'bad name error message' );

done_testing;
