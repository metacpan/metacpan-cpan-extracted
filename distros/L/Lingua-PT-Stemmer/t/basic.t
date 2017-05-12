use Test;
BEGIN { plan tests => 12 };
use Lingua::PT::Stemmer;
use Lingua::GL::Stemmer;

##########################################################################
@ptword = Lingua::PT::Stemmer::stem(qw(bons chilena pezinho 
				    existencialista beberiam));
@ptstem = qw(bom chilen pe exist beb);

ok(1);
ok($ptword[$_], $ptstem[$_]) for (0..$#ptword);


##########################################################################
@glword = Lingua::GL::Stemmer::stem(qw(bons chilena cazola
				  preconceituoso chegou));
@glstem = qw(bon chilen caz preconceit cheg);

ok(1);
ok($glword[$_], $glstem[$_]) for (0..$#glword);
