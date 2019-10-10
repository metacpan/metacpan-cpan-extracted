# -*- Perl -*-
#
# some utility subs for text patterns

package Game::TextPatterns::Util;
our $VERSION = '1.47';

use strict;
use warnings;
use constant { COL => 0, ROW => 1, };

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(adj_4way adj_8way);

# NOTE the adj_* functions for speeds do not check if all points lie
# outside the given 0,0,mc,mr bounding box. this may change if this
# proves problematic in practice
sub adj_4way {
    my ($p, $max_col, $max_row) = @_;
    my @adj;
    push @adj, [ $p->[COL] - 1, $p->[ROW] ] unless $p->[COL] <= 0;
    push @adj, [ $p->[COL] + 1, $p->[ROW] ] unless $p->[COL] >= $max_col;
    push @adj, [ $p->[COL], $p->[ROW] - 1 ] unless $p->[ROW] <= 0;
    push @adj, [ $p->[COL], $p->[ROW] + 1 ] unless $p->[ROW] >= $max_row;
    return @adj;
}

sub adj_8way {
    my ($p, $max_col, $max_row) = @_;
    my @adj;
    push @adj, [ $p->[COL] - 1, $p->[ROW] ] unless $p->[COL] == 0;
    push @adj, [ $p->[COL] + 1, $p->[ROW] ] unless $p->[COL] == $max_col;
    push @adj, [ $p->[COL], $p->[ROW] - 1 ] unless $p->[ROW] == 0;
    push @adj, [ $p->[COL], $p->[ROW] + 1 ] unless $p->[ROW] == $max_row;
    push @adj, [ $p->[COL] - 1, $p->[ROW] - 1 ]
      unless $p->[COL] == 0
      or $p->[ROW] == 0;
    push @adj, [ $p->[COL] - 1, $p->[ROW] + 1 ]
      unless $p->[COL] == 0
      or $p->[ROW] == $max_row;
    push @adj, [ $p->[COL] + 1, $p->[ROW] - 1 ]
      unless $p->[COL] == $max_col
      or $p->[ROW] == 0;
    push @adj, [ $p->[COL] + 1, $p->[ROW] + 1 ]
      unless $p->[COL] == $max_col
      or $p->[ROW] == $max_row;
    return @adj;
}

1;
__END__

=head1 NAME

Game::TextPatterns::Util - utilities for text pattern generation

=head1 SYNOPSIS

  use Game::TextPatterns::Util qw(adj_4way adj_8way);
  my @adj   = adj_4way([1,1], 7, 7);
  my @diags = adj_8way([1,1], 7, 7);

=head1 DESCRIPTION

See L<Game::TextPatterns> which uses the provided utility
functions. The B<randomly> method might well use these functions
via a callback function.

=head1 FUNCTIONS

=over 4

=item B<adj_4way> I<point> I<max-col> I<max-row>

Given a I<point> that is an array reference C<column, row> (x,y) returns
the points adjancent by compass motion. Note that error checking is
limited in these routines as B<_fill> or such in theory will restrict
input points to lie within the bounding box.

Callers must not assume that the points will be returned in any
particular order; use C<shuffle> or C<rand> to pick from the points
randomly if necessary.

C<max-col, max-row> are array index values so must be C<7,7> for an
8x8 pattern.

=item B<adj_8way> I<point> I<max-col> I<max-row>

Same as B<adj_4way> only returning points by both compass and
diagonal motions.

=back

=head1 Known Issues

Humans are really good at mixing up the col,row (x,y) points with
other forms especially given the different orientation of the
internal pattern. Favor non-square patterns for tests to better
expose such mixups.

=cut
