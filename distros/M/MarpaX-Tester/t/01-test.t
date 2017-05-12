#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use MarpaX::Tester;

plan tests => 17;

# Test a couple of bad ones first.

my $t = MarpaX::Tester->new(<<'END_OF_SOURCE');
:default ::= action => [name,values]
:start ::= exp

exp ::= op number*
op ~ [\w]+
number ~ [\d]+

END_OF_SOURCE

my $r = $t->result;
is ($r->{status}, 0);
is ($t->status, 0);
like ($r->{error}, qr/No lexemes accepted/);


# Test a good one (from the syntax point of view).
$t = MarpaX::Tester->new(<<'END_OF_SOURCE');
:default ::= action => [name,values]
lexeme default = latm => 1
:start ::= exp

exp ::= op number
op ::= [\w]+
number ::= [\d]+

END_OF_SOURCE

is ($t->status, 1);

# Now test some things against that.

$r = $t->test ('lk23');
is (ref($r->{result}), 'HASH');
is ($r->{result}->{test}, 'lk23');
is ($r->{result}->{status}, 1);
like ($r->{result}->{parse}, qr/'exp'/); # Lame. It's late.
my $result = $r->{result}->{parse_val};
is_deeply ($$result,   # Have to dereference it...
  ['exp', ['op', 'l', 'k'], ['number', '2', '3']]);

is_deeply ($r, $t->result);

# Test an array, one of which will fail.

$r = $t->test (['jj1', '1qq']);

is (ref($r->{result}), 'ARRAY');
is ($r->{result}->[0]->{test}, 'jj1');
is ($r->{result}->[0]->{status}, 1);
is ($r->{result}->[1]->{test}, '1qq');
is ($r->{result}->[1]->{status}, 0);
is ($r->{result}->[1]->{parse}, '$VAR1 = undef;' . "\n");
is ($r->{result}->[1]->{parse_val}, undef);

#diag Dumper($r);


#done_testing;