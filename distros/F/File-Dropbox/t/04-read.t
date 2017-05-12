use strict;
use warnings;
use feature 'say';
use lib 't/lib';
use Test::More;
use Test::Common qw{ EINVAL :func :fcntl };
use File::Dropbox;

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app, chunk => 4096);
my $path    = base();
my $file    = $path. '/'. time;
my $data;

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

plan tests => 78;

# Write plain file
okay { open  $dropbox, '>', $file } 'File opened for writing';
okay { print $dropbox  'A' x 1024 } '1k';
okay { print $dropbox  'B' x 1024 } '2k';
okay { print $dropbox  'C' x 1024 } '3k';
okay { print $dropbox  'D' x 1024 } '4k';
okay { print $dropbox  'E' x 1024 } '5k';
okay { print $dropbox  'F' x 1024 } '6k';
okay { close $dropbox }             'Committed';

# Seek test
okay { open  $dropbox, '<', $file }     'File opened for reading';
okay { seek  $dropbox, 1024, SEEK_SET } 'Seek absolute';
okay { read  $dropbox, $data, 2048 }    'Read 2k from file';

is $data, join('', 'B' x 1024, 'C' x 1024),
	'Content is okay';

okay { read  $dropbox, $data, 2048 } 'Read 2k from file';

is $data, join('', 'D' x 1024, 'E' x 1024),
	'Content is okay';

okay { seek  $dropbox, -512, SEEK_CUR } 'Seek relative';
okay { read  $dropbox, $data, 1024 }    'Read 1k from file';

is $data, join('', 'E' x 512, 'F' x 512),
	'Content is okay';

is tell $dropbox, 5 * 1024 + 512, 'Right position is set';

okay { read $dropbox, $data, 1024 } 'Read 1k from file';

is tell $dropbox, 6 * 1024, 'Right position is set';

is $data, join('', 'F' x 512),
	'Content is okay';

okay { eof  $dropbox }                  'File end reached';
okay { seek $dropbox, -1024, SEEK_END } 'Seek relative to end';
okay { seek $dropbox, -1024, SEEK_END } 'Seek relative to end';

is tell $dropbox, 5 * 1024, 'Right position is set';

okay { read $dropbox, $data, 1024 } 'Read 1k from file';

is $data, join('', 'F' x 1024),
	'Content is okay';

errn { read $dropbox, $data, 1024 } 0, 'Read 1k from file end';

is $data, '',               'No content';
is tell $dropbox, 6 * 1024, 'Right position is set';

okay { seek $dropbox, 1024, SEEK_END }  'Seek beyond end';
errn { read $dropbox, $data, 1024 } 0,  'Read 1k from file end';

is $data, '',               'No content';
is tell $dropbox, 7 * 1024, 'Right position is set';

okay { seek  $dropbox, -1024, SEEK_SET } 'Seek before start';
okay { read $dropbox, $data, 1024 }      'Read 1k from file start';

is $data, 'A' x 1024,   'Right content';
is tell $dropbox, 1024, 'Right position is set';

okay { seek  $dropbox, 1023, SEEK_SET } 'Seek to 1023';

is getc $dropbox, 'A', 'Get A character';
is getc $dropbox, 'B', 'Get B character';
is getc $dropbox, 'B', 'Get B character';

is tell $dropbox, 1026, 'Right position is set';

okay { open  $dropbox, '<', $file } 'File reopened for reading';

is tell $dropbox, 0, 'Right position is set';
ok !eof $dropbox,    'Not at end of file';

okay { seek $dropbox, 0, SEEK_CUR } 'Dummy seek';

is tell $dropbox, 0, 'Right position is set';
ok !eof $dropbox,    'Not at end of file';

okay { close $dropbox } 'All done';
