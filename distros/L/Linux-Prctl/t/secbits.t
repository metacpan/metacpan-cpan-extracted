use strict;
use warnings;

use Test::More tests => 13;
use Linux::Prctl qw(:constants :securebits);

SKIP: {
    skip "set_securebits not available", 13 unless Linux::Prctl->can('set_securebits');
    skip "This test only makes sense when run as root", 13 unless $< == 0;
    is(defined(tied %Linux::Prctl::securebits), 1, "Have a tied securebits object");
    for(qw(keep_caps noroot no_setuid_fixup)) {
        is($Linux::Prctl::securebits{$_}, 0, "Checking whether $_ is 0");
        $Linux::Prctl::securebits{$_} = 1;
        is($Linux::Prctl::securebits{$_}, 1, "Checking whether $_ is 1");
        $Linux::Prctl::securebits{$_} = 0;
        is($Linux::Prctl::securebits{$_}, 0, "Checking whether $_ is 0");
        $Linux::Prctl::securebits{$_ . '_locked'} = 1;
        $Linux::Prctl::securebits{$_ . '_locked'} = 0;
        is($Linux::Prctl::securebits{$_ . '_locked'}, 1, "Checking whether ${_}_locked is 1");
    }
}
