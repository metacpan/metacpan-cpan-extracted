use 5.006;
use strict;
use warnings;

package LINQ::Collection;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Role::Tiny;
use LINQ::Util::Internal ();

requires qw( to_list );

my $_coerce = sub {
	my ( $thing ) = @_;
	
	require Scalar::Util;
	if ( Scalar::Util::blessed( $thing ) and $thing->DOES( __PACKAGE__ ) ) {
		return $thing;
	}
	
	if ( ref( $thing ) eq 'ARRAY' ) {
		require LINQ::Array;
		return LINQ::Array::->new( $thing );
	}
	
	LINQ::Util::Internal::throw(
		"CallerError",
		message => "Expected a LINQ collection; got '$thing'"
	);
};

sub select {
	my $self = shift;
	my $map  = LINQ::Util::Internal::assert_code( @_ );
	
	my $iter = $self->to_iterator;
	my $stopped;
	
	require LINQ;
	LINQ::LINQ(
		sub {
			# uncoverable branch true
			return LINQ::END() if $stopped;
			my @got = $iter->();
			if ( @got ) {
				local $_;
				return scalar $map->( $_ = $got[0] );
			}
			++$stopped;
			return LINQ::END();
		}
	);
} #/ sub select

sub where {
	my $self   = shift;
	my $filter = LINQ::Util::Internal::assert_code( @_ );
	
	my $iter = $self->to_iterator;
	my $stopped;
	
	require LINQ;
	LINQ::LINQ(
		sub {
			GETVAL: {
				return LINQ::END() if $stopped;
				my @got = $iter->();
				if ( @got ) {
					local $_;
					my $pass = $filter->( $_ = $got[0] );
					return $got[0] if $pass;
					redo GETVAL;
				}
				++$stopped;
				return LINQ::END();
			} #/ GETVAL:
		}
	);
} #/ sub where

sub select_many {
	my $self = shift;
	my $map  = LINQ::Util::Internal::assert_code( @_ );
	
	my $outer = $self->to_iterator;
	my $inner;
	my $end;
	
	require LINQ;
	LINQ::LINQ(
		sub {
			BODY: {
				return LINQ::END() if $end;
				if ( not $inner ) {
					$inner = $outer->();
					if ( defined $inner ) {
						local $_;
						$inner = $map->( $_ = $inner )->$_coerce->to_iterator;
					}
					else {
						$end = 1;
						redo BODY;
					}
				} #/ if ( not $inner )
				my @got = $inner->();
				if ( not @got ) {
					undef $inner;
					redo BODY;
				}
				return @got;
			} #/ BODY:
		}
	);
} #/ sub select_many

sub min {
	my $self = shift;
	return $self->select( @_ )->min if @_;
	require List::Util;
	&List::Util::min( $self->to_list );
}

sub max {
	my $self = shift;
	return $self->select( @_ )->max if @_;
	require List::Util;
	&List::Util::max( $self->to_list );
}

sub sum {
	my $self = shift;
	return $self->select( @_ )->sum if @_;
	require List::Util;
	&List::Util::sum( $self->to_list );
}

sub average {
	my $self = shift;
	$self->sum( @_ ) / $self->count();
}

sub aggregate {
	my $self    = shift;
	my $code    = LINQ::Util::Internal::assert_code( shift );
	my $wrapper = sub { $code->( $a, $b ) };
	require List::Util;
	&List::Util::reduce( $wrapper, @_, $self->to_list );
}

my $_prepare_join = sub {
	my $x = shift;
	my $y = shift;
	
	my $hint   = ref( $_[0] ) ? -inner : shift( @_ );
	my $x_keys = LINQ::Util::Internal::assert_code( shift );
	my $y_keys = LINQ::Util::Internal::assert_code( shift );
	my $joiner = LINQ::Util::Internal::assert_code( @_ );
	
	$hint =~ /\A-(inner|left|right|outer)\z/
		or LINQ::Util::Internal::throw(
		"CallerError",
		message => "Expected a recognized join type; got '$hint'"
		);
		
	my @x_mapped =
		$x->select( sub { [ scalar( $x_keys->( $_[0] ) ), $_[0] ] } )->to_list;
	my @y_mapped =
		$y->select( sub { [ scalar( $y_keys->( $_[0] ) ), $_[0] ] } )->to_list;
		
	return ( \@x_mapped, \@y_mapped, $hint, $joiner );
};

