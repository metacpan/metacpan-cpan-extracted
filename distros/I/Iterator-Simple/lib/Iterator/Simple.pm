package Iterator::Simple;

use strict;

use Carp;
#use UNIVERSAL qw(isa);
use Scalar::Util qw(blessed reftype);
use overload;
use base qw(Exporter);
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);

use constant ITERATOR_CLASS => 'Iterator::Simple::Iterator';
$VERSION = '0.06';

$EXPORT_TAGS{basic} = [qw(iterator iter list is_iterator)];
$EXPORT_TAGS{utils} = [qw(
	ifilter iflatten ichain izip ienumerate
	islice ihead iskip imap igrep iarray
	is_iterable is_listable
)];

push @EXPORT_OK, @{$EXPORT_TAGS{basic}}, @{$EXPORT_TAGS{utils}};
$EXPORT_TAGS{all} = [@EXPORT_OK];

sub iterator(&) { ITERATOR_CLASS->new($_[0]);}

# name: iter
# synopsis: iter($object);
# description:
#   autodetect object type and turn it into iterator
# param: object: object to turn into iterator
# return: iterator
sub iter {
	if(not @_) {
		return iterator { return };
	}
	my($self) = @_;
	if(blessed $self) {
		if($self->isa(ITERATOR_CLASS)) {
			return $self;
		}
		my $method;
		if($method = $self->can('__iter__')) {
			return $method->($self);
		}
		if($method = overload::Method($self, '<>') || $self->can('next')) {
			return ITERATOR_CLASS->new(sub { $method->($self) });
		}
		if($method = overload::Method($self, '&{}')) {
			return ITERATOR_CLASS->new($method->($self));
		}
		if($method = overload::Method($self,'@{}')) {
			return iarray($method->($self));
		}
	}
	if(ref($self) eq 'ARRAY') {
		return iarray($self);
	}
	if(ref($self) eq 'CODE') {
		return ITERATOR_CLASS->new($self);
	}
	if(reftype($self) eq 'GLOB') {
		return ITERATOR_CLASS->new(sub { scalar <$self> });
	}

	croak sprintf "'%s' object is not iterable", (ref($self)||'SCALAR');
}

# name: is_iterable
# synopsis: iter($object);
# description:
#   returns given object is iterable or not.
# param: object
# return: iterator
sub is_iterable {
	my($self) = @_;
	return not not (
		(blessed($self) and (
			$self->isa(ITERATOR_CLASS)
			or $self->can('__iter__')
			or $self->can('next')
			or overload::Method($self, '<>')
			or overload::Method($self, '&{}')
			or overload::Method($self,'@{}')
		))
		or ref($self) eq 'ARRAY'
		or ref($self) eq 'CODE'
		or reftype($self) eq 'GLOB'
	);
}

# name: is_iterator
# synopsis: is_iterator($object);
# description:
#   reports Iterator::Simpler iterator object or not;
# param: object: some object;
# return: bool
sub is_iterator {
	blessed($_[0]) and $_[0]->isa(ITERATOR_CLASS);
}

# name: list
# synopsis: list($object)
# description:
#   autodetect object type and turn it into array reference
# param: object: object to turn into array
# return: array reference
sub list {
	if(not @_) {
		return [];
	}
	my($self) = @_;
	if(ref($self) eq 'ARRAY') {
		return $self;
	}
	if(reftype($self) eq 'GLOB') {
		return [<$self>];
	}
	if(blessed $self) {
		if($self->isa(ITERATOR_CLASS)) {
			my(@list, $val);
			push @list, $val while defined($val = $self->());
			return \@list;
		}
		my $method;
		if($method = overload::Method($self,'@{}')) {
			return $method->($self);
		}
		if($method = $self->can('__iter__')) {
			my(@list, $val);
			my $iter = $method->($self);
			push @list, $val while defined($val = $iter->());
			return \@list;
		}
		if($method = overload::Method($self, '<>') || $self->can('next')) {
			my(@list, $val);
			push @list, $val while defined($val = $method->($self));
			return \@list;
		}
	}
	croak sprintf "'%s' object could not be converted to array ref", (ref($self)||'SCALAR');
}

