# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 126;
use Carp;

use Lingua::Zompist::Verdurian 'ctanec';

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

form_ok('lelen', ctanec('lelen'), [ qw( lelmai lelmei lelme lelmam lelmo lelmu ) ]);
form_ok('badhir', ctanec('badhir'), [ qw( badhretu badhreteu badhrete badhretum badhreto badhretü ) ]);
form_ok('elirec', ctanec('elirec'), [ qw( elirtao elirteo elirte elirtom elirto elirtu ) ]);

form_ok('lachan', ctanec('lachan'), [ qw( ladmai ladmei ladme ladmam ladmo ladmu ) ]);
form_ok('legan', ctanec('legan'), [ qw( lezhmai lezhmei lezhme lezhmam lezhmo lezhmu ) ]);
form_ok('zhechir', ctanec('zhechir'), [ qw( zhetretu zhetreteu zhetrete zhetretum zhetreto zhetretü ) ]);
form_ok('visanir', ctanec('visanir'), [ qw( visandretu visandreteu visandrete visandretum visandreto visandretü ) ]);
form_ok('rizir', ctanec('rizir'), [ qw( ridretu ridreteu ridrete ridretum ridreto ridretü ) ]);
form_ok('ivrec', ctanec('ivrec'), [ qw( ivritao ivriteo ívrite ívritom ívrito ívritu ) ]);

form_ok('esan', ctanec('esan'), [ qw( esmai esmei esme esmam esmo esmu ) ]);

# test the general replacements
form_ok('aaachan', ctanec('aaachan'), [ qw( aaadmai aaadmei aaadme aaadmam aaadmo aaadmu ) ]);
form_ok('aaagan', ctanec('aaagan'), [ qw( aaazhmai aaazhmei aaazhme aaazhmam aaazhmo aaazhmu ) ]);

form_ok('aaachir', ctanec('aaachir'), [ qw( aaatretu aaatreteu aaatrete aaatretum aaatreto aaatretü ) ]);
form_ok('aaamir', ctanec('aaamir'), [ qw( aaambretu aaambreteu aaambrete aaambretum aaambreto aaambretü ) ]);
form_ok('aaanir', ctanec('aaanir'), [ qw( aaandretu aaandreteu aaandrete aaandretum aaandreto aaandretü ) ]);
form_ok('aaazir', ctanec('aaazir'), [ qw( aaadretu aaadreteu aaadrete aaadretum aaadreto aaadretü ) ]);

form_ok('dan', ctanec('dan'), [ qw( domai domei dome domam domo domu ) ]);
form_ok('kies', ctanec('kies'), [ qw( kaimai kaimei kaime kaimam kaimo kaimu ) ]);

# Test that syllables don't get added for CC where the second
# consonant is not 'l' or 'r'
form_ok('chamzan', ctanec('chamzan'), [ qw( chamzmai chamzmei chamzme chamzmam chamzmo chamzmu ) ]);

# I think 'fassec' should conjugate like this:
form_ok('fassec', ctanec('fassec'), [ qw( fasstao fassteo fasste fasstom fassto fasstu ) ]);
# and 'shushchan' like this:
form_ok('shushchan', ctanec('shushchan'), [ qw( shushmai shushmei shushme shushmam shushmo shushmu ) ]);
