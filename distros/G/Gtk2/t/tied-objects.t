#!/usr/bin/perl
use strict;
use warnings;

use Tie::Hash;
use Glib qw/:constants/;
use Gtk2::TestHelper tests => 1;

# Make sure a tied Glib::Object is handled normally.  Based on a test sent to
# the list by Terrence Brannon.
tie my %objects, 'Tie::StdHash';
my $vbox = Gtk2::VBox->new (FALSE, 0);
$objects{button} = Gtk2::Button->new ('Quit');
ok (eval { $vbox->add ($objects{button}); 1 });
