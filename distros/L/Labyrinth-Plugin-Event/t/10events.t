#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use DateTime;
use Labyrinth::Test::Harness;
use Test::More tests => 74;

my $thisyear = DateTime->now->year;
my $date1 = DateTime->new( year => $thisyear, month => 1, day => 14, hour => 18, minute => 0, second => 0, time_zone => 'Europe/London' )->clone->add( years => 1 );
my %date1 = ( epoch => $date1->epoch, event => sprintf "%d %s %d", $date1->day, $date1->month_abbr, $date1->year );
my $date2 = DateTime->new( year => $thisyear, month => 1, day => 28, hour => 19, minute => 30, second => 0, time_zone => 'Europe/London' )->clone->subtract( years => 1 );
my %date2 = ( epoch => $date2->epoch, event => sprintf "%d %s %d", $date2->day, $date2->month_abbr, $date2->year );
my $date3 = DateTime->new( year => $thisyear, month => 1, day => 28, hour => 19, minute => 30, second => 0, time_zone => 'Europe/London' )->clone->add( years => 1 );
my %date3 = ( epoch => $date3->epoch, event => sprintf "%d %s %d", $date3->day, $date3->month_abbr, $date3->year );
my $date4 = DateTime->new( year => $thisyear, month => 12, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'Europe/London' )->clone->subtract( years => 1 );
my %date4 = ( epoch => $date4->epoch, event => sprintf "%d %s %d", $date4->day, $date4->month_abbr, $date4->year );
my $date5 = DateTime->new( year => $thisyear, month => 3, day => 13, hour => 0, minute => 0, second => 0, time_zone => 'Europe/London' )->clone->subtract( years => 1 );
my %date5 = ( epoch => $date5->epoch, event => sprintf "%d-16 %s %d", $date5->day, $date5->month_abbr, $date5->year );

