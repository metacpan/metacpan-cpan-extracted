use inc::Module::Install;

name 'IPIP';
all_from 'lib/IPIP.pm';
auto_set_repository;

if (! cc_available()) {
    warn "no compiler available";
    exit 1;
}

test_requires 'Test::More', 0.84;
test_requires 'Test::Requires';
use_ppport;
cc_warnings;
cc_src_paths 'xs';

WriteAll;