sub join {
	my ( $x_mapped, $y_mapped, $hint, $joiner ) = $_prepare_join->( @_ );
	
	my @joined;
	my ( @found_x, @found_y );
	
	for my $Xi ( 0 .. $#$x_mapped ) {
		my $X = $x_mapped->[$Xi];
		
		for my $Yi ( 0 .. $#$y_mapped ) {
			my $Y = $y_mapped->[$Yi];
			
			if ( $X->[0] eq $Y->[0] ) {
				my $a = $X->[1];
				my $b = $Y->[1];
				$found_x[$Xi]++;
				$found_y[$Yi]++;
				
				push @joined, scalar $joiner->( $a, $b );
			}
		} #/ for my $Yi ( 0 .. $#$y_mapped)
	} #/ for my $Xi ( 0 .. $#$x_mapped)
	
	if ( $hint eq -left or $hint eq -outer ) {
		for my $Xi ( 0 .. $#$x_mapped ) {
			next if $found_x[$Xi];
			my $a = $x_mapped->[$Xi][1];
			my $b = undef;
			push @joined, scalar $joiner->( $a );
		}
	}
	
	if ( $hint eq -right or $hint eq -outer ) {
		for my $Yi ( 0 .. $#$y_mapped ) {
			next if $found_y[$Yi];
			my $a = undef;
			my $b = $y_mapped->[$Yi][1];
			push @joined, scalar $joiner->( undef, $b );
		}
	}
	
	LINQ::Util::Internal::create_linq( \@joined );
} #/ sub join

sub group_join {
	my ( $x_mapped, $y_mapped, $hint, $joiner ) = $_prepare_join->( @_ );
	
	$hint =~ /\A-(left|inner)\z/ or LINQ::Util::Internal::throw(
		"CallerError",
		message => "Join type '$hint' not supported for group_join",
	);
	
	my @joined;
	my ( @found_x, @found_y );
	
	for my $Xi ( 0 .. $#$x_mapped ) {
		my $X     = $x_mapped->[$Xi];
		my @group = map $_->[1], grep $X->[0] eq $_->[0], @$y_mapped;
		
		if ( @group or $hint eq -left ) {
			my $a = $X->[1];
			my $b = LINQ::Util::Internal::create_linq( \@group );
			push @joined, scalar $joiner->( $a, $b );
		}
	} #/ for my $Xi ( 0 .. $#$x_mapped)
	
	LINQ::Util::Internal::create_linq( \@joined );
} #/ sub group_join

sub take {
	my $self = shift;
	my ( $n ) = @_;
	$self->take_while( sub { $n-- > 0 } );
}

sub take_while {
	my $self    = shift;
	my $filter  = LINQ::Util::Internal::assert_code( @_ );
	my $stopped = 0;
	my $iter    = $self->to_iterator;
	
	require LINQ;
	LINQ::LINQ(
		sub {
			# uncoverable branch true
			return LINQ::END() if $stopped;
			my @got = $iter->();
			if ( !@got or !$filter->( $_ = $got[0] ) ) {
				$stopped++;
				return LINQ::END();
			}
			return $got[0];
		}
	);
} #/ sub take_while

sub skip {
	my $self = shift;
	my ( $n ) = @_;
	$self->skip_while( sub { $n-- > 0 } );
}

sub skip_while {
	my $self    = shift;
	my $filter  = LINQ::Util::Internal::assert_code( @_ );
	my $stopped = 0;
	my $started = 0;
	my $iter    = $self->to_iterator;
	
	require LINQ;
	LINQ::LINQ(
		sub {
			SKIPPING: {
				return LINQ::END() if $stopped;
				my @got = $iter->();
				if ( !@got ) {
					$stopped++;
					redo SKIPPING;
				}
				return $got[0] if $started;
				if ( $filter->( $_ = $got[0] ) ) {
					redo SKIPPING;
				}
				++$started;
				return $got[0];
			} #/ SKIPPING:
		}
	);
} #/ sub skip_while

sub concat {
	my @collections = map $_->to_iterator, @_;
	my $idx = 0;
	
	require LINQ;
	LINQ::LINQ(
		sub {
			FIND_NEXT: {
				return LINQ::END() if not @collections;
				
				my @got = $collections[0]->();
				if ( not @got ) {
					shift @collections;
					redo FIND_NEXT;
				}
				
				return $got[0];
			} #/ FIND_NEXT:
		}
	);
} #/ sub concat

