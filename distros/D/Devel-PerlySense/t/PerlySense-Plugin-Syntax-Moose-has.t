#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
use Test::Differences;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Meta");
use_ok("Devel::PerlySense::Document::Location");

#use Carp::Always;

my $dirData = "t/data/plugin-moose";
my $oMeta;


my $file = "Has.pm";
note("Checking has in ($file)");

my $fileOrigin = "t/data/plugin-moose/$file";
ok(
    my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()),
    "new ok",
);

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");


$oMeta = $oDocument->oMeta;
# eq_or_diff
is_deeply(
    [ @{$oMeta->raLocationSub} ],
    [
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 12,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeBareword",
                source       => q|has timeBareword => (is => "rw");|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 12,
                    col  => 33,
                ),
            },
        ),

        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 14,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeQuoted",
                source       => q|has "timeQuoted" => (
    is  => "rw",
    isa => "Int",
);|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 17,
                    col  => 3,
                ),
            },
        ),

        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 19,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeQuotedComma",
                source       => q|has "timeQuotedComma", (is => "rw");|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 19,
                    col  => 36,
                ),
            },
        ),

        #Quoted list
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 23,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeList1",
                source       => q|has ["timeList1", "timeList2"] => (
    is => "rw",
);|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 25,
                    col  => 3,
                ),
            },
        ),
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 23,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeList2",
                source       => q|has ["timeList1", "timeList2"] => (
    is => "rw",
);|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 25,
                    col  => 3,
                ),
            },
        ),

        #Quoted Word list
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 27,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeQwList1",
                source       => q|has [ qw/ timeQwList1 timeQwList2 / ] => (
    is => "ro",
);|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 29,
                    col  => 3,
                ),
            },
        ),
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 27,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeQwList2",
                source       => q|has [ qw/ timeQwList1 timeQwList2 / ] => (
    is => "ro",
);|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 29,
                    col  => 3,
                ),
            },
        ),

        #Quoted Word list with "qw" as one of the words
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 31,
            col              => 1,
            rhProperty       => {
                nameSub      => "qw",
                source       => q|has [ qw/ qw timeQwList3 / ] => (
    is => "ro",
);|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 33,
                    col  => 3,
                ),
            },
        ),
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 31,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeQwList3",
                source       => q|has [ qw/ qw timeQwList3 / ] => (
    is => "ro",
);|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 33,
                    col  => 3,
                ),
            },
        ),

        #q/name/
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 35,
            col              => 1,
            rhProperty       => {
                nameSub      => "timeSingleQuoted",
                source       => q|has q/timeSingleQuoted/ => ();|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 35,
                    col  => 30,
                ),
            },
        ),

        #"+name"
        Devel::PerlySense::Document::Location->new(
            file             => $fileOrigin,
            row              => 39,
            col              => 1,
            rhProperty       => {
                nameSub      => "timePlus",
                source       => q|has "+timePlus" => (is => "rw");|,
                namePackage  => "Has",
                oLocationEnd => Devel::PerlySense::Document::Location->new(
                    file => $fileOrigin,
                    row  => 39,
                    col  => 32,
                ),
            },
        ),
        
    ],
    " correct sub declarations",
);




__END__
