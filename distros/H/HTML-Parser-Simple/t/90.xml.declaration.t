use lib 't';

use Data;

use HTML::Parser::Simple;

use Test::More tests => 1;

# ------------------------

my($data)   = Data -> new;
my($html)   = $data -> read_file('t/data/90.xml.declaration.xhtml');
my($parser) = HTML::Parser::Simple -> new(xhtml => 1);

$parser -> parse($html);
$parser -> traverse($parser -> root);

ok($parser -> result() =~ m/..xml.+?version.+?encoding/, 'XML declaration is preserved');
