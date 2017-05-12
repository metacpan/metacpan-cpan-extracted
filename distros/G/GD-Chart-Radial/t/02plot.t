#!/usr/bin/perl -w
use strict;

use Test::More  tests => 30;
use GD::Chart::Radial;
use IO::File;

my $chart;
my @data = ([qw/A B C D E F G/],[12,21,23,30,23,22,5],[10,20,21,24,28,15,9]);
my @lots = ([qw/A B C D E F G/],[12,21,23,30,23,22,5],[10,20,21,24,28,15,9],[1,5,7,8,9,4,2],[15,14,10,3,20,18,16]);
my $max = 31;

my @files = qw(plot-Polygon.gd plot-Fill.gd plot-Notch.gd plot-default.gd plot-Circle.gd);

# clean up
unlink $_    for(@files);

for my $style (qw(Fill Notch Circle Polygon)) {
    $chart = GD::Chart::Radial->new(500,500);
    isa_ok($chart,'GD::Chart::Radial','specified new');

    eval { $chart->set() };
    ok(!$@,'no errors on empty set');
    diag($@)    if(@_);

    eval { $chart->plot() };
    ok(!$@,'no errors on empty plot');
    diag($@)    if(@_);

    eval {
        $chart->set(
            legend          => [qw/april may/],
            title           => 'Some simple graph',
            y_max_value     => $max,
            y_tick_number   => 5,
            style           => $style,
            colours         => ['white', 'light_grey', 'red', '#00f', '#00ff00'],
           );
    };
    ok(!$@,'no errors with set values');
    diag($@)    if(@_);

    eval { $chart->plot(\@data) };
    ok(!$@,'no errors with plot values');
    diag($@)    if(@_);

    SKIP: {
        my $file = "plot-$style.gd";
        my $fh;
        skip "Write access disabled for test files",1
            unless($fh = IO::File->new($file,'w'));

        binmode $fh;
        print $fh $chart->gd;
        $fh->close;
        ok(-f $file,"file [$file] exists");
    }
}

{
    $chart = GD::Chart::Radial->new();
    isa_ok($chart,'GD::Chart::Radial','default new');

    eval { $chart->plot(\@lots) };
    ok(!$@,'no errors with plot values without any set');
    diag($@)    if(@_);

    for my $type (qw(png gif jpg gd)) {
        SKIP: {
            my $file = 'plot-default.'.$type;
            my $fh;
            skip "Write access disabled for test files",1
                unless($fh = IO::File->new($file,'w'));

            binmode $fh;
            print $fh $chart->$type;
            $fh->close;
            ok(-f $file,"file [$file] exists");
        }
    }
}

# clean up
unlink $_    for(@files);
unlink $_    for(qw(plot-default.png plot-default.gif plot-default.jpg));
