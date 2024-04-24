# -*- perl -*-
# t/012-build-transitions-probe-error.t
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
    plan tests => 63;
}
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use lib qw( t/lib );
use Helpers qw(
    test_report
    test_commit_range
    test_transitions_data
);
use Data::Dump;

my $startdir = cwd();

chdir $ENV{PERL_GIT_CHECKOUT_DIR}
    or croak "Unable to change to perl checkout directory";

my (%args, $params, $self);
my ($first, $last, $branch, $configure_command, $test_command);
my ($git_checkout_dir, $outputdir, $rv, $this_commit_range);
my ($multisected_outputs, @invalids);
my ($default_probe, $probe_validated, $set_probe);
my $compiler = 'clang';

$git_checkout_dir = cwd();
$outputdir = tempdir( CLEANUP => 1 );
#$outputdir = tempdir(); # Permit CLEANUP only when we're set

#$first = 'ab340fffd3aab332a1b31d7cf502274d67d1d4a5';
#$last =  'b54ed1c793fbfd1e9a6bdf117dea77bfac8ba4a4';
#$branch = 'blead';

$branch = 'squash-multibisect-probe-errors-retain-20210827';
$first = '2623ca3c173506cabaa0bad66c0e8ed775985f19';
$last =  '17053877bc526a49bfb8d3974b2ca7528c151b3e';

$configure_command = 'sh ./Configure -des -Dusedevel';
$configure_command   .= " -Dcc=$compiler -Accflags=-DPERL_GLOBAL_STRUCT";
$configure_command   .= ' 1>/dev/null 2>&1';
$test_command = '';

%args = (
    gitdir  => $git_checkout_dir,
    outputdir => $outputdir,
    first   => $first,
    last    => $last,
    branch  => $branch,
    configure_command => $configure_command,
    test_command => $test_command,
    verbose => 1,
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
is($self->{probe}, 'error',
    "BuildTransitions has default 'probe' attribute: error");

test_commit_range($self->get_commits_range(), $first, $last);

note("Test for bad arguments to multisect_builds()");

{
    local $@;
    eval { $rv = $self->multisect_builds( [ qw( probe error ) ] ); };
    like($@, qr/Argument passed to multisect_builds\(\) must be hashref/,
        "Got expected error for bad argument to multisect_builds()");
}

{
    local $@;
    my $bad_key = 'foo';
    eval { $rv = $self->multisect_builds( { $bad_key => 'bar' } ); };

    like($@, qr/\QInvalid key '$bad_key' in hashref passed to multisect_builds()\E/,
        "Got expected error for bad argument to multisect_builds()");
}

{
    local $@;
    my $bad_value = 'foo';
    eval { $rv = $self->multisect_builds( { probe => $bad_value } ); };

    like($@, qr/\QInvalid value '$bad_value' in 'probe' element in hashref passed to multisect_builds()\E/,
        "Got expected error for bad argument to multisect_builds()");
}

note("_validate_multisect_builds_args(): tested explicitly because multisect_builds() takes a long time");

$default_probe = 'error';

$probe_validated = $self->_validate_multisect_builds_args();
is($probe_validated, $default_probe,
    "_validate_multisect_builds_args() returned default value of $default_probe");
is($self->{probe}, $probe_validated,
    "'probe' set to default value of $default_probe");

$set_probe = 'error';
$probe_validated = $self->_validate_multisect_builds_args( { probe => $set_probe } );
is($probe_validated, $set_probe,
    "_validate_multisect_builds_args() returned set value of $set_probe");
is($self->{probe}, $probe_validated,
    "'probe' set to value of $default_probe");

note("multisect_builds, probing for C-level errors");

$rv = $self->multisect_builds( { probe => 'error' } );
ok($rv, "multisect_builds() returned true value");

note("get_multisected_outputs()");

$multisected_outputs = $self->get_multisected_outputs();
is(ref($multisected_outputs), 'ARRAY',
    "get_multisected_outputs() returned array reference");
is(scalar(@{$multisected_outputs}), scalar(@{$self->{commits}}),
    "get_multisected_outputs() has one element for each commit");
@invalids = ();
for my $r (@{$multisected_outputs}) {
    if (! test_report($r)) {
        push @invalids, $r;
    }
}
if (@invalids) {
    fail("Expectation as to elements not met");
    Data::Dump::pp(\@invalids);
}
else {
    pass("Each element is either undefined or a hash ref with expected keys");
}

note("inspect_transitions()");

my $transitions = $self->inspect_transitions();

my $transitions_report = write_transitions_report(
    $outputdir,
    "transitions.$compiler.pl",
    $transitions
);
note("Report: $transitions_report");

my @arr = test_transitions_data($transitions);
is(scalar(@arr), 2, "Observed 2 older/newer transitions, as expected");

# clean up

chdir $startdir or croak "Unable to return to $startdir";

__END__
