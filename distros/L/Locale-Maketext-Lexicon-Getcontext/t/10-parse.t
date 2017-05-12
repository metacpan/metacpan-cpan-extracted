#!perl
use utf8;
use open ":std", "OUT" => "encoding(UTF-8)";
use strict;
use warnings;
use Test::More;
use Locale::Maketext::Lexicon _auto => 0, _decode => 1, _style => "gettext";


opendir my $dh, "t/po/off-common/"
    or die "can't read directory 't/po/off-common/': $!";
my @files = map "t/po/off-common/$_", grep {!/^\./} readdir $dh;
closedir $dh;

my %field = (
    ":langname" => {
        en  => "English",
        fr  => "French",
        he  => "Hebrew",
        ja  => "Japanese",
    },
    error_reset_already_connected => {
        en  => "You are already signed in.",
        fr  => "Vous avez déjà une session ouverte.",
        he  => "כבר נכנסת.",
        ja  => undef,
    },
    ingredients => {
        en  => "Ingredients",
        fr  => "Ingrédients",
        he  => "רכיבים",
        ja  => "材料",
    },
    multiline_msgid => {
	en => "Pouet pouetPouet",
    },
);

plan tests => 1 + @files * (2 + keys %field);

my $module = "Locale::Maketext::Lexicon::Getcontext";

use_ok $module;

for my $file (@files) {
    # read & parse the .po
    open my $fh, "<", $file or die "can't read file '$file': $!";

    my $lexicon = eval { $module->parse(<$fh>) };
    is $@, "", "$module->parse(<$file>)";

    close $fh;

    # check some fields
    my ($lc) = $file =~ m:/([a-z]+)\.po$:;
    is $lexicon->{":langtag"}, $lc, ":langtag = $lc";

    for my $field (sort keys %field) {
        is $lexicon->{$field}, $field{$field}{$lc},
            "$field = " . ($field{$field}{$lc} // "<undef>");
    }
}

