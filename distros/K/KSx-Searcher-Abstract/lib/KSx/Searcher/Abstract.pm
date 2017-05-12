use strict;
use warnings;

package KSx::Searcher::Abstract;

our $VERSION = '0.002';
use 5.008003; # KinoSearch requires this

use base qw(KinoSearch::Searcher);

use KinoSearch::Search::BooleanQuery;
use KinoSearch::Search::MatchFieldQuery;
use KinoSearch::Search::TermQuery;
use KinoSearch::Search::PolyFilter;
use KinoSearch::Search::RangeFilter;
# we should figure out a way to use this for better performance
#use aliased 'KinoSearch::Search::QueryFilter';
use KinoSearch::Search::SortSpec;
use KinoSearch::Index::Term;

sub search {
  my ($self, $query, $options) = @_;
  unless ($query) {
    Carp::croak "'query' argument is mandatory for search";
  }
  $options ||= {};
  $self->SUPER::search(
    $self->build_abstract($query, $options)
  );
}

sub _clause_is  { shift; return query => _term(@_), occur => 'MUST' }
sub _clause_not { shift; return query => _term(@_), occur => 'MUST_NOT' }

sub _term {
  KinoSearch::Search::TermQuery->new(
    term => KinoSearch::Index::Term->new(@_)
  )
}  

sub _process_hash {
  my ($self, $key, $val, $bq) = @_;
  for my $k (keys %$val) {
    if ($k eq '=') { 
      $bq->add_clause($self->_clause_is($key, $val));
    } elsif ($k eq '!=') {
      $bq->add_clause($self->_clause_not($key, $val));
    } else {
      die "unhandled operator: $k";
    }
  }
}

sub build_abstract {
  my ($self, $query, $options) = @_;
   
  Carp::croak "can't process empty query" unless %$query;
  my $bq = KinoSearch::Search::BooleanQuery->new;
  
  # TODO: allow arrayref queries
  for my $key (sort keys %$query) {
    my $val = $query->{$key};
    if (ref $val eq 'HASH') {
      $self->_process_hash($key, $val, $bq);
    } elsif (not ref $val) {
      $bq->add_clause($self->_clause_is($key, $val));
    } else {
      Carp::croak "unhandled value: $val";
    }
  }

  my $sort_spec;
  # XXX I hate this format.  It is still too wordy.  It should change.
  if (my $sort = delete $options->{sort}) {
    $sort_spec = KinoSearch::Search::SortSpec->new;
    for (@$sort) { $sort_spec->add(%$_) }
  }
  return (
    query => $bq,
    # filter => ???
    %$options,
    $sort_spec ? (sort_spec => $sort_spec) : (),
  )
}

1;
__END__

=head1 NAME

KSx::Searcher::Abstract - build searches from Perl data structures

=head1 VERSION

 0.002

=head1 SYNOPSIS

  use KSx::Searcher::Abstract;

  my $searcher = KSx::Searcher::Abstract->new(%args);

  my $hits = $searcher->search(\%query, \%options);

=head1 DESCRIPTION

KSx::Searcher::Abstract is intended to be a simple and flexible search builder
for KinoSearch, analogous to SQL::Abstract and its role in the DBI world.

Wherever possible, KSx::Searcher::Abstract copies or mimics SQL::Abstract's
query building behavior.

=head1 LIMITATIONS

Currently, only a single level of query data is supported, e.g.

  $searcher->search({ foo => 1, bar => 2 })

All queries are effectively joined with AND.

In the future, nested conditions and conditions joined with OR should be
supported.

=head1 METHODS

=head2 search

  my $hits = $searcher->search(\%query, \%options);

Build a query and search with it.  See L</QUERY SYNTAX> and
L<KinoSearch::Searcher>.

=head2 build_abstract

  my %arg = $searcher->build_abstract(\%query, \%options);

Builds input for KinoSearch::Searcher from the supplied query and options
hashrefs.  This is called automatically by C<search>; you should not need to
use it.

=head1 QUERY SYNTAX

Each query is built from a hashref.  The keys are field names and the values
are constraints.

The simplest kind of constraint is a scalar.  This translates directly into a
TermQuery for that field and value.

  { foo => 1 }

More complex constraints are available using a hashref.

  { foo => { '='  => 1 } } # foo = 1, equivalent to the first example
  { foo => { '!=' => 1 } } # foo != 1

Watch this space as more constraints become available (see L</LIMITATIONS>).

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ksx-searcher-abstract at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=KSx-Searcher-Abstract>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc KSx::Searcher::Abstract

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/KSx-Searcher-Abstract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/KSx-Searcher-Abstract>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=KSx-Searcher-Abstract>

=item * Search CPAN

L<http://search.cpan.org/dist/KSx-Searcher-Abstract>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

