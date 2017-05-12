#! /usr/bin/perl -w

use strict;

use Tree::Numbered;
use Tree::Numbered::DB;
use Javascript::Menu;

use DBI;
use CGI;

my $cgi = CGI->new;

my $tree = Tree::Numbered->new('White House');
$tree->append("Ramadan");
$tree->append("Money");

Javascript::Menu->convert(tree => $tree, 
			  base_URL => 'http://www.whitehouse.gov');
$tree->deepProcess(sub {my $s = shift;
			$s->setURL($s->getURL."/infocus/" .
				   lcfirst $s->getValue . 
				   '/index.html');
		    });

my $css = Javascript::Menu->buildCSS(Javascript::Menu->reasonableCSS);

print $cgi->header(-charset => "windows-1255");
print $cgi->start_html(-xbase => "http://192.168.0.124/",
		       -encoding => "windows-1255", 
		       -lang => "he", -dir => "rtl",
		       -style => {-code => $css},
		       -script => {-language => 'Javascript',
				   -code => $tree->baseJS('rtl')});

print $cgi->div({-id => 'middle'}, $tree->getHTML(no_ie => 0));
