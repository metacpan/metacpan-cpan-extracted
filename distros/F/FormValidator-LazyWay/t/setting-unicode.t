use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
# no use utf8 pragma. this test is for 'bytes'.

use CGI;
use Data::Dumper;
use Encode;
use FormValidator::LazyWay;
use MyTestBase;
use YAML::Syck;

plan tests => 1 * blocks;

SKIP:
{
    eval { require Data::Visitor::Encode; };
    skip "Data::Visitor::Encode is not installed" ,1 * blocks ,if $@;

my $dve = Data::Visitor::Encode->new();

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $fv = FormValidator::LazyWay->new( config => $block->config, unicode => $block->unicode );

    # 期待される結果は flagged UTF-8
    my $expected = $dve->decode('utf8', $block->expected);

    is_deeply($fv->config, $expected );
}

}
__END__
=== sccess1
--- config yaml_bytes
rules:
  - Object
setting:
  strict:
    name:
      rule:
        - Object#true 
    kana:
      rule:
        - Object#true 
lang: ja
labels:
  ja:
    name: 名前
    kana: カナ
--- unicode chomp
1
--- expected eval
{   'messages' => { 'ja' => { 'rule' => {} } },
    'lang'     => 'ja',
    'setting'  => {
        'strict' => {
            'name' => { 'rule' => [ 'Object#true' ] },
            'kana' => { 'rule' => [ 'Object#true' ] }
        }
    },
    'labels' => {
        'ja' => {
            'name' => '名前',
            'kana' => 'カナ'
        }
    },
    'rules' => [ 'Object' ]
}

=== config sccess2
--- config yaml_bytes
unicode: 1
rules:
  - Object
setting:
  strict:
    name:
      rule:
        - Object#true 
    kana:
      rule:
        - Object#true 
lang: ja
labels:
  ja:
    name: 名前
    kana: カナ
--- unicode chomp

--- expected eval
{   'unicode'  => 1,
    'messages' => { 'ja' => { 'rule' => {} } },
    'lang'     => 'ja',
    'setting'  => {
        'strict' => {
            'name' => { 'rule' => [ 'Object#true' ] },
            'kana' => { 'rule' => [ 'Object#true' ] }
        }
    },
    'labels' => {
        'ja' => {
            'name' => '名前',
            'kana' => 'カナ'
        }
    },
    'rules' => [ 'Object' ]
}

