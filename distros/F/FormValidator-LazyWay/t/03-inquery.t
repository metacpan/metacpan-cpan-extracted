use Test::Base;
use FormValidator::LazyWay;
use FindBin;
use File::Spec;
use CGI;
use YAML::Syck;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use Data::Dumper;
use utf8;

no warnings 'once';
local $YAML::Syck::ImplicitUnicode = 1;
use warnings;

plan tests => 5 * blocks;

my $conf_file = File::Spec->catfile( $FindBin::Bin, 'conf/inquery-sample.yml' );
my $config = LoadFile($conf_file);
my $fv = FormValidator::LazyWay->new( config => $config );

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $res = $fv->check( $cgi , {
        required => [qw/email message/],
        optional => [qw/user_key/],
    });

    is_deeply($res->valid , $block->valid ) ;
    is_deeply($res->missing , $block->missing ) ;
    is_deeply($res->unknown , $block->unknown ) ;
    is_deeply($res->invalid , $block->invalid ) ;
    is_deeply($res->error_message , $block->error_message ) ;

}

__END__
=== noraml
--- param eval
{ email => 'tomohiro.teranishi@gmail.com' ,  message => "hogehoge" }
--- valid eval
{ email => 'tomohiro.teranishi@gmail.com' , message => "hogehoge" }
--- missing eval
[]
--- error_message eval
{}
--- invalid eval
{}
--- unknown eval
[]
=== wrong1
--- param eval
{ email => 'tomohiro.teranishi@gmail.com' , user_key => 'tomyhero' , message => 'hoge hoge' }
--- valid eval
{ email => 'tomohiro.teranishi@gmail.com' , user_key => 'tomyhero' , message => 'hoge hoge' }
--- missing eval
[]
--- error_message eval
{}
--- invalid eval
{}
--- unknown eval
[]
=== wrong2
--- param eval
 { email => 'email' }
--- valid eval
{}
--- missing eval
[qw/message/]
--- error_message eval
{
    'email' => 'メールアドレスには、メールアドレスの書式が使用できます。',
    'message' => 'お問い合わせ内容が空欄です。'
}
--- invalid eval
{
    'email' => {
        'Email#email' => 1
    }
}
--- unknown eval
[]
=== wrong3
--- param eval
{   email => 'email',
    message => 'wahaha',
    user_key => 'ほげらららららら'
}
--- valid eval
{
    message => 'wahaha',
}
--- missing eval
[]
--- error_message eval
{
    'email' => 'メールアドレスには、メールアドレスの書式が使用できます。',
    'user_key' => 'ユーザIDには、英数字と記号、空白が使用できます。',
}
--- invalid eval
{
    'email' => {
        'Email#email' => 1
    },
    'user_key' => {
        'String#ascii' => 1,
    }
}
--- unknown eval
[]
