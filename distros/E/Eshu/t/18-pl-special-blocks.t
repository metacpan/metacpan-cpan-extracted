use strict;
use warnings;
use Test::More tests => 7;
use Eshu;

# BEGIN block
{
	my $input = <<'END';
BEGIN {
require 'config.pl';
$VERSION = '1.0';
}

sub foo {
return 1;
}
END

	my $expected = <<'END';
BEGIN {
	require 'config.pl';
	$VERSION = '1.0';
}

sub foo {
	return 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'BEGIN block');
}

# END block
{
	my $input = <<'ETEST';
END {
cleanup();
log_shutdown();
}

sub bar {
return 2;
}
ETEST

	my $expected = <<'ETEST';
END {
	cleanup();
	log_shutdown();
}

sub bar {
	return 2;
}
ETEST

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'END block');
}

# INIT block
{
	my $input = <<'END';
INIT {
setup_db();
}

sub baz {
return 3;
}
END

	my $expected = <<'END';
INIT {
	setup_db();
}

sub baz {
	return 3;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'INIT block');
}

# CHECK block
{
	my $input = <<'END';
CHECK {
verify_config();
}

sub qux {
return 4;
}
END

	my $expected = <<'END';
CHECK {
	verify_config();
}

sub qux {
	return 4;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'CHECK block');
}

# Multiple special blocks
{
	my $input = <<'ETEST';
BEGIN {
use Config;
}

INIT {
connect_db();
}

END {
disconnect_db();
}
ETEST

	my $expected = <<'ETEST';
BEGIN {
	use Config;
}

INIT {
	connect_db();
}

END {
	disconnect_db();
}
ETEST

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multiple special blocks');
}

# DESTROY method in class
{
	my $input = <<'END';
package My::Object;

sub new {
my ($class) = @_;
return bless {}, $class;
}

sub DESTROY {
my ($self) = @_;
$self->cleanup();
}
END

	my $expected = <<'END';
package My::Object;

sub new {
	my ($class) = @_;
	return bless {}, $class;
}

sub DESTROY {
	my ($self) = @_;
	$self->cleanup();
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'DESTROY method in class');
}

# BEGIN with nested code
{
	my $input = <<'END';
BEGIN {
if ($ENV{DEBUG}) {
$debug = 1;
}
my @mods = qw(Foo Bar);
for my $m (@mods) {
require $m;
}
}
END

	my $expected = <<'END';
BEGIN {
	if ($ENV{DEBUG}) {
		$debug = 1;
	}
	my @mods = qw(Foo Bar);
	for my $m (@mods) {
		require $m;
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'BEGIN block with nested code');
}
