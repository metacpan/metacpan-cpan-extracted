#!/usr/bin/perl -w
use strict;

use Test::More tests => 14;
use Test::Exception;
use Test::Differences;

use Data::Dumper;


use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Class");
use_ok("Devel::PerlySense::Editor::Emacs");


BEGIN { -d "t" and chdir("t"); }



ok(my $oPerlySense = Devel::PerlySense->new(), "Created PerlySense object ok");
ok(
    my $oEditor = Devel::PerlySense::Editor::Emacs->new(
        oPerlySense => $oPerlySense,
        widthDisplay => undef,
    ),
    "Created Editor ok",
);


my $raItem;



$raItem = [qw/ a b /];
is(
    $oEditor->textTable($raItem, 1, sub { "($_[0])(@{$_[1]})" } ),
    "(a)(a b)\n(b)(a b)\n",
    "One item, with renderer",
);



$raItem = [];
is(
    $oEditor->textTable($raItem, 1),
    "",
    "No items, 1 col",
);
is(
    $oEditor->textTable($raItem, 10),
    "",
    "No items, 10 col",
);



$raItem = [qw/ a /];
is(
    $oEditor->textTable($raItem, 1),
    "a\n",
    "One item, single col",
);
is(
    $oEditor->textTable($raItem, 10),
    "a\n",
    "One item, very wide col",
);


$raItem = [qw/ a b /];
is(
    $oEditor->textTable($raItem, 1),
    "a\nb\n",
    "Two items, one col",
);
is(
    $oEditor->textTable($raItem, 10),
    "a b\n",
    "Two items, wide",
);

$raItem = [qw/ a b c d e f g h i j k /];
is(
    $oEditor->textTable($raItem, 5),
    "a e i
b f j
c g k
d h  \n",
    "12 Items, five cols",
);


$raItem = [qw/ abc b c d e f g h i j k /];
is(
    $oEditor->textTable($raItem, 7),
    "abc e i
b   f j
c   g k
d   h  \n",
    "12 Items with varied widths, five cols",
);



__END__

