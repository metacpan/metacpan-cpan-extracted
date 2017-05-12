#---------------------------------------------------------------------
package DateTimeX::Seinfeld;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 10 Mar 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Calculate Seinfeld chain length
#---------------------------------------------------------------------

use 5.010;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw(CodeRef);
use MooseX::Types::DateTime (); # Just load coercions

our $VERSION = '1.000';
# This file is part of DateTimeX-Seinfeld 1.000 (January 11, 2014)

#=====================================================================


has start_date => (
  is       => 'ro',
  isa      => 'DateTime',
  coerce   => 1,
  required => 1,
);


has increment => (
  is       => 'ro',
  isa      => 'DateTime::Duration',
  coerce   => 1,
  required => 1,
);


has skip => (
  is       => 'ro',
  isa      => CodeRef,
);

#=====================================================================


sub find_chains
{
  my ($self, $dates, $info) = @_;

  # If we were passed $info, continue a previous search:
  my $end;
  if ($info and %$info) {
    if ($info->{last} and $info->{longest} and
        $info->{last} != $info->{longest} and
        $info->{last}{start_period} == $info->{longest}{start_period}) {

      $info->{longest} = $info->{last};
    } # end if last and longest are the same chain

    $end = $info->{last}{end_period} if $info->{last};
  } else {
    $info = {total_periods => 0, marked_periods => 0};
  }

  $end ||= $self->start_date->clone;
  my $inc = $self->increment;

  if (not $info->{last} and @$dates and $dates->[0] < $end) {
    confess "start_date ($end) must be before first date ($dates->[0])";
  }

  for my $d (@$dates) {
    my $count = $self->_find_period($d, $end);

    undef $info->{last} if $count > 1; # the chain broke

    $info->{last} ||= {
      start_event  => $d,
      start_period => $end->clone->subtract_duration( $inc ),
    };

    ++$info->{last}{num_events};
    if ($count) { # first event in period
      ++$info->{last}{length};
      ++$info->{marked_periods};
      $info->{total_periods} += $count;
    }
    $info->{last}{end_event}  = $d;
    $info->{last}{end_period} = $end->clone;

    if (not $info->{longest}
        or $info->{longest}{length} < $info->{last}{length}) {
      $info->{longest} = $info->{last};
    }
  } # end for each $d in @$dates

  return $info;
} # end find_chains

#---------------------------------------------------------------------
# Find the start of the first period *after* date:
#
# Returns the number of increments that had to be added to $end to
# make it greater than $date.

sub _find_period
{
  my ($self, $date, $end) = @_;

  my $count = 0;
  my $inc   = $self->increment;
  my $skip  = $self->skip;

  my $skip_this;
  while ($date >= $end) {
    $skip_this = $skip && $skip->($end);
    $end->add_duration($inc);
    redo if $skip_this;
    ++$count;
  }

  return $count;
} # end _find_period
#---------------------------------------------------------------------


sub period_containing
{
  my ($self, $date) = @_;

  my $end = $self->start_date->clone;

  $self->_find_period($date, $end);

  $end->subtract_duration( $self->increment );
} # end period_containing

#=====================================================================
# Package Return Value:

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

DateTimeX::Seinfeld - Calculate Seinfeld chain length

=head1 VERSION

This document describes version 1.000 of
DateTimeX::Seinfeld, released January 11, 2014.

=head1 SYNOPSIS

  use DateTimeX::Seinfeld;

  my $seinfeld = DateTimeX::Seinfeld->new(
    start_date => $starting_datetime,
    increment  => { weeks => 1 },
  );

  my $chains = $seinfeld->find_chains( \@list_of_datetimes );

  say "Longest chain: $chains->{longest}{length}";
  say "First event in longest chain: $chains->{longest}{start_event}";
  say "The current chain may continue"
    if $chains->{last}{end_period}
       >= $seinfeld->period_containing( DateTime->now );

=head1 DESCRIPTION

DateTimeX::Seinfeld calculates the maximum Seinfeld chain length from
a sorted list of L<DateTime> objects.

