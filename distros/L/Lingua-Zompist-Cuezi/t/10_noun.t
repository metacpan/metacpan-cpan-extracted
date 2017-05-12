# vim:set filetype=perl sw=4 et encoding=utf-8 fileencoding=utf-8 keymap=cuezi:
#########################

use Test::More no_plan => ; # tests => 521;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'noun'; }

sub form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "gen.sg. of $noun");
    is($is->[2], $should->[2], "acc.sg. of $noun");
    is($is->[3], $should->[3], "dat.sg. of $noun");
    is($is->[4], $should->[4], "abl.sg. of $noun");
    is($is->[5], $should->[5], "ins.sg. of $noun");
    is($is->[6], $should->[6], "nom.pl. of $noun");
    is($is->[7], $should->[7], "gen.pl. of $noun");
    is($is->[8], $should->[8], "acc.pl. of $noun");
    is($is->[9], $should->[9], "dat.pl. of $noun");
    is($is->[10], $should->[10], "abl.pl. of $noun");
    is($is->[11], $should->[11], "ins.pl. of $noun");
}

# masculine
form_ok('oluon', noun('oluon'), [ qw( oluon oluonex oluon oluonnu oluontu oluonco
                                      oluoni oluoniē oluoni oluoninu oluonitu oluonico ) ]);

# neuter
form_ok('usolu', noun('usolu'), [ qw( usolu usolex usolu usolnu usoltu usoluco
                                      usolū usoluē usolū usolūna usolūta usolūco ) ]);

# feminine
form_ok('etêia', noun('etêia'), [ qw( etêia etêiaē etêiā etêianu etêiadi etêialu
                                      etêiē etêieē etêiē etêiēnu etêiēdi etêiēlu ) ]);

# test general forms
# masculine

# neuter
# can't test generic neuter '-IS', but see at end
# form_ok('GGGIS', noun('GGGIS'), [ qw( GGGIS GGGII GGGIM GGGIN GGGITH
#                                       GGGUI GGGUIE GGGUIM GGGUIN GGGUITH ) ]);

# feminine

# test neuter nouns
# form_ok('ATITRIS', noun('ATITRIS'), [ qw( ATITRIS ATITRII ATITRIM ATITRIN ATITRITH
#                                           ATITRUI ATITRUIE ATITRUIM ATITRUIN ATITRUITH ) ]);
# form_ok('ZURRIS', noun('ZURRIS'), [ qw( ZURRIS ZURRII ZURRIM ZURRIN ZURRITH
#                                         ZURRUI ZURRUIE ZURRUIM ZURRUIN ZURRUITH ) ]);
