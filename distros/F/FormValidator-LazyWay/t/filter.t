use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use Data::Dumper;
use FormValidator::LazyWay::Filter;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $filter = FormValidator::LazyWay::Filter->new( config => $block->config );

    is( $filter->setting->{strict}{hoge}[0]{label}  , $block->setting );
    
}

__END__
=== normal
--- config yaml
filters :
    - Encode
setting :
    strict :
        hoge :
            filter :
                - Encode::decode
--- setting chomp
Encode::decode
