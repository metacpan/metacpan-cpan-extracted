package LJ::Schedule::Vcal;

use warnings;
use strict;

use Date::Parse;
use Date::Format;
use Data::Ical;

use Data::Dumper;

our $SECS_IN_DAY  = 60 * 60 * 24;
our $SECS_IN_WEEK = 60 * 60 * 24 * 7;
our @DAY_NAMES    = qw(Sun Mon Tue Wed Thu Fri Sat);

=head1 NAME

LJ::Schedule::Vcal - The default calendar module for LJ::Schedule

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

This module is used internally by LJ::Schedule, and shouldn't need to be
used directly.

=head1 AUTHOR

Ben Evans, C<< <ben at bpfh.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lj-schedule-vcal at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LJ-Schedule>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LJ::Schedule

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LJ-Schedule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LJ-Schedule>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LJ-Schedule>

=item * Search CPAN

L<http://search.cpan.org/dist/LJ-Schedule>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Ben Evans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

#
# Default constructor
#
sub new {
    my ($pkg, $params) = @_;
    my $self = {};

    $self = $params if (ref($params) eq 'HASH');
    bless $self, $pkg;

    $self->{cal} = Data::ICal->new(filename => $self->{filename});

    #print $cal->as_string();
    # print Dumper $cal;

    $self->{ent}  = $self->{cal}->entries();
    $self->{evts} = [];

    return $self;
}

# Helper method which returns the events (evts) 
sub evts { return (shift)->{evts}; }

#
# Loops over the events in the Vcal file, processing each one in turn
#
sub prep_cal_for_lj {
    my $self = shift;

    my $ra_ent  = $self->{ent};
    my $ra_evts = $self->{evts};

  EVENT: foreach my $ent (@$ra_ent) {
        #print Dumper $ent;

      my $ra = $self->process_event($ent);
      push @$ra_evts, @$ra;
    }

    @$ra_evts = sort { $a->{tval} <=> $b->{tval} } @$ra_evts;

#  return 0;
}

#
# Returns 1 if the event is a single-day event, 0 otherwise
#
sub is_single_day {
    my $self = shift;
    my $ent = shift;

    my $start = $self->get_tval($ent);
    my $end   = $self->get_tval($ent, 'dtend');

    # All-day events have no end date defined
    return 1 if !defined $end;

    my $diff = $end - $start;

#    print "Start: $start ; End: $end ; Diff: $diff\n";

    # It seems as though the Treo translates multi-day events to
    # several single day events before export.
    #
    # Nonetheless, this code is here in case that ever changes.
    #
    return 1 if $diff < $SECS_IN_DAY;

#    print STDERR Dumper $ent;

    return 0;
}

#
# Gets the tval in seconds-since-epoch for a given event
#
sub get_tval {
    my $self = shift;
    my $ent = shift;
    my $t = shift || "dtstart";

    my $rh_props = $ent->properties();
    my $ra_prop_start = $rh_props->{$t};

    my $value;
  PROP: foreach my $start (@$ra_prop_start) {
      my $key = $start->key();
      if (lc($key) eq $t) {
	  $value = $start->value();
	  last PROP;
      }
  }

    my $date = str2time($value);

    return $date;
}

#
# Returns an arrayref of hashrefs of event details for a given future 
# event. Returns [] for a past event.
#
sub process_event {
    my $self = shift;
    my $ent = shift;

    my $rh_props = $ent->properties();

    if ($self->is_single_day($ent)) {
        my $tval = $self->get_tval($ent);

        my $now = time();

        return [] if $tval < $now;
        my $date = time2str($LJ::Schedule::DATE_FMT, $tval);

#       print STDERR "Date: $date ; Tval: $tval ; Now: $now ; ";

        my $ra_prop_summ = $rh_props->{summary};

        my $value;
      SUMMARY: foreach my $summ (@$ra_prop_summ) {
          my $key = $summ->key();
          if (lc($key) eq "summary") {
              $value = $summ->value();
              last SUMMARY;
          }
      }
#       print "$value\n";
        my $rh = {tval => $tval, summary => $value, date => $date};

        return [$rh];
    } else {
    }

}


1; # End of LJ::Schedule::Vcal