The term "Seinfeld chain" comes from advice attributed to comedian
Jerry Seinfeld.  He got a large year-on-one-page calendar and marked a
big red X on every day he wrote something.  The chain of continuous
X's gave him a sense of accomplishment and helped motivate him to
write every day.
(Source: L<http://lifehacker.com/281626/jerry-seinfelds-productivity-secret>)

This module calculates the length of the longest such chain of
consecutive days.  However, it generalizes the concept; instead of
having to do something every day, you can make it every week, or every
month, or any other period that can be defined by a
L<DateTime::Duration>.

Some definitions: B<period> is the time period during which some
B<event> must occur in order to keep the chain from breaking.  More
than one event may occur in a single period, but the period is only
counted once.

=head1 ATTRIBUTES

=head2 start_date

This is the DateTime (or a hashref acceptable to C<< DateTime->new >>)
of the beginning of the first period.  All events passed to
C<find_chains> must be greater than or equal to this value.
(required)


=head2 increment

This is the DateTime::Duration (or a hashref acceptable to
C<< DateTime::Duration->new >>) giving the length of each period.
(required)


=head2 skip

This is a CodeRef that allows you to skip specified periods.  It is
called with one argument, the DateTime at which the period begins.  If
the CodeRef returns a true value, any events taking place during this
period are instead considered to take place in the next period.  (The
CodeRef must not modify the DateTime object it was given.)  (optional)

For example, to skip Sundays:

  skip => sub { shift->day_of_week == 7 }

Using C<skip> does I<not> change the start time of the next period (as
reported by C<period_containing>, C<start_period>, or C<end_period>).
The idea is that events will not normally occur during skipped periods
(or you probably shouldn't be skipping them).  This means that it is
possible for an event to be less than the start time of the period
containing it.

=head1 METHODS

=head2 find_chains

  $info = $seinfeld->find_chains( \@events );
  $info = $seinfeld->find_chains( \@events, $info ); # continue search

This calculates Seinfeld chains from the events in C<@events> (an
array of DateTime objects which must be sorted in ascending order).
Note that you must pass an array reference, not a list.

The return value is a hashref describing the results.

Two keys describe the number of periods.  C<total_periods> is the
number of periods between the C<start_date> and
C<< $info->{last}{end_period} >>.  C<marked_periods> is the number of
periods that contained at least one event.  If C<marked_periods>
equals C<total_periods>, then the events form a single chain of the
same length.

Two keys describe the chains: C<last> (the last chain of events found)
and C<longest> (the longest chain found).  These may be the same chain
(in which case the values will be references to the same hash).  If
there are multiple chains of the same length, C<longest> will be the
first such chain.  The value of each key is a hashref describing that
chain with the following keys:

=over

=item C<start_period>

The DateTime of the start of the period containg the first event of the chain.

=item C<end_period>

The DateTime of the start of the period where the chain broke
(i.e. the first period that didn't contain an event).  If this is
greater than or equal to the period containing the current date (see
L</period_containing>), then the chain may still be extended.
Otherwise, the chain is already broken, and a future event would start
a new chain.

=item C<start_event>

The DateTime of the first event in the chain (this is the same object
that appeared in C<@events>, not a clone).

=item C<end_event>

The DateTime of the last event in the chain (again, the same object
that appeared in C<@events>).

=item C<length>

The number of periods in the chain.

=item C<num_events>

The number of events in the chain.  This can never be less than
C<length>, but it can be more (if multiple events occurred in one period).

=back

Note: If C<@events> is empty, then C<last> and C<longest> will not
exist in the hash.  Otherwise, there will always be at least one
chain, even if only of length 1.

If you are monitoring an ongoing sequence of events, it would be
wasteful to have to start each search from the first event.  Instead,
you can pass the hashref returned by the first search to
C<find_chains>, along with just the new events.  The hashref you pass
will be modified (the same hashref will be returned).  To simplify
this, it is not necessary that C<last> and C<longest> reference the
same hash if they are the same chain.  If they have the same
C<start_period>, then C<find_chains> will link them automatically (by
setting S<C<< $info->{longest} = $info->{last} >>>).
When continuing a search, the C<start_date> is ignored.  Instead, the
search resumes from C<< $info->{last}{end_period} >>.

The only fields that you I<must> supply in order to continue a calculation
are C<start_period>, C<end_period>, & C<length> in C<< $info->{last} >>,
and C<start_period> & C<length> in C<< $info->{longest} >>.
However, any field that you don't supply can't be expected to hold
valid data afterwards.

When continuing a calculation, C<@events> should not include any dates
before C<< $info->{last}{end_event} >>.  If you disregard this rule,
any events less than C<< $info->{last}{end_period} >> are considered
to have occurred in the previous period (even if they actually
occurred in an even earlier period).


=head2 period_containing

  $start = $seinfeld->period_containing( $date );

Returns the DateTime at which the period containing C<$date> (a
DateTime) begins.

Note: If C<$date> occurs during a period that is skipped, then
C<$start> will be greater than C<$date>.  Otherwise, C<$start> is
always less than or equal to C<$date>.

=head1 DIAGNOSTICS

=over

=item C<start_date (%s) must be before first date (%s)>

You must not pass an event to C<find_chains> that occurs before the
C<start_date> of the first period.


=back

=head1 CONFIGURATION AND ENVIRONMENT

DateTimeX::Seinfeld requires no configuration files or environment variables.

=head1 DEPENDENCIES

DateTimeX::Seinfeld requires
L<Moose>,
L<namespace::autoclean>,
L<MooseX::Types::DateTime>,
L<MooseX::Types::Moose>,
and Perl 5.10.0 or later.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-DateTimeX-Seinfeld AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=DateTimeX-Seinfeld >>.

You can follow or contribute to DateTimeX-Seinfeld's development at
L<< https://github.com/madsen/datetimex-seinfeld >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
