#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
#use Log::Any::Test;    # should appear before 'use Log::Any'!
#use Log::Any qw($log);

#use lib 't';
#use lib 'integ_t';
#require 'iron_io_integ_tests_common.pl';
use lib 'lib';
use lib '../io-iron/lib';

plan tests => 1;

use App::Cmd::Tester;

use File::Slurp qw();
use IO::Iron::Applications::IronCache;

use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
use Data::Dumper; $Data::Dumper::Maxdepth = 2;

diag("Testing IO::Iron::Applications::IronCache, Perl $], $^X");

my $config_file_name = 'iron_cache.json';
BAIL_OUT("File " . $config_file_name . " not exists! Quitting...") if(!-e $config_file_name);;
my $policies_file_name = 'iron_cache_policies.json';
my $policies_file_content = <<END_OF_CONTENT;
{
    "__comment1":"Use normal regexp. [[:digit:]] = number:0-9, [[:alpha:]] = alphabetic character, [[:alnum:]] = character or number.",
    "__comment2":"Do not use end/begin limitators '^' and '\$'. They are added automatically.",
    "character_set":"ascii",
    "character_group":{
        "[:lim_uchar:]":"ABC",
        "[:low_digit:]":"0123"
    },
    "cache":{
        "name":[
            "cache_01_main",
            "cache_[:alpha:]{1}[:digit:]{2}"
        ],
        "item_key":[
            "item.01_[:digit:]{2}",
            "item.02_[:lim_uchar:]{1,2}"
        ]
    }
}
END_OF_CONTENT

File::Slurp::write_file($policies_file_name, , {binmode => ':utf8'}, $policies_file_content);

# Cache names
my $cache_name_01 = 'cache_A01';
my $cache_name_02 = 'cache_A02';
my $cache_name_03 = 'cache_A03';
# Item keys
my $item_key_01 = 'item.01_01';
my $item_key_02 = 'item.01_02';
my $item_key_03 = 'item.02_A';
my $item_key_04 = 'item.02_BB';
# Item integer values
my $item_value_01 = '15';
my $item_value_02 = '-95';

subtest 'Testing' => sub {
    plan tests => 20;

#    my $test = Test::Cmd->new(workdir => '', prog => 'blib/script/base64');
#ok($test, 'Made Test::Cmd object');
#
#is($test->run(args => 'decode', stdin => 'cGFja2FnZSBBcHA6OkJhc2U2NDs=') => 0, 'Test ran properly');
#is($test->stdout => 'package App::Base64;', 'Execution gave the correct result');

    my @cmd_line_array;
    my $result;

    # This is just to create the three caches.
    @cmd_line_array = ('put', 'item', "$item_key_01",
            '--cache', "$cache_name_01,$cache_name_02,$cache_name_03",
            '--value', '10', '--create-cache',
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    is($result->stdout(), '', 'Print nothing to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # list the three caches.
    @cmd_line_array = ('list', 'caches', 
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    like($result->stdout(), qr/^$cache_name_01$/sx, 'Print cache 01 to stdout.');
    like($result->stdout(), qr/^$cache_name_02$/sx, 'Print cache 01 to stdout.');
    like($result->stdout(), qr/^$cache_name_03$/sx, 'Print cache 01 to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # list the three items with their values.
    @cmd_line_array = ('list', 'items', "$item_key_01",
            '--cache', "$cache_name_01,$cache_name_02,$cache_name_03",
            '--show-value', 
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    like($result->stdout(), qr/^$cache_name_01.*$item_key_01.*10$/sx, 'List item.');
    like($result->stdout(), qr/^$cache_name_02.*$item_key_01.*10$/sx, 'List item.');
    like($result->stdout(), qr/^$cache_name_03.*$item_key_01.*10$/sx, 'List item.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # Get items (only value)
    @cmd_line_array = ('get', 'item', "$item_key_01,$item_key_02",
            '--cache', $cache_name_01,
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    is($result->stdout(), '10\nKey not exists.\n', 'Print item values');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # Increment values (inc one item, create three items.)
    @cmd_line_array = ('increment', 'item', "$item_key_01,$item_key_02",
            '--cache', "$cache_name_01,$cache_name_02",
            '--value', '10',
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    is($result->stdout(), '', 'Print nothing to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # Get four items. Two different values.
    @cmd_line_array = ('get', 'item', "$item_key_01,$item_key_02",
            '--cache', "$cache_name_01,$cache_name_02",
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    #diag(Dumper($result));
    is($result->stdout(), "20\n10\n10\n10\n", 'Stdout has the value.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # Delete one item.
    @cmd_line_array = ('delete', 'item', "$item_key_01",
            '--cache', "$cache_name_01",
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    #diag(Dumper($result));
    is($result->stdout(), '', 'Print nothing to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # Clear cache
    @cmd_line_array = ('clear', 'cache', "$cache_name_01,$cache_name_02",
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    #diag(Dumper($result));
    is($result->stdout(), '', 'Print nothing to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    @cmd_line_array = ('list', 'items', '.*', '--cache', "$cache_name_01",
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    #diag(Dumper($result));
    is($result->stdout(), '', 'Print nothing to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    @cmd_line_array = ('delete', 'cache', "$cache_name_01,$cache_name_02,$cache_name_03",
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    #diag(Dumper($result));
    is($result->stdout(), '', 'Print nothing to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

    # list the three caches.
    @cmd_line_array = ('list', 'caches', 
            '--config', $config_file_name, '--policies', $policies_file_name );
    diag("Command line: " . (join ' ', @cmd_line_array));
    $result = test_app('IO::Iron::Applications::IronCache' => \@cmd_line_array);
    unlike($result->stdout(), qr/^$cache_name_01$/sx, 'Print cache 01 to stdout.');
    unlike($result->stdout(), qr/^$cache_name_02$/sx, 'Print cache 01 to stdout.');
    unlike($result->stdout(), qr/^$cache_name_03$/sx, 'Print cache 01 to stdout.');
    is($result->stderr(), '', 'Print nothing to stderr.');
    is($result->exit_code(), 0, 'Exit code is 0.');

};

