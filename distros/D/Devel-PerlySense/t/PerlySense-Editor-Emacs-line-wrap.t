#!/usr/bin/perl -w
use strict;

use Test::More tests => 12;
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
        widthDisplay => 10,
    ),
    "Created Editor ok",
);



is(
    $oEditor->textLineWrapped("12345"),
    "12345",
    "Line wrap 5 chars, no wrap",
);

is(
    $oEditor->textLineWrapped("1234567890"),
    "1234567890",
    "Line wrap 10 chars, no wrap",
);

is(
    $oEditor->textLineWrapped("1234567890a"),
    "1234567890\na",
    "Line wrap 11 chars, wrap 1",
);

is(
    $oEditor->textLineWrapped("1234567890abcdefghi"),
    "1234567890\nabcdefghi",
    "Line wrap 19 chars, wrap 9",
);

is(
    $oEditor->textLineWrapped("1234567890abcdefghij"),
    "1234567890\nabcdefghij",
    "Line wrap 20 chars, wrap two lines",
);

is(
    $oEditor->textLineWrapped("1234567890abcdefghijABC"),
    "1234567890\nabcdefghij\nABC",
    "Line wrap 20 chars, wrap two lines, plus a little",
);

is(
    $oEditor->textLineWrapped("1234567890abcdefghijABCDEFGHIJ"),
    "1234567890\nabcdefghij\nABCDEFGHIJ",
    "Line wrap 20 chars, wrap three lines",
);





__END__

