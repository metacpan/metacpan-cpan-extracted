use strict;
use warnings;

use Test::More;

use Email::Simple::Markdown;

plan skip_all => "No markdown module found"
    unless eval { Email::Simple::Markdown->find_markdown_engine };

plan tests => 3;

my $email = Email::Simple::Markdown->create(
    header => [
        From    => 'me@here.com',
        To      => 'you@there.com',
        Subject => q{Here's a multipart email},
    ],
    body => '[this](http://metacpan.org/search?q=Email::Simple::Markdown) is *amazing*',
    charset => 'utf8',
);

my $text = $email->as_string;

isa_ok $email->with_markdown, 'Email::Abstract';

like $text, qr#<em>amazing</em>#, 'html is present';

like $text => qr#Content-Type: text/plain; charset="utf8"\s*\n#, "content type is utf8";
