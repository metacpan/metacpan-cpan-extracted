#!/usr/bin/perl

use Test;
BEGIN { plan tests => 4 };
use Imager::TimelineDiagram;
use Imager::Font;

my $tg = Imager::TimelineDiagram->new(
                                      #maxTime => 10,
                                      #dataLabelSide => 'left',
                                      labelFont => Imager::Font->new(file => 't/ImUgly.ttf'),
                                     );
ok($tg);

$tg->set_milestones(qw(A B C D E));
ok($tg);

my @points = (
     # From, To, AtTime
     ['A','B',1.0],
     ['B','C',2.0],
     ['C','D',3.3],
     ['D','C',4.3],
     ['C','A',5.0],
);

$tg->add_points(@points);
ok($tg);

$tg->write('foo.png');
ok(-e 'foo.png');
