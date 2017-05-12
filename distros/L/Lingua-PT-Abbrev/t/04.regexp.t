# -*- cperl -*-

use Test::More tests => 4;
use Lingua::PT::Abbrev;

my $dic = Lingua::PT::Abbrev->new;


my $re = $dic->regexp;
like("av.",qr/$re/);
like("sr.",qr/$re/);
like("sra.",qr/$re/);
like("dr.",qr/$re/);
