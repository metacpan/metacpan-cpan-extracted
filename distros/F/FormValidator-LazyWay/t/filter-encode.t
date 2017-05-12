use Test::Base;
use FormValidator::LazyWay;
use FindBin;
use File::Spec;
use CGI;
use YAML::Syck;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use Data::Dumper;
use Encode;

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
        required => [qw/name/],
    });

    # valid->{name} は Unicode であることが期待される。
    my $expected = decode('utf8', $block->expected);
    is($res->valid->{name}, $expected );
}

__END__
=== sccess1
--- yaml
filters :
  - Encode
rules :
  - Object
setting :
  strict :
    name :
      rule :
        - Object#true 
      filter :
        - Encode#decode:
            encoding: utf8
lang : ja
labels :
    ja :
        name : 名前
--- param eval
 { name => 'てらにしともひろ' }
--- expected chomp
てらにしともひろ

=== sccess2 default
--- yaml
filters :
  - Encode
rules :
  - Object
setting :
  strict :
    name :
      rule :
        - Object#true 
      filter :
        - Encode#decode:
lang : ja
labels :
    ja :
        name : 名前
--- param eval
 { name => 'てらにしともひろ' }
--- expected chomp
てらにしともひろ

