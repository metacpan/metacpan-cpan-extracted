use strict;
use warnings;
use lib 't/lib';

use REPLTest;
use Test::More tests => 9;
use Test::NoWarnings;

NONEXISTENT_MODULE:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load('IDontExist');
    $repl->lazy_load('IDontExist2' => qw{foo bar});

    my ( $result ) = $repl->eval('IDontExist->new');
    isa_ok $result, 'Devel::REPL::Error';

    ( $result ) = $repl->eval('foo()');
    isa_ok $result, 'Devel::REPL::Error';

    # do it again, in case something funky happens the second time around
    ( $result ) = $repl->eval('IDontExist->new');
    isa_ok $result, 'Devel::REPL::Error';

    ( $result ) = $repl->eval('foo()');
    isa_ok $result, 'Devel::REPL::Error';
};

BAD_MODULE:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load('BadOOModule');
    $repl->lazy_load('BadExporterModule' => qw{foo bar});

    my ( $result ) = $repl->eval('BadOOModule->new');
    isa_ok $result, 'Devel::REPL::Error';

    ( $result ) = $repl->eval('foo()');
    isa_ok $result, 'Devel::REPL::Error';
};

BAD_EXPORT_SYMBOL:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load(ExportingModule => qw{baz});

    my ( $result ) = $repl->eval('baz()');
    isa_ok $result, 'Devel::REPL::Error';
};

BAD_CUSTOM_EXPORTER:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load(BadCustomExporter => qw{quux});

    my ( $result ) = $repl->eval('quux()');
    isa_ok $result, 'Devel::REPL::Error';
};
