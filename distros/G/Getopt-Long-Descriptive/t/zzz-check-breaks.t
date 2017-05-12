use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.016

use Test::More tests => 1;

SKIP: {
    eval 'require Moose::Conflicts; Moose::Conflicts->check_conflicts';
    skip('no Moose::Conflicts module found', 1) if not $INC{'Moose/Conflicts.pm'};

    diag $@ if $@;
    pass 'conflicts checked via Moose::Conflicts';
}

# this data duplicates x_breaks in META.json
my $breaks = {
  "MooseX::Getopt" => "< 0.66"
};

use CPAN::Meta::Requirements;
use CPAN::Meta::Check 0.011;

my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

if (my @breaks = grep { defined $result->{$_} } keys %$result)
{
    diag 'Breakages found with Getopt-Long-Descriptive:';
    diag "$result->{$_}" for sort @breaks;
    diag "\n", 'You should now update these modules!';
}
