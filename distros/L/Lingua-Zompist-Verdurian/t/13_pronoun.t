# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 160;
use Carp;

use Lingua::Zompist::Verdurian 'noun';

sub form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "gen.sg. of $noun");
    is($is->[2], $should->[2], "acc.sg. of $noun");
    is($is->[3], $should->[3], "dat.sg. of $noun");
    is($is->[4], $should->[4], "nom.pl. of $noun");
    is($is->[5], $should->[5], "gen.pl. of $noun");
    is($is->[6], $should->[6], "acc.pl. of $noun");
    is($is->[7], $should->[7], "dat.pl. of $noun");
}

sub sg_form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom. of $noun");
    is($is->[1], $should->[1], "gen. of $noun");
    is($is->[2], $should->[2], "acc. of $noun");
    is($is->[3], $should->[3], "dat. of $noun");
}


# Personal pronouns

form_ok('se', noun('se'), [ qw( se esë et sen
                                ta taë tam tan ) ]);
form_ok('le', noun('le'), [ qw( le lë erh len
                                mu muë mü mun ) ]);
form_ok('ilu', noun('ilu'), [ qw( ilu lië ilet ilun
                                  ca caë cam can ) ]);
form_ok('ila', noun('ila'), [ qw( ila liue ilat ilan
                                  ca caë cam can ) ]);
form_ok('il', noun('il'), [ qw( il lië iler ilon
                                ca caë cam can ) ]);
form_ok('ze', noun('ze'), [ qw( ze zië zet zen
                                za zaë zam zan ) ]);
sg_form_ok('tu', noun('tu'), [ qw( tu tuë tu/tü tun ) ]);
sg_form_ok('ta', noun('ta'), [ qw( ta taë tam tan ) ]);
sg_form_ok('mu', noun('mu'), [ qw( mu muë mü  mun ) ]);
sg_form_ok('ca', noun('ca'), [ qw( ca caë cam can ) ]);
sg_form_ok('za', noun('za'), [ qw( za zaë zam zan ) ]);


# Relative and interrogative pronouns

form_ok('ke', noun('ke'), [ qw( ke kë ket ken
                                kaë kaëne kaëm kaën ) ]);
sg_form_ok('kio', noun('kio'), [ qw( kio kiei kiom kion ) ]);
sg_form_ok('eto', noun('eto'), [ qw( eto etë eto eton ) ]);
sg_form_ok('tot', noun('tot'), [ qw( tot totë tot totán ) ]);
sg_form_ok('fsya', noun('fsya'), [ qw( fsya fsye fsya fsyan ) ]);
sg_form_ok('fsë', noun('fsë'), [ qw( fsë fsëi fsë fsën ) ]);
sg_form_ok('ktë', noun('ktë'), [ qw( ktë ktëi ktë ktën ) ]);
sg_form_ok('zdesy', noun('zdesy'), [ qw( zdesy zdesii zdesy zdesín ) ]);
sg_form_ok('cechel', noun('cechel'), [ qw( cechel cechelei cechel cechelán ) ]);
sg_form_ok('nish', noun('nish'), [ qw( nish nishei nish nishán ) ]);

# and derived forms of the above

sg_form_ok('ifkio', noun('ifkio'), [ qw( ifkio ifkiei ifkiom ifkion ) ]);
sg_form_ok('nibkio', noun('nibkio'), [ qw( nibkio nibkiei nibkiom nibkion ) ]);
form_ok('nibke', noun('nibke'), [ qw( nibke nibkë nibket nibken
                                      nibkaë nibkaëne nibkaëm nibkaën ) ]);
form_ok('ifke', noun('ifke'), [ qw( ifke ifkë ifket ifken
                                    ifkaë ifkaëne ifkaëm ifkaën ) ]);
sg_form_ok('nëcto', noun('nëcto'), [ qw( nëcto nëctë nëcto nëcton ) ]);
sg_form_ok('nikto', noun('nikto'), [ qw( nikto niktë nikto nikton ) ]);
sg_form_ok('shto', noun('shto'), [ qw( shto shtë shto shton ) ]);
sg_form_ok('nibcë', noun('nibcë'), [ qw( nibcë nibcëi nibcë nibcën ) ]);
sg_form_ok('ticë', noun('ticë'), [ qw( ticë ticëi ticë ticën ) ]);
sg_form_ok('ifcë', noun('ifcë'), [ qw( ifcë ifcëi ifcë ifcën ) ]);

# fsuda and nikudá don't decline