# name: ifilter
# synopsis: ifilter $iterable, sub { CODE };
# description:
#   filters another iterable object.
#   if filter code yields another iterator, iterate it until it
#   exhausted. if filter code yields undefined value, ignores it.
# param: source: source iterable object
# param: code: transformation code
# return: transformed iterator
sub ifilter {
	my($src, $code) = @_;
	$src = iter($src);
	if(ref($code) ne 'CODE' and ! overload::Method($code, '&{}')) {
		croak 'Second argument to ifilter must be callable.';
	}

	my $buf;

	ref($src)->new(sub {
		my $rv;
		if($buf) {
			return $rv if defined($rv = $buf->());
			undef $buf;
		}
		while(defined(local $_ = $src->())) {
			next unless defined($rv = $code->());
			return $rv unless eval {$rv->isa(ITERATOR_CLASS)}; 
			$buf = $rv;
			return $rv if defined($rv = $buf->());
			undef $buf;
		}
		return;
	});
}

# name: imap
# synopsis: imap { CODE } $iterable;
# description:
#   simplified version of ifilter, no skip, no inflate.
# param: code: transformation code;
# param: source: source iterable object
# return: transformed iterator;
sub imap(&$) {
	my($code, $src) = @_;
	$src = iter($src);
	ref($src)->new(sub {
		local $_ = $src->();
		return if not defined $_;
		return $code->();
	});
}

# name: igrep
# synopsis: igrep { CODE } $iterable;
# description:
#   iterator filter iterator
# param: code: filter condition
# param: source: source iterable object
# return: filtered iterator
sub igrep(&$) {
	my($code, $src) = @_;
	$src = iter($src);
	ref($src)->new(sub {
		while(defined(my $rv = $src->())) {
			local $_ = $rv;
			return $rv if $code->();
		}
		return;
	});
}

# name: iflatten
# synopsys: iflatten $iterable;
# description:
#   if source iterator yields another iterator, iterate it first.
# param: source: source iterable object
# return: flatten iterator
sub iflatten {
	my($src) = @_;
	$src = iter($src);

	my $buf;
	ref($src)->new(sub {
		my $rv;
		if($buf) {
			return $rv if defined($rv = $buf->());
			undef $buf;
		}
		while(1){
			$rv = $src->();
			return if not defined $rv;
			return $rv unless eval {$rv->isa(ITERATOR_CLASS)}; 
			$buf = $rv;
			return $rv if defined($rv = $buf->());
			undef $buf;
		}
	});
}

# name: ichain
# synopsis: ichain($iterable1, $iterable2,...)
# description:
#   iterate one or more iterater one by one.
# param: iteraters: one or more iterable object
# return: chained iterator
sub ichain {
	my @srcs = map { iter($_) } @_;
	if(@srcs == 1) {
		return $srcs[0];
	}
	ref($srcs[0])->new(sub{
		while(@srcs) {
			my $rv = $srcs[0]->();
			return $rv if defined $rv;
			shift @srcs;
		}
		return;
	});
}

# name: ienumerate
# sysopsis: ienumerate($iterable);
# description:
#   returns an iterator which yields $souce value with its index.
# param: iterable: source iterator
# return: iterator
sub ienumerate {
	my($src) = @_;
	$src = iter($src);
	my $idx = 0;
	
	ref($src)->new(sub{
		my $rv = $src->();
		return if not defined $rv;
		return [$idx++, $rv];
	});
}

# name: izip
# synopsis: izip($iterable, ...)
# description:
#   this function returns an iterator yields array reference,
#   where i-th array contains i-th element from each of the argument iterables.
# param: iterables: list of iterables;
# return: zipped iterator;
sub izip {
	my @srcs = map { iter($_) } @_;
	
	ref($srcs[0])->new(sub{
		my @rv;
		for my $src (@srcs) {
			my $rv = $src->();
			return if not defined $rv;
			push @rv, $rv;
		}
		return \@rv;
	});
}

# name: islice
# synopsis: isplice($iterable, $start, $end, $step);
# description:
#   this function returns an iterator,
# param: iterable: source iterable object
# param: start: how many first values are skipped
# param: end: last index of source iterator
# param: step: step
# return: sliced iterator
sub islice {
	my($src, $next, $end, $step) = @_;
	$next = defined $next  ? int($next) : 0;
	$end = defined $end ? int($end) : -1;
	$step = defined $step ? int($step) : 1;
	if($next == $end) {
		$next = -1;
	}

	$src = iter($src);
	my $idx = 0;

	ref($src)->new(sub{
		return if $next < 0;
		my $rv;
		while($rv = $src->()) {
			if($idx++ == $next) {
				$next += $step;
				if($end > 0 and $next >= $end) {
					$next = -1;
				}
				return $rv;
			}
		}
		return;
	});
}

