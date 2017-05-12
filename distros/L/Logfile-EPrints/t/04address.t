use Test::More tests => 2;

use Logfile::EPrints;

my $str = 'localhost - - [03/May/2005:05:49:19 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 304 - "-" "htdig/3.1.6 (_wmaster@soton.ac.uk)"';

my $hit = Logfile::EPrints::Hit::Combined->new($str);

is($hit->hostname, 'localhost', 'hostname');
ok($hit->address =~ '127\.', 'address');

1;
