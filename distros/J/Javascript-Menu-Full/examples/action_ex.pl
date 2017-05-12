#! /usr/bin/perl -w

use strict;

use Tree::Numbered;
use Tree::Numbered::DB;
use Javascript::Menu;

use DBI;
use CGI;

my $cgi = CGI->new;

my $action = sub {
    my $self = shift;
    my ($level, $unique) = @_;

    my $value = $self->getValue;
    return "document.getElementById('caption_${unique}').innerHTML='$value';";
};

my $tree2 = Javascript::Menu->new(value => 'root', action => $action);
$tree2->append(value => 'first');
$tree2->append(value => 'second');
$tree2->nextNode->append(value => 'child1');

my $css = Javascript::Menu->buildCSS(Javascript::Menu->reasonableCSS);

print $cgi->header(-charset => "windows-1255");
print $cgi->start_html(-xbase => "http://192.168.0.124/",
		       -encoding => "windows-1255", 
		       -lang => "he", -dir => "rtl",
		       -style => {-code => $css},
		       -script => {-language => 'Javascript',
				   -code => $tree2->baseJS('rtl')});

print $cgi->div({-id => 'middle'}, $tree2->getHTML(no_ie => 0));
