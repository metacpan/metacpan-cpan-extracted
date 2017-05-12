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
# is normally if parse thread only one, otherwise use single mode MyHTML_OPTIONS_PARSE_MODE_SINGLE
# or methods parse_single, parse_fragment_single, parse_chunk_single, parse_chunk_fragment_single
# for development use single mode, it will be easier to debug
my $myhtml = HTML::MyHTML->new(MyHTML_OPTIONS_DEFAULT, 1);
my $tree = $myhtml->new_tree();

# detect encoding
my $encoding;
$myhtml->encoding_detect($body, $encoding);

my $args = {count => 0};

$tree->callback_before_token_done_set(sub {
   my ($tree, $token_node, $ctx) = @_;
   use bytes;
   
   $ctx->{count}++;
   
   my $info = $token_node->info($tree);
   
	my $str = substr $body, $info->{element_begin}, $info->{element_length};
	print $str, "\n";
	
}, $args);

# parse
$myhtml->parse($tree, $encoding, $body);

print "Total count: ", $args->{count}, "\n";
