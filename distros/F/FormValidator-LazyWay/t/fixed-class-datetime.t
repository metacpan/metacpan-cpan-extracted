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

plan tests => 6 * blocks;

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $config = Load($block->yaml);
    my $fv = FormValidator::LazyWay->new( config => $config );

    my $res = $fv->check( $cgi , {
        required => [qw/username birthday password/],
    });

    is_deeply($res->valid , $block->valid ) ;
    is_deeply($res->missing , $block->missing ) ;
    is_deeply($res->unknown , $block->unknown ) ;
    is_deeply($res->invalid , $block->invalid ) ;
    is_deeply($res->error_message , $block->error_message ) ;
    is( ref( $res->valid->{birthday} ), $block->fixed_class );
}

__END__
=== sccess1
--- yaml
rules :
  - Email
  - String
  - Object
fixes :
  - DateTime
setting :
  strict :
    username :
      rule :
        - String#length :
            min : 4
            max : 12
        - String#ascii
    birthday:
      rule :
        - Object#true
      fix:
        - DateTime#format:
            pattern: '%Y-%m-%d %H:%M:%S'
    password :
      rule :
        - String#length :
            min : 4
            max : 12
        - String#ascii
lang : ja
labels :
    ja :
        username : ユーザーネーム
        birthday : 誕生日
        password : パスワード
--- param eval
 { username => 'vkgtaro', birthday => '1977-11-06 00:00:00', password => 'oppai' }
--- valid eval
 { username => 'vkgtaro', birthday => '1977-11-06T00:00:00', password => 'oppai' }
--- missing eval
[]
--- error_message eval
{}
--- invalid eval
{}
--- unknown eval
[]
--- fixed_class chomp
DateTime
=== success2
--- yaml
rules :
  - Email
  - String
  - Object
fixes :
  - DateTime
setting :
  strict :
    username :
      rule :
        - String#length :
            min : 4
            max : 12
        - String#ascii
    birthday:
      rule :
        - Object#true
      fix:
        - DateTime#format:
            pattern: '%Y-%m-%d'
    password :
      rule :
        - String#length :
            min : 4
            max : 12
        - String#ascii
lang : ja
labels :
    ja :
        username : ユーザーネーム
        birthday : 誕生日
        password : パスワード
--- param eval
 { username => 'vkgtaro', birthday => '1977-11-06', password => 'oppai' }
--- valid eval
 { username => 'vkgtaro', birthday => '1977-11-06T00:00:00', password => 'oppai' }
--- missing eval
[]
--- error_message eval
{}
--- invalid eval
{}
--- unknown eval
[]
--- fixed_class chomp
DateTime

=== wrong1
--- yaml
rules :
  - Email
  - String
  - Object
fixes :
  - DateTime
setting :
  strict :
    username :
      rule :
        - String#length :
            min : 4
            max : 12
        - String#ascii
    birthday:
      rule :
        - Object#true
      fix:
        - DateTime#format:
            pattern: '%Y-%m-%d'
    password :
      rule :
        - String#length :
            min : 4
            max : 12
        - String#ascii
lang : ja
labels :
    ja :
        username : ユーザーネーム
        birthday : 誕生日
        password : パスワード
--- param eval
 { username => 'vkgtaro', birthday => undef, password => 'oppai' }
--- valid eval
 { username => 'vkgtaro', password => 'oppai' }
--- missing eval
['birthday']
--- error_message eval
{ birthday => '誕生日が空欄です。' }
--- invalid eval
{}
--- unknown eval
[]
--- fixed_class chomp

