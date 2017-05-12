use Test;
BEGIN { plan tests => 2 };
ok(1);

use Lingua::LA::Stemmer;

ok( join( q//, qw(Loc natur era haec qu loc nostr castr delegera )),
  join q//, Lingua::LA::Stemmer::stem( qw(Loci natura erat haec quem
  locum nostri castris delegerant)));
