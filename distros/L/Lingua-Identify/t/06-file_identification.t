#!/usr/bin/perl

use Test::More tests => 13 + 3 * 26;
BEGIN { use_ok('Lingua::Identify', qw/:language_identification :language_manipulation/) };

for my $language (get_all_languages()) {
    die "**** Text file for $language language not available" unless -f "t/files/$language";

    my @lang = langof_file("t/files/$language");
    is($lang[0], $language, "Checking identified language is $language.");

    if (grep { $language eq $_ } (qw"sl cs")) {
        # Harder languages
        cmp_ok($lang[1],'>','0.15', "Checking probability for $language");
    } else {
        cmp_ok($lang[1],'>','0.16', "Checking probability for $language");
    }

    cmp_ok(confidence(@lang),'>','0.51', "Checking confidence for $language");
}

# Some extra tests

my @pt = langof_file({method=>'smallwords'},'t/files/pt_big');
is($pt[0],'pt');
cmp_ok($pt[1],'>','0.14');
cmp_ok(confidence(@pt),'>','0.50');

@pt = langof_file('t/files/pt_big');
is($pt[0],'pt');
cmp_ok($pt[1],'>','0.18');
cmp_ok(confidence(@pt),'>','0.51');

@pt = langof_file('t/files/en', 't/files/pt_big');
is($pt[0],'pt');
cmp_ok($pt[1],'>','0.13');
cmp_ok(confidence(@pt),'>','0.50');

# Encoding

@pt = langof_file({encoding=>'ISO-8859-1'},'t/files/pt_lt1');
is($pt[0],'pt');
cmp_ok($pt[1],'>','0.16');
cmp_ok(confidence(@pt),'>','0.51');
