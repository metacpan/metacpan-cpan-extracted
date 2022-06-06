#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;
use Data::Dumper;
use Config;
use Cwd;

use File::Temp;
use File::Slurper;

use JavaScript::QuickJS;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

mkdir "$dir/my";

File::Slurper::write_binary(
    "$dir/my/module.js",
    "export const life = 42;\n",
);

my $cwd = Cwd::getcwd();

my $retval;

my $js = JavaScript::QuickJS->new()->set_globals(
    _return => sub { $retval = shift },
);

#----------------------------------------------------------------------

eval { _test_module($js, '(should fail)'); fail 'nonono' };
my $err = $@;
like($err, qr<ReferenceError>, 'module load should fail without default dir');

chdir $dir;

_test_module('before set_module_base()');

chdir $cwd;

is(
    q<> . $js->set_module_base($dir),
    "$js",
    'set_module_base() returns object',
);

_test_module('after set_module_base()');

#----------------------------------------------------------------------

is(
    q<> . $js->unset_module_base(),
    "$js",
    'unset_module_base() returns object',
);

eval { _test_module('(should fail)'); fail 'nonono' };
$err = $@;
like($err, qr<ReferenceError>, 'module load should fail without default dir');

chdir $dir;

_test_module('after unset_module_base()');

sub _test_module {
    my ($label) = @_;

    my $ret = $js->eval_module(<<END);
        import * as IMPORTED from 'my/module.js';
        _return(IMPORTED.life);
        42;
END

    is($ret, $js, 'eval_module() returns JS object');

    is( $retval, 42, "$label: module imported and used" );

    $js = JavaScript::QuickJS->new()->set_globals(
        _return => sub { $retval = shift },
    );
}

undef $js;

chdir $cwd;

done_testing;
