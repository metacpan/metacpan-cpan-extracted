use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# struct type definition
{
	my $input = <<'END';
type Point struct {
X float64
Y float64
}
END
	my $expected = <<'END';
type Point struct {
	X float64
	Y float64
}
END
	is(go($input), $expected, 'struct type definition');
}

# struct literal
{
	my $input = <<'END';
func f() {
p := Point{
X: 1.0,
Y: 2.0,
}
_ = p
}
END
	my $expected = <<'END';
func f() {
	p := Point{
		X: 1.0,
		Y: 2.0,
	}
	_ = p
}
END
	is(go($input), $expected, 'struct literal with trailing comma');
}

# embedded struct
{
	my $input = <<'END';
type Animal struct {
Name string
}

type Dog struct {
Animal
Breed string
}
END
	my $expected = <<'END';
type Animal struct {
	Name string
}

type Dog struct {
	Animal
	Breed string
}
END
	is(go($input), $expected, 'embedded struct');
}

# nested struct literal
{
	my $input = <<'END';
func f() {
cfg := Config{
Server: ServerConfig{
Host: "localhost",
Port: 8080,
},
}
return cfg
}
END
	my $expected = <<'END';
func f() {
	cfg := Config{
		Server: ServerConfig{
			Host: "localhost",
			Port: 8080,
		},
	}
	return cfg
}
END
	is(go($input), $expected, 'nested struct literal');
}

done_testing;
