use strict;
use warnings;
use utf8;
use Test::More;
use Email::MIME::MobileJP::Creator;
use Encode ();

subtest 'single part(docomo)' => sub {
    my $creator = Email::MIME::MobileJP::Creator->new('docomo.taro.@docomo.ne.jp');
    is $creator->header('To'), 'docomo.taro.@docomo.ne.jp';
    $creator->subject('こんにちわ!');
    $creator->body('ほげほげ');

    is $creator->subject(), 'こんにちわ!';
    is $creator->body(), 'ほげほげ';
    is $creator->mail->content_type(), 'text/plain; charset="Shift_JIS"';

    my $mail = $creator->finalize();
    my $str = $mail->as_string;
    ok !Encode::is_utf8($str);
    like $str, qr{\QSubject: =?SHIFT_JIS?B?grGC8YLJgr+C7SE=?=};
    note $str;
};

subtest 'single part(ezweb)' => sub {
    my $creator = Email::MIME::MobileJP::Creator->new('example@ezweb.ne.jp');
    is $creator->header('To'), 'example@ezweb.ne.jp';
    $creator->subject('こんにちわ!');
    $creator->body('ほげほげ');
    isa_ok $creator->carrier, 'Email::Address::JP::Mobile::EZweb';
    isa_ok $creator->carrier->mime_encoding(), 'Encode::JP::Mobile::MIME::KDDI::SJIS';
    isa_ok $creator->carrier->send_encoding(), 'Encode::JP::Mobile::_ConvertPictogramSJISkddi-auto';

    is $creator->subject(), 'こんにちわ!';
    is $creator->body(), 'ほげほげ';
    is $creator->mail->content_type(), 'text/plain; charset="Shift_JIS"';

    my $mail = $creator->finalize();
    my $str = $mail->as_string;
    ok !Encode::is_utf8($str);
    note $str;
};

subtest 'multi part' => sub {
    my $creator = Email::MIME::MobileJP::Creator->new('docomo.taro.@docomo.ne.jp');
    is $creator->header('To'), 'docomo.taro.@docomo.ne.jp';
    $creator->subject('こんにちわ!');

    is $creator->subject(), 'こんにちわ!';
    is $creator->mail->content_type(), 'text/plain; charset="Shift_JIS"';

    $creator->add_text_part('ほげほげ');
    $creator->add_part(
        "JFIF(ry" => +{
            content_type => 'image/jpeg',
            name         => 'hoge',
            filename     => 'hoge.jpg',
            encoding     => 'base64',
            disposition  => 'attachment',
        }
    );

    my $mail = $creator->finalize();
    isa_ok $mail, 'Email::MIME';
    my $str = $mail->as_string;
    ok !Encode::is_utf8($str);
    like $str, qr{\QSubject: =?SHIFT_JIS?B?grGC8YLJgr+C7SE=?=};
    like $str, qr{Content-Type: image/jpeg; name="hoge"};
    note $str;
};

done_testing;

