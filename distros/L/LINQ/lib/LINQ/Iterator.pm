use 5.006;
use strict;
use warnings;

if ( $] < 5.010000 ) {
	require UNIVERSAL::DOES;
}

{
	package    # hide from PAUSE
		LINQ::Iterator::_LazyList;
		
	my $_throw_caller_error = sub {
		shift;
		require LINQ::Exception;
		'LINQ::Exception::CallerError'->throw( message => @_ );
	};
	
	sub __GENERATOR () { 0 }
	sub __EXHAUSTED () { 1 }
	sub __VALUES ()    { 2 }
	sub __NEXT_SLOT () { 3 }
	
	sub TIEARRAY {
		my $class = shift;
		bless [
			$_[0],
			!!0,
			[],
		], $class;
	}
	
	sub FETCH {
		my $self   = shift;
		my ( $ix ) = @_;
		my $cache  = $self->[__VALUES];
		
		$self->extend_to( $ix );
		
		$ix >= @$cache ? undef : $cache->[$ix];
	}
	
	sub fetch_ref {
		my $self   = shift;
		my ( $ix ) = @_;
		my $cache  = $self->[__VALUES];
		
		$self->extend_to( $ix );
		
		return if $ix > 0+ $#$cache;
		return if $ix < 0 - @$cache;
		\( $cache->[$ix] );
	} #/ sub fetch_ref
	
	sub FETCHSIZE {
		my $self = shift;
		$self->extend_to( -1 );
		scalar @{ $self->[__VALUES] };
	}
	
	sub current_extension {
		my $self = shift;
		scalar @{ $self->[__VALUES] };
	}
	
	sub is_fully_extended {
		my $self = shift;
		$self->[__EXHAUSTED];
	}
	
	sub extend_to {
		require LINQ;
		
		my $self   = shift;
		my ( $ix ) = @_;
		my $cache  = $self->[__VALUES];
		
		EXTEND: {
			return if $self->[__EXHAUSTED];
			return if $ix >= 0 && $ix < @$cache;
			
			my @got = $self->[__GENERATOR]->();
			my $got;
			
			# Crazy optimized loop to find and handle LINQ::END
			# within @got
			# uncoverable condition count:1
			# uncoverable condition count:5
			push( @$cache, shift @got )
				and ref( $got = $cache->[-1] )
				and $got == LINQ::END()
				and ( $self->[__EXHAUSTED] = !!1 )
				and pop( @$cache )
				and (
				@got
				? $self->$_throw_caller_error( 'Returned values after LINQ::END' )
				: return ()
				) while @got;
				
			redo EXTEND;
		} #/ EXTEND:
	} #/ sub extend_to
}

package LINQ::Iterator;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Role::Tiny::With     ();
use LINQ::Util::Internal ();

Role::Tiny::With::with( qw( LINQ::Collection ) );

sub new {
	my $class = shift;
	if ( @_ ) {
		tie my ( @arr ), 'LINQ::Iterator::_LazyList',
			LINQ::Util::Internal::assert_code( @_ );
		return bless \@arr, $class;
	}
	LINQ::Util::Internal::throw(
		"CallerError",
		message => "Expected a coderef"
	);
} #/ sub new

sub _guts {
	my $self = shift;
	tied( @$self );
}

sub to_list {
	my $self = shift;
	my @list = @$self;
	
	# We must have exhausted the iterator now,
	# so remove all the magic and act like a
	# plain old arrayref.
	#
	if ( tied( @$self ) ) {
		no warnings;
		untie( @$self );
		@$self = @list;
	}
	
	@list;
} #/ sub to_list


sub to_array {
	my $self = shift;
	
	if ( my $guts = $self->_guts ) {
		tie ( my @tied, 'LINQ::Iterator::_LazyList', undef );
		@{ tied( @tied ) } = @$guts;
		return \@tied;
	}
	
	$self->LINQ::Collection::to_array( @_ );
}

sub element_at {
	my $self = shift;
	
	if ( my $guts = $self->_guts ) {
		my $ref = $guts->fetch_ref( @_ );
		return $$ref if $ref;
		require LINQ::Exception;
		'LINQ::Exception::NotFound'->throw( collection => $self );
	}
	
	$self->LINQ::Collection::element_at( @_ );
} #/ sub element_at

sub to_iterator {
	my $self = shift;
	
	if ( my $guts = $self->_guts ) {
		my $idx  = 0;
		my $done = 0;
		return sub {
			return if $done;
			my $val = $guts->fetch_ref( $idx++ );
			return $$val if $val;
			++$done;
			return;
		};
	} #/ if ( my $guts = $self->...)
	
	$self->LINQ::Collection::to_iterator( @_ );
} #/ sub to_iterator

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::Iterator - a LINQ collection with an iterator backend

=head1 SYNOPSIS

  use LINQ qw( LINQ );
  use LINQ::Iterator;
  
  my $linq  = LINQ( sub { ... } );
  
  # Same:
  my $linq  = 'LINQ::Iterator'->new( sub { ... } );

=head1 METHODS

LINQ::Iterator supports all the methods defined in L<LINQ::Collection>.

=begin trustme

=item new

=item element_at

=item to_list

=item to_array

=item to_iterator

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ>, L<LINQ::Collection>.

L<https://en.wikipedia.org/wiki/Language_Integrated_Query>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
