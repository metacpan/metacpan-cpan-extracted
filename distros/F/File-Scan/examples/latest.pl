#!/usr/bin/perl
#############################################################################
#
# Get the most recent version of File::Scan module from CPAN
# Last Change: Sat Jan  4 16:42:17 WET 2003
# Copyright (c) 2005 Henrique Dias <hdias@aesbuc.pt>
#
#############################################################################
use strict;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

my $VERSION = "0.01";

my $module = "File::Scan";
my $dir = "";
my $cpan = "http://www.cpan.org/authors/id/H/HD/HDIAS";
my $url = "http://search.cpan.org/search?mode=module&format=xml&query=$module";

&main();

sub main {
	my $content = &get_content($url);
	$content =~ /<VERSION>(\d+\.\d+)<\/VERSION>/i;
	my $file = "File-Scan-$1.tar.gz";
	&save($file, &get_content("$cpan/$file"));
	exit(0);
}

sub save {
	my $file = shift;
	my $content = shift;

	$file = "$dir/$file" if($dir);
	open(FILE, ">$file") or die("$!");
	binmode(FILE);
	print FILE $content;
	close(FILE);
	return();
}

sub get_content {
	my $url = shift;

	my $req = HTTP::Request->new(GET => $url);
	my $ua = LWP::UserAgent->new();
	my $response = $ua->request($req);
	if($response->is_error()) {
		print $response->status_line . "\n";
		exit(0);
	}
	my $content = $response->content();
	return($content);
}
