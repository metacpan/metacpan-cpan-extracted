use strict;
use warnings;
use feature 'say';
use lib 't/lib';
use Test::More;
use Test::Common qw{ EINVAL :func };
use File::Dropbox qw{ metadata deletefile };

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app, chunk => 16 * 1024);
my $path    = base();
my $file    = $path. '/'. time;
my $counter = 0;
my $conflict;

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

plan tests => 67;

package Furl;
no warnings 'redefine';

my $request = UNIVERSAL::can(__PACKAGE__, 'request');

# Request counter
*request = sub {
	++$counter;
	goto &$request;
};

package main;

sub cntr ($) { is $counter, $_[0], sprintf 'Completed %i requests', $_[0] }

# Try to open directory for writing
okay { open  $dropbox, '>', $path }                  'Path opened';
okay { say   $dropbox 'Test directory for writing' } 'Test string written';

# XXX: new behaviour of Dropbox API, file created with (conflicted copy) in name
okay { close $dropbox } 'Commited';

my $conflicted = (metadata $dropbox)->{'path'};

like $conflicted, qr{$path}, 'Path for conflicted copy matches';

cntr 2;

# Write plain file
okay { open  $dropbox, '>', $file } 'File opened for writing';
okay { print $dropbox  'A' x 1024 } '1k';
okay { print $dropbox  'B' x 1024 } '2k';
okay { print $dropbox  'C' x 1024 } '3k';
okay { print $dropbox  'D' x 1024 } '4k';
okay { close $dropbox }             'Committed';

cntr 4;

# Check file content
okay { open $dropbox, '<', $file } 'File opened for reading';

is readline $dropbox, join('', 'A' x 1024, 'B' x 1024, 'C' x 1024, 'D' x 1024),
	'Content is okay';

cntr 6;

# Rewrite file
okay { open  $dropbox, '>', $file }       'File opened for writing';
okay { printf $dropbox '%s', 'E' x 4096 } '4k';
okay { printf $dropbox '%s', 'F' x 4096 } '8k';

cntr 6;

# Check file content
okay { open $dropbox, '<', $file } 'File opened for reading';

cntr 9;

is readline $dropbox, join('', 'E' x 4096, 'F' x 4096),
	'Content is okay';

cntr 10;

# Multipart upload
okay { open $dropbox, '>', $file } 'File opened for writing';
okay { print $dropbox 'G' x 4096 } '4k';
okay { print $dropbox 'H' x 8192 } '12k';
okay { print $dropbox 'I' x 8192 } '20k';
okay { close $dropbox }            'Committed';

cntr 13;

# Check file content
okay { open $dropbox, '<', $file } 'File opened for reading';

cntr 14;

is readline $dropbox, join('', 'G' x 4096, 'H' x 8192, 'I' x 8192),
	'Content is okay';

cntr 16;

# Truncate file
okay { open $dropbox, '>', $file } 'File opened for writing';
okay { close $dropbox }            'Committed';

cntr 18;

# Check file content
okay { open $dropbox, '<', $file } 'File opened for reading';

cntr 19;

is readline $dropbox, undef, 'Content is okay';
okay { close $dropbox }      'All done';

cntr 19;

okay { deletefile $dropbox, $conflicted } 'Remove conflicted copy';
