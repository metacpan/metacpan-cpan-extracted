#!perl
use strict;
use Test::More tests => 7;
use ETLp;
use FindBin qw($Bin);
use lib ("$Bin/lib", "$Bin/t/lib");
use ETLp::Test::Singleton;
use Try::Tiny;
use Data::Dumper;
use File::Path qw/rmtree/;

my $etlp;

mkdir "$Bin/tests/log" unless -d "$Bin/tests/log";

$etlp = ETLp->new(
    config_directory => "$Bin/tests/conf",
    app_config_file  => "basic.conf",
    env_config_file  => "env_test.conf",
    section          => "test_one",
    log_dir          => "$Bin/tests/log",
);

isa_ok($etlp, 'ETLp');

my $config_contents = {
    'colours' => {
        'second' => 'blue',
        'fav'    => 'red'
    },
    'pass'         => 'blogg',
    'user'         => 'joe',
    'name'         => 'one',
    'type'         => 'serial',
};


my $plugins = [qw/ETLp::PluginTest::Test2 ETLp::PluginTest::Test/];
my $plugin_method_count = 0;

is_deeply($etlp->config, $config_contents, 'Job defined');
is_deeply([(reverse sort($etlp->plugins))[0,1]], $plugins, 'Plugins Defined');

foreach my $plugin ($etlp->plugins) {
    if ($plugin->can('test')) {
        $plugin_method_count++;
    }
}

is ($plugin_method_count, 2, "Two plugins can handle test method");

my $etlp2;

try {
    $etlp2 = ETLp->new(
        config_directory => "$Bin/tests/conf",
        app_config_file  => "basic.conf",
        env_config_file  => "env_test.conf",
        section          => "test_two",
        log_dir          => "$Bin/tests/log",
    );
}
catch {
    like($_, qr/No type for test_two/, "No type defined");
};

try {
    $etlp2 = ETLp->new(
        config_directory => "$Bin/tests/conf",
        app_config_file  => "basic.conf",
        env_config_file  => "env_test.conf",
        section          => "does_not_exist",
        log_dir          => "$Bin/tests/log",
    );
}
catch {
    like($_, qr/No section does_not_exist in.*basic.conf/,
        "No section defined");
};

try {
    $etlp2 = ETLp->new(
        config_directory => "$Bin/tests/conf",
        app_config_file  => "no_such_config.conf",
        env_config_file  => "env_test.conf",
        section          => "does_not_exist",
        log_dir          => "$Bin/tests/log",
    );
}
catch {
    like($_, qr/No such application configuration file.*no_such_config.conf/,
        "No such config file");
};

rmtree "$Bin/tests/log";
