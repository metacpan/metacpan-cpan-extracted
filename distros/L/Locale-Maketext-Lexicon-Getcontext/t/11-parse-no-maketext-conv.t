#!perl
use utf8;
use open ":std", "OUT" => "encoding(UTF-8)";
use strict;
use warnings;
use Test::More;
use Locale::Maketext::Lexicon _auto => 0, _decode => 1, _style => "gettext",
        _disable_maketext_conversion => 1;


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
    months => {
        en => "['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']",
        fr => "['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']",
        he => "['ינואר','פברואר','מרץ','אפריל','מאי','יוני','יולי','אוגוס','ספטמבר','אוקטובר','נובמבר','דצמבר']",
        ja => "['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月']",
    },
    weekdays => {
        en => "['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']",
        fr => "['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']",
        he => "['ראשון','שני','שלישי','רביעי','חמישי','שישי','שבת']",
        ja => "['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日']",
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

