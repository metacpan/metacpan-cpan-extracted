use strict;
use warnings;

use Test::More;

use Email::Simple::Markdown;

plan skip_all => "No markdown module found"
    unless eval { Email::Simple::Markdown->find_markdown_engine };

plan tests => 2;

my $txt = '[this](http://metacpan.org/search?q=Email::Simple::Markdown) is *amazing*';

{
my $email = Email::Simple::Markdown->create(
    header => [
        From    => 'me@here.com',
        To      => 'you@there.com',
        Subject => q{Here's a multipart email},
    ],
    body => $txt,
    css => 'p { color: red; }',
);

subtest 'text css' => sub { general_checkup( $email ) };
}

{
my $email = Email::Simple::Markdown->create(
    header => [
        From    => 'me@here.com',
        To      => 'you@there.com',
        Subject => q{Here's a multipart email},
    ],
    body => $txt,
    css => [ p => 'color: red;' ],
);

subtest 'arrayref css' => sub { general_checkup( $email ) };
}



sub general_checkup {
    plan tests => 4;

    my $email = shift;

    $email = $email->with_markdown->cast('Email::MIME');

    my %part = map { $_->content_type => $_ } $email->parts;

    is keys %part => 2, 'two parts';

    like $part{'text/plain'}->body => qr/\Q$txt/, 'text part';

    my $html_re = qr!\Q<p><a href="http://metacpan.org/search?q=Email::Simple::Markdown">this</a> is <em>amazing</em></p>!;

    like $part{'text/html'}->body => qr/$html_re/, 'html part';

    like $part{'text/html'}->body => qr/\Qp { color: red; }/, 'html part';
}



