#!/usr/bin/env perl

BEGIN {
    binmode STDOUT, ':encoding(utf8)';
    binmode STDERR, ':encoding(utf8)';
}

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Gcis::Client;
use Test::More qw/no_plan/;
use v5.14;
no warnings 'uninitialized';

sub usage { die "Usage : $0 [<url>]\n"; }

my $url = shift @ARGV || "http://localhost:3000";

my $c = Gcis::Client->new->url($url);
my $d = Gcis::Client->new->accept("application/vnd.citationstyles.csl+json;q=0.5")
                          ->url("http://dx.doi.org");

sub check_doi {
    my $doi = shift;
    my $gcis = $c->get("/article/$doi") or die "Article $doi not found in gcis.";
    $gcis->{journal} = $c->get("/journal/$gcis->{journal_identifier}");
    my $crossref = $d->get("/$doi");
    my $url = $c->url."/article/$doi";
    ok keys %$crossref, "Found DOI : $doi";
    SKIP: {
        skip "Missing crossref data for $url", 4 unless keys %$crossref;
        is $gcis->{title},          $crossref->{title},  "title" or diag $url;
        is $gcis->{journal_vol},    $crossref->{volume}, "volume" or diag $url;
        is $gcis->{year},           $crossref->{issued}{'date-parts'}[0][0], "year" or diag $url;
        is $gcis->{journal}{title}, $crossref->{'container-title'}, "journal title" or diag $url;
    }
}

my $max = 10;
my $count = 1;
for my $article ($c->get("/article")) {
    my $doi = $article->{doi} or next;
    check_doi($doi);
    last if $count++>$max;
} continue {
    diag "skip : ".$article->{identifier} unless $article->{doi};
}



