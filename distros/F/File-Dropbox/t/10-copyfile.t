use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Common qw{ :func :errno };
use File::Dropbox qw{ putfile copyfile movefile };

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app);
my $path    = base();
my $filea   = $path. '/i/'. time;
my $fileb   = $path. '/j/'. time;
my $filec   = $path. '/k/'. time;

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

plan tests => 16;

okay { putfile $dropbox, $filea, 'Y' x 1024 } 'Put 1k file';

okay { copyfile $dropbox, $filea, $fileb } 'Create copy';

okay { open $dropbox, '<', $fileb } 'Open target for reading';

# Read file
my $data = readline $dropbox;

# Check content
is $data, join('', 'Y' x 1024), 'Content is okay';

# Source file remains
okay { open $dropbox, '<', $filea } 'Open source for reading';

# Read file
$data = readline $dropbox;

# Check content
is $data, join('', 'Y' x 1024), 'Content is okay';

# Copy not existing file
errn {
	copyfile $dropbox, $filec, $filea;
} ENOENT, 'Failed to copy not existing file';

# Copy file to itself
okay { movefile $dropbox, $fileb, $fileb } 'File copied to same name';

# Try overwrite file
errn {
	movefile $dropbox, $fileb, $filea;
} EACCES, 'Failed to overwrite one file with another';
