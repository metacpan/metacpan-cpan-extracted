use Test::Base;
use FormValidator::LazyWay;
use FindBin;
use File::Spec;
use CGI;
use YAML::Syck;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use Data::Dumper;
use Encode;
use utf8;

no warnings 'once';
local $YAML::Syck::ImplicitUnicode = 1;
use warnings;

plan tests => 1 * blocks;

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $config = Load($block->yaml);
    my $fv = FormValidator::LazyWay->new( config => $config );

    my $res = $fv->check( $cgi , {
        required => [qw/phone/],
    });

    # valid->{phone} は Unicode であることが期待される。
    my $expected = decode('utf8', $block->expected);
    is($res->valid->{phone}, $expected );
}

__END__
=== sccess1
--- yaml
filters:
  - Unify
rules:
  - Object
setting:
  strict:
    phone:
      rule:
        - Object#true 
      filter:
        - Unify#hyphen
lang : ja
labels :
    ja :
        phone : 電話番号
--- param eval
 { phone => '012ー3456ー7890' }
--- expected chomp
012-3456-7890
