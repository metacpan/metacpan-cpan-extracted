use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.019

use Test::More tests => 3;

SKIP: {
    eval { +require Module::Runtime::Conflicts; Module::Runtime::Conflicts->check_conflicts };
    skip('no Module::Runtime::Conflicts module found', 1) if not $INC{'Module/Runtime/Conflicts.pm'};

    diag $@ if $@;
    pass 'conflicts checked via Module::Runtime::Conflicts';
}

SKIP: {
    eval { +require Moose::Conflicts; Moose::Conflicts->check_conflicts };
    skip('no Moose::Conflicts module found', 1) if not $INC{'Moose/Conflicts.pm'};

    diag $@ if $@;
    pass 'conflicts checked via Moose::Conflicts';
}

# this data duplicates x_breaks in META.json
my $breaks = {
  "Dist::Zilla::App::Command::stale" => "< 0.040",
  "Dist::Zilla::App::Command::update" => "<= 0.04",
  "Dist::Zilla::App::Command::xtest" => "< 0.029",
  "Dist::Zilla::Plugin::Author::Plicease::Tests" => "<= 2.02",
  "Dist::Zilla::Plugin::CopyFilesFromBuild" => "< 0.161230",
  "Dist::Zilla::Plugin::CopyFilesFromBuild::Filtered" => "<= 0.001",
  "Dist::Zilla::Plugin::Git" => "<= 2.036",
  "Dist::Zilla::Plugin::Keywords" => "<= 0.006",
  "Dist::Zilla::Plugin::MakeMaker::Awesome" => "< 0.22",
  "Dist::Zilla::Plugin::NameFromDirectory" => "<= 0.03",
  "Dist::Zilla::Plugin::PodWeaver" => "<= 4.006",
  "Dist::Zilla::Plugin::Prereqs::AuthorDeps" => "<= 0.005",
  "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "< 0.161170",
  "Dist::Zilla::Plugin::RepoFileInjector" => "<= 0.005",
  "Dist::Zilla::Plugin::Run" => "<= 0.035",
  "Dist::Zilla::Plugin::Test::CheckDeps" => "<= 0.013",
  "Dist::Zilla::Plugin::Test::Version" => "<= 1.05",
  "Dist::Zilla::Plugin::TrialVersionComment" => "<= 0.003"
};

use CPAN::Meta::Requirements;
use CPAN::Meta::Check 0.011;

my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

if (my @breaks = grep { defined $result->{$_} } keys %$result)
{
    diag 'Breakages found with Dist-Zilla:';
    diag "$result->{$_}" for sort @breaks;
    diag "\n", 'You should now update these modules!';
}

pass 'checked x_breaks data';
