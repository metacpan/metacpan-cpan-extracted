#!perl

# $Id: Iterator-Simple-Lookahead.t,v 1.2 2013/07/19 20:06:03 Paulo Exp $

use strict;
use warnings;

use Test::More;
use Iterator::Simple 'iter';

use_ok 'Iterator::Simple::Lookahead';

# compute with: perl -MMath::Prime::Util=primes -e "@p=(1,@{primes(1000)}); print qq(@p\n)"
my @primes = qw(
1 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 
101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179 181 191 
193 197 199 211 223 227 229 233 239 241 251 257 263 269 271 277 281 283 
293 307 311 313 317 331 337 347 349 353 359 367 373 379 383 389 397 401 
409 419 421 431 433 439 443 449 457 461 463 467 479 487 491 499 503 509 
521 523 541 547 557 563 569 571 577 587 593 599 601 607 613 617 619 631 
641 643 647 653 659 661 673 677 683 691 701 709 719 727 733 739 743 751 
757 761 769 773 787 797 809 811 821 823 827 829 839 853 857 859 863 877 
881 883 887 907 911 919 929 937 941 947 953 967 971 977 983 991 997 
);

my $s;

#------------------------------------------------------------------------------
sub t_get (@) {
	my $where = "[line ".(caller)[2]."]";
	for (@_) {
		is $s->peek,     $_, "$where peek is ".($_||"undef");
		is $s->next,     $_, "$where next is ".($_||"undef");
		$s->unget($_);
		is $s->(),       $_, "$where ()   is ".($_||"undef");
		$s->unget($_);
		is scalar(<$s>), $_, "$where <>   is ".($_||"undef");
	}
}

sub t_new (@) {
	my $obj;
	isa_ok $obj = Iterator::Simple::Lookahead->new(@_), 'Iterator::Simple::Lookahead';
	return $obj;
}	

sub array_iter {
	my(@d) = @_;
	return sub { shift @d; };
}

#------------------------------------------------------------------------------
# new without arguments
{
	$s = t_new();
	t_get 	undef, undef;
	$s->unget(1..3);
	t_get 	1, 2, 3, undef, undef;
}

#------------------------------------------------------------------------------
# new with arguments
{
	my $n;
	$s = t_new(
			undef,
			1..3,
			undef,
			array_iter(4..6),
			iter( [7..9] ),
			sub {
				$n++;
				return array_iter(10..12) if $n == 1;
				return array_iter(13..15) if $n == 2;
				return;
			},
			undef,
	);
	t_get 	1;
	$s->unget(10..12, array_iter(13..15));
	t_get 	10..15,2..15, undef, undef;
}

#------------------------------------------------------------------------------
# unget from within the iterator
{
	my @d1 = (4..6);

	$s = t_new(
			sub {
				my $ret = shift @d1; 
				if ($ret && $ret == 5) {
					$s->unget(1..3);
				}
				return $ret;
			},
	);
	t_get 	4, 5, 1, 2, 3, 6, undef, undef;
}

#------------------------------------------------------------------------------
# return iterator from within the iterator
{
	my @d1 = (4..6);

	$s = t_new(
			sub {
				my $ret = shift @d1; 
				if ($ret && $ret == 5) {
					return iter([1..3, $ret]);
				}
				return $ret;
			},
	);
	t_get 	4, 1, 2, 3, 5, 6, undef, undef;
}

#------------------------------------------------------------------------------
# peek
{
	$s = t_new( array_iter(0..10000) );
	for (0..10000) {
		is $s->peek($_), $_, "peek $_";
	}
	for (10001..10011) {
		is $s->peek($_), undef, "peek $_";
	}
	t_get 	0..10000, undef, undef;

	eval {$s->peek(-1)}; 
	like $@, qr/negative index/, "croak on negative peek";
}

#------------------------------------------------------------------------------
# stream of []
{
	$s = t_new( [1,1], [2,4], [3,9] );
	for (1..3) {
		is_deeply $s->(), [$_,$_*$_], "next [$_,$_*$_]";
	}
	t_get undef, undef;
}

#------------------------------------------------------------------------------
# subclass of Iterator::Simple::Iterator
{
	my @not_prime;
	my $max = $primes[-1];
	$s = t_new( array_iter( 1..$max ) ) |
			sub { 
				return 1 if $_ == 1;
				for (my $i = 2*$_; $i < $max; $i += $_) {
					$not_prime[$i]++;
				}
				return $_;
			} |
			sub {
				return if $not_prime[$_];
				return $_;
			};
	t_get @primes, undef, undef;
}

done_testing();
