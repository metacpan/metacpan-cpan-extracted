use strict;
use warnings;
use Test::More tests => 8;
use Eshu;

# //= (defined-or assignment) must not be treated as regex
{
	my $input = <<'END';
sub fullscreen {
my ($self, $enable) = @_;
$enable //= 1;
$self->{_webview}->set_fullscreen($enable);
return $self;
}
END

	my $expected = <<'END';
sub fullscreen {
	my ($self, $enable) = @_;
	$enable //= 1;
	$self->{_webview}->set_fullscreen($enable);
	return $self;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '//= does not break indentation');
}

# // (defined-or) as expression
{
	my $input = <<'END';
sub test {
my $val = $x // $y;
my $next = 1;
return $next;
}
END

	my $expected = <<'END';
sub test {
	my $val = $x // $y;
	my $next = 1;
	return $next;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '// operator does not break indentation');
}

# //= with complex RHS
{
	my $input = <<'END';
sub watch {
my ($self, $path, $callback) = @_;
require Chandra::HotReload;
$self->{_hot_reload} //= Chandra::HotReload->new;
$self->{_hot_reload}->watch($path, $callback);
return $self;
}
END

	my $expected = <<'END';
sub watch {
	my ($self, $path, $callback) = @_;
	require Chandra::HotReload;
	$self->{_hot_reload} //= Chandra::HotReload->new;
	$self->{_hot_reload}->watch($path, $callback);
	return $self;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '//= with method call RHS');
}

# Multiple //= in one sub
{
	my $input = <<'END';
sub defaults {
my ($self, %args) = @_;
$args{width} //= 800;
$args{height} //= 600;
$args{title} //= 'Untitled';
return \%args;
}
END

	my $expected = <<'END';
sub defaults {
	my ($self, %args) = @_;
	$args{width} //= 800;
	$args{height} //= 600;
	$args{title} //= 'Untitled';
	return \%args;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multiple //= in one sub');
}

# // in ternary-like context
{
	my $input = <<'END';
my $blocking = $self->{_hot_reload} ? 0 : 1;
my $val = $x // 'default';
if ($val) {
print "ok\n";
}
END

	my $expected = <<'END';
my $blocking = $self->{_hot_reload} ? 0 : 1;
my $val = $x // 'default';
if ($val) {
	print "ok\n";
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '// in expression context');
}

# //= inside nested blocks
{
	my $input = <<'END';
sub run {
my ($self) = @_;
if ($self->{active}) {
$self->{count} //= 0;
$self->{count}++;
if ($self->{count} > 10) {
$self->{limit} //= 100;
return;
}
}
return $self;
}
END

	my $expected = <<'END';
sub run {
	my ($self) = @_;
	if ($self->{active}) {
		$self->{count} //= 0;
		$self->{count}++;
		if ($self->{count} > 10) {
			$self->{limit} //= 100;
			return;
		}
	}
	return $self;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '//= inside nested blocks');
}

# Actual regex after // operator (no confusion)
{
	my $input = <<'END';
my $x = $val // $default;
if ($x =~ /foo/) {
print "matched\n";
}
END

	my $expected = <<'END';
my $x = $val // $default;
if ($x =~ /foo/) {
	print "matched\n";
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'regex after // operator is handled correctly');
}

# Idempotency with //=
{
	my $input = <<'END';
sub set_color {
	my ($self, $r, $g, $b, $a) = @_;
	$a //= 255;
	$self->{_webview}->set_color($r, $g, $b, $a);
	return $self;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $input, '//= idempotent when already indented');
}
