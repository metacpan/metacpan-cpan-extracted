use v5.14;
use warnings;

use Test2::V0;

use HTTP::CSPHeader;

subtest "basic header with amendment" => sub {

    my $h = HTTP::CSPHeader->new(
        policy => {
            "default-src" => q['self'],
            "image-src"   => q[static.example.com],
            "script-src"  => q['self'],
            "style-src"   => q['self'],
        },
    );

    isa_ok $h, 'HTTP::CSPHeader';

    note my $header = $h->header;

    like $header, qr[\bdefault-src 'self'(; |\z)],             'default-src';
    like $header, qr[\bscript-src 'self'(; |\z)],              'script-src';
    like $header, qr[\bstyle-src 'self'(; |\z)],               'style-src';
    like $header, qr[\bimage-src static\.example\.com(; |\z)], 'image-src';

    $h->amend( '+script-src' => 'cdn.example.com' );
    like $h->header, qr[\bscript-src 'self' cdn\.example\.com(; |\z)], 'script-src (append)';

    $h->amend( 'script-src' => 'cdn.example.com' );
    like $h->header, qr[\bscript-src cdn\.example\.com(; |\z)], 'script-src (overwrite)';

    $h->amend( 'style-src' => undef );
    unlike $h->header, qr[\bstyle-src\b], 'style-src (removed)';

    $h->amend( 'media-src' => 'https:' );
    like $h->header, qr[\bmedia-src https:(; |\z)], 'media-src (create)';

    $h->reset;

    like $h->header,   qr[\bdefault-src 'self'(; |\z)],             'default-src (reset)';
    like $h->header,   qr[\bscript-src 'self'(; |\z)],              'script-src (reset)';
    like $h->header,   qr[\bstyle-src 'self'(; |\z)],               'style-src (reset)';
    like $h->header,   qr[\bimage-src static\.example\.com(; |\z)], 'image-src (reset)';
    unlike $h->header, qr[\bmedia-src\b],                           'media-src (reset)';

};

subtest 'nonce' => sub {

    my $h = HTTP::CSPHeader->new(
        nonces_for => [qw/ script-src style-src /],
        policy     => {
            "script-src" => q['self'],
            "style-src"  => q['self'],
        },
    );

    isa_ok $h, 'HTTP::CSPHeader';

    ok my $n1 = $h->nonce, 'nonce';

    note $h->header;

    like $h->header, qr[\bscript-src 'self' 'nonce-$n1'(; |\z)], 'script-src';
    like $h->header, qr[\bstyle-src 'self' 'nonce-$n1'(; |\z)],  'style-src';

    $h->reset;

    ok my $n2 = $h->nonce, 'nonce';

    isnt $n2, $n1, "nonce changed after reset";

    note $h->header;

    like $h->header, qr[\bscript-src 'self' 'nonce-$n2'(; |\z)], 'script-src';
    like $h->header, qr[\bstyle-src 'self' 'nonce-$n2'(; |\z)],  'style-src';

};

subtest 'corce nonces_for' => sub {

    my $h = HTTP::CSPHeader->new(
        nonces_for => 'script-src',
        policy     => {
            "script-src" => q['self'],
            "style-src"  => q['self'],
        },
    );

    isa_ok $h, 'HTTP::CSPHeader';

    is $h->nonces_for, [qw/ script-src /], 'nonces_for';
};

done_testing;
