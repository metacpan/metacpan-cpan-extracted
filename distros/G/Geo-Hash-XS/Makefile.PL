use inc::Module::Install;
use File::Spec;

name 'Geo-Hash-XS';
all_from 'lib/Geo/Hash/XS.pm';

test_requires 'Test::More' => '0.94';
use_xshelper;
use_ppport;
cc_warnings;
cc_src_paths 'xs';

author_tests 'xt';

WriteAll;
