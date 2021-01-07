#!/usr/bin/perl -w

use strict;

use constant TESTS => 3; # number of skippable tests
use Config;
use Test::More tests => TESTS + 1;

use Gnome2::VFS '-init';

BEGIN { use_ok( 'Gtk2::Recent' ); }

my $file = '/tmp/recent-files-test.txt';
my $scheme = 'file://';
open(FH, ">$file") || die ("Unable to open $file: $!");
print FH scalar localtime;
close(FH);

SKIP: {
	skip( "Unable to find $file", TESTS ) unless -f $file;

	my $uri = $scheme . $file;

	my $item = Gtk2::Recent::Item->new_from_uri($uri);
	isa_ok( $item, 'Gtk2::Recent::Item' );
	$item->set_mime_type('text/plain');
	
	my $model = Gtk2::Recent::Model->new('none');
	isa_ok( $model, 'Gtk2::Recent::Model' );

	ok( $model->add_full($item) );
	#ok( $model->delete($uri) );
}
