#!/usr/bin/perl -w

use strict;

use constant TESTS => 9; # number of skippable tests.
use Config;
use Test::More tests => TESTS + 1;

use Gnome2::VFS '-init';

BEGIN { use_ok( 'Gtk2::Recent' ); };

my $file = '/tmp/recent-files-test.txt';
open(FH, ">$file") || die ("Unable to open $file: $!");
print FH scalar localtime;
close(FH);

SKIP: {
	skip( "Unable to find $file", TESTS ) unless -f $file;

	my $uri = 'file://' . $file;

	my $item = Gtk2::Recent::Item->new;
	isa_ok( $item, 'Gtk2::Recent::Item' );
	
	$item->set_uri($file);
	ok( 1 );

	is( $item->get_uri, $uri);

	$item->set_mime_type('text/plain');
	ok( 1 );

	is( $item->get_mime_type, 'text/plain' );

	$item->add_group('Test');
	ok( 1 );

	ok( $item->in_group('Test') );
	
	my @groups = $item->get_groups;
	is( @groups, 1, 'groups list is 1 item long' );

	$item->remove_group('Test');
	ok( 1 );
}

Gnome2::VFS->shutdown;

__END__

Copyright (C) 2005 Emmanuele Bassi <ebassi (at) gmail.com>
See LICENSE for more informations.
