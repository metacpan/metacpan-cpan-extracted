package IntervalTree;

use 5.006;
use POSIX qw(ceil); 
use List::Util qw(max min);
use strict;
use warnings;
no warnings 'once';

our $VERSION = '0.05';

=head1 NAME

IntervalTree.pm

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Data structure for performing intersect queries on a set of intervals which
preserves all information about the intervals (unlike bitset projection methods).

=cut

# Historical note:
#    This module original contained an implementation based on sorted endpoints
#    and a binary search, using an idea from Scott Schwartz and Piotr Berman.
#    Later an interval tree implementation was implemented by Ian for Galaxy's
#    join tool (see `bx.intervals.operations.quicksect.py`). This was then
#    converted to Cython by Brent, who also added support for
#    upstream/downstream/neighbor queries. This was modified by James to
#    handle half-open intervals strictly, to maintain sort order, and to
#    implement the same interface as the original Intersecter.

=head1 SYNOPSIS


Data structure for performing window intersect queries on a set of 
of possibly overlapping 1d intervals.

Usage
=====

Create an empty IntervalTree

    use IntervalTree;
    my $intersecter = IntervalTree->new();

An interval is a start and end position and a value (possibly None).
You can add any object as an interval:

    $intersecter->insert( 0, 10, "food" );
    $intersecter->insert( 3, 7, {foo=>'bar'} );

    $intersecter->find( 2, 5 );
    # output: ['food', {'foo'=>'bar'}]

If the object has start and end attributes (like the IntervalTree::Interval class) there
is are some shortcuts:

    my $intersecter = IntervalTree->new();
    $intersecter->insert_interval( IntervalTree::Interval->new( 0, 10 ) );
    $intersecter->insert_interval( IntervalTree::Interval->new( 3, 7 ) );
    $intersecter->insert_interval( IntervalTree::Interval->new( 3, 40 ) );
    $intersecter->insert_interval( IntervalTree::Interval->new( 13, 50 ) );

    $intersecter->find( 30, 50 );
    # output: [IntervalTree::Interval(3, 40), IntervalTree::Interval(13, 50)]

    $intersecter->find( 100, 200 );
    # output: []

Before/after for intervals

    $intersecter->before_interval( IntervalTree::Interval->new( 10, 20 ) );
    # output: [IntervalTree::Interval(3, 7)]

    $intersecter->before_interval( IntervalTree::Interval->new( 5, 20 ) );
    # output: []

Upstream/downstream

    $intersecter->upstream_of_interval(IntervalTree::Interval->new(11, 12));
    # output: [IntervalTree::Interval(0, 10)]
    $intersecter->upstream_of_interval(IntervalTree::Interval->new(11, 12, undef, undef, "-"));
    # output: [IntervalTree::Interval(13, 50)]

    $intersecter.upstream_of_interval(IntervalTree::Interval->new(1, 2, undef, undef, "-"), 3);
    # output: [IntervalTree::Interval(3, 7), IntervalTree::Interval(3, 40), IntervalTree::Interval(13, 50)]

=cut
  
sub new {
  my ( $class ) = @_;
  my $self = {};
  $self->{root} = undef;
  return bless $self, $class;
}
    
# ---- Position based interfaces -----------------------------------------

=head2 insert

Insert the interval [start,end) associated with value `value`.

=cut

sub insert {
  my ( $self, $start, $end, $value) = @_;
  if (!defined $self->{root}) {
    $self->{root} = IntervalTree::Node->new( $start, $end, $value );
  }
  else {
    $self->{root} = $self->{root}->insert( $start, $end, $value );
  }
}

*add = \&insert;

=head2 find

Return a sorted list of all intervals overlapping [start,end).

=cut

sub find {
  my ( $self, $start, $end ) = @_;
  if (!defined $self->{root}) {
    return [];
  }
  return $self->{root}->find( $start, $end );
}

=head2 before

Find `num_intervals` intervals that lie before `position` and are no
further than `max_dist` positions away

=cut
    
sub before {
  my ( $self, $position, $num_intervals, $max_dist ) = @_;
  $num_intervals = 1 if !defined $num_intervals;
  $max_dist = 2500 if !defined $max_dist;
  
  if (!defined $self->{root}) {
    return [];
  }
  return $self->{root}->left( $position, $num_intervals, $max_dist );
}

=head2 after

Find `num_intervals` intervals that lie after `position` and are no
further than `max_dist` positions away

=cut

sub after {
  my ( $self, $position, $num_intervals, $max_dist) = @_;
  $num_intervals = 1 if !defined $num_intervals;
  $max_dist = 2500 if !defined $max_dist;

  if (!defined $self->{root}) {
    return [];
  }
  return $self->{root}->right( $position, $num_intervals, $max_dist );
}

