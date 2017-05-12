use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $storage = $block->storage;
    my $error_messages = $block->error_messages;
    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    $fv->_set_error_message_for_display( $storage , $error_messages , $block->lang );

    is_deeply ( $storage->{error_message}, $block->result );
}

__END__
=== normal
--- config yaml
rules :
    - Email
    - String
setting :
    strict :
        email :
            rule :
                - String#length :
                    max  : 3
                    min  : 1
                - Email#email
lang  : ja
labels :
    ja :
        email : Eメール
        hoge : ほげ
--- storage eval
{
    valid => {
        email => 'h',
    },
    missing => [ 'hoge' ],
}
--- error_messages eval
{
    email => [
        '1文字以上3文字以下',
        'メールアドレスの書式',

    ],
}
--- lang chomp
ja
--- result eval
{
    email => 'Eメールには、1文字以上3文字以下,メールアドレスの書式が使用できます。',
    hoge => 'ほげが空欄です。',
}
