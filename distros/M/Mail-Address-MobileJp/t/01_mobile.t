use strict;
use Test::More tests => 38;

use Mail::Address;
use Mail::Address::MobileJp;

my @ok_imode = (
    'foo@docomo.ne.jp',
);

my @ok_vodafone = (
    'foo@jp-d.ne.jp',
    'foo@d.vodafone.ne.jp',
    'foo@softbank.ne.jp',
);

my @ok_ezweb = (
    'foo@ezweb.ne.jp',
    'foo@hoge.ezweb.ne.jp',
);

my @ok_softbank = (
    'foo@softbank.ne.jp',
    'foo@d.vodafone.ne.jp',
    'foo@disney.ne.jp',
);

my @ok = (
    @ok_imode,
    @ok_vodafone,
    @ok_ezweb,
    @ok_softbank,
    'foo@mnx.ne.jp',
    'foo@bar.mnx.ne.jp',
    'foo@dct.dion.ne.jp',
    'foo@sky.tu-ka.ne.jp',
    'foo@bar.sky.tkc.ne.jp',
    'foo@em.nttpnet.ne.jp',
    'foo@bar.em.nttpnet.ne.jp',
    'foo@pdx.ne.jp',
    'foo@dx.pdx.ne.jp',
    'foo@phone.ne.jp',
    'foo@bar.mozio.ne.jp',
    'foo@p1.foomoon.com',
    'foo@x.i-get.ne.jp',
    'foo@ez1.ido.ne.jp',
    'foo@cmail.ido.ne.jp',
    Mail::Address->parse('foo <foo@p1.foomoon.com>'),
);

my @not = (
    'foo@example.com',
    'foo@dxx.pdx.ne.jp',
    'barabr',
    Mail::Address->parse('foo <foo@doo.com>'),
);

for my $ok (@ok_imode) {
    ok is_imode($ok), "$ok";
}

for my $ok (@ok_vodafone) {
    ok is_vodafone($ok), "$ok";
}

for my $ok (@ok_ezweb) {
    ok is_ezweb($ok), "$ok";
}

for my $ok (@ok_softbank) {
    ok is_softbank($ok), "$ok";
}

for my $ok (@ok) {
    ok is_mobile_jp($ok), "$ok";
}

for my $not (@not) {
    ok !is_mobile_jp($not), "$not";
}
