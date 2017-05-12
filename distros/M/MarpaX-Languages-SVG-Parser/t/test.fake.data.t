use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Basename; # For basename().
use File::Slurp;    # For read_dir().

use Test::More;

# ------------------------------------------------

my($count) = 0;

my($attribute);
my($result);

for my $file (sort grep{/dat$/} read_dir('data', {prefix => 1}) )
{
	$attribute = basename($file);
	$attribute =~ s/^(\w+)(\..+)$/$1/;

	# Could use Try::Tiny, but at home I want to see it die if it fails.

	(undef, undef, $result) = capture{system($^X, '-Ilib', 'scripts/test.file.pl', '-a', $attribute, '-i', $file)};

	ok($result == 0, "Processed $file");
	$count++;
}

print "# Internal test count: $count. \n";

done_testing;
