# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 102;
use Carp;

use Lingua::Zompist::Verdurian 'demeric';

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "I.sg. of $verb");
    is($is->[1], $should->[1], "II.sg. of $verb");
    is($is->[2], $should->[2], "III.sg. of $verb");
    is($is->[3], $should->[3], "I.pl. of $verb");
    is($is->[4], $should->[4], "II.pl. of $verb");
    is($is->[5], $should->[5], "III.pl. of $verb");
}

form_ok('lelen', demeric('lelen'), [ qw( lelai lelei lele lelam lelo lelu) ]);
form_ok('badhir', demeric('badhir'), [ qw( badhu badheu badhe badhum badho badhü ) ]);
form_ok('elirec', demeric('elirec'), [ qw( elirao elireo elire elirom eliro eliru ) ]);

form_ok('esan', demeric('esan'), [ qw( ai ei e am eo eu ) ]);
form_ok('fassec', demeric('fassec'), [ qw( fassao fasseo fas fassom fasso fassu ) ]);
form_ok('kies', demeric('kies'), [ qw( kiai kiei kiet kaiam kaio kaiu ) ]);
form_ok('lübec', demeric('lübec'), [ qw( lübao lüo lü lübom lübo lübu ) ]);
form_ok('mizec', demeric('mizec'), [ qw( mizao mizeo mis mizom mizo mizu ) ]);
form_ok('shrifec', demeric('shrifec'), [ qw( shrifao shris shri shrifom shrifo shrifu ) ]);
form_ok('zhanen', demeric('zhanen'), [ qw( zhai zhes zhe zhanam zhano zhanu ) ]);
form_ok('zhusir', demeric('zhusir'), [ qw( zhui zhus zhu zhusum zhuso zhusü ) ]);

form_ok('cummizec', demeric('cummizec'), [ qw( cummizao cummizeo cummis cummizom cummizo cummizu ) ]);
form_ok('onzhanen', demeric('onzhanen'), [ qw( onzhai onzhes onzhe onzhanam onzhano onzhanu ) ]);
# more?
form_ok('adesan', demeric('adesan'), [ qw(adesai adesei adese adesam adeso adesu ) ]);

form_ok('nozhen', demeric('nozhen'), [ qw(nogai nozhei nozhe nogam nogo nogu ) ]);
form_ok('lazhec', demeric('lazhec'), [ qw(lagao lazheo lazhe lagom lago lagu ) ]);
form_ok('dyuzher', demeric('dyuzher'), [ qw(dyugu dyuzheu dyuzhe dyugum dyugo dyuzhü ) ]);

