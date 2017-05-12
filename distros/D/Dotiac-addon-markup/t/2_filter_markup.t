use Test::More tests=>18;
chdir "t";
no warnings;

require Dtest;
use warnings;
use strict;
use Text::Textile qw/textile/;
use Text::Markdown qw/markdown/;

my $markdown = <<EOM;
A First Level Header
====================

A Second Level Header
---------------------

Now is the time for all good men to come to
the aid of their country. This is just a
regular paragraph.

The quick brown fox jumped over the lazy
dog's back.

### Header 3

> This is a blockquote.
> 
> This is the second paragraph in the blockquote.
>
> ## This is an H2 in a blockquote
EOM

my $markdown2=markdown($markdown);

dtest("filter_markdown.html","A$markdown2"."A\n",{text=>$markdown});
my $textile = <<EOT;
h1. Heading

A _simple_ demonstration of Textile markup.

* One
* Two
* Three

"More information":http://www.textism.com/tools/textile is available.
EOT
my $textile2=textile($textile);
dtest("filter_textile.html","A$textile2"."A\n",{text=>$textile});
my $rest = <<EOR;
=====
Title
=====


Titles are underlined (or over-
and underlined) with a printing
nonalphanumeric 7-bit ASCII
character.

- This is item 1
- This is item 2 

EOR
SKIP: {
	eval {
		require Text::Restructured::Writer;
		require Text::Restructured::DOM;		
		1;
	} or skip("Text::Restructured not installed",6);
	my $restmaker=sub {
		my $w=$^W;
		$^W=0;
		my $writer = new Text::Restructured::Writer('html',{w=>'html',d=>0,D=>{}});
		my $value=shift;
		my $dom;
		if ($value =~ /^<document/) {
			$dom = Text::Restructured::DOM::Parse($value, {w=>'html',d=>0,D=>{}});
		}
		else {
			require Text::Restructured;
			my $rst_parser = new Text::Restructured({w=>'html',d=>0,D=>{}}, "1 release 1");
			$dom = $rst_parser->Parse($value, tmpnam());
		}
		my $x=$writer->ProcessDOM($dom);
		$^W=$w;
		$x=substr $x,index($x,"<body>")+6;
		$x=substr $x,0,index($x,"<div class=\"footer\"");
		return $x;
	};	
	my $rest2=$restmaker->($rest);
	dtest("filter_restructuredtext.html","A$rest2"."A\n",{text=>$rest}); 
}
