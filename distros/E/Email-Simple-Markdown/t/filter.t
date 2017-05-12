use strict;
use warnings;

use Test::More;

use Email::Simple::Markdown;

plan skip_all => "No markdown module found"
    unless eval { Email::Simple::Markdown->find_markdown_engine };

plan tests => 1;

my $txt = '[this](http://metacpan.org/search?q=Email::Simple::Markdown) is *amazing*';

my $email = Email::Simple::Markdown->create(
    header => [
        From    => 'me@here.com',
        To      => 'you@there.com',
        Subject => q{Here's a multipart email},
    ],
    body => $txt,
    pre_markdown_filter => sub { s/^/WORKING/ },
);

my %part = map { $_->content_type => $_ }
            $email->with_markdown->cast('Email::MIME')->parts;

like $part{'text/html'}->body => qr/WORKING/, 'html part';
