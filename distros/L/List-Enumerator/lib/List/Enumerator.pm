package List::Enumerator;
use strict;
use warnings;

use Sub::Exporter -setup => {
	exports => [ "E" ],
	groups  => {
		default => [ "E" ],
	}
};

use List::Enumerator::Array;
use List::Enumerator::Sub;

our $VERSION = "0.10";

sub E {
	my (@args) = @_;
	if (ref($args[0]) eq "ARRAY") {
		List::Enumerator::Array->new(array => $args[0]);
	} elsif (ref($args[0]) eq "HASH") {
		List::Enumerator::Sub->new(%{ $args[0] });
	} elsif (ref($args[0]) =~ /^List::Enumerator/) {
		$args[0];
	} else {
		List::Enumerator::Array->new(array => \@args);
	}
}


1;
__END__

=head1 NAME

List::Enumerator - list construct library

=head1 SYNOPSIS

  use List::Enumerator qw/E/;

  my $fizzbuzz =
      E(1)->countup
          ->zip(
              E("", "", "Fizz")->cycle,
              E("", "", "", "", "Buzz")->cycle
          )
          ->map(sub {
              my ($n, $fizz, $buzz) = @$_;
              $fizz . $buzz || $n;
          });
  
  $fizzbuzz->take(20)->each(sub {
      print $_, "\n";
  });


=head1 DESCRIPTION

List::Enumerator is list library like Enumerator of Ruby.

List::Enumerator::E is interface wrapper for generating List::Enumerator::Array or List::Enumerator::Sub.

Most methods (except what returns always infinite list) consider caller context. ex:

  E(1, 2, 3, 4, 5)->take(3);     #=> new List::Enumerator::Sub
  [ E(1, 2, 3, 4, 5)->take(3) ]; #=> [1, 2, 3]

=over

=item C<E(list)>

=item C<E([arrayref])>

Returns List::Enumerator::Array.

=item C<E({ next =E<gt> sub {}, rewind =E<gt> sub {} })>

Returns List::Enumerator::Sub. ex:

  use List::Enumerator qw/E/;

  sub fibonacci {
      my ($p, $i);
      E(0, 1)->chain(E({
          next => sub {
              my $ret = $p + $i;
              $p = $i;
              $i = $ret;
              $ret;
          },
          rewind => sub {
              ($p, $i) = (0, 1);
          }
      }))->rewind;
  }

  [ fibonacci->take(10) ];           #=> [ 0, 1, 1, 2, 3, 5, 8, 13, 21, 34 ];
  [ fibonacci->drop(10)->take(10) ]; #=> [ 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181 ];

=item C<next>

Returns next element of receiver.

=item C<rewind>

Rewinds receiver.

=item C<select(sub {})>, C<find_all(sub {})>

Selects all elements which is evaluated true with block. find_all is just alias to select.

  E(1..10)->select(sub {
      $_ % 2 == 0
  })->to_a; #=> [2, 4, 6, 8, 10];


=item C<reject(sub {})>

Selects all elements which is evaluated false with block. This is antonym of select.


=item C<reduce(sub {})>, C<inject(sub {})>

Reduces receiver to one value using block.

  E(1..3)->reduce(sub { $a + $b }); #=> 6


=item C<slice($start, $end)>

Slices receiver with $start and $end.

  E(1..10)->slice(0);  #=> 1
  E(1..10)->slice(-1); #=> 10

  E(1..20)->slice(9, 11)->to_a; #=> [10, 11, 12]


=item C<find($target)>

Finds $target. If the value is found returns it. If not so returns undef.


=item C<find_index($target)>, C<index_of($target)>

Finds $target and returns its index.


=item C<first>

Returns first element of receiver.

=item C<last>

Returns last element of receiver.

=item C<max>

Returns max value of receiver.

=item C<max_by(sub {})>

Returns max value of receiver with block.

=item C<min>

Returns min value of receiver.

=item C<min_by(sub {})>

Returns min value of receiver with block.

=item C<minmax_by(sub {})>

Returns min value and max value of receiver with block.

=item C<sort_by(sub {})>

Returns sorted list with returned value from block. (Schwartzian transformed sort)

=item C<sort(sub {})>

Returns sorted list with block.

=item C<sum>

Sums receiver up and returns the value.

=item C<uniq>

Returns new unique list.

=item C<grep(sub {})>

Grep receiver and returns new list.

  [ E(1..10)->grep(sub { $_ % 2 == 0 }) ]; #=> [2, 4, 6, 8, 10];


=item C<compact>

Returns new list excludes undef.

=item C<reverse>

Returns new reversed list of receiver.

=item C<flatten($level)>

Expands nested array.

	[ E([1, 2, [3, 4], 5])->flatten ];      #=> [1, 2, 3, 4, 5];
	[ E([1, [2, [3, 4]], 5])->flatten ];    #=> [1, 2, 3, 4, 5];
	[ E([1, [2, [3, 4]], 5])->flatten(1) ]; #=> [1, 2, [3, 4], 5];

=item C<length>, C<size>

Returns length of receiver. You should not call this method for infinite list.

=item C<is_empty>

This is synonym of !$self->length;

=item C<chain(list...)>

Chains with other lists.

  [ E(1, 2, 3)->chain([4, 5, 6]) ]; #=> [1, 2, 3, 4, 5, 6];


