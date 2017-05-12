package List::Filter::Filters::Standard;

=head1 NAME

List::Filter::Filters::Standard - define standard List::Filter filter methods

=head1 SYNOPSIS

   # This module is not intended to be used directly
   # See: L<List::Filter::Dispatcher>

=head1 DESCRIPTION

This module defines the standard List::Filter filter methods.
This is to say that it supplies a series of methods that can be
used with a List::Filter "filter" to do the actual filtering
operations upon a list of input strings.

Note that this module uses Exporter to export all of it's subs,
but these subs must be written as methods (e.g. with "my $self =
shift" as first the line), because that's how they'll ultimately
be used.  Here "$self" is a "Dispatcher" object, and has nothing
to do with this package.

=head2 interface

Each of these subs begins with:

  my $self            = shift;
  my $filter          = shift;  # object (href based)
  my $items           = shift;  # aref
  my $opt             = shift;  # href of options (which is itself optional)

And each returns an aref.  See L<List::Filter::Project/"creating new filter methods">.


=head2 METHODS

=cut

use 5.8.0;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
                  find_any
                  skip_any
                  match_all_any_order
               );

our $VERSION = '0.01';

=head2 search filter filter methods

These are the methods that apply a list of search criteria.  Each
search filter specifies one of these methods to use by default.

They all have identical interfaces: they take two input
arguments, a search filter and a reference to a list of strings
to be filtered, and they return an array reference of strings
that meet the search criteria.

=over


=item find_any

Pass through an item if it matches any one of the search terms/patterns.

Input:

(1) a search filter structure (which contains an aref of search patterns),

(2) arrayref of items to be searched

Return: arrayref of items that match all criteria.

=cut

sub find_any {
  my $self            = shift;
  my $filter          = shift;
  my $items           = shift;

  my $search_patterns = $filter->{ terms };

  my $modifiers = $filter->{modifiers};

  my @result = ();
  ITEM: foreach my $item ( @{ $items } ) {
    foreach my $pat ( @{ $search_patterns } ) {
      my $mpat;
      if ($modifiers) {
        $mpat = "(?$modifiers)$pat";
      } else {
        $mpat = $pat;
      }
      if ( $item =~ m{ $mpat }x ) {
        push @result, $item;
        next ITEM;
      }
    }
  }
  return \@result;
}


=item skip_any

Pass through an item only if it does not match any of the search
terms/patterns.

Input:
(1) a search filter structure (which contains an aref of search patterns),
(2) arrayref of items to be searched
Return: arrayref of items that match all criteria.

=cut

sub skip_any {
  my $self            = shift;
  my $filter          = shift;
  my $items           = shift;

  my $search_patterns = $filter->{ terms };
  my $modifiers       = $filter->{ modifiers };

  my @result = ();
  ITEM: foreach my $item ( @{ $items } ) {
    foreach my $pat ( @{ $search_patterns } ) {
      my $mpat;
      if ($modifiers) {
        $mpat = "(?$modifiers)$pat";
      } else {
        $mpat = $pat;
      }
      if ( $item =~ m{ $mpat }x ) { # if any pattern matches skip this item
        next ITEM;
      }
    }
    # made it through the gauntlet, so keep this item
    push @result, $item;
  }
  return \@result;
}


=item match_all_any_order

Pass through an item if it matches all of the search criteria
(irrespective of the the order of the matches inside the string).

On each term of the search criteria, a leading minus sign may
reverse the sense of the match.

Input:

(1) a search filter structure (which contains an aref of
    search patterns),

(2) arrayref of items to be searched

Return: arrayref of items that match all criteria.

=cut

sub match_all_any_order {
  my $self            = shift;
  my $filter          = shift;
  my $items           = shift;
  my $search_patterns = $filter->{ terms };
  my $modifiers = $filter->{modifiers};

  my $criteria_count = scalar( @{ $search_patterns } );

  my @result = ();
  foreach my $item (@{ $items }) {
    my $pass_count = 0;
    my @patterns = @{ $search_patterns };  # copy to avoid munging originals
    foreach my $pat (@patterns) {
      if ( $pat =~ s{^ - (.*?) $}{$1}x ) { # leading hyphens become rev matches

        my $mpat;
        if ($modifiers) {
          $mpat = "(?$modifiers)$pat";
        } else {
          $mpat = $pat;
        }

        $pass_count++ if (not( $item =~ m{$mpat}x ));
      } else {

        my $mpat;
        if ($modifiers) {
          $mpat = "(?$modifiers)$pat";
        } else {
          $mpat = $pat;
        }

        $pass_count++ if ( $item =~ m{$mpat}x );
      }
    }
    if ( $pass_count >= $criteria_count ) {
          push @result, $item;
    }
  }
  return \@result;
}


=back

1;

=head1 SEE ALSO

L<List::Filter>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