sub order_by {
	my $self = shift;
	my ( $hint, $keygen ) = ( -numeric, undef );
	if ( @_ ) {
		$hint   = ref( $_[0] ) ? -numeric : shift( @_ );
		$keygen = @_ ? LINQ::Util::Internal::assert_code( @_ ) : undef;
	}
	
	if ( not $keygen ) {
		if ( $hint eq -string ) {
			return LINQ::Util::Internal::create_linq(
				[ sort { $a cmp $b } $self->to_list ] );
		}
		elsif ( $hint eq -numeric ) {
			return LINQ::Util::Internal::create_linq(
				[ sort { $a <=> $b } $self->to_list ] );
		}
	} #/ if ( not $keygen )
	
	if ( $hint eq -string ) {
		return LINQ::Util::Internal::create_linq(
			[
				map $_->[1],
				sort { $a->[0] cmp $b->[0] }
					map [ $keygen->( $_ ), $_ ],
				$self->to_list
			]
		);
	} #/ if ( $hint eq -string )
	
	elsif ( $hint eq -numeric ) {
		return LINQ::Util::Internal::create_linq(
			[
				map $_->[1],
				sort { $a->[0] <=> $b->[0] }
					map [ $keygen->( $_ ), $_ ],
				$self->to_list
			]
		);
	} #/ elsif ( $hint eq -numeric)
	
	LINQ::Util::Internal::throw(
		"CallerError",
		message => "Expected '-numeric' or '-string'; got '$hint'"
	);
} #/ sub order_by

sub then_by {
	LINQ::Util::Internal::throw( "Unimplemented", method => "then_by" );
}

sub order_by_descending {
	my $self = shift;
	$self->order_by( @_ )->reverse;
}

sub then_by_descending {
	LINQ::Util::Internal::throw( "Unimplemented", method => "then_by_descending" );
}

sub reverse {
	my $self = shift;
	LINQ::Util::Internal::create_linq(
		[ reverse( $self->to_list ) ],
	);
}

sub group_by {
	my $self   = shift;
	my $keygen = LINQ::Util::Internal::assert_code( @_ );
	
	my @keys;
	my %values;
	
	for ( $self->to_list ) {
		my $key = $keygen->( $_ );
		unless ( $values{$key} ) {
			push @keys, $key;
			$values{$key} = [];
		}
		push @{ $values{$key} }, $_;
	}
	
	require LINQ::Grouping;
	LINQ::Util::Internal::create_linq(
		[
			map 'LINQ::Grouping'->new(
				key    => $_,
				values => LINQ::Util::Internal::create_linq( $values{$_} ),
			),
			@keys
		]
	);
} #/ sub group_by

sub distinct {
	my $self = shift;
	my $compare =
		@_ ? LINQ::Util::Internal::assert_code( @_ ) : sub { $_[0] == $_[1] };
		
	my @already;
	$self->where(
		sub {
			my $maybe = $_[0];
			for my $got ( @already ) {
				return !!0 if $compare->( $maybe, $got );
			}
			push @already, $maybe;
			return !!1;
		}
	);
} #/ sub distinct

sub union {
	my $self = shift;
	my ( $other, @compare ) = @_;
	$self->concat( $other )->distinct( @compare );
}

sub intersect {
	my $self  = shift;
	my $other = shift;
	my @compare =
		@_ ? LINQ::Util::Internal::assert_code( @_ ) : sub { $_[0] == $_[1] };
	$self->where( sub { $other->contains( $_, @compare ) } );
}

sub except {
	my $self  = shift;
	my $other = shift;
	my @compare =
		@_ ? LINQ::Util::Internal::assert_code( @_ ) : sub { $_[0] == $_[1] };
	$self->where( sub { not $other->contains( $_, @compare ) } );
}

sub sequence_equal {
	my $self = shift;
	my ( $other, @compare ) = @_;
	
	my $compare;
	if ( @compare ) {
		$compare = LINQ::Util::Internal::assert_code( @compare );
	}
	
	my $iter1 = $self->to_iterator;
	my $iter2 = $other->to_iterator;
	
	while ( 1 ) {
		my @got1 = $iter1->();
		my @got2 = $iter2->();
		
		if ( not @got1 ) {
			if ( @got2 ) {
				return !!0;
			}
			else {
				return !!1;
			}
		}
		elsif ( not @got2 ) {
			return !!0;
		}
		
		if ( $compare ) {
			return !!0 unless $compare->( $got1[0], $got2[0] );
		}
		else {
			return !!0 unless $got1[0] == $got2[0];
		}
	} #/ while ( 1 )
} #/ sub sequence_equal

my $_with_default = sub {
	my $self    = shift;
	my $method  = shift;
	my @args    = @_;
	my $default = pop( @args );
	
	my $return;
	eval { $return = $self->$method( @args ); 1 } or do {
		my $e = $@;    # catch
		
		# Rethrow any non-blessed errors.
		require Scalar::Util;
		die( $e ) unless Scalar::Util::blessed( $e );
		
		# Rethrow any errors of the wrong class.
		die( $e )
			unless $e->isa( 'LINQ::Exception::NotFound' )
			|| $e->isa( 'LINQ::Exception::MultipleFound' );
			
		# Rethrow any errors which resulted from the wrong source.
		die( $e ) unless $e->collection == $self;
		
		return $default;
	};
	
	return $return;
};

