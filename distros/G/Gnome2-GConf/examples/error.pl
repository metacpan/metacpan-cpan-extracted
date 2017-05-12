#!/usr/bin/perl
# GConf Error test using Glib::Error.
# Copyright 2004 Emmanuele Bassi
# Released under the terms of the GNU General Public License.

use strict;
use warnings;
use Gnome2::GConf;

our $client = Gnome2::GConf::Client->get_default;

# try:
eval
{
	# if you ran the basic/complex gconf apps inside the examples/ directory,
	# this call should not fail.
	print $client->get_string('/apps/basic-gconf-app/foo') . "\n";
	
	# this call, on the other hand, will always fail.
	print $client->get_string('/apps/basic-gconf-app/') . "\n";

	1;
};
# catch:
if ($@)
{
	use Data::Dumper;
	use Glib;
	
	# catch Gnome2::GConf::Error
	if ($@->isa('Gnome2::GConf::Error'))
	{
		print "Catching a Gnome2::GConf::Error exception...\n";
		if (Glib::Error::matches($@, 'Gnome2::GConf::Error', 'bad-key'))
		{
			# print message...
			print "*** Our catched error:\n" . $@->message . "\n";
			
			# ...and recover from the 'bad-key' error.
		}
	}

	# this is always valid
	print "*** GConf error:\n$@\n";
	
	print Dumper($@) . "\n";
}

0;
