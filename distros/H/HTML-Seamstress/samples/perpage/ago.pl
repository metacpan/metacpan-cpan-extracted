#!/usr/bin/perl

use strict;
use warnings;

use lib '.';

use html::abstract::homepage;

my $page_object = html::abstract::homepage->new;
warn $page_object;
$page_object->process;

print $page_object->as_HTML(undef, ' ');


use html::abstract::productpage;

my $page_object = html::abstract::productpage->new;
$page_object->process;
print $page_object->as_HTML(undef, ' ');

