#!perl
use strict;
use warnings;
use utf8;
use Test2::V0;

use FindBin '$Bin';
use File::Spec;
use File::Glob 'bsd_glob';

use JSON qw<from_json>;
use JSON::Feed::Types qw(JSONFeed);

ok JSONFeed->check( from_json( json_example_1() ) );
ok JSONFeed->check( from_json( json_example_2() ) );
ok JSONFeed->check( from_json( json_example_3() ) );

for my $f ( bsd_glob( File::Spec->catfile($Bin, 'data', '*.json') ) ) {
    open my $fh, '<:utf8', $f;
    local $/;
    my $json = <$fh>;
    close($fh);
    my $o = from_json($json);
    
    if (JSONFeed->check( $o )) {
        pass $f;
    } else {
        diag JSONFeed->get_message( $o );
        fail $f;
    }
}

done_testing;

sub json_example_1 {
    return <<'EXAMPLE';
{
    "version": "https://jsonfeed.org/version/1",
    "title": "My Example Feed",
    "home_page_url": "https://example.org/",
    "feed_url": "https://example.org/feed.json",
    "items": [
        {
            "id": "2",
            "content_text": "This is a second item.",
            "url": "https://example.org/second-item"
        },
        {
            "id": "1",
            "content_html": "<p>Hello, world!</p>",
            "url": "https://example.org/initial-post"
        }
    ]
}
EXAMPLE
}

sub json_example_2 {
    <<'EXAMPLE'
{
    "version": "https://jsonfeed.org/version/1",
    "user_comment": "This is a podcast feed. You can add this feed to your podcast client using the following URL: http://therecord.co/feed.json",
    "title": "The Record",
    "home_page_url": "http://therecord.co/",
    "feed_url": "http://therecord.co/feed.json",
    "items": [
        {
            "id": "http://therecord.co/chris-parrish",
            "title": "Special #1 - Chris Parrish",
            "url": "http://therecord.co/chris-parrish",
            "content_text": "Chris has worked at Adobe and as a founder of Rogue Sheep, which won an Apple Design Award for Postage. Chris’s new company is Aged & Distilled with Guy English — which shipped Napkin, a Mac app for visual collaboration. Chris is also the co-host of The Record. He lives on Bainbridge Island, a quick ferry ride from Seattle.",
            "content_html": "Chris has worked at <a href=\"http://adobe.com/\">Adobe</a> and as a founder of Rogue Sheep, which won an Apple Design Award for Postage. Chris’s new company is Aged & Distilled with Guy English — which shipped <a href=\"http://aged-and-distilled.com/napkin/\">Napkin</a>, a Mac app for visual collaboration. Chris is also the co-host of The Record. He lives on <a href=\"http://www.ci.bainbridge-isl.wa.us/\">Bainbridge Island</a>, a quick ferry ride from Seattle.",
            "summary": "Brent interviews Chris Parrish, co-host of The Record and one-half of Aged & Distilled.",
            "date_published": "2014-05-09T14:04:00-07:00",
            "attachments": [
                {
                    "url": "http://therecord.co/downloads/The-Record-sp1e1-ChrisParrish.m4a",
                    "mime_type": "audio/x-m4a",
                    "size_in_bytes": 89970236,
                    "duration_in_seconds": 6629
                }
            ]
        }
    ]
}
EXAMPLE
}

sub json_example_3 {
    return <<'EXAMPLE';
{
    "version": "https://jsonfeed.org/version/1",
    "user_comment": "This is a microblog feed. You can add this to your feed reader using the following URL: https://example.org/feed.json",
    "title": "Brent Simmons’s Microblog",
    "home_page_url": "https://example.org/",
    "feed_url": "https://example.org/feed.json",
    "author": {
        "name": "Brent Simmons",
        "url": "http://example.org/",
        "avatar": "https://example.org/avatar.png"
    },
    "items": [
        {
            "id": "2347259",
            "url": "https://example.org/2347259",
            "content_text": "Cats are neat. \n\nhttps://example.org/cats",
            "date_published": "2016-02-09T14:22:00-07:00"
        }
    ]
}
EXAMPLE
}

