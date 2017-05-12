# -*- mode: Perl; -*-
package TemplateTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Eve::TemplateStub;

use Eve::Template;

sub test_init : Test(5) {
    my $template = Eve::Template->new(
        path => '/some/include/path',
        compile_path => '/some/compile/path',
        expiration_interval => 60);

    isa_ok($template->template, 'Template');

    is($template->template->call_pos(1), 'new');
    is_deeply(
        [$template->template->call_args(1)],
        [$template->template, 'Template',
         {INCLUDE_PATH => '/some/include/path',
          COMPILE_DIR => '/some/compile/path',
          STAT_TTL => 60,
          ENCODING => 'utf8',
          STASH => Template::Stash::XS->new()}]);

    $template = Eve::Template->new(
        path => '/another/include/path',
        compile_path => '/another/compile/path',
        expiration_interval => 120);

    is($template->template->call_pos(1), 'new');
    is_deeply(
        [$template->template->call_args(1)],
        [$template->template, 'Template',
         {INCLUDE_PATH => '/another/include/path',
          COMPILE_DIR => '/another/compile/path',
          STAT_TTL => 120,
          ENCODING => 'utf8',
          STASH => Template::Stash::XS->new()}]);
}

sub test_init_error : Test {
    throws_ok(
        sub {
            Eve::Template->new(
                path => '/some/buggy/path',
                compile_path => '/some/compile/path',
                expiration_interval => 60);
        },
        'Eve::Error::Template');
}

sub test_process : Test(4) {
    my $template = Eve::Template->new(
        path => '/some/include/path',
        compile_path => '/some/compile/path',
        expiration_interval => 60);

    my $var_hash = {'some' => 'var', 'goes' => 'here'};
    my $output = $template->process(
        file => 'helloworld.html',
        var_hash => $var_hash);

    is($template->template->call_pos(2), 'process');
    my $call_args = [$template->template->call_args(2)];
    is_deeply(
        [@{$call_args}[0..2], ${@{$call_args}[3]}],
        [$template->template, 'helloworld.html', $var_hash, $output]);

    $var_hash = {'another' => 'one'};
    $output = $template->process(
        file => 'goodbyeworld.html',
        var_hash => $var_hash);

    is($template->template->call_pos(3), 'process');
    $call_args = [$template->template->call_args(3)];
    is_deeply(
        [@{$call_args}[0..2], ${@{$call_args}[3]}],
        [$template->template, 'goodbyeworld.html', $var_hash, $output]);
}

sub test_process_error : Test {
    my $template = Eve::Template->new(
        path => '/some/include/path',
        compile_path => '/some/compile/path',
        expiration_interval => 60);

    throws_ok(
        sub {
            $template->process(
                file => 'buggy.html',
                var_hash => {'some' => 'var', 'goes' => 'here'});
        },
        'Eve::Error::Template');
}

1;
