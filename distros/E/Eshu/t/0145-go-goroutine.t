use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# anonymous goroutine
{
	my $input = <<'END';
func f() {
go func() {
fmt.Println("goroutine")
}()
fmt.Println("main")
}
END
	my $expected = <<'END';
func f() {
	go func() {
		fmt.Println("goroutine")
	}()
	fmt.Println("main")
}
END
	is(go($input), $expected, 'anonymous goroutine func(){}()');
}

# goroutine with channel
{
	my $input = <<'END';
func f() {
ch := make(chan int)
go func() {
ch <- 42
}()
v := <-ch
fmt.Println(v)
}
END
	my $expected = <<'END';
func f() {
	ch := make(chan int)
	go func() {
		ch <- 42
	}()
	v := <-ch
	fmt.Println(v)
}
END
	is(go($input), $expected, 'goroutine with channel send');
}

# select statement
{
	my $input = <<'END';
func f(ch1, ch2 <-chan int) {
select {
case v := <-ch1:
fmt.Println("ch1", v)
case v := <-ch2:
fmt.Println("ch2", v)
default:
fmt.Println("none")
}
}
END
	my $expected = <<'END';
func f(ch1, ch2 <-chan int) {
	select {
	case v := <-ch1:
		fmt.Println("ch1", v)
	case v := <-ch2:
		fmt.Println("ch2", v)
	default:
		fmt.Println("none")
	}
}
END
	is(go($input), $expected, 'select with channel cases');
}

done_testing;
