# -*- perl -*-
# 015-transitions-probe-stderr-outside-target.t
use 5.14.0;
use warnings;
use Devel::Git::MultiBisect::Transitions;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Devel::Git::MultiBisect::Auxiliary qw( write_transitions_report );
use Test::More;
unless (
    $ENV{PERL_GIT_CHECKOUT_DIR}
        and
    (-d $ENV{PERL_GIT_CHECKOUT_DIR})
) {
    plan skip_all => "No git checkout of perl found";
}
else {
    plan tests => 45;
}
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use Tie::File;
use lib qw( t/lib );
use Helpers qw(
    test_report
    test_commit_range
    test_transitions_data
);

my $startdir = cwd();

chdir $ENV{PERL_GIT_CHECKOUT_DIR}
    or croak "Unable to change to perl checkout directory";

my (%args, $params, $self);
my ($first_commit, $last_commit, $branch, $configure_command, $make_command, $test_command);
my ($git_checkout_dir, $outputdir, $rv, $this_commit_range);
my ($multisected_outputs, @invalids);
my ($probe, $probe_validated);

my $compiler = 'gcc';

$git_checkout_dir = cwd();
$outputdir = tempdir( CLEANUP => 1 );
#$outputdir = tempdir(); # Permit CLEANUP only when we're set

$branch = 'blead';
#$first = 'd4bf6b07402c770d61a5f8692f24fe944655d99f';
#$last  = '9be343bf32d0921e5c792cbaa2b0038f43c6e463';
#$first_commit   = 'v5.39.2';
#$last_commit    = 'v5.39.3';
$first_commit   = '4cfb14d6002a7da98a32388d6e3a72a6929f4181';
$last_commit    = '7aab773a19c703d6ab3ff858455bc3a9ead7639b';

$configure_command =  q|sh ./Configure -des -Dusedevel|;
$configure_command   .= qq| -Dcc=$compiler |;
$configure_command   .=  q| 1>/dev/null 2>&1|;
$make_command       = 'make minitest_prep 1>/dev/null 2>&1';
#$test_command = '';
$test_command       = './miniperl -Ilib';
$probe = 'stderr';

%args = (
    gitdir  => $git_checkout_dir,
    outputdir => $outputdir,
    first   => $first_commit,
    last    => $last_commit,
    branch  => $branch,
    configure_command => $configure_command,
    make_command => $make_command,
    test_command => $test_command,
    verbose => 1,
    probe => $probe,
);
$params = process_options(%args);
is($params->{gitdir}, $git_checkout_dir, "Got expected gitdir");
is($params->{outputdir}, $outputdir, "Got expected outputdir");
is($params->{first}, $first_commit, "Got expected first commit to be studied");
is($params->{last}, $last_commit, "Got expected last commit to be studied");
is($params->{branch}, $branch, "Got expected branch");
is($params->{configure_command}, $configure_command, "Got expected configure_command");
is($params->{make_command}, $make_command, "Got expected make_command");
is($params->{test_command}, $test_command, "Got expected test_command");
ok($params->{verbose}, "verbose requested");

$self = Devel::Git::MultiBisect::Transitions->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::Transitions');
isa_ok($self, 'Devel::Git::MultiBisect');

note("set_outside_targets()");
my $target_file = File::Spec->catdir($startdir, qw|t lib gh-22159-class.t|);
my $target_args = [ $target_file ];
my $full_targets = $self->set_outside_targets($target_args);
ok($full_targets, "set_outside_targets() returned true value");
is(ref($full_targets), 'ARRAY', "set_outside_targets() returned array ref");

note("get_commits_range()");
$this_commit_range = $self->get_commits_range();

test_commit_range(
    $this_commit_range,
    $first_commit,
    $last_commit,
);

note("multisect_all_targets()");
$rv = $self->multisect_all_targets();
ok($rv, "multisect_all_targets() returned true value");

note("get_timings()");
my $timings = $self->get_timings();
ok(exists $timings->{elapsed}, "get_timings(): elapsed time recorded");
ok(exists $timings->{runs}, "get_timings(): number of runs recorded");
ok(exists $timings->{mean}, "get_timings(): mean time recorded");


note("get_multisected_outputs");
$multisected_outputs = $self->get_multisected_outputs();

is(ref($multisected_outputs), 'HASH',
    "get_multisected_outputs() returned hash reference");
is(scalar(keys %{$multisected_outputs}), scalar(@{$target_args}),
    "get_multisected_outputs() has one element for each target");
for my $target (keys %{$multisected_outputs}) {
    my @reports = @{$multisected_outputs->{$target}};
    is(scalar(@reports), scalar(@{$this_commit_range}),
        "Array for $target has " . scalar(@{$this_commit_range}) . " elements, as expected");
    for my $r (@reports) {
        ok(test_report($r),
            "Each element is either undefined or a hash ref with expected keys");
    }
}

note("inspect_transitions()");
my $transitions = $self->inspect_transitions($rv);

is(ref($transitions), 'HASH',
    "inspect_transitions() returned hash reference");
is(scalar(keys %{$transitions}), scalar(@{$target_args}),
    "inspect_transitions() has one element for each target");
for my $target (keys %{$transitions}) {
    for my $k ( qw| newest oldest transitions | ) {
        ok(exists $transitions->{$target}->{$k},
            "Got '$k' element for '$target', as expected");
    }
    for my $k ( qw| newest oldest | ) {
        is(ref($transitions->{$target}->{$k}), 'HASH',
            "Got hashref as value for '$k' for '$target'");
        for my $l ( qw| idx md5_hex file | ) {
            ok(exists $transitions->{$target}->{$k}->{$l},
                "Got key '$l' for '$k' for '$target'");
        }
    }
    is(ref($transitions->{$target}->{transitions}), 'ARRAY',
        "Got arrayref as value for 'transitions' for $target");
    is(1, scalar(@{$transitions->{$target}->{transitions}}),
        "There was 1 transition for '$target' in the commit range");
}

__END__

my $transitions_report = write_transitions_report(
    $outputdir,
    "transitions.$compiler.pl",
    $transitions
);
note("Report: $transitions_report");

#my @arr = test_transitions_data($transitions);

#if (defined $pattern_sought) {
#    my $first_commit_with_warning = '';
#    LOOP: for my $t (@arr) {
#        my $newer = $t->{newer}->{file};
#        say "Examining $newer";
#        my @lines;
#        tie @lines, 'Tie::File', $newer or croak "Unable to Tie::File to $newer";
#        for my $l (@lines) {
#            if ($l =~ m/$quoted_pattern/) {
#                $first_commit_with_warning =
#                    $multisected_outputs->[$t->{newer}->{idx}]->{commit};
#                untie @lines;
#                last LOOP;
#            }
#        }
#        untie @lines;
#    }
#    say "Likely commit with first instance of warning is $first_commit_with_warning";
#}
#
#say STDERR "See results in:\n$transitions_report";
#say "\nFinished";

#done_testing();
__END__
