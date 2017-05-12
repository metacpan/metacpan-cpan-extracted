#!/usr/bin/env perl
use v5.10.1;
use strict;
use warnings;
use Carp;
use Data::Dump qw(pp);
use Cwd;

use Devel::Git::MultiBisect::Opts ( qw| process_options | );
use Devel::Git::MultiBisect::Transitions;

my $cwd = cwd();

my (%args, $params, $self);
my ($first_commit, $last_commit);
my ($target_args, $full_targets);
my ($rv, $transitions);
my ($timings);

my $homedir = "/home/username";
my $perlgitdir = "$homedir/gitwork/perl";
my $outputdir = "$homedir/multisect/outputs";
$first_commit = 'v5.25.1';
$last_commit = 'd6e0ab90d221e0e0cbfcd8c68c96c721a688265f';


%args = (
    gitdir => $perlgitdir,
    workdir => $cwd,
    first => $first_commit,
    last => $last_commit,
    outputdir => $outputdir,
    configure_command => 'sh ./Configure -des -Dusedevel -Duseithreads 1>/dev/null',
    make_command => 'make test_prep 1>/dev/null 2>&1',
    test_command => 'harness',
    verbose => 1,
);
$params = process_options(%args);
$self = Devel::Git::MultiBisect::Transitions->new($params);

my $commits_range = $self->get_commits_range();
say STDERR "ZZZ: get_commits_range:";
pp($commits_range);
say STDERR "ZZZ: items in get_commits_range: ", scalar(@{$commits_range});

$target_args = [
    'lib/locale.t',
];
$full_targets = $self->set_targets($target_args);
say STDERR "AAA: set_targets";
pp($full_targets);

$rv = $self->multisect_all_targets();
say STDERR "BBB: multisect_all_targets: $rv";

$timings = $self->get_timings();
say STDERR "CCC: get_timings";
pp($timings);

$rv = $self->get_multisected_outputs();
say STDERR "DDD: get_multisected_outputs";
pp($rv);

$transitions = $self->inspect_transitions($rv);
say STDERR "EEE: inspect_transitions";
pp($transitions);

say "\nFinished";

