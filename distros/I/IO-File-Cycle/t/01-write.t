#!perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'IO::File::Cycle' ) || print "Bail out!\n";
}

my $file = IO::File::Cycle->new('>/tmp/foo.txt');
for ( 1..10_000 ) {
	$file->cycle if tell($file) + length($_) + 1 > 10_000;
	print $file $_, "\n";
}
$file->close;

is( -s '/tmp/foo.1.txt', 9998, 'foo.1.txt is 9998 chars in size' );

unlink glob '/tmp/foo.*.txt';