### 20-skip.t #############################################################
# This file tests setting the files attribute with skip settings in its
# various incarnations.

# We have a test "pipeline".
#
# stage1:
#   converts f.in to f.out, using f.tmp for the partial output and then
#       renaming after completion
# stage2:
#   converts f.out to f.out2, using f.tmp2 for partial output

# This pipeline is run in a number of ways:
# 1: stage1 fails in the middle
#        f.out should not be created
#        stage2 should not be run
# 2: stage1 succeeds, stage2 fails in the middle
#        f.out should be created
#        f.out2 should not
# 3: stage1 should be skipped, stage2 succeeds
#        f.out2 should be created
# 4: both stage1 and stage2 should be skipped
# 5: f.in is touched, both stage1 and stage2 should run
#        f.out and f.out2 should be recreated

# That while sequence of steps 1-5 are themselves run in a number of ways:
# 1: using command or code for the execution of each stage
# 2: using a shared or an unshared files system for the in/out files
# That allows 4 sets of runs:
#     code-shared     code-unshared
#     command-shared  command-unshared

# To run a single test instead of the entire suite of 20,
# set env variable: ONETEST=code-shared-1

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::Exception;
use List::MoreUtils qw(pairwise);

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $dispatch;
my $sharing;
my $tests;

sub limit_keys {
    my $list = shift;
    my $limit = shift;

    my @new_list = grep { $limit->{$_} } @$list;
    return @new_list ? @new_list : @$list;
}

my $test_count;

BEGIN {
    $dispatch = [ qw(code command) ];
	$sharing  = [ qw(shared) ];
    # $sharing  = [ qw(shared unshared) ];
	$tests    = [ 1..5 ];

	if ($ENV{LIMIT_TEST}) {
		my %valid_key = map { $_ => 1 } @$dispatch,@$sharing,@$tests;
		my @keys = map {
            $_ =~ m/(\d*)-(\d*)/
                ? ( ($1 || 1) .. ($2 || 5) )
                : ($_)
            } $ENV{LIMIT_TEST} =~ m/([-\w]+)/g;
		if (my @bad_keys = grep { !$valid_key{$_} } @keys) {
			die "Invalid key(s) found in LIMIT_TEST: "
				. join( ' ', @keys )
				. "\nValid keys are: "
				. join( ' ', @$dispatch,@$sharing,@$tests );
		}
		my $limit_keys = { map { $_ => 1 } @keys };

		$dispatch = [ limit_keys( $dispatch, $limit_keys ) ];
		$sharing  = [ limit_keys( $sharing,  $limit_keys ) ];
		$tests    = [ limit_keys( $tests,    $limit_keys ) ];
	}

	$test_count = scalar(@$dispatch) * scalar(@$sharing) * scalar(@$tests);
};

use Test::More tests => $test_count;

my $dir_path=`pwd`;
chomp($dir_path);

-d 'scratch' or mkdir 'scratch';

my $workdir = "scratch/TEST.SKIPSTAGE";

my @fs_delay = (file_system_delay => 5, log_level => 'debug');
# push @fs_delay, stage_defaults => { force_unshared_files => 1 }
# if $ENV{TEST_UNSHARED_FILES};

if ( -e $workdir ) {
        die "file exists where work directory was going to be used ($workdir)"
          if -f _;
        system("rm -rf $workdir") if -d _;
        die "cannot remove old work directory $workdir" if -e $workdir;
}

mkdir $workdir or die "cannot create directory $workdir: $!";

#  stage_stat: result of stages S1 and S2, can pass, fail, failskip, skip
#  file_stat:  state of files f.in, f.tmp, f.out, f.out2, must exist (1) or not (0)
my @check_stages = ( qw(S1 S2) );
my @check_files  = map { "$workdir/$_" } qw(f.in f.tmp f.out f.out2);
my @tests = (
    {   # 1: stage1 fails in the middle
        #        f.out should not be created
        #        stage2 should not be run
        description => 'stage1 fails',
        fail1       => 1,
        build       => [ qw( in ) ],
        stage_stat  => [ qw( fail failskip ) ],
        file_stat   => [ qw( 1 1 0 0 ) ],
    },
    {   # 2: stage1 succeeds, stage2 fails in the middle
        #        f.out should be created
        #        f.out2 should not
        description => 'stage2 fails',
        fail2       => 1,
        build       => [ qw( in ) ],
        stage_stat  => [ qw( pass fail ) ],
        file_stat   => [ qw( 1 1 1 0 ) ],
    },
    {   # 3: stage1 should be skipped, stage2 succeeds
        #        f.out2 should be created
        description => 'all stages pass',
        build       => [ qw( in out )],
        stage_stat  => [ qw( skip pass ) ],
        file_stat   => [ qw( 1 0 1 1 ) ],
    },
    {   # 4: both stage1 and stage2 should be skipped
        description => 'all stages skipped',
        build       => [ qw( in out out2 ) ],
        stage_stat  => [ qw( skip skip ) ],
        file_stat   => [ qw( 1 0 1 1 ) ],
    },
    {   # 5: f.in is touched, both stage1 and stage2 should run
        #        f.out and f.out2 should be recreated
        description => 'all stages re-run',
        build       => [ qw( out out2 in ) ],
        stage_stat  => [ qw( pass pass ) ],
        file_stat   => [ qw( 1 0 1 1 ) ],
    },
);

use diagnostics; # TODO: remove this when test is debugged

my $group;
my $prev_stage;
my $file_test = 0;
my $test_name;

