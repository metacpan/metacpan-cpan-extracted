#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use Getopt::Long   qw(GetOptions);
use MetaCPAN::API;

my %opt = (depth => 2);
GetOptions(\%opt, 'distro=s', 'depth=i') or usage();
usage() if not $opt{distro};

$| = 1;

my %data;
my %tree;

# Given a distribution, we would like to get the list of distributions,
# that are using it. (directly or indirectly)

my $mcpan = MetaCPAN::API->new;

# make sure we have a real distribution name
# my $r = $mcpan->release( distribution => $opt{distro});
# print Dumper $r;

# Given a distribution fetch the list of modules it provides and save them in data
# return the number of modules fetched
my $modules_count = get_modules_provided_by_distribution($opt{distro});
if (not $modules_count) {
    die "There were no modules in this distribution\n";
}

for my $depth (1 .. $opt{depth}) {
    # for each module in data, that has not been processed yet
    my @modules = grep { not $data{module}{$_} } keys %{ $data{module} };
    foreach my $m (@modules) {
        get_users_of_module($m);
        $data{module}{$m} = $depth;
        # fetch the distributions mentioning it and save them in data
        # for each distribution fetch the list of modules it provides
    }
}
print Dumper \%data;
exit;


# Give a distribution, list all the files in it and then extract the modules
sub get_modules_provided_by_distribution {
    my ($distro_name) = @_;

    my $mcpan = MetaCPAN::API->new;
    my $r = $mcpan->fetch( 'module/_search',
        q => "distribution:$distro_name AND status:latest AND name:*.pm",
        fields => 'path',
        size => 200,
     );
    my @modules =
        map { $_ =~ s{/}{::}g; $_ }
        map { (substr($_, 0, 4) eq 'lib/') ? substr($_, 4, -3) : substr($_, 0, -3) }
        grep { substr($_, 0, 2) ne 't/' }
        map { $_->{fields}{path} } @{ $r->{hits}{hits} };

    foreach my $m (@modules) {
        $data{module}{$m} = undef;
    }

    return scalar @modules;
}

sub get_users_of_module {
    my ($module_name) = @_;
    print "Processing module '$module_name'\n";

    # get list of distributions using this module
    my $r = $mcpan->fetch( 'release/_search',
        q => qq{release.dependency.module:"$module_name" AND release.status:latest},
        fields => 'distribution',
        size => 50,
    );
    #die Dumper $r;

    my @distributions = sort {lc $a cmp lc $b} map { $_->{fields}{distribution} } @{ $r->{hits}{hits} };
    foreach my $d (@distributions) {
        print "Found distro: $d\n";

        # use only those, that use the module in an 'important' phase
        my @dependencies = get_dependencies($d);
        if (not grep {$module_name eq $_} @dependencies) {
            print "     ... skipping (not a hard dependency)\n";
            next;
        }

        if (not $data{distribution}{$d}) {
            get_modules_provided_by_distribution($d);
            $data{distribution}{$d} = {};
        }
    }

    return;
}

sub get_dependencies {
    my ($distro_name) = @_;

    my $r = $mcpan->fetch( "release/$distro_name" );
    # list of phases I found. We only take in account some of them
    my %phases = (
        'develop'   => 0,
        'test'      => 1,
        'runtime'   => 1,
        'configure' => 1,
    );
    return map { $_->{module} }
        grep { $phases{ $_->{phase} } }
        @{ $r->{dependency} };
}

sub usage {
    print "Usage: $0 --distro Distribution-Name  [--depth N=10]\n";
    exit;
}
