#!perl
use strict;
use warnings;
use 5.010;
use Data::Dumper;
use feature 'signatures';
no warnings 'experimental::signatures';
use Getopt::Long;
use GitHub::RSS;

our $VERSION = '0.01';

=head1 NAME

fetch-issues.pl - fetch GitHub issues and comments into an SQLite database

=head1 SYNOPSIS

  fetch-issues.pl --user Perl --repo perl5 --dbfile=db/issues.sqlite

=head1 OPTIONS

    --token         GitHub API token
    --token-file    filename containing JSON with the GitHub API token
    --user          GitHub user of repository to fetch
    --repo          GitHub repository containing the issues and comments
    --dbfile        Name of the SQLite database to store the issues

=cut

GetOptions(
    'token=s' => \my $token,
    'token-file=s' => \my $token_file,
    'filter=s' => \my $issue_regex,
    'user=s' => \my $github_user,
    'repo=s' => \my $github_repo,
    'dbfile=s' => \my $store,
    'verbose' => \my $verbose,
);

$store //= 'db/issues.sqlite';

my $gh = GitHub::RSS->new(
    dbh => {
        dsn => "dbi:SQLite:dbname=$store",
    },
);

if( @ARGV ) {
    $gh->refetch_issues( $github_user => $github_repo, @ARGV );

} else {
    my $last_updated = $gh->last_check;
    $gh->fetch_and_store( $github_user => $github_repo, $last_updated );
    if( $verbose ) {
        if( $last_updated eq $gh->last_check ) {
            print "Up to date as of $last_updated\n";
        } else {
            print "Updated from $last_updated to " . $gh->last_check, "\n";
        };
    };
}