# ---- Interval-like object based interfaces -----------------------------

=head2 insert_interval

Insert an "interval" like object (one with at least start and end
attributes)

=cut

sub insert_interval {
  my ( $self, $interval ) = @_;
  $self->insert( $interval->{start}, $interval->{end}, $interval );
}

*add_interval = \&insert_interval;

=head2 before_interval

Find `num_intervals` intervals that lie completely before `interval`
and are no further than `max_dist` positions away

=cut

sub before_interval {
  my ( $self, $interval, $num_intervals, $max_dist ) = @_;
  $num_intervals = 1 if !defined $num_intervals;
  $max_dist = 2500 if !defined $max_dist;
  
  if (!defined $self->{root}) {
    return [];
  }
  return $self->{root}->left( $interval->{start}, $num_intervals, $max_dist );
}

=head2 after_interval

Find `num_intervals` intervals that lie completely after `interval` and
are no further than `max_dist` positions away

=cut

sub after_interval {
  my ( $self, $interval, $num_intervals, $max_dist ) = @_;
  $num_intervals = 1 if !defined $num_intervals;
  $max_dist = 2500 if !defined $max_dist;

  if (!defined $self->{root}) {
    return [];
  }
  return $self->{root}->right( $interval->{end}, $num_intervals, $max_dist );
}

=head2 upstream_of_interval

Find `num_intervals` intervals that lie completely upstream of
`interval` and are no further than `max_dist` positions away

=cut

sub upstream_of_interval {
  my ( $self, $interval, $num_intervals, $max_dist ) = @_;
  $num_intervals = 1 if !defined $num_intervals;
  $max_dist = 2500 if !defined $max_dist;

  if (!defined $self->{root}) {
    return [];
  }
  if ($interval->{strand} && ($interval->{strand} eq "-" || $interval->{strand} eq "-1")) {
    return $self->{root}->right( $interval->{end}, $num_intervals, $max_dist );
  }
  else {
    return $self->{root}->left( $interval->{start}, $num_intervals, $max_dist );
  }
}

=head2 downstream_of_interval

Find `num_intervals` intervals that lie completely downstream of
`interval` and are no further than `max_dist` positions away

=cut


sub downstream_of_interval {
  my ( $self, $interval, $num_intervals, $max_dist ) = @_;
  $num_intervals = 1 if !defined $num_intervals;
  $max_dist = 2500 if !defined $max_dist;

  if (!defined $self->{root}) {
    return [];
  }
  if ($interval->{strand} && ($interval->{strand} eq "-" || $interval->{strand} eq "-1")) {
    return $self->{root}->left( $interval->{start}, $num_intervals, $max_dist );
  }
  else {
    return $self->{root}->right( $interval->{end}, $num_intervals, $max_dist );
  }
}

=head2 traverse
  
call fn for each element in the tree

=cut

sub traverse {
  my ($self, $fn) = @_;
  if (!defined $self->{root}) {
    return undef;
  }
  return $self->{root}->traverse($fn);
}

=head2 IntervalTree::Node

A single node of an `IntervalTree`.

NOTE: Unless you really know what you are doing, you probably should us
      `IntervalTree` rather than using this directly. 

=cut

package IntervalTree::Node;
use List::Util qw(min max);

our $EmptyNode = IntervalTree::Node->new( 0, 0, IntervalTree::Interval->new(0, 0));

sub nlog {
  return -1.0 / log(0.5);
}

sub left_node {
  my ($self) = @_;
  return $self->{cleft} != $EmptyNode ? $self->{cleft} : undef;
}

sub right_node {
  my ($self) = @_;
  return $self->{cright} != $EmptyNode ? $self->{cright}  : undef;
}

sub root_node {
  my ($self) = @_;
  return $self->{croot} != $EmptyNode ? $self->{croot} : undef;
}
    
sub str {
  my ($self) = @_;
  return "Node($self->{start}, $self->{end})";
}

sub new {
  my ($class, $start, $end, $interval) = @_;
  # Perl lacks the binomial distribution, so we convert a
  # uniform into a binomial because it naturally scales with
  # tree size.  Also, perl's uniform is perfect since the
  # upper limit is not inclusive, which gives us undefined here.
  my $self = {};
  $self->{priority} = POSIX::ceil(nlog() * log(-1.0/(1.0 * rand() - 1)));
  $self->{start}    = $start;
  $self->{end}      = $end;
  $self->{interval} = $interval;
  $self->{maxend}   = $end;
  $self->{minstart} = $start;
  $self->{minend}   = $end;
  $self->{cleft}    = $EmptyNode;
  $self->{cright}   = $EmptyNode;
  $self->{croot}    = $EmptyNode;
  return bless $self, $class;
}

=head2 insert
  
