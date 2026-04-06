use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# $#array — last index of named array
{
	my $input = <<'END';
sub foo {
my $last = $#items;
return $last;
}
END

	my $expected = <<'END';
sub foo {
	my $last = $#items;
	return $last;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '$#array — last index operator');
}

# $#$arrayref — last index of array reference
{
	my $input = <<'END';
sub foo {
my $chapters = [1, 2, 3];
for my $i (1 .. $#$chapters) {
print "$i\n";
}
return;
}
END

	my $expected = <<'END';
sub foo {
	my $chapters = [1, 2, 3];
	for my $i (1 .. $#$chapters) {
		print "$i\n";
	}
	return;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '$#$arrayref — last index of deref');
}

# $#$ref inside map with closing brackets on same line
{
	my $input = <<'END';
my @items = (map {
$_ * 2
} 1 .. $#$chapters);
my $next = 1;
END

	my $expected = <<'END';
my @items = (map {
	$_ * 2
} 1 .. $#$chapters);
my $next = 1;
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '$#$ref with closing parens on same line');
}

# Chandra::EPUB-style nesting — subs after route blocks stay at correct depth
{
	my $input = <<'END';
sub run {
my ($self) = @_;
my $chapters = $self->{chapters};

$self->route('/toc' => sub {
my @items = (map {
my $i = $_;
{
tag => 'a',
href => "/chapter/$i",
};
} 1 .. $#$chapters);
return \@items;
});

for my $i (1 .. $#$chapters) {
$self->route("/chapter/$i" => sub {
return $chapters->[$i];
});
}

$self->run_app;
}

sub other_func {
return 1;
}
END

	my $expected = <<'END';
sub run {
	my ($self) = @_;
	my $chapters = $self->{chapters};

	$self->route('/toc' => sub {
		my @items = (map {
			my $i = $_;
			{
				tag => 'a',
				href => "/chapter/$i",
			};
		} 1 .. $#$chapters);
		return \@items;
	});

	for my $i (1 .. $#$chapters) {
		$self->route("/chapter/$i" => sub {
			return $chapters->[$i];
		});
	}

	$self->run_app;
}

sub other_func {
	return 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'route blocks with $#$ref — depth stays correct after');
}

# $#{$arrayref} — alternate syntax
{
	my $input = <<'END';
sub foo {
my $last = $#{$items};
return $last;
}
END

	my $expected = <<'END';
sub foo {
	my $last = $#{$items};
	return $last;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '$#{$ref} — braced last-index syntax');
}
