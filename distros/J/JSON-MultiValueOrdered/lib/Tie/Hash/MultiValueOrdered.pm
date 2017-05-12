use 5.008;
use strict;
use warnings;

{
	package Tie::Hash::MultiValueOrdered;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.005';
	
	use constant {
		IDX_DATA  => 0,
		IDX_ORDER => 1,
		IDX_LAST  => 2,
		IDX_SEEN  => 3,
		IDX_MODE  => 4,
		NEXT_IDX  => 5,
	};
	use constant {
		MODE_LAST  => -1,
		MODE_FIRST => 0,
		MODE_REF   => 'ref',
		MODE_ITER  => 'iter',
	};
	
	sub fetch_first    { $_[0][IDX_MODE] = MODE_FIRST }
	sub fetch_last     { $_[0][IDX_MODE] = MODE_LAST }
	sub fetch_list     { $_[0][IDX_MODE] = MODE_REF }
	sub fetch_iterator { $_[0][IDX_MODE] = MODE_ITER }
	
	use Storable qw( dclone );
	sub TIEHASH {
		my $class = shift;
		bless [{}, [], 0, {}, -1], $class;
	}
	sub STORE {
		my ($tied, $key, $value) = @_;
		$key = "$key";
		push @{$tied->[IDX_ORDER]}, $key;
		push @{$tied->[IDX_DATA]{$key}}, $value;
	}
	sub FETCH {
		my ($tied, $key) = @_;
		my $mode = $tied->[IDX_MODE];
		if ($mode eq 'ref')
		{
			return $tied->[IDX_DATA]{$key} || [];
		}
		elsif ($mode eq 'iter')
		{
			my @values = @{ $tied->[IDX_DATA]{$key} || [] };
			return sub { shift @values };
		}
		else
		{
			return unless exists $tied->[IDX_DATA]{"$key"};
			return $tied->[IDX_DATA]{$key}[$mode];
		}
	}
	sub EXISTS {
		my ($tied, $key) = @_;
		return exists $tied->[IDX_DATA]{"$key"};
	}
	sub DELETE {
		my ($tied, $key) = @_;
		my $r = delete $tied->[IDX_DATA]{"$key"};
		return $r->[-1] if $r;
		return;
	}
	sub CLEAR {
		my $tied = shift;
		$tied->[IDX_DATA]  = {};
		$tied->[IDX_ORDER] = [];
		$tied->[IDX_LAST]  = 0;
		$tied->[IDX_SEEN]  = {};
		return;
	}
	sub FIRSTKEY {
		my $tied = shift;
		$tied->[IDX_LAST] = -1;
		$tied->[IDX_SEEN] = {};
		return $tied->NEXTKEY;
	}
	sub NEXTKEY {
		no warnings qw(uninitialized);
		my $tied = shift;
		my $i = ++$tied->[IDX_LAST];
		$i++ while $tied->[IDX_SEEN]{ $tied->[IDX_ORDER][$i] };
		$tied->[IDX_SEEN]{ $tied->[IDX_ORDER][$i] }++;
		my $key = $tied->[IDX_ORDER][$i];
		if (wantarray) {
			return (
				$tied->[IDX_ORDER][$i],
				$tied->FETCH( $tied->[IDX_ORDER][$i] ),
			);
		}
		return $tied->[IDX_ORDER][$i];
	}
	sub get {
		my ($tied, $key) = @_;
		return my @list = @{ $tied->[IDX_DATA]{"$key"} || [] };
	}
	sub pairs {
		my $tied = shift;
		my $clone = dclone( $tied->[IDX_DATA] );
		return map {
			$_, shift @{$clone->{$_}}
		} @{$tied->[IDX_ORDER]}
	}
	sub pair_refs {
		my $tied = shift;
		my $clone = dclone( $tied->[IDX_DATA] );
		return map {
			[ $_, shift @{$clone->{$_}} ]
		} @{$tied->[IDX_ORDER]}
	}
	sub all_keys {
		my $tied = shift;
		return @{$tied->[IDX_ORDER]};
	}
	sub keys {
		my $tied = shift;
		my %seen;
		return grep { not $seen{$_}++ } @{$tied->[IDX_ORDER]};
	}
	sub rr_keys {
		my $tied = shift;
		my %seen;
		return reverse grep { not $seen{$_}++ } reverse @{$tied->[IDX_ORDER]};
	}
	sub all_values {
		my $tied = shift;
		my $alt = 1;
		return grep { $alt=!$alt } $tied->pairs;
	}
	sub values {
		my $tied = shift;
		return map { $tied->[IDX_DATA]{$_}[-1] } $tied->keys;
	}
	sub rr_values {
		my $tied = shift;
		return map { $tied->[IDX_DATA]{$_}[0] } $tied->keys;
	}
}