sub run_a_test {
    my $dispatch = shift;
    my $sharing  = shift;
    my $test     = shift;
    my $parms = $tests[$test-1];
    $test_name  = "$dispatch-$sharing-$test";
    subtest "$test_name: $parms->{description}" => sub {
        plan tests => 6;
        $group = HPCI->group(
            name     => $test_name,
            cluster  => $cluster,
            base_dir => "$dir_path/scratch",
            @fs_delay,
        );
        my $s1    = $parms->{fail1} ? '; (exit 1)' : '';
        my $s2    = $parms->{fail2} ? '; (exit 1)' : '';

        undef $prev_stage;

        sub chain_stage {
            my $stage_name = $group->stage( @_ )->name;
            $group->add_deps( pre_req => $prev_stage, dep => $stage_name )
                if $prev_stage;
            $prev_stage = $stage_name;
        }

        sub check_stat {
            my $stat     = shift;
            my $stage    = shift;
            my $check    = shift;
            my $testinfo = shift;
            my $testheader = "test ($test_name) stage ($stage)";
            if ($check =~ qr(^(pass|fail)$)) {
                is(
                    $stat->{$stage}[-1]{final_job_state},
                    $check,
                    $testinfo // "$testheader should $check"
                );
            }
            elsif ($check eq 'failskip') {
                like(
                    $stat->{$stage}[-1]{exit_status},
                    qr/Skipped because of failure of stage/,
                    $testinfo // "Failed stage ($testheader) without execution because one or more required input files were not present"
                );
            }
            elsif ($check eq 'failfile') {
                like(
                    $stat->{$stage}[-1]{exit_status},
                    qr/Failed stage .* without execution because one or more required input files were not present/,
                    $testinfo // "$testheader should have failed without execution: because of file pre-req"
                );
            }
            elsif ($check eq 'skip') {
                like(
                    $stat->{$stage}[-1]{exit_status},
                    qr/skipped.*skip/,
                    $testinfo // "$testheader should have been skipped by skip"
                );
            }
        }

        sub check_file {
            my $file = shift;
            my $want = shift;

            my $name = "SkipStageFile" . ++$file_test;
            my $group = HPCI->group(
                name => $name,
                cluster => $cluster,
                base_dir => "$dir_path/scratch",
                @fs_delay,
            );
            my $sleep = $group->file_system_delay;
            $group->stage(
                name => $name,
                files => { in => { req => $file } },
                command => ($sleep ? "(sleep $sleep)" : '(exit 0)'),
            );
            my $stat = $group->execute;
            if ($want) {
                check_stat( $stat, $name, 'pass', "test ($test_name) file should exist: $file" );
            }
            else {
                check_stat( $stat, $name, 'failfile', "test ($test_name) file should NOT exist: $file" );
            }
        }

        for my $file ( @{ $parms->{build} } ) {
            my $fname = "$workdir/f.$file";
            chain_stage(
                name => "build_$file",
                code => sub {
                    sleep 1;
                    open my $fd, '>', $fname
                        or return "open $fname for write failed: $!";
                    print $fd "hi\n"
                        or return "write to $fname failed: $!";
                    close $fd
                        or return "close $fname failed: $!";
                    sleep 1;
                    return undef;
                },
                # command => "sleep 1;echo hi > $workdir/f.$file",
                files => {
                    out => { req => "$fname" }
                },
            );
        }

        my $cmdS1 = "sleep 1; cp $workdir/f.in $workdir/f.tmp$s1";
        chain_stage(
            name    => 'S1',
            ( $dispatch eq 'command'
                ? (command => $cmdS1)
                : (code    => sub { system( $cmdS1 ) } )
            ),
            files   => {
                in     => { req => "$workdir/f.in"  },
                out    => { req => "$workdir/f.tmp" },
                skip   => {
                    pre   => [ "$workdir/f.in" ],
                    lists => [
                        [ "$workdir/f.out" ],
                        [ "$workdir/f.out2" ],
                    ],
                },
                rename => [ [ "$workdir/f.tmp", "$workdir/f.out" ] ],
            },
        );

        my $cmdS2 = "sleep 1; cp $workdir/f.out $workdir/f.tmp$s2";
        chain_stage(
            name    => 'S2',
            ( $dispatch eq 'command'
                ? (command => $cmdS2)
                : (code    => sub { system( $cmdS2 ) } )
            ),
            files   => {
                in     => { req => "$workdir/f.out" },
                out    => { req => "$workdir/f.tmp" },
                rename => [ [ "$workdir/f.tmp", "$workdir/f.out2" ] ],
                skip => [
                    {   pre  => [ "$workdir/f.in"   ],
                        post => [ "$workdir/f.out2" ]
                    },
                ]
            },
        );

        my $stat = $group->execute;
        #use Data::Dump qw(dump);
        #print STDERR "\n---===---\nAfter executing test: $test_name\n",
            #"stat:\n", dump($stat), "workdir:\n",
            #map { "$_:\t" . (-M $_) . "\n" } <$workdir/*>,
            #;
        pairwise { check_stat( $stat, $a, $b ) } @check_stages, @{ $parms->{stage_stat} };
        pairwise { check_file( $a, $b ) }        @check_files, @{ $parms->{file_stat} };
    };
}

for my $d (@$dispatch) {
    for my $s (@$sharing) {
        unlink "$workdir/$_" for qw(f.in f.out f.out2);
        for my $t (@$tests) {
            run_a_test( $d, $s, $t );
        }
    }
}

done_testing();

1;
