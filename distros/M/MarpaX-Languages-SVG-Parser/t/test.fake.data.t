use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Basename; # For basename().
use File::Slurper 'read_dir';
use File::Spec;

use Test::More;

# ------------------------------------------------

my($count) = 0;

my($attribute);
my($in_file_name);
my($result);

for my $file_name (sort grep{/dat$/} read_dir('data') )
{
	$attribute		= basename($file_name);
	$attribute		=~ s/^(\w+)(\..+)$/$1/;
	$in_file_name	= File::Spec -> catfile('data', $file_name);

	# Could use Try::Tiny, but at home I want to see it die if it fails.

	(undef, undef, $result) = capture{system($^X, '-Ilib', 'scripts/test.file.pl', '-a', $attribute, '-i', $in_file_name)};

	ok($result == 0, "Processed $file_name");
	$count++;
}

print "# Internal test count: $count. \n";

done_testing;
