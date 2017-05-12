package List::Group;
# $Id: Group.pm,v 1.3 2004/02/24 23:52:58 cwest Exp $
use strict;
use base qw[Exporter];
use Carp;
use POSIX qw[ceil];
use Storable qw[dclone];

use vars qw[$VERSION @EXPORT_OK %EXPORT_TAGS];
$VERSION = (qw$Revision: 1.3 $)[1];
@EXPORT_OK = ( qw[group] );
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

=head1 NAME

List::Group - Group a list of data structures to your specifications.

=head1 SYNOPSIS

  use List::Group qw[group];
  my @list  = qw[cat dog cow rat];
  my @group = group @list, cols => 2;

  foreach my $row ( @group ) {
    print "@{$row}\n";
  }

=head1 DESCRIPTION

A simple module that currently allows you to group a list by columns or rows.

=head2 Functions

=over 8

=item C<group> I<listref>, I<args>

  my @table = group \@list, cols => 2;

This function returns a list-of-lists containing the elements of I<listref>
passed as the first argument. The remaining arguments detail how to group the
elements. Available groupings are C<cols>, and C<rows>. Each of these groupings
accept a single digit as a value, the number of C<cols> or C<rows> to create.

The following is what C<@table> would look like from the previous example.

  my @list  = qw[cat dog mouse rat];
  my @table = group \@list, cols => 2;

  print Dumper \@table;
  __END__

  $VAR1 = [
    [ 'cat', 'dog' ],
    [ 'mouse', 'rat' ]
  ];

=cut

sub group($$$;) {
  my ($list, $group_by, $number) = @_;
  croak "First argument to __PACKAGE__\::group() was not a list ref!"
    unless ref($list) eq 'ARRAY';
  croak "Number of $group_by passed to __PACKAGE__\::group() was not a digit"
    if $number =~ /\D/ && grep $group_by, qw[cols rows];
  my $grouping;
  $grouping = _group_by_cols(dclone($list), $number) if $group_by eq 'cols';
  $grouping = _group_by_rows(dclone($list), $number) if $group_by eq 'rows';
  return wantarray ? @{$grouping} : $grouping if $grouping;
  croak "Unrecognized group by argument '$group_by' to __PACKAGE__\::group()";
}

=pod

=back

=cut

sub _group_by_cols($$;) {
  my ($list, $number) = @_;
  my $grouping = [];
  push @{$grouping}, [ splice @{$list}, 0, $number ]
    while @{$list};
  return $grouping;
}

sub _group_by_rows($$;) {
  my ($list, $number) = @_;
  return _group_by_cols($list, ceil @{$list}/$number);
}

1;

__END__

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

