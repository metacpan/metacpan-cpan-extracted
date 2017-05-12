#!/usr/bin/env perl

use strict;
use warnings;

binmode(STDOUT, ':utf8');

use XML::Twig;

use Bench;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');


my $twig = XML::Twig->new(
	twig_handlers => {
		page => \&page_handler,
	}
);

$twig->parsefile(shift(@ARGV));

sub page_handler {
	my ($twig, $page) = @_;
	
	my $title = $page->first_child('title')->text;
	my $text = $page->first_child('revision')->first_child('text')->text;

	Bench::Article($title, $text);	
	
	$twig->purge;
} 