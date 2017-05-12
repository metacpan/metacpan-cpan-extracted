use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Capture::Tiny 'capture';

use File::Spec;
use File::Temp;

use GraphViz2::Filer;

use Test::More;

# ------------------------------------------------

BEGIN{ use_ok('GraphViz2'); }

my($count)  = 1; # Counting the use_ok above.
my(%script) = GraphViz2::Filer -> new -> get_scripts;

# The EXLOCK option is for BSD-based systems.

my($temp_dir) = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);

my($stdout, $stderr, @stderr);

for my $key (sort keys %script)
{
	$count++;

	($stdout, $stderr)	= capture{system $^X, '-Ilib', $script{$key}, 'svg', File::Spec -> catfile($temp_dir, "$key.svg")};
	@stderr				= grep{! /Insecure (?:\$ENV\{PATH}|dependency)/} split(/\n/, $stderr);
	$stderr				= '' if ($#stderr < 0);

	ok(length($stderr) == 0, "$script{$key} runs without error");
}

done_testing($count);
