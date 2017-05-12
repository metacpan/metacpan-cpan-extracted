#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tagger::Preserve;


# _tag_close and _tag_open functions
{
    my $text = <<EOF;
ConnectUK also provides hands-on support to the network offering exhibition
and marketing initiatives, networking and promotional opportunities,xi
 funding, anewsletters and up-to-date regional and national news.
EOF

    $text = MKDoc::XML::Tagger::Preserve->process_data (
        [ 'a' ],
        $text,
        { _expr => 'News', _tag => 'a', href => 'http://news.com/' },
    );

    like ($text, qr/anewsletter/); 
}


1;


__END__
