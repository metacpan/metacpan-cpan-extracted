#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tagger::Preserve;


# _tag_close and _tag_open functions
{
    my $text = qq|Hello, <a href="http://world.com/">Cool World</a>|;
    @MKDoc::XML::Tagger::Preserve::Preserve = ('a');
    my @list = ();
    
    MKDoc::XML::Tagger::Preserve::_compute_unique_string ($text, qq|<a href="http://world.com/">Cool World</a>|, \@list);
    is ($text, 'Hello, <a href="http://world.com/">Cool World</a>');
    is ($list[1], '<a href="http://world.com/">Cool World</a>');
}


# _tag_close and _tag_open functions
{
    my $text = qq|Hello, <a href="http://world.com/">Cool World</a>|;
    @MKDoc::XML::Tagger::Preserve::Preserve = ('a');
    my @list = ();
    
    ($text, @list) = MKDoc::XML::Tagger::Preserve::_preserve_encode ($text);
    unlike ($text, qr/Hello, </);
    is ($list[1], '<a href="http://world.com/">Cool World</a>');
}


# _tag_close and _tag_open functions
{
    my $text = qq|Hello, <a href="http://world.com/">Cool World</a>. Cool huh?|;
    $text = MKDoc::XML::Tagger::Preserve->process_data (
        [ 'a' ],
        $text,
        { _expr => 'cool', _tag => 'a', href => 'http://cool.com/' }
    );
   
    is ($text, qq|Hello, <a href="http://world.com/">Cool World</a>. <a href="http://cool.com/">Cool</a> huh?|);
}


1;


__END__
