#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Log::Log4perl::Layout::SimpleLayout::Multiline';

my $x = Log::Log4perl::Layout::SimpleLayout::Multiline->new;

isa_ok($x, 'Log::Log4perl::Layout::SimpleLayout::Multiline');
isa_ok($x, 'Log::Log4perl::Layout::SimpleLayout');

can_ok($x, "render");

my $formatted = $x->render("foo\nbar\n", "cat", "WARN", 1);

like( $formatted, qr/\n/, "has newlines");
unlike( $formatted, qr/^bar/m, "bar is indented" );
