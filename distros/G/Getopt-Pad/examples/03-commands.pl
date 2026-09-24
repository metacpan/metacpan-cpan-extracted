#!/usr/bin/env perl

# Nested subcommands: each level owns its options, the first bare word picks
# the command, and every level yields its own result object reachable via
# ->subcommand. The dump below shows the chain with indentation.
#
# Try:
#   perl examples/03-commands.pl document create --format pdf "My Doc"
#   perl examples/03-commands.pl image resize --width 640 --height 480
#   perl examples/03-commands.pl document create --help
#   perl examples/03-commands.pl frobnicate

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Getopt::Pad;
use ResultDump;

my $opt = GetOptions(
	options => {
		'verbose' => { type => '!', help => 'Print more information' },
	},
	commands => {
		'document' => {
			description => 'Work on documents',
			options     => {
				'path' => { type => 'file', help => 'Path to the document to process' },
			},
			commands => {
				'create' => {
					description => 'Create a new document',
					options     => {
						'format' => { type => 's', valid => [qw(pdf docx)], help => 'Target document type' },
					},
					args => [
						{ short => 'title', required => 1, help => 'Title of the new document' },
					],
				},
			},
		},
		'image' => {
			description => 'Work on images',
			options     => {
				'path' => { type => 'file', help => 'Path to the image to process' },
			},
			commands => {
				'resize' => {
					description => 'Resize an image',
					options     => {
						'width'  => { type => 'i', min => 1, help => 'Target width in pixels' },
						'height' => { type => 'i', min => 1, help => 'Target height in pixels' },
					},
				},
			},
		},
	},
	description => 'Demonstrate nested subcommands.',
);

dumpResult($opt);
