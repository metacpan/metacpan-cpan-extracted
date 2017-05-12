package List::Objects::WithUtils::Role::Array;
$List::Objects::WithUtils::Role::Array::VERSION = '2.028003';
use strictures 2;

use Carp            ();
use List::Util      ();
use Module::Runtime ();
use Scalar::Util    ();

# This (and relevant tests) can disappear if UtilsBy gains XS:
our $UsingUtilsByXS = 0;
{ no warnings 'once';
  if (eval {; require List::UtilsBy::XS; 1 } && !$@) {
    $UsingUtilsByXS = 1;
    *__sort_by  = \&List::UtilsBy::XS::sort_by;
    *__nsort_by = \&List::UtilsBy::XS::nsort_by;
    *__uniq_by  = \&List::UtilsBy::XS::uniq_by;
  } else {
    require List::UtilsBy;
    *__sort_by  = \&List::UtilsBy::sort_by;
    *__nsort_by = \&List::UtilsBy::nsort_by;
    *__uniq_by  = \&List::UtilsBy::uniq_by;
  }
}


=for Pod::Coverage ARRAY_TYPE blessed_or_pkg

=begin comment

Regarding blessed_or_pkg():
This is some nonsense to support autoboxing; if we aren't blessed, we're
autoboxed, in which case we appear to have no choice but to cheap out and
return the basic array type.

This should only be called to get your hands on ->new().

->new() methods should be able to operate on a blessed invocant.

=end comment

=cut

sub ARRAY_TYPE () { 'List::Objects::WithUtils::Array' }

sub blessed_or_pkg {
  Scalar::Util::blessed($_[0]) ? 
    $_[0] : Module::Runtime::use_module(ARRAY_TYPE)
}


sub __flatten_all {
  # __flatten optimized for max depth:
  ref $_[0] eq 'ARRAY' || Scalar::Util::blessed($_[0]) 
      # 5.8 doesn't have ->DOES()
      && $_[0]->can('does') 
      && $_[0]->does('List::Objects::WithUtils::Role::Array') ?
        map {; __flatten_all($_) } @{ $_[0] }
    : $_[0]
}

sub __flatten {
  my $depth = shift;
  CORE::map {
    ref eq 'ARRAY' || Scalar::Util::blessed($_)
        && $_->can('does')
        && $_->does('List::Objects::WithUtils::Role::Array') ?
          $depth > 0 ? __flatten( $depth - 1, @$_ ) : $_
      : $_
  } @_
}


use Role::Tiny;   # my position relative to subs matters


sub inflated_type { 'List::Objects::WithUtils::Hash' }

sub is_mutable { 1 }
sub is_immutable { ! $_[0]->is_mutable }

sub _try_coerce {
  # subclass-mungable (keep me under the Role::Tiny import)
  my (undef, $type, @vals) = @_;
    Carp::confess "Expected a Type::Tiny type but got $type"
      unless Scalar::Util::blessed $type;

  CORE::map {;
    my $coerced;
    $type->check($_) ? $_
    : $type->assert_valid( 
        $type->has_coercion ? ($coerced = $type->coerce($_)) : $_
      ) ? $coerced
      : Carp::confess "I should be unreachable!"
  } @vals
}


=for Pod::Coverage TO_JSON TO_ZPL damn type

=cut

sub type {
  # array() has an empty ->type
}