sub ihead {islice($_[1], 0, $_[0]);}
sub iskip {islice($_[1], $_[0]);}

# name: iarray
# synopsis: iarray $array_ref;
# description:
#   creates iterator from array reference
# param: array_ref: source array reference
# return: iterator
sub iarray {
	my($ary) = @_;
	if(ref($ary) ne 'ARRAY') {
		croak 'Argument to iarray must be ARRAY reference';
	}
	my $idx = 0;

	iterator {
		return if $idx == @$ary;
		return $ary->[$idx++];
	};
}

# class Iterator::Simple::Iterator is underlying Iterator object.
# It is just a blessed subroutine reference.
{
	package Iterator::Simple::Iterator;

	use Carp;
	use overload (
		'<>'  => 'next',
		'|' => 'filter',
		fallback => 1,
	);

	sub new {
		if(ref($_[1]) ne 'CODE') {
			croak 'Parameter to iterator constructor must be code reference.';
		}
		bless $_[1], $_[0];
	}

	sub next { goto shift }

	sub __iter__ { $_[0] }

	*filter = \&Iterator::Simple::ifilter;
	*flatten = \&Iterator::Simple::iflatten;
	*chain = \&Iterator::Simple::ichain;
	*zip = \&Iterator::Simple::izip;
	*enumerate = \&Iterator::Simple::ienumerate;
	*slice  = \&Iterator::Simple::islice;
	sub head { Iterator::Simple::ihead($_[1], $_[0]); }
	sub skip { Iterator::Simple::iskip($_[1], $_[0]); }
}

1;
__END__

=head1 NAME

Iterator::Simple - Simple iterator and utilities

=head1 SYNOPSIS

  use Iterator::Simple;
  
  sub foo {
    my $max = shift;
    my $i = 0;
    iterator {
      return if $i > $max;
      $i++;
    }
  }
  
  my $iterator = foo(20); # yields 0,1,2, ..., 19, 20;
  $iterator = imap { $_ + 2 } $iterator; # yields 2,3,4,5, ... ,20,21,22
  $iterator = igrep { $_ % 2 } $iterator; # yields 3,5,7,9, ... ,17,19,21
  
  # iterable object
  $iterator = iter([qw(foo bar baz)]); # iterator from array ref
  $iterator = iter(IO::File->new($filename)); # iterator from GLOB
  
  # filters
  $iterator = ichain($itr1, $itr2); # chain iterators;
  $iterator = izip($itr1, $itr2); # zip iterators;
  $iterator = ienumerate $iterator; # add index;
  
  # general filter
  $iterator = ifilter $iterator, sub {
    return $_ if /^A/;
    return;
  }
  
  # how to iterate
  while(defined($_ = $iterator->())) {
    print;
  }
  
  while(defined($_ = $iterator->next)) {
    print;
  }
  
  while(<iterator>) {
    print;
  }

=head1 DESCRIPTION

Iterator::Simple is yet another general-purpose iterator utilities.

Rather simple, but powerful and fast iterator.

=head1 FUNCTIONS

Iterator::Simple doesn't export any functions by default. please import
them like:

  use Iterator::Simple qw(iter list imap);

For all functions:

  use Iterator::Simple qw(:all);

=over 4

=item iterator { CODE }

Iterator constructor. CODE returns a value on each call, and if
it is exhausted, returns undef. Therefore, you cannot yields
undefined value as a meaning value. If you want, you could use
L<Iterator> module which can do that.

Generally, you can implement iterator as a closure like:

  use Iterator::Simple qw(iterator);
  
  sub fibonacci {
    my($s1, $s2, $max) = @_;
    
    iterator {
      my $rv;
      ($rv, $s1, $s2) = ($s1, $s2, $s1 + $s2);
      return if $rv > $max;
      return $rv;
    }
  }
  
  my $iterator = fiboacci(1, 1, 1000);

You can iterate it in several ways:

