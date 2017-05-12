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

plan tests => 2 * blocks;

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $config = Load($block->yaml);
    my $fv = FormValidator::LazyWay->new( config => $config );

    my $res = $fv->check( $cgi , {
        required => [qw/username birthday password/],
        use_fixed_method => { birthday => 'birthday_obj' },
    });

    is_deeply($res->fixed , $block->fixed ) ;
    is_deeply($res->valid , $block->valid ) ;
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
--- fixed eval
 { birthday_obj => '1977-11-06T00:00:00' }
--- valid eval
 { username => 'vkgtaro', birthday => '1977-11-06 00:00:00', password => 'oppai' }
--- fixed_class chomp
DateTime
