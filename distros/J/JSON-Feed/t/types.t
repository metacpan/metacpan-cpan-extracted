#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test2::V0;

use JSON::Feed::Types qw(JSONFeed JSONFeedAuthor JSONFeedAttachment JSONFeedItem);

subtest JSONFeed=> sub {
    my @good_vals = (
        { version => "https://jsonfeed.org/version/1", title => "Good", items => [] },
        { version => "https://jsonfeed.org/version/1", title => "Good", _ext_meh => "Meh", items => [] },
    );
    
    for (@good_vals) {
        ok JSONFeed->check($_);
    }

    my @bad_vals = (
        {},
        [],
        { meh => "Bah" },
        { _meh => "Bah" },
        { version => "https://jsonfeed.org/version/1", title => "Good", _ext_meh => "Meh", items => [{ _meh => "Meh" }] },
    );
    
    for (@bad_vals) {
        ok ! JSONFeed->check($_);
    }
};

subtest JSONFeedItem=> sub {
    my @good_vals = (
        { id => "https://example.com/attachments/1.jpg" },
        { id => "https://example.com/attachments/1.jpg", _meh => "Meh" },
    );
    
    for (@good_vals) {
        ok JSONFeedItem->check($_);
    }

    my @bad_vals = (
        {},
        [],
        { meh => "Bah" },
        { _meh => "Bah" },
    );
    
    for (@bad_vals) {
        ok ! JSONFeedItem->check($_);
    }
};

subtest JSONFeedAttachment => sub {
    my @good_vals = (
        { url => "https://example.com/attachments/1.jpg", mime_type => "image/jpeg" },
        { url => "https://example.com/attachments/1.jpg", mime_type => "image/jpeg", _ext_meh => "Meh" },
        { url => "https://example.com/attachments/1.jpg", mime_type => "image/jpeg", title => "One JPG", _ext_meh => "Meh" },
    );
    
    for (@good_vals) {
        ok JSONFeedAttachment->check($_);
    }

    my @bad_vals = (
        {},
        [],
        { meh => "Bah" },
        { _meh => "Bah" },
    );
    
    for (@bad_vals) {
        ok ! JSONFeedAttachment->check($_);
    }
};

subtest JSONFeedAuthor => sub {
    my @good_vals = (
        { name => "Someone" },
        { name => "Someone", url => "https://example.com" },
        { url => "https://example.com" },
        { url => "https://example.com", "avatar" => "https://example.com/someone.jpg" },
        { url => "https://example.com", _meh => "Meh" },
    );
    
    for (@good_vals) {
        ok JSONFeedAuthor->check($_);
    }

    my @bad_vals = (
        { _meh => "Meh" },
        { meh => "Bah" },
    );
    
    for (@bad_vals) {
        ok ! JSONFeedAuthor->check($_);
    }
};

done_testing;
