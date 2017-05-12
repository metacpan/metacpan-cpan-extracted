use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use CGI;
use FormValidator::LazyWay;
use MyTestBase;

plan tests => 2 * blocks;

run {
  my $block = shift;

  my $cgi = new CGI( $block->param );

  my $fv = FormValidator::LazyWay->new({ config => $block->config });
  my $result = $fv->check( $cgi, $block->check );

  is( $result->has_error, $block->has_error);
  is_deeply( $result->invalid, $block->invalid );
};

__END__
=== regex_map_multi
--- param yaml
name_kana: hogehoge
--- config yaml
rules:
  - String
  - Japanese
setting:
  regex_map:
    '^name':
      rule:
        - String#length:
            max: 5
            min: 1
    _kana$:
      rule:
        - Japanese#katakana
--- check yaml
required:
  - name_kana
--- has_error chomp
1
--- invalid yaml
name_kana:
  String#length: 1
  Japanese#katakana: 1

=== regex_map_multi
--- param yaml
name_kana: hoge
--- config yaml
rules:
  - String
  - Japanese
setting:
  regex_map:
    '^name':
      rule:
        - String#length:
            max: 5
            min: 1
    _kana$:
      rule:
        - Japanese#katakana
--- check yaml
required:
  - name_kana
--- has_error chomp
1
--- invalid yaml
name_kana:
  Japanese#katakana: 1

=== regex_map_multi
--- param yaml
name_kana: ホゲホゲホゲ
--- config yaml
rules:
  - String
  - Japanese
setting:
  regex_map:
    '^name':
      rule:
        - String#length:
            max: 5
            min: 1
    _kana$:
      rule:
        - Japanese#katakana
--- check yaml
required:
  - name_kana
--- has_error chomp
1
--- invalid yaml
name_kana:
  String#length: 1

=== regex_map_multi
--- param yaml
name_kana: ホゲホゲ
--- config yaml
rules:
  - String
  - Japanese
setting:
  regex_map:
    '^name':
      rule:
        - String#length:
            max: 5
            min: 1
    _kana$:
      rule:
        - Japanese#katakana
--- check yaml
required:
  - name_kana
--- has_error chomp
0
--- invalid eval
{}

