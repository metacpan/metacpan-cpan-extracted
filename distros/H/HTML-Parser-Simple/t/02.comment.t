use lib 't';

use Data;

use HTML::Parser::Simple;

use Test::More tests => 1;

# ------------------------

my($data)   = Data -> new;
my($html)   = $data -> read_file('t/data/02.comment.html');
my($parser) = HTML::Parser::Simple -> new;

$parser -> parse($html);
$parser -> traverse($parser -> root);

ok($parser -> result() =~ /Comment/, 'Comments are preserved');
