# t/license/mpl.t
use strict;
local $^W = 1;
use Test::More tests => 17;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::Licenses::Local' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
        licensetest
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (17 - 11) if $@;
    use warnings;

    my $caller = 'ExtUtils::ModuleMaker::PBP';
    licensetest($caller,
        'mpl',
        qr/Mozilla Public License 1\.1 \(MPL 1\.1\)/s
    );

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