Insert a new IntervalTree::Node into the tree of which this node is
currently the root. The return value is the new root of the tree (which
may or may not be this node!)

=cut

sub insert {
  my ($self, $start, $end, $interval) = @_;
  my $croot = $self;
  # If starts are the same, decide which to add interval to based on
  # end, thus maintaining sortedness relative to start/end
  my $decision_endpoint = $start;
  if ($start == $self->{start}) {
    $decision_endpoint = $end;
  }

  if ($decision_endpoint > $self->{start}) {
    # insert to cright tree
    if ($self->{cright} != $EmptyNode) {
      $self->{cright} = $self->{cright}->insert( $start, $end, $interval );
    }
    else {
      $self->{cright} = IntervalTree::Node->new( $start, $end, $interval );
    }
    # rebalance tree
    if ($self->{priority} < $self->{cright}{priority}) {
      $croot = $self->rotate_left();
    }
  }
  else {
    # insert to cleft tree
    if ($self->{cleft} != $EmptyNode) {
      $self->{cleft} = $self->{cleft}->insert( $start, $end, $interval);
    }
    else {
      $self->{cleft} = IntervalTree::Node->new( $start, $end, $interval);
    }
    # rebalance tree
    if ($self->{priority} < $self->{cleft}{priority}) {
      $croot = $self->rotate_right();
    }
  }

  $croot->set_ends();
  $self->{cleft}{croot}  = $croot;
  $self->{cright}{croot} = $croot;
  return $croot;
}

sub rotate_right {
  my ($self) = @_;
  my $croot = $self->{cleft};
  $self->{cleft}  = $self->{cleft}{cright};
  $croot->{cright} = $self;
  $self->set_ends();
  return $croot;
}

sub rotate_left {
  my ($self) = @_;
  my $croot = $self->{cright};
  $self->{cright} = $self->{cright}{cleft};
  $croot->{cleft}  = $self;
  $self->set_ends();
  return $croot;
}

sub set_ends {
  my ($self) = @_;
  if ($self->{cright} != $EmptyNode && $self->{cleft} != $EmptyNode) {
    $self->{maxend} = max($self->{end}, $self->{cright}{maxend}, $self->{cleft}{maxend});
    $self->{minend} = min($self->{end}, $self->{cright}{minend}, $self->{cleft}{minend});
    $self->{minstart} = min($self->{start}, $self->{cright}{minstart}, $self->{cleft}{minstart});
  }
  elsif ( $self->{cright} != $EmptyNode) {
    $self->{maxend} = max($self->{end}, $self->{cright}{maxend});
    $self->{minend} = min($self->{end}, $self->{cright}{minend});
    $self->{minstart} = min($self->{start}, $self->{cright}{minstart});
  }
  elsif ( $self->{cleft} != $EmptyNode) {
    $self->{maxend} = max($self->{end}, $self->{cleft}{maxend});
    $self->{minend} = min($self->{end}, $self->{cleft}{minend});
    $self->{minstart} = min($self->{start}, $self->{cleft}{minstart});
  }
}


=head2 intersect

given a start and a end, return a list of features
falling within that range

=cut

sub intersect {
  my ( $self, $start, $end, $sort ) = @_;
  $sort = 1 if !defined $sort;
  my $results = [];
  $self->_intersect( $start, $end, $results );
  return $results;
}

*find = \&intersect;

sub _intersect {
  my ( $self, $start, $end, $results) = @_;
  # Left subtree
  if ($self->{cleft} != $EmptyNode && $self->{cleft}{maxend} > $start) {
    $self->{cleft}->_intersect( $start, $end, $results );
  }
  # This interval
  if (( $self->{end} > $start ) && ( $self->{start} < $end )) {
    push @$results, $self->{interval};
  }
  # Right subtree
  if ($self->{cright} != $EmptyNode && $self->{start} < $end) {
    $self->{cright}->_intersect( $start, $end, $results );
  }
}
    

sub _seek_left {
  my ($self, $position, $results, $n, $max_dist) = @_;
  # we know we can bail in these 2 cases.
  if ($self->{maxend} + $max_dist < $position) {
    return;
  }
  if ($self->{minstart} > $position) { 
    return;
  }

  # the ordering of these 3 blocks makes it so the results are
  # ordered nearest to farest from the query position
  if ($self->{cright} != $EmptyNode) {
    $self->{cright}->_seek_left($position, $results, $n, $max_dist);
  }

  if (-1 < $position - $self->{end} && $position - $self->{end} < $max_dist) {
    push @$results, $self->{interval};
  }

  # TODO: can these conditionals be more stringent?
  if ($self->{cleft} != $EmptyNode) {
    $self->{cleft}->_seek_left($position, $results, $n, $max_dist);
  }
}


    
sub _seek_right {
  my ($self, $position, $results, $n, $max_dist) = @_;
  # we know we can bail in these 2 cases.
  return if $self->{maxend} < $position;
  return if $self->{minstart} - $max_dist > $position;

  #print "SEEK_RIGHT:",self, self.cleft, self.maxend, self.minstart, position

  # the ordering of these 3 blocks makes it so the results are
  # ordered nearest to farest from the query position
  if ($self->{cleft} != $EmptyNode) {
    $self->{cleft}->_seek_right($position, $results, $n, $max_dist);
  }

  if (-1 < $self->{start} - $position && $self->{start} - $position < $max_dist) {
    push @$results, $self->{interval};
  }

  if ($self->{cright} != $EmptyNode) {
    $self->{cright}->_seek_right($position, $results, $n, $max_dist);
  }
}