my $test_data = { 
    next0 => {
        '0' => {
            'next' => {
                'body' => 'See our meetings page for further details.',
                'address' => 'Hurst Street, Birmingham, B5 4TD',
                'talks' => '0',
                'sponsorid' => '0',
                'venuelink' => 'http://www.jdwetherspoon.co.uk/pubs/pub-details.php?PubNumber=5609',
                'eventtypeid' => '5',
                'info' => '<h2>Directions</h2><p>In Brum.</p>',
                'userid' => '1',
                'venue' => 'The Dragon Inn',
                'addresslink' => 'http://maps.google.co.uk/maps?q=B5%204TD',
                'eventtime' => '6pm onwards',
                'imageid' => '1',
                'folderid' => '1',
                'title' => 'Birmingham.pm Social Meeting',
                'extralink' => undef,
                'align' => '1',
                'eventdate' => $date1{event},
                'eventtype' => 'Social Meeting',
                'listdate' => $date1{epoch},
                'links' => '<a href="/meet/main" title="Social Meeting pages">Social Meetings</a>',
                'venueid' => '4',
                'eventid' => '4',
                'publish' => '3'
            }
        }
    },
    next5 => {
        '5' => {
            'next' => {
                'listdate' => $date1{epoch},
                'addresslink' => 'http://maps.google.co.uk/maps?q=B5%204TD',
                'eventdate' => $date1{event},
                'info' => '<h2>Directions</h2><p>In Brum.</p>',
                'userid' => '1',
                'eventtime' => '6pm onwards',
                'folderid' => '1',
                'venue' => 'The Dragon Inn',
                'links' => '<a href="/meet/main" title="Social Meeting pages">Social Meetings</a>',
                'align' => '1',
                'eventtype' => 'Social Meeting',
                'eventtypeid' => '5',
                'imageid' => '1',
                'venuelink' => 'http://www.jdwetherspoon.co.uk/pubs/pub-details.php?PubNumber=5609',
                'title' => 'Birmingham.pm Social Meeting',
                'talks' => '0',
                'address' => 'Hurst Street, Birmingham, B5 4TD',
                'publish' => '3',
                'body' => 'See our meetings page for further details.',
                'sponsorid' => '0',
                'extralink' => undef,
                'eventid' => '4',
                'venueid' => '4'
            }
        }
    },
    nexts0 => {
        'publish' => '3',
        'venue' => 'The Dragon Inn',
        'listdate' => $date1{epoch},
        'sponsorid' => '0',
        'userid' => '1',
        'address' => 'Hurst Street, Birmingham, B5 4TD',
        'addresslink' => 'http://maps.google.co.uk/maps?q=B5%204TD',
        'eventid' => '4',
        'align' => '1',
        'folderid' => '1',
        'venueid' => '4',
        'eventtypeid' => '5',
        'links' => '<a href="/meet/main" title="Social Meeting pages">Social Meetings</a>',
        'extralink' => undef,
        'talks' => '0',
        'imageid' => '1',
        'eventtype' => 'Social Meeting',
        'eventtime' => '6pm onwards',
        'info' => '<h2>Directions</h2><p>In Brum.</p>',
        'eventdate' => $date1{event},
        'body' => 'See our meetings page for further details.',
        'title' => 'Birmingham.pm Social Meeting',
        'venuelink' => 'http://www.jdwetherspoon.co.uk/pubs/pub-details.php?PubNumber=5609'
    },
    nexts6 => {
        'sponsorid' => '0',
        'addresslink' => 'http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=B7+4BB&amp;sll=53.800651,-4.064941&amp;sspn=18.409311,57.084961&amp;ie=UTF8&amp;hq=&amp;hnear=Birmingham,+West+Midlands+B7+4BB,+United+Kingdom&amp;t=h&amp;z=16',
        'eventtype' => 'Technical Meeting',
        'listdate' => $date3{epoch},
        'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>',
        'talks' => '1',
        'eventtypeid' => '6',
        'address' => 'Faraday Wharf, Holt Street, Birmingham, B7 4BB',
        'imageid' => '1',
        'align' => '1',
        'userid' => '1',
        'title' => 'Birmingham.pm Technical Meeting',
        'venuelink' => 'http://www.bsp-a.com',
        'body' => 'A selection of talks regarding Perl and related subjects.',
        'venue' => 'Birmingham Science Park Aston',
        'venueid' => '5',
        'info' => '',
        'folderid' => '1',
        'eventid' => '5',
        'publish' => '3',
        'extralink' => undef,
        'eventdate' => $date3{event},
        'eventtime' => '7.30pm - 9.30pm'
    },
    nexts6intro => {
        'data' => {
            'quickname' => 'eventtype6',
            'title' => 'Technical Meetings',
            'name' => 'Barbie',
            'publish' => '3',
            'snippet' => '',
            'folderid' => '1',
            'latest' => '0',
            'articleid' => '6',
            'postdate' => '6th December 2014',
            'front' => '0',
            'sectionid' => '2',
            'userid' => '1',
            'createdate' => '0',
            'imageid' => '0'
        },
        'body' => [
            {
                'link' => undef,
                'href' => '',
                'type' => 2,
                'paraid' => '6',
                'orderno' => '1',
                'body' => '<p>The Next Technical Meeting page.</p>',
                'articleid' => '6',
                'align' => undef,
                'imageid' => '0'
            }
        ]
    },
    prev0 => {
        '0' => {
            'past' => [
                {
                    'address' => '115 New Cavendish Street, London W1W 6UW',
                    'eventtypeid' => '2',
                    'talktitle' => undef,
                    'eventtime' => 'all day',
                    'talkid' => undef,
                    'folderid' => '1',
                    'body' => '<p>A one day mini conference in London.</p>',
                    'venueid' => '2',
                    'userid' => undef,
                    'abstract' => undef,
                    'addresslink' => 'http://www.wmin.ac.uk/page-7679-smhp=4459',
                    'venue' => 'University of Westminster',
                    'info' => '<p>The Campus is located just by Cleveland Street and the imposing landmark of the BT Tower, and close to undergound and mainline railway stations and bus routes. Limited underground car parking is available only to those people with special needs. The nearest undergound stations are:</p><ul><li>Goodge Street (Northern Line)<br /></li><li>Great Portland Street (Metropolitan, Circle and Hammersmith and City Lines)<br /></li><li>Oxford Circus (Central, Bakerloo and Victoria Lines)<br /></li><li>Warren Street (Northern and Victoria Lines).<br /></li></ul><p>Several buses run along Tottenham Court Road and Euston Road that are only five minutes&#39; walk away. The Campus is a 15-20 minute walk from Kings&#39; Cross, St Pancras and Euston railway stations.</p>',
                    'title' => 'London Perl Workshop',
                    'imageid' => '1',
                    'venuelink' => 'http://www.wmin.ac.uk/page-4459',
                    'eventid' => undef,
                    'listdate' => $date4{epoch},
                    'links' => '',
                    'extralink' => undef,
                    'resource' => undef,
                    'align' => '1',
                    'sponsorid' => '0',
                    'eventtype' => 'Workshop',
                    'guest' => undef,
                    'realname' => undef,
                    'publish' => '3',
                    'eventdate' => $date4{event}
                },
                {
                    'venuelink' => '',
                    'listdate' => $date5{epoch},
                    'eventid' => undef,
                    'links' => '',
                    'extralink' => undef,
                    'resource' => undef,
                    'align' => '1',
                    'sponsorid' => '0',
                    'eventtype' => 'Hackathon',
                    'publish' => '3',
                    'realname' => undef,
                    'guest' => undef,
                    'eventdate' => $date5{event},
                    'address' => 'Lyon',
                    'eventtypeid' => '3',
                    'talktitle' => undef,
                    'talkid' => undef,
                    'folderid' => '1',
                    'eventtime' => 'all day',
                    'body' => '<p>A hackathon in Lyon.</p>',
                    'venueid' => '3',
                    'userid' => undef,
                    'abstract' => undef,
                    'venue' => 'Booking.com Offices, Lyon',
                    'info' => '',
                    'addresslink' => '',
                    'title' => 'QA Hackathon',
                    'imageid' => '1'
                },
                {
                    'title' => 'Birmingham.pm Technical Meeting',
                    'imageid' => '1',
                    'addresslink' => 'http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=B7+4BB&amp;sll=53.800651,-4.064941&amp;sspn=18.409311,57.084961&amp;ie=UTF8&amp;hq=&amp;hnear=Birmingham,+West+Midlands+B7+4BB,+United+Kingdom&amp;t=h&amp;z=16',
                    'info' => '',
                    'venue' => 'Birmingham Science Park Aston',
                    'abstract' => '<p>Stuff And Nonsense</p>',
                    'venueid' => '5',
                    'userid' => '2',
                    'body' => 'A selection of talks regarding Perl and related subjects.',
                    'folderid' => '1',
                    'eventtime' => '7.30pm - 9.30pm',
                    'talkid' => '3',
                    'talktitle' => 'More',
                    'eventtypeid' => '6',
                    'address' => 'Faraday Wharf, Holt Street, Birmingham, B7 4BB',
                    'eventdate' => $date2{event},
                    'realname' => 'guest',
                    'talks' => [
                        {
                            'talktitle' => 'Stuff',
                            'guest' => '0',
                            'realname' => 'Barbie'
                        },
                        {
                            'talktitle' => 'More',
                            'guest' => '1',
                            'realname' => 'guest'
                        }
                    ],
                    'guest' => '1',
                    'publish' => '3',
                    'eventtype' => 'Technical Meeting',
                    'sponsorid' => '0',
                    'align' => '1',
                    'resource' => '<p>some links</p>',
                    'extralink' => undef,
                    'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>',
                    'listdate' => $date2{epoch},
                    'eventid' => '6',
                    'venuelink' => 'http://www.bsp-a.com'
                },
                {
                    'talks' => [
                        {
                            'guest' => '1',
                            'realname' => 'Barbie',
                            'talktitle' => 'Title To Be Confirmed'
                        }
                    ],
                    'publish' => '3',
                    'guest' => '1',
                    'realname' => 'Barbie',
                    'eventdate' => '1-3 January 2011',
                    'sponsorid' => '1',
                    'eventtype' => 'Conference',
                    'resource' => '<p>No Resources</p>',
                    'align' => '1',
                    'eventid' => '1',
                    'listdate' => '1293840000',
                    'venuelink' => '',
                    'extralink' => undef,
                    'links' => 'web links here',
                    'venue' => 'To Be Confirmed',
                    'addresslink' => '',
                    'info' => '',
                    'abstract' => '<p>Abstract Here</p>',
                    'imageid' => '1',
                    'title' => 'Test Conference',
                    'venueid' => '1',
                    'userid' => '1',
                    'talktitle' => 'Title To Be Confirmed',
                    'body' => '<p>This is a test',
                    'eventtime' => 'all day',
                    'folderid' => '1',
                    'talkid' => '1',
                    'address' => 'More details soon',
                    'eventtypeid' => '1'
                }
            ]
        }
    },
    prev6 => {
        '6' => {
            'intro' => {
                'body' => [
                    {
                        'type' => 2,
                        'articleid' => '6',
                        'imageid' => '0',
                        'link' => undef,
                        'orderno' => '1',
                        'href' => '',
                        'align' => undef,
                        'paraid' => '6',
                        'body' => '<p>The Next Technical Meeting page.</p>'
                    }
                ],
                'data' => {
                    'name' => 'Barbie',
                    'latest' => '0',
                    'postdate' => '6th December 2014',
                    'snippet' => '',
                    'folderid' => '1',
                    'articleid' => '6',
                    'sectionid' => '2',
                    'front' => '0',
                    'userid' => '1',
                    'imageid' => '0',
                    'title' => 'Technical Meetings',
                    'quickname' => 'eventtype6',
                    'createdate' => '0',
                    'publish' => '3'
                }
            },
            'past' => [
                {
                    'sponsorid' => '0',
                    'eventtype' => 'Technical Meeting',
                    'realname' => 'guest',
                    'talks' => [
                        {
                            'talktitle' => 'Stuff',
                            'realname' => 'Barbie',
                            'guest' => '0'
                        },
                        {
                            'realname' => 'guest',
                            'guest' => '1',
                            'talktitle' => 'More'
                        }
                    ],
                    'publish' => '3',
                    'guest' => '1',
                    'eventdate' => $date2{event},
                    'eventid' => '6',
                    'listdate' => $date2{epoch},
                    'venuelink' => 'http://www.bsp-a.com',
                    'extralink' => undef,
                    'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>',
                    'resource' => '<p>some links</p>',
                    'align' => '1',
                    'userid' => '2',
                    'venueid' => '5',
                    'info' => '',
                    'addresslink' => 'http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=B7+4BB&amp;sll=53.800651,-4.064941&amp;sspn=18.409311,57.084961&amp;ie=UTF8&amp;hq=&amp;hnear=Birmingham,+West+Midlands+B7+4BB,+United+Kingdom&amp;t=h&amp;z=16',
                    'venue' => 'Birmingham Science Park Aston',
                    'abstract' => '<p>Stuff And Nonsense</p>',
                    'imageid' => '1',
                    'title' => 'Birmingham.pm Technical Meeting',
                    'address' => 'Faraday Wharf, Holt Street, Birmingham, B7 4BB',
                    'eventtypeid' => '6',
                    'talktitle' => 'More',
                    'body' => 'A selection of talks regarding Perl and related subjects.',
                    'talkid' => '3',
                    'eventtime' => '7.30pm - 9.30pm',
                    'folderid' => '1'
                }
            ]
        }
    },

    'shortlist' => [
        {
            'venueid' => '5',
            'extralink' => undef,
            'userid' => '1',
            'shortdate' => '28 Jan',
            'eventid' => '5',
            'sponsorid' => '0',
            'venuelink' => 'http://www.bsp-a.com',
            'align' => '1',
            'addresslink' => 'http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=B7+4BB&amp;sll=53.800651,-4.064941&amp;sspn=18.409311,57.084961&amp;ie=UTF8&amp;hq=&amp;hnear=Birmingham,+West+Midlands+B7+4BB,+United+Kingdom&amp;t=h&amp;z=16',
            'address' => 'Faraday Wharf, Holt Street, Birmingham, B7 4BB',
            'eventtypeid' => '6',
            'body' => 'A selection of talks regarding Perl and related subjects.',
            'imageid' => '1',
            'info' => '',
            'snippet' => 'A selection of talks regarding Perl and related subjects.',
            'listdate' => $date3{epoch},
            'publish' => '3',
            'title' => 'Birmingham.pm Technical Meeting',
            'folderid' => '1',
            'eventtime' => '7.30pm - 9.30pm',
            'venue' => 'Birmingham Science Park Aston',
            'eventdate' => '28&nbsp;Jan&nbsp;' . $date3->year,
            'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>'
        }
    ],
    longlist => {
        'ddtypes' => '<select id="eventtypeid" name="eventtypeid"><option value="0">Select An Event Type</option><option value="1">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6" selected="selected">Technical Meeting</option><option value="7">Special</option></select>',
        'longlist' => [
            {
                'extralink' => undef,
                'venueid' => '5',
                'shortdate' => '28 Jan',
                'userid' => '1',
                'venuelink' => 'http://www.bsp-a.com',
                'sponsorid' => '0',
                'eventid' => '5',
                'body' => 'A selection of talks regarding Perl and related subjects.',
                'address' => 'Faraday Wharf, Holt Street, Birmingham, B7 4BB',
                'eventtypeid' => '6',
                'addresslink' => 'http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=B7+4BB&amp;sll=53.800651,-4.064941&amp;sspn=18.409311,57.084961&amp;ie=UTF8&amp;hq=&amp;hnear=Birmingham,+West+Midlands+B7+4BB,+United+Kingdom&amp;t=h&amp;z=16',
                'align' => '1',
                'imageid' => '1',
                'listdate' => $date3{epoch},
                'info' => '',
                'snippet' => 'A selection of talks regarding Perl and related subjects.',
                'folderid' => '1',
                'eventtime' => '7.30pm - 9.30pm',
                'title' => 'Birmingham.pm Technical Meeting',
                'publish' => '3',
                'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>',
                'eventdate' => $date3{event},
                'venue' => 'Birmingham Science Park Aston'
            }
        ],
        'ddpublish' => '<select id="publish" name="publish"><option value="0">Select Status</option><option value="1">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>'
    },

    item => {
        'type' => '1',
        'venuelink' => 'http://www.bsp-a.com',
        'folderid' => '1',
        'title' => 'Birmingham.pm Technical Meeting',
        'imageid' => '1',
        'eventid' => '6',
        'info' => '',
        'dimensions' => undef,
        'href' => undef,
        'venue' => 'Birmingham Science Park Aston',
        'extralink' => undef,
        'eventdate' => $date2{event},
        'eventtype' => 'Technical Meeting',
        'talks' => [
            {
                'eventid' => '6',
                'talktitle' => 'Stuff',
                'resource' => '<p>some links</p>',
                'aboutme' => '',
                'imageid' => '1',
                'nickname' => 'Barbie',
                'talkid' => '2',
                'guest' => '0',
                'email' => 'barbie@example.com',
                'userid' => '1',
                'password' => 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3',
                'accessid' => '5',
                'url' => '',
                'realm' => 'admin',
                'abstract' => '<p>And Nonsense</p>',
                'search' => '1',
                'realname' => 'Barbie'
            },
            {
                'aboutme' => undef,
                'resource' => '<p>some links</p>',
                'imageid' => '1',
                'nickname' => 'Guest',
                'talkid' => '3',
                'guest' => '1',
                'email' => 'GUEST',
                'eventid' => '6',
                'talktitle' => 'More',
                'abstract' => '<p>Stuff And Nonsense</p>',
                'realm' => 'public',
                'search' => '0',
                'realname' => 'guest',
                'userid' => '2',
                'password' => 'c8d6ea7f8e6850e9ed3b642900ca27683a257201',
                'accessid' => '1',
                'url' => undef
            }
        ],
        'venueid' => '5',
        'listdate' => $date2{epoch},
        'sponsor' => undef,
        'eventtypeid' => '6',
        'tag' => undef,
        'body' => 'A selection of talks regarding Perl and related subjects.',
        'sponsorid' => undef,
        'addresslink' => 'http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=B7+4BB&amp;sll=53.800651,-4.064941&amp;sspn=18.409311,57.084961&amp;ie=UTF8&amp;hq=&amp;hnear=Birmingham,+West+Midlands+B7+4BB,+United+Kingdom&amp;t=h&amp;z=16',
        'align' => '1',
        'link' => 'images/blank.png',
        'userid' => '1',
        'sponsorlink' => undef,
        'address' => 'Faraday Wharf, Holt Street, Birmingham, B7 4BB',
        'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>',
        'eventtime' => '7.30pm - 9.30pm',
        'publish' => '3'
    },

    add => {
        'ddalign' => '<select id="ALIGN0" name="ALIGN0"><option value="0">none</option><option value="1" selected="selected">left</option><option value="2">centre</option><option value="3">right</option><option value="4">left (no wrap)</option><option value="5">right (no wrap)</option></select>',
        'link' => 'images/blank.png',
        'ddtype' => '<select id="eventtypeid" name="eventtypeid"><option value="0" selected="selected">Select An Event Type</option><option value="1">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>',
        'title' => '',
        'folderid' => 1,
        'userid' => 1,
        'ddvenue' => '<select id="venueid" name="venueid"><option value="0">Select A Venue</option><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1">To Be Confirmed</option><option value="2">University of Westminster</option></select>',
        'ddpublish' => '<select id="publish" name="publish"><option value="1" selected="selected">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
        'ddsponsor' => '<select id="sponsorid" name="sponsorid"><option value="0">Select Sponsor</option><option value="1">Miss Barbell Productions</option></select>',
        'body' => '',
        'name' => 'Barbie',
        'imageid' => 1,
        'createdate' => 'Sun Dec 07 14:05:52 2014'
    },

    edit3 => {
        'talks' => [
            {
                'eventid' => '1',
                'realm' => 'admin',
                'imageid' => '1',
                'userid' => '1',
                'search' => '1',
                'abstract' => '<p>Abstract Here</p>',
                'resource' => '<p>No Resources</p>',
                'aboutme' => '',
                'guest' => '1',
                'password' => 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3',
                'accessid' => '5',
                'nickname' => 'Barbie',
                'talkid' => '1',
                'talktitle' => 'Title To Be Confirmed',
                'realname' => 'Barbie',
                'email' => 'barbie@example.com',
                'url' => ''
            }
        ],
        'eventtypeid' => '1',
        'ddvenue' => '<select id="venueid" name="venueid"><option value="0">Select A Venue</option><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1" selected="selected">To Be Confirmed</option><option value="2">University of Westminster</option></select>',
        'extralink' => undef,
        'tag' => undef,
        'eventtime' => 'all day',
        'title' => 'Test Conference',
        'venuelink' => '',
        'ddtype' => '<select id="eventtypeid" name="eventtypeid"><option value="0">Select An Event Type</option><option value="1" selected="selected">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>',
        'listdate' => '1293840000',
        'link' => 'images/blank.png',
        'ddsponsor' => '<select id="sponsorid" name="sponsorid"><option value="0">Select Sponsor</option><option value="1" selected="selected">Miss Barbell Productions</option></select>',
        'type' => '1',
        'eventdate' => '1-3 January 2011',
        'address' => 'More details soon',
        'imageid' => '1',
        'alignment' => 'left',
        'publish' => 3,
        'folderid' => '1',
        'venue' => 'To Be Confirmed',
        'links' => 'web links here',
        'body' => '&lt;p&gt;This is a test',
        'sponsorlink' => 'http://www.missbarbell.co.uk',
        'ddpublish' => '<select id="publish" name="publish"><option value="1">Draft</option><option value="2">Submitted</option><option value="3" selected="selected">Published</option><option value="4">Archived</option></select>',
        'sponsorid' => '1',
        'listeddate' => '01/01/2011',
        'venueid' => '1',
        'createdate' => 'Sun Dec 07 14:12:28 2014',
        'name' => 'Barbie',
        'ddalign' => '<select id="ALIGN0" name="ALIGN0"><option value="0" selected="selected">none</option><option value="1">left</option><option value="2">centre</option><option value="3">right</option><option value="4">left (no wrap)</option><option value="5">right (no wrap)</option></select>',
        'info' => '',
        'sponsor' => 'Miss Barbell Productions',
        'addresslink' => '',
        'eventtype' => 'Conference',
        'align' => undef,
        'eventid' => '1',
        'dimensions' => undef,
        'userid' => '1',
        'href' => undef
    },
    edit4 => {
        'address' => 'More details soon',
        'addresslink' => '',
        'venue' => 'To Be Confirmed',
        'userid' => '1',
        'ddtype' => '<select id="eventtypeid" name="eventtypeid"><option value="0">Select An Event Type</option><option value="1">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7" selected="selected">Special</option></select>',
        'folderid' => '0',
        'eventtypeid' => '7',
        'align' => undef,
        'links' => '',
        'type' => '1',
        'href' => undef,
        'sponsorlink' => undef,
        'imageid' => '1',
        'venueid' => '1',
        'talks' => undef,
        'ddpublish' => '<select id="publish" name="publish"><option value="1" selected="selected">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
        'publish' => 1,
        'ddvenue' => '<select id="venueid" name="venueid"><option value="0">Select A Venue</option><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1" selected="selected">To Be Confirmed</option><option value="2">University of Westminster</option></select>',
        'ddalign' => '<select id="ALIGN0" name="ALIGN0"><option value="0" selected="selected">none</option><option value="1">left</option><option value="2">centre</option><option value="3">right</option><option value="4">left (no wrap)</option><option value="5">right (no wrap)</option></select>',
        'body' => 'A Big Event',
        'eventdate' => '13th Sept 2015',
        'sponsorid' => undef,
        'info' => '',
        'name' => 'Barbie',
        'title' => 'A New Event',
        'eventtype' => 'Special',
        'ddsponsor' => '<select id="sponsorid" name="sponsorid"><option value="0">Select Sponsor</option><option value="1">Miss Barbell Productions</option></select>',
        'sponsor' => undef,
        'eventtime' => 'All day',
        'venuelink' => '',
        'eventid' => '7',
        'createdate' => 'Sun Dec 07 15:08:32 2014',
        'link' => 'images/blank.png',
        'tag' => undef,
        'dimensions' => undef,
        'alignment' => 'left',
        'extralink' => undef,
        'listeddate' => '13/09/2015',
        'listdate' => '1442098800'
    },

    admin1 => [
        {
            'listdate' => $date3{epoch},
            'eventtype' => 'Technical Meeting',
            'eventdate' => $date3{event},
            'align' => '1',
            'eventid' => '5',
            'imageid' => '1',
            'userid' => '1',
            'publish' => '3',
            'body' => 'A selection of talks regarding Perl and related subjects.',
            'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>',
            'folderid' => '1',
            'talks' => '1',
            'sponsorid' => '0',
            'eventtypeid' => '6',
            'extralink' => undef,
            'title' => 'Birmingham.pm Technical Meeting',
            'eventtime' => '7.30pm - 9.30pm',
            'venueid' => '5',
            'name' => 'Barbie',
            'createdate' => '28/01/' . $date3->year,
            'publishstate' => 'Published'
        },
        {
            'listdate' => $date1{epoch},
            'eventdate' => $date1{event},
            'eventtype' => 'Social Meeting',
            'align' => '1',
            'imageid' => '1',
            'userid' => '1',
            'eventid' => '4',
            'folderid' => '1',
            'links' => '<a href="/meet/main" title="Social Meeting pages">Social Meetings</a>',
            'body' => 'See our meetings page for further details.',
            'publish' => '3',
            'eventtypeid' => '5',
            'talks' => '0',
            'sponsorid' => '0',
            'eventtime' => '6pm onwards',
            'title' => 'Birmingham.pm Social Meeting',
            'extralink' => undef,
            'createdate' => '14/01/' . $date1->year,
            'name' => 'Barbie',
            'venueid' => '4',
            'publishstate' => 'Published'
        },
        {
            'publishstate' => 'Published',
            'venueid' => '2',
            'createdate' => '01/12/' . $date4->year,
            'name' => 'Barbie',
            'extralink' => undef,
            'eventtime' => 'all day',
            'title' => 'London Perl Workshop',
            'talks' => '1',
            'sponsorid' => '0',
            'eventtypeid' => '2',
            'publish' => '3',
            'folderid' => '1',
            'links' => '',
            'body' => '<p>A one day mini conference in London.</p>',
            'eventid' => '2',
            'userid' => '1',
            'imageid' => '1',
            'align' => '1',
            'eventtype' => 'Workshop',
            'listdate' => $date4{epoch},
            'eventdate' => $date4{event}
        },
        {
            'title' => 'QA Hackathon',
            'eventtime' => 'all day',
            'extralink' => undef,
            'eventtypeid' => '3',
            'talks' => '1',
            'sponsorid' => '0',
            'publishstate' => 'Published',
            'name' => 'Barbie',
            'createdate' => '13/03/' . $date4->year,
            'venueid' => '3',
            'align' => '1',
            'eventtype' => 'Hackathon',
            'links' => '',
            'body' => '<p>A hackathon in Lyon.</p>',
            'folderid' => '1',
            'publish' => '3',
            'imageid' => '1',
            'userid' => '1',
            'eventid' => '3',
            'listdate' => $date5{epoch},
            'eventdate' => $date5{event}
        },
        {
            'publish' => '3',
            'links' => '<a href="/tech/main" title="Technical Meeting pages">Technical Meetings</a>',
            'body' => 'A selection of talks regarding Perl and related subjects.',
            'folderid' => '1',
            'eventid' => '6',
            'imageid' => '1',
            'userid' => '1',
            'align' => '1',
            'listdate' => $date2{epoch},
            'eventtype' => 'Technical Meeting',
            'eventdate' => $date2{event},
            'publishstate' => 'Published',
            'venueid' => '5',
            'name' => 'Barbie',
            'createdate' => '28/01/' . $date2->year,
            'extralink' => undef,
            'title' => 'Birmingham.pm Technical Meeting',
            'eventtime' => '7.30pm - 9.30pm',
            'talks' => '1',
            'sponsorid' => '0',
            'eventtypeid' => '6'
        },
        {
            'align' => '1',
            'eventdate' => '1-3 January 2011',
            'listdate' => '1293840000',
            'eventtype' => 'Conference',
            'folderid' => '1',
            'body' => '<p>This is a test',
            'links' => 'web links here',
            'publish' => '3',
            'imageid' => '1',
            'userid' => '1',
            'eventid' => '1',
            'eventtime' => 'all day',
            'title' => 'Test Conference',
            'extralink' => undef,
            'eventtypeid' => '1',
            'talks' => '1',
            'sponsorid' => '1',
            'publishstate' => 'Published',
            'createdate' => '01/01/2011',
            'name' => 'Barbie',
            'venueid' => '1'
        }
    ],
    copy => {
        'eventtype' => 'Special',
        'links' => '',
        'tag' => undef,
        'eventtime' => 'All day',
        'extralink' => undef,
        'name' => 'Barbie',
        'eventtypeid' => '7',
        'createdate' => 'Sun Dec 07 15:06:11 2014',
        'ddtype' => '<select id="eventtypeid" name="eventtypeid"><option value="0">Select An Event Type</option><option value="1">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7" selected="selected">Special</option></select>',
        'publish' => 1,
        'talks' => undef,
        'eventdate' => '13th Sept 2015',
        'alignment' => 'left',
        'addresslink' => '',
        'listdate' => '1442098800',
        'href' => undef,
        'venueid' => '1',
        'eventid' => '8',
        'folderid' => '0',
        'body' => 'A Big Event',
        'ddvenue' => '<select id="venueid" name="venueid"><option value="0">Select A Venue</option><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1" selected="selected">To Be Confirmed</option><option value="2">University of Westminster</option></select>',
        'venue' => 'To Be Confirmed',
        'imageid' => '1',
        'listeddate' => '13/09/2015',
        'title' => 'A New Event',
        'dimensions' => undef,
        'venuelink' => '',
        'link' => 'images/blank.png',
        'ddpublish' => '<select id="publish" name="publish"><option value="1" selected="selected">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
        'sponsorid' => undef,
        'align' => undef,
        'userid' => '1',
        'sponsorlink' => undef,
        'type' => '1',
        'address' => 'More details soon',
        'ddalign' => '<select id="ALIGN0" name="ALIGN0"><option value="0" selected="selected">none</option><option value="1">left</option><option value="2">centre</option><option value="3">right</option><option value="4">left (no wrap)</option><option value="5">right (no wrap)</option></select>',
        'ddsponsor' => '<select id="sponsorid" name="sponsorid"><option value="0">Select Sponsor</option><option value="1">Miss Barbell Productions</option></select>',
        'sponsor' => undef,
        'info' => ''
    }
};

