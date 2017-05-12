use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Common qw{ :func :errno };
use File::Dropbox qw{ putfile movefile copyfile };

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app);
my $path    = base();
my $filea   = $path. '/e/'. time;
my $fileb   = $path. '/f/'. time;
my $filec   = $path. '/g/'. time;

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

plan tests => 17;

okay { putfile $dropbox, $filea, 'X' x 1024 } 'Put 1k file';

okay { movefile $dropbox, $filea, $fileb } 'Rename file';

okay { open $dropbox, '<', $fileb } 'Open renamed file for reading';

# Read file
my $data = readline $dropbox;

# Check content
is $data, join('', 'X' x 1024), 'Content is okay';

# First file not exists anymore
errn {
	open $dropbox, '<', $filea;
} ENOENT, 'Failed to read from not existing file';

# Move not existing file
errn {
	movefile $dropbox, $filea, $fileb;
} ENOENT, 'Failed to move not existing file';

okay {
	movefile $dropbox, $fileb, $fileb;
} 'Moving to same name does nothing';

okay { copyfile $dropbox, $fileb, $filec } 'Copy created';

errn {
	movefile $dropbox, $filec, $fileb;
} EACCES, 'Failed override another file';
