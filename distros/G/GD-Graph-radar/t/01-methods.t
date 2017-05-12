#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('GD::Graph::radar') }

my $g = eval { GD::Graph::radar->new(400, 400) };
isa_ok $g, 'GD::Graph::radar';
ok !$@, 'object created';
warn $@ if $@;

my $i = eval {
    $g->plot([
        [qw(a    b  c    d    e    f    g  h    i)],
        [   3.2, 9, 4.4, 3.9, 4.1, 4.3, 7, 6.1, 5 ]
    ]);
};
ok !$@, 'image plotted';

my $format = 'png';
my $outfile = "t/test.$format";

eval {
    open my $img, ">$outfile" or die "Can't open $outfile - $!\n";
    binmode $img;
    print $img $i->$format();
    close $img;
};
ok !$@, "image file written as $outfile";
ok -e $outfile && -s $outfile > 0, 'image file exists';
