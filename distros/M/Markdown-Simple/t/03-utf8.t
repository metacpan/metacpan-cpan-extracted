use strict;
use warnings;
use utf8;
use Test::More;
use Markdown::Simple;

# Bytes go in, bytes come out — assert the UTF-8 sequence survives.
my $md   = "# \xC6\x92\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8b\n\n\xF0\x9F\x98\x80\n";
my $html = markdown_to_html($md);
like $html, qr|<h1>\xC6\x92\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8\xC3\xB8b</h1>|,
    'UTF-8 heading preserved';
like $html, qr|<p>\xF0\x9F\x98\x80</p>|, 'UTF-8 emoji in paragraph';

done_testing;
