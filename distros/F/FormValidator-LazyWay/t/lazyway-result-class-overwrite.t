use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use lib 't/lib';
use utf8;

use CGI;
use FormValidator::LazyWay;
use MyTestBase;

plan tests => 2 * blocks;

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;
    {
        my $fv = FormValidator::LazyWay->new( { config => $block->config } );
        my $result = $fv->check( $cgi, $block->check );
        is(ref $result , 'FormValidator::LazyWay::Result');
    }

    {
        my $fv = FormValidator::LazyWay->new( { config => $block->config , result_class => 'MyResult' } );
        my $result = $fv->check( $cgi, $block->check );
        is(ref $result , 'MyResult');
    }
}

__END__
=== normal
--- config yaml
rules:
  - String
setting:
  strict:
    username:
      rule:
        - String#length:
            min: 4
            max: 12
        - String#ascii
    password:
      rule:
        - String#length:
            min: 4
            max: 12
        - String#ascii
lang: ja
labels:
  ja:
    username: ユーザネーム
    password: パスワード
--- param yaml
username: vkgtaro
password: p4ssw0rd
--- check yaml
required:
  - username
  - password
