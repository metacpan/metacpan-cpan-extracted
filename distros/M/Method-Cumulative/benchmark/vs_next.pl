#!perl -w
use strict;
use Benchmark qw(:all);

BEGIN{ require MRO::Compat if $] < 5.010 }
{
	package A;
	use Mouse;

	sub mc{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}

	sub mn{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}

	sub mx{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}

	package B;
	use Mouse;
	use parent qw(Method::Cumulative);

	extends qw(A);

	sub mc :CUMULATIVE{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}

	sub mn{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		$self->next::method($init);
		return;
	}

	before mx => \&_mx;
	sub _mx{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}


	package C;
	use Mouse;
	use parent qw(Method::Cumulative);

	extends qw(A);

	sub mc :CUMULATIVE{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}

	sub mn{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		$self->next::method($init);
		return;
	}

	before mx => \&_mx;
	sub _mx{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}


	package D;
	use Mouse;
	use parent qw(Method::Cumulative);
	use mro 'c3';

	extends qw(C B);

	sub mc :CUMULATIVE{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}

	sub mn{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		$self->next::method($init);
		return;
	}

	before mx => \&_mx;
	sub _mx{
		my($self, $init) = @_;
		my $sum = $init;
		for my $i(1 .. 10){
			$sum += $i;
		}
		return;
	}

	#__PACKAGE__->meta->make_immutable();
}

print "Benchmark: CUMULATIVE, next::method and Mouse::before\n";

cmpthese -1 => {
	cumulative => sub{
		my $x = D->new();
		# method call * 10
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
		$x->mc(42);
	},
	'next::method' => sub{
		my $x = D->new();
		# method call * 10
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
		$x->mn(42);
	},
	'before' => sub{
		my $x = D->new();
		# method call * 10
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
		$x->mx(42);
	},
};
