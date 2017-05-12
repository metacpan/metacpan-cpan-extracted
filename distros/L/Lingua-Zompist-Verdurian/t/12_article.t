# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 16;
use Carp;

use Lingua::Zompist::Verdurian 'adj';

sub form_ok {
    croak 'usage: form_ok($adj, $is, $should)' unless @_ >= 3;
    my($adj, $is, $should) = @_;

    is($is->[0][0], $should->[0][0], "masc.nom.sg. of $adj");
    is($is->[0][1], $should->[0][1], "masc.gen.sg. of $adj");
    is($is->[0][2], $should->[0][2], "masc.acc.sg. of $adj");
    is($is->[0][3], $should->[0][3], "masc.dat.sg. of $adj");
    is($is->[0][4], $should->[0][4], "masc.nom.pl. of $adj");
    is($is->[0][5], $should->[0][5], "masc.gen.pl. of $adj");
    is($is->[0][6], $should->[0][6], "masc.acc.pl. of $adj");
    is($is->[0][7], $should->[0][7], "masc.dat.pl. of $adj");
    is($is->[1][0], $should->[1][0], "fem.nom.sg. of $adj");
    is($is->[1][1], $should->[1][1], "fem.gen.sg. of $adj");
    is($is->[1][2], $should->[1][2], "fem.acc.sg. of $adj");
    is($is->[1][3], $should->[1][3], "fem.dat.sg. of $adj");
    is($is->[1][4], $should->[1][4], "fem.nom.pl. of $adj");
    is($is->[1][5], $should->[1][5], "fem.gen.pl. of $adj");
    is($is->[1][6], $should->[1][6], "fem.acc.pl. of $adj");
    is($is->[1][7], $should->[1][7], "fem.dat.pl. of $adj");
}


# Test the definite article

form_ok('so', adj('so'), [ [ qw( so soei so soán
                                 soî soië soi soin ) ],
                           [ qw( soa soe soa soan
                                 soî soië soem soen ) ] ]);
