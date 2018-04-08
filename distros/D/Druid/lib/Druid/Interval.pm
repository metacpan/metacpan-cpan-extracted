package Druid::Interval;

use Moo;
use Druid::Util qw(yyyy_mm_dd_hh_mm_ss_iso8601);

has start => (is => 'ro');
has end   => (is => 'ro');

sub build {
    my $self = shift;

    return sprintf(
                   "%s/%s",
                    yyyy_mm_dd_hh_mm_ss_iso8601($self->start),
                    yyyy_mm_dd_hh_mm_ss_iso8601($self->end)
                  );
}

1;
