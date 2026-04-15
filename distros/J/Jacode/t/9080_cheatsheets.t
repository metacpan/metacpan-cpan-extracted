#!/usr/bin/perl
######################################################################
#
# t/9080-cheatsheets.t - Cheat sheet quality checks for Jacode
#
# Checks all doc/jacode_cheatsheet.*.txt files for:
#   CS1  UTF-8 encoding (no raw non-UTF-8 bytes)
#   CS2  Filename pattern: jacode_cheatsheet.XX.txt
#   CS3  Known language code
#   CS4  Header: language code appears in line 2 as "(XX)"
#   CS5  Header: metacpan URL present
#   CS6  Header: author credit "INABA Hitoshi"
#   CS7  Header: author email "ina@cpan.org"
#   CS8  Install: "cpanm Jacode"
#   CS9  Usage: "use Jacode"
#   CS10 API: Jacode::convert
#   CS11 API: Jacode::getcode
#   CS12 API: Jacode::jis_inout
#   CS13 API: Jacode::get_inout
#   CS14 API: Jacode::init
#   CS15 API: Jacode::cache / nocache / flushcache
#   CS16 Encoding names: 'jis' 'sjis' 'euc' 'utf8' 'binary'
#   CS17 Options: option 'z' (h2z, half->full)
#   CS18 Options: option 'h' (z2h, full->half)
#   CS19 JIS sequences: '@' 'B' '&' 'O' 'Q' all present
#   CS20 Example: convert(\$line, 'utf8', 'sjis') present
#   CS21 Example: correct h2z option -- 'z' not 'h' in h2z example
#   CS22 Command line: -sw example
#   CS23 Command line: -Z and -H flags
#   CS24 Compat: jcode.pl mentioned
#   CS25 No stray 'h' option in h2z context (regression guard)
#   CS26 File size reasonable (>= 2000 bytes, <= 20000 bytes)
#   CS27 Line count reasonable (>= 80 lines, <= 200 lines)
#   CS28 No Windows line endings (no CR)
#   CS29 Ends with newline
#   CS30 21 language files present
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;

my @LANG_CODES = qw(BM BN EN FR HI ID JA KM KO MN MY NE SI TH TL TR TW UR UZ VI ZH);

# Count tests: CS1-CS29 per file (29 checks) x 21 files + CS30 (1 check)
my $tests_per_file = 29;
my $n_files        = scalar @LANG_CODES;
my $total          = $tests_per_file * $n_files + 1;

print "1..$total\n";

my $test_num = 0;

