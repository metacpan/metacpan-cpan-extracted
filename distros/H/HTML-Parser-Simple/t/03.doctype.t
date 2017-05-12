use lib 't';

use Data;

use HTML::Parser::Simple;

use Test::More tests => 1;

# -----------------------

my($data)   = Data -> new;
my($html)   = $data -> read_file('t/data/03.doctype.html');
my($parser) = HTML::Parser::Simple -> new;

$parser -> parse($html);
$parser -> traverse($parser -> root);

ok($parser -> result() =~ m/DOCTYPE/, 'DOCTYPE is preserved');