=item C<take(sub {})>, C<take(number)>, C<take_while(sub {})>

Returns prefix of receiver of length number or elements satisfy block.

=item C<drop(sub {})>, C<drop(number)>, C<drop_while(sub {})>

Returns remaining of receiver.

=item C<every(sub {})>, C<all(sub {})>

Returns 1 if all elements in receiver satisfies the block.

=item C<some(sub {})>, C<any(sub {})>

Returns 1 if at least one element in receiver satisfies the block.

=item C<none(sub {})>

Returns 1 if all elements in receiver not satisfies the block.

  E(0, 0, 0, 0)->none; #=> 1
  E(0, 0, 0, 1)->none; #=> 0
  E(0, 0, 1, 1)->none; #=> 0

=item C<one(sub {})>

Returns 1 if just one elements in receiver satisfies the block.

  E(0, 0, 0, 0)->one; #=> 0
  E(0, 0, 0, 1)->one; #=> 1
  E(0, 0, 1, 1)->one; #=> 0

=item C<zip(list..)>

Returns zipped list with arguments. The length of returned list is length of receiver.

  [ E(1..3)->zip([qw/a b c/]) ]; #=> [ [1, "a"], [2, "b"], [3, "c"] ]


=item C<with_index>

Returns zipped with count.

  E("a", "b", "c")->with_index->each(sub {
  	my ($item, $index) = @$_;
  });


=item C<countup($lim)>, C<to($lim)>

Returns count up list starts from first of receiver.
If $lim is not supplied, this returns infinite list.

  E(1)->countup; #=> List::Enumerator::Sub
  [ E(1)->countup->take(3) ]; #=>  [1, 2, 3]

  E(1)->to(100); #=> E(1..100)

=item C<cycle>

Returns infinite list which cycles receiver.

  [ E(1, 2, 3)->cycle->take(5) ]; #=> [1, 2, 3, 1, 2]

=item C<join($sep)>

Returns string of receiver joined with $sep

=item C<group_by(subh{})>

Returns a hash reference group by the block.

  E([
  	{ cat => 'a' }, { cat => 'a' },{ cat => 'a' },{ cat => 'a' },
  	{ cat => 'b' }, { cat => 'b' },{ cat => 'b' },{ cat => 'b' },
  	{ cat => 'c' }, { cat => 'c' },{ cat => 'c' },{ cat => 'c' },
  ])->group_by(sub {
  	$_->{cat};
  });
  
  {
  	'a' => [ { cat => 'a' }, { cat => 'a' },{ cat => 'a' },{ cat => 'a' } ],
  	'b' => [ { cat => 'b' }, { cat => 'b' },{ cat => 'b' },{ cat => 'b' } ],
  	'c' => [ { cat => 'c' }, { cat => 'c' },{ cat => 'c' },{ cat => 'c' } ],
  };

=item C<partition(sub {})>

  my ($even, $odd) = E(1..10)->partition(sub { $_ % 2 == 0 });

=item C<include($target)>, C<is_include($target)>

If receiver include $target this return true.

=item C<map(sub {})>, C<collect(sub {})>

map.

=item C<each(sub {})>

Iterate items.

=item C<each_index>

Iterate indexes with block.

=item C<each_slice($n, sub {})>

  E(1)->countup->each_slice(3)->take(3)->to_a;
  
  [
  	[1, 2, 3],
  	[4, 5, 6],
  	[7, 8, 9],
  ];

=item C<each_cons($n, sub {})>

  E(1)->countup->each_cons(3)->take(3)->to_a;
  
  [
  	[1, 2, 3],
  	[2, 3, 4],
  	[3, 4, 5]
  ];

=item C<choice>, C<sample>

Returns one item in receiver randomly.

=item C<shuffle>

Returns randomized array of receiver.

=item C<transpose>

Returns transposed array of receiver.

  [ E([
  	[1, 2],
  	[3, 4],
  	[5, 6],
  ])->transpose ]
  
  [
  	[1, 3, 5],
  	[2, 4, 6],
  ];

=item C<to_list>

Returns expanded array or array reference.

  E(1)->countup->take(5)->to_list;     #=> [1, 2, 3, 4, 5]
  [ E(1)->countup->take(5)->to_list ]; #=> [1, 2, 3, 4, 5]

=item C<to_a>

Returns expanded array reference.

  E(1)->countup->take(5)->to_a;     #=> [1, 2, 3, 4, 5]
  [ E(1)->countup->take(5)->to_a ]; #=> [ [1, 2, 3, 4, 5] ]

=item C<expand>

Returns new List::Enumerator::Array with expanded receiver.

=item C<dump>

Dump receiver.

=item C<stop>

Throw StopIteration exception.

  my $list = E({
  	next => sub {
  		$_->stop;
  	}
  });

  $list->to_a; #=> [];

=back


=head2 Concept

=over

=item * Lazy evaluation for infinite list (ex. cycle)

=item * Method chain

=item * Read the context

=item * Applicable

=back


=head1 DEVELOPMENT

This module is developing on github L<http://github.com/cho45/list-enumerator/tree/master>.


=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

L<List::RubyLike>, L<http://coderepos.org/share/wiki/JSEnumerator>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
