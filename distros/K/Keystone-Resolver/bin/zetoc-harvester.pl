#!/usr/bin/perl

# $Id: zetoc-harvester.pl,v 1.3 2007-05-10 14:17:35 mike Exp $
#
# This is a rough and ready OpenURL harvester -- not a part of the
# production system.  It is used to provoke ZETOC into calling our
# resolver, which responds by dumping the OpenURL parameters in a file
# so we can play them back later.

use strict;
use warnings;
use URI::Escape;
use LWP;


if (@ARGV != 1) {
    print STDERR "Usage: $0 <query>\n";
    exit 1;
}

my $query = uri_escape($ARGV[0]);
my $ua = new LWP::UserAgent();
my $text = fetch($ua, $query, undef, "http://zetoc.mimas.ac.uk/zetoc/wzgw?fs=Search&any=$query&ti=&au=&isn=&date=&form=general&id=952379");
if ($text =~ /<h1>No records retrieved<\/h1>/) {
    print "$0 ($query): no hits\n";
    exit 0;
}

### We only use the first page of results (25 records)
my($count) = ($text =~ /Displaying records 1 to (\d+) of /);
die "$0 ($query): can't get count ($text)" if !defined $count;
print "found $count records\n";

my($rsn, $esn, $rn, $nr, $settags, $id) =
    map { inputValue($text, $_) } qw(rsn esn rn nr settags id);

foreach my $i (1..$count) {
    my $text2 = fetch($ua, $query, $i,
		      "http://zetoc.mimas.ac.uk/zetoc/wzgw?" .
		      makeQuery(fs => " $i ", rsn => $rsn,
				esn => $esn, rn => $rn, nr => $nr,
				settags => $settags, id => $id));
    my($openURL) = ($text2 =~ /href="(.*)">More information about/);
    die "$0 ($query) hit $i: can't get OpenURL" if !defined $openURL;
    print $openURL, "\n";

    # We don't care what this resolves to: at this stage, all we want
    # to do is provoke the resolver, so it can log the OpenURLs that
    # it's being asked to resolve.
    fetch($ua, $query, $i, $openURL);
}


sub fetch {
    my($ua, $query, $i, $url) = @_;

    my $req = new HTTP::Request(GET => $url);
    my $res = $ua->request($req);
    if (!$res->is_success()) {
	print STDERR "$0 ($query)", (defined $i ? " hit $i" : ""),
	    ": ", $res->status_line(), "\n";
	exit 2;
    }

    sleep 1;			# polite
    return $res->content();
}


sub inputValue {
    my($text, $param) = @_;

    my($value) = ($text =~ /name="$param" value="(.*)">/);
    return $value;
}


sub makeQuery {
    my $text = "";

    while (@_) {
	my $name = shift();
	my $value = shift();
	$text .= "&" if $text ne "";
	$text .= uri_escape($name) . "=" . uri_escape($value);
    }

    return $text;
}
