use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Common qw{ :func ENOENT };
use File::Dropbox qw{ deletefile };

my $app     = conf();
my $path    = base();
my $dropbox = File::Dropbox->new(%$app);

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

plan tests => 4;

okay { deletefile $dropbox, $path } 'Test directory removed';

errn { deletefile $dropbox, $path } ENOENT, 'Removed already';
