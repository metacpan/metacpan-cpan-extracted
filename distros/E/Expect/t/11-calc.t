use strict;
use warnings;

use Test::More;

plan tests => 22;

use Expect;
my $e = Expect->new;

$e->spawn($^X, "examples/calc.pl") or die;

$e->log_stdout(0);
#$e->raw_pty(1);

is $e->match,  undef, 'match';
is $e->before, undef, 'before';
is $e->after,  undef, 'after';
is $e->get_accum, '', 'get_accum';


my $space;
{
	$e->send("19+23\n");
	my $exp = $e->expect(1, "19+23");
	is $exp, 1, 'expect';
	is $e->match, '19+23', 'match';
	is $e->before, '', 'before';
	my $SPACE = qr/\s*/;
	my $OUTPUT = qr/\s*Input: '19\+23' = '42' :Output\s*/;

	# This is very strange. It seems that the same system sometimes will have an almost empty 'after'
	# and in other cases thet will have an 'after' containing the the string returned by the AUT.
	# See for example the Travis reports of the Github repository.
	# https://travis-ci.org/szabgab/expect.pm/builds
	# between build 11 and 19
	# The same strange behaviour is also encountered on the CPAN Testers.
	like $e->after, qr/^($SPACE|$OUTPUT)$/, 'after';
	$space = $e->after =~ /^$SPACE$/;
	diag $space ? 'SPACE' : 'OUTPUT';
	my $ACCUM = $space ? $SPACE : $OUTPUT;
	like $e->clear_accum, qr/^$ACCUM$/, 'clear_accum';
}

SKIP: {
	skip 'Strange behavior on some of the systems', 4 if not $space;
	my $exp = $e->expect(1, '-re' => qr/'\d+'/);
	is $exp, 1, 'expect';
	is $e->match, q{'42'}, 'match';
	is $e->before, q{Input: '19+23' = }, 'before';
	like $e->after,  qr/^ :Output\s*$/,  'after';
}

{
	my $exp = $e->expect(1, 'abc');
	is $exp, undef, 'expect';
	is $e->match, undef, 'match';
	my $BEFORE = $space ? qr/^ :Output\s*$/ : qr/^$/;
	like $e->before, $BEFORE, 'before';
	is $e->after,  undef, 'after';
	like $e->clear_accum, $BEFORE, 'clear_accum';
}

{
	my $exp = $e->expect(1, 'xyz');
	is $exp, undef, 'expect';
	is $e->match, undef, 'match';
	is $e->before, '',  'before';    #??
	is $e->after,  undef, 'after';
}


$e->close;

# These tests faled on midnightbsd, and on almost all cases of gnukfreebsd
# http://www.cpantesters.org/cpan/report/fb542c9a-3253-11e4-a396-829772410e08
# one was successful though.
# On netbased failed on all except this one:
# http://www.cpantesters.org/cpan/report/fd895392-2bbd-11e4-b698-db7a2867dcfa
