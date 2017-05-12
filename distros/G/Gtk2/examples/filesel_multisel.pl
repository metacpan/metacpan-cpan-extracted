#!/usr/bin/perl -w

# using a Gtk2::FileSelection to get multiple files is really easy.

use Data::Dumper;
use Gtk2 -init;

my $fs = Gtk2::FileSelection->new ('pick something');
# tell it to allow multiple selections...
$fs->set_select_multiple (TRUE);
if ('ok' eq $fs->run) {
	# and then fetch the selections as a list.
	print Dumper($fs->get_selections);
}
