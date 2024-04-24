# -*- perl -*-
# t/014-build-transitions-probe-stderr.t
use 5.14.0;
use warnings;
use Devel::Git::MultiBisect::BuildTransitions;
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
my ($first, $last, $branch, $configure_command, $test_command);
my ($git_checkout_dir, $outputdir, $rv, $this_commit_range);
my ($multisected_outputs, @invalids);
my ($probe, $probe_validated);

my $compiler = 'clang';

$git_checkout_dir = cwd();
$outputdir = tempdir( CLEANUP => 1 );
#$outputdir = tempdir(); # Permit CLEANUP only when we're set

$branch = 'blead';
$first = 'd4bf6b07402c770d61a5f8692f24fe944655d99f';
$last  = '9be343bf32d0921e5c792cbaa2b0038f43c6e463';

$configure_command =  q|sh ./Configure -des -Dusedevel|;
$configure_command   .= qq| -Dcc=$compiler |;
$configure_command   .=  q| 1>/dev/null 2>&1|;
$test_command = '';
$probe = 'stderr';

%args = (
    gitdir  => $git_checkout_dir,
    outputdir => $outputdir,
    first   => $first,
    last    => $last,
    branch  => $branch,
    configure_command => $configure_command,
    test_command => $test_command,
    verbose => 1,
    probe => $probe,
);
$params = process_options(%args);
is($params->{gitdir}, $git_checkout_dir, "Got expected gitdir");
is($params->{outputdir}, $outputdir, "Got expected outputdir");
is($params->{first}, $first, "Got expected first commit to be studied");
is($params->{last}, $last, "Got expected last commit to be studied");
is($params->{branch}, $branch, "Got expected branch");
is($params->{configure_command}, $configure_command, "Got expected configure_command");
ok(! $params->{test_command}, "test_command empty as expected");
ok($params->{verbose}, "verbose requested");

$self = Devel::Git::MultiBisect::BuildTransitions->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::BuildTransitions');
isa_ok($self, 'Devel::Git::MultiBisect');

ok(! exists $self->{targets},
    "BuildTransitions has no need of 'targets' attribute");
ok(! exists $self->{test_command},
    "BuildTransitions has no need of 'test_command' attribute");
is($self->{probe}, $probe,
    "BuildTransitions has user-provided value '$probe' for 'probe' attribute");

test_commit_range($self->get_commits_range(), $first, $last);

note("_validate_multisect_builds_args(): tested explicitly because multisect_builds() takes a long time");

$probe_validated = $self->_validate_multisect_builds_args();
is($probe_validated, $probe,
    "_validate_multisect_builds_args() returned user-provided value of $probe provided to new()");

$probe_validated = $self->_validate_multisect_builds_args( { probe => 'stderr' } );
is($probe_validated, $probe,
    "_validate_multisect_builds_args() returned user-provided value of $probe provided IRL to multisect_builds()");

$rv = $self->multisect_builds();
ok($rv, "multisect_builds() returned true value");

note("get_multisected_outputs()");

$multisected_outputs = $self->get_multisected_outputs();

is(ref($multisected_outputs), 'ARRAY',
    "get_multisected_outputs() returned array reference");
is(scalar(@{$multisected_outputs}), scalar(@{$self->{commits}}),
    "get_multisected_outputs() has one element for each commit");

note("inspect_transitions()");

my $transitions = $self->inspect_transitions();

my $transitions_report = write_transitions_report(
    $outputdir,
    "transitions.$compiler.pl",
    $transitions
);
note("Report: $transitions_report");

my @arr = test_transitions_data($transitions);

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
