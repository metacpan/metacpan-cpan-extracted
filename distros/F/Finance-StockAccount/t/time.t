use strict;
use warnings;

use Test::More;

use_ok('Time::Moment');

ok(my $tm1 = Time::Moment->from_string('20140827T090807Z'), 'Create tm1');
ok(my $tm2 = Time::Moment->from_string('20140827T090808Z'), 'Create tm2');
is($tm2->epoch() - $tm1->epoch(), 1, 'Tried subtracting tm1 epoch from tm2 epoch');

my $dateString = '5/27/2014 1:54:46 PM';

sub getTm {
    my $string = shift;
    if ($string =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s+(\wM)$/i) {
        my ($month, $day, $year, $hour, $minute, $second, $pm) = ($1, $2, $3, $4, $5, $6, $7);
        if ($pm =~ /^PM$/i) {
            $hour += 12;
        }
        my $tm = Time::Moment->new(
            year        => $year,
            month       => $month,
            day         => $day,
            hour        => $hour,
            minute      => $minute,
            second      => $second,
            offset      => -240,
        );
        return $tm;
    }
    else {
        warn "Did not recognize date time format:\n$string\n";
        return undef;
    }
}

ok(my $tm3 =  Time::Moment->from_string(getTm($dateString)), 'Create tm3');
print "$tm3\n";


done_testing();