sub first {
	my $self  = shift;
	my $found = @_ ? $self->where( @_ ) : $self;
	return $found->element_at( 0 ) if $found->count > 0;
	LINQ::Util::Internal::throw( 'NotFound', collection => $self );
}

sub first_or_default {
	shift->$_with_default( first => @_ );
}

sub last {
	my $self  = shift;
	my $found = @_ ? $self->where( @_ ) : $self;
	return $found->element_at( -1 ) if $found->count > 0;
	LINQ::Util::Internal::throw( 'NotFound', collection => $self );
}

sub last_or_default {
	shift->$_with_default( last => @_ );
}

sub single {
	my $self  = shift;
	my $found = @_ ? $self->where( @_ ) : $self;
	return $found->element_at( 0 ) if $found->count == 1;
	$found->count == 0
		? LINQ::Util::Internal::throw( 'NotFound', collection => $self )
		: LINQ::Util::Internal::throw( 'MultipleFound', collection => $self,
		found => $found );
}

sub single_or_default {
	shift->$_with_default( single => @_ );
}

sub element_at {
	my $self = shift;
	my ( $i ) = @_;
	
	my @list = $self->to_list;
	
	if ( $i > $#list ) {
		LINQ::Util::Internal::throw( 'NotFound', collection => $self );
	}
	
	if ( $i < 0 - @list ) {
		LINQ::Util::Internal::throw( 'NotFound', collection => $self );
	}
	
	$list[$i];
} #/ sub element_at

sub element_at_or_default {
	shift->$_with_default( element_at => @_ );
}

sub any {
	my $self = shift;
	my $iter = @_ ? $self->where( @_ )->to_iterator : $self->to_iterator;
	my @got  = $iter->();
	!!scalar @got;
}

sub all {
	my $self  = shift;
	my $check = LINQ::Util::Internal::assert_code( @_ );
	my $iter  = $self->where( sub { not $check->( $_ ) } )->to_iterator;
	my @got   = $iter->();
	!scalar @got;
}

sub contains {
	my $self = shift;
	my ( $x, @args ) = @_;
	
	if ( @args ) {
		splice( @args, 1, 0, $x );
		return $self->any( LINQ::Util::Internal::assert_code( @args ) );
	}
	
	my $iter = $self->to_iterator;
	while ( 1 ) {
		my @got = $iter->() or return !!0;
		return !!1 if $got[0] == $x;
	}
} #/ sub contains

sub count {
	my $self = shift;
	return $self->where( @_ )->count if @_;
	my @list = $self->to_list;
	return scalar( @list );
}

sub to_array {
	my $self = shift;
	[ $self->to_list ];
}

sub to_dictionary {
	my $self = shift;
	my ( $keygen ) = LINQ::Util::Internal::assert_code( @_ );
	+{ map +( $keygen->( $_ ), $_ ), $self->to_list };
}

sub to_lookup {
	my $self = shift;
	$self->to_dictionary( @_ );
}

sub to_iterator {
	my $self = shift;
	my @list = $self->to_list;
	sub { @list ? shift( @list ) : () };
}

sub cast {
	my $self = shift;
	my ( $type ) = @_;
	
	my $cast = $self->of_type( @_ );
	return $cast if $self->count == $cast->count;
	
	LINQ::Util::Internal::throw( "Cast", collection => $self, type => $type );
}

sub of_type {
	my $self = shift;
	my ( $type ) = @_;
	
	require Scalar::Util;
	
	unless ( Scalar::Util::blessed( $type ) and $type->can( 'check' ) ) {
		LINQ::Util::Internal::throw(
			"CallerError",
			message => "Expected type constraint; got '$type'",
		);
	}
	
	if ( $type->isa( 'Type::Tiny' ) ) {
		my $check = $type->compiled_check;
		
		if ( $type->has_coercion ) {
			my $coercion = $type->coercion->compiled_coercion;
			return $self->select( $coercion )->where( $check );
		}
		
		return $self->where( $check );
	} #/ if ( $type->isa( 'Type::Tiny'...))
	
	if ( $type->can( 'has_coercion' ) and $type->has_coercion ) {
		return $self
			->select( sub { $type->coerce( $_ ) } )
			->where( sub { $type->check( $_ ) } );
	}
	
	return $self->where( sub { $type->check( $_ ) } );
} #/ sub of_type

sub zip {
	my $self  = shift;
	my $other = shift;
	my $map   = LINQ::Util::Internal::assert_code( @_ );
	
	my $iter1 = $self->to_iterator;
	my $iter2 = $other->to_iterator;
	my @results;
	
	require LINQ;
	LINQ::LINQ(
		sub {
			my @r1 = $iter1->();
			my @r2 = $iter2->();
			return LINQ::END() unless @r1 && @r2;
			$map->( $r1[0], $r2[0] );
		}
	);
} #/ sub zip

