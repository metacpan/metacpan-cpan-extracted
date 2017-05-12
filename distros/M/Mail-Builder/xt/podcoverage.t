use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};
plan tests => 4;

pod_coverage_ok( "Mail::Builder",{  also_private => [qr/^(charset)$/] }  );
pod_coverage_ok( "Mail::Builder::Attachment");
pod_coverage_ok( "Mail::Builder::Image");
pod_coverage_ok( "Mail::Builder::Address",{  also_private => [qr/^(empty|address)$/] }  );
#all_pod_coverage_ok();

