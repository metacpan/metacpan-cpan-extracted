use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 12;
use Test::NoWarnings;
use REPLTest;

NO_LAZY_LOADING:
test_repl {
    my ( $repl ) = @_;

    my ( $result ) = $repl->eval('OOModule->frobnicate');
    isa_ok $result, 'Devel::REPL::Error';

    ( $result ) = $repl->eval('foo_bar()');
    isa_ok $result, 'Devel::REPL::Error';
};

LAZY_LOAD_PLUGIN_NO_LAZY_LOADING:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');

    my ( $result ) = $repl->eval('OOModule->frobnicate');
    isa_ok $result, 'Devel::REPL::Error';

    ( $result ) = $repl->eval('foo_bar()');
    isa_ok $result, 'Devel::REPL::Error';
};

LAZY_LOAD_OO_MODULE:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load('OOModule');

    my ( $result ) = $repl->eval('OOModule->frobnicate');
    is $result, 17;

    ( $result ) = $repl->eval('foo_bar()');
    isa_ok $result, 'Devel::REPL::Error';
};

LAZY_LOAD_FUNC_MODULE:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load('OOModule');
    $repl->lazy_load(ExportingModule => qw{foo_bar});

    my ( $result ) = $repl->eval('OOModule->frobnicate');
    is $result, 17;

    ( $result ) = $repl->eval('foo_bar()');
    is $result, 18;
};

LAZY_LOAD_MULTI_LEVEL_OO_PACKAGE:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load('OOModule::Nested::Package');

    my ( $result ) = $repl->eval('OOModule::Nested::Package->invoke');
    is $result, 19;
};

LAZY_LOAD_NEW_SYMBOLS_OLD_MODULE:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->eval('use ExportingModule2 qw(foo)');
    my ( $result ) = $repl->eval('bar()');
    isa_ok $result, 'Devel::REPL::Error';
    $repl->lazy_load('ExportingModule2' => qw{foo bar});

    ( $result ) = $repl->eval('bar()');
    is $result, 'called bar';
};