sub default_if_empty {
	my $self = shift;
	my $item = shift;
	
	if ( $self->count == 0 ) {
		return LINQ::Util::Internal::create_linq( [$item] );
	}
	
	return $self;
} #/ sub default_if_empty

sub foreach {
	my $self = shift;
	my $code = LINQ::Util::Internal::assert_code( @_ );
	
	my $ok = eval {
		local $LINQ::IN_LOOP = 1;
		$self->where( sub { $code->( $_ ); 0 } )->to_list;
		1;
	};
	if ( not $ok ) {
		my $e = $@;
		require Scalar::Util;
		die( $e ) unless Scalar::Util::blessed( $e );
		die( $e ) unless $e->isa( 'LINQ::LAST' );
	}
	return;
} #/ sub foreach

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ - the interface which all LINQ collections share

=head1 SYNOPSIS

  use feature 'say';
  use LINQ 'LINQ';
  
  my $double_even_numbers =
    LINQ( [1..100] )
      ->where( sub { $_ % 2 == 0 } )
      ->select( sub { $_ * 2 } );
  
  if ( not $double_even_numbers->DOES( 'LINQ::Collection' ) ) {
    die "What? But you said they all do it!";
  }
  
  for my $n ( $double_even_numbers->to_list ) {
    say $n;
  }

=head1 DESCRIPTION

Objects returned by the C<< LINQ() >>, C<< LINQ::Repeat() >>, and
C<< LINQ::Range() >> functions all provide the LINQ::Collection interface.
Many of the methods in this interface also return new objects which provide
this interface.

=head1 METHODS

Many methods take a parameter "CALLABLE". This means they can accept a
coderef, an object overloading C<< &{} >>, or an arrayref where the first
item is one of the previous two things and the remainder are treated as
arguments to curry to the first argument. A quoted regexp C<< qr/.../ >> can
also be used as a callable.

If using an arrayref, it is generally permissable to flatten it into a
list, unless otherwise noted. An example of this can be seen in the
documentation for C<select>.

=over

=item C<< select( CALLABLE ) >>

LINQ's version of C<map>, except that the code given is always called in
scalar context, being expected to return exactly one result.

Returns a LINQ::Collection of the results.

  my $people = LINQ( [
    { name => "Alice", age => 32 },
    { name => "Bob",   age => 31 },
    { name => "Carol", age => 34 },
  ] );
  
  my $names = $people->select( sub {
    return $_->{name};
  } );
  
  for my $name ( $names->to_list ) {
    print "$name\n";
  }

Another way of doing the same thing, using currying:

  my $people = LINQ( [
    { name => "Alice", age => 32 },
    { name => "Bob",   age => 31 },
    { name => "Carol", age => 34 },
  ] );
  
  my $BY_HASH_KEY = sub {
    my ($key) = @_;
    return $_->{$key};
  };
  
  my $names = $people->select( $BY_HASH_KEY, 'name' );
  
  for my $name ( $names->to_list ) {
    print "$name\n";
  }

=item C<< select_many( CALLABLE ) >>

If you wanted C<select> to be able to return a list like C<map> does, then
C<select_many> is what you want. However, rather than returning a Perl list,
your callable should return a LINQ::Collection or an arrayref.

=item C<< where( CALLABLE ) >>

LINQ's version of C<grep>. Returns a LINQ::Collection of the filtered results.

  my $people = LINQ( [
    { name => "Alice", age => 32 },
    { name => "Bob",   age => 31 },
    { name => "Carol", age => 34 },
  ] );
  
  my $young_people = $people->where( sub {
    return $_->{age} < 33;
  } );

=item C<< min( CALLABLE? ) >>

Returns the numerically lowest value in the collection.

  my $lowest = LINQ( [ 5, 1, 2, 3 ] )->min;   # ==> 1

If a callable is provided, then C<select> will be called and the minimum of the
result will be returned.

  my $people = LINQ( [
    { name => "Alice", age => 32 },
    { name => "Bob",   age => 31 },
    { name => "Carol", age => 34 },
  ] );
  
  my $lowest_age = $people->min( sub { $_->{age} } );   # ==> 31

If you need more flexible comparison (e.g. non-numeric comparison), use
C<order_by> followed by C<first>.

=item C<< max( CALLABLE? ) >>

Like C<min>, but returns the numerically highest value.

=item C<< sum( CALLABLE? ) >>

Like C<min>, but returns the sum of all values in the collection.

=item C<< average( CALLABLE? ) >>

Takes C<sum>, and divides by the count of items in the collection.

  my $people = LINQ( [
    { name => "Alice", age => 32 },
    { name => "Bob",   age => 31 },
    { name => "Carol", age => 34 },
  ] );
  
  my $average_age = $people->average( sub {
    return $_->{age};
  } );   # ==> 32.33333

