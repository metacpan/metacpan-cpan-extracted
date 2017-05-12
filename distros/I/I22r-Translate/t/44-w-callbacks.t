use I22r::Translate;
use Test::More;
use lib 't';

# exercise I22r::Translate with a trivial backend

my ($I,$J,$K) = (0,0,"");

sub cb1 { shift; $I += length($_[0]->otext); $K .= "A" }
sub cb2 { shift; $J += $I; $I = 5; $K .= "B" };
sub cb3 { shift; $J -= length($_[0]->otext); $K .= "C" }

I22r::Translate->config(
    callback => \&cb1,
    'Test::Backend::Reverser' => {
	ENABLED => 1,
	callback => \&cb2,
    }
);

my $r = I22r::Translate->translate_string(
    src => 'en', dest => 'ko', text => 'some unprotected text',
    callback => \&cb3 );
ok( $r, 'translate_string: got result');

# expect cb3 to be called first, then cb2, then cb1
# cb3: $J = -21; $K = -1
# cb2: $J = -21; $I = 5; $K = -2
# cb1: $J = -21; $I = 26; $K = -1
our $diag = 0;
ok( $K eq 'CBA', 'global callback invoked last' ) or $diag++;
ok( $I == 26, 'backend callback invoked second' ) or $diag++;
ok( $J == -21, 'req callback invoked first' ) or $diag++;
if ($diag) {
   diag $I, $J, $K
}

done_testing();

