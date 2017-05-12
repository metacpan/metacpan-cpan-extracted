package t::lib::Harness;

use strict;
use warnings;
use Exporter;

use ExtUtils::Command::MM ();
use DB::DbgrXS;

*import = \&Exporter::import;

our @EXPORT = qw(test_harness);

sub test_harness {
    my $pure_perl = shift;

    $ENV{DBGP_PURE_PERL} = $pure_perl eq 'perl' ? 1 : 0;
    $ENV{DBGP_XS_ONLY}   = !$ENV{DBGP_PURE_PERL} ? 1 : 0;
    if (!$ENV{DBGP_PURE_PERL} && !DB::DbgrXS::HAS_XS()) {
        print <<EOT;

XS version not built, skipping XS tests

EOT

        return 0;
    } else {
        print <<EOT;

Running tests for $pure_perl version

EOT
        return ExtUtils::Command::MM::test_harness(@_);
    }
}

1;
