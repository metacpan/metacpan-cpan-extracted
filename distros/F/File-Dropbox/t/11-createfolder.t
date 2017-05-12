use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Common qw{ :func :errno };
use File::Dropbox qw{ metadata createfolder deletefile };

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app);
my $path    = base();
my $folder  = $path. '/z/'. time;

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

plan tests => 9;

# Check folder existence
errn { open $dropbox, '<', $folder } ENOENT, 'Folder not exists';

# Create folder
okay { createfolder $dropbox, $folder } 'Folder created';

# Check returned path
is metadata($dropbox)->{'path'}, '/'. $folder, 'Path is okay';

# Try to create folder again
errn {
	createfolder $dropbox, $folder
} EACCES, 'Folder exists already';

# Delete folder
okay { deletefile $dropbox, $folder } 'Folder deleted';
