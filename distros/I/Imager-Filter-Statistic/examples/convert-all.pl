#!/usr/bin/env perl
use strict;
use warnings;
use Imager;
use Imager::Filter::Statistic;

my ($file, $output_dir, $geometry) = @ARGV;
-f $file or die;
$output_dir ||= "/tmp";
$geometry ||= "3x3";

my $img = Imager->new(file => $file) or die Imager->errstr;

for my $method (qw< median mode gradient variance min max mean >) {
    print "doing $method\n";
    my $img_copy = $img->copy;
    $img_copy->filter( type => "statistic", method => $method, "geometry" => $geometry );
    $img_copy->write(file => "$output_dir/filter.$method.png");
    print "... done\n";
}




