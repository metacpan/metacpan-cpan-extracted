#!perl -w
use strict;
use Test::More tests => 4;
use Meetup::ToICal 'meetup_to_icalendar';
use Net::CalDAVTalk;
use Data::Dumper;

my $meetup = {
          'created' => '1478470295000',
          'description' => "<p>... some HTML ...</p> ",
          'group' => {
                       'created' => '1477928159000',
                       'id' => 20979353,
                       'join_mode' => 'open',
                       'lat' => '50.1199989318848',
                       'localized_location' => 'Frankfurt, Germany',
                       'lon' => '8.68000030517578',
                       'name' => 'Perl User Groups Rhein-Main',
                       'region' => 'en_US',
                       'urlname' => 'Perl-User-Groups-Rhein-Main',
                       'who' => 'Mitglieder'
                     },
          'id' => 'qhmffmywpbkb',
          'link' => 'https://www.meetup.com/Perl-User-Groups-Rhein-Main/events/244460782/',
          'local_date' => '2017-11-07',
          'local_time' => '19:00',
          'name' => 'Frankfurt Perlmongers Social Meeting',
          'status' => 'upcoming',
          'time' => '1510077600000',
          'updated' => '1478470295000',
          'utc_offset' => 3600000,
          'venue' => {
                       'address_1' => "Konrad-Bro\x{df}witz-Str. 1 ",
                       'city' => 'Frankfurt',
                       'country' => 'de',
                       'id' => 24887200,
                       'lat' => '50.1249465942383',
                       'localized_country_name' => 'Germany',
                       'lon' => '8.63925933837891',
                       'name' => 'Cafe Diesseits ',
                       'repinned' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' )
                     },
          'visibility' => 'public',
          'waitlist_count' => 0,
          'yes_rsvp_count' => 4
        };

my $ical = meetup_to_icalendar( $meetup );
my $entries = Net::CalDAVTalk->_argsToVCalendar($ical);
my $entry = $entries->{entries}->[0];

ok $entry, "We created a calendar entry";

#diag Dumper $entry;

is $entry->property('dtstart')->[0]->value, '20171107T190000', "The event starts at the correct time"
    or diag $entry->as_string;
is $entry->property('summary')->[0]->value, 'Frankfurt Perlmongers Social Meeting', "The event has the correct summary"
    or diag $entry->as_string;
is $entry->property('url')->[0]->value, 'https://www.meetup.com/Perl-User-Groups-Rhein-Main/events/244460782/', "The event has the correct URL"
    or diag $entry->as_string;

done_testing();