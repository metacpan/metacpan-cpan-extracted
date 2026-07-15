use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# simple switch
{
	my $input = <<'END';
func f(x int) string {
switch x {
case 1:
return "one"
case 2:
return "two"
default:
return "other"
}
}
END
	my $expected = <<'END';
func f(x int) string {
	switch x {
	case 1:
		return "one"
	case 2:
		return "two"
	default:
		return "other"
	}
}
END
	is(go($input), $expected, 'switch with case/default');
}

# fallthrough
{
	my $input = <<'END';
func f(x int) {
switch x {
case 1:
fmt.Println("one")
fallthrough
case 2:
fmt.Println("one or two")
}
}
END
	my $expected = <<'END';
func f(x int) {
	switch x {
	case 1:
		fmt.Println("one")
		fallthrough
	case 2:
		fmt.Println("one or two")
	}
}
END
	is(go($input), $expected, 'switch with fallthrough keyword');
}

# type switch
{
	my $input = <<'END';
func describe(i interface{}) {
switch v := i.(type) {
case int:
fmt.Printf("int %d\n", v)
case string:
fmt.Printf("string %q\n", v)
default:
fmt.Printf("unknown %T\n", v)
}
}
END
	my $expected = <<'END';
func describe(i interface{}) {
	switch v := i.(type) {
	case int:
		fmt.Printf("int %d\n", v)
	case string:
		fmt.Printf("string %q\n", v)
	default:
		fmt.Printf("unknown %T\n", v)
	}
}
END
	is(go($input), $expected, 'type switch');
}

# switch inside for
{
	my $input = <<'END';
func f(nums []int) {
for _, n := range nums {
switch {
case n < 0:
fmt.Println("neg")
case n > 0:
fmt.Println("pos")
default:
fmt.Println("zero")
}
}
}
END
	my $expected = <<'END';
func f(nums []int) {
	for _, n := range nums {
		switch {
		case n < 0:
			fmt.Println("neg")
		case n > 0:
			fmt.Println("pos")
		default:
			fmt.Println("zero")
		}
	}
}
END
	is(go($input), $expected, 'switch inside for loop (nested case indentation)');
}

done_testing;
