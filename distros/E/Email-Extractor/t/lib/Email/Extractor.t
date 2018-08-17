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

# use Data::Dumper;
# warn Dumper $crawler->extract_contact_links('<a href="kontakty" title="">Че то там</a>');

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

    # L<Email::Extractor/contacts> extracted in uppercase and lowercase

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

    is_deeply( $crawler->get_emails_from_uri( $html_loc . '/antispam.html' ),
        [], 'No emails at antispam.html' );

};

subtest "_get_emails_from_text" => sub {

    is_deeply( $crawler->_get_emails_from_text('<!--Rating@Mail.ru COUNTER-->'),
        [], 'Mail ru counter is not email' )

};

subtest "search_until_attempts" => sub {

    no warnings 'redefine';

    local *Email::Extractor::get_emails_from_uri = sub {
        return [];
    };

    local *Email::Extractor::extract_contact_links = sub {
        return undef;
    };

    use Data::Dumper;

    is $crawler->search_until_attempts( 'http://example.com', 0 ),
      undef,
      'return undef if no email on main page and no contact links';

    local *Email::Extractor::get_emails_from_uri = sub {
        return [ 'my@example.com', 'your@example.com' ];
    };

    is_deeply $crawler->search_until_attempts( 'http://example.com', 0 ),
      [ 'my@example.com', 'your@example.com' ],
      'Return result of get_emails_from_uri if emails found on main page';

    is_deeply $crawler->search_until_attempts( 'http://example.com', 5 ),
      [ 'my@example.com', 'your@example.com' ],
'Return result of get_emails_from_uri if emails found on main page and attempts = 5';

    # simulate that email found on second contact link

    local *Email::Extractor::extract_contact_links = sub {
        return [ '/about', '/contacts' ];
    };

    local *Email::Extractor::get_emails_from_uri = sub {
        my ( $self, $addr ) = @_;
        return [] if $addr eq '/about';
        return ['test@example.com'] if $addr eq '/contacts';
    };

    is_deeply $crawler->search_until_attempts('http://example.com'),
      ['test@example.com'],
      'Email found on second contact link'

};

done_testing();
