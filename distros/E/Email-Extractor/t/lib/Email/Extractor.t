use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Email::Extractor'); }

my $crawler = Email::Extractor->new();

subtest "extract_contact_links" => sub {

    is_deeply(
        $crawler->extract_contact_links(
            '<a href="/index.php/kontakty" title="">Че то там</a>'),
        ['/index.php/kontakty'],
        '<a> href analysis: relative links: extracted fine by url'
    );

    is_deeply(
        $crawler->extract_contact_links(
            '<a href="/index.php/some_url" title="">Контакты</a>'),
        ['/index.php/some_url'],
        '<a> text analysis: relative links: extracted fine by text'
    );

    is_deeply(
        $crawler->extract_contact_links(
            '<a href="http://example.com/kontakty" title="">Че то там</a>'),
        ['http://example.com/kontakty'],
        '<a> href analysis: absolute links: extracted fine in contacts key'
    );

    is_deeply(
        $crawler->extract_contact_links(
            '<a href="http://example.com/some_url" title="">Контакты</a>'),
        ['http://example.com/some_url'],
        '<a> text analysis: absolute links: extracted fine in contacts key'
    );

    is_deeply(
        $crawler->extract_contact_links(
            '<a href="http://какойтодомен.рф/роут" title="">Контакты</a>'),
        ['http://какойтодомен.рф/роут'],
'cyrillic domain: <a> text analysis: absolute links: extracted fine in contacts key'
    );

    is_deeply(
        $crawler->extract_contact_links(
            '<a href="/роут" title="">Контакты</a>'),
        ['/роут'],
'cyrillic domain: <a> text analysis: relative links: cyrillic domain: extracted fine in contacts key'
    );

};

subtest "get_emails_from_uri" => sub {

    my $html_loc = 't/htmls';

    is_deeply(
        $crawler->get_emails_from_uri( $html_loc . '/regexp_test_1.html' ),
        ['school-6@mail.ru'], 'Parsing email from first regular page' );

    is_deeply(
        $crawler->get_emails_from_uri( $html_loc . '/regexp_test_2.html' ),
        ['sh-67@yandex.ru'], 'Parsing email from second regular page' );

    is_deeply(
        $crawler->get_emails_from_uri(
            $html_loc . '/no_links_on_main_page.html'
        ),
        [],
        'Parsing email from third regular page without any email'
    );

};

done_testing();
