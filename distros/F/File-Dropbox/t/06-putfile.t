use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Common qw{ :func };
use File::Dropbox qw{ putfile metadata };

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app);
my $file    = join '/', base(), time;

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

plan tests => 7;

eval { putfile $app, $file, 'ABCD' };

like $@, qr{GLOB reference expected},
	'Function called on wrong reference';

# Normal upload
okay { putfile $dropbox, $file, 'A' x 1024 } 'Put 1k file';

# Get meta from closed handle
my $meta = metadata $dropbox;

okay { open $dropbox, '<', $file } 'Open file for reading';

# Get meta from opened handle
my $meta2 = metadata $dropbox;

# Compare
is_deeply $meta, $meta2, 'Metadata matches';

# Read file
my $data = readline $dropbox;

# Check content
is $data, join('', 'A' x 1024),
	'Content is okay';
