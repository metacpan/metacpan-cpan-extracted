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

plan tests => 9 * blocks;

my $conf_file = File::Spec->catfile( $FindBin::Bin, 'conf/regex_map.yml' );
my $config = LoadFile($conf_file);
my $fv = FormValidator::LazyWay->new( config => $config );

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $res = $fv->check( $cgi , {
        required => [qw/user_id category_id/],
    });
    is_deeply($res->valid , $block->valid ) ;
    is_deeply($res->missing , $block->missing ) ;
    is_deeply($res->unknown , $block->unknown ) ;
    is_deeply($res->invalid , $block->invalid ) ;
    is_deeply($res->error_message , $block->error_message ) ;
    is( $res->has_missing , $block->has_missing );
    is( $res->has_invalid , $block->has_invalid );
    is( $res->has_error ,  $block->has_error );
    is( $res->success , $block->success );

}

__END__
=== noraml
--- has_missing chomp
0
--- has_invalid chomp
0
--- has_error chomp
0
--- success chomp
1
--- param eval
 { user_id => 31 , category_id => 20 }
--- valid eval
 { user_id => 31 , category_id => 20 }
--- missing eval
[]
--- error_message eval
{}
--- invalid eval
{}
--- unknown eval
[]
=== missing error
--- has_missing chomp
1
--- has_invalid chomp
0
--- has_error chomp
1
--- success chomp
0
--- param eval
 { user_id => 31 }
--- valid eval
 { user_id => 31 }
--- missing eval
[qw/category_id/]
--- error_message eval
{
    category_id => 'カテゴリーIDが空欄です。',
}
--- invalid eval
{ }
--- unknown eval
[]
=== invald error
--- has_missing chomp
0
--- has_invalid chomp
1
--- has_error chomp
1
--- success chomp
0
--- param eval
 { user_id => 31 , category_id => 'a' , hoge_id => 3 }
--- valid eval
 { user_id => 31  }
--- missing eval
[]
--- error_message eval
{
    category_id => 'カテゴリーIDには、正数が使用できます。',
}
--- invalid eval
{
    category_id => {
        'Number#uint' => 1,
    }
}
--- unknown eval
['hoge_id']
