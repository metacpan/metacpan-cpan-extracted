use Test2::V0;
use Test2::Require::Module 'Marlin::X::Clone';

package Local::Foo {
	use Marlin::Antlers { x => ':Clone' };
	has "foo";
	has "bar";
}

my $x = Local::Foo->new( foo => 66, bar => 99 );
my $y = $x->clone( bar => 77 );

is $y->foo, 66;
is $y->bar, 77;

done_testing;
