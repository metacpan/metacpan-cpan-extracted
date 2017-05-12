#!/usr/bin/perl -w
use strict;

use Test::More tests => 17;
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


$raItem = [];
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 1),
    [ ],
    "No items, one group",
);
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 2),
    [ ],
    "No items, two groups",
);



$raItem = [qw/ a /];
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 1),
    [ ["a"] ],
    "One item, one group",
);
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 2),
    [ ["a"] ],
    "One item, two groups",
);
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 3),
    [ ["a"] ],
    "One item, three groups",
);



$raItem = [qw/ a b /];
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 1),
    [ ["a", "b"] ],
    "Two items, one group",
);
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 2),
    [ ["a"], ["b"] ],
    "Two items, two groups",
);
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 3),
    [ ["a"], ["b"] ],
    "Two items, three groups",
);


$raItem = [qw/ a b c d e f g h i j k /];
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 1),
    [ [qw/ a b c d e f g h i j k /] ],
    "11 Items, one group",
);
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 2),
    [ [qw/ a b c d e f /], [qw/ g h i j k /] ],
    "11 Items, two groups",
);
eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 3),
    [ [qw/ a b c d /], [qw/ e f g h /], [qw/ i j k /] ],
    "11 Items, three groups",
);

eq_or_diff(
    $oEditor->raItemInNGroups($raItem, 4),
    [ [qw/ a b c /], [qw/ d e f /], [qw/ g h i /], [qw/ j k /] ],
    "11 Items, four group",
);




__END__