sub new { bless [ @_[1 .. $#_ ] ], Scalar::Util::blessed($_[0]) || $_[0] }


=for Pod::Coverage untyped

=cut

{ no warnings 'once'; *untyped = *copy }
sub copy { blessed_or_pkg($_[0])->new(@{ $_[0] }) }

sub inflate {
  my ($self) = @_;
  my $cls = blessed_or_pkg($self);
  Module::Runtime::require_module( $cls->inflated_type );
  $cls->inflated_type->new(@$self)
}

{ no warnings 'once'; 
  *TO_JSON  = *unbless; 
  *TO_ZPL   = *unbless;
  *damn     = *unbless; 
}
sub unbless { [ @{ $_[0] } ] }

sub validated {
  my ($self, $type) = @_;
  # Autoboxed?
  $self = blessed_or_pkg($self)->new(@$self)
    unless Scalar::Util::blessed $self;
  blessed_or_pkg($_[0])->new(
    CORE::map {; $self->_try_coerce($type, $_) } @$self
  )
}

sub all { @{ $_[0] } }
{ no warnings 'once'; *export = *all; *elements  = *all; }


=for Pod::Coverage size

=cut

sub count { CORE::scalar @{ $_[0] } }
{ no warnings 'once'; *scalar = *count; *size = *count; }

sub end { $#{ $_[0] } }

sub is_empty { ! @{ $_[0] } }

sub exists {
  my $r;
  !!(
    $_[1] <= $#{ $_[0] } ? $_[1] >= 0 ? 1
      : (($r = $_[1] + @{ $_[0] }) <= $#{ $_[0] } && $r >= 0) ? 1 : ()
      : ()
  )
}

sub defined { defined $_[0]->[ $_[1] ] }

sub get { $_[0]->[ $_[1] ] }

sub get_or_else {
  defined $_[0]->[ $_[1] ] ? $_[0]->[ $_[1] ]
    : (Scalar::Util::reftype $_[2] || '') eq 'CODE' ? $_[2]->(@_[0,1])
    : $_[2]
}

sub set { $_[0]->[ $_[1] ] = $_[2] ; $_[0] }

sub random { $_[0]->[ rand @{ $_[0] } ] }

sub kv {
  my ($self) = @_;
  blessed_or_pkg($self)->new(
    map {; [ $_ => $self->[$_] ] } 0 .. $#$self
  )
}

sub head {
  wantarray ?
    ( 
      $_[0]->[0], 
      blessed_or_pkg($_[0])->new( @{ $_[0] }[ 1 .. $#{$_[0]} ] ) 
    )
    : $_[0]->[0]
}

sub tail {
  wantarray ?
    (
      $_[0]->[-1],
      blessed_or_pkg($_[0])->new( @{ $_[0] }[ 0 .. ($#{$_[0]} - 1) ] )
    )
    : $_[0]->[-1]
}

sub pop  { CORE::pop @{ $_[0] } }
sub push { 
  CORE::push @{ $_[0] }, @_[1 .. $#_]; 
  $_[0] 
}

sub shift   { CORE::shift @{ $_[0] } }
sub unshift { 
  CORE::unshift @{ $_[0] }, @_[1 .. $#_]; 
  $_[0] 
}

sub clear  { @{ $_[0] } = (); $_[0] }

sub delete { scalar CORE::splice @{ $_[0] }, $_[1], 1 }

sub delete_when {
  my ($self, $cb) = @_;
  my @removed;
  my $i = @$self;
  while ($i--) {
    local *_ = \$self->[$i];
    CORE::push @removed, CORE::splice @$self, $i, 1 if $cb->($_);
  }
  blessed_or_pkg($_[0])->new(@removed)
}

sub insert { 
  $#{$_[0]} = ($_[1]-1) if $_[1] > $#{$_[0]};
  CORE::splice @{ $_[0] }, $_[1], 0, @_[2 .. $#_];
  $_[0] 
}

sub intersection {
  my %seen;
  blessed_or_pkg($_[0])->new(
    # Well. Probably not the most efficient approach . . .
    CORE::grep {; ++$seen{$_} > $#_ } 
      CORE::map {; 
        my %s = (); CORE::grep {; not $s{$_}++ } @$_
      } @_
  )
}

sub diff {
  my %seen;
  my @vals = CORE::map {; 
    my %s = (); CORE::grep {; not $s{$_}++ } @$_
  } @_;
  $seen{$_}++ for @vals;
  my %inner;
  blessed_or_pkg($_[0])->new(
    CORE::grep {; $seen{$_} != @_ }
      CORE::grep {; not $inner{$_}++ } @vals
  )
}

sub join { 
  CORE::join( 
    ( defined $_[1] ? $_[1] : ',' ), 
    @{ $_[0] } 
  ) 
}

sub map {
  blessed_or_pkg($_[0])->new(
    CORE::map {; $_[1]->($_) } @{ $_[0] }
  )
}

sub mapval {
  my ($self, $cb) = @_;
  my @copy = @$self;
  blessed_or_pkg($self)->new(
    CORE::map {; $cb->($_); $_ } @copy
  )
}

sub visit {
  $_[1]->($_) for @{ $_[0] };
  $_[0]
}

sub grep {
  blessed_or_pkg($_[0])->new(
    CORE::grep {; $_[1]->($_) } @{ $_[0] }
  )
}



=for Pod::Coverage indices

=cut

{ no warnings 'once'; *indices = *indexes; }
sub indexes {
  $_[1] ? 
    blessed_or_pkg($_[0])->new(
      grep {; local *_ = \$_[0]->[$_]; $_[1]->() } 0 .. $#{ $_[0] }
    )
    : blessed_or_pkg($_[0])->new( 0 .. $#{ $_[0] } )
}

sub sort {
  if (defined $_[1] && (my $cb = $_[1])) {
    my $pkg = caller;
    no strict 'refs';
    return blessed_or_pkg($_[0])->new(
      CORE::sort {; 
        local (*{"${pkg}::a"}, *{"${pkg}::b"}) = (\$a, \$b);
        $a->$cb($b) 
      } @{ $_[0] }
    )
  }
  blessed_or_pkg($_[0])->new( CORE::sort @{ $_[0] } )
}

sub reverse {
  blessed_or_pkg($_[0])->new( CORE::reverse @{ $_[0] } )
}


=for Pod::Coverage slice

=cut

{ no warnings 'once'; *slice = *sliced }
sub sliced {
  my @safe = @{ $_[0] };
  blessed_or_pkg($_[0])->new( @safe[ @_[1 .. $#_] ] )
}

sub splice {
  blessed_or_pkg($_[0])->new(
    @_ == 2 ? CORE::splice( @{ $_[0] }, $_[1] )
      : CORE::splice( @{ $_[0] }, $_[1], $_[2], @_[3 .. $#_] )
  )
}

sub has_any {
  defined $_[1] ? !! &List::Util::any( $_[1], @{ $_[0] } )
    : !! @{ $_[0] }
}


=for Pod::Coverage first

=cut

{ no warnings 'once'; *first = *first_where }
sub first_where { &List::Util::first( $_[1], @{ $_[0] } ) }

sub last_where {
  my ($self, $cb) = @_;
  my $i = @$self;
  while ($i--) {
    local *_ = \$self->[$i];
    my $ret = $cb->();
    $self->[$i] = $_;
    return $_ if $ret;
  }
  undef
}

{ no warnings 'once';
  *first_index = *firstidx;
  *last_index  = *lastidx;
}
sub firstidx { 
  my ($self, $cb) = @_;
  for my $i (0 .. $#$self) {
    local *_ = \$self->[$i];
    return $i if $cb->();
  }
  -1
}

sub lastidx {
  my ($self, $cb) = @_;
  for my $i (CORE::reverse 0 .. $#$self) {
    local *_ = \$self->[$i];
    return $i if $cb->(); 
  }
  -1
}

{ no warnings 'once'; *zip = *mesh; }
sub mesh {
  my $max_idx = -1;
  for (@_) { $max_idx = $#$_ if $max_idx < $#$_ }
  blessed_or_pkg($_[0])->new(
    CORE::map {;
      my $idx = $_; map {; $_->[$idx] } @_
    } 0 .. $max_idx
  )
}

sub natatime {
  my @list  = @{ $_[0] };
  my $count = $_[1];
  my $itr = sub { CORE::splice @list, 0, $count };
  if (defined $_[2]) {
    while (my @nxt = $itr->()) { $_[2]->(@nxt) }
    return
  }
  $itr
}

sub rotator {
  my @list = @{ $_[0] };
  my $pos = 0;
  sub {
    my $val = $list[$pos++];
    $pos = 0 if $pos == @list;
    $val
  }
}

sub part {
  my ($self, $code) = @_;
  my @parts;
  CORE::push @{ $parts[ $code->($_) ] }, $_ for @$self;
  my $cls = blessed_or_pkg($self);
  $cls->new(
    map {; $cls->new(defined $_ ? @$_ : () ) } @parts
  )
}

sub part_to_hash {
  my ($self, $code) = @_;
  my %parts;
  CORE::push @{ $parts{ $code->($_) } }, $_ for @$self;
  my $cls = blessed_or_pkg($self);
  Module::Runtime::require_module( $cls->inflated_type );
  @parts{keys %parts} = map {; $cls->new(@$_) } values %parts;
  $cls->inflated_type->new(%parts)
}

sub bisect {
  my ($self, $code) = @_;
  my @parts = ( [], [] );
  CORE::push @{ $parts[ $code->($_) ? 0 : 1 ] }, $_ for @$self;
  my $cls = blessed_or_pkg($self);
  $cls->new( map {; $cls->new(@$_) } @parts )
}

sub nsect {
  my ($self, $sections) = @_;
  my $total = scalar @$self;
  my @parts;
  my $x = 0;
  $sections = $total if (defined $sections ? $sections : 0) > $total;
  if ($sections && $total) {
    CORE::push @{ $parts[ int($x++ * $sections / $total) ] }, $_ for @$self;
  }
  my $cls = blessed_or_pkg($self);
  $cls->new( map {; $cls->new(@$_) } @parts )
}

sub ssect {
  my ($self, $per) = @_;
  my @parts;
  my $x = 0;
  if ($per) {
    CORE::push @{ $parts[ int($x++ / $per) ] }, $_ for @$self;
  }
  my $cls = blessed_or_pkg($self);
  $cls->new( map {; $cls->new(@$_) } @parts )
}

sub tuples {
  my ($self, $size, $type, $bless) = @_;
  $size = 2 unless defined $size;
  Carp::confess "Expected a positive integer size but got $size"
    if $size < 1;

  # Autoboxed? Need to be blessed if we're to _try_coerce:
  my $cls = blessed_or_pkg($self);
  $self = $cls->new(@$self)
    if defined $type and not Scalar::Util::blessed $self;

  my $itr = do {
    my @copy = @$self;
    sub { CORE::splice @copy, 0, $size }
  };
  my @res;
  while (my @nxt = $itr->()) {
    @nxt = CORE::map {; $self->_try_coerce($type, $_) } @nxt
      if defined $type;
    CORE::push @res, $bless ? $cls->new(@nxt) : [ @nxt ];
  }

  $cls->new(@res)
}


=for Pod::Coverage fold_left foldl fold_right

=cut

{ no warnings 'once'; *foldl = *reduce; *fold_left = *reduce; }
sub reduce {
  my $pkg = caller;
  no strict 'refs';
  my $cb = $_[1];
  List::Util::reduce { 
    local (*{"${pkg}::a"}, *{"${pkg}::b"}) = (\$a, \$b);
    $a->$cb($b)
  } @{ $_[0] }
}

{ no warnings 'once'; *fold_right = *foldr; }
sub foldr {
  my $pkg = caller;
  no strict 'refs';
  my $cb = $_[1];
  List::Util::reduce {
    local (*{"${pkg}::a"}, *{"${pkg}::b"}) = (\$b, \$a);
    $a->$cb($b)
  } CORE::reverse @{ $_[0] }
}

sub rotate {
  my ($self, %params) = @_;
  $params{left} && $params{right} ?
    Carp::confess "Cannot rotate in both directions!"
  : $params{right} ?
    blessed_or_pkg($self)->new(
      @$self ? ($self->[-1], @{ $self }[0 .. ($#$self - 1)]) : ()
    )
  : blessed_or_pkg($self)->new(
      @$self ? (@{ $self }[1 .. $#$self], $self->[0]) : ()
    )
}

sub rotate_in_place {
  $_[0] = Scalar::Util::blessed $_[0] ?
    $_[0]->rotate(@_[1 .. $#_]) : rotate(@_)
}

sub items_after {
  my ($started, $lag);
  blessed_or_pkg($_[0])->new(
    CORE::grep $started ||= do { 
      my $x = $lag; $lag = $_[1]->(); $x 
    }, @{ $_[0] }
  )
}

sub items_after_incl {
  my $started;
  blessed_or_pkg($_[0])->new(
    CORE::grep $started ||= $_[1]->(), @{ $_[0] }
  )
}

sub items_before {
  my $more = 1;
  blessed_or_pkg($_[0])->new(
    CORE::grep $more &&= !$_[1]->(), @{ $_[0] }
  )
}

sub items_before_incl {
  my $more = 1; my $lag = 1;
  blessed_or_pkg($_[0])->new(
    CORE::grep $more &&= do { my $x = $lag; $lag = !$_[1]->(); $x }, 
      @{ $_[0] }
  )
}

sub pick {
  return $_[0]->shuffle if $_[1] >= @{ $_[0] };
  my %idx;
  $idx{ int rand @{ $_[0] } } = 1 until keys %idx == $_[1];
  blessed_or_pkg($_[0])->new(
    @{ $_[0] }[keys %idx]
  )
}

sub roll {
  blessed_or_pkg($_[0])->new(
    @{ $_[0] }[ 
      map {; int rand @{ $_[0] } }
        0 ..  (defined $_[1] ? $_[1] : @{ $_[0] }) - 1
    ]
  )
}

sub shuffle {
  blessed_or_pkg($_[0])->new(
    List::Util::shuffle( @{ $_[0] } )
  )
}

=for Pod::Coverage squish

=cut

{ no warnings 'once'; *squish = *squished; }
sub squished {
  # @last is a single-item array to make tracking undefs saner ->
  my (@last, @res);
  ITEM: for (@{ $_[0] }) {
    if (!@last) {
      # No items seen yet.
      $last[0] = $_; CORE::push @res, $_; next ITEM
    } elsif (!defined $_) {
      # Possibly two undefs in a row:
      next ITEM if not defined $last[0];
      # .. or not:
      $last[0] = $_; CORE::push @res, $_; next ITEM
    } elsif (!defined $last[0]) {
      # Previous was an undef (but this isn't)
      $last[0] = $_; CORE::push @res, $_; next ITEM
    }
    next ITEM if $_ eq $last[0];
    $last[0] = $_; CORE::push @res, $_;
  }
  blessed_or_pkg($_[0])->new(@res)
}

sub uniq {
  my %s;
  blessed_or_pkg($_[0])->new( CORE::grep {; not $s{$_}++ } @{ $_[0] } )
}

sub repeated {
  my %s;
  blessed_or_pkg($_[0])->new( CORE::grep {; $s{$_}++ == 1 } @{ $_[0] } )
}

sub sort_by {
  blessed_or_pkg($_[0])->new(
    __sort_by( $_[1], @{ $_[0] } )
  )
}

sub nsort_by {
  blessed_or_pkg($_[0])->new(
    __nsort_by( $_[1], @{ $_[0] } )
  )
}

sub uniq_by {
  blessed_or_pkg($_[0])->new(
    __uniq_by( $_[1], @{ $_[0] } )
  )
}

sub flatten_all {
  CORE::map {;  __flatten_all($_)  } @{ $_[0] }
}

sub flatten {
  __flatten( 
    ( defined $_[1] ? $_[1] : 0 ),
    @{ $_[0] } 
  )
}

print
  qq[<Schroedingers_hat> My sleeping pattern is cryptographically secure.\n]
unless caller;
1;

=pod

=head1 NAME

List::Objects::WithUtils::Role::Array - Array manipulation methods

=head1 SYNOPSIS

  ## Via List::Objects::WithUtils::Array ->
  use List::Objects::WithUtils 'array';

  my $array = array(qw/ a b c /);

  $array->push(qw/ d e f /);

  my @upper = $array->map(sub { uc })->all;

  if ( $array->has_any(sub { $_ eq 'a' }) ) {
    ...
  }

  my $sum = array(1 .. 10)->reduce(sub { $a + $b });

  # See below for full list of methods

  ## As a Role ->
  use Role::Tiny::With;
  with 'List::Objects::WithUtils::Role::Array';

=head1 DESCRIPTION

A L<Role::Tiny> role defining methods for creating and manipulating ARRAY-type
objects.

L<List::Objects::WithUtils::Array> consumes this role (along with
L<List::Objects::WithUtils::Role::Array::WithJunctions>) to provide B<array()> object
methods.

In addition to the methods documented below, these objects provide a
C<TO_JSON> method exporting a plain ARRAY-type reference for convenience when
feeding L<JSON::Tiny> or similar, as well as a C<TO_ZPL> method for
compatibility with L<Text::ZPL>.

=head2 Basic array methods

=head3 new

Constructs a new ARRAY-type object.

=head3 copy

Returns a shallow clone of the current object.

=head3 count

Returns the number of elements in the array.

=head3 defined

Returns true if the element at the specified position is defined.

(Available from v2.13.1)

=head3 end

Returns the last index of the array (or -1 if the array is empty).

=head3 exists

Returns true if the specified index exists in the array.

Negative indices work as you might expect:

  my $arr = array(1, 2, 3);
  $arr->set(-2 => 'foo') if $arr->exists(-2);
  # [ 1, 'foo', 3 ]

(Available from v2.13.1)

=head3 is_empty

Returns boolean true if the array is empty.

=head3 is_mutable

Returns boolean true if the hash is mutable; immutable subclasses can override
to provide a negative value.

=head3 is_immutable

The opposite of L</is_mutable>. (Subclasses do not need to override so long as
L</is_mutable> returns a correct value.)

=head3 inflate

  my $hash = $array->inflate;
  # Same as:
  # my $hash = hash( $array->all )

Inflates an array-type object to a hash-type object.

Returns an object of type L</inflated_type>; by default this is a
L<List::Objects::WithUtils::Hash>.

Throws an exception if the array contains an odd number of elements.

=head3 inflated_type

The class name that objects are blessed into when calling L</inflate>;
subclasses can override to provide their own hash-type objects.

Defaults to L<List::Objects::WithUtils::Hash>.

A consumer returning an C<inflated_type> that is not a hash-type object will
result in undefined behavior.

=head3 scalar

See L</count>.

=head3 unbless

Returns a plain C</ARRAY> reference (shallow clone).

=head2 Methods that manipulate the list

=head3 clear

Delete all elements from the array.

Returns the newly-emptied array object.

=head3 delete

Splices a given index out of the array.

Returns the removed value.

=head3 delete_when

  $array->delete_when( sub { $_ eq 'foo' } );

Splices all items out of the array for which the given subroutine evaluates to
true.

Returns a new array object containing the deleted values (possibly none).

=head3 insert

  $array->insert( $position, $value );
  $array->insert( $position, @values );

Inserts values at a given position, moving the rest of the array
rightwards.

The array will be "backfilled" (with undefs) if $position is past the end of
the array.

Returns the array object.

(Available from v2.12.1)

=head3 pop

Pops the last element off the array and returns it.

=head3 push

Pushes elements to the end of the array.

Returns the array object.

=head3 rotate_in_place

  array(1 .. 3)->rotate_in_place;             # 2, 3, 1
  array(1 .. 3)->rotate_in_place(right => 1); # 3, 1, 2

Rotates the array in-place. A direction can be given.

Also see L</rotate>, L</rotator>.

=head3 set

  $array->set( $index, $value );

Takes an array element and a new value to set.

Returns the array object.

=head3 shift

Shifts the first element off the beginning of the array and returns it.

=head3 unshift

Adds elements to the beginning of the array.

Returns the array object.

=head3 splice

  # 1- or 2-arg splice (remove elements):
  my $spliced = $array->splice(0, 2)
  # 3-arg splice (replace):
  $array->splice(0, 1, 'abc');

Performs a C<splice()> on the current list and returns a new array object
consisting of the items returned from the splice.

The existing array is modified in-place.

=head3 validated

  use Types::Standard -all;
  my $valid = array(qw/foo bar baz/)->validated(Str);

Accepts a L<Type::Tiny> type, against which each element of the current array
will be checked before being added to a new array. Returns the new array.

If the element fails the type check but can be coerced, the coerced value will
be added to the new array.

Dies with a stack trace if the value fails type checks and can't be coerced.

(You probably want an B<array_of> object from
L<List::Objects::WithUtils::Array::Typed> instead.)

See: L<Types::Standard>, L<List::Objects::Types>

=head2 Methods that retrieve items

=head3 all

Returns all elements in the array as a plain list.

=head3 bisect

  my ($true, $false) = array( 1 .. 10 )
    ->bisect(sub { $_ >= 5 })
    ->all;
  my @bigger  = $true->all;   # ( 5 .. 10 )
  my @smaller = $false->all;  # ( 1 .. 4 )

Like L</part>, but creates an array-type object containing two
partitions; the first contains all items for which the subroutine evaluates to
true, the second contains items for which the subroutine evaluates to false.

=head3 nsect

  my ($first, $second) = array( 1 .. 10 )->nsect(2)->all;
  # array( 1 .. 5 ), array( 6 .. 10 )

Like L</part> and L</bisect>, but takes an (integer) number of sets to create.

If there are no items in the list (or no sections are requested), 
an empty array-type object is returned.

If the list divides unevenly, the first set will be the largest.

Inspired by L<List::NSect>.

(Available from v2.11.1)

=head3 ssect

  my ($first, $second) = array( 1 .. 10 )->ssect(5)->all;
  # array( 1 .. 5 ), array( 6 .. 10 );

Like L</nsect> and L</bisect>, but takes an (integer) target number of items
per set.

If the list divides unevenly, the last set will be smaller than the specified
target.

Inspired by L<List::NSect>.

(Available from v2.11.1)

=head3 elements

Same as L</all>; included for consistency with similar array-type object
classes.

=head3 export

Same as L</all>; included for consistency with hash-type objects.

=head3 flatten

Flatten array objects to plain lists, possibly recursively.

C<flatten> without arguments is the same as L</all>:

  my @flat = array( 1, 2, [ 3, 4 ] )->flatten;
  #  @flat = ( 1, 2, [ 3, 4 ] );

If a depth is specified, sub-arrays are recursively flattened until the
specified depth is reached: 

  my @flat = array( 1, 2, [ 3, 4 ] )->flatten(1);
  #  @flat = ( 1, 2, 3, 4 );

  my @flat = array( 1, 2, [ 3, 4, [ 5, 6 ] ] )->flatten(1);
  #  @flat = ( 1, 2, 3, 4, [ 5, 6 ] );

This works with both ARRAY-type references and array objects:

  my @flat = array( 1, 2, [ 3, 4, array( 5, 6 ) ] )->flatten(2);
  #  @flat = ( 1, 2, 3, 4, 5, 6 );

(Specifically, consumers of this role and plain ARRAYs are flattened; other
ARRAY-type objects are left alone.)

See L</flatten_all> for flattening to an unlimited depth.

=head3 flatten_all

Returns a plain list consisting of all sub-arrays recursively
flattened. Also see L</flatten>.

=head3 get

Returns the array element corresponding to a specified index.

=head3 get_or_else

  # Expect to find an object at $pos in $array,
  # or return an empty one if $pos is undef:
  my @keys = $array->get_or_else($pos => hash)->keys->all;

  # Or pass a coderef that provides a default return value;
  # First arg is the object being operated on:
  my $item_or_first = $array->get_or_else($pos => sub { shift->get(0) });
  # Second arg is the requested index:
  my $item  = $array->get_or_else(3 => sub {
    my (undef, $pos) = @_;
    my $created = make_value_for( $pos );
    $array->set($pos => $created);
    $created
  });

Returns the element corresponding to a specified index; optionally takes a
second argument that is used as a default return value if the given index is
undef (the array remains unmodified).

If the second argument is a coderef, it is invoked on the object (with the
requested index as an argument) and its return value is taken as the default.

=head3 head

  my ($first, $rest) = $array->head;

In list context, returns the first element of the list, and a new array-type
object containing the remaining list. The original object's list is untouched.

In scalar context, returns just the first element of the array:

  my $first = $array->head;

=head3 tail

Similar to L</head>, but returns either the last element and a new array-type
object containing the remaining list (in list context), or just the last
element of the list (in scalar context).

=head3 join

  my $str = $array->join(' ');

Joins the array's elements and returns the joined string.

Defaults to ',' if no delimiter is specified.

=head3 kv

Returns an array-type object containing index/value pairs as (unblessed) ARRAYs;
this is much like L<List::Objects::WithUtils::Role::Hash/"kv">, except the
array index is the "key."

=head3 zip

=head3 mesh

  my $meshed = array(qw/ a b c /)->mesh(
    array( 1 .. 3 )
  );
  $meshed->all;  # 'a', 1, 'b', 2, 'c', 3

Takes array references or objects and returns a new array object consisting of
one element from each array, in turn, until all arrays have been traversed
fully.

You can mix and match references and objects freely:

  my $meshed = array(qw/ a b c /)->mesh(
    array( 1 .. 3 ),
    [ qw/ foo bar baz / ],
  );

(C<zip> is an alias for C<mesh>.)

=head3 part

  my $parts = array( 1 .. 8 )->part(sub { $i++ % 2 });
  # Returns array objects:
  $parts->get(0)->all;  # 1, 3, 5, 7
  $parts->get(1)->all;  # 2, 4, 6, 8

Takes a subroutine that indicates into which partition each value should be
placed.

Returns an array-type object containing partitions represented as array-type
objects, as seen above.

Skipped partitions are empty array objects:

  my $parts = array(qw/ foo bar /)->part(sub { 1 });
  $parts->get(0)->is_empty;  # true
  $parts->get(1)->is_empty;  # false

The subroutine is passed the value we are operating on, or you can use the
topicalizer C<$_>:

  array(qw/foo bar baz 1 2 3/)
    ->part(sub { m/^[0-9]+$/ ? 0 : 1 })
    ->get(1)
    ->all;   # 'foo', 'bar', 'baz'

=head3 part_to_hash

  my $people = array(qw/ann andy bob fred frankie/);
  my $parts  = $people->part_to_hash(sub { ucfirst substr $_, 0, 1 });
  $parts->get('A')->all;  # 'ann', 'andy'

Like L</part>, but partitions values into a hash-type object using the result
of the given subroutine as the hash key; the values are array-type objects.

The returned object is of type L</inflated_type>; by default this is a
L<List::Objects::WithUtils::Hash>.

(Available from v2.23.1)

=head3 pick

  my $picked = array('a' .. 'f')->pick(3);

Returns a new array object containing the specified number of elements chosen
randomly and without repetition.

If the given number is equal to or greater than the number of elements in the
list, C<pick> will return a shuffled list (same as calling L</shuffle>).

(Available from v2.26.1)

=head3 random

Returns a random element from the array.

=head3 reverse

Returns a new array object consisting of the reversed list of elements.

=head3 roll

Much like L</pick>, but repeated entries in the resultant list are allowed,
and the number of entries to return may be larger than the size of the array.

If the number of elements to return is not specified, the size of the original
array is used.

(Available from v2.26.1)

=head3 rotate

  my $leftwards  = $array->rotate;
  my $rightwards = $array->rotate(right => 1);

Returns a new array object containing the rotated list.

Also see L</rotate_in_place>, L</rotator>.

=head3 shuffle

  my $shuffled = $array->shuffle;

Returns a new array object containing the shuffled list.

=head3 sliced

  my $slice = $array->sliced(1, 3, 5);

Returns a new array object consisting of the elements retrived 
from the specified indexes.

=head3 tuples

  my $tuples = array(1 .. 7)->tuples(2);
  # Returns:
  #  array(
  #    [ 1, 2 ], 
  #    [ 3, 4 ],
  #    [ 5, 6 ],
  #    [ 7 ],
  #  )

Returns a new array object consisting of tuples (unblessed ARRAY references)
of the specified size (defaults to 2). 

C<tuples> accepts L<Type::Tiny> types as an optional second parameter; if
specified, items in tuples are checked against the type and a coercion is
attempted (if available for the given type) if the initial type-check fails:

  use Types::Standard -all;
  my $tuples = array(1 .. 7)->tuples(2 => Int);

A stack-trace is thrown if a value in a tuple cannot be made to validate.

As of v2.24.1, it's possible to make the returned tuples blessed array-type
objects (of the type of the original class) by passing a boolean true third
parameter:

  # bless()'d tuples, no type validation or coercion:
  my $tuples = array(1 .. 7)->tuples(2, undef, 'bless');

See: L<Types::Standard>, L<List::Objects::Types>

=head2 Methods that find items

=head3 grep

  my $matched = $array->grep(sub { /foo/ });

Returns a new array object consisting of the list of elements for which the
given subroutine evaluates to true. C<$_[0]> is the element being operated
on; you can also use the topicalizer C<$_>.

=head3 indexes

  my $matched = $array->indexes(sub { /foo/ });

If passed a reference to a subroutine, C<indexes> behaves like L</grep>, but
returns a new array object consisting of the list of array indexes for which
the given subroutine evaluates to true.

If no subroutine is provided, returns a new array object consisting of the
full list of indexes (like C<keys> on an array in perl-5.12+). This feature
was added in C<v2.022>.

=head3 first_where

  my $arr = array( qw/ ab bc bd de / );
  my $first = $arr->first_where(sub { /^b/ });  ## 'bc'

Returns the first element of the list for which the given sub evaluates to
true. C<$_> is set to each element, in turn, until a match is found (or we run
out of possibles).

=head3 first_index

Like L</first_where>, but return the index of the first successful match.

Returns -1 if no match is found.

=head3 firstidx

An alias for L</first_index>.

=head3 last_where

Like L</first_where>, but returns the B<last> successful match.

=head3 last_index

Like L</first_index>, but returns the index of the B<last> successful match.

=head3 lastidx

An alias for L</last_index>.

=head3 has_any

  if ( $array->has_any(sub { $_ eq 'foo' }) ) {
    ...
  }

If passed no arguments, returns boolean true if the array has any elements.

If passed a sub, returns boolean true if the sub is true for any element
of the array.

C<$_> is set to the element being operated upon.

=head3 intersection

  my $first  = array(qw/ a b c /);
  my $second = array(qw/ b c d /);
  my $intersection = $first->intersection($second);

Returns a new array object containing the list of values common between all
given array-type objects (including the invocant).

The new array object is not sorted in any predictable order.

(It may be worth noting that an intermediate hash is used; objects that
stringify to the same value will be taken to be the same.)

=head3 diff

  my $first  = array(qw/ a b c d /);
  my $second = array(qw/ b c x /);
  my @diff = $first->diff($second)->sort->all;  # (a, d, x)

The opposite of L</intersection>; returns a new array object containing the
list of values that are not common between all given array-type objects
(including the invocant).

The same constraints as L</intersection> apply.

=head3 items_after

  my $after = array( 1 .. 10 )->items_after(sub { $_ == 5 });
  ## $after contains [ 6, 7, 8, 9, 10 ]

Returns a new array object consisting of the elements of the original list
that occur after the first position for which the given sub evaluates to true.

=head3 items_after_incl

Like L</items_after>, but include the item that evaluated to true.

=head3 items_before

The opposite of L</items_after>.

=head3 items_before_incl

The opposite of L</items_after_incl>.

=head2 Methods that iterate the list

=head3 map

  my $lowercased = $array->map(sub { lc });
  # Same as:
  my $lowercased = $array->map(sub { lc $_[0] });

Evaluates a given subroutine for each element of the array, and returns a new
array object. C<$_[0]> is the element being operated on; you can also use
the topicalizer C<$_>.

Also see L</mapval>.

=head3 mapval

  my $orig = array(1, 2, 3);
  my $incr = $orig->mapval(sub { ++$_ });

  $incr->all;  # (2, 3, 4)
  $orig->all;  # Still untouched

An alternative to L</map>. C<$_> is a copy, rather than an alias to the
current element, and the result is retrieved from the altered C<$_> rather
than the return value of the block.

This feature is borrowed from L<Data::Munge> by Lukas Mai (CPAN: MAUKE).

=head3 natatime

  my $iter = array( 1 .. 7 )->natatime(3);
  $iter->();  ##  ( 1, 2, 3 )
  $iter->();  ##  ( 4, 5, 6 )
  $iter->();  ##  ( 7 )

  array( 1 .. 7 )->natatime(3, sub { my @vals = @_; ... });

Returns an iterator that, when called, produces a list containing the next
'n' items.

If given a coderef as a second argument, it will be called against each
bundled group.

=head3 rotator

  my $rot = array(qw/cat sheep mouse/);
  $rot->();  ## 'cat'
  $rot->();  ## 'sheep'
  $rot->();  ## 'mouse'
  $rot->();  ## 'cat'

Returns an iterator that, when called, produces the next element in the array;
when there are no elements left, the iterator returns to the start of the
array.

See also L</rotate>, L</rotate_in_place>.

(Available from v2.7.1)

=head3 reduce

  my $sum = array(1,2,3)->reduce(sub { $a + $b });

Reduces the array by calling the given subroutine for each element of the
list. C<$a> is the accumulated value; C<$b> is the current element. See
L<List::Util/"reduce">.

Prior to C<v2.18.1>, C<$_[0]> and C<$_[1]> must be used in place of C<$a> and
C<$b>, respectively. Using positional arguments may make for cleaner syntax in
some cases:

  my $divide = sub {
    my ($acc, $next) = @_;
    $acc / $next
  };
  my $q = $array->reduce($divide);

An empty list reduces to C<undef>.

This is a "left fold" -- B<foldl> is an alias for L</reduce> (as of v2.17.1).

See also: L</foldr>

=head3 foldr

  my $result = array(2,3,6)->foldr(sub { $_[1] / $_[0] });  # 1

Reduces the array by calling the given subroutine for each element of the
list starting at the end (the opposite of L</reduce>).

Unlike L</reduce> (foldl), the first argument passed to the subroutine is the
current element; the second argument is the accumulated value.

An empty list reduces to C<undef>.

(Available from v2.17.1)

=head3 visit

  $arr->visit(sub { warn "array contains: $_" });

Executes the given subroutine against each element sequentially; in practice
this is much like L</map>, except the return value is thrown away.

Returns the original array object.

(Available from v2.7.1)

=head2 Methods that sort the list

=head3 sort

  my $sorted = $array->sort(sub { $a cmp $b });

Returns a new array object consisting of the list sorted by the given
subroutine.

Prior to version 2.18.1, positional arguments (C<$_[0]> and C<$_[1]>) must be
used in place of C<$a> and C<$b>, respectively. 

=head3 sort_by

  my $array = array(
    { id => 'a' },
    { id => 'c' },
    { id => 'b' },
  );
  my $sorted = $array->sort_by(sub { $_->{id} });

Returns a new array object consisting of the list of elements sorted via a
stringy comparison using the given sub. 
See L<List::UtilsBy>.

Uses L<List::UtilsBy::XS> if available.

=head3 nsort_by

Like L</sort_by>, but using numerical comparison.

=head3 repeated

  my $repeats = $array->repeated;

The opposite of L</uniq>; returns a new array object containing only repeated
elements.

(The same constraints apply with regards to stringification; see L</uniq>)

(Available from v2.26.1)

=head3 squished

  my $squished = array(qw/a a b a b b/)->squished;
  # $squished = array( 'a', 'b', 'a', 'b' );

Similar to L</uniq>, but only consecutively repeated values are removed from
the returned (new) array object.

The same constraints as L</uniq> apply with regards to stringification, but
multiple C<undef>s in a row will also be squished.

(Available from v2.27.1)

=head3 uniq

  my $unique = $array->uniq;

Returns a new array object containing only unique elements from the original
array.

(It may be worth noting that this takes place via an intermediate hash;
objects that stringify to the same value are not unique, even if they are
different objects. L</uniq_by> plus L<Scalar::Util/"refaddr"> may help you
there.)

=head3 uniq_by

  my $array = array(
    { id => 'a' },
    { id => 'a' },
    { id => 'b' },
  );
  my $unique = $array->uniq_by(sub { $_->{id} });

Returns a new array object consisting of the list of elements for which the
given sub returns unique values.

Uses L<List::UtilsBy::XS> if available; falls back to L<List::UtilsBy> if not.

=head1 NOTES FOR CONSUMERS

If creating your own consumer of this role, some extra effort is required to
make C<$a> and C<$b> work in sort statements without warnings; an example with
a custom exported constructor (and junction support) might look something like:

  package My::Custom::Array;
  use strictures 2;
  require Role::Tiny;
  Role::Tiny->apply_roles_to_package( __PACKAGE__,
    qw/
      List::Objects::WithUtils::Role::Array
      List::Objects::WithUtils::Role::Array::WithJunctions
      My::Custom::Array::Role
     /
  );

  use Exporter ();
  our @EXPORT = 'myarray';
  sub import {
    # touch $a/$b in caller to avoid 'used only once' warnings:
    my $pkg = caller;
    { no strict 'refs';
      ${"${pkg}::a"} = ${"${pkg}::a"};
      ${"${pkg}::b"} = ${"${pkg}::b"};
    }
    goto &Exporter::import
  }

  sub myarray { __PACKAGE__->new(@_) }

=head1 SEE ALSO

L<List::Objects::WithUtils>

L<List::Objects::WithUtils::Array>

L<List::Objects::WithUtils::Array::Immutable>

L<List::Objects::WithUtils::Array::Typed>

L<List::Objects::WithUtils::Role::Array::WithJunctions>

L<Data::Perl>

L<List::Util>

L<List::UtilsBy>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Portions of this code were contributed by Toby Inkster (CPAN: TOBYINK).

Portions of this code are derived from L<Data::Perl> by Matthew Phillips
(MATTP), Graham Knop (HAARG) et al.

Portions of this code are inspired by L<List::MoreUtils>-0.33 by Adam Kennedy (ADAMK), 
Tassilo von Parseval, and Aaron Crane.

L</part_to_hash> was inspired by Yanick Champoux in
L<https://github.com/perl5-utils/List-MoreUtils/pull/15>

Licensed under the same terms as Perl.

=cut

