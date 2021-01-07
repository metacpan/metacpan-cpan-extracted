#!/usr/bin/perl -w

use strict;

use Gnome2::VFS '-init';
use Gtk2::Recent;

if ($#ARGV < 1) {
	print STDERR "Usage:\n";
	print STDERR "$0 --add <URI>\n";
	print STDERR "$0 --delete <URI>\n";
	exit 1;
}

my $option = $ARGV[0];
my $file_uri = $ARGV[1];

my $model = Gtk2::Recent::Model->new('none');
$model->set_limit(0);

if ('--add' eq $option) {
	print "Adding: " . $file_uri . "\n";
	$model->add($file_uri);
}
elsif ('--delete' eq $option) {
	print "Deleting: " . $file_uri . "\n";
	$model->delete($file_uri);
}

0;
