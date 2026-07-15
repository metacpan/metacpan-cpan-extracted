use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# func body
{
	my $input = <<'END';
func main() {
fmt.Println("hello")
}
END
	my $expected = <<'END';
func main() {
	fmt.Println("hello")
}
END
	is(go($input), $expected, 'func body indented');
}

# if/else
{
	my $input = <<'END';
func f() {
if x > 0 {
fmt.Println("positive")
} else {
fmt.Println("negative")
}
}
END
	my $expected = <<'END';
func f() {
	if x > 0 {
		fmt.Println("positive")
	} else {
		fmt.Println("negative")
	}
}
END
	is(go($input), $expected, 'if/else block indentation');
}

# for loop
{
	my $input = <<'END';
func f() {
for i := 0; i < 10; i++ {
fmt.Println(i)
}
}
END
	my $expected = <<'END';
func f() {
	for i := 0; i < 10; i++ {
		fmt.Println(i)
	}
}
END
	is(go($input), $expected, 'for loop indentation');
}

# switch
{
	my $input = <<'END';
func describe(x int) {
switch x {
case 1:
fmt.Println("one")
case 2:
fmt.Println("two")
default:
fmt.Println("other")
}
}
END
	my $expected = <<'END';
func describe(x int) {
	switch x {
	case 1:
		fmt.Println("one")
	case 2:
		fmt.Println("two")
	default:
		fmt.Println("other")
	}
}
END
	is(go($input), $expected, 'switch/case indentation');
}

# nested struct and method
{
	my $input = <<'END';
type Server struct {
host string
port int
}

func (s *Server) Start() error {
if s.port == 0 {
return errors.New("no port")
}
return nil
}
END
	my $expected = <<'END';
type Server struct {
	host string
	port int
}

func (s *Server) Start() error {
	if s.port == 0 {
		return errors.New("no port")
	}
	return nil
}
END
	is(go($input), $expected, 'struct definition and method');
}

# idempotent
{
	my $src = <<'END';
func main() {
	if true {
		fmt.Println("yes")
	}
}
END
	is(go($src), $src, 'idempotent on already-correct input');
}

# spaces mode
{
	my $input = <<'END';
func f() {
x := 1
}
END
	my $expected = <<'END';
func f() {
    x := 1
}
END
	is(Eshu->indent_go($input, indent_char => ' ', indent_width => 4),
	   $expected, 'spaces indentation mode');
}

done_testing;
