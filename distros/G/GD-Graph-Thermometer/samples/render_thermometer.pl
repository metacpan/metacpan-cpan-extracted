#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw{/home/hesco/sb/GD-Graph-Thermometer/lib};
# use lib qw{../lib};
use GD::Graph::Thermometer;

my $blue = [0,0,255];

my $result = GD::Graph::Thermometer->new({
             image_path => '/home/hesco/sb/GD-Graph-Thermometer/result.png',
                   type => 'png',
                   goal => '80000',
                current => '50000',
                  title => 'Funding our League for the Year ($)',
                  width => '100',
                 height => '200',
            transparent => '1',
#       background_color => '',
#             text_color => $blue,
#             text_color => [0,0,255],
#          outline_color => '',
#          mercury_color => [212,76,32] 
    });

1;
