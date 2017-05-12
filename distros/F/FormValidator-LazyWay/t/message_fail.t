use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay::Message;
use FormValidator::LazyWay::Rule;
use MyTestBase;
use Test::Exception;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $rule = FormValidator::LazyWay::Rule->new( config => $block->config );
    throws_ok { FormValidator::LazyWay::Message->new( config => $block->config , rule => $rule ) }  qr/lang:en label:\+MyRule::Oppai#name/ , 'no message' ;
}

__END__
=== normal
--- config yaml
rules :
    - Email
    - +MyRule::Oppai
setting :
    strict :
        email :
            rule :
                - Email#email
        oppai : 
            rule :
                - +MyRule::Oppai#name
    loose  :
langs :
    - ja
    - en
lang  : ja
labels : 
    ja :
        subject : 題名
        amount  : 料金
        use_id  : ユーザー番号
messages :
    ja :
        custom_invalid  : 
            foo_error : フーエラー
        rule_message : __field__には__rule__が使用できます。
        rule :
            Email#email : メールアドレス
            +MyRule::Oppai#name : ぼいん
# この配下は考え中段階
        missing :
            default : 値が入力されていません。
--- rule_message eval
{
    'ja' => {
        'Email#email' => 'メールアドレス',
            '+MyRule::Oppai#name' => 'ぼいん'
    }
}
