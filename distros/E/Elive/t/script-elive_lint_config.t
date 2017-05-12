#!perl
use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

use lib '.';
use t::Elive;

eval "use Test::Script::Run 0.04 qw{:all}";

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Script::Run 0.04+ required to run scripts';
    plan( skip_all => $msg );
}

local ($ENV{TERM}) = 'dumb';

plan(tests => 6);

my $script_name = 'elive_lint_config';

#
# try running script with --help
#

do {
    my ( $result, $stdout, $stderr ) = run_script($script_name, ['--help'] );
    my $status = last_script_exit_code();
    is($status   => 0, "$script_name --help: zero exit status");
    diag $stderr if $stderr;
    like($stdout => qr{usage:}ix, "$script_name --help: stdout =~ 'usage:...''");
};

#
# try with invalid option
#

do {
    my ( $result, $stdout, $stderr ) = run_script($script_name, ['--invalid-opt'] );
    my $status = last_script_exit_code();
    isnt($status   => 0, "$script_name invalid option: non-zero exit status");
    is($stdout   => '', "$script_name invalid option: stdout empty");
    like($stderr => qr{unknown \s+ option}ix, "$script_name invalid option: message");
    like($stderr => qr{usage:}ix, "$script_name invalid option: usage");
};

# TODO: test with actual XML content? - however, this script is on the verge of
# being depreciated.

