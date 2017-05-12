#!/usr/bin/perl -w
use strict;


# Note that this test file is purely to test that large data sets can be 
# supported with all the point shapes being used.


use Test::More  tests => 6;
use GD::Chart::Radial;
use IO::File;

my $chart;
my $max = 40;
my @lots = ([qw/A B C/],
            [39,39,39],[38,38,38],[37,37,37],[36,36,36],[35,35,35],[34,34,34],[33,33,33],[32,32,32],[31,31,31],[30,30,30],
            [29,29,29],[28,28,28],[27,27,27],[26,26,26],[25,25,25],[24,24,24],[23,23,23],[22,22,22],[21,21,21],[20,20,20],
            [19,19,19],[18,18,18],[17,17,17],[16,16,16],[15,15,15],[14,14,14],[13,13,13],[12,12,12],[11,11,11],[10,10,10],
            [9,9,9],[8,8,8],[7,7,7],[6,6,6],[5,5,5],[4,4,4],[3,3,3],[2,2,2],[1,1,1],[0,0,0]);

my $file = 'point-default.jpg';
unlink $file    if(-f $file);

{
    my $style = 'Notch';
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

    eval { $chart->plot(\@lots) };
    ok(!$@,'no errors with plot values');
    diag($@)    if(@_);

    SKIP: {
        my $fh;
        skip "Write access disabled for test files",2
            unless($fh = IO::File->new($file,'w'));

        binmode $fh;
        print $fh $chart->jpg;
        $fh->close;
        ok(-f $file,"file [$file] exists");
    }
}

# clean up
unlink $file    if(-f $file);
