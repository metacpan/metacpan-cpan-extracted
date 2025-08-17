use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.020

use Test::More tests => 2;
use Term::ANSIColor 'colored';

SKIP: {
    skip 'no conflicts module found to check against', 1;
}

# this data duplicates x_breaks in META.json
my $breaks = {
  "JSON::Schema::Modern::Document::OpenAPI" => "< 0.091",
  "JSON::Schema::Modern::Vocabulary::OpenAPI" => "< 0.080",
  "Mojolicious::Plugin::OpenAPI::Modern" => "< 0.014",
  "OpenAPI::Modern" => "< 0.077",
  "Test::Mojo::Role::OpenAPI::Modern" => "< 0.007"
};

use CPAN::Meta::Requirements;
use CPAN::Meta::Check 0.011;

my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

if (my @breaks = grep defined $result->{$_}, keys %$result) {
    diag colored('Breakages found with JSON-Schema-Modern:', 'yellow');
    diag colored("$result->{$_}", 'yellow') for sort @breaks;
    diag "\n", colored('You should now update these modules!', 'yellow');
}

pass 'checked x_breaks data';
