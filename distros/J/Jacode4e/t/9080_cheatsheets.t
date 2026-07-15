#!/usr/bin/perl
######################################################################
#
# t/9080_cheatsheets.t - Cheat sheet quality checks for Jacode4e
#
# Checks all doc/jacode4e_cheatsheet.*.txt files for:
#   CS1  UTF-8 encoding (no raw non-UTF-8 bytes)
#   CS2  Filename pattern: jacode4e_cheatsheet.XX.txt
#   CS3  Known language code
#   CS4  Header: language code appears in line 2 as "(XX)"
#   CS5  Header: metacpan URL present
#   CS6  Header: author credit "INABA Hitoshi"
#   CS7  Header: author email "ina.cpan@gmail.com"
#   CS8  Usage: "use Jacode4e"
#   CS9  API: Jacode4e::convert
#   CS10 Encoding mnemonics: cp932x cp932ibm cp932nec sjis2004
#   CS11 Encoding mnemonics: cp00930 keis78 keis83 keis90
#   CS12 Encoding mnemonics: jef jef9p jipsj jipse letsj
#   CS13 Encoding mnemonics: sjis euc jis utf8 utf8.1 utf8jp
#   CS14 Option: INPUT_LAYOUT
#   CS15 Option: OUTPUT_SHIFTING
#   CS16 Option: SPACE
#   CS17 Option: GETA
#   CS18 Option: OVERRIDE_MAPPING
#   CS19 Round-trip documented: ROUND_TRIP option mentioned
#   CS20 File size reasonable (>= 2000 bytes, <= 20000 bytes)
#   CS21 Line count reasonable (>= 60 lines, <= 200 lines)
#   CS22 No Windows line endings (no CR)
#   CS23 Ends with newline
#   CS24 21 language files present
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;

my @LANG_CODES = qw(BM BN EN FR HI ID JA KM KO MN MY NE SI TH TL TR TW UR UZ VI ZH);

# Count tests: CS1-CS23 per file (23 checks) x 21 files + CS24 (1 check)
my $tests_per_file = 23;
my $n_files        = scalar @LANG_CODES;
my $total          = $tests_per_file * $n_files + 1;

print "1..$total\n";

my $test_num = 0;

sub ok ($$) {
    my ($cond, $label) = @_;
    $test_num++;
    if ($cond) {
        print "ok $test_num - $label\n";
    }
    else {
        print "not ok $test_num - $label\n";
    }
}

#---------------------------------------------------------------------
# Locate doc/ directory relative to this test file
#---------------------------------------------------------------------
use File::Basename;
my $t_dir   = File::Basename::dirname(__FILE__);
my $doc_dir = "$t_dir/../doc";

#---------------------------------------------------------------------
# CS24: exactly 21 language files present
#---------------------------------------------------------------------
{
    my @found = ();
    if (opendir(DOC_DIR, $doc_dir)) {
        @found = grep { /^jacode4e_cheatsheet\.[A-Z]{2}\.txt$/ } readdir(DOC_DIR);
        closedir(DOC_DIR);
    }
    ok( scalar(@found) == $n_files,
        "CS24 doc/ contains exactly $n_files jacode4e_cheatsheet.XX.txt files (found " . scalar(@found) . ")" );
}

