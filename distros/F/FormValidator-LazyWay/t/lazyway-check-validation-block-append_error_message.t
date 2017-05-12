use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay;
use MyTestBase;

plan tests => 2 * blocks;

run {
    my $block = shift;
    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    my $storage = {};
    my $error_messages = {};
    $fv->_append_error_message( $block->lang,  $block->level , $block->field , $storage , $block->label , $error_messages );

    is_deeply( $storage , $block->storage_result ); 
    is( $error_messages->{email}[0] , '1文字以上3文字以下' );
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
                - String#length :
                    min : 1
                    max : 3
                - Email#email
lang  : ja
messages :
    ja :
        rule :
            Email#email : メールアドレス
            +MyRule::Oppai##name : ぼいん
--- level chomp
strict
--- label chomp
String#length
--- field chomp
email
--- lang chomp
ja
--- storage_result eval
{
    invalid => {
        email => {
            'String#length' => 1
            },
        },
}
