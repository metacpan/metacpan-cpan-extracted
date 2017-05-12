#!/usr/bin/perl
#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

use lib "../lib","examples";

$|++;

use HTML::FormFu::ExtJS;
use File::Find;
use Carp;
use warnings;
use strict;

require "template_extjs.pl";
require "template_html.pl";

croak "Couldn't find directory 'forms'. Run as 'perl -Ilib examples/create.pl'" unless(-d "examples/forms");

my @forms;

sub wanted {
	push(@forms, $_) if ($_ =~ /\.yml$/);
}

find(\&wanted, "examples/forms");

find(sub { unlink if($_ =~ /\.html$/) }, "examples/html");

for(@forms) {
	my $title = $_;
	$title  =~ s/\.yml//;
	print "Creating $title... ";
	my $form = new HTML::FormFu;
	$form->load_config_file("examples/forms/".$title.".yml");
	$form->process;
	open(FILE, ">examples/html/".$title."-html.html");
	print FILE render_html(form => $title, html => $form->render);
	close(FILE);
	$form = new HTML::FormFu::ExtJS;
	$form->load_config_file("examples/forms/".$title.".yml");
	open(FILE, ">examples/html/".$title."-extjs.html");
	print FILE render_extjs(form => $title, html => $form->render(title => "HTML::FormFu::ExtJS - $title", frame => \1, width => 800));
	close(FILE);
	print "done".$/;
}