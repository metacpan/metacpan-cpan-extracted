#!perl
use strict;
use Test::More tests => 3;
use ETLp;
use FindBin qw($Bin);
use lib "$Bin/lib";
use ETLp::Test::Singleton;
use File::Path qw/rmtree/;

mkdir "$Bin/tests/log" unless -d "$Bin/tests/log";

my $etlp = ETLp->new(
    config_directory => "$Bin/tests/conf",
    app_config_file  => "basic.conf",
    env_config_file  => "env_test.conf",
    section          => "test_one",
    log_dir          => "$Bin/tests/log",
);

my $etlps = ETLp::Test::Singleton->new;
isa_ok($etlps->dbh,    'DBI::db');
isa_ok($etlps->logger, 'Log::Log4perl::Logger');
isa_ok($etlps->schema, 'ETLp::Schema');

rmtree "$Bin/tests/log";