#!/usr/bin/perl -w

use utf8;
use strict;
use Encode;

use HTML::MyHTML;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => "http://edition.cnn.com/2016/03/22/weather/great-barrier-reef-coral-bleaching/index.html");
my $res = $ua->request($req);

my $body = $res->content;

# init
my $myhtml = HTML::MyHTML->new(MyHTML_OPTIONS_DEFAULT, 1);
my $tree = $myhtml->new_tree();

# detect encoding
my $encoding;
$myhtml->encoding_detect($body, $encoding);

# parse
$myhtml->parse($tree, $encoding, $body);

my $list = [];
join_text($myhtml, $tree, $tree->document->child, $list) if $tree->document->child;

print join("\n", @$list);

$tree->destroy();


sub join_text {
	my ($myhtml, $tree, $node, $res) = @_;
	
	while ($node) {
		my $info = $node->info($tree);
		
		if ($info->{tag_id} == MyHTML_TAG__COMMENT ||
			$info->{tag_id} == MyHTML_TAG_STYLE ||
			$info->{tag_id} == MyHTML_TAG_SCRIPT ||
			$info->{tag_id} == MyHTML_TAG_TEXTAREA)
		{
			$node = $node->next;
			next;
		}
		
		if($info->{tag_id} == MyHTML_TAG__TEXT) {
			my $text = $node->text();
			Encode::_utf8_on($text) unless utf8::is_utf8($text);
			
			push @$res, $text unless $text =~ /^\s+$/;
		}
		
		join_text($myhtml, $tree, $node->child, $res) if $node->child;
		
		$node = $node->next;
	}
}