#---------------------------------------------------------------------
# Per-file checks CS1-CS23
#---------------------------------------------------------------------
for my $lang (@LANG_CODES) {
    my $fname = "jacode4e_cheatsheet.$lang.txt";
    my $path  = "$doc_dir/$fname";

    #------------------------------------------------------------------
    # CS2: filename pattern
    #------------------------------------------------------------------
    ok( $fname =~ /^jacode4e_cheatsheet\.[A-Z]{2}\.txt$/,
        "$lang CS2  filename pattern jacode4e_cheatsheet.XX.txt" );

    #------------------------------------------------------------------
    # CS3: known language code
    #------------------------------------------------------------------
    my %known = map { $_ => 1 } @LANG_CODES;
    ok( $known{$lang},
        "$lang CS3  language code '$lang' is in known-languages list" );

    #------------------------------------------------------------------
    # Read file (binary)
    #------------------------------------------------------------------
    my $raw     = '';
    my $file_ok = 0;

    if (open(CS_FH, $path)) {
        binmode(CS_FH);
        local $/ = undef;
        $raw = <CS_FH>;
        close(CS_FH);
        $file_ok = 1;
    }

    #------------------------------------------------------------------
    # CS1: valid UTF-8 (no illegal byte sequences)
    # Strategy: remove all valid UTF-8 sequences; anything left is
    # invalid.  Works on Perl 5.005_03 without Encode.
    #------------------------------------------------------------------
    {
        my $copy = $raw;
        $copy =~ s/[\x00-\x7F]//g;                          # US-ASCII
        $copy =~ s/[\xC2-\xDF][\x80-\xBF]//g;               # 2-byte
        $copy =~ s/[\xE0-\xEF][\x80-\xBF][\x80-\xBF]//g;    # 3-byte
        $copy =~ s/[\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF]//g; # 4-byte
        ok( $file_ok && length($copy) == 0,
            "$lang CS1  file is valid UTF-8" );
    }

    my $content = $raw;

    #------------------------------------------------------------------
    # CS4: header line 2 contains "(XX)"
    #------------------------------------------------------------------
    {
        my @lines = split /\n/, $content;
        my $line2 = defined($lines[1]) ? $lines[1] : '';
        ok( $line2 =~ /\(\Q$lang\E\)/,
            "$lang CS4  header line 2 contains ($lang)" );
    }

    #------------------------------------------------------------------
    # CS5: metacpan URL
    #------------------------------------------------------------------
    ok( $content =~ m{metacpan\.org/dist/Jacode4e},
        "$lang CS5  metacpan URL present" );

    #------------------------------------------------------------------
    # CS6: author credit
    #------------------------------------------------------------------
    ok( $content =~ /INABA Hitoshi/,
        "$lang CS6  author 'INABA Hitoshi' present" );

    #------------------------------------------------------------------
    # CS7: author email
    #------------------------------------------------------------------
    ok( $content =~ /ina\.cpan\@gmail\.com/,
        "$lang CS7  author email 'ina.cpan\@gmail.com' present" );

    #------------------------------------------------------------------
    # CS8: use Jacode4e
    #------------------------------------------------------------------
    ok( $content =~ /use Jacode4e/,
        "$lang CS8  'use Jacode4e' present" );

    #------------------------------------------------------------------
    # CS9: Jacode4e::convert
    #------------------------------------------------------------------
    ok( $content =~ /Jacode4e::convert/,
        "$lang CS9  Jacode4e::convert present" );

    #------------------------------------------------------------------
    # CS10-CS13: encoding mnemonics
    #------------------------------------------------------------------
    ok( $content =~ /cp932x/
     && $content =~ /cp932ibm/
     && $content =~ /cp932nec/
     && $content =~ /sjis2004/,
        "$lang CS10 mnemonics cp932x/cp932ibm/cp932nec/sjis2004 present" );

    ok( $content =~ /cp00930/
     && $content =~ /keis78/
     && $content =~ /keis83/
     && $content =~ /keis90/,
        "$lang CS11 mnemonics cp00930/keis78/keis83/keis90 present" );

    ok( $content =~ /\bjef\b/
     && $content =~ /jef9p/
     && $content =~ /jipsj/
     && $content =~ /jipse/
     && $content =~ /letsj/,
        "$lang CS12 mnemonics jef/jef9p/jipsj/jipse/letsj present" );

    ok( $content =~ /\bsjis\b/
     && $content =~ /\beuc\b/
     && $content =~ /\bjis\b/
     && $content =~ /utf8\.1/
     && $content =~ /utf8jp/,
        "$lang CS13 mnemonics sjis/euc/jis/utf8.1/utf8jp present" );

    #------------------------------------------------------------------
    # CS14-CS18: option names
    #------------------------------------------------------------------
    ok( $content =~ /INPUT_LAYOUT/,
        "$lang CS14 option INPUT_LAYOUT present" );

    ok( $content =~ /OUTPUT_SHIFTING/,
        "$lang CS15 option OUTPUT_SHIFTING present" );

    ok( $content =~ /SPACE/,
        "$lang CS16 option SPACE present" );

    ok( $content =~ /GETA/,
        "$lang CS17 option GETA present" );

    ok( $content =~ /OVERRIDE_MAPPING/,
        "$lang CS18 option OVERRIDE_MAPPING present" );

    #------------------------------------------------------------------
    # CS19: round-trip conversion is documented (ROUND_TRIP option)
    #------------------------------------------------------------------
    ok( $content =~ /ROUND_TRIP/,
        "$lang CS19 ROUND_TRIP option mentioned" );

    #------------------------------------------------------------------
    # CS20: file size reasonable
    #------------------------------------------------------------------
    ok( length($raw) >= 2000 && length($raw) <= 20000,
        "$lang CS20 file size " . length($raw) . " within 2000..20000 bytes" );

    #------------------------------------------------------------------
    # CS21: line count reasonable
    #------------------------------------------------------------------
    {
        my $n_lines = scalar(split /\n/, $content);
        ok( $n_lines >= 60 && $n_lines <= 200,
            "$lang CS21 line count $n_lines within 60..200" );
    }

    #------------------------------------------------------------------
    # CS22: no CR
    #------------------------------------------------------------------
    ok( $content !~ /\r/,
        "$lang CS22 no CR (Windows line endings)" );

    #------------------------------------------------------------------
    # CS23: ends with newline
    #------------------------------------------------------------------
    ok( $content =~ /\n$/,
        "$lang CS23 file ends with newline" );
}

__END__
