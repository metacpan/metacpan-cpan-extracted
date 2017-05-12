#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper   qw(Dumper);
use Getopt::Long   qw(GetOptions);
use MetaCPAN::API;
my $mcpan = MetaCPAN::API->new;

my %opt = (size => 2);
GetOptions(\%opt, 'distro=s', 'size=i') or usage();
usage() if not $opt{distro};

my $results = $mcpan->post(
        "/search/reverse_dependencies/$opt{distro}",
        {
            query  => { match_all => {} },
            size   => $opt{size},
            filter => {
                and => [
                    {
                        term => { 'release.status' => 'latest' },
                    },
                    {
                        term => { 'authorized' => 'true' },
                    },
                ],
            },
        },
    );

my @list =  map { $_->{_source}{distribution} } @{ $results->{hits}{hits} };
print Dumper \@list;

sub usage {
    die <<"END_USAGE";

List the distributions that are directly dependent on the given distribution.

Usage: $0 --distro Distro-Name [--size LIMIT]

    LIMIT defaults to 2
END_USAGE
}

# MetaCPAN::API call taken from Test::DependentModules of Dave Rolsky

