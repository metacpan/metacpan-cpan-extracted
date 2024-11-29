use strict;
use warnings;
use lib 'lib';
use threads;
use aliased 'Javonet::Javonet' => 'Javonet', qw(in_memory tcp);

use File::Spec; 
use Test::More qw(no_plan);



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
    open my $config_file, '>', 'javonet.config';
    close $config_file;
    my $runtime_ctx1 = Javonet->with_config("javonet.config")->jvm();
    my $runtime_ctx2 = Javonet->with_config("javonet.config")->jvm();
    is($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with config are equal');
    unlink 'javonet.config';
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
    open my $config_file, '>', 'javonet.config';
    close $config_file;
    my $runtime_ctx1 = Javonet->with_config("javonet.config")->nodejs();
    my $runtime_ctx2 = Javonet->with_config("javonet.config")->jvm();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with different languages but same config are different');
    unlink 'javonet.config';
}

sub test_invoke_multiple_runtime_contexts_are_different5 {
    open my $config_file, '>', 'javonet.config';
    close $config_file;
    my $runtime_ctx1 = Javonet->in_memory()->jvm();
    my $runtime_ctx2 = Javonet->with_config("javonet.config")->jvm();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with and without config are different');
    unlink 'javonet.config';
}

sub test_invoke_multiple_runtime_contexts_are_different6 {
    open my $config_file1, '>', 'javonet.config';
    close $config_file1;
    open my $config_file2, '>', 'javonet2.config';
    close $config_file2;
    my $runtime_ctx1 = Javonet->with_config("javonet.config")->nodejs();
    my $runtime_ctx2 = Javonet->with_config("javonet2.config")->nodejs();
    isnt($runtime_ctx1, $runtime_ctx2, 'Invoking multiple runtime contexts with different configs are different');
    unlink 'javonet.config';
    unlink 'javonet2.config';
}

sub test_create_runtime_context_with_config_path_which_exists {
    open my $config_file, '>', 'javonet.config';
    close $config_file;
    my $runtime_ctx1 = Javonet->with_config("javonet.config")->jvm();
    ok(defined $runtime_ctx1, 'Runtime context with existing config path is created');
    unlink 'javonet.config';
}

sub test_create_runtime_context_with_config_path_which_not_exists {
    eval {
        my $runtime_ctx1 = Javonet->with_config("javonet2.config")->jvm();
    };
    if ($@) {
        like($@, qr/Javonet set config source result: -6. Native error message: Configuration file javonet2.config not found/, 'Exception is thrown when config path does not exist');
    } else {
        fail('Exception was not thrown when config path does not exist');
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
test_invoke_multiple_runtime_contexts_are_different6();
test_create_runtime_context_with_config_path_which_exists();
#test_create_runtime_context_with_config_path_which_not_exists();

done_testing();
1