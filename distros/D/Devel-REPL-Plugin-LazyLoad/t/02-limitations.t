use strict;
use warnings;
use lib 't/lib';

use REPLTest;
use Test::More tests => 3;
use Test::NoWarnings;

CLASS_IN_VARIABLE:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load('OOModule');

    my ( $result ) = $repl->eval('my $class = q{OOModule}; $class->frobnicate');
    isa_ok $result, 'Devel::REPL::Error';
};

FULL_PACKAGE_NAME:
test_repl {
    my ( $repl ) = @_;
    $repl->load_plugin('LazyLoad');
    $repl->lazy_load('OOModule');

    # we turn off that warning because we're expecting it
    my ( $result ) = $repl->eval('no warnings q{bareword}; OOModule::->frobnicate');
    isa_ok $result, 'Devel::REPL::Error';
};
