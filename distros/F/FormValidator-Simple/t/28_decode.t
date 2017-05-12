use strict;
use Test::More tests => 17;
BEGIN{ use_ok("FormValidator::Simple") }
use CGI;
my $conf_file = "t/conf/messages_ja.yml";
FormValidator::Simple->set_messages($conf_file);
FormValidator::Simple->set_message_decode_from('utf-8');

my $q = CGI->new;
$q->param( data1 => 'hoge' );
$q->param( data2 => '123'  );
$q->param( data3 => ''     );

my $r = FormValidator::Simple->check( $q => [
    data1 => [qw/NOT_BLANK INT/, [qw/LENGTH 0 3/] ],
    data2 => [qw/NOT_BLANK ASCII/, [qw/LENGTH 5/]],
    data3 => [qw/NOT_BLANK/],
] );

my $messages = $r->messages('test');

ok (Encode::is_utf8($messages->[0]));
ok (Encode::is_utf8($messages->[1]));
ok (Encode::is_utf8($messages->[2]));
ok (Encode::is_utf8($messages->[3]));

is($messages->[0], Encode::decode('utf-8','data1は整数で入力してください。'));
is($messages->[1], Encode::decode('utf-8','data1の長さが不正です。'));
is($messages->[2], Encode::decode('utf-8','data2の値が不正です。'));
is($messages->[3], Encode::decode('utf-8','data3を入力してください。'));


FormValidator::Simple->set_message_format('<p>%s</p>');
my $messages2 = $r->messages('test');

ok (Encode::is_utf8($messages2->[0]));
ok (Encode::is_utf8($messages2->[1]));
ok (Encode::is_utf8($messages2->[2]));
ok (Encode::is_utf8($messages2->[3]));

is($messages2->[0], Encode::decode('utf-8','<p>data1は整数で入力してください。</p>'));
is($messages2->[1], Encode::decode('utf-8','<p>data1の長さが不正です。</p>'));
is($messages2->[2], Encode::decode('utf-8','<p>data2の値が不正です。</p>'));
is($messages2->[3], Encode::decode('utf-8','<p>data3を入力してください。</p>'));

