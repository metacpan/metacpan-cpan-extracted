# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 132;
use Carp;

use Lingua::Zompist::Verdurian 'epesec';

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

form_ok('lelen', epesec('lelen'), [ qw( lelcelai lelcelei lelcele lelcelam lelcelo lelcelu ) ]);
form_ok('badhir', epesec('badhir'), [ qw( badhcelu badhceleu badhcele badhcelum badhcelo badhcelü ) ]);
form_ok('elirec', epesec('elirec'), [ qw( elircelao elirceleo elircele elircelom elircelo elircelu ) ]);

form_ok('esan', epesec('esan'), [ qw( eshelai eshelei eshele eshelam eshelo eshelu ) ]);

# test the general replacements
form_ok('aaacan', epesec('aaacan'), [ qw( aaascelai aaascelei aaascele aaascelam aaascelo aaascelu ) ]);
form_ok('aaachan', epesec('aaachan'), [ qw( aaashcelai aaashcelei aaashcele aaashcelam aaashcelo aaashcelu ) ]);
form_ok('aaaman', epesec('aaaman'), [ qw( aaancelai aaancelei aaancele aaancelam aaancelo aaancelu ) ]);
form_ok('aaasan', epesec('aaasan'), [ qw( aaashelai aaashelei aaashele aaashelam aaashelo aaashelu ) ]);
form_ok('aaazan', epesec('aaazan'), [ qw( aaazhelai aaazhelei aaazhele aaazhelam aaazhelo aaazhelu ) ]);

form_ok('aaacir', epesec('aaacir'), [ qw( aaascelu aaasceleu aaascele aaascelum aaascelo aaascelü ) ]);
form_ok('aaachir', epesec('aaachir'), [ qw( aaashcelu aaashceleu aaashcele aaashcelum aaashcelo aaashcelü ) ]);
form_ok('aaamir', epesec('aaamir'), [ qw( aaancelu aaanceleu aaancele aaancelum aaancelo aaancelü ) ]);
form_ok('aaasir', epesec('aaasir'), [ qw( aaashelu aaasheleu aaashele aaashelum aaashelo aaashelü ) ]);
form_ok('aaazir', epesec('aaazir'), [ qw( aaazhelu aaazheleu aaazhele aaazhelum aaazhelo aaazhelü ) ]);

form_ok('aaacec', epesec('aaacec'), [ qw( aaascelao aaasceleo aaascele aaascelom aaascelo aaascelu ) ]);
form_ok('aaachec', epesec('aaachec'), [ qw( aaashcelao aaashceleo aaashcele aaashcelom aaashcelo aaashcelu ) ]);
form_ok('aaamec', epesec('aaamec'), [ qw( aaancelao aaanceleo aaancele aaancelom aaancelo aaancelu ) ]);
form_ok('aaasec', epesec('aaasec'), [ qw( aaashelao aaasheleo aaashele aaashelom aaashelo aaashelu ) ]);
form_ok('aaazec', epesec('aaazec'), [ qw( aaazhelao aaazheleo aaazhele aaazhelom aaazhelo aaazhelu ) ]);

form_ok('dan', epesec('dan'), [ qw( doncelai doncelei doncele doncelam doncelo doncelu ) ]);
form_ok('kies', epesec('kies'), [ qw( keshelai keshelei keshele keshelam keshelo keshelu ) ]);

# I think 'fassec' should conjugate like this:
form_ok('fassec', epesec('fassec'), [ qw( fashshelao fashsheleo fashshele fashshelom fashshelo fashshelu ) ]);
