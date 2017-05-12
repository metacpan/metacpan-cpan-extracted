# vim:set filetype=perl sw=4 et encoding=utf-8 fileencoding=utf-8 keymap=cuezi:
#########################

use Test::More no_plan => ; # tests => 181;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'adj'; }

sub form_ok {
    croak 'usage: form_ok($adj, $is, $should)' unless @_ >= 3;
    my($adj, $is, $should) = @_;

    is($is->[0][0], $should->[0][0], "masc.nom.sg. of $adj");
    is($is->[0][1], $should->[0][1], "masc.gen.sg. of $adj");
    is($is->[0][2], $should->[0][2], "masc.acc.sg. of $adj");
    is($is->[0][3], $should->[0][3], "masc.dat.sg. of $adj");
    is($is->[0][4], $should->[0][4], "masc.abl.sg. of $adj");
    is($is->[0][5], $should->[0][5], "masc.ins.sg. of $adj");
    is($is->[0][6], $should->[0][6], "masc.nom.pl. of $adj");
    is($is->[0][7], $should->[0][7], "masc.gen.pl. of $adj");
    is($is->[0][8], $should->[0][8], "masc.acc.pl. of $adj");
    is($is->[0][9], $should->[0][9], "masc.dat.pl. of $adj");
    is($is->[0][10], $should->[0][10], "masc.abl.pl. of $adj");
    is($is->[0][11], $should->[0][11], "masc.ins.pl. of $adj");
    is($is->[1][0], $should->[1][0], "neut.nom.sg. of $adj");
    is($is->[1][1], $should->[1][1], "neut.gen.sg. of $adj");
    is($is->[1][2], $should->[1][2], "neut.acc.sg. of $adj");
    is($is->[1][3], $should->[1][3], "neut.dat.sg. of $adj");
    is($is->[1][4], $should->[1][4], "neut.abl.sg. of $adj");
    is($is->[1][5], $should->[1][5], "neut.ins.sg. of $adj");
    is($is->[1][6], $should->[1][6], "neut.nom.pl. of $adj");
    is($is->[1][7], $should->[1][7], "neut.gen.pl. of $adj");
    is($is->[1][8], $should->[1][8], "neut.acc.pl. of $adj");
    is($is->[1][9], $should->[1][9], "neut.dat.pl. of $adj");
    is($is->[1][10], $should->[1][10], "neut.abl.pl. of $adj");
    is($is->[1][11], $should->[1][11], "neut.ins.pl. of $adj");
    is($is->[2][0], $should->[2][0], "fem.nom.sg. of $adj");
    is($is->[2][1], $should->[2][1], "fem.gen.sg. of $adj");
    is($is->[2][2], $should->[2][2], "fem.acc.sg. of $adj");
    is($is->[2][3], $should->[2][3], "fem.dat.sg. of $adj");
    is($is->[2][4], $should->[2][4], "fem.abl.sg. of $adj");
    is($is->[2][5], $should->[2][5], "fem.ins.sg. of $adj");
    is($is->[2][6], $should->[2][6], "fem.nom.pl. of $adj");
    is($is->[2][7], $should->[2][7], "fem.gen.pl. of $adj");
    is($is->[2][8], $should->[2][8], "fem.acc.pl. of $adj");
    is($is->[2][9], $should->[2][9], "fem.dat.pl. of $adj");
    is($is->[2][10], $should->[2][10], "fem.abl.pl. of $adj");
    is($is->[2][11], $should->[2][11], "fem.ins.pl. of $adj");
}

form_ok('sīlo', adj('sīlo'), [ [ qw( sīle sīlex sīle sīlnu sīltu sīlco
                                     sīli sīliē sīli sīlinu sīlitu sīlico ) ],
                               [ qw( sīlo sīlex sīlo sīlonu sīlotu sīloco
                                     sīlō sīloē sīlō sīlōna sīlōta sīlōco ) ],
                               [ qw( sīla sīlaē sīla sīlanu sīladi sīlalu
                                     sīlē sīleē sīlē sīlēnu sīlēdi sīlēlu ) ] ]);

# test general forms
ok(1);
