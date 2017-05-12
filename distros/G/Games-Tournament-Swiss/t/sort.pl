#!perl

use strict;
use warnings;

sub permute {
  my @items = @_;
  my $n = 0;
  return sub {
    $n++, return @items if $n==0;
    my $i;
    my $p = $n;
    for ($i=1; $i<=@items && $p%$i==0; $i++) {
      $p /= $i;
    }
    my $d = $p % $i;
    my $j = @items - $i;
    return if $j < 0;

    @items[$j+1..$#items] = reverse @items[$j+1..$#items];
    @items[$j,$j+$d] = @items[$j+$d,$j];

    $n++;
    return @items;
  };
}

my $it = permute(qw/1.5 1.5Remainder 1 1Remainder 1Bye/);

my $sort = sub {
       if ( $a =~ /Bye$/ ) {
	   return -1;
       }
       elsif ( $b =~ /Bye$/ ) {
	   return 1;
       }
       elsif ( $a =~ /^(\d+\.?5?)Remainder$/ ) {
	   if ( $1 eq $b ) {
	       return -1;
	   }
	   else {
	       my $numbers_a = $1;
	       if ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
		   return $numbers_a <=> $1;
	       }
	       else {
		   return $numbers_a <=> $b;
	       }
	   }
       }
       elsif ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
	   if ( $1 eq $a ) {
	       return 1;
	   }
	   else {
	       my $numbers_b = $1;
	       if ( $a =~ /^(\d+\.?5?)Remainder$/ ) {
		   return $1 <=> $numbers_b;
	       }
	       else {
		   return $a <=> $numbers_b;
	       }
	   }
       }
       else { return $a cmp $b; }
};

while (my @order = &$it )
{
	local $, = ' ';
	local $\ = "\n";
	print reverse sort $sort @order;
}

print "\n";

$it = permute(qw/1.5 1.5Remainder 1 1Remainder 1Bye/);

while (my @order = &$it )
{
	my %index;
	@index{@order} = map {	m/^(\d*\.?\d+)(\D.*)?$/;
				{score => $1, tag => $2||'' }
				} @order;
	my $sort = sub { $index{$b}->{score} <=> $index{$a}->{score} ||
			$index{$a}->{tag} cmp $index{$b}->{tag} };
	local $, = ' ';
	local $\ = "\n";
	print sort $sort @order;
}
