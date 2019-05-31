#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf;

my $where = __FILE__;
$where = "./$where" unless $where =~ /^\//;

my @nonvoid = (
    do "$where.1.psgi",
    do "$where.2.psgi",
);

push @nonvoid, neaf->run;
my @known = sort keys %{ neaf->get_routes };
is_deeply \@known, [ '/file/1', '/file/2' ], "route loaded via resources"
    or diag "Found routes: @known";

lives_ok {
    push @nonvoid, neaf->run;
} "reload doesn't die";

my @content = neaf->run_test('/file/1');
is $content[0], 200, "http ok";
is $content[2], "Foo bar", "data from static file returned";

done_testing;

__DATA__
# empty
