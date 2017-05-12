#!/usr/bin/perl

use strict;
use warnings;

use lib qw(lib t/lib);

use Test::More qw(no_plan);

use IkiWiki;
use IkiWiki::Plugin::syntax;

my  $source = <<EOF;
int i = 1;
int j = 2;

sumar( i, j);

int sumar( int a, int b)
{
    return a + b;
}
EOF

$IkiWiki::config{syntax_engine} = q(Kate);
IkiWiki::Plugin::syntax::checkconfig();

eval {
    my $output = IkiWiki::Plugin::syntax::preprocess( 
                engine      =>      q(Kate),
                language    =>      q(c),
                text        =>      $source,
                linenumbers =>      1
            );
        };

if ($@) {
    fail("preprocess C source code");
}
else {
    pass("preprocess C source code");
}

