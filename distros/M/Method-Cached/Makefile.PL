use inc::Module::Install;

perl_version_from 'lib/Method/Cached.pm';

name 'Method-Cached';

all_from 'lib/Method/Cached.pm';

my %requires = (
    'Cache::FastMmap'       => 1.28,
    'Digest::SHA'           => 5.47,
    'JSON::XS'              => 2.2222,
    'MIME::Base64'          => 3.07,
    'Storable'              => 2.18,
    'Sub::Attribute'        => 0.02,
    'UNIVERSAL::require'    => 0.11,
);

while (my ($key, $val) = each %requires) {
    requires $key => $val;
}

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
