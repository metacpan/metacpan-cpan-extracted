
use strict;
use warnings;
#########################

use Test::More tests => 73;
use_ok('Math::Symbolic');
use_ok('Math::Symbolic::Custom::Simplification');

my $data = join '', <DATA>;
my ($mysimp, $myosimp) = split /__SEPARATOR__/, $data;
eval $mysimp;
ok(!$@, 'mysimplification');
eval $myosimp;
ok(!$@, 'myothersimplification');

my $tree = Math::Symbolic::parse_from_string('a+a');
sub check_simp {
	my $tr = shift;
	my $type = shift;

	my $simp;
	eval {
		$simp = $tree->simplify();
	};
	ok(!$@, 'No fatal error simplifying');
	ok(ref($simp) =~ /^Math::Symbolic/, 'result is valid');
	if ($type eq 'same') {
		ok($tree->is_identical($simp), 'result eq original');
	}
	elsif ($type eq 'not same') {
		ok(!$tree->is_identical($simp)&&!$tree->is_simple_constant(),
		 'result ne original');
	}
	elsif ($type eq 'constant') {
		ok($simp->is_simple_constant(), 'result constant');
	}
}

# simple test
check_simp($tree, 'not same');

MySimplification->register();
check_simp($tree, 'same');

MySimplification->unregister();
check_simp($tree, 'not same');

# nested register same class
MySimplification->register();
check_simp($tree, 'same');

MySimplification->register();
check_simp($tree, 'same');

MySimplification->unregister();
check_simp($tree, 'same');

MySimplification->unregister();
check_simp($tree, 'not same');

# nested register different classes
MyOtherSimplification->register();
check_simp($tree, 'constant');

MyOtherSimplification->register();
check_simp($tree, 'constant');

MySimplification->register();
check_simp($tree, 'same');

MyOtherSimplification->register();
check_simp($tree, 'constant');

MyOtherSimplification->register();
check_simp($tree, 'constant');

MySimplification->unregister();
check_simp($tree, 'constant');

MyOtherSimplification->unregister();
check_simp($tree, 'not same');

# more nested classes
MySimplification->unregister();
MyOtherSimplification->unregister();
MyOtherSimplification->unregister();
MySimplification->unregister();
check_simp($tree, 'not same');

MyOtherSimplification->register();
check_simp($tree, 'constant');

MySimplification->register();
check_simp($tree, 'same');

MyOtherSimplification->register();
check_simp($tree, 'constant');

MySimplification->register();
check_simp($tree, 'same');

MySimplification->unregister();
check_simp($tree, 'constant');

MyOtherSimplification->unregister();
check_simp($tree, 'same');

MySimplification->unregister();
check_simp($tree, 'constant');

MySimplification->unregister();
check_simp($tree, 'not same');


__DATA__
package MySimplification;
use base 'Math::Symbolic::Custom::Simplification';
sub simplify {return $_[0]->new();}
1;
__SEPARATOR__
package MyOtherSimplification;
use base 'Math::Symbolic::Custom::Simplification';
sub simplify {return Math::Symbolic::parse_from_string('1');}
1;

