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

    my $res = $fv->check( $cgi, { required => [qw/username uri/] } );

    is_deeply($res->valid , $block->valid ) ;
    is_deeply($res->missing , $block->missing ) ;
    is_deeply($res->unknown , $block->unknown ) ;
    is_deeply($res->invalid , $block->invalid ) ;
    is_deeply($res->error_message , $block->error_message ) ;
    is( ref( $res->valid->{uri} ), $block->fixed_class );
}

__END__
=== sccess by URI
--- yaml
rules :
  - String
  - Object
fixes :
  - URI
setting :
  strict :
    username :
      rule :
        - String#length :
            min : 4
            max : 12
        - String#ascii 
    uri:
      rule :
        - Object#true 
      fix:
        - URI#format:
lang : ja
labels :
    ja :
        username : ユーザーネーム
        uri : blog のアドレス
--- check_param eval
--- param eval
 { username => 'vkgtaro', uri => 'http://vkgtaro.jp' }
--- valid eval
 { username => 'vkgtaro', uri => 'http://vkgtaro.jp' }
--- missing eval
[]
--- error_message eval
{}
--- invalid eval
{}
--- unknown eval 
[]
--- fixed_class chomp
URI::http
