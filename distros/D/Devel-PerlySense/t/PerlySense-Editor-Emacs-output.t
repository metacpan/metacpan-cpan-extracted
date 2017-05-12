#!/usr/bin/perl -w
use strict;

use Test::More tests => 7;
use Test::Exception;
use Test::Differences;

use Data::Dumper;


use lib "lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Editor::Emacs");




ok(my $oPerlySense = Devel::PerlySense->new(), "Created PerlySense object ok");
ok(
    my $oEditor = Devel::PerlySense::Editor::Emacs->new(
        oPerlySense => $oPerlySense,
        widthDisplay => 10,
    ),
    "Created Editor ok",
);



note("Elisp");

is(
    $oEditor->formatOutputDataStructure(
        rhData => {
            hej => "Baberiba",
            2   => "two",
        },
    ),
    qq{'(("2" . "two") ("hej" . "Baberiba"))},
    "Simple structure ok",
);

is(
    $oEditor->formatOutputDataStructure(
        rhData => {
            hej => [ "Ba", "beriba" ],
            2   => "two",
        },
    ),
    qq{'(("2" . "two") ("hej" . ("Ba" "beriba")))},
    "Array ref ok",
);

is(
    $oEditor->formatOutputDataStructure(
        rhData => {
            hej => { "Ba" => "beriba", Hej => "Baberiba" },
            2   => "two",
        },
    ),
    qq{'(("2" . "two") ("hej" . (("Ba" . "beriba") ("Hej" . "Baberiba"))))},
    "Array ref ok",
);




__END__