=item C<< aggregate( CALLABLE, INITIAL? ) >>

LINQ's version of C<reduce> (from L<List::Util>). We pass C<< $a >> and
C<< $b >> as the last arguments to CALLABLE, rather than using the package
variables like List::Util does.

The CALLABLE must not be a flattened list, but may still be an arrayref.
INITIAL is an initial value.

  my $people = LINQ( [
    { name => "Alice", age => 32 },
    { name => "Bob",   age => 31 },
    { name => "Carol", age => 34 },
  ] );
  
  my dotted_names = $people
    ->select( sub { $_->{name} } )
    ->aggregate( sub {
       my ( $a, $b ) = @_;
       return "$a.$b";
    } );
  
  print "$dotted_names\n";  # ==> Alice.Bob.Carol

=item C<< join( Y, HINT?, X_KEYS, Y_KEYS, JOINER ) >>

This is akin to an SQL join.

  my $people = LINQ( [
    { name => "Alice", dept => 'Marketing' },
    { name => "Bob",   dept => 'IT' },
    { name => "Carol", dept => 'IT' },
  ] );
  
  my $departments = LINQ( [
    { dept_name => 'Accounts',  cost_code => 1 },
    { dept_name => 'IT',        cost_code => 7 },
    { dept_name => 'Marketing', cost_code => 8 },
  ] );
  
  my $BY_HASH_KEY = sub {
    my ($key) = @_;
    return $_->{$key};
  };
  
  my $joined = $people->join(
    $departments,
    -inner,                        # inner join
    [ $BY_HASH_KEY, 'dept' ],      # select from $people 
    [ $BY_HASH_KEY, 'dept_name' ], # select from $departments
    sub {
      my ( $person, $dept ) = @_;
      return {
        name         => $person->{name},
        dept         => $person->{dept},
        expense_code => $dept->{cost_code},
      };
    },
  );

Hints C<< -inner >>, C<< -left >>, C<< -right >>, and C<< -outer >> are
supported, analagous to the joins with the same names in SQL.

X_KEYS and Y_KEYS are non-list callables which return the values to join the
two collections by.

JOINER is a callable (which may be a flattened list) which is passed items
from each of the two collections and should return a new item. In the case
of left/right/outer joins, one of those items may be undef.

=item C<< group_join( Y, HINT?, X_KEYS, Y_KEYS, JOINER ) >>

Similar to C<group> except that rather than JOINER being called for every
X/Y combination, all the Ys for a particular X are put in a collection, and
the JOINER is called for each X and passed the collection of Ys.

The only hints supported are C<< -inner >> and C<< -left >>.

This is best explained with a full example:

  my $departments = LINQ( [
    { dept_name => 'Accounts',  cost_code => 1 },
    { dept_name => 'IT',        cost_code => 7 },
    { dept_name => 'Marketing', cost_code => 8 },
  ] );
  
  my $people = LINQ( [
    { name => "Alice", dept => 'Marketing' },
    { name => "Bob",   dept => 'IT' },
    { name => "Carol", dept => 'IT' },
  ] );
  
  my $BY_HASH_KEY = sub {
    my ($key) = @_;
    return $_->{$key};
  };
  
  my $joined = $departments->group_join(
    $people,
    -left,                         # left join
    [ $BY_HASH_KEY, 'dept_name' ], # select from $departments
    [ $BY_HASH_KEY, 'dept' ],      # select from $people 
    sub {
      my ( $dept, $people ) = @_;  # $people is a LINQ::Collection 
      my $names = $people->select( $BY_HASH_KEY, 'name' )->to_array;
      return {
        dept      => $dept->{dept_name},
        cost_code => $dept->{cost_code},
        people    => $names,
      };
    },
  );
  
  # [
  #   {
  #     'cost_code' => 1,
  #     'dept' => 'Accounts',
  #     'people' => []
  #   },
  #   {
  #     'cost_code' => 7,
  #     'dept' => 'IT',
  #     'people' => [
  #       'Bob',
  #       'Carol'
  #     ]
  #   },
  #   {
  #     'cost_code' => 8,
  #     'dept' => 'Marketing',
  #     'people' => [
  #       'Alice'
  #     ]
  #   }

=item C<< take( N ) >>

Takes just the first N items from a collection, returning a new collection.

=item C<< take_while( CALLABLE ) >>

Takes items from the collection, stopping at the first item where CALLABLE
returns false.

If CALLABLE dies, there are some issues on older versions of Perl with the
error message getting lost.

=item C<< skip( N ) >>

Skips the first N items from a collection, and returns the rest as a new
collection.

