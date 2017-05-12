use Test::More tests => 5;;

use Linux::Svgalib ':all';
pass "manage to import";

eval 
{
   my $mode = G640x480x16;
};
if ( $@ )
{
  fail "can get a constant";
}
else
{
  pass "can get a constant";
}

my $vga = Linux::Svgalib->new();

isa_ok $vga, 'Linux::Svgalib', "got the new object";

eval {
    $vga->disabledriverreport();
};
if ( $@ ) {
    fail "disabledriverreport";
}
else {
    pass "disabledriverreport";
}

SKIP:
{
    skip "can only run as root", 1 if $<;
    ok $vga->init(), "init";
    ok $vga->setmode(4), "setmode";

    my $maxcol = $vga->getxdim();
    my $maxrow = $vga->getydim();

    for ( 0 ... 10000 ) {
        $vga->setcolor(int (rand 17));
        $vga->drawpixel(int( rand $maxcol), int(rand $maxrow));
    }

    my $line = [];
    $vga->setmode(8);

    for ( 1 .. 480 ) {
        @{$line} = ( 1 .. 255 );
        $vga->drawscanline($_,$line);
    }

    $vga->setmode(TEXT);
}
