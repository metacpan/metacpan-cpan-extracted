use strict;
use warnings;

use Encode             qw( encode_utf8 );
use HTTP::Headers      ();
use HTTP::Request      ();
use HTTP::Response     ();
use Log::Dispatch      ();
use LWP::ConsoleLogger ();
use Test::More import => [qw( done_testing subtest like unlike )];
use Test::Warnings;

# Anonymous fake UA — has no title() and a no-op cookie_jar
{
    package Fake::UA;
    sub new        { bless {}, shift }
    sub cookie_jar { undef }
    sub can { my ( $s, $m ) = @_; $m eq 'title' ? 0 : $s->SUPER::can($m) }
}

sub make_logger {
    my $captured = shift;    # arrayref the caller wants populated
    return Log::Dispatch->new(
        outputs => [
            [
                'Code',
                min_level => 'debug',
                code      => sub {
                    my %args = @_;
                    push @{$captured}, $args{message};
                },
            ],
        ],
    );
}

sub make_response {
    my %args    = @_;
    my $headers = HTTP::Headers->new(
        'Content-Type' => 'text/plain; charset=utf-8',
        Title          => $args{title},
    );
    my $res = HTTP::Response->new( 200, 'OK', $headers, 'body' );
    $res->request( HTTP::Request->new( GET => 'http://example.com/' ) );
    return $res;
}

my $greek_chars = "\x{03B1}\x{03B9}\x{03C1}\x{03B5}\x{03AF}\x{03B1}";
my $greek_bytes = encode_utf8($greek_chars);
subtest 'raw UTF-8 bytes in Title header render correctly (pretty)' => sub {
    my @captured;
    my $cl = LWP::ConsoleLogger->new(
        logger       => make_logger( \@captured ),
        dump_content => 0,
        dump_headers => 1,
        dump_text    => 0,
        pretty       => 1,
    );
    $cl->response_callback(
        make_response( title => $greek_bytes ),
        Fake::UA->new
    );

    my $all = join "\n", @captured;
    like( $all, qr/\Q$greek_chars\E/, 'Greek characters present in output' );
    unlike( $all, qr/Î±Î¹/, 'no mojibake in output' );
};

subtest 'raw UTF-8 bytes in Title header render correctly (pretty=>0)' =>
    sub {
    my @captured;
    my $cl = LWP::ConsoleLogger->new(
        logger       => make_logger( \@captured ),
        pretty       => 0,
        dump_content => 0,
        dump_text    => 0,
    );
    $cl->response_callback(
        make_response( title => $greek_bytes ),
        Fake::UA->new
    );

    my $all = join "\n", @captured;
    like(
        $all, qr/Title: \Q$greek_chars\E/,
        'Greek characters present after Title: prefix'
    );
    unlike( $all, qr/Î±Î¹/, 'no mojibake' );
    };

subtest 'multi-value header emits one line per value (non-pretty)' => sub {
    my @captured;
    my $cl = LWP::ConsoleLogger->new(
        logger       => make_logger( \@captured ),
        pretty       => 0,
        dump_content => 0,
        dump_headers => 1,
        dump_text    => 0,
    );

    my $headers = HTTP::Headers->new( 'Content-Type' => 'text/plain' );
    $headers->push_header( 'Set-Cookie' => 'a=1' );
    $headers->push_header( 'Set-Cookie' => 'b=2' );
    my $res = HTTP::Response->new( 200, 'OK', $headers, 'body' );
    $res->request( HTTP::Request->new( GET => 'http://example.com/' ) );

    $cl->response_callback( $res, Fake::UA->new );

    my $all = join "\n", @captured;
    like( $all, qr/Set-Cookie: a=1\b/, 'first cookie on its own line' );
    like( $all, qr/Set-Cookie: b=2\b/, 'second cookie on its own line' );
    unlike( $all, qr/Set-Cookie: a=1, b=2/, 'values are not comma-joined' );
};

{
    package Fake::UA::WithTitle;
    sub new        { bless { title => $_[1] }, $_[0] }
    sub cookie_jar { undef }
    sub title      { $_[0]->{title} }

    sub can {
        my ( $s, $m ) = @_;
        return 1 if $m eq 'title';
        return $s->SUPER::can($m);
    }
}

subtest 'ua title with raw UTF-8 bytes renders as decoded characters' => sub {
    my @captured;
    my $cl = LWP::ConsoleLogger->new(
        logger       => make_logger( \@captured ),
        dump_content => 0,
        dump_text    => 0,
    );
    $cl->response_callback(
        make_response( title => 'plain' ),
        Fake::UA::WithTitle->new($greek_bytes)
    );

    my $all = join "\n", @captured;
    like(
        $all, qr/Title: \Q$greek_chars\E/,
        'Title line shows decoded chars'
    );
    unlike( $all, qr/Title: Î/, 'Title is not mojibake' );
};

done_testing;
