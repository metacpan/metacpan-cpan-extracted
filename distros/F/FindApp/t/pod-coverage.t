#!/usr/bin/env perl

use t::setup;

use Env qw(RELEASE_TESTING);

unless ($RELEASE_TESTING) {
    plan skip_all => "Author tests not required for installation";
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my $coverage_class = "Pod::Coverage";

my $min_pcc = 1.0;
$coverage_class = "Pod::Coverage::Careful" if eval "use Pod::Coverage::Careful; 1";
plan skip_all => "Pod::Coverage::Careful $min_pcc required for testing POD coverage"
    if $@;

my $private = [
    qr/^init$/,
    qr/^import$/,
];

my %Constraint = (

    "FindApp::Sample" => {
        # trustme => [ qr/^xyzpdq/ ],
    },

    "FindApp::Foosle" => {
        trustme => [ 
            # qr/^ Elbereth $ /x,
        ],
    }

);

my @modules = modules_in_libdirs grep { /^FindApp/ } @LIBDIRS;
print "mods are @modules\n";

plan tests => 0+@modules;

for my $module (@modules) { 
    my $private = $Constraint{$module}{private} || $private;
    my $trustme = $Constraint{$module}{trustme} || [ ];
    my $cc = $Constraint{$module}{coverage_class} || $coverage_class;
    pod_coverage_ok($module => {
        private => $private,
        trustme => $trustme,
        coverage_class => $cc,
        # nonwhitespace => 1,
    }, "pod coverage via $coverage_class on $module");
}

done_testing();

__END__
