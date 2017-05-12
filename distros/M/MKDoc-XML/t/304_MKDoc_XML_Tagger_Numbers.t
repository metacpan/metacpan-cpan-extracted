#!/usr/bin/perl
use lib ('../lib', 'lib');
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tagger::Preserve;
use MKDoc::XML::Tagger;

{
    my $text = MKDoc::XML::Tagger->process_data (
        "<p>stuff 1</p>",
        { _expr => '&(1)', _tag => 'a', href => '/' }
    );

    like ($text, qr|<p>stuff 1</p>|);
}

{
    my $text = MKDoc::XML::Tagger->process_data (
        "<p>stuff 1</p>",
        { _expr => '1', _tag => 'a', href => '/' }
    );

    # very wrong
    # like ($text, qr|&\(<a href=\"/\">1</a>\)stuff <a href=\"/\">1</a></p>|);

    # correct output
    like ($text, qr|<p>stuff <a href=\"/\">1</a></p>|);
}

{
    my $text = MKDoc::XML::Tagger->process_data (
        "<p>stuff &amp;(1)</p>",
        { _expr => '&(1)', _tag => 'a', href => '/' }
    );

    like ($text, qr|<p>stuff <a href=\"/\">&amp;\(1\)</a></p>|);
}

1;

__END__
