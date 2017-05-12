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
    is_deeply( $message->labels , $block->labels ) ;
}

__END__
=== alias
--- config yaml
rules :
    - email=Email
setting :
    strict :
        email :
            rule :
                - email#email
    loose  :
langs :
    - ja
lang  : ja
labels : 
    ja :
        subject : 題名
        amount  : 料金
        user_id : ユーザー番号
# この配下は考え中段階
--- labels eval
{
'ja' => {
    subject => '題名',
    amount  => '料金',
    user_id => 'ユーザー番号',
    },

}
