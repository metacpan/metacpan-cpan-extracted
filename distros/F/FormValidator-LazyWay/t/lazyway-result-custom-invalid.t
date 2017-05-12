use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use CGI;
use FormValidator::LazyWay;
use MyTestBase;

plan tests => 3 * blocks;

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    my $result = $fv->check( $cgi, $block->check );
    $result->custom_invalid($block->key, $block->message);

    is( $result->has_error, $block->has_error);
    is( $result->custom_invalid->{$block->key}, $block->message );
    is_deeply( $result->error_message, $block->error_message );
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
--- key chomp
login
--- message chomp
ログインに失敗しました。
--- error_message yaml
login: ログインに失敗しました。
--- has_error chomp
1

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
username: 小松大輔
password: p4ssw0rd
--- check yaml
required:
  - username
  - password
--- key chomp
login
--- message chomp
ログインに失敗しました。
--- error_message yaml
login: ログインに失敗しました。
username: ユーザネームには、英数字と記号、空白が使用できます。
--- has_error chomp
1
