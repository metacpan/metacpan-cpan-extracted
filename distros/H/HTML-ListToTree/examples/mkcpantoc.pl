#!perl
use Pod::Usage;
use LWP::Simple;
use HTML::ListToTree;
use Getopt::Long qw(:config no_ignore_case permute);
use strict;
use warnings;

my $outfile;
if ((@ARGV) && ($ARGV[0] eq '-k')) {
	shift @ARGV;
	$outfile = shift @ARGV;
}
my %tocs;
my %titles;
my $toc = '<ul>';
my @order;
my ($isfile, $page);
while (<STDIN>) {
	chop;
#
#	comment, skip it
#
	next
		if /^\s*#/;
#
#	embedded markup, accept and proceed
#
	$toc .= $_,
	next
		if /^\s*</;

	my ($pkg, $title) = split /\s*;\s*/;
	
	if (substr($pkg, 0, 1) eq '!') {
		$pkg = substr($pkg, 1);
		$isfile = 1;
	}
	else {
		$isfile = 0;
		$title ||= $pkg;
	}

	if ($isfile) {
		open INF, $pkg or die "Can't open $pkg: $!";
		my $sep = $/;
		$/= undef;
		$page = <INF>;
		close INF;
		$/= $sep;
#
#	if no title, then remove any enclosing list
#
		$page=~s/<!--[^>]*>//g;	# remove comments
		$page = $1 
			if (!$title) && ($page=~/^\s*<ul(?:\s[^>]*)?>(.*)<\/ul\s*>\s*$/);
		$toc .= $title ? "\n<li>$title\n$page\n</li>\n" : $page;
	}
	else {
		$page = get "http://search.cpan.org/perldoc?$pkg";
		warn "Unable to get CPAN docs for $pkg, skipping...\n" and next
			unless $page;
		$page = extractTOC(\$page, $pkg)
			or next;
		$toc .= "<li><a href='http://search.cpan.org/perldoc?$pkg'>$title</a>
	$page
	</li>
";
	}
	print STDERR "Added TOC for $pkg\n";
}
$toc .= '</ul>';

if ($outfile) {
	open OUTF, ">$outfile";
	print OUTF $toc, "\n";
	close OUTF;
}

my $tree = HTML::ListToTree->new(Text => $ARGV[0], Link => '', Source => $toc)
	or die $@;

my $widget = $tree->render(RootIcon => 'globe.gif', RootText => $ARGV[0])
	or die $@;

print $widget;

sub extractTOC {
	my ($src, $pkg) = @_;
	my ($toc) = ($$src=~/<div class=toc>\s*<div class='indexgroup'>\s*(.*?)<\/div>\s*<\/div>/s);
	return undef unless $toc;
	$toc=~s/\s+class='[^']+'/ /gs;
	$toc=~s/\s+>/>/gs;
	$toc=~s!(<li\s*><a [^>]+>.*?</a>)!$1</li>!gs;
	$toc=~s!</li>\s*<ul>!<ul>!gs;
	$toc=~s!</ul>\s*<li>!</ul></li>\n<li>!gs;

#
#	fixup the hrefs while we're here
#
	$toc=~s!<a href='(#[^']+)'>!<a href='http://search.cpan.org/perldoc\?$pkg$1'>!gs;
	$toc=~s!<li><a href='http://search.cpan.org/perldoc\?[^>]+>NAME</a></li>!!;
	
#	print "\n************\n$toc\n**********\n";
	return $toc;
}
