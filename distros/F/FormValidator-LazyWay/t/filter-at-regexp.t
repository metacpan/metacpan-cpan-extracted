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

plan tests => 1 * blocks;

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $fv = FormValidator::LazyWay->new( config => $block->config );
    my $res = $fv->check( $cgi , {
        required => [qw/birth_day/],
    });

    is($res->valid->{birth_day}, $block->expected);
}

__END__
=== noraml
--- config yaml
filters:
  - Unify
rules:
  - DateTime
setting:
  regex_map:
    '_day$':
      rule:
        - DateTime#date
      filter:
        - Unify#hyphen
  strict:
    hoge_day:
      rule:
        - DateTime#date
      filter:
        - Unify#hyphen
lang: ja
labels:
  ja:
    birth_day: 誕生日
--- param eval
{ birth_day => '2009ー09ー11' }
--- expected chomp
2009-09-11
=== wrong
--- config yaml
filters:
  - Unify
rules:
  - DateTime
setting:
  regex_map:
    '_day$':
      rule:
        - DateTime#date
      filter:
        - Unify#hyphen
  strict:
    hoge_day:
      rule:
        - DateTime#date
      filter:
        - Unify#hyphen
lang: ja
labels:
  ja:
    birth_day: 誕生日
--- param eval
{ birth_day => '' }
--- expected eval
undef


