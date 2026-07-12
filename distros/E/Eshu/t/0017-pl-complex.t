use strict;
use warnings;
use Test::More tests => 12;
use Eshu;

# Real-world: module boilerplate
{
	my $input = <<'END';
package My::Module;

use strict;
use warnings;

sub new {
my ($class, %args) = @_;
return bless {
name => $args{name} || 'default',
items => [],
}, $class;
}

sub add_item {
my ($self, $item) = @_;
push @{$self->{items}}, $item;
return $self;
}

1;
END

	my $expected = <<'END';
package My::Module;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
		name => $args{name} || 'default',
		items => [],
	}, $class;
}

sub add_item {
	my ($self, $item) = @_;
	push @{$self->{items}}, $item;
	return $self;
}

1;
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'module boilerplate');
}

# Real-world: eval/die
{
	my $input = <<'END';
sub safe_call {
my ($self, $code) = @_;
my $result = eval {
$code->();
};
if ($@) {
warn "Error: $@\n";
return;
}
return $result;
}
END

	my $expected = <<'END';
sub safe_call {
	my ($self, $code) = @_;
	my $result = eval {
		$code->();
	};
	if ($@) {
		warn "Error: $@\n";
		return;
	}
	return $result;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'eval/die pattern');
}

# Real-world: dispatch table
{
	my $input = <<'END';
my %dispatch = (
add => sub {
my ($a, $b) = @_;
return $a + $b;
},
sub => sub {
my ($a, $b) = @_;
return $a - $b;
},
);
END

	my $expected = <<'END';
my %dispatch = (
	add => sub {
		my ($a, $b) = @_;
		return $a + $b;
	},
	sub => sub {
		my ($a, $b) = @_;
		return $a - $b;
	},
);
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'dispatch table with anonymous subs');
}

# Real-world: mixed heredoc, regex, comment
{
	my $input = <<'END';
sub process {
my ($self, $input) = @_;
# strip comments
$input =~ s/#.*$//gm;
my $template = <<'TMPL';
Hello, {name}!
TMPL
if ($input =~ /^\s*$/) {
return $template;
}
return $input;
}
END

	my $expected = <<'END';
sub process {
	my ($self, $input) = @_;
	# strip comments
	$input =~ s/#.*$//gm;
	my $template = <<'TMPL';
Hello, {name}!
TMPL
	if ($input =~ /^\s*$/) {
		return $template;
	}
	return $input;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'mixed heredoc, regex, comment');
}

# Real-world: chained method calls
{
	my $input = <<'END';
sub build_query {
my ($self) = @_;
my $q = $self->schema->resultset('User')->search(
{
active => 1,
role => 'admin',
},
{
order_by => { -desc => 'created' },
rows => 10,
},
);
return $q;
}
END

	my $expected = <<'END';
sub build_query {
	my ($self) = @_;
	my $q = $self->schema->resultset('User')->search(
		{
			active => 1,
			role => 'admin',
		},
		{
			order_by => { -desc => 'created' },
			rows => 10,
		},
	);
	return $q;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'chained method calls with nested args');
}

# Explicit scalar deref ${$ref} — braces net zero, depth unaffected
{
	my $input = <<'END';
sub foo {
my $ref = \42;
my $val = ${$ref};
return $val;
}
END

	my $expected = <<'END';
sub foo {
	my $ref = \42;
	my $val = ${$ref};
	return $val;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'explicit scalar deref ${$ref}');
}

# Array deref @{$ref} — braces net zero
{
	my $input = <<'END';
sub foo {
my @copy = @{$self->{items}};
return \@copy;
}
END

	my $expected = <<'END';
sub foo {
	my @copy = @{$self->{items}};
	return \@copy;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'array deref @{$ref} does not corrupt depth');
}

# Statement modifier: if/unless do not open a block
{
	my $input = <<'END';
sub process {
my $x = get_value();
return undef if !defined $x;
return 0 if $x == 0;
return $x;
}
END

	my $expected = <<'END';
sub process {
	my $x = get_value();
	return undef if !defined $x;
	return 0 if $x == 0;
	return $x;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'statement modifiers do not open blocks');
}

# Statement modifiers: unless/while/until
{
	my $input = <<'END';
sub run {
do_step() unless $done;
redo() while !$finished;
my $x = 1;
}
END

	my $expected = <<'END';
sub run {
	do_step() unless $done;
	redo() while !$finished;
	my $x = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'unless/while statement modifiers do not open blocks');
}

# die with hashref object
{
	my $input = <<'END';
sub check {
my ($val) = @_;
die {
code => 400,
message => 'bad input',
value => $val,
} unless defined $val;
return $val;
}
END

	my $expected = <<'END';
sub check {
	my ($val) = @_;
	die {
		code => 400,
		message => 'bad input',
		value => $val,
	} unless defined $val;
	return $val;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'die with hashref object');
}

# Ternary operator spanning conditions
{
	my $input = <<'END';
sub label {
my ($n) = @_;
my $text = $n == 1
? 'one item'
: "$n items";
return $text;
}
END

	my $expected = <<'END';
sub label {
	my ($n) = @_;
	my $text = $n == 1
	? 'one item'
	: "$n items";
	return $text;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'ternary continuation lines at depth 1');
}

# Nested map/grep pipeline
{
	my $input = <<'END';
sub active_names {
my ($self) = @_;
return [
map { $_->{name} }
grep { $_->{active} }
@{$self->{users}}
];
}
END

	my $expected = <<'END';
sub active_names {
	my ($self) = @_;
	return [
		map { $_->{name} }
		grep { $_->{active} }
		@{$self->{users}}
	];
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'nested map/grep pipeline inside arrayref');
}
