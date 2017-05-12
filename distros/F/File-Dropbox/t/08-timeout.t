use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Common qw{ :func ECANCELED };
use File::Dropbox;

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app, furlopts => {
	timeout => 1,
});

unless (keys %$app) {
	plan skip_all => 'DROPBOX_AUTH is not set or has wrong value';
	exit;
}

unless (exists $ENV{'DROPBOX_TIMEOUT'}) {
	plan skip_all => 'DROPBOX_TIMEOUT is not set';
	exit;
}

plan tests => 10;

errn { open $dropbox, 'r', time } ECANCELED, 'Timeout on open';

okay { open $dropbox, 'w', time } 'File opened for writing';

okay { print $dropbox 'A' x 4096 } '4k';

errn {
	print $dropbox 'A' x (8 << 20);
} ECANCELED, 'Timeout on write';

errn {
	close $dropbox;
} ECANCELED, 'Timeout on close';
