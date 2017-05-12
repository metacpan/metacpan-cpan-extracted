#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({also_private => [qr!add_to_jquery|closeNodes|debug|get_css|get_jquery_code|highlightUnderline|packages_needed|produce|id|splitRepeat!]});