=over 2

=item * just call it

  while(defined($_ = $iterator->())) {
    print "$_\n";
  }

=item * C<next> method

  while(defined($_ = $iterator->next)) {
    print "$_\n";
  }

=item * <> operator

  while(<$iterator>) {
    print "$_\n";
  }

=back

=item is_iterator($object)

If C<$object> is an iterator created by Iterator::Simple, returns true.
False otherwise.

=item iter($object)

This function auto detects what $object is, and automatically
turns it into an iterator. Supported objects are:

=over 2

=item *

Iterator made with Iterator::Simple.

=item *

Object that implements C<__iter__> method.

=item *

Object that overloads '<>' or has C<next> method.

=item *

Object that overloads '&{}'.(as iterator function.)

=item *

Object that overloads '@{}'.(with C<iarray()>)

=item *

ARRAY reference. (C<iarray()>)

=item *

CODE reference. (as iterator function.)

=item *

GLOB reference.

=item *

nothing (C<iter()>.) (empty iterator.)

=back

If it fails to convert, runtime error.

=item is_iterable($object)

return true if C<$object> can be converted with C<iter($object)>

=item list($object)

This fuction converts C<$object> into single array referece.

=over 2

=item *

ARRAY reference.

=item *

GLOB reference.

=item *

Iterator made with Iterator::Simple.

=item *

Object that overloads '@{}' operator.

=item *

Object that implements '__iter__' method.

=item *

Object that overloads '<>' operator or has C<next> method.

=item *

nothing (i.e. list() returns []);

=back

If it fails to convert, runtime error.

Note that after C<list($iterator)>, that iterator is not usable any more.

=item imap { CODE } $iterable

This is the iterator version of C<map>. Returns an iterator which yields
the value from source iterator modified by CODE.

=item igrep { CODE } $iterable

This is the iterator version of C<grep>. Returns an iterator which yields
the value from source iterator only when CODE returns true value.

=item iflatten $iterable

When C<$iterable> yields another iterator, iterate it first.

  $subitr = iter([10, 11,12]);
  $source = iter([ 1, 2, $subitr, 4]);
  
  $flattened = iflatten $source;
  
  # yields 1, 2, 10, 11, 12, 4.

=item ifilter $iterable, sub{ CODE }

This is the combination of imap, igrep, iflatten. it supports modify (imap)
, skip (igrep), and inflate (iflatten). but it should be faster than
combination of them.

For example:

  $combination = iflatten
    imap { $_ eq 'baz' ? iter(['whoa', 'who']) : ":$_:" }
    igrep { $_ ne 'bar' }
    iter [ 'foo', 'bar', 'baz', 'fiz' ];

  $itr = iter [ 'foo', 'bar', 'baz', 'fiz' ];
  $filterd = ifilter $itr, sub {
    return if $_ eq 'bar'; #skip
    retrun iter(['whoa', 'who']) if $_ eq 'baz'; #inflate
    return ":$_:"; # modify
  };

Both of them will yields C<':foo:', 'whoa', 'who', ':fiz:'>.

=item ichain($iterable, $iterable2, ...)

This function returns an iterator which chains one or more iterators.
Iterates each iterables in order as is, until each iterables are exhausted.

Example:

  $itr1 = iter(['foo', 'bar', 'baz']);
  $itr2 = iter(['hoge', 'hage']);
  
  $chained = ichain($itr1, $itr2);
  
  # yields 'foo', 'bar', 'baz', 'hoge', 'hage'.

=item ienumerate($iterable)

This function returns an iterator yields like:

  $ary = iter(['foo', 'bar', 'baz', ... ]);
  
  $iter = ienumerate $ary;
  
  # yields [0, 'foo'], [1, 'bar'], [2, 'baz'], ... 

=item izip($iterable, $iterable2, ...);

Accepts one or more iterables, returns an iterator like:

  $animals = iter(['dogs', 'cats', 'pigs']);
  $says = iter(['bowwow', 'mew', 'oink']);
  
  $zipped = izip($animals, $says);
  
  # yields ['dogs','bowwow'], ['cats','mew'], ['pigs', 'oink'].

Note that when one of source iterables is exhausted, zipped iterator
will be exhausted also.

=item islice($iterable, $start, $end, $step)

