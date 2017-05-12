#!perl -T

use Test::More;
use Test::Exception;

BEGIN {
    use_ok( 'Encode::Detect::Upload' ) || print "Bail out!\n";
}

diag( "Testing Encode::Detect::Upload $Encode::Detect::Upload::VERSION, Perl $], $^X" );

my $detector = new Encode::Detect::Upload;

note( 'get_os' );
subtest 'get_os', sub {
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1';
    is( $detector->get_os(), 'Windows', 'Windows user_agent detection' );
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.7a) Gecko/2008070208 Firefox/3.0.1';
    is( $detector->get_os(), 'Macintosh', 'Macintosh user_agent detection' );
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (X11; U; Linux; i686; en-US; rv:1.6) Gecko/2008070208 Firefox/3.0.1';
    is( $detector->get_os(), 'Linux', 'Linux user_agent detection' );
    $ENV{HTTP_USER_AGENT} = '';
    throws_ok( sub { $detector->get_os() }, qr/No USER_AGENT/, 'NO OS vars available' );
    $ENV{HTTP_USER_AGENT} = 'no match';
    is( $detector->get_os(), undef, 'Unknown user_agent detection' );
};

note( 'get_country' );
SKIP: {
    skip('get_country tests rely on IP::Country', 1) if !$INC{'IP::Country'};
    subtest 'get_country', sub {
        $ENV{REMOTE_ADDR} = '94.116.13.219';
        is( $detector->get_country(), 'United Kingdom', 'IP -> country' );
        $ENV{REMOTE_ADDR} = '';
        throws_ok( sub { $detector->get_country() }, qr/No IP/, 'No IP vars available' );
        $ENV{REMOTE_ADDR} = '12312312.12312312.123123123.1231232';
        throws_ok( sub { $detector->get_country() }, qr/not a valid IP/, 'Invalid IP' );
    };
}

note( 'get_country_lang' );
subtest 'get_country_lang', sub {
    is( $detector->get_country_lang('gb'), 'en-gb', 'British English (correct English)' );
    my @lang_ls = $detector->get_country_lang('gb');
    is_deeply( \@lang_ls, [ 'en-gb', 'cy-gb', 'gd' ], 'Language list' );
    throws_ok( sub { $detector->get_country_lang() }, qr/No country passed/, 'No country passed' );
};

note( 'get_country_name' );
subtest 'get_country_name', sub {
    is( $detector->get_country_name('gb'), 'United Kingdom', 'United Kingdom' );
    throws_ok( sub { $detector->get_country_name() }, qr/No country passed/, 'No country passed' );
};

note( 'get_accept_lang' );
subtest 'get_accept_lang', sub {
    $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb,en-us;q=0.8,en;q=0.6';
    is( $detector->get_accept_lang(), 'en-gb', 'British English' );
    my @lang_ls = $detector->get_accept_lang();
    is_deeply( \@lang_ls, [ 'en-gb', 'en-us', 'en' ], 'Language list' );
    $ENV{HTTP_ACCEPT_LANGUAGE} = '';
    throws_ok( sub { $detector->get_accept_lang() }, qr/No ACCEPT_LANGUAGE/, 'No ACCEPT_LANGUAGE passed' );
};

note( 'get_lang_name' );
subtest 'get_lang_name', sub {
    is( $detector->get_lang_name('en-gb'), 'English - Great Britain', 'United Kingdom' );
    is( $detector->get_lang_name('funny-language'), undef, 'Unknown language' );
    throws_ok( sub { $detector->get_lang_name() }, qr/No language passed/, 'No language passed' );
};

note( 'get_lang_list' );
subtest 'get_lang_list', sub {
    my @lang_ls = $detector->get_lang_list('en-gb');
    is_deeply( \@lang_ls, [ 'en-gb', 'en' ], 'Language list' );
    @lang_ls = $detector->get_lang_list('az');
    is_deeply( \@lang_ls, [ 'az', 'az-latn', 'az-cyrl' ], 'Language list' );
    throws_ok( sub { $detector->get_lang_list() }, qr/No language passed/, 'No language passed' );
};

note( 'get_lang_charset' );
subtest 'get_lang_charset', sub {
    is( $detector->get_lang_charset('en-gb','windows'), 'windows-1252', 'Charset' );
    my @char_ls = $detector->get_lang_charset('en-gb');
    is_deeply( \@char_ls, [ 'windows-1252', 'x-mac-roman', 'iso-8859-1' ], 'Charset list' );
    throws_ok( sub { $detector->get_lang_charset() }, qr/No language tag passed/, 'No language tag passed' );
};

note( 'get_words' );
subtest 'get_words', sub {
    my @words = $detector->get_words( "The Magazine Mari\x{e9} Cl\x{e2}re" );
    is_deeply( \@words, [ "Mari\x{e9}", "Cl\x{e2}re" ], 'Non ASCII words' );
    throws_ok( sub { $detector->get_words() }, qr/No sample text passed/, 'No sample text passed' );
};


done_testing();
