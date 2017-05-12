use Test::More tests => 67;

use lib '../lib', 'lib';

chdir 't';

BEGIN {
    use_ok( 'IPC::Open3::Utils', ':all' );
}

diag("Testing IPC::Open3::Utils $IPC::Open3::Utils::VERSION");

my $script = 'ipc_opens_utils_testing.perl';
if ( open my $fh, '>', $script ) {
    print "#!$^X\n";
    print {$fh} <<'END_SCRIPT';
    
require Time::HiRes;

my ($n,$e,$p) = @ARGV;
$n = abs(int($n)) || 1;
$e = abs(int($e)) || 0;
$p = abs(int($p)) || 0;

if ($p) {
    $|++;
    print "What number:\n";
    my $num = <STDIN>;
    $num =~ s{\D+}{};
    print "You said -$num-\n";    
}

for (1 .. $n) {
    print "expected stdout\n";
    Time::HiRes::nanosleep(10_000); # handle oddity in timing in tests on some systems
    print STDERR "expected stderr\n"
}

exit($e);
END_SCRIPT
    close $fh;
    chmod 0755, $script;
}

my @cmd = ( $^X, $script );
my @one = ( "expected stdout\n", "expected stderr\n" );

SKIP: {
    skip "Could not create executable script for testing: $!", 70 if !-x $script;
    skip "\n\$^X is not set!\n",                               70 if !$^X;

  SKIP: {

        # To verify that the default handler goes where it should, manually run these commands in t/:
        #   perl -I../lib -e 'use IPC::Open3::Utils;IPC::Open3::Utils::run_cmd("perl","ipc_opens_utils_testing.perl",1);' 2>/dev/null
        #   perl -I../lib -e 'use IPC::Open3::Utils;IPC::Open3::Utils::run_cmd("perl","ipc_opens_utils_testing.perl",1);' 1>/dev/null
        #   perl -I../lib -e 'use IPC::Open3::Utils;IPC::Open3::Utils::run_cmd("perl","ipc_opens_utils_testing.perl",1);' 1>/dev/null 2>&1
        #
        # TODO: get one of these test modules to work or find another
        #    untie attempted while 1 inner references still exist at /System/Library/Perl/5.8.8/IPC/Open3.pm line 204.
        #    untie attempted while 2 inner references still exist at /System/Library/Perl/5.8.8/IPC/Open3.pm line 204.

        skip 'Test::Output && Test::Trap are both broken', 4;

        # eval 'require Test::Output'; # see Test::Output, Test::Trap
        # skip "Test::Output is needed for these tests", 4 if $@;

        # use Test::Trap;
        # trap {
        my $run_test_script = sub {
            IPC::Open3::Utils::run_cmd( $^X, $script, 1 );
        };

        # is ( $trap->stdout, "expected stdout\n", "STDOUT" );
        # is ( $trap->stderr, "expected stderrn", "STDERR" );

        Test::Output::output_is( $run_test_script, @one, 'STDOUT' );
        Test::Output::combined_is( $run_test_script, join( '', @one ), 'STDOUT/STDERRORDER' );

        $run_test_script = sub {
            IPC::Open3::Utils::run_cmd(
                $^X, $script, 1,
                {
                    'handler' => sub {
                        my ( $cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_sr ) = @_;
                        if ($is_stderr) {
                            print STDERR "LINE: $cur_line";
                        }
                        else {
                            print "LINE: $cur_line";
                        }

                        return 1;
                    },
                }
            );
        };

        Test::Output::output_is( $run_test_script, "LINE: expected stdout\n", "LINE: expected stderr\n", 'STDOUT w/ hashref modifier' );
        Test::Output::combined_is( $run_test_script, "LINE: expected stdout\nLINE: expected stderr\n", 'ORDERING w/ hashref modifier' );
    }

    my %args;

  SKIP: {

        my $wasclosed = 1;
        my $output    = '';
        my $handler   = 0;
        my $my_is_stderr;
        my $rc = run_cmd(
            @cmd,
            {
                'handler' => sub {
                    my ( $cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_sr ) = @_;

                    $my_is_stderr = $is_stderr;
                    $handler++;

                    $output .= $cur_line;
                    $wasclosed = !defined $stdin ? 1 : 0;
                    ${$short_circuit_loop_sr} = 1;

                    return 1;
                },
                'close_stdin' => 1,
                'autoflush'   => {
                    'stdout' => 1,
                    'stderr' => 1,
                },
                '_pre_run_sleep' => 1,    # to avoid skip 'stderr weirdness X, skipping test' ?
            }
        );
        ok( $rc,      'returns true when handler returns true' );
        ok( $handler, 'handler key used' );
      SKIP: {
            # Order issues happen consistently on some servers and consistently not on others. Appears ot simply be timing and not much we can do about it. tests get around it by using undocumented '_pre_run_sleep' sleep
            # skip "stderr weirdness X, skipping test", 2 if $output eq "expected stderr\n";
            ok( $output eq $one[0], 'short circuit scalar ref set to true stops while()' );    # X this fails because stderr happens before stdout
            ok( !$my_is_stderr,     '$is_stderr is false when we are on STDOUT' );             # X this fails because stderr happens before stdout
        }

        ok( $wasclosed, 'close_stdin being true  results in stdin being closed' );

        my $wasclosed_x = 1;
        my $output_x    = '';
        my $my_is_stderr_x;
        my $parsed_from_stdin_echo = 0;
        my $rc_x                   = run_cmd(
            @cmd, 1, 0, 1,
            {
                'handler' => sub {
                    my ( $cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_sr ) = @_;

                    if ( $cur_line =~ m{What number:} ) {
                        $stdin->print("42\n");    # print {$stdin} "42\n"; also works
                        $wasclosed_x = 0;
                        return 1;
                    }

                    if ( $cur_line =~ m{You said -(\d+)-} ) {
                        $parsed_from_stdin_echo = $1;
                        $wasclosed_x            = 0;
                        return 1;
                    }

                    $my_is_stderr_x = $is_stderr;

                    # $wasclosed_x = $stdin->opened ? 0 : 1; # how to tell id an IO::Handle object is open or not
                    ${$short_circuit_loop_sr} = 0;
                    return 1 if !$is_stderr;
                    $output_x .= $cur_line;
                    return;
                },
                'close_stdin' => 0,
            }
        );
        ok( !$rc_x,                        'returns false when handler returns false' );
        ok( $output_x eq $one[1],          'short circuit scalar ref set to false does not stop while()' );
        ok( !$wasclosed_x,                 'close_stdin being false results in stdin being open' );
        ok( $my_is_stderr_x,               '$is_stderr is true when we are on STDERR' );
        ok( $parsed_from_stdin_echo == 42, 'stdin handle operable' );

        {
            local $? = 0;
            local $! = 42;
            ok( $? == 0 && $! != 0, 'pre test variable sanity check' );
            my $rc = run_cmd(
                @cmd, 1, 1,
                {
                    'handler' => sub { return 1; }
                }
            );

            # use Data::Dumper;Test::More::diag($? . " && " . Dumper(int($!)));
            ok( !$rc, 'rc is failed on exit 1' );
        }

        {
            local $? = 0;
            local $! = 42;
            ok( $? == 0 && $! != 0, 'pre test variable sanity check w/ ref' );
            my $rc = run_cmd(
                @cmd, 1, 1,
                {
                    'handler' => sub { return 1; }
                }
            );
            ok( !$rc, 'rc is failed on exit 1 w/ ref' );
        }

        {
            my %args;
            my $rc = run_cmd( \%args );
            ok( !$rc, 'open3_error returns false non-ref populated' );
            ok( exists $args{'open3_error'} && $args{'open3_error'}, 'open3_error non-ref populated' );
            my $open3;
            my $rc_x = run_cmd( { 'open3_error' => \$open3 } );
            ok( !$rc_x, 'open3_error returns false ref populated' );
            ok( defined $open3 && $open3, 'open3_error ref populated' );
        }

        {
            my $child = undef;
            my $rc = put_cmd_in( @cmd, 1, 1, [], [] );
            ok( !$rc, 'put_cmd_in exit one returns false' );
        }

        # TODO tests for 'autoflush' key
    }

    # TODO test that these have no output once Test::Output or friends work:

    # test output placement
    my @all_output;
    my $all_output;
    my @stderr;
    my @stdout;
    my $stderr;
    my $stdout;

    put_cmd_in( @cmd, \@all_output );

    # order not necessarily kept due to to IO::Select behavior
    my $all_str = join( '', @all_output );
    ok( $all_str eq join( '', @one ) || $all_str eq join( '', reverse @one ), 'one output arg array ref' );
    ## Test::Deep::any, bag, set, etc would work as well
    ## is_deeply(\@all_output, \@one, 'one output arg array ref');
    ## or
    ## is_deeply(\@all_output, [reverse @one], 'one output arg array ref');

    put_cmd_in( @cmd, \$all_output );

    # order not necessarily kept due to to IO::Select behavior
    ok( $all_output eq join( '', @one ) || $all_output eq join( '', reverse @one ), 'one output arg scalar ref' );

    put_cmd_in( @cmd, \@stdout, \@stderr );
    is_deeply( \@stdout, [ $one[0] ], 'two output arg array ref - stdout' );
    is_deeply( \@stderr, [ $one[1] ], 'two output arg array ref - stderr' );

    put_cmd_in( @cmd, \$stdout, \$stderr );
    ok( $stdout eq $one[0], 'two output arg scalar ref - stdout' );
    ok( $stderr eq $one[1], 'two output arg scalar ref - stderr' );

    $stderr = '';
    $stdout = '';
    put_cmd_in( @cmd, \$stdout, \$stderr, { 'ignore_handle' => 'unknown' } );
    ok( $stdout eq $one[0], 'ignore_handle unknown - stdout' );
    ok( $stderr eq $one[1], 'ignore_handle unknown - stderr' );
    $stderr = '';
    $stdout = '';
    put_cmd_in( @cmd, \$stdout, \$stderr, { 'ignore_handle' => 'stderr' } );
    ok( $stdout eq $one[0], 'ignore_handle stderr - stdout' );
    ok( $stderr eq '',      'ignore_handle stderr - stderr' );
    $stderr = '';
    $stdout = '';
    put_cmd_in( @cmd, \$stdout, \$stderr, { 'ignore_handle' => 'stdout' } );
    ok( $stdout eq '',      'ignore_handle stdout - stdout' );
    ok( $stderr eq $one[1], 'ignore_handle stdout - stderr' );

    @stderr = ();
    @stdout = ();
    put_cmd_in( @cmd, \@stdout, undef, \%args );
    is_deeply( \@stdout, [ $one[0] ], 'two output arg, one undef - stdout' );

    put_cmd_in( @cmd, undef, \@stderr, \%args );
    is_deeply( \@stderr, [ $one[1] ], 'two output arg, one undef - stderr' );

    # TODO test these for silence once Test::Output or friends work:
    #   put_cmd_in(@cmd, undef, undef, \%args)
    #   put_cmd_in(@cmd, undef, \%args);
    #   put_cmd_in(@cmd, undef, \%args);
    #   put_cmd_in(@cmd, \%args);
    #   put_cmd_in(@cmd);

    $? = 0;
    ok( child_error_ok(), 'child_error_ok true $?' );
    $? = 1;
    ok( !child_error_ok(), 'child_error_ok false $?' );
    $? = -1;
    ok( !child_error_ok(), 'child_error_ok false 2 $?' );
    $? = -1;
    ok( child_error_failed_to_execute(), 'child_error_failed_to_execute true $?' );
    $? = 0;
    ok( !child_error_failed_to_execute(), 'child_error_failed_to_execute false $?' );
    $? = 139;
    ok( child_error_seg_faulted(), 'child_error_seg_faulted true $?' );
    $? = 140;
    ok( !child_error_seg_faulted(), 'child_error_seg_faulted false $?' );
    $? = 128;
    ok( child_error_core_dumped(), 'child_error_core_dumped true $?' );
    $? = 127;
    ok( !child_error_core_dumped(), 'child_error_core_dumped false $?' );
    $? = 142;
    ok( child_error_exit_signal() == 14, 'child_error_exit_signal diff $?' );
    $? = 127;
    ok( child_error_exit_signal() == 127, 'child_error_exit_signal same $?' );
    $? = 256;
    ok( child_error_exit_value() == 1, 'child_error_exit_value 1 $?' );
    $? = 255;
    ok( child_error_exit_value() == 0, 'child_error_exit_value 0 $?' );

    $? = 42;
    ok( child_error_ok(0),                 'child_error_ok true ARG' );
    ok( !child_error_ok(1),                'child_error_ok false ARG' );
    ok( !child_error_ok(-1),               'child_error_ok false 2 ARG' );
    ok( child_error_failed_to_execute(-1), 'child_error_failed_to_execute true ARG' );
    ok( !child_error_failed_to_execute(0), 'child_error_failed_to_execute false ARG' );
    ok( child_error_seg_faulted(139),      'child_error_seg_faulted true ARG' );
    ok( !child_error_seg_faulted(140),     'child_error_seg_faulted false ARG' );
    ok( child_error_core_dumped(128),      'child_error_core_dumped true ARG' );
    $? = 142;
    ok( !child_error_core_dumped(127), 'child_error_core_dumped false ARG' );
    $? = 42;
    ok( child_error_exit_signal(142) == 14,  'child_error_exit_signal diff ARG' );
    ok( child_error_exit_signal(127) == 127, 'child_error_exit_signal same ARG' );
    ok( child_error_exit_value(256) == 1,    'child_error_exit_value 1 ARG' );
    $? = 256;
    ok( child_error_exit_value(255) == 0, 'child_error_exit_value 0 ARG' );

}

ok(
    run_cmd(
        @cmd,
        {
            'handler' => sub { 1 }
        }
    ),
    'sanity check that cmd by itself returns true'
);    # sub { 1 } || put_cmd_in() == silent
ok(
    !run_cmd(
        @cmd,
        {
            'handler' => sub { die 'epoch fail' }
        }
    ),
    "handler dies returns false"
);
ok( $@ =~ m/epoch fail/, 'handler dies sets $@' );