1;


__END__

=head1 NAME

Tie::Hash::MultiValueOrdered - hash with multiple values per key, and ordered keys

=head1 SYNOPSIS

   use Test::More;
   use Tie::Hash::MultiValueOrdered;
   
   my $tied = tie my %hash, "Tie::Hash::MultiValueOrdered";
   
   $hash{a} = 1;
   $hash{b} = 2;
   $hash{a} = 3;
   $hash{b} = 4;
   
   # Order of keys is predictable
   is_deeply(
      [ keys %hash ],
      [ qw( a b ) ],
   );
   
   # Order of values is predictable
   # Note that the last values of 'a' and 'b' are returned.
   is_deeply(
      [ values %hash ],
      [ qw( 3 4 ) ],
   );
   
   # Can retrieve list of all key-value pairs
   is_deeply(
      [ $tied->pairs ],
      [ qw( a 1 b 2 a 3 b 4 ) ],
   );
   
   # Switch the retrieval mode for the hash.
   $tied->fetch_first;
   
   # Now the first values of 'a' and 'b' are returned.
   is_deeply(
      [ values %hash ],
      [ qw( 1 2 ) ],
   );
   
   # Switch the retrieval mode for the hash.
   $tied->fetch_list;
   
   # Now arrayrefs are returned.
   is_deeply(
      [ values %hash ],
      [ [1,3], [2,4] ],
   );
   
   # Restore the default retrieval mode for the hash.
   $tied->fetch_last;
   
   done_testing;

=head1 DESCRIPTION

A hash tied to this class acts more or less like a standard hash, except that
when you assign a new value to an existing key, the old value is retained
underneath. An explicit C<delete> deletes all values associated with a key.

By default, the old values are inaccessible through the hash interface, but
can be retrieved via the tied object:

   my @values = tied(%hash)->get($key);

However, the C<< fetch_* >> methods provide a means to alter the behaviour of
the hash.

=head2 Tied Object Methods

=over

=item C<< pairs >>

Returns all the hash's key-value pairs (including duplicates) as a flattened
list.

=item C<< pair_refs >>

Returns all the hash's key-value pairs (including duplicates) as a list of two
item arrayrefs.

=item C<< get($key) >>

Returns the list of all values associated with a key.

=item C<< keys >>

The list of all hash keys in their original order. Where a key is duplicated,
only the first occurance is returned.

=item C<< rr_keys >>

The list of all hash keys in their original order. Where a key is duplicated,
only the last occurance is returned.

=item C<< all_keys >>

The list of all hash keys in their original order, including duplicates.

=item C<< values >>

The values correponding to C<keys>.

=item C<< rr_values >>

The values correponding to C<rr_keys>.

=item C<< all_values >>

The values correponding to C<all_keys>.

=back

=head2 Fetch Styles

=over

=item C<< fetch_last >>

This is the default style of fetching.

   tie my %hash, "Tie::Hash::MultiValueOrdered";
   
   $hash{a} = 1;
   $hash{b} = 2;
   $hash{b} = 3;
   
   tied(%hash)->fetch_last;
   
   is($hash{a}, 1);
   is($hash{b}, 3);

=item C<< fetch_first >>

   tie my %hash, "Tie::Hash::MultiValueOrdered";
   
   $hash{a} = 1;
   $hash{b} = 2;
   $hash{b} = 3;
   
   tied(%hash)->fetch_first;
   
   is($hash{a}, 1);
   is($hash{b}, 2);

=item C<< fetch_list >>

   tie my %hash, "Tie::Hash::MultiValueOrdered";
   
   $hash{a} = 1;
   $hash{b} = 2;
   $hash{b} = 3;
   
   tied(%hash)->fetch_first;
   
   is_deeply($hash{a}, [1]);
   is_deeply($hash{b}, [2, 3]);

=item C<< fetch_iterator >>

This fetch style is experimental and subject to change.

   tie my %hash, "Tie::Hash::MultiValueOrdered";
   
   $hash{a} = 1;
   $hash{b} = 2;
   $hash{b} = 3;
   
   tied(%hash)->fetch_iterator;
   
   my $A = $hash{a};
   my $B = $hash{b};
   
   is($A->(), 1);
   is($B->(), 2);
   is($B->(), 3);

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=JSON-MultiValueOrdered>.

=head1 SEE ALSO

L<JSON::Tiny::Subclassable>,
L<JSON::Tiny>,
L<Mojo::JSON>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

