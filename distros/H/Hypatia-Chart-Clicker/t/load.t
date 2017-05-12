#!perl -T

use Test::More;

BEGIN {
    my @modules=qw(
        Hypatia::Chart::Clicker
        Hypatia::Chart::Clicker::Line
        Hypatia::Chart::Clicker::Bar
        Hypatia::Chart::Clicker::Area
        Hypatia::Chart::Clicker::Point
        Hypatia::Chart::Clicker::Bubble
        Hypatia::Chart::Clicker::Pie
        Hypatia::Chart::Clicker::Types
        Hypatia::Chart::Clicker::Options
        Hypatia::Chart::Clicker::Options::Axis
    );

    foreach(@modules)
    {
        use_ok($_) or print "Couldn't load module $_\n";
    }
}

diag( "Testing Hypatia::Chart::Clicker $Hypatia::Chart::Clicker::VERSION, Perl $], $^X" );

done_testing();