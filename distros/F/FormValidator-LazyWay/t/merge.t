use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use CGI;
use Data::Dumper;
use Encode;
use FormValidator::LazyWay;
use MyTestBase;
use YAML::Syck;

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
        required => [qw/date/],
    });

    is($res->valid->{date}, $block->expected );
}

__END__
=== ok
--- yaml
rules:
  - DateTime
setting:
  merge:
    date:
      format: "%04d-%02d-%02d"
      fields:
        - year
        - month
        - day
  strict:
    date:
      rule:
        - DateTime#date
lang: ja
labels:
  ja:
    date: 日付
--- param yaml
year: 1977
month: 11
day: 6
--- expected chomp
1977-11-06