my @plugins = qw(
    Labyrinth::Plugin::Event
);

# -----------------------------------------------------------------------------
# Set up

my $loader = Labyrinth::Test::Harness->new( keep => 0 );
my $dir = $loader->directory;

my $res = $loader->prep(
    sql     => [ "$dir/cgi-bin/db/plugin-base.sql","t/data/test-base.sql","t/data/test-base-events.sql" ],
    files   => { 
        't/data/phrasebook.ini' => 'cgi-bin/config/phrasebook.ini'
    },
    config  => {
        'INTERNAL'  => { logclear => 0 }
    }
);
diag($loader->error)    unless($res);

SKIP: {
    skip "Unable to prep the test environment", 74  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2 }, {} );
    $res = is($loader->action('Event::NextEvent'),1);
    diag($loader->error)    unless($res);
    my $vars = $loader->vars;
    $test_data->{next0}{0}{next}{$_} = $vars->{event}{0}{next}{$_} for(qw(eventdate listdate));
    diag("next event all vars=".Dumper($vars));
    is_deeply($vars->{event},$test_data->{next0},'next event all variables are as expected');
    is(scalar(@{$vars->{events}{0}{dates}}),1,'1 date returned');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, events => {}, event => {} }, { eventtypeid => 5 } );
    $res = is($loader->action('Event::NextEvent'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{next5}{5}{next}{$_} = $vars->{event}{5}{next}{$_} for(qw(eventdate listdate));
    #diag("next event 5 vars=".Dumper($vars));
    is_deeply($vars->{event},$test_data->{next5},'next event 5 variables are as expected');
    is(scalar(@{$vars->{events}{5}{dates}}),1,'1 date returned');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, events => {}, event => {} }, { eventtypeid => 0 } );
    $res = is($loader->action('Event::NextEvents'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("next events all vars=".Dumper($vars));
    is_deeply($vars->{events}{6}{intro},undef,'next events 0 intro variables are as expected');
    is_deeply($vars->{events}{0}{future},$test_data->{nexts0},'next events all variables are as expected');
    is(scalar(@{$vars->{events}{0}{dates}}),2,'2 dates returned');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, events => {}, event => {} }, { eventtypeid => 6 } );
    $res = is($loader->action('Event::NextEvents'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{nexts6intro}{data}{$_} = $vars->{events}{6}{intro}{data}{$_}    for(qw(postdate)); # these will always be the current timestamp
    #diag("next events vars=".Dumper($vars));
    is_deeply($vars->{events}{6}{intro},$test_data->{nexts6intro},'next events 6 intro variables are as expected');
    is_deeply($vars->{events}{6}{future},$test_data->{nexts6},'next events 6 variables are as expected');
    is(scalar(@{$vars->{events}{6}{dates}}),1,'1 date returned');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, page => {}, events => {}, event => {} }, { eventtypeid => 0 } );
    $res = is($loader->action('Event::PrevEvents'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("prev events all vars=".Dumper($vars));
    is_deeply($vars->{events},$test_data->{prev0},'previous events all variables are as expected');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, page => {}, events => {}, event => {} }, { eventtypeid => 6 } );
    $res = is($loader->action('Event::PrevEvents'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{prev6}{6}{intro}{data}{$_} = $vars->{events}{6}{intro}{data}{$_}    for(qw(postdate)); # these will always be the current timestamp
    #diag("prev events 6 vars=".Dumper($vars));
    is_deeply($vars->{events},$test_data->{prev6},'previous events 6 variables are as expected');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, page => {}, events => {}, event => {} }, {} );
    $res = is($loader->action('Event::ShortList'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("short list vars=".Dumper($vars));
    is_deeply($vars->{events}{shortlist},$test_data->{shortlist},'short list variables are as expected');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, page => {}, events => {}, event => {} }, {} );
    $res = is($loader->action('Event::LongList'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("long list vars=".Dumper($vars));
    is_deeply($vars->{events},$test_data->{longlist},'long list variables are as expected');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, page => {}, events => {}, event => {} }, { eventid => 0 } );
    $res = is($loader->action('Event::Item'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("item vars=".Dumper($vars));
    is_deeply($vars->{event},{},'no event item variables are as expected');

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, page => {}, events => {}, event => {} }, { eventid => 6 } );
    $res = is($loader->action('Event::Item'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("item 6 vars=".Dumper($vars));
    $test_data->{item}{$_} = $vars->{event}{$_}  for(qw(listdate eventdate));
    is_deeply($vars->{event},$test_data->{item},'item variables are as expected');

    # -------------------------------------------------------------------------
    # Internal methods

    like(Labyrinth::Plugin::Event::_get_timer(),qr/\d+/,'got an epoch date');
    my @date = Labyrinth::Plugin::Event::_startdate();
    is(scalar(@date),3);
    like($date[0],qr/^([1-9]|[12][0-9]|3[01])$/,'got day');
    like($date[1],qr/^([1-9]|1[0-2])$/,'got month');
    like($date[2],qr/^(19|20)\d\d$/,'got year');

=pod

_events_list

=cut

    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access

    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2 } );
    for my $call (
            'Event::Admin',           'Event::Add',             'Event::Edit',
            'Event::Copy',            'Event::Save',            'Event::Delete',
            'Event::Promote'
        ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }
    

    # Add - test adding an event
    $loader->clear;
    $loader->refresh( \@plugins, {} );
    $loader->login( 1 );
    $res = is($loader->action('Event::Add'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{add}{$_} = $vars->{data}{$_}    for(qw(createdate)); # these will always be the current timestamp
    #diag("add vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{add},'add variables are as expected');


    # Edit - no event given
    $loader->clear;
    $loader->refresh( \@plugins, {}, { eventid => 0 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit1 vars=".Dumper($vars));
    is_deeply($vars->{data},undef,"edit1 data provided, when no page given");

    # Edit - missing event
    $loader->clear;
    $loader->refresh( \@plugins, {}, { eventid => 9 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars));
    is_deeply($vars->{data},undef,"edit2 data provided, with no reordering");

    # Edit - valid event
    $loader->clear;
    $loader->refresh( \@plugins, {}, { eventid => 1 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{edit3}{$_} = $vars->{data}{$_}  for(qw(createdate)); # these will always be the current timestamp
    #diag("edit3 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit3},"edit3 data provided, with no reordering");

    # Admin - test basic admin
    $loader->clear;
    $loader->refresh( \@plugins, {} );
    $loader->login( 1 );
    $res = is($loader->action('Event::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin1},'admin1 list variables are as expected');


    # Save a new page
    $loader->clear;
    $loader->refresh( \@plugins, {},
        { title => 'A New Event', eventid => 0, publish => 1, listeddate => '13/09/2015', eventdate => '13th Sept 2015', body => 'A Big Event', eventtypeid => 7, eventtime => 'All day', venueid => 1 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save1 vars=".Dumper($vars));
    is($vars->{thanks},1,'saved successfully');

    $loader->clear;
    $loader->refresh( \@plugins, {}, { eventid => 7 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{edit4}{$_} = $vars->{data}{$_}   for(qw(createdate)); # these will always be the current timestamp
    #diag("save1 edit4 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit4},'edit check variables are as expected');

    
    # -------------------------------------------------------------------------
    # Admin Link Copy/Promote/Delete methods - as we change the db

    # test base admin
    $loader->clear;
    $loader->refresh( \@plugins, {}, {} );
    $loader->login( 1 );
    $res = is($loader->action('Event::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars));
    is(scalar(@{ $vars->{data} }),7,'start admin as expected');

    # test delete via admin
    $loader->clear;
    $loader->refresh( \@plugins, {}, { doaction => 'Delete', LISTED => [ 1 ] } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars));
    is(scalar(@{ $vars->{data} }),6,'delete admin as expected');

    # test copy via admin
    $loader->clear;
    $loader->refresh( \@plugins, {}, { doaction => 'Copy', LISTED => 7 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Admin'),1);
    diag($loader->error)    unless($res);
    my $params = $loader->params;
    is($params->{eventid},8,'new event created from copy');
    $loader->clear;
    $loader->refresh( \@plugins, {}, { eventid => 8 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{copy}{$_} = $vars->{data}{$_}   for(qw(createdate)); # these will always be the current timestamp
    #diag("copy vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{copy},'copy check variables are as expected');

=pod

Promote

=cut

    is(Labyrinth::Plugin::Event::VenueSelect(),       '<select id="venueid" name="venueid"><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1">To Be Confirmed</option><option value="2">University of Westminster</option></select>');
    is(Labyrinth::Plugin::Event::VenueSelect(1),      '<select id="venueid" name="venueid"><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1" selected="selected">To Be Confirmed</option><option value="2">University of Westminster</option></select>');
    is(Labyrinth::Plugin::Event::VenueSelect(1,1),    '<select id="venueid" name="venueid"><option value="0">Select A Venue</option><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1" selected="selected">To Be Confirmed</option><option value="2">University of Westminster</option></select>');
    is(Labyrinth::Plugin::Event::VenueSelect(1,0),    '<select id="venueid" name="venueid"><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1" selected="selected">To Be Confirmed</option><option value="2">University of Westminster</option></select>');
    is(Labyrinth::Plugin::Event::VenueSelect(undef,1),'<select id="venueid" name="venueid"><option value="0">Select A Venue</option><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1">To Be Confirmed</option><option value="2">University of Westminster</option></select>');
    is(Labyrinth::Plugin::Event::VenueSelect(undef,0),'<select id="venueid" name="venueid"><option value="5">Birmingham Science Park Aston</option><option value="3">Booking.com Offices, Lyon</option><option value="4">The Dragon Inn</option><option value="1">To Be Confirmed</option><option value="2">University of Westminster</option></select>');

}
