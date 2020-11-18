#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use Getopt::Long qw(GetOptions);
use MetaCPAN::API;
my $mcpan = MetaCPAN::API->new;

my $verbose = 0;
GetOptions(
    'verbose' => \$verbose,
);

my ($size, $pauseid) = @ARGV;
die "Usage: $0 N [PAUSEID]  (N = number of most recent distributions)\n" if not $size;

my $q = 'status:latest';
if ($pauseid) {
    $q .= " AND author:$pauseid";
}

my $r = $mcpan->fetch( 'release/_search',
    q => $q,
    sort => 'date:desc',
    fields => 'distribution,date,license,author,resources.repository',
    size => $size,
);

# In preparation to have a list of acceptable
# password keys. (Is this really important for the
# purposes of this script?)
my @acceptable_licenses = qw(
    agpl_3
    apache_2_0
    artistic_1
    artistic_2
    bsd
    gpl_3
    lgpl_2_1
    mit
    perl_5

    restricted
    unrestricted
);

#    freebsd
#    zlib

my %licenses;
my @missing_license;
my @missing_repo;
my %repos;
my $license_found = 0;
my $repo_found = 0;
my $hits = scalar @{ $r->{hits}{hits} };
foreach my $d (@{ $r->{hits}{hits} }) {
    my $license = $d->{fields}{license};
    my $distro  = $d->{fields}{distribution};
    my $author  = $d->{fields}{author};
    my $repo    = $d->{fields}{'resources.repository'};

    if ($license and $license ne 'unknown' and $license ne 'open_source') {
        $license_found++;
        $licenses{$license}++;
    } else {
        push @missing_license, [$distro, $author];
    }

    if ($repo and $repo->{url}) {
        $repo_found++;
        if ($repo->{url} =~ m{http://code.google.com/}) {
            $repos{google}++;
        } elsif ($repo->{url} =~ m{git://github.com/}) {
            $repos{github_git}++;
        } elsif ($repo->{url} =~ m{http://github.com/}) {
            $repos{github_http}++;
        } elsif ($repo->{url} =~ m{https://github.com/}) {
            $repos{github_https}++;
        } elsif ($repo->{url} =~ m{https://bitbucket.org/}) {
            $repos{bitbucket}++;
        } elsif ($repo->{url} =~ m{git://git.gnome.org/}) {
            $repos{git_gnome}++;
        } elsif ($repo->{url} =~ m{https://svn.perl.org/}) {
            $repos{svn_perl_org}++;
        } elsif ($repo->{url} =~ m{git://}) {
            $repos{other_git}++;
        } elsif ($repo->{url} =~ m{\.git$}) {
            $repos{other_git}++;
        } elsif ($repo->{url} =~ m{https?://svn\.}) {
            $repos{other_svn}++;
        } else {
            $repos{other}++;
            say "Other repo: $repo->{url}";
        }
    } else {
        push @missing_repo, [$distro, $author];
    }
}
@missing_license = sort {$a->[0] cmp $b->[0]} @missing_license;
@missing_repo    = sort {$a->[0] cmp $b->[0]}
	map { $_->[2] = "http://metacpan.org/release/$_->[0]"; $_ }
	@missing_repo;
say "Total asked for: $size";
say "Total received : $hits";
printf "License found: %3s, missing: %s\n", $license_found, scalar(@missing_license);
printf "Repos found:   %3s, missing: %s\n", $repo_found, scalar(@missing_repo);
say "-" x 40;
print Dumper \%repos;
print Dumper \%licenses;
if ($verbose) {
    print 'missing_licenses: ' . Dumper \@missing_license;
    print 'missing_repo: ' . Dumper \@missing_repo;
}

