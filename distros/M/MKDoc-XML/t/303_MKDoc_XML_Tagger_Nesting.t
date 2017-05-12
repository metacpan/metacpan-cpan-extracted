#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tagger::Preserve;
use MKDoc::XML::Tagger;

{

    my $text = MKDoc::XML::Tagger->process_data (
        "<p>URI <i>Name</i></p>",
        { _expr => 'URI Name', _tag => 'a', href => '/' }
    );

    #$text = '<p><a href="/">URI </a><i><a href="/">Name</a></i></p>' ."\n";
    like ($text, qr/<p><a href=\"\/\">URI <\/a><i><a href=\"\/\">Name<\/a><\/i><\/p>/);
}

1;

__END__
