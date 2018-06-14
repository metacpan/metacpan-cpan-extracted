package Hash::MoreUtils;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);
use base 'Exporter';

%EXPORT_TAGS = (
    all => [
        qw(slice slice_def slice_exists slice_without slice_missing),
        qw(slice_notdef slice_true slice_false slice_grep),
        qw(slice_map slice_def_map slice_exists_map slice_missing_map),
        qw(slice_notdef_map slice_true_map slice_false_map slice_grep_map),
        qw(hashsort safe_reverse)
    ],
);

@EXPORT_OK = (@{$EXPORT_TAGS{all}});

$VERSION = '0.06';

=head1 NAME

Hash::MoreUtils - Provide the stuff missing in Hash::Util

=head1 SYNOPSIS

  use Hash::MoreUtils qw(:all);
  
  my %h = (foo => "bar", FOO => "BAR", true => 1, false => 0);
  my %s = slice \%h, qw(true false); # (true => 1, false => 0)
  my %f = slice_false \%h; # (false => 0)
  my %u = slice_grep { $_ =~ m/^[A-Z]/ }, \%h; # (FOO => "BAR")
  
  my %r = safe_reverse \%h; # (bar => "foo", BAR => "FOO", 0 => "false", 1 => "true")

=head1 DESCRIPTION

Similar to L<List::MoreUtils>, C<Hash::MoreUtils> contains trivial
but commonly-used functionality for hashes. The primary focus for
the moment is providing a common API - speeding up by XS is far
away at the moment.

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

=head2 C<slice_without> HASHREF[, LIST ]

As C<slice> but without any (key/value) pair whose key is
in LIST.

If no C<LIST> is given, in opposite to slice an empty list
is assumed, thus nothing will be deleted.

=head2 C<slice_missing> HASHREF[, LIST]

Returns a HASH containing the (key => undef) pair for every
C<LIST> element (as key) that does not exist hashref.

If no C<LIST> is given there are obviously no non-existent
keys in C<HASHREF> so the returned HASH is empty.

=head2 C<slice_notdef> HASHREF[, LIST]

Searches for undefined slices with the given C<LIST>
elements as keys in the given C<HASHREF>.
Returns a C<HASHREF> containing the slices (key -> undef)
for every undefined item.

To search for undefined slices C<slice_notdef> needs a
C<LIST> with items to search for (as keys). If no C<LIST>
is given it returns an empty C<HASHREF> even when the given
C<HASHREF> contains undefined slices.

=head2 C<slice_true> HASHREF[, LIST]

A special C<slice_grep> which returns only those elements
of the hash which's values evaluates to C<TRUE>.

If no C<LIST> is given, all keys are assumed as C<LIST>.

=head2 C<slice_false> HASHREF[, LIST]

A special C<slice_grep> which returns only those elements
of the hash which's values evaluates to C<FALSE>.

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
    my ($href, @list) = @_;
    @list and return map { $_ => $href->{$_} } @list;
    return %{$href};
}

sub slice_exists
{
    my ($href, @list) = @_;
    @list or @list = keys %{$href};
    return map { $_ => $href->{$_} } grep { exists($href->{$_}) } @list;
}

sub slice_without
{
    my ($href, @list) = @_;
    @list or return %{$href};
    local %_ = %{$href};
    delete $_{$_} for @list;
    return %_;
}

sub slice_def
{
    my ($href, @list) = @_;
    @list or @list = keys %{$href};
    return map { $_ => $href->{$_} } grep { defined($href->{$_}) } @list;
}

sub slice_missing
{
    my ($href, @list) = @_;
    @list or return ();
    return map { $_ => undef } grep { !exists($href->{$_}) } @list;
}

sub slice_notdef
{
    my ($href, @list) = @_;
    @list or return ();
    return map { $_ => undef } grep { !defined($href->{$_}) } @list;
}

sub slice_true
{
    my ($href, @list) = @_;
    @list or @list = keys %{$href};
    return map { $_ => $href->{$_} } grep { defined $href->{$_} and $href->{$_} } @list;
}

sub slice_false
{
    my ($href, @list) = @_;
    @list or @list = keys %{$href};
    return map { $_ => $href->{$_} } grep { not $href->{$_} } @list;
}

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub slice_grep (&@)
{
    my ($code, $href, @list) = @_;
    local %_ = %{$href};
    @list or @list = keys %{$href};
    no warnings 'uninitialized';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    return map { ($_ => $_{$_}) } grep { $code->($_) } @list;
}

use warnings;

=head2 C<slice_map> HASHREF[, MAP]

Returns a hash containing the (key, value) pair for every
key in C<MAP>.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to themselves.

=head2 C<slice_def_map> HASHREF[, MAP]

As C<slice_map>, but only includes keys whose values are
defined.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to themselves.

=head2 C<slice_exists_map> HASHREF[, MAP]

