use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use Data::Dumper;
use FormValidator::LazyWay::Message;
use FormValidator::LazyWay::Rule;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $rule = FormValidator::LazyWay::Rule->new( config => $block->config );
    my $message = FormValidator::LazyWay::Message->new( config => $block->config , rule => $rule );
    is_deeply( $message->rule_message , $block->rule_message) ;
}

__END__
=== normal
--- config yaml
rules :
    - Email
    - +MyRule::Oppai
    - String
setting :
    strict :
        email :
            rule :
                - Email#email
                - String#length :
                    max : 30
                    min : 4
        oppai : 
            rule :
                - +MyRule::Oppai#name
    loose  :
langs :
    - ja
lang  : ja
labels : 
    ja :
        subject : 題名
        amount  : 料金
        use_id  : ユーザー番号
messages :
    ja :
        rule_message : __field__には__rule__が使用できます。
        rule :
            Email#email : メールアドレス
            +MyRule::Oppai#name : ぼいん
--- rule_message eval
{
'ja' => {
    'strict' => {
        'email' => {
            'String#length' => '4文字以上30文字以下',
                'Email#email' => 'メールアドレス'
        },
            'oppai' => {
                '+MyRule::Oppai#name' => 'ぼいん'
            }
    }
}
}
=== alias
--- config yaml
rules :
    - email=Email
    - oppai=+MyRule::Oppai
setting :
    strict :
        email :
            rule :
                - email#email
        oppai : 
            rule :
                - oppai#name
    loose  :
langs :
    - ja
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
        invalid : __field__には__rule__が使用できます。
        missing : 値が入力されていません。
        rule :
            email#email : メールアドレス
            oppai#name : ぼいん
# この配下は考え中段階
--- rule_message eval
{
'ja' => {
    'strict' => {
        'email' => {
            'Email#email' => 'メールアドレス'
        },
        'oppai' => {
                '+MyRule::Oppai#name' => 'ぼいん'
        }
    }
}
}
