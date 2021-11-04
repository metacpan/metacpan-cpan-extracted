#!/usr/bin/env perl 

use lib qw(t/lib);

use FindApp::Test::Setup;

my $Class = __TEST_PACKAGE__;

#note "test package is $Class";
#require_ok $Class;
#diag "need to fix import() sensitivity in $Class";

$DB::single = 1;
run_tests();
$DB::single = 1;

sub load_tests {
    require_ok $Class;
    {
        local $TODO = "need to fix import() sensitivity in $Class";
        use_ok $Class;
    }
    note "done loading tests";
}

__END__
