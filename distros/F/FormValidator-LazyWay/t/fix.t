use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use Data::Dumper;
use FormValidator::LazyWay::Fix;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $filter = FormValidator::LazyWay::Fix->new( config => $block->config );

    is( $filter->setting->{strict}{hoge}[0]{label}  , $block->setting );
}

__END__
=== normal
--- config yaml
fixes:
  - DateTime
setting :
  strict :
    hoge :
      fix :
        - DateTime#format:
            - '%Y-%m-%d %H:%M:%S'
--- setting chomp
DateTime#format

