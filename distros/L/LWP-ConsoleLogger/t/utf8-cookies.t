use strict;
use warnings;

use Encode               qw( encode_utf8 );
use HTTP::Cookies        ();
use HTTP::CookieJar::LWP ();
use HTTP::Headers        ();
use HTTP::Request        ();
use HTTP::Response       ();
use Log::Dispatch        ();
use LWP::ConsoleLogger   ();
use Test::More import => [qw( done_testing like unlike subtest )];
use Test::Warnings;

{
    package Fake::UA;
    sub new        { bless { jar => $_[1] }, $_[0] }
    sub cookie_jar { $_[0]->{jar} }
    sub can { my ( $s, $m ) = @_; $m eq 'title' ? 0 : $s->SUPER::can($m) }
}

my $greek_chars = "\x{03B1}\x{03B9}\x{03C1}\x{03B5}\x{03AF}\x{03B1}";
my $greek_bytes = encode_utf8($greek_chars);

subtest 'cookie value with raw UTF-8 bytes renders as decoded characters' =>
    sub {
    my @captured;
    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'Code',
                min_level => 'debug',
                code      => sub {
                    my %args = @_;
                    push @captured, $args{message};
                },
            ],
        ],
    );

    my $jar = HTTP::Cookies->new;
    $jar->set_cookie(
        0,                # version
        'greek',          # key
        $greek_bytes,     # val (raw UTF-8 bytes)
        '/',              # path
        'example.com',    # domain
        undef, 0, 0,      # port, path_spec, secure
        86400,            # maxage
    );

    my $cl = LWP::ConsoleLogger->new(
        logger       => $logger,
        dump_cookies => 1,
        dump_content => 0,
        dump_text    => 0,
        dump_headers => 0,
    );

    my $req = HTTP::Request->new( GET => 'http://example.com/' );
    my $res = HTTP::Response->new(
        200,                                                  'OK',
        HTTP::Headers->new( 'Content-Type' => 'text/plain' ), 'body'
    );
    $res->request($req);

    $cl->response_callback( $res, Fake::UA->new($jar) );

    my $all = join "\n", @captured;
    like(
        $all, qr/\Q$greek_chars\E/,
        'Greek characters present in cookie output'
    );
    unlike( $all, qr/Î±Î¹/, 'no mojibake in cookie output' );
    };

subtest
    'HTTP::CookieJar value with raw UTF-8 bytes renders as decoded characters'
    => sub {
    my @captured;
    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'Code',
                min_level => 'debug',
                code      => sub {
                    my %args = @_;
                    push @captured, $args{message};
                },
            ],
        ],
    );

    my $jar = HTTP::CookieJar::LWP->new;
    $jar->add(
        'http://example.com/',
        "greek=$greek_bytes; Path=/; Max-Age=86400"
    );

    my $cl = LWP::ConsoleLogger->new(
        logger       => $logger,
        dump_cookies => 1,
        dump_content => 0,
        dump_text    => 0,
        dump_headers => 0,
    );

    my $req = HTTP::Request->new( GET => 'http://example.com/' );
    my $res = HTTP::Response->new(
        200,                                                  'OK',
        HTTP::Headers->new( 'Content-Type' => 'text/plain' ), 'body'
    );
    $res->request($req);

    $cl->response_callback( $res, Fake::UA->new($jar) );

    my $all = join "\n", @captured;
    like(
        $all, qr/\Q$greek_chars\E/,
        'Greek characters present in CookieJar output'
    );
    unlike( $all, qr/Î±Î¹/, 'no mojibake in CookieJar output' );
    };

done_testing;
