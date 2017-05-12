use Test::Effects;
use 5.014;

plan tests => 2;

use lib 'tlib';

subtest 'fail --> extra handler used', sub {
    use ExtrasModule errors => 'squawk';

    effects_ok { ExtrasModule::dont_succeed() }
               VERBOSE {
                    return => 'squawk!',
                    warn   => qr{\A \QSquawked as expected\E }xms,
                }
               => 'Extra handler installed and called';
};


subtest 'fail --> extra handler unused', sub {
    use ExtrasModule;

    eval { ExtrasModule::dont_succeed() };
    like $@, qr{\A \QDidn't succeed\E }xms => 'Extra handler installed and called';
#    effects_ok { ExtrasModule::dont_succeed() }
#               VERBOSE {
#                    die   => qr{\A \QDidn't succeed\E }xms,
#                }
#               => 'Extra handler installed and called';
};

