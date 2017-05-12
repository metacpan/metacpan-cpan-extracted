use utf8;
use warnings;
use strict;

use Test::More;
use Test::Deep;
use HTTP::Body;
use HTTP::Request::Common;
use Encode;
use File::Spec::Functions;
use File::Temp qw/ tempdir /;

SKIP: {
    eval { require HTTP::Message::PSGI };

    skip "Plack not installed", 13 if $@;

    my $string_for_utf8 = 'test ♥';
    my $string_in_utf8 = Encode::encode('UTF-8',$string_for_utf8);
    my $string_for_shiftjis = 'test テスト';
    my $string_in_shiftjis = Encode::encode('SHIFT_JIS',$string_for_shiftjis);
    my $path = File::Spec->catfile('t', 'utf8.txt');

    ok my $req = POST '/root/echo_arg',
      Content_Type => 'form-data',
        Content =>  [
          arg0 => 'helloworld',
          arg1 => [
            undef, '',
            'Content-Type' =>'text/plain; charset=UTF-8',
            'Content' => $string_in_utf8, ],
          arg2 => [
            undef, '',
            'Content-Type' =>'text/plain; charset=SHIFT_JIS',
            'Content' => $string_in_shiftjis, ],
          arg2 => [
            undef, '',
            'Content-Type' =>'text/plain; charset=SHIFT_JIS',
            'Content' => $string_in_shiftjis, ],
          file => [
            "$path", Encode::encode_utf8('♥ttachment.txt'), 'Content-Type' =>'text/html; charset=UTF-8'
          ],
        ];


    ok my $env = HTTP::Message::PSGI::req_to_psgi($req);
    ok my $fh = $env->{'psgi.input'};
    ok my $body = HTTP::Body->new( $req->header('Content-Type'), $req->header('Content-Length') );
    ok my $tempdir = tempdir( 'XXXXXXX', CLEANUP => 1, DIR => File::Spec->tmpdir() );
    $body->tmpdir($tempdir);

    binmode $fh, ':raw';

    while ( $fh->read( my $buffer, 1024 ) ) {
      $body->add($buffer);
    }

    is $body->param->{'arg0'}, 'helloworld';
    is $body->param->{'arg1'}, $string_in_utf8;
    is $body->param->{'arg2'}[0], $string_in_shiftjis;
    is $body->param->{'arg2'}[1], $string_in_shiftjis;

    cmp_deeply(
        $body->part_data->{'arg0'},
        {
            data => 'helloworld',
            headers => {
                'Content-Disposition' => re(qr{^form-data\b}),
            },
            done => 1,
            name => 'arg0',
            size => 10,
        },
        'arg0 part data correct',
    );
    cmp_deeply(
        $body->part_data->{'arg1'},
        {
            data => $string_in_utf8,
            headers => {
                'Content-Disposition' => re(qr{^form-data\b}),
                'Content-Type' => 'text/plain; charset=UTF-8',
            },
            done => 1,
            name => 'arg1',
            size => length($string_in_utf8),
        },
        'arg1 part data correct',
    );

    cmp_deeply(
        $body->part_data->{'arg2'},
        [
            ({
                data => $string_in_shiftjis,
                headers => {
                    'Content-Disposition' => re(qr{^form-data\b}),
                    'Content-Type' => 'text/plain; charset=SHIFT_JIS',
                },
                done => 1,
                name => 'arg2',
                size => length($string_in_shiftjis),
            }) x 2,
        ],
        'arg2 part data correct',
    );

};

done_testing;
