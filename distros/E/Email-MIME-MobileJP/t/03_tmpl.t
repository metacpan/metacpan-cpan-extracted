use strict;
use warnings;
use utf8;
use Test::More;
use Email::MIME::MobileJP::Template;
use Test::Requires 'Text::Xslate';
use Encode;

my $tmpl = Email::MIME::MobileJP::Template->new('Text::Xslate' => {syntax => 'TTerse', path => ['./t/tmpl/']});
my $mail = $tmpl->render('tomi...@docomo.ne.jp', 'foo.eml', {name => 'たろう'});
note $mail->as_string();
ok index($mail->as_string, encode('cp932', 'はーい!たろう')) > 0;
is $mail->header('From'), '事務局';
is $mail->header('Subject'), 'たろうさんへの重要な挨拶';

done_testing;

