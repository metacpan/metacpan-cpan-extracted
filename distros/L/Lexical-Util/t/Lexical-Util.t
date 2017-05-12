##==============================================================================
## Lexical-Util.t - test code for Lexical::Util
##==============================================================================
## $Id: Lexical-Util.t,v 1.3 2004/07/29 02:47:14 kevin Exp $
##==============================================================================
use strict;
use Test;
BEGIN { plan tests => 14 };
use Lexical::Util qw(lexalias frame_to_cvref lexical_alias ref_to_lexical);
ok(1); # If we made it this far, we're ok.

sub basic {
	my ($one, $two, $three, $four, $six);
	my $cv = frame_to_cvref(0);
	lexalias($cv, '$one', \$_[0]);
	lexalias($cv, '$two', \$_[1]);
	lexalias($cv, '$three', \$_[2]);
	my $msg = lexical_alias($cv, '$four', 0);
	ok($msg eq 'for variable $four, invalid reference passed to lexical_alias');
	$msg = lexical_alias($cv, '$five', \$_[3]);
	ok($msg eq 'variable $five not found in lexical_alias');
	$msg = lexical_alias($cv, '$six', \$_[4]);
	ok(!defined $msg);
	ok($six == 5);
	$six = 6;
	ok($_[4] == 6);

	ok($one == 1 && $two == 2 && $three == 3);
	$one = 'one';
	ok($_[0] eq 'one');

	$four = 4;
	test_ref_lexical(\$four);
}

sub test_ref_lexical {
	my ($lexref) = @_;
	my $cv = frame_to_cvref(1);
	my $rv = ref_to_lexical($cv, '$four');
	ok($lexref eq $rv);
	ok($$rv == 4);
}

my @args = qw/1 2 3 4 5 6/;

basic(@args);

ok($args[0] eq 'one');
ok($args[1] == 2);

my $four = 4;
my $afour;

my $cv = frame_to_cvref(0);
lexalias($cv, '$afour', \$four);

ok($afour == 4);
$afour = 'four';
ok($four eq 'four');
