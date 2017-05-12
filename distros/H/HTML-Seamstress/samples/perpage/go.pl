#!/usr/bin/perl

use strict;
use warnings;

use lib '.';

use html::homepage;

my $page_object = html::homepage->new;
$page_object->process;

print $page_object->as_HTML(undef, ' ');

use html::productpage;

my $page_object = html::productpage->new;
$page_object->process;
print $page_object->as_HTML(undef, ' ');
