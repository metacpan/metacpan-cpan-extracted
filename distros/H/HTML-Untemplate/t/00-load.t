#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(HTML::Untemplate));
};

diag(qq(HTML::Untemplate v$HTML::Untemplate::VERSION, Perl $], $^X));
