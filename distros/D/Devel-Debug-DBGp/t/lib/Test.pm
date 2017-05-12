package t::lib::Test;

use 5.006;
use strict;
use warnings;
use parent 'Test::Builder::Module';

use Test::More;
use Test::DBGp;

use IPC::Open3 ();
use MIME::Base64 qw(encode_base64);
use Cwd;
use File::Spec::Functions;

our @EXPORT = (
  @Test::More::EXPORT,
  @Test::DBGp::EXPORT,
  qw(
        abs_uri
        abs_path
        run_debugger
        run_program
        send_command
        command_is
        position_is
        stack_depth_is
        breakpoint_list_is
        eval_value_is
        parsed_response_is
        start_listening
        stop_listening
        wait_connection
        close_connection
        wait_line
        send_line
  )
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

my ($PID, $CHILD_IN, $CHILD_OUT, $CHILD_ERR);

sub abs_uri {
    return 'file://' . File::Spec::Functions::rel2abs(
        $_[0], Cwd::getcwd());
}

sub abs_path {
    return File::Spec::Functions::rel2abs(
        $_[0], Cwd::getcwd());
}

sub start_listening { dbgp_listen() }
sub stop_listening { dbgp_stop_listening() }

sub run_program {
    my ($script, $opts) = @_;
    $opts ||= '';

    my $port = dbgp_listening_port();
    my $path = dbgp_listening_path();
    local $ENV{PERLDB_OPTS} = $port ?
        "RemotePort=localhost:$port $opts" :
        "RemotePath=$path $opts";
    # the harness/blib don't add dbgp-helper to the path
    local $ENV{PERL5LIB} = join ':', qw(blib/lib/dbgp-helper blib/arch),
                                     ($ENV{PERL5LIB}) x !!$ENV{PERL5LIB}
        if grep /blib/, @INC;
    $PID = IPC::Open3::open3(
        $CHILD_IN, $CHILD_OUT, $CHILD_ERR,
        $^X, '-d', $script,
    );
}

sub run_debugger {
    my ($script, $opts) = @_;

    start_listening();
    run_program($script, $opts);
    wait_connection();
}

sub wait_connection { dbgp_wait_connection($PID, @_) }

sub wait_line {
    readline $CHILD_OUT;
}

sub send_line {
    print $CHILD_IN "\n";
    flush $CHILD_IN;
}

sub send_command { dbgp_send_command(@_) }

sub command_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    dbgp_command_is(@_);
}

sub position_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($file, $line) = @_;

    dbgp_command_is(['stack_get', '-d', 0], {
        command => 'stack_get',
        frames  => [
            {
                level       => 0,
                filename    => abs_uri($file),
                lineno      => $line,
            },
        ],
    });
}

sub stack_depth_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($depth) = @_;

    dbgp_command_is(['stack_depth'], {
        command => 'stack_depth',
        depth   => $depth,
    });
}

sub eval_value_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($expr, $value) = @_;
    my $res = send_command('eval', encode_base64($expr));
    my $eval_type = $res->result->type;
    my $eval_value = $res->result->value;

    # workaround for current client behaviour
    is($eval_type eq 'undef' ? undef :
       defined $eval_value   ? $eval_value :
                          '',
       $value);
}

sub breakpoint_list_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($expected) = @_;

    my $breakpoints = send_command('breakpoint_list')->breakpoints;
    my $sorted_breakpoints = [sort { $a->id <=> $b->id } @$breakpoints];

    dbgp_parsed_response_cmp($sorted_breakpoints, $expected);
}

sub parsed_response_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    dbgp_parsed_response_cmp(@_);
}

sub _cleanup {
    return unless $PID;
    kill 9, $PID;
}

END { _cleanup() }

1;