=item C<< skip_while( CALLABLE ) >>

Skips the first items from a collection while CALLABLE returns true, and
returns the rest as a new collection.

=item C<< concat( COLLECTION ) >>

Returns a new collection by concatenating this collection with another
collection.

  my $deck_of_cards = $red_cards->concat( $black_cards );

=item C<< order_by( HINT?, CALLABLE? ) >>

HINT may be C<< -numeric >> (the default) or C<< -string >>.

If CALLABLE is given, it should return a number or string to sort by.

  my $sorted = $people->order_by(
    -string,
    [ $BY_HASH_KEY, 'name' ]   # CALLABLE as an arrayref
  );

=item C<< then_by( HINT?, CALLABLE ) >>

Not implemented.

=item C<< order_by_descending( HINT?, CALLABLE ) >>

Like C<order_by> but uses reverse order.

=item C<< then_by_descending( HINT?, CALLABLE ) >>

Not implemented.

=item C<< reverse >>

Reverses the order of the collection.

=item C<< group_by( CALLABLE ) >>

Groups the items by the key returned by CALLABLE.

The collection of groups is a LINQ::Collection and each grouping is a
LINQ::Grouping. LINQ::Grouping provides two accessors: C<key> and C<values>,
with C<values> returning a LINQ::Collection of items.

  my $people = LINQ( [
    { name => "Alice", dept => 'Marketing' },
    { name => "Bob",   dept => 'IT' },
    { name => "Carol", dept => 'IT' },
  ] );
  
  my $groups = $people->group_by( sub { $_->{dept} } );
  
  for my $group ( $groups->to_list ) {
    print "Dept: ", $group->key, "\n";
    
    for my $person ( $group->values->to_list ) {
      print " - ", $person->{name};
    }
  }

=item C<< distinct( CALLABLE? ) >>

Returns a new collection without any duplicates which were in the original.

If CALLABLE is provided, this will be used to determine when two items are
considered identical/equivalent. Otherwise, numeric equality is used. 

=item C<< union( COLLECTION, CALLABLE? ) >>

Returns a new collection formed from the union of both collections.

  my $first  = LINQ( [ 1, 2, 3, 4 ] );
  my $second = LINQ( [ 3, 4, 5, 6 ] );
  
  $first->union( $second )->to_array;  # ==> [ 1, 2, 3, 4, 5, 6 ]

If CALLABLE is provided, this will be used to determine when two items are
considered identical/equivalent. Otherwise, numeric equality is used. 

=item C<< intersect( COLLECTION, CALLABLE? ) >>

Returns a new collection formed from the union of both collections.

  my $first  = LINQ( [ 1, 2, 3, 4 ] );
  my $second = LINQ( [ 3, 4, 5, 6 ] );
  
  $first->intersect( $second )->to_array;  # ==> [ 3, 4 ]

If CALLABLE is provided, this will be used to determine when two items are
considered identical/equivalent. Otherwise, numeric equality is used. 

=item C<< except( COLLECTION, CALLABLE? ) >>

Returns a new collection formed from the asymmetric difference of both
collections.

  my $first  = LINQ( [ 1, 2, 3, 4 ] );
  my $second = LINQ( [ 3, 4, 5, 6 ] );
  
  $first->except( $second )->to_array;  # ==> [ 1, 2 ]

If CALLABLE is provided, this will be used to determine when two items are
considered identical/equivalent. Otherwise, numeric equality is used. 

=item C<< sequence_equal( COLLECTION, CALLABLE? ) >>

Returns true if and only if each item in the first collection is
identical/equivalent to its corresponding item in the second collection,
considered in order, according to CALLABLE.

If CALLABLE isn't given, then numeric equality is used.

=item C<< first( CALLABLE? ) >>

Returns the first item in a collection.

If CALLABLE is provided, returns the first item in the collection where
CALLABLE returns true.

If there is no item to return, does not return undef, but throws a
LINQ::Exception::NotFound exception.

=item C<< first_or_default( CALLABLE?, DEFAULT ) >>

Like C<first>, but instead of throwing an exception, will return the DEFAULT.

=item C<< last( CALLABLE? ) >>

Returns the last item in a collection.

If CALLABLE is provided, returns the last item in the collection where
CALLABLE returns true.

If there is no item to return, does not return undef, but throws a
LINQ::Exception::NotFound exception.

=item C<< last_or_default( CALLABLE?, DEFAULT ) >>

Like C<last>, but instead of throwing an exception, will return the DEFAULT.

=item C<< single( CALLABLE? ) >>

Returns the only item in a collection.

If CALLABLE is provided, returns the only item in the collection where
CALLABLE returns true.

If there is no item to return, does not return undef, but throws a
LINQ::Exception::NotFound exception.

