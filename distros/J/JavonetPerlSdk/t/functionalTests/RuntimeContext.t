use strict;
use warnings;
use lib 'lib';
use threads;
use aliased 'Javonet::Javonet' => 'Javonet', qw(in_memory tcp);

use File::Spec;
use File::Basename;
use Test::More qw(no_plan);

my $this_file_path = dirname(__FILE__);
my $config_path = "${this_file_path}/../../../../testResources/configuration-file/functional-tests-config.json";

sub test_invoke_multiple_runtime_contexts_are_equal {
    my $runtime_ctx1 = Javonet->in_memory()->nodejs();
    my $runtime_ctx2 = Javonet->in_memory()->nodejs();
    is($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts in memory are equal');
}

sub test_invoke_multiple_runtime_contexts_are_equal2 {
    my $runtime_ctx1 = Javonet->tcp("123.121.21.21:2212")->ruby();
    my $runtime_ctx2 = Javonet->tcp("123.121.21.21:2212")->ruby();
    is($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts over TCP are equal');
}

sub test_invoke_multiple_runtime_contexts_are_equal3 {
    my $runtime_ctx1 = Javonet->with_config($config_path)->jvm();
    my $runtime_ctx2 = Javonet->with_config($config_path)->jvm();
    is($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with config are equal');
}

sub test_invoke_multiple_runtime_contexts_are_different {
    my $runtime_ctx1 = Javonet->in_memory()->jvm();
    my $runtime_ctx2 = Javonet->tcp("127.0.2.3:8080")->jvm();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts are different');
}

sub test_invoke_multiple_runtime_contexts_are_different2 {
    my $runtime_ctx1 = Javonet->tcp("127.0.2.3:8081")->netcore();
    my $runtime_ctx2 = Javonet->tcp("127.0.2.3:8082")->netcore();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts on different ports are different');
}

sub test_invoke_multiple_runtime_contexts_are_different3 {
    my $runtime_ctx1 = Javonet->tcp("127.0.2.3:8081")->netcore();
    my $runtime_ctx2 = Javonet->tcp("127.0.2.3:8081")->ruby();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with different languages are different');
}

sub test_invoke_multiple_runtime_contexts_are_different4 {
    my $runtime_ctx1 = Javonet->with_config($config_path)->nodejs();
    my $runtime_ctx2 = Javonet->with_config($config_path)->jvm();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with different languages but same config are different');
}

sub test_invoke_multiple_runtime_contexts_are_different5 {
    my $runtime_ctx1 = Javonet->in_memory()->jvm();
    my $runtime_ctx2 = Javonet->with_config($config_path)->jvm();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with and without config are different');
}

sub test_create_runtime_context_with_config_path_which_exists {
    my $runtime_ctx1 = Javonet->with_config($config_path)->jvm();
    ok(defined $runtime_ctx1, 'Runtime context with existing config path is created');
}

sub test_create_runtime_context_with_config_path_which_does_not_exist {
    my $config_path2 = "./javonet2config";
    eval {
        my $runtime_ctx = Javonet->with_config($config_path2)->ruby();
        fail("Expected exception was not raised");
    };
    if ($@) {
        my $expected_message = "Configuration source is not a valid JSON. Check your configuration:\n$config_path2";
        like($@, qr/\Q$expected_message\E/, 'Exception message matches expected pattern');
    }
}

sub test_create_runtime_context_with_config_source_invalid {
    my $config_source = "invalid content";
    eval {
        my $runtime_ctx = Javonet->with_config($config_source)->nodejs();
        fail("Expected exception was not raised");
    };
    if ($@) {
        my $expected_message = "Configuration source is not a valid JSON. Check your configuration:\n$config_source";
        like($@, qr/\Q$expected_message\E/, 'Exception message matches expected pattern');
    }
}



test_invoke_multiple_runtime_contexts_are_equal();
test_invoke_multiple_runtime_contexts_are_equal2();
test_invoke_multiple_runtime_contexts_are_equal3();
test_invoke_multiple_runtime_contexts_are_different();
test_invoke_multiple_runtime_contexts_are_different2();
test_invoke_multiple_runtime_contexts_are_different3();
test_invoke_multiple_runtime_contexts_are_different4();
test_invoke_multiple_runtime_contexts_are_different5();
test_create_runtime_context_with_config_path_which_does_not_exist();
test_create_runtime_context_with_config_source_invalid();

done_testing();
1