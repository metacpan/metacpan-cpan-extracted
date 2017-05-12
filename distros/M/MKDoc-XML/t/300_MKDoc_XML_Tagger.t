#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tagger;
use MKDoc::XML::Tokenizer;


# _tag_close and _tag_open functions
{
    my $tag = MKDoc::XML::Tagger::_tag_close ('strong');
    is ($tag, '</strong>');
    
    $tag = MKDoc::XML::Tagger::_tag_open ('strong');
    is ($tag, '<strong>');
    
    $tag = MKDoc::XML::Tagger::_tag_open ('strong', { class => 'superFort' });
    is ($tag, '<strong class="superFort">');
}


# this regex should match any amount of consecutive whitespace,
# or \&(214) like tags, or carriage returns
{
    my $sample_text = <<EOF;
   \&(214) \&(214)
\&(22)  \&(214)  \&(33)
 \&(2142343432432) 
EOF

    if (0) { $MKDoc::XML::Tagger::Ignorable_RE = $MKDoc::XML::Tagger::Ignorable_RE } # no silly warnings
    my $re = '^' . $MKDoc::XML::Tagger::Ignorable_RE . '$';
    like ($sample_text, qr/$re/);
    unlike ('hello world', qr /$re/);
}


# _segregate_markup_from_text
{
    my $example = <<'EOF';
Abstract

The Extensible Markup Language (XML) is a subset of <strong>SGML</strong>
that is <a href="foo">completely described</a> in this document.
EOF
    
    my $tokens        = MKDoc::XML::Tokenizer->process_data ($example);
    my ($text, $tags) = MKDoc::XML::Tagger::_segregate_markup_from_text ($tokens);
    like ($text, qr/\&\(1\)SGML\&\(2\)/);
    like ($text, qr/\&\(3\)completely described\&\(4\)/);
}


# more nasty test
{
    my $r = MKDoc::XML::Tagger->process_data (
	'Hello Cool World!',
        { _expr => 'Cool World',       _tag => 'a', href => 'cw', alt => 'foo'  },
        { _expr => 'Hello Cool World', _tag => 'a', href => 'hcw' }
       );
    is ($r, '<a href="hcw">Hello Cool World</a>!');

    $r = MKDoc::XML::Tagger->process_data (
	'&lt;hello&gt;',
        { _expr => 'hello', _tag => 'a', href => 'http://www.hello.com/' },
       );

    like ($r, qr/<a/);
}


# more nasty test
{
    my $r = MKDoc::XML::Tagger->process_data (
        '<p>News foo bar<strong>Statements</strong>, declarations</p>',
        {
            '_expr' => 'news',
            'href' => 'http://news.com/',
            '_tag' => 'a',
        },
        {
            '_expr' => 'News',
            'lang' => 'en',
            'href' => 'http://users.groucho/news/',
            '_tag' => 'a',
        }
    );
}


{
    my $data = qq |<span><p>&lt;p&gt;this is a test, hello world, this is a test&lt;/p&gt;</p></span>|;
    my $r = MKDoc::XML::Tagger->process_data (
        $data,
        { _expr => 'Hello World', _tag => 'a', href => 'cw', alt => 'foo'  }
    );
}


{
    my $r = MKDoc::XML::Tagger->process_data (
        'q &amp; a',
        {
            '_expr' => 'Q & A',
            'href' => 'http://news.com/',
            '_tag' => 'a',
        }
     );

     is ($r, '<a href="http://news.com/">q &amp; a</a>');
}


1;


__END__
