#/usr/bin/env perl
#===============================================================================
#Last Modified:  2012/11/02
#===============================================================================
use warnings;
use strict;
use Test::More 0.96;
use Test::Differences;
use utf8;
use HTML::WikiConverter;
my $have_lwp         = eval "use LWP::UserAgent; 1";
my $have_query_param = eval "use URI::QueryParam; 1";

my $wiki;
{ local $/ = undef; local *FILE; open FILE, '<', "./t/test.wiki"; $wiki = <FILE>; close FILE }
chomp $wiki;
my $html;
{ local $/ = undef; local *FILE; open FILE, '<', "./t/test.html"; $html = <FILE>; close FILE }

my $wc = HTML::WikiConverter->new(
    dialect => 'FreeStyleWiki',
    base_uri => 'http://www.example.com/wiki/wiki.cgi',
);

sub extract_wiki_page {
    my ( $wc, $url ) = @_;
    return $have_query_param ? $url->query_param('page') : $url =~ /page\=([^&]+)/ && $1;
}

no warnings 'uninitialized';
my $converted_wiki = $wc->html2wiki(html => $html);
chomp $converted_wiki;

if ($ENV{DEBUG}) {
    open my $fh, '>', 'output.wiki' or die $!;
    print $fh $converted_wiki;
    close $fh;
#    diag "output html to output.wiki\n";
}

unified_diff;
eq_or_diff ($converted_wiki, $wiki, 'convert');

done_testing;
