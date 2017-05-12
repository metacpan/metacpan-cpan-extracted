#!perl -w
use strict;
use Benchmark qw(:all);

BEGIN{
	package M;
	use Mouse;

	has foo => (
		is => 'rw',
	);
	has bar => (
		is => 'rw',
	);
	has baz => (
		is => 'rw',
	);
	__PACKAGE__->meta->make_immutable;
}
BEGIN{
	package HF;
	use Hash::FieldHash qw(:all);

	fieldhash my %foo => 'foo';
	fieldhash my %bar => 'bar';
	fieldhash my %baz => 'baz';
	sub new{ my $o; bless \$o, shift }

#	sub new{
#		my $class = shift;
#		my $self  = bless do{ \my $o }, $class;
#		return Hash::FieldHash::from_hash($self, @_);
#	}
}
BEGIN{
	package HUF;
	use Hash::Util::FieldHash::Compat qw(:all);
	fieldhashes \my(%foo, %bar, %baz);

	sub new{ my $o; bless \$o, shift }

	sub foo{
		@_ > 1 ? ($foo{$_[0]} = $_[1]) : $foo{$_[0]}
	}
	sub bar{
		@_ > 1 ? ($bar{$_[0]} = $_[1]) : $bar{$_[0]}
	}
	sub baz{
		@_ > 1 ? ($baz{$_[0]} = $_[1]) : $baz{$_[0]}
	}
}
printf "Perl %vd on $^O\n", $^V;

foreach my $count(1, 100){
	print "new, and access(read:write 11:3)*$count\n";
	cmpthese timethese -1 => {
		'H::F' => sub{
			my $o = HF->new();
			for(1 .. $count){
				$o->foo($_);
				$o->bar($o->foo + $o->foo + $o->foo + $o->foo + $o->foo);
				$o->baz($o->bar + $o->bar + $o->bar + $o->bar + $o->bar);
				$o->baz == ($_ * 5 * 5) or die $o->baz;
			}
		},
		'H::U::F' => sub{
			my $o = HUF->new();
			for(1 .. $count){
				$o->foo($_);
				$o->bar($o->foo + $o->foo + $o->foo + $o->foo + $o->foo);
				$o->baz($o->bar + $o->bar + $o->bar + $o->bar + $o->bar);
				$o->baz == ($_ * 5 * 5) or die $o->baz;
			}
		},
		'Mouse' => sub{
			my $o = M->new();
			for(1 .. $count){
				$o->foo($_);
				$o->bar($o->foo + $o->foo + $o->foo + $o->foo + $o->foo);
				$o->baz($o->bar + $o->bar + $o->bar + $o->bar + $o->bar);
				$o->baz == ($_ * 5 * 5) or die $o->baz;
			}
		},
	};
}
