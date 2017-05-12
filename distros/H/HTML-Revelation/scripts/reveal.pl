#!/usr/bin/perl

use strict;
use warnings;

use HTML::Revelation;

# -----------------------------------------------

my($reveal) = HTML::Revelation -> new
(
 caption          => 1,
 comment          => "DBIx::Admin::CreateTable's POD converted to HTML with my pod2html.pl",
 css_output_file  => '/home/ron/homepage/Perl-modules/css/CreateTable.css',
 css_url          => '/assets/css/local/CreateTable.css',
 html_output_file => '/home/ron/homepage/Perl-modules/html/CreateTable.html',
 input_file       => '/home/ron/homepage/Perl-modules/html/DBIx/Admin/CreateTable.html',
);

$reveal -> run();
