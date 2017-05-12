use strict;
use warnings;

use File::Basename;
use File::Spec;
use Test::More tests => 3;
use File::MimeInfo::Simple;

my $file_tests = [
	{
		filename => 'sample.pl',
		like => qr!/x\-perl$!, # this depends on arch
	},
	{
		filename => 'plaintext.txt',
		like => qr!^text/plain$!, # this must be the same on all
	},
	{
		filename => 'image.jpg',
		like => qr!^image/jpeg$!, # same on all
	}
];

for my $test ( @{ $file_tests } ) {
	my $file = File::Spec->join(dirname(__FILE__), "files", $test->{filename});
	
	like mimetype($file), $test->{like}, "mimetype for $test->{filename}";
}

