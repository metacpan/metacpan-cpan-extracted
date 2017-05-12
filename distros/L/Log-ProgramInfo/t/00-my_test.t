### 00-test.t #################################################################

# TODO: rename this test file

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More;
use Test::Exception;
use File::Path qw(make_path remove_tree);

### Prep  #####################################################################

my $logdir;

BEGIN {
    my @logdir = ( "scratch", $$ );
    for (@logdir) {
        $logdir .= '/' if $logdir;
        $logdir .= $_;
        make_path( $logdir );
    }
    print STDERR "Log for tests will be written in $logdir\n";
}

### Tests #####################################################################

my $num_setup_tests = 4;

sub setup_test {
    my ($dir, $script, $logpat, $logcount, @args) = @_;
    make_path($dir);
    open my $fhout, '>', "$dir/script";
    print $fhout $script;
    close $fhout;
    my $args = join( ' ', @args );
    is (system( "$^X $dir/script $args >>$dir/stdout 2>>$dir/stderr" ), 0, 'executing script should pass');
    opendir( my $dirhandle, $dir ) || die "cannot open dirhandle on ($dir): $!";
    my @logs =
        grep { -f $_ && $_ =~ $logpat }
        map { "$dir/$_" }
        readdir $dirhandle;
    if (is( scalar(@logs), 1, 'find one log file')) {
        my $log = shift @logs;
        if (lives_ok { @logs = Log::ProgramInfo::readlog( $log ); } "reading log file(s)") {
            is( scalar(@logs), $logcount, 'find $logcount log(s) in file');
            return @logs;
        }
    }
    return undef;
}


# Verify that the module can be included. (BEGIN just makes this happen early)
BEGIN {use_ok('Log::ProgramInfo' => ( '-logdir' => $logdir ))};

subtest "basics" => sub {
    plan tests => $num_setup_tests+8;

    my $dir = "$logdir/basics";
    my @logs = setup_test( $dir, <<"SCRIPT", qr(/20\d{6}-script.programinfo$), 1 );

    use Log::ProgramInfo ( '-logdir', '$dir' );
    exit(0);
SCRIPT

    my $log = pop @logs; # check the latest in case there is more than one
    my $mod = $log->{MODULE}{NAME};
    # my $ver = $log->{MODULE}{VERSION};
    my $loc = $log->{MODULE}{LOC};
    my @index = grep { $mod->[$_] eq "Log::ProgramInfo" } 0..(scalar(@$mod)-1);
    is( scalar(@index), 1, 'found one index for module Log::ProgramInfo' );
    like( $loc->[$index[0]], qr(Log/ProgramInfo\.pm$), 'index for Log::ProgramInfo has a valid looking filename' );
    cmp_ok( $log->{Elapsed}, '>', 0, 'elapsed time is numeric and positive' );
    cmp_ok( $log->{Elapsed}, '<', 1, 'elapsed time in less than one second' );
    cmp_ok( $log->{Args}, 'eq', '0', 'zero command line args passed' );
    ok( !exists $log->{arg}, 'no individual arg found' );
    if (length($log->{ProgDir}) == length($dir)) {
        is( $log->{ProgDir}, $dir, "program directory" );
    }
    else {
        like( $log->{ProgDir}, qr(/$dir$), "program directory" );
    }
    is( $log->{Program}, 'script', "program name" );
    done_testing;
};

subtest "args_and_time" => sub {
    plan tests => $num_setup_tests+6;

	my $dir = "$logdir/args_and_time";
    my @logs = setup_test( $dir, <<"SCRIPT", qr(/20\d{6}-script.programinfo$), 1, 'arg1', 'arg2' );

    use Log::ProgramInfo ( '-logdir', '$dir' );
    sleep(10);
    exit(0);
SCRIPT

    my $log = pop @logs; # check the latest in case there is more than one
    cmp_ok( $log->{Elapsed}, '>', 0, 'elapsed time is numeric and positive' );
    cmp_ok( $log->{Elapsed}, '>=', 10, 'elapsed time at least ten seconds' );
    cmp_ok( $log->{Args}, 'eq', '2', 'two command line args passed' );
    ok( exists $log->{arg}, 'individual args found' );
    is( $log->{arg}{1}, 'arg1', 'arg 1 correct' );
    is( $log->{arg}{2}, 'arg2', 'arg 2 correct' );
    done_testing;
};

subtest "import_parameters" => sub {
    plan tests => $num_setup_tests;

    my $dir = "$logdir/import_parameters";
    my @logs = setup_test( $dir, <<"SCRIPT", qr(/foo.bar$), 1 );

    use Log::ProgramInfo ( '-logdir', '$dir', '-logdate', 'none', '-logname', 'foo', '-logext', 'bar' );
    exit(0);
SCRIPT

    # the only real test was finding the log file with the right name
    # - done in setup_test
    done_testing;
};

subtest "bad user provided logger" => sub {
    plan tests => 1;
    dies_ok { Log::ProgramInfo::add_extra_logger( "string" ) } 'catch non-sub arg to add_extra_logger';
};

subtest "good user provided logger" => sub {
    plan tests => $num_setup_tests+1;

    my $dir = "$logdir/good_user_provided_logger";
    my @logs = setup_test( $dir, <<"SCRIPT", qr(/20\d{6}-script.programinfo$), 1 );

    use Log::ProgramInfo ( '-logdir', '$dir' );
    sub my_logger {
        my \$log_it = shift;
        \$log_it->(My_logger => "is simple");
    }
    Log::ProgramInfo::add_extra_logger( \\&my_logger );
    exit(0);
SCRIPT

    my $log = pop @logs; # check the latest in case there is more than one
    is( $log->{My_logger}, 'is simple', 'user logger provides expected value' );

    # the only real test was finding the log file with the right name
    # - done in setup_test
    done_testing;
};

done_testing(6);

# This code gets run before the use_ok above - the first test - for some reason,
# so forget cleanup for now.
#
#     my $tb = Test::More->builder;
#     print STDERR "In END BLOCK\n";
#     if ($tb->is_passing) {
#         remove_tree( $logdir );
#     }

1;
