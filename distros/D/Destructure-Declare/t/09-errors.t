use strict;
use warnings;
use Test::More;

# Each construct is a compile-time error; check via string eval under the pragma.
sub compile_err {
	my ($code) = @_;
	local $@;
	my $ok = eval "use Destructure::Declare; $code; 1";
	return $ok ? '' : "$@";
}

like(compile_err('let [$a, @r, $b] = [1,2,3]'),
	qr/slurpy.*must be the last/, 'slurpy not last');

like(compile_err('let [$a $b] = [1]'),
	qr/expected ',' or/, 'missing comma between elements');

like(compile_err('let {foo $x} = {}'),
	qr/expected '=>'/, 'hash key without fat comma');

like(compile_err('let 42 = [1]'),
	qr/expected '\[', '\{' or '\('/, 'non-pattern after let');

like(compile_err('let [$a] [1]'),
	qr/expected '='/, 'missing = before RHS');

# the pragma is lexical: without it, `let` is not our keyword
{
	local $@;
	my $ok = eval 'no Destructure::Declare; let [$z] = [1]; 1';
	ok(!$ok, 'let inactive without the pragma in scope');
}

done_testing;
