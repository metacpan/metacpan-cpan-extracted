use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.018

use Test::More tests => 2;

SKIP: {
    skip 'no conflicts module found to check against', 1;
}

# this data duplicates x_breaks in META.json
my $breaks = {
  "Dist::Zilla::App::CommandHelper::ChainSmoking" => "<= 1.04"
};

use CPAN::Meta::Requirements;
use CPAN::Meta::Check 0.011;

my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

if (my @breaks = grep { defined $result->{$_} } keys %$result)
{
    diag 'Breakages found with Dist-Zilla-Plugin-Git:';
    diag "$result->{$_}" for sort @breaks;
    diag "\n", 'You should now update these modules!';
}

pass 'checked x_breaks data';
