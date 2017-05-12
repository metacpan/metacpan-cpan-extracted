#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q({{$dist->name =~ s/-/::/gr}}));
};

diag(qq({{$dist->name =~ s/-/::/gr}} v${{$dist->name =~ s/-/::/gr}}::VERSION, Perl $], $^X));