As C<slice_map> but only includes keys which exist in the
hashref.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to themselves.

=head2 C<slice_missing_map> HASHREF[, MAP]

As C<slice_missing> but checks for missing keys (of C<MAP>) and map to the value (of C<MAP>) as key in the returned HASH.
The slices of the returned C<HASHREF> are always undefined.

If no C<MAP> is given, C<slice_missing> will be used on C<HASHREF> which will return an empty HASH.

=head2 C<slice_notdef_map> HASHREF[, MAP]

As C<slice_notdef> but checks for undefined keys (of C<MAP>) and map to the value (of C<MAP>) as key in the returned HASH.

If no C<MAP> is given, C<slice_notdef> will be used on C<HASHREF> which will return an empty HASH.

=head2 C<slice_true_map> HASHREF[, MAP]

As C<slice_map>, but only includes pairs whose values are
C<TRUE>.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to themselves.

=head2 C<slice_false_map> HASHREF[, MAP]

As C<slice_map>, but only includes pairs whose values are
C<FALSE>.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to themselves.

=head2 C<slice_grep_map> BLOCK, HASHREF[, MAP]

As C<slice_map>, with an arbitrary condition.

If no C<MAP> is given, all keys of C<HASHREF> are assumed mapped to themselves.

Unlike C<grep>, the condition is not given aliases to
elements of anything.  Instead, C<< %_ >> is set to the
contents of the hashref, to avoid accidentally
auto-vivifying when checking keys or values.  Also,
'uninitialized' warnings are turned off in the enclosing
scope.

=cut

sub slice_map
{
    my ($href, %map) = @_;
    %map and return map { $map{$_} => $href->{$_} } keys %map;
    return %{$href};
}

sub slice_exists_map
{
    my ($href, %map) = @_;
    %map or return slice_exists($href);
    return map { $map{$_} => $href->{$_} } grep { exists($href->{$_}) } keys %map;
}

sub slice_missing_map
{
    my ($href, %map) = @_;
    %map or return slice_missing($href);
    return map { $map{$_} => undef } grep { !exists($href->{$_}) } keys %map;
}

sub slice_notdef_map
{
    my ($href, %map) = @_;
    %map or return slice_notdef($href);
    return map { $map{$_} => $href->{$_} } grep { !defined($href->{$_}) } keys %map;
}

sub slice_def_map
{
    my ($href, %map) = @_;
    %map or return slice_def($href);
    return map { $map{$_} => $href->{$_} } grep { defined($href->{$_}) } keys %map;
}

sub slice_true_map
{
    my ($href, %map) = @_;
    %map or return slice_true($href);
    return map { $map{$_} => $href->{$_} } grep { defined $href->{$_} and $href->{$_} } keys %map;
}

sub slice_false_map
{
    my ($href, %map) = @_;
    %map or return slice_false($href);
    return map { $map{$_} => $href->{$_} } grep { not $href->{$_} } keys %map;
}

sub slice_grep_map (&@)
{
    my ($code, $href, %map) = @_;
    %map or return goto &slice_grep;
    local %_ = %{$href};
    no warnings 'uninitialized';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    return map { ($map{$_} => $_{$_}) } grep { $code->($_) } keys %map;
}

use warnings;

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
    my ($code, $hash) = @_;
    $hash or return map { ($_ => $hash->{$_}) } sort { $a cmp $b } keys %{$hash = $code};

    # Localise $a, $b
    my ($caller_a, $caller_b) = do
    {
        my $pkg = caller();
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        (\*{$pkg . '::a'}, \*{$pkg . '::b'});
    };

    ## no critic (Variables::RequireInitializationForLocalVars)
    local (*$caller_a, *$caller_b);
    ## no critic (BuiltinFunctions::RequireSimpleSortBlock)
    return map { ($_ => $hash->{$_}) } sort { (*$caller_a, *$caller_b) = (\$a, \$b); $code->(); } keys %$hash;
}

=head2 C<safe_reverse> [BLOCK,] HASHREF

  my %dup_rev = safe_reverse \%hash

  sub croak_dup {
      my ($k, $v, $r) = @_;
      exists( $r->{$v} ) and
        croak "Cannot safe reverse: $v would be mapped to both $k and $r->{$v}";
      $v;
  };
  my %easy_rev = safe_reverse \&croak_dup, \%hash

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
    my ($code, $hash) = @_;
    unless ($hash)
    {
        $hash = $code;
        $code = sub {
            my ($k, $v, $r) = @_;
            return exists($r->{$v})
              ? (ref($r->{$v}) ? [@{$r->{$v}}, $k] : [$r->{$v}, $k])
              : $k;
        };
    }

    my %reverse;
    while (my ($key, $val) = each %{$hash})
    {
        $reverse{$val} = &{$code}($key, $val, \%reverse);
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
Copyright 2010-2018 Jens Rehsack

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Hash::MoreUtils
