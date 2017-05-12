use Test::More tests => 3;

BEGIN { use_ok(Imager::Filter::Sepia) }

my $im = Imager->new(xsize=>100, ysize=>100);
SKIP:
{
    ok($im->filter(type => 'sepia'), "try filter")
        or print "# ", $im->errstr, "\n";
    ok($im->write(file => '01.sepia.ppm'), "save result");
}
