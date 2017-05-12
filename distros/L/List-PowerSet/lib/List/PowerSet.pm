package List::PowerSet;

# $Id: PowerSet.pm,v 1.4 2004/03/07 22:44:43 nik Exp $

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw(powerset powerset_lazy);
our $VERSION   = '0.01';

=head1 NAME

List::PowerSet - generate the power set of a list

=head1 SYNOPSIS

  use List::PowerSet qw(powerset powerset_lazy);

  my $ps = powerset(qw(1 2 3));

  my $ps_iterator = powerset_lazy(1 .. 1_000);
  while(my $set = $ps_iterator->()) {
      # $set is the next powerset entry
  }

=head1 DESCRIPTION

Suppose you have a list L. The power set of such a list is a list of
all the sublists that you can obtain from L by deleting elements from it.
For example, the power set of (1, 2, 3) is the list of lists ((), (1),
(2), (3), (1, 2), (1, 3), (2, 3), (1, 2, 3)), in some order.

C<List::PowerSet> provides two functions (which are not exported by default,
you have to ask for them) to generate power sets.

=cut

=head1 FUNCTIONS

=head2 B<powerset()>

Given a list, C<powerset()> returns an array reference of array references,
each referring to a different subset in the powerset of the input list.

  my $ps = powerset(qw(1 2 3));

  # $ps == [ [1, 2, 3],
  #          [   2, 3],
  #          [1,    3],
  #          [      3],
  #          [1, 2   ],
  #          [   2   ],
  #          [1      ],
  #          [       ] ];

=cut

# mjd's powerset implementation.  See http://perl.plover.com/LOD/199803.html
# for more details
sub powerset {
  return [[]] if @_ == 0;
  my $first = shift;
  my $pow = &powerset;
  [ map { [$first, @$_ ], [ @$_] } @$pow ];
}

=head2 B<powerset_lazy()>

Given even a moderately sized input list, C<powerset()> will have to
generate a huge result list, taking time and memory to generate.  A 20
element input list to C<powerset()> will generate a result list containing
1,048,576 references to other arrays, on average containing 10 items.

C<powerset_lazy()> takes the same input list as C<powerset()>, and returns
a subroutine reference.  Every time you call through this reference an
array reference to a different subset of the powerset is generated and 
returned.

=cut

# mjd's implementation, from personal e-mail
sub powerset_lazy {
  my @set = @_;
  my @odometer = (1) x @set;
  my $FINISHED;
  return sub {
    return if $FINISHED;
    my @result;
    my $adjust = 1;
    for (0 .. $#odometer) {
      push @result, $set[$_]  if $odometer[$_];
      $adjust = $odometer[$_] = 1 - $odometer[$_] if $adjust;
    }
    $FINISHED = (@result == 0);
            \@result;
  };
}


=head1 AUTHORS

Mark Jason Dominus <mjd@plover.com>, Nik Clayton <nik@FreeBSD.org>

The original code was written by Mark.

The module was written by Nik, who discovered mjd's code after failing
to find a powerset implementation on CPAN.  With mjd's permission he
packaged it so that others can easily make use of it.

Copyright 2004 Mark Jason Dominus, and Nik Clayton.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=List::PowerSet>.

=cut

1;