=head2 left

find n features with a start > than `position`
    f: a IntervalTree::Interval object (or anything with an `end` attribute)
    n: the number of features to return
    max_dist: the maximum distance to look before giving up.

=cut
    
sub left {
  my ($self, $position, $n, $max_dist) = @_;
  $n = 1 if !defined $n;
  $max_dist = 2500 if !defined $max_dist;

  my $results = [];
  # use start - 1 becuase .left() assumes strictly left-of
  $self->_seek_left( $position - 1, $results, $n, $max_dist );
  return $results if scalar(@$results) == $n;

  my $r = $results;
  @$r = sort {$b->{end} <=> $a->{end}} @$r;
  return @$r[0..$n-1];
}

=head2 right

find n features with a end < than position
    f: a IntervalTree::Interval object (or anything with a `start` attribute)
    n: the number of features to return
    max_dist: the maximum distance to look before giving up.

=cut

sub right {
  my ($self, $position, $n, $max_dist) = @_;
  $n = 1 if !defined $n;
  $max_dist = 2500 if !defined $max_dist;

  my $results = [];
  # use end + 1 because .right() assumes strictly right-of
  $self->_seek_right($position + 1, $results, $n, $max_dist);
  return $results if scalar(@$results) == $n;

  my $r = $results;
  @$r = sort {$a->{start} <=> $b->{start}} @$r;
  return @$r[0..$n-1];
}

sub traverse {
  my ($self, $func) = @_;
  $self->_traverse($func);
}

sub _traverse {
  my ($self, $func) = @_;
  $self->{cleft}->_traverse($func) if $self->{cleft} != $EmptyNode;
  $func->($self);
  $self->{cright}->_traverse($func) if $self->{cright} != $EmptyNode;
}

## ---- Wrappers that retain the old interface -------------------------------

=head2 IntervalTree::Interval

Basic feature, with required integer start and end properties.
Also accepts optional strand as +1 or -1 (used for up/downstream queries),
a name, and any arbitrary data is sent in on the info keyword argument

    $f1 = IntervalTree::Interval->new(23, 36);
    $f2 = IntervalTree::Interval->new(34, 48, {'chr':12, 'anno':'transposon'});
    $f2
    # output: Interval(34, 48, {'anno': 'transposon', 'chr': 12})

=cut

package IntervalTree::Interval;

sub new {
  my ($class, $start, $end, $value, $chrom, $strand) = @_;
  die "start must be less than end" unless $start <= $end;
  my $self = {};
  $self->{start}  = $start;
  $self->{end}   = $end;
  $self->{value} = $value;
  $self->{chrom} = $chrom;
  $self->{strand} = $strand;
  return bless $self, $class;
}

sub str {
  my ($self) = @_;
  my $fstr = "Interval($self->{start}, $self->{end}";
  if (defined($self->{value})) {
    $fstr .= ", value=$self->{value}";
  }
  $fstr .= ")";
  return $fstr;
}

=head2 AUTHOR

Ben Booth, C<< <benwbooth at gmail.com> >>

Original Authors: 

    James Taylor (james@jamestaylor.org),
    Ian Schenk (ian.schenck@gmail.com),
    Brent Pedersen (bpederse@gmail.com)

=head2 BUGS

Please report any bugs or feature requests to C<bug-intervaltree at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IntervalTree>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head2 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IntervalTree


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IntervalTree>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IntervalTree>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IntervalTree>

=item * Search CPAN

L<http://search.cpan.org/dist/IntervalTree/>

=back

=head2 ACKNOWLEDGEMENTS

This code was directly ported from the bx-python project:

https://bitbucket.org/james_taylor/bx-python/src/tip/lib/bx/intervals/intersection.pyx

Original Authors: 

    James Taylor (james@jamestaylor.org),
    Ian Schenk (ian.schenck@gmail.com),
    Brent Pedersen (bpederse@gmail.com)

=head2 LICENSE AND COPYRIGHT

Copyright 2012 Ben Booth.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of IntervalTree
