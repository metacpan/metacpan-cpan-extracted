#!/usr/bin/perl -w
# Example for GraphViz::ISA::Multi
# 2003 (c) by Marcus Thiesen
# marcus@cpan.org

use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";

use GraphViz::ISA::Multi;
use Curses::UI; # make sure it is there


my $gnew= GraphViz::ISA::Multi->new(ignore => [ 'Exporter' ]);

$gnew->add("Curses::UI::TextViewer" );
$gnew->add("Curses::UI::Listbox" );
$gnew->add("Curses::UI::PasswordEntry" );
$gnew->add( "Curses::UI::Buttonbox" );
$gnew->add( "Curses::UI::Calendar" );
$gnew->add("Curses::UI::Checkbox" );
$gnew->add( "Curses::UI::Color" );
$gnew->add("Curses::UI::Label" );
$gnew->add("Curses::UI::Menubar" );
$gnew->add("Curses::UI::Popupmenu" );
$gnew->add("Curses::UI::Progressbar" );
$gnew->add("Curses::UI::Radiobuttonbox" );
$gnew->add("Curses::UI::Window" );

print "Writing to curses-ui.png\n";
open TEST, ">curses-ui.png";
print TEST $gnew->as_png();
close TEST;

