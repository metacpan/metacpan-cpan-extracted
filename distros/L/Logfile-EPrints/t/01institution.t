use Test::More tests => 2;

use Logfile::EPrints;
use_ok('Logfile::EPrints::Institution');

my $str = '152.78.128.117 - - [03/May/2005:05:49:19 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 304 - "-" "htdig/3.1.6 (_wmaster@soton.ac.uk)"';

my $hit = Logfile::EPrints::Hit::Combined->new($str);
$hit = Logfile::EPrints::Institution->new(
	handler=>Handler->new()
)->fulltext($hit);

ok($hit->homepage eq 'http://www.soton.ac.uk/');

package Handler;

sub new { bless {}, shift }

sub AUTOLOAD { pop @_ }

1;
