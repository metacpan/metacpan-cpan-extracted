use strict;
use warnings;
use Test::More tests => 5;
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
