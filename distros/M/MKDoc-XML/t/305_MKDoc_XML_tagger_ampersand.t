#!/usr/bin/perl
use lib ('../lib', 'lib');
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tagger::Preserve;
use MKDoc::XML::Tagger;

{
    my $text = MKDoc::XML::Tagger->process_data (
        "<p>stuff</p>",
        { _expr => 'stuff', _tag => 'a', href => 'http://example.com/foo.cgi?a=b&c=d' }
    );

    like ($text, qr|<p><a href="http://example\.com/foo\.cgi\?a=b&amp;c=d">stuff</a></p>|, '& double escaped');
};

{
    my $text = MKDoc::XML::Tagger->process_data (
        "<p>stuff</p>",
        { _expr => 'stuff', _tag => 'foo', bar => '<zzz>' }
    );

    like ($text, qr|<p><foo bar="&lt;zzz&gt;">stuff</foo></p>|, '<> double escaped');
};

{
    my $text = MKDoc::XML::Tagger->process_data (
        "<p>stuff</p>",
        { _expr => 'stuff', _tag => 'foo', bar => '"hello world"' }
    );

    like ($text, qr|<p><foo bar="&quot;hello world&quot;">stuff</foo></p>|, '" double escaped');
};

1;

__END__
