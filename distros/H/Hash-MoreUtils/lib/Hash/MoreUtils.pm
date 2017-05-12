package Hash::MoreUtils;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Scalar::Util qw(blessed);

require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS = (
    all => [
        qw(slice slice_def slice_exists slice_grep),
        qw(slice_map slice_def_map slice_exists_map slice_grep_map),
        qw(hashsort safe_reverse)
    ],
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

$VERSION = '0.05';

=head1 NAME

Hash::MoreUtils - Provide the stuff missing in Hash::Util

=head1 SYNOPSIS

  use Hash::MoreUtils qw(slice slice_def slice_exists slice_grep
                         hashsort
                        );

=head1 DESCRIPTION

Similar to C<< List::MoreUtils >>, C<< Hash::MoreUtils >>
contains trivial but commonly-used functionality for hashes.

=head1 FUNCTIONS

=head2 C<slice> HASHREF[, LIST]

Returns a hash containing the (key, value) pair for every
key in LIST.

If no C<LIST> is given, all keys are assumed as C<LIST>.

=head2 C<slice_def> HASHREF[, LIST]

As C<slice>, but only includes keys whose values are
defined.

If no C<LIST> is given, all keys are assumed as C<LIST>.

=head2 C<slice_exists> HASHREF[, LIST]

As C<slice> but only includes keys which exist in the
hashref.

If no C<LIST> is given, all keys are assumed as C<LIST>.

=head2 C<slice_grep> BLOCK, HASHREF[, LIST]

As C<slice>, with an arbitrary condition.

If no C<LIST> is given, all keys are assumed as C<LIST>.

Unlike C<grep>, the condition is not given aliases to
elements of anything.  Instead, C<< %_ >> is set to the
contents of the hashref, to avoid accidentally
auto-vivifying when checking keys or values.  Also,
'uninitialized' warnings are turned off in the enclosing
scope.

=cut

sub slice
{
    my ( $href, @list ) = @_;
    @list and return map { $_ => $href->{$_} } @list;
    %{$href};
}

sub slice_exists
{
    my ( $href, @list ) = @_;
    @list or @list = keys %{$href};
    return map { $_ => $href->{$_} } grep {exists( $href->{$_} ) } @list;
}

sub slice_def
{
    my ( $href, @list ) = @_;
    @list or @list = keys %{$href};
    return map { $_ => $href->{$_} } grep { defined( $href->{$_} ) } @list;
}

sub slice_grep (&@)
{
    my ( $code, $href, @list ) = @_;
    local %_ = %{$href};
    @list or @list = keys %{$href};
    no warnings 'uninitialized';
    return map { ( $_ => $_{$_} ) } grep { $code->($_) } @list;
}

=head2 C<slice_map> HASHREF[, MAP]

Returns a hash containing the (key, value) pair for every
key in C<MAP>.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to theirself.

=head2 C<slice_def_map> HASHREF[, MAP]

As C<slice_map>, but only includes keys whose values are
defined.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to theirself.

=head2 C<slice_exists_map> HASHREF[, MAP]

As C<slice_map> but only includes keys which exist in the
hashref.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to theirself.

=head2 C<slice_grep_map> BLOCK, HASHREF[, MAP]

As C<slice_map>, with an arbitrary condition.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to theirself.

Unlike C<grep>, the condition is not given aliases to
elements of anything.  Instead, C<< %_ >> is set to the
contents of the hashref, to avoid accidentally
auto-vivifying when checking keys or values.  Also,
'uninitialized' warnings are turned off in the enclosing
scope.

=cut

sub slice_map
{
    my ( $href, %map ) = @_;
    %map and return map { $map{$_} => $href->{$_} } keys %map;
    %{$href};
}

sub slice_exists_map
{
    my ( $href, %map ) = @_;
    %map or return slice_exists($href);
    return map { $map{$_} => $href->{$_} } grep {exists( $href->{$_} ) } keys %map;
}

sub slice_def_map
{
    my ( $href, %map ) = @_;
    %map or return slice_def($href);
    return map { $map{$_} => $href->{$_} } grep { defined( $href->{$_} ) } keys %map;
}

sub slice_grep_map (&@)
{
    my ( $code, $href, %map ) = @_;
    %map or return goto &slice_grep;
    local %_ = %{$href};
    no warnings 'uninitialized';
    return map { ( $map{$_} => $_{$_} ) } grep { $code->($_) } keys %map;
}

=head2 C<hashsort> [BLOCK,] HASHREF

  my @array_of_pairs  = hashsort \%hash;
  my @pairs_by_length = hashsort sub { length($a) <=> length($b) }, \%hash;

Returns the (key, value) pairs of the hash, sorted by some
property of the keys.  By default (if no sort block given), sorts the
keys with C<cmp>.

I'm not convinced this is useful yet.  If you can think of
some way it could be more so, please let me know.

=cut

sub hashsort
{
    my ( $code, $hash ) = @_;
    my $cmp;
    if ( $hash )
    {
        my $package = caller;
        $cmp = sub {
          no strict 'refs';
          local ${$package.'::a'} = $a;
          local ${$package.'::b'} = $b;
          $code->();
        };
    }
    else
    {
        $hash = $code;
        $cmp = sub { $a cmp $b };
    }
    return map { ( $_ => $hash->{$_} ) } sort { $cmp->() } keys %$hash;
}

=head2 C<safe_reverse> [BLOCK,] HASHREF

  my %dup_rev = safe_reverse \%hash

  sub croak_dup {
      my ($k, $v, $r) = @_;
      exists( $r->{$v} ) and
        croak "Cannot safe reverse: $v would be mapped to both $k and $r->{$v}";
      $v;
  };
  my %easy_rev = save_reverse \&croak_dup, \%hash

Returns safely reversed hash (value, key pairs of original hash). If no
C<< BLOCK >> is given, following routine will be used:

  sub merge_dup {
      my ($k, $v, $r) = @_;
      return exists( $r->{$v} )
             ? ( ref($r->{$v}) ? [ @{$r->{$v}}, $k ] : [ $r->{$v}, $k ] )
	     : $k;
  };

The C<BLOCK> will be called with 3 arguments:

=over 8

=item C<key>

The key from the C<< ( key, value ) >> pair in the original hash

=item C<value>

The value from the C<< ( key, value ) >> pair in the original hash

=item C<ref-hash>

Reference to the reversed hash (read-only)

=back

The C<BLOCK> is expected to return the value which will used
for the resulting hash.

=cut

sub safe_reverse
{
    my ( $code, $hash ) = @_;
    unless ($hash)
    {
        $hash = $code;
        $code = sub {
	      my ($k, $v, $r) = @_;
	      return exists( $r->{$v} )
		     ? ( ref($r->{$v}) ? [ @{$r->{$v}}, $k ] : [ $r->{$v}, $k ] )
		     : $k;
	};
    }

    my %reverse;
    while( my ( $key, $val ) = each %{$hash} )
    {
	$reverse{$val} = &{$code}( $key, $val, \%reverse );
    }
    return %reverse;
}

1;

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>,
Jens Rehsack, C<< <rehsack@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-moreutils@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-MoreUtils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::MoreUtils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-MoreUtils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-MoreUtils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-MoreUtils>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-MoreUtils/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Hans Dieter Pearcey, all rights reserved.
Copyright 2010-2013 Jens Rehsack

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Hash::MoreUtils
