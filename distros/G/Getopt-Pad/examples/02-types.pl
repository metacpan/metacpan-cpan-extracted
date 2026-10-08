#!/usr/bin/env perl

# One option per built-in type, showing what each reader returns:
#   flag (the default), bool (negatable), counter, string,
#   int (with min/max), float, file and dir (with mustExist), url.
# Not shown: date and duration, which need DateTime::Format::Natural;
# see 09-dates.pl.
# Most types also have other names, e.g. 's' for string, 'i' for int,
# '!' for bool and '+' for counter; see "TYPES" in the Getopt::Pad docs.
#
# Try:
#   perl examples/02-types.pl --dry-run --no-color -vvv --name demo --width 640 \
#     --ratio 1.5 --identity examples/02-types.pl --work-dir examples \
#     --source ssh://git@example.com/project.git
#   perl examples/02-types.pl --width 9999    (fails: above max)

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Getopt::Pad;
use ResultDump;

my $opt = GetOptions(
	options => {
		'dry-run'  => { help => 'flag: plain switch, not negatable' },
		'color'    => { type => 'bool', default => 1, help => 'bool: --color / --no-color' },
		'verbose|v' => { type => 'counter', help => 'counter: -v -v -v or -vvv' },
		'name'     => { type => 'string', help => 'string' },
		'width'    => { type => 'int', min => 1, max => 4096, help => 'int with min/max' },
		'ratio'    => { type => 'float', help => 'float' },
		'identity' => { type => 'file', mustExist => 1, help => 'file that has to exist' },
		'work-dir' => { type => 'dir', mustExist => 1, help => 'directory that has to exist' },
		'source'   => { type => 'url', help => 'URL of the form scheme://... (ssh://, https://, ...)' },
	},
	description => 'Demonstrate the built-in option types.',
);

dumpResult($opt);

say "\n# now try an invalid value, e.g.:  perl $0 --width 9999";
