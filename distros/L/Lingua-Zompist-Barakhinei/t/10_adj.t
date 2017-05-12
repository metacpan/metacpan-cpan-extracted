# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 10_adj.t'

#########################

use Test::More tests => 169;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Barakhinei', 'adj' }

sub form_ok ($$$) {
    # croak 'usage: form_ok($adj, $is, $should)' unless @_ >= 3;
    my($adj, $is, $should) = @_;

    is($is->[0][0], $should->[0][0], "masc.nom.sg. of $adj");
    is($is->[0][1], $should->[0][1], "masc.acc.sg. of $adj");
    is($is->[0][2], $should->[0][2], "masc.dat.sg. of $adj");
    is($is->[0][3], $should->[0][3], "masc.gen.sg. of $adj");
    is($is->[0][4], $should->[0][4], "masc.nom.pl. of $adj");
    is($is->[0][5], $should->[0][5], "masc.acc./dat.pl. of $adj");
    is($is->[0][6], $should->[0][6], "masc.gen.pl. of $adj");
    is($is->[1][0], $should->[1][0], "neut.nom.sg. of $adj");
    is($is->[1][1], $should->[1][1], "neut.acc.sg. of $adj");
    is($is->[1][2], $should->[1][2], "neut.dat.sg. of $adj");
    is($is->[1][3], $should->[1][3], "neut.gen.sg. of $adj");
    is($is->[1][4], $should->[1][4], "neut.nom.pl. of $adj");
    is($is->[1][5], $should->[1][5], "neut.acc./dat.pl. of $adj");
    is($is->[1][6], $should->[1][6], "neut.gen.pl. of $adj");
    is($is->[2][0], $should->[2][0], "fem.nom.sg. of $adj");
    is($is->[2][1], $should->[2][1], "fem.acc.sg. of $adj");
    is($is->[2][2], $should->[2][2], "fem.dat.sg. of $adj");
    is($is->[2][3], $should->[2][3], "fem.gen.sg. of $adj");
    is($is->[2][4], $should->[2][4], "fem.nom.pl. of $adj");
    is($is->[2][5], $should->[2][5], "fem.acc./dat.pl. of $adj");
    is($is->[2][6], $should->[2][6], "fem.gen.pl. of $adj");
}

form_ok('âr', adj('âr'), [ [ qw( âr âr  âra âro   âri ârî  ârich ) ],
                           [ qw( âr âru âru âro   âro ârî  ârich ) ],
                           [ qw( âr âra ârê ârach ârâ ârêi ârech ) ] ]);

form_ok('na', adj('na'), [ [ qw( na na   nana nano   nani nanî  nanich ) ],
                           [ qw( na nanu nanu nano   nano nanî  nanich ) ],
                           [ qw( na nana nanê nanach nanâ nanêi nanech ) ] ]);

form_ok('gelê', adj('gelê'), [ [ qw( gelê gelê gela gelo   gelê gelî  gelêch ) ],
                               [ qw( gele gelê gelê gelo   gele gelê  gelech ) ],
                               [ qw( gelê gele gelê gelech gelê gelêi gelech ) ] ]);

form_ok('ori', adj('ori'), [ [ qw( ori or  ori  orio  ori  orî  orich  ) ],
                             [ qw( ori ori ori  orio  oru  orî  orich  ) ],
                             [ qw( ori ori oriê orich oriê oria oriech ) ] ]);

# Give the oblique stem consonant explicitly
form_ok('âr', adj('âr', ''), [ [ qw( âr âr  âra âro   âri ârî  ârich ) ],
                               [ qw( âr âru âru âro   âro ârî  ârich ) ],
                               [ qw( âr âra ârê ârach ârâ ârêi ârech ) ] ]);

form_ok('na', adj('na', 'n'), [ [ qw( na na   nana nano   nani nanî  nanich ) ],
                                [ qw( na nanu nanu nano   nano nanî  nanich ) ],
                                [ qw( na nana nanê nanach nanâ nanêi nanech ) ] ]);

form_ok('gelê', adj('gelê', ''), [ [ qw( gelê gelê gela gelo   gelê gelî  gelêch ) ],
                                   [ qw( gele gelê gelê gelo   gele gelê  gelech ) ],
                                   [ qw( gelê gele gelê gelech gelê gelêi gelech ) ] ]);

form_ok('ori', adj('ori', ''), [ [ qw( ori or  ori  orio  ori  orî  orich  ) ],
                                 [ qw( ori ori ori  orio  oru  orî  orich  ) ],
                                 [ qw( ori ori oriê orich oriê oria oriech ) ] ]);

# Give the oblique stem consonant explicitly
