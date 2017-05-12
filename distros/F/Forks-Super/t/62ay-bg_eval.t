use Forks::Super ':test';
use Test::More tests => 25;
use strict;
use warnings;

ok(!defined $Forks::Super::LAST_JOB, 
   "$$\\\$Forks::Super::LAST_JOB not set");
ok(!defined $Forks::Super::LAST_JOB_ID, 
   "\$Forks::Super::LAST_JOB_ID not set");

delete $Forks::Super::Config::CONFIG{"YAML"};

SKIP: {
    if ($ENV{NO_YAML} || !Forks::Super::Config::CONFIG_module("YAML")) {
	skip "YAML not available, skipping bg_eval tests", 23;
    }

    Forks::Super::Debug::no_Carp_Always();

    require "./t/62a-bg_eval.tt";
}

