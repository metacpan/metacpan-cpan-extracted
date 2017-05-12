package Finance::TW::TAIFEX::Settlement::SecondWednesday;
use strict;
use Any::Moose 'Role';

sub default_settlement_day {
    my ($self, $date) = @_;

    my $first_day = $date->clone->truncate(to => 'month');

    return $first_day->add
        (weeks => $first_day->day_of_week > 3 ? 2 : 1,
         days => 3 - $first_day->day_of_week,
     );
}

1;

=head1 NAME

Finance::TW::TAIFEX::Settlement::SecondWednesday - settlement role

=cut