Same as islice of itertools in Python. If C<$end> is undef or
negative value, it iterates source until it is exhausted.
C<$step> defaults to 1. 0 or negative step value is prohibited.

  $iter = iter([0,1,2,3,4,5,6,7,8,9,10,11,12]);
  
  $sliced = islice($iter, 3, 13, 2);

  # yields 3, 5, 7, 9, 11.

=item ihead($count, $iterable)

  islice($iterable, 0, $count, 1);

=item iskip($count, $iterable)

  islice($iterable, $count, undef, 1);

=item iarray($arrayref);

Turns array reference into an iterator. Used in C<iter($arrayref)>.
You do not have to use this function directly, because
C<iter($arrayref)> is sufficient.

=back

=head1 OO INTERFACE

Iterator used in Iterator::Simple is just a code reference blessed
in Iterator::Simple::Iterator. This class implements several method
and overloads some operators.

=over 4

=item Itrator::Simple::Iterator->new($coderef)

Just bless $coderef in Iterator::Simple::Iterator and returns it.

=item $iterator->next

Call undelying code.

=item $iterator->__iter__

Returns self. You don't need to use this.

=item Overloaded operators.

=over 2

=item * Read filehandle operator '<>'

Overloading '<>' makes this possible like:

  print while <$iterator>;

=item * Pipe.. bit_OR? .. No, pipe!

  $iterator | $coderef1 | $coderef2;

is equivalent to:

  $iterator->filter($coderef1)->filter($coderef2);

is equivalent to:

  ifilter(ifilter($iterator, $coderef1), $coderef2);

=back

=item $iterator->filter($coderef)

=item $iterator->flatten()

=item $iterator->chain($another, ..)

=item $iterator->zip($another, ..)

=item $iterator->enumerate()

=item $iterator->slice($start, $end, $step)

=item $iterator->head($count)

=item $iterator->skip($count)

For example, $iterator->flatten() is equivalent to
C<iflatten $iterator>.

=back

=head1 TIPS

All iterator transformation function calls C<iter> function on all source
iterables. So you can pass just array reference, GLOB ref, etc.

These examples completely do the right thing:

  imap { $_ + 2 } [1, 2, 3, ... ];
  ienumerate(\*STDIN);
  
  # DBIx::Class::ResultSet has 'next' method.
  ifilter $dbic_resultset, sub {CODE};

You can implement C<__iter__> method on your objects in your application.
By doing that, your object will be Iterator::Simple friendly :).

Note that C<__iter__> method must return an iterator.

=head1 Why Not Iterator.pm

There is another iterator module in CPAN, named L<Iterator> and
L<Iterator::Util> made by Eric J. Roode that is great solution.
Why yet another iterator module? The answer is *Speed*. You use iterator
because you have too many data to manipulate in memory, therefore
iterator could be called thousands of times, speed is important.

For this simple example:

  use Iterator::Util qw(iarray imap igrep);
  
  for(1 .. 100) {
    my $itr = igrep { $_ % 2 } imap { $_ + 2 } iarray([1 .. 1000]);
    my @result;
    while($itr->isnt_exhausted) {
      push @result, $itr->value;
    }
  }

meanwhile:

  use Iterator::Simple qw(iarray imap igrep);
  
  for(1 .. 100) {
    my $itr = igrep { $_ % 2 } imap { $_ + 2 } iarray([1 .. 1000]);
    my @result;
    while(defined($_ = $itr->())) {
      push @result, $_;
    }
  }

Iterator::Simple is about ten times faster!

That is natural because Iterator::Simple iterator is just a code reference,
while Iterator.pm iterator is full featured class instance.
But Iterator::Simple is sufficient for usual demands.

One of most downside of Iterator::Simple is, you cannot yields undef value
as a meaning value, because Iterator::Simple thinks it as a exhausted sign.
If you need to do that, you have to yield something which represents undef
value.

Also, Iterator::Simple cannot determine iterator is exhausted until next
iteration, while Iterator.pm has 'is(nt)_exhausted' method which is useful
in some situation.

=head1 AUTHOR

Rintaro Ishizaki E<lt>rintaro@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 2

=item *

L<Iterator> - Feature rich another iterator class.

=item *

L<Iterator::Util> - Utilities which uses L<Iterator>. Many of filter
functions are from this module.

=back

=cut
