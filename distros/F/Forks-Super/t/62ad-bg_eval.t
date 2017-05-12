use Forks::Super ':test';
use Test::More tests => 25;
use strict;
use warnings;

ok(!defined $Forks::Super::LAST_JOB, 
   "$$\\\$Forks::Super::LAST_JOB not set");
ok(!defined $Forks::Super::LAST_JOB_ID, 
   "\$Forks::Super::LAST_JOB_ID not set");

$Forks::Super::Config::CONFIG{"YAML"} = 0;

SKIP: {
    if (!Forks::Super::Config::CONFIG_module("Data::Dumper")) {
	skip "Data::Dumper not available, skipping bg_eval tests", 23;
    }

    require "./t/62a-bg_eval.tt";
}
