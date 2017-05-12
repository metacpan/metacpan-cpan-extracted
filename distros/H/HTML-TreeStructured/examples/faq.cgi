#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeStructured;
use CGI;

print <<EOF;
Content-Type: text/html

<h4>HTML::TreeStructured for FAQ</h4>
Demonstrates that one can use this module for FAQ display
<br>See "perldoc HTML::TreeStructured" for more details.
<hr>
EOF

my $q = new CGI;

my @qqq = ();
my @aaa = ();

$qqq[0] = "What is the weight?";
$aaa[0] = "It is 40 lb.";

$qqq[1] = "What is the height?";
$aaa[1] = "It is 40 in.";

$qqq[2] = "What is the color?";
$aaa[2] = "It is red";

$qqq[3] = "What are the elements?";
$aaa[3] = "Hydrogen and Oxygen";

$qqq[4] = "Is it acidic or basic?";
$aaa[4] = "It is neutral";

$qqq[5] = "What is the Young's modulus?";
$aaa[5] = "It is 3.4";

$qqq[6] = "What is the coefficient of restitution?";
$aaa[6] = "It is 1.4";

my $tree = {
	Physical => {
		$qqq[0] => {
			closed  => 1,
			$aaa[0] => {},
		},
		$qqq[1] => {
			closed  => 1,
			$aaa[1] => {},
		},
		$qqq[2] => {
			closed  => 1,
			$aaa[2] => {},
		},
	},
	Chemical => {
		$qqq[3] => {
			closed  => 1,
			$aaa[3] => {},
		},
		$qqq[4] => {
			closed  => 1,
			$aaa[4] => {},
		},
	},
	Mechanical => {
		$qqq[5] => {
			closed  => 1,
			$aaa[5] => {},
		},
		$qqq[6] => {
			closed  => 1,
			$aaa[6] => {},
		},
	},
};


my $tree_html = HTML::TreeStructured->new(
     name         => 'tree_name',
     image_path   => 'images/',
     data         => { BlaBlarium => $tree },
     title        => "FAQ",
     title_width  => 300,
)->output;

print $tree_html;
