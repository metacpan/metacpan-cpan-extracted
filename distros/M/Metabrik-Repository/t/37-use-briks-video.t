use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Video::Convert"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Video::Ffmpeg"); $@ ? 0 : 1 }, 1, $@);