If there are multiple items in the collection, or multiple items where
CALLABLE returns true, throws a LINQ::Exception::MultipleFound exception.

=item C<< single_or_default( CALLABLE?, DEFAULT ) >>

Like C<single> but rather than throwing an exception, will return DEFAULT.

=item C<< element_at( N ) >>

Returns element N within the collection. N may be negative to count from the
end of the collection. Collections are indexed from zero.

If N exceeds the length of the collection, throws a LINQ::Exception::NotFound
exception.

=item C<< element_at_or_default( N, DEFAULT ) >>

Like C<element_at> but rather than throwing an exception, will return DEFAULT.

=item C<< any( CALLABLE? ) >>

Returns true if CALLABLE returns true for any item in the collection.

=item C<< all( CALLABLE? ) >>

Returns true if CALLABLE returns true for every item in the collection.

=item C<< contains( ITEM, CALLABLE? ) >>

Returns true if the collection contains ITEM. By default, this is checked
using numeric equality.

If CALLABLE is given, this is passed two items and should return true
if they should be considered identical/equivalent.

  my $SAME_NAME = sub {
    $_[0]{name} eq $_[1]{name};
  };
  
  if ( $people->contains( { name => "Bob" }, $SAME_NAME ) ) {
    print "The collection includes Bob.\n";
  }

=item C<< count >>

Returns the size of the collection. (Number of items.)

=item C<< to_list >>

Returns the collection as a list.

=item C<< to_array >>

Returns an arrayref for the collection. This may be a tied arrayref and you
should not assume it will be writable.

=item C<< to_dictionary( CALLABLE ) >>

The CALLABLE will be called for each item in the collection and is expected to
return a string key.

The method will return a hashref mapping the keys to each item in the
collection.

=item C<< to_lookup( CALLABLE ) >>

Alias for C<to_dictionary>.

=item C<< to_iterator >>

Returns a coderef which can be used to iterate through the collection.

  my $people = LINQ( [
    { name => "Alice", dept => 'Marketing' },
    { name => "Bob",   dept => 'IT' },
    { name => "Carol", dept => 'IT' },
  ] );
  
  my $next_person = $people->to_iterator;
  
  while ( my $person = $next_person->() ) {
    print $person->{name}, "\n";
  }

=item C<< cast( TYPE ) >>

Given a type constraint (see L<Type::Tiny>) will attempt to coerce every item
in the collection to the type, and will return the collection of coerced
values. If any item cannot be coerced, throws a LINQ::Exception::Cast
exception.

=item C<< of_type( TYPE ) >>

Given a type constraint (see L<Type::Tiny>) will attempt to coerce every item
in the collection to the type, and will return the collection of coerced
values. Any items which cannot be coerced will be skipped.

=item C<< zip( COLLECTION, CALLABLE ) >>

Will loop through both collections in parallel and pass one item from each
collection to CALLABLE as arguments.

If the two collections are of different sizes, will stop after exhausing the
shorter collection.

=item C<< default_if_empty( ITEM ) >>

If this collection contains one or more items, returns itself.

If the collection is empty, returns a new collection containing just a single
item, given as a parameter.

  my $collection = $people->default_if_empty( "Bob" );
  
  # Equivalent to:
  my $collection = $people->count ? $people : LINQ( [ "Bob" ] );

=item C<< foreach( CALLABLE ) >>

This calls CALLABLE on each item in the collection. The following are roughly
equivalent:

  for ( $collection->to_list ) {
    say $_;
  }
  
  $collection->foreach( sub {
    say $_;
  } );

The advantage of the latter is that it avoids calling C<to_list>, which would
obviously fail on infinite collections.

You can break out of the loop using C<< LINQ::LAST >>.

  my $counter = 0;
  $collection->foreach( sub {
    say $_;
    LINQ::LAST if ++$counter >= 10;
  } );

Microsoft's official LINQ API doesn't include a C<ForEach> method, but this
method is provided by the MoreLINQ extension.

=back

=head1 WORKING WITH INFINITE COLLECTIONS

Because LINQ collections can be instantiated from an iterator, they may
contain infinite items.

Certain methods aggregate the entire collection, so can go into an infinite
loop. This includes: C<aggregate>, C<min>, C<max>, C<sum>, C<average>, and
C<count>.

Other methods which will go into an infinite loop on infinite collections:
C<join>, C<group_join>, C<group_by>, C<order_by>, C<order_by_descending>,
C<reverse>, C<to_lookup>, C<to_dictionary>, and C<to_list>.

The C<to_array> method in general I<will> succeed on infinite collections
as it can return a reference to a tied array. However, trying to dereference
the entire array to a list will fail.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ>, L<LINQ::Grouping>.

L<https://en.wikipedia.org/wiki/Language_Integrated_Query>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
