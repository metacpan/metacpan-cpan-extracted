use Test;

INIT {
    require Module::Compile;
    unless (Module::Compile->can('pmc_use_means_no')) {
        print "1..0\n";
        exit;
    }
}

plan tests => 4;

no t::TestFilterSimple3;

ok "No semicolons needed"
ok "Indeed nothing is needed"

use t::TestFilterSimple3;

ok "Semicolons are needed now";
ok "Really, I mean it";
