use Test::More tests => 8;

use strict;
use warnings;

use Iterator::Simple qw(list iterator);

{
	my $now = 0;
	my $itr = iterator {
		return if $now > 5;
		return $now++;
	};
	is_deeply list($itr), [0,1,2,3,4,5], 'list(iterator)';
}

{
	my @ary = ('dogs', 'cats','cow');
	is_deeply list(\@ary), ['dogs', 'cats', 'cow'], 'list(ARRAY REF)';
}

{
	is_deeply list(\*DATA), ["foo\n", "bar\n", "baz\n"], 'list(GLOB)';
}

{
	my $foo = Foo->new();
	is_deeply list($foo), ['hoge', 'hage'], 'list(@{} overloaded)';
}

{
	my $bar = Bar->new();
	is_deeply list($bar) , [0,1,2,3], 'list(__iter__ implemented)';
}

{
	my $baz = Baz->new();
	is_deeply list($baz) , [0,1,2,3,4,5], 'list(<> overloaded)';
}

{
	my $fiz = Fiz->new();
	is_deeply list($fiz) , [0,1,2,3,4,5,6,7], 'list(next implemented)';
}

{
	is_deeply list(), [], 'list()';
}

{
	package Foo;
	sub new { bless {i => 0}, $_[0]; }
	use overload (
		'@{}' => sub { [ 'hoge', 'hage'] },
	);
}

{
	package Bar;
	use Iterator::Simple qw(iterator);
	sub new { bless {i => 0}, $_[0]; }
	sub __iter__ {
		my($self) = @_;
		my $k = 0;
		iterator {
			return if $k > 3;
			return $k++;
		}
	}
}

{
	package Baz;
	sub new { bless {i => 0}, $_[0]; }
	use overload (
		'<>' => sub {
			my($self) = @_;
			return if $self->{i} > 5;
			return $self->{i}++;
		}
	);
}

{
	package Fiz;
	sub new { bless {i => 0}, $_[0]; }
	sub next {
		my($self) = @_;
		return if $self->{i} > 7;
		return $self->{i}++;
	}
}


__END__
foo
bar
baz
