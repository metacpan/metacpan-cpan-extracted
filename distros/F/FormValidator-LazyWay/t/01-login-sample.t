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

my $conf_file = File::Spec->catfile( $FindBin::Bin, 'conf/login-sample.yml' );
my $config = LoadFile($conf_file);
my $fv = FormValidator::LazyWay->new( config => $config );

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $res = $fv->check( $cgi , {
        required => [qw/email password/],
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
 { email => 'tomohiro.teranishi@gmail.com' , password => 'oppai' }
--- valid eval
 { email => 'tomohiro.teranishi@gmail.com' , password => 'oppai' }
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
 { email => 'tomohiro' , hoge => 'hoge', }
--- valid eval
{}
--- missing eval
[qw/password/]
--- error_message eval
{
    password => 'パスワードが空欄です。',
    email => 'メールアドレスには、メールアドレスの書式が使用できます。',
}
--- invalid eval
{
    'email' => {
        'Email#email' => 1,
    },
}
--- unknown eval
['hoge']
=== wrong2
--- param eval
 { email => 'tomohiro.teranishi@gmail.com' , password => 'ほげ'  }
--- valid eval
{
    email => 'tomohiro.teranishi@gmail.com' ,
}
--- missing eval
[]
--- error_message eval
{
    password => 'パスワードには、4文字以上12文字以下,英数字と記号、空白が使用できます。',
}
--- invalid eval
{
    password => {
        'String#length' => 1,
        'String#ascii' => 1,
    }
}
--- unknown eval
[]