sub ok {
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
my $t_dir  = File::Basename::dirname(__FILE__);
my $doc_dir = "$t_dir/../doc";

#---------------------------------------------------------------------
# CS30: exactly 21 language files present
#---------------------------------------------------------------------
{
    my @found = ();
    if (opendir(DOC_DIR, $doc_dir)) {
        @found = grep { /^jacode_cheatsheet\.[A-Z]{2}\.txt$/ } readdir(DOC_DIR);
        closedir(DOC_DIR);
    }
    ok( scalar(@found) == $n_files,
        "CS30 doc/ contains exactly $n_files jacode_cheatsheet.XX.txt files (found " . scalar(@found) . ")" );
}

#---------------------------------------------------------------------
# Per-file checks CS1-CS29
#---------------------------------------------------------------------
for my $lang (@LANG_CODES) {
    my $fname   = "jacode_cheatsheet.$lang.txt";
    my $path    = "$doc_dir/$fname";

    #------------------------------------------------------------------
    # CS2: filename pattern
    #------------------------------------------------------------------
    ok( $fname =~ /^jacode_cheatsheet\.[A-Z]{2}\.txt$/,
        "$lang CS2  filename pattern jacode_cheatsheet.XX.txt" );

    #------------------------------------------------------------------
    # CS3: known language code
    #------------------------------------------------------------------
    my %known = map { $_ => 1 } @LANG_CODES;
    ok( $known{$lang},
        "$lang CS3  language code '$lang' is in known-languages list" );

    #------------------------------------------------------------------
    # Read file (binary for CS1, then UTF-8 decode for the rest)
    #------------------------------------------------------------------
    my $raw     = '';
    my $content = '';
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
    # Strategy: try to match the entire file as a sequence of valid
    # UTF-8 code points.  Works on Perl 5.005_03 without Encode.
    #------------------------------------------------------------------
    {
        my $copy = $raw;
        # Remove all valid UTF-8 sequences; anything left is invalid.
        $copy =~ s/[\x00-\x7F]//g;                          # US-ASCII
        $copy =~ s/[\xC2-\xDF][\x80-\xBF]//g;               # 2-byte
        $copy =~ s/[\xE0-\xEF][\x80-\xBF]{2}//g;            # 3-byte
        $copy =~ s/[\xF0-\xF4][\x80-\xBF]{3}//g;            # 4-byte
        ok( $file_ok && length($copy) == 0,
            "$lang CS1  file is valid UTF-8" );
    }

    # Decode raw bytes as UTF-8 string for text checks
    # (simple: treat as Latin-1 overlay; exact match strings are ASCII
    #  or will be embedded as UTF-8 literals in this source file)
    $content = $raw;

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
    ok( $content =~ m{metacpan\.org/dist/Jacode},
        "$lang CS5  metacpan URL present" );

    #------------------------------------------------------------------
    # CS6: author credit
    #------------------------------------------------------------------
    ok( $content =~ /INABA Hitoshi/,
        "$lang CS6  author 'INABA Hitoshi' present" );

    #------------------------------------------------------------------
    # CS7: author email
    #------------------------------------------------------------------
    ok( $content =~ /ina\@cpan\.org/,
        "$lang CS7  author email 'ina\@cpan.org' present" );

    #------------------------------------------------------------------
    # CS8: install command
    #------------------------------------------------------------------
    ok( $content =~ /cpanm Jacode/,
        "$lang CS8  install command 'cpanm Jacode' present" );

    #------------------------------------------------------------------
    # CS9: use Jacode
    #------------------------------------------------------------------
    ok( $content =~ /use Jacode/,
        "$lang CS9  'use Jacode' present" );

    #------------------------------------------------------------------
    # CS10: Jacode::convert
    #------------------------------------------------------------------
    ok( $content =~ /Jacode::convert/,
        "$lang CS10 Jacode::convert present" );

    #------------------------------------------------------------------
    # CS11: Jacode::getcode
    #------------------------------------------------------------------
    ok( $content =~ /Jacode::getcode/,
        "$lang CS11 Jacode::getcode present" );

    #------------------------------------------------------------------
    # CS12: Jacode::jis_inout
    #------------------------------------------------------------------
    ok( $content =~ /Jacode::jis_inout/,
        "$lang CS12 Jacode::jis_inout present" );

    #------------------------------------------------------------------
    # CS13: Jacode::get_inout
    #------------------------------------------------------------------
    ok( $content =~ /Jacode::get_inout/,
        "$lang CS13 Jacode::get_inout present" );

    #------------------------------------------------------------------
    # CS14: Jacode::init
    #------------------------------------------------------------------
    ok( $content =~ /Jacode::init/,
        "$lang CS14 Jacode::init present" );

    #------------------------------------------------------------------
    # CS15: cache API (all three: cache / nocache / flushcache)
    #------------------------------------------------------------------
    ok( $content =~ /Jacode::cache/
     && $content =~ /Jacode::nocache/
     && $content =~ /Jacode::flushcache/,
        "$lang CS15 cache/nocache/flushcache present" );

    #------------------------------------------------------------------
    # CS16: all five encoding names
    #------------------------------------------------------------------
    ok( $content =~ /'jis'/
     && $content =~ /'sjis'/
     && $content =~ /'euc'/
     && $content =~ /'utf8'/
     && $content =~ /'binary'/,
        "$lang CS16 encoding names jis/sjis/euc/utf8/binary all present" );

    #------------------------------------------------------------------
    # CS17: option 'z' for h2z (half->full)
    #------------------------------------------------------------------
    ok( $content =~ /'z'.*h2z/,
        "$lang CS17 option 'z' paired with h2z description" );

    #------------------------------------------------------------------
    # CS18: option 'h' for z2h (full->half)
    #------------------------------------------------------------------
    ok( $content =~ /'h'.*z2h/,
        "$lang CS18 option 'h' paired with z2h description" );

    #------------------------------------------------------------------
    # CS19: all five JIS kanji start sequences
    #------------------------------------------------------------------
    ok( $content =~ /'\@'/
     && $content =~ /'B'/
     && $content =~ /'&'/
     && $content =~ /'O'/
     && $content =~ /'Q'/,
        "$lang CS19 JIS sequences \@/B/&/O/Q all present" );

    #------------------------------------------------------------------
    # CS20: basic conversion example
    #------------------------------------------------------------------
    ok( $content =~ /convert\(\\?\\\$line,\s*'utf8',\s*'sjis'\)/,
        "$lang CS20 convert example (utf8, sjis) present" );

    #------------------------------------------------------------------
    # CS21: h2z example uses 'z' not 'h'
    # The example line must be: convert(..., 'utf8', 'sjis', 'z')
    #------------------------------------------------------------------
    ok( $content =~ /convert\(\\?\\\$line,\s*'utf8',\s*'sjis',\s*'z'\)/,
        "$lang CS21 h2z example uses option 'z' (not 'h')" );

    #------------------------------------------------------------------
    # CS22: -sw command line example
    #------------------------------------------------------------------
    ok( $content =~ /-sw/,
        "$lang CS22 command line -sw example present" );

    #------------------------------------------------------------------
    # CS23: -Z and -H flags in command line section
    #------------------------------------------------------------------
    ok( $content =~ /\-Z/ && $content =~ /\-H/,
        "$lang CS23 command line -Z and -H flags present" );

    #------------------------------------------------------------------
    # CS24: jcode.pl compatibility mention
    #------------------------------------------------------------------
    ok( $content =~ /jcode\.pl/,
        "$lang CS24 jcode.pl compatibility mention present" );

    #------------------------------------------------------------------
    # CS25: regression -- h2z example must NOT use option 'h'
    # i.e. no line matching: convert(...sjis', 'h')
    #------------------------------------------------------------------
    ok( $content !~ /convert\(\\?\\\$line,\s*'utf8',\s*'sjis',\s*'h'\)/,
        "$lang CS25 h2z example does not erroneously use option 'h'" );

    #------------------------------------------------------------------
    # CS26: file size reasonable
    #------------------------------------------------------------------
    my $size = length($raw);
    ok( $file_ok && $size >= 2000 && $size <= 20000,
        "$lang CS26 file size ${size}B is between 2000 and 20000 bytes" );

    #------------------------------------------------------------------
    # CS27: line count reasonable
    #------------------------------------------------------------------
    my $lines = scalar( () = $raw =~ /\n/g );
    ok( $file_ok && $lines >= 80 && $lines <= 200,
        "$lang CS27 line count $lines is between 80 and 200" );

    #------------------------------------------------------------------
    # CS28: no Windows CR line endings
    #------------------------------------------------------------------
    ok( $file_ok && $raw !~ /\r/,
        "$lang CS28 no Windows CR (\\r) in file" );

    #------------------------------------------------------------------
    # CS29: file ends with newline
    #------------------------------------------------------------------
    ok( $file_ok && $raw =~ /\n\z/,
        "$lang CS29 file ends with newline" );
}

__END__

=pod

=encoding utf8

=head1 NAME

t/9080-cheatsheets.t - Cheat sheet quality checks for Jacode

=head1 SYNOPSIS

  prove -v t/9080-cheatsheets.t

=head1 DESCRIPTION

Validates all C<doc/jacode_cheatsheet.XX.txt> files.
Checks cover encoding validity, structure, required API coverage,
correct option-letter assignments (CS17/CS18/CS21/CS25), and
file hygiene (size, line count, line endings).

=head1 TEST LABELS

  CS1   Valid UTF-8 encoding
  CS2   Filename matches jacode_cheatsheet.XX.txt
  CS3   Language code is in the known 21-language list
  CS4   Header line 2 contains (XX) language tag
  CS5   metacpan.org/dist/Jacode URL present
  CS6   Author "INABA Hitoshi" present
  CS7   Author email ina@cpan.org present
  CS8   Install command "cpanm Jacode" present
  CS9   "use Jacode" present
  CS10  Jacode::convert present
  CS11  Jacode::getcode present
  CS12  Jacode::jis_inout present
  CS13  Jacode::get_inout present
  CS14  Jacode::init present
  CS15  cache/nocache/flushcache present
  CS16  Encoding names jis/sjis/euc/utf8/binary all present
  CS17  Option 'z' paired with h2z (half->full)
  CS18  Option 'h' paired with z2h (full->half)
  CS19  JIS sequences @/B/&/O/Q all present
  CS20  Basic convert example (utf8, sjis) present
  CS21  h2z example uses option 'z'
  CS22  Command line -sw example present
  CS23  Command line -Z and -H flags present
  CS24  jcode.pl compatibility mention present
  CS25  h2z example does NOT use option 'h' (regression guard)
  CS26  File size 2000-20000 bytes
  CS27  Line count 80-200
  CS28  No Windows CR line endings
  CS29  File ends with newline
  CS30  Exactly 21 language files present in doc/

=cut
