#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 14;

require_ok 'Dist::Zilla::Plugin::LocaleTextDomain';
is_deeply [Dist::Zilla::Plugin::LocaleTextDomain->mvp_multivalue_args],
    [qw(language finder)], 'Should have mvp_multivalue_args';

for my $cmd (qw(msg_init msg_scan msg_merge msg_compile)) {
    my $module = "Dist::Zilla::App::Command::$cmd";
    require_ok $module;
    isa_ok $module => 'App::Cmd::Command';
    can_ok $module => qw(
        command_names
        abstract
        usage_desc
        opt_spec
        validate_args
        execute
    );
}
