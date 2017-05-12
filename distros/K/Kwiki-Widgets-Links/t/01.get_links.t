#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Kwiki::Test;
use Kwiki::Widgets::Links;
use Test::More;

plan tests => 9;

my $kwiki = Kwiki::Test->new->init(['Kwiki::Widgets::Links']);

my %links = @{$kwiki->hub->config->widgets_links};
ok($links{Kwiki} eq 'http://kwiki.org');
ok($links{Perl}  eq 'http://perl.org');
ok($links{CPAN}  eq 'http://cpan.org');

my @links = $kwiki->hub->widgets_links->get_links;
ok($links[0]{title} eq "Kwiki");
ok($links[1]{title} eq "Perl");
ok($links[2]{title} eq "CPAN");
ok($links[0]{url} eq "http://kwiki.org");
ok($links[1]{url} eq "http://perl.org");
ok($links[2]{url} eq "http://cpan.org");


$kwiki->cleanup;
