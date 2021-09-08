# -*- perl -*-
# stderr-transitions.pl

use 5.14.0;
use warnings;
use lib (qw| /home/jkeenan/gitwork/devel-git-multibisect/lib |);
use Devel::Git::MultiBisect::Opts qw( process_options );
use Devel::Git::MultiBisect::BuildTransitions;
use Test::More;
use Carp;
use File::Spec;
use Data::Dump qw(dd pp);
use Getopt::Long;
use Tie::File;

say STDERR "Using BT version: $Devel::Git::MultiBisect::BuildTransitions::VERSION";

my ($compiler, $pattern_sought, $git_checkout_dir, $workdir, $first, $last, $branch, $configure_command,
$make_command);

GetOptions(
    "compiler=s"            => \$compiler,
    "git_checkout_dir=s"    => \$git_checkout_dir,
    "workdir=s"             => \$workdir,
    "first=s"               => \$first,
    "last=s"                => \$last,
    "branch=s"              => \$branch,
    "configure_command=s"   => \$configure_command,
    "make_command=s"        => \$make_command,
    "pattern_sought=s"      => \$pattern_sought,
) or croak("Error in command-line arguments\n");

my ($quoted_pattern, %args, $params, $self);

# Argument validation

$compiler //= 'gcc';
unless (defined $git_checkout_dir) {
    croak "Must provide value for '--git_checkout_dir' on command-line";
    unless (-d $git_checkout_dir) {
        croak "git_checkout_dir $git_checkout_dir not found";
    }
}
unless (defined $workdir) {
    croak "Must provide value for '--workdir' on command-line";
    unless (-d $workdir) {
        croak "workdir $workdir not found";
    }
}
unless (defined $workdir and -d $workdir) {
    croak "work directory $workdir not defined or not found";
}
for my $p ($first, $last) {
    croak "First and last commits (40-character SHA) must be provided on command-line"
        unless (length($p) == 40);
}
$branch //= 'blead';
$configure_command //=  q|sh ./Configure -des -Dusedevel|
                     . qq| -Dcc=$compiler|
                     .  q| 1>/dev/null 2>&1|;

if (defined $pattern_sought) {
    croak "pattern_sought, if provided, must be of non-zero length"
        unless length($pattern_sought);
    $quoted_pattern = qr/\Q$pattern_sought\E/;
}

# Prepare for Devel::Git::MultiBisect::Opts::process_options,
# then validate

%args = (
    gitdir              => $git_checkout_dir,
    workdir             => $workdir,
    first               => $first,
    last                => $last,
    branch              => $branch,
    configure_command   => $configure_command,
    verbose             => 1,
);
say STDERR '\%args';
pp(\%args);
$params = process_options(%args);
say STDERR '$params';
pp($params);
pp($quoted_pattern);

$self = Devel::Git::MultiBisect::BuildTransitions->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::BuildTransitions');
isa_ok($self, 'Devel::Git::MultiBisect');

ok(! exists $self->{targets},
    "BuildTransitions has no need of 'targets' attribute");
ok(! exists $self->{test_command},
    "BuildTransitions has no need of 'test_command' attribute");

my $this_commit_range = $self->get_commits_range();
ok($this_commit_range, "get_commits_range() returned true value");
is(ref($this_commit_range), 'ARRAY', "get_commits_range() returned array ref");
is($this_commit_range->[0], $first, "Got expected first commit in range");
is($this_commit_range->[-1], $last, "Got expected last commit in range");

# See t/011-buildtransitions.t for tests of bad values to multisect_builds()

my $rv = $self->multisect_builds( { probe => 'stderr' } );
ok($rv, "multisect_builds() returned true value");

note("get_multisected_outputs()");

my $multisected_outputs = $self->get_multisected_outputs();
pp($multisected_outputs);

is(ref($multisected_outputs), 'ARRAY',
    "get_multisected_outputs() returned array reference");
is(scalar(@{$multisected_outputs}), scalar(@{$self->{commits}}),
    "get_multisected_outputs() has one element for each commit");

note("inspect_transitions()");

my $transitions = $self->inspect_transitions();
#pp($transitions);

my $transitions_report = File::Spec->catfile($workdir, "transitions.$compiler.pl");
open my $TR, '>', $transitions_report
    or croak "Unable to open $transitions_report for writing";
my $old_fh = select($TR);
dd($transitions);
select($old_fh);
close $TR or croak "Unable to close $transitions_report after writing";

is(ref($transitions), 'HASH',
    "inspect_transitions() returned hash reference");
is(scalar(keys %{$transitions}), 3,
    "inspect_transitions() has 3 elements");
for my $k ( qw| newest oldest | ) {
    is(ref($transitions->{$k}), 'HASH',
        "Got hashref as value for '$k'");
    for my $l ( qw| idx md5_hex file | ) {
        ok(exists $transitions->{$k}->{$l},
            "Got key '$l' for '$k'");
    }
}
is(ref($transitions->{transitions}), 'ARRAY',
    "Got arrayref as value for 'transitions'");
my @arr = @{$transitions->{transitions}};
for my $t (@arr) {
    is(ref($t), 'HASH',
        "Got hashref as value for element in 'transitions' array");
    for my $m ( qw| newer older | ) {
        ok(exists $t->{$m}, "Got key '$m'");
        is(ref($t->{$m}), 'HASH', "Got hashref");
        for my $n ( qw| idx md5_hex file | ) {
            ok(exists $t->{$m}->{$n},
                "Got key '$n'");
        }
    }
}

if (defined $pattern_sought) {
    dd($quoted_pattern);
    my $first_commit_with_warning = '';
    LOOP: for my $t (@arr) {
        my $newer = $t->{newer}->{file};
        say "Examining $newer";
        my @lines;
        tie @lines, 'Tie::File', $newer or croak "Unable to Tie::File to $newer";
        for my $l (@lines) {
            if ($l =~ m/$quoted_pattern/) {
                $first_commit_with_warning =
                    $multisected_outputs->[$t->{newer}->{idx}]->{commit};
                untie @lines;
                last LOOP;
            }
        }
        untie @lines;
    }
    say "Likely commit with first instance of warning is $first_commit_with_warning";
}

say STDERR "See results in:\n$transitions_report";
say "\nFinished";

done_testing();
__END__
