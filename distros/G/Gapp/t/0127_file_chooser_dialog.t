#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 6;

use Gtk2 '-init';






{ # basic construction test
    use_ok 'Gapp::FileChooserDialog';
    my $w = Gapp::FileChooserDialog->new;
    isa_ok $w, 'Gapp::FileChooserDialog';
    isa_ok $w->gobject,  'Gtk2::FileChooserDialog';
}


{ # basic construction test
    use_ok 'Gapp::FileFilter';
    my $w = Gapp::FileFilter->new( name => 'Text', patterns => [ '*.txt' ] );
    isa_ok $w, 'Gapp::FileFilter';
    isa_ok $w->gobject,  'Gtk2::FileFilter';
}
