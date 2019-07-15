package jacode;
$support_jcode_package_too = 1;
######################################################################
#
# jacode.pl: Perl program for Japanese character code conversion
#
# Copyright (c) 2010, 2011, 2014, 2015, 2016, 2017, 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# The latest version is available here:
#
#   http://search.cpan.org/dist/jacode/
#
# *** ATTENTION ***
# This software is not "jcode.pl"
# Thus don't redistribute this software renaming as "jcode.pl"
# Moreover, this software IS NOT "jacode4e.pl"
# If you want "jacode4e.pl", search it on CPAN again.
#
# Original version `jcode.pl' is ...
#
# Copyright (c) 2002 Kazumasa Utashiro
# http://web.archive.org/web/20090608090304/http://srekcah.org/jcode/
#
# Copyright (c) 1995-2000 Kazumasa Utashiro <utashiro@iij.ad.jp>
# Internet Initiative Japan Inc.
# 3-13 Kanda Nishiki-cho, Chiyoda-ku, Tokyo 101-0054, Japan
#
# Copyright (c) 1992,1993,1994 Kazumasa Utashiro
# Software Research Associates, Inc.
#
# Use and redistribution for ANY PURPOSE are granted as long as all
# copyright notices are retained.  Redistribution with modification
# is allowed provided that you make your modified version obviously
# distinguishable from the original one.  THIS SOFTWARE IS PROVIDED
# BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES ARE
# DISCLAIMED.
#
# Original version was developed under the name of srekcah@sra.co.jp
# February 1992 and it was called kconv.pl at the beginning.  This
# address was a pen name for group of individuals and it is no longer
# valid.
#
# The latest version is available here:
#
#   ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/
#
$VERSION = '2.13.4.21';
$VERSION = $VERSION;
$rcsid = sprintf(q$Id: jacode.pl,v %s branched from jcode.pl,v 2.13 2000/09/29 16:10:05 utashiro Exp $, $VERSION);

######################################################################
#
# INTERFACE for newcomers
# -----------------------
#
#   jacode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])
#       Convert the contents of $line to the specified Japanese
#       encoding given in the second argument $OUTPUT_encoding.
#       $OUTPUT_encoding can be any of "jis", "sjis", "euc" or "utf8",
#       or use "noconv" when you don't want the encoding conversion.
#
#       Input encoding is recognized semi-automatically from the
#       $line itself when $INPUT_encoding is not supplied. It is
#       better to specify $INPUT_encoding, since jacode::getcode's
#       guess is not always right. xxx2yyy routine is more efficient
#       when both codes are known.
#
#       It returns the encoding of input string in scalar context,
#       and a list of pointer of convert subroutine and the
#       input encoding in array context.
#
#       Japanese character encoding JIS X0201, X0208, X0212 and
#       ASCII code are supported.  JIS X0212 characters can not
#       be represented in sjis or utf8 and they will be replased
#       by "geta" character when converted to sjis.
#       JIS X0213 characters can not be represented in all.
#
#       For perl is 5.8.1 or later, jacode::convert acts as a wrapper
#       to Encode::from_to. When $OUTPUT_encoding or $INPUT_encoding
#       is neither "jis", "sjis", "euc" nor "utf8", and Encode module
#       can be used,
#
#       Encode::from_to( $line, $INPUT_encoding, $OUTPUT_encoding )
#
#       is executed instead of
#
#       jacode::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, $option).
#
#       In this case, there is no effective return value of pointer
#       of convert subroutine in array context.
#
#       Fourth $option parameter is just forwarded to conversion
#       routine. See next paragraph for detail.
#
#   jacode::xxx2yyy(\$line [, $option])
#       Convert the Japanese code from xxx to yyy.  String xxx
#       and yyy are any convination from "jis", "euc", "sjis"
#       or "utf8". They return *approximate* number of converted
#       bytes.  So return value 0 means the line was not
#       converted at all.
#
#       Optional parameter $option is used to specify optional
#       conversion method.  String "z" is for JIS X0201 KANA
#       to JIS X0208 KANA, and "h" is for reverse.
#
#   jacode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])
#   jacode::jis($line [, $INPUT_encoding [, $option]])
#   jacode::euc($line [, $INPUT_encoding [, $option]])
#   jacode::sjis($line [, $INPUT_encoding [, $option]])
#   jacode::utf8($line [, $INPUT_encoding [, $option]])
#       These functions are prepared for easy use of
#       call/return-by-value interface.  You can use these
#       funcitons in s///e operation or any other place for
#       convenience.
#
#   jacode::jis_inout($JIS_Kanji_IN, $ASCII_IN)
#       Set or inquire JIS Kanji start and ASCII start sequences.
#       Default is "ESC-$-B" and "ESC-(-B".  "ASCII start" is used
#       instead of "JIS Kanji OUT".  If specified in the short form
#       of one character, and is set by being converted into full
#       sequence.
#
#       -----------------------------------------------
#       short  full sequence    means
#       -----------------------------------------------
#       @      ESC-$-@          JIS C 6226-1978
#       B      ESC-$-B          JIS X 0208-1983
#       &      ESC-&@-ESC-$-B   JIS X 0208-1990
#       O      ESC-$-(-O        JIS X 0213:2000 plane1
#       Q      ESC-$-(-Q        JIS X 0213:2004 plane1
#       -----------------------------------------------
#
#   jacode::get_inout($line)
#       Get JIS Kanji start and ASCII start sequences from $line.
#
#   jacode::h2z_xxx(\$line)
#       JIS X0201 KANA (so-called Hankaku-KANA) to JIS X0208 KANA
#       (Zenkaku-KANA) code conversion routine.  String xxx is
#       any of "jis", "sjis", "euc" and "utf8".  From the difficulty
#       of recognizing code set from 1-byte KATAKANA string,
#       automatic code recognition is not supported.
#
#   jacode::z2h_xxx(\$line)
#       JIS X0208 to JIS X0201 KANA code conversion routine.
#       String xxx is any of "jis", "sjis", "euc" and "utf8".
#
#   jacode::getcode(\$line)
#       Return 'jis', 'sjis', 'euc', 'utf8' or undef according
#       to Japanese character code in $line.  Return 'binary' if
#       the data has non-character code.
#
#       When evaluated in array context, it returns a list
#       contains two items.  First value is the number of
#       characters which matched to the expected code, and
#       second value is the code name.  It is useful if and
#       only if the number is not 0 and the code is undef;
#       that case means it couldn't tell 'euc' or 'sjis'
#       because the evaluation score was exactly same.  This
#       interface is too tricky, though.
#
#       Code detection between euc and sjis is very difficult
#       or sometimes impossible or even lead to wrong result
#       when it includes JIS X0201 KANA characters.
#
#   jacode::init()
#       Initialize the variables used in this package.  You
#       don't have to call this when using jocde.pl by `do' or
#       `require' interface.  Call it first if you embedded
#       the jacode.pl at the end of your script.
#
# INTERFACE for backward compatibility
# ------------------------------------
#
#   jacode::getcode_utashiro_2000_09_29(\$line)
#       Original &getcode() of jcode.pl.
#
#   jacode::tr(\$line, $from, $to [, $option])
#       jacode::tr emulates tr operator for 2 byte code.  Only 'd'
#       is interpreted as an option.
#
#       Range operator like `A-Z' for 2 byte code is partially
#       supported.  Code must be JIS or EUC-JP, and first byte
#       have to be same on first and last character.
#
#       CAUTION: Handling range operator is a kind of trick
#       and it is not perfect.  So if you need to transfer `-'
#       character, please be sure to put it at the beginning
#       or the end of $from and $to strings.
#
#   jacode::trans($line, $from, $to [, $option])
#       Same as jacode::tr but accept string and return string
#       after translation.
#
#   jacode::cache()
#   jacode::nocache()
#   jacode::flushcache()
#   jacode::flush()
#       Usually, converted character is cached in memory to
#       avoid same calculations have to be done many times.
#       To disable this caching, call jacode::nocache().  It
#       can be revived by jacode::cache() and cache is flushed
#       by calling jacode::flushcache().  jacode::cache() and
#       jacode::nocache() functions return previous caching state.
#       jacode::flush() is an alias of jacode::flushcache() to save
#       old documents.
#
#   $jacode::convf{'xxx', 'yyy'}
#       The value of this associative array is pointer to the
#       subroutine jacode::xxx2yyy().
#
#   $jacode::z2hf{'xxx'}
#   $jacode::h2zf{'xxx'}
#       These are pointer to the corresponding function just
#       as $jacode::convf.
#
######################################################################
#
# PERL4 INTERFACE for jcode.pl users
# ----------------------------------
#
# See jacode::xxxxx to know &jcode'xxxxx
#
#   &jcode'getcode_utashiro_2000_09_29(*line)
#   &jcode'getcode(*line)
#   &jcode'convert(*line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])
#   &jcode'xxx2yyy(*line [, $option])
#   $jcode'convf{'xxx', 'yyy'}
#   &jcode'to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])
#   &jcode'jis($line [, $INPUT_encoding [, $option]])
#   &jcode'euc($line [, $INPUT_encoding [, $option]])
#   &jcode'sjis($line [, $INPUT_encoding [, $option]])
#   &jcode'utf8($line [, $INPUT_encoding [, $option]])
#   &jcode'jis_inout($JIS_Kanji_IN, $ASCII_IN)
#   &jcode'get_inout($line)
#   &jcode'cache()
#   &jcode'nocache()
#   &jcode'flushcache()
#   &jcode'flush()
#   &jcode'h2z_xxx(*line)
#   &jcode'z2h_xxx(*line)
#   $jcode'z2hf{'xxx'}
#   $jcode'h2zf{'xxx'}
#   &jcode'tr(*line, $from, $to [, $option])
#   &jcode'trans($line, $from, $to [, $option])
#   &jcode'init()
#
######################################################################
#
# PERL5 INTERFACE for jcode.pl users
# ----------------------------------
#
# Since lexical variable is not a subject of typeglob, *string style
# call doesn't work if the variable is declared as `my'.  Same thing
# happens to special variable $_ if the perl is compiled to use
# thread capability.  So using reference is generally recommented to
# avoid the mysterious error.
#
# See jacode::xxxxx to know jcode::xxxxx
#
#   jcode::getcode_utashiro_2000_09_29(\$line)
#   jcode::getcode(\$line)
#   jcode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])
#   jcode::xxx2yyy(\$line [, $option])
#   &{$jcode::convf{'xxx', 'yyy'}}(\$line)
#   jcode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])
#   jcode::jis($line [, $INPUT_encoding [, $option]])
#   jcode::euc($line [, $INPUT_encoding [, $option]])
#   jcode::sjis($line [, $INPUT_encoding [, $option]])
#   jcode::utf8($line [, $INPUT_encoding [, $option]])
#   jcode::jis_inout($JIS_Kanji_IN, $ASCII_IN)
#   jcode::get_inout($line)
#   jcode::cache()
#   jcode::nocache()
#   jcode::flushcache()
#   jcode::flush()
#   jcode::h2z_xxx(\$line)
#   jcode::z2h_xxx(\$line)
#   &{$jcode::z2hf{'xxx'}}(\$line)
#   &{$jcode::h2zf{'xxx'}}(\$line)
#   jcode::tr(\$line, $from, $to [, $option])
#   jcode::trans($line, $from, $to [, $option])
#   jcode::init()
#
######################################################################
#
# SAMPLES
#
# Convert SJIS to JIS and print each line with code name
#
#   #require 'jcode.pl';
#   require 'jacode.pl';
#   while (defined($s = <>)) {
#       $code = &jcode'convert(*s, 'jis', 'sjis');
#       print $code, "\t", $s;
#   }
#
# Convert all lines to JIS according to the first recognized line
#
#   #require 'jcode.pl';
#   require 'jacode.pl';
#   while (defined($s = <>)) {
#       print, next unless $s =~ /[\x1b\x80-\xff]/;
#       (*f, $INPUT_encoding) = &jcode'convert(*s, 'jis');
#       print;
#       defined(&f) || next;
#       while (<>) { &f(*s); print; }
#       last;
#   }
#
# The safest way of JIS conversion
#
#   #require 'jcode.pl';
#   require 'jacode.pl';
#   while (defined($s = <>)) {
#       ($matched, $INPUT_encoding) = &jcode'getcode(*s);
#       if (@buf == 0 && $matched == 0) {
#           print $s;
#           next;
#       }
#       push(@buf, $s);
#       next unless $INPUT_encoding;
#       while (defined($s = shift(@buf))) {
#           &jcode'convert(*s, 'jis', $INPUT_encoding);
#           print $s;
#       }
#       while (defined($s = <>)) {
#           &jcode'convert(*s, 'jis', $INPUT_encoding);
#           print $s;
#       }
#       last;
#   }
#   print @buf if @buf;
#
# Convert SJIS to UTF-8 and print each line by perl 4.036 or later
#
#   #retire 'jcode.pl';
#   require 'jacode.pl';
#   while (defined($s = <>)) {
#       &jcode'convert(*s, 'utf8', 'sjis');
#       print $s;
#   }
#
# Convert SJIS to UTF16-BE and print each line by perl 5.8.1 or later
#
#   require 'jacode.pl';
#   use 5.8.1;
#   while (defined($s = <>)) {
#       jacode::convert(\$s, 'UTF16-BE', 'sjis');
#       print $s;
#   }
#
# Convert SJIS to MIME-Header-ISO_2022_JP and print each line by perl 5.8.1 or later
#
#   require 'jacode.pl';
#   use 5.8.1;
#   while (defined($s = <>)) {
#       jacode::convert(\$s, 'MIME-Header-ISO_2022_JP', 'sjis');
#       print $s;
#   }
#
######################################################################
#
# STYLES
#
# Traditional style of file I/O
#
#   require 'jacode.pl';
#   open(FILE,'input.txt');
#   while (<FILE>) {
#       chomp;
#       jacode::convert(\$_,'sjis','utf8');
#       ...
#   }
#
# Minimalist style
#
#   open(FILE,'perl jacode.pl -ws input.txt | ');
#
######################################################################

#
# Call initialize function if not called yet.  This sounds strange
# but this makes easy to embed the jacode.pl at the script.  Call
# &jcode'init at the beginning of the script in that case.
#
&init unless defined $version;

######################################################################
# "perl jacode.pl" works as pkf command on command line
#
# PKF (perl kanji filter) is a sample script of jacode.pl. It had
# almost equivalent capabilities of widely used code conversion
# program, nkf. Speed of execution is not as fast as nkf, but reading
# and understanding are very fast.
######################################################################

if ($0 eq __FILE__) {

#
# Original version `pkf' is ...
#
# pkf: Perl Kanji Filter
#
# Copyright (c) 1995-1996,2000 Kazumasa Utashiro <utashiro@iij.ad.jp>
# Internet Initiative Japan Inc.
# 3-13 Kanda Nishiki-cho, Chiyoda-ku, Tokyo 101-0054, Japan
#
# Copyright (c) 1991,1992 srekcah@sra.co.jp
# Software Research Associates, Inc.
#
# Use and redistribution for ANY PURPOSE are granted as long as all
# copyright notices are retained.  Redistribution with modification
# is allowed provided that you make your modified version obviously
# distinguishable from the original one.  THIS SOFTWARE IS PROVIDED
# BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES ARE
# DISCLAIMED.
#
    local ($usage) = sprintf(<<END, q$Id: pkf,v 2.1 2000/02/23 08:04:22 utashiro Exp $);
perl $0 [option] [-[INPUT_encoding]OUTPUT_encoding[in,out]] files

  option

  -b  [b]uffered output (default)
  -u  [u]nbuffered output (*NOT MEANS* UTF-8)
  -m  dyna[m]ic input encoding recognition
  -c  print en[c]oding name
  -v  print escape sequences used in JIS when used along with -c
  -n  [n]o encoding conversion (use original encoding)
  -Z  convert 1-byte hankaku kana to 2-byte [Z]enkaku kana
  -H  convert 2-byte zenkaku kana to 1-byte [H]ankaku kana
  -f [unix, mac, dos, nl, lf, cr, crnl, crlf]
     convert eol string to \\n, \\r, \\r\\n respectively.
     currently this option can't be used with other options.

  INPUT_encoding/OUTPUT_encoding is one of [jsew]
  (j=JIS, s=SJIS, e=EUC-JP, w=UTF-8)
  OUTPUT_encoding `j' can be followed by JIS in/out character

  Input Kanji encoding is recognized automatically if not supplied.
  Usually this is done only once, but it will be done on each input
  line when dynamic recognition is specified.

  Output Kanji encoding is JIS by default.

  Output JIS encoding can be followed by kanji in and out characters.
  Default is "BB" which means kanji sequence start with ESC-\$-B and
  end with ESC-(-B

  -----------------------------------------------
  short  full sequence    means
  -----------------------------------------------
  \@      ESC-\$-\@          JIS C 6226-1978
  B      ESC-\$-B          JIS X 0208-1983
  &      ESC-&\@-ESC-\$-B   JIS X 0208-1990
  O      ESC-\$-(-O        JIS X 0213:2000 plane1
  Q      ESC-\$-(-Q        JIS X 0213:2004 plane1
  -----------------------------------------------

Example:
  perl $0 file        convert to JIS encoding
  perl $0 -j\@J file   convert to JIS encoding ("ESC-\$-\@", "ESC-(-J")
  perl $0 -es file    convert EUC-JP to SJIS
  perl $0 -sw file    convert SJIS to UTF-8
  perl $0 -me file    convert mixed encoding file to EUC-JP
  perl $0 -mc file    convert to JIS and print orginal encoding on each line

${rcsid}and %s
END

    unless (@ARGV) {
        die $usage, "\n";
    }

    local ($INPUT_encoding) = '';
    local ($OUTPUT_encoding) = 'jis';
    local (%encoding_name) = (
        'j', 'jis',
        's', 'sjis',
        'e', 'euc',
        'w', 'utf8', # 'u' means unbuffered output, 'w' does world wide encoding
        'n', 'noconv',
    );
    local (%eol) = (

# Newlines
# http://perldoc.perl.org/perlport.html#Newlines
# Some of this may be confusing. Here's a handy reference to the ASCII CR
# and LF characters. You can print it out and stick it in your wallet.
#
#     LF  eq  \012  eq  \x0A  eq  \cJ  eq  chr(10)  eq  ASCII 10
#     CR  eq  \015  eq  \x0D  eq  \cM  eq  chr(13)  eq  ASCII 13
#
#              | Unix | DOS  | Mac  |
#         ---------------------------
#         \n   |  LF  |  LF  |  CR  |
#         \r   |  CR  |  CR  |  LF  |
#         \n * |  LF  | CRLF |  CR  |
#         \r * |  CR  |  CR  |  LF  |
#         ---------------------------
#         * text-mode STDIO

        '',     "\n",
        'unix', "\x0a",
        'mac',  "\x0d",
        'dos',  "\x0d\x0a",
        'nl',   "\x0a",
        'lf',   "\x0a",
        'cr',   "\x0d",
        'crnl', "\x0d\x0a",
        'crlf', "\x0d\x0a",
    );
    local ($eol) = '';

    # Option handling
    local (%opt) = ();
    while (($_ = $ARGV[0]) =~ s/^-(.+)/$1/ && shift) {
        next if $_ eq '';
        s/^([budmcvZH])// && ++$opt{$1} && redo;
        if (s/^f(.*)//) {
            ($eol = $1 || shift) =~ tr/A-Z/a-z/;
            unless (defined($eol) && defined($eol{$eol})) {
                die("Usage:\n$usage");
            }
            next;
        }
        if (/^([jsewn]+)/) {
            ($OUTPUT_encoding, $INPUT_encoding) = @encoding_name{split(//, reverse($1))};
            &jcode'jis_inout(split(//, $')) if $';
            next;
        }
        print "Usage:\n", $usage;
        exit(0);
    }

    $| = $opt{'u'} && !$opt{'b'};
    local ($debug, $dynamic, $show_encoding, $show_seq) = @opt{'d', 'm', 'c', 'v'};
    local ($conv_opt) = $opt{'Z'} ? 'z' : $opt{'H'} ? 'h' : undef;

    if ($show_encoding && !$dynamic) {
        @ARGV = ('-') unless @ARGV;
        local ($file);
        while (defined($file = shift)) {
            if ($file ne '-') {
                print "$file: " if @ARGV .. undef;
                if (-d $file) {
                    print "directory\n";
                    next;
                }
                unless (-f _) {
                    print "not a normal file\n";
                    next;
                }
                unless (-s _) {
                    print "empty\n";
                    next;
                }
            }
            open(FILE, $file) || do { warn "$file: $!\n"; next; };
            while (<FILE>) {
                next unless $INPUT_encoding = &jcode'getcode(*_) || (eof && "ascii");
                print $INPUT_encoding;
                if ($show_seq && $INPUT_encoding eq 'jis') {
                    local ($JIS_Kanji_IN, $ASCII_IN) = &jcode'get_inout($_);
                    $JIS_Kanji_IN  =~ s/\e/ESC/g;
                    $ASCII_IN      =~ s/\e/ESC/g;
                    print ' [', $JIS_Kanji_IN, ', ', $ASCII_IN, ']';
                }
                print "\n";
                last;
            }
            close(FILE);
        }
        exit 0;
    }

    if ($eol) {
        eval q{ CORE::binmode(STDOUT); };
        while (<>) {
            if (s/[\r\n]+$//) {
                print $_, $eol{$eol};
            }
            else {
                print $_;
            }
        }
        exit;
    }

    eval q{ CORE::binmode(ARGV); };
    eval q{ CORE::binmode(STDOUT); };

    local (@read_ahead) = ();
    while (<>) {
        if ($dynamic) {
            local ($c) = &jcode'convert(*_, $OUTPUT_encoding, $INPUT_encoding, $conv_opt);
            print "$c\t" if $show_encoding;
            print;
            next;
        }
        $show_encoding || print, next if !@read_ahead && !/[\033\200-\377]/;
        push(@read_ahead, $_) unless $show_encoding;
        next unless $INPUT_encoding || ($INPUT_encoding = &jcode'getcode(*_));
        $OUTPUT_encoding = $INPUT_encoding if $OUTPUT_encoding eq 'noconv';
        local (*conv_func) = $jcode'convf{$INPUT_encoding, $OUTPUT_encoding};
        printf STDERR "in=$INPUT_encoding, out=$OUTPUT_encoding, f=$conv_func\n" if $debug;

        while ($_ = shift(@read_ahead)) {
            &conv_func(*_, $conv_opt);
            print;
        }
        while (<>) {
            &conv_func(*_, $conv_opt);
            print;
        }

        last;
    }
    print @read_ahead;

    exit $!;
}

#---------------------------------------------------------------------
# Initialize variables
#---------------------------------------------------------------------
sub init {
    $version = $VERSION;

    $re_bin = '[\x00-\x06\x7f\xff]';

    $re_esc_jis0208_1978        = '\e\$\@';     # "\x1b\x24\x40"             '@' JIS C 6226-1978
    $re_esc_jis0208_1983        = '\e\$B';      # "\x1b\x24\x42"             'B' JIS X 0208-1983
    $re_esc_jis0208_1990        = '\e&\@\e\$B'; # "\x1b\x26\x40\x1b\x24\x42" '&' JIS X 0208-1990
    $re_esc_jis0213_2000_plane1 = '\e\$\(O';    # "\x1b\x24\x28\x4f"         'O' JIS X 0213:2000 plane1
    $re_esc_jis0213_2004_plane1 = '\e\$\(Q';    # "\x1b\x24\x28\x51"         'Q' JIS X 0213:2004 plane1
    $re_esc_jis0208             = "$re_esc_jis0208_1978|$re_esc_jis0208_1983|$re_esc_jis0208_1990|$re_esc_jis0213_2000_plane1|$re_esc_jis0213_2004_plane1";
    $re_esc_jis0212             = '\e\$\(D';
    $re_esc_jp                  = "$re_esc_jis0208|$re_esc_jis0212";
    $re_esc_asc                 = '\e\([BJ]';
    $re_esc_kana                = '\e\(I';

    $esc_0208 = "\e\$B";
    $esc_0212 = "\e\$(D";
    $esc_asc  = "\e(B";
    $esc_kana = "\e(I";

    $re_ascii    = '[\x07-\x7e]';

    $re_sjis_c    = '[\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]';
    $re_sjis_kana = '[\xa1-\xdf]';
    $re_sjis_ank  = '[\x07-\x7e\xa1-\xdf]';

    $re_euc_c     = '[\xa1-\xfe][\xa1-\xfe]';
    $re_euc_kana  = '\x8e[\xa1-\xdf]';
    $re_euc_0212  = '\x8f[\xa1-\xfe][\xa1-\xfe]';

    #   # RFC 2279
    #   $re_utf8_rfc2279_c =
    #       '[\xc2-\xdf][\x80-\xbf]'
    #     . '|[\xe0-\xef][\x80-\xbf][\x80-\xbf]'
    #     . '|[\xf0-\xf4][\x80-\x8f][\x80-\xbf][\x80-\xbf]';

    # RFC 3629
    $re_utf8_rfc3629_c =
        '[\xc2-\xdf][\x80-\xbf]'
      . '|[\xe0-\xe0][\xa0-\xbf][\x80-\xbf]'
      . '|[\xe1-\xec][\x80-\xbf][\x80-\xbf]'
      . '|[\xed-\xed][\x80-\x9f][\x80-\xbf]'
      . '|[\xee-\xef][\x80-\xbf][\x80-\xbf]'
      . '|[\xf0-\xf0][\x90-\xbf][\x80-\xbf][\x80-\xbf]'
      . '|[\xf1-\xf3][\x80-\xbf][\x80-\xbf][\x80-\xbf]'
      . '|[\xf4-\xf4][\x80-\x8f][\x80-\xbf][\x80-\xbf]';

    $re_utf8_c    = $re_utf8_rfc3629_c;
    $re_utf8_kana = '\xef\xbd[\xa1-\xbf]|\xef\xbe[\x80-\x9f]';
    $re_utf8_voiced_kana =
        '(\xef\xbd[\xb3\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf]'
      . '|\xef\xbe[\x80\x81\x82\x83\x84\x8a\x8b\x8c\x8d\x8e])\xef\xbe\x9e'
      . '|\xef\xbe[\x8a\x8b\x8c\x8d\x8e]\xef\xbe\x9f';
    $re_utf8_not_kana =
        '[\xc2-\xdf][\x80-\xbf]'
      . '|[\xe0-\xe0][\xa0-\xbf][\x80-\xbf]'
      . '|[\xe1-\xec][\x80-\xbf][\x80-\xbf]'
      . '|[\xed-\xed][\x80-\x9f][\x80-\xbf]'
      . '|[\xee-\xee][\x80-\xbf][\x80-\xbf]'
      . '|[\xef-\xef][\x80-\xbc][\x80-\xbf]'
      . '|[\xef-\xef][\xbd-\xbd][\x80-\xa0]'
      . '|[\xef-\xef][\xbe-\xbe][\xa0-\xbf]'
      . '|[\xef-\xef][\xbf-\xbf][\x80-\xbf]'
      . '|[\xf0-\xf0][\x90-\xbf][\x80-\xbf][\x80-\xbf]'
      . '|[\xf1-\xf3][\x80-\xbf][\x80-\xbf][\x80-\xbf]'
      . '|[\xf4-\xf4][\x80-\x8f][\x80-\xbf][\x80-\xbf]';

    # use `geta' for cancel tofu (undefined character code)
    $undef_sjis = "\x81\xac";
    $undef_euc  = "\xa2\xae";
    $undef_utf8 = "\xe3\x80\x93";

    $cache = 1;

    # JIS X0201 -> JIS X0208 KANA conversion table.  Looks weird?
    # Not that much.  This is simply JIS text without escape sequences.
    ( $h2z_high = $h2z = <<'__TABLE_END__') =~ tr/\x21-\x7e/\xa1-\xfe/;
!   !#  $   !"  %   !&  "   !V  #   !W
^   !+  _   !,  0   !<
'   %!  (   %#  )   %%  *   %'  +   %)
,   %c  -   %e  .   %g  /   %C
1   %"  2   %$  3   %&  4   %(  5   %*
6   %+  7   %-  8   %/  9   %1  :   %3
6^  %,  7^  %.  8^  %0  9^  %2  :^  %4
;   %5  <   %7  =   %9  >   %;  ?   %=
;^  %6  <^  %8  =^  %:  >^  %<  ?^  %>
@   %?  A   %A  B   %D  C   %F  D   %H
@^  %@  A^  %B  B^  %E  C^  %G  D^  %I
E   %J  F   %K  G   %L  H   %M  I   %N
J   %O  K   %R  L   %U  M   %X  N   %[
J^  %P  K^  %S  L^  %V  M^  %Y  N^  %\
J_  %Q  K_  %T  L_  %W  M_  %Z  N_  %]
O   %^  P   %_  Q   %`  R   %a  S   %b
T   %d          U   %f          V   %h
W   %i  X   %j  Y   %k  Z   %l  [   %m
\   %o  ]   %s  &   %r  3^  %t
__TABLE_END__

    if ( $h2z ne <<'__TABLE_END__') {
!   !#  $   !"  %   !&  "   !V  #   !W
^   !+  _   !,  0   !<
'   %!  (   %#  )   %%  *   %'  +   %)
,   %c  -   %e  .   %g  /   %C
1   %"  2   %$  3   %&  4   %(  5   %*
6   %+  7   %-  8   %/  9   %1  :   %3
6^  %,  7^  %.  8^  %0  9^  %2  :^  %4
;   %5  <   %7  =   %9  >   %;  ?   %=
;^  %6  <^  %8  =^  %:  >^  %<  ?^  %>
@   %?  A   %A  B   %D  C   %F  D   %H
@^  %@  A^  %B  B^  %E  C^  %G  D^  %I
E   %J  F   %K  G   %L  H   %M  I   %N
J   %O  K   %R  L   %U  M   %X  N   %[
J^  %P  K^  %S  L^  %V  M^  %Y  N^  %\
J_  %Q  K_  %T  L_  %W  M_  %Z  N_  %]
O   %^  P   %_  Q   %`  R   %a  S   %b
T   %d          U   %f          V   %h
W   %i  X   %j  Y   %k  Z   %l  [   %m
\   %o  ]   %s  &   %r  3^  %t
__TABLE_END__
        die "JIS X0201 -> JIS X0208 KANA conversion table is broken.";
    }
    %h2z = split( /\s+/, $h2z . $h2z_high );

    if ( scalar(keys %h2z) != 178 ) {
        die "scalar(keys %h2z) is ", scalar(keys %h2z), ".";
    }

    %z2h = reverse %h2z;
    if ( scalar( keys %z2h ) != scalar( keys %h2z ) ) {
        die "scalar(keys %z2h) != scalar(keys %h2z).";
    }

    $convf{ 'jis',  'jis' }  = *jis2jis;
    $convf{ 'jis',  'sjis' } = *jis2sjis;
    $convf{ 'jis',  'euc' }  = *jis2euc;
    $convf{ 'jis',  'utf8' } = *jis2utf8;
    $convf{ 'euc',  'jis' }  = *euc2jis;
    $convf{ 'euc',  'sjis' } = *euc2sjis;
    $convf{ 'euc',  'euc' }  = *euc2euc;
    $convf{ 'euc',  'utf8' } = *euc2utf8;
    $convf{ 'sjis', 'jis' }  = *sjis2jis;
    $convf{ 'sjis', 'sjis' } = *sjis2sjis;
    $convf{ 'sjis', 'euc' }  = *sjis2euc;
    $convf{ 'sjis', 'utf8' } = *sjis2utf8;
    $convf{ 'utf8', 'jis' }  = *utf82jis;
    $convf{ 'utf8', 'sjis' } = *utf82sjis;
    $convf{ 'utf8', 'euc' }  = *utf82euc;
    $convf{ 'utf8', 'utf8' } = *utf82utf8;
    $h2zf{'jis'}  = *h2z_jis;
    $z2hf{'jis'}  = *z2h_jis;
    $h2zf{'euc'}  = *h2z_euc;
    $z2hf{'euc'}  = *z2h_euc;
    $h2zf{'sjis'} = *h2z_sjis;
    $z2hf{'sjis'} = *z2h_sjis;
    $h2zf{'utf8'} = *h2z_utf8;
    $z2hf{'utf8'} = *z2h_utf8;

    # Appendix A. Japanese Code Conversion Table
    # Understanding Japanese Information Processing

    # Appendix A: Code Conversion Tables
    # CJKV Information Processing Chinese, Japanese, Korean & Vietnamese Computing
    # CJKV Information Processing, 2nd Edition

    %Ken_Lunde_CJKV_AppA_sjis2euc1st_a = (
0x81,0xa1,
0x82,0xa3,
0x83,0xa5,
0x84,0xa7,
0x85,0xa9,
0x86,0xab,
0x87,0xad,
0x88,0xaf,
0x89,0xb1,
0x8a,0xb3,
0x8b,0xb5,
0x8c,0xb7,
0x8d,0xb9,
0x8e,0xbb,
0x8f,0xbd,
0x90,0xbf,
0x91,0xc1,
0x92,0xc3,
0x93,0xc5,
0x94,0xc7,
0x95,0xc9,
0x96,0xcb,
0x97,0xcd,
0x98,0xcf,
0x99,0xd1,
0x9a,0xd3,
0x9b,0xd5,
0x9c,0xd7,
0x9d,0xd9,
0x9e,0xdb,
0x9f,0xdd,
0xe0,0xdf,
0xe1,0xe1,
0xe2,0xe3,
0xe3,0xe5,
0xe4,0xe7,
0xe5,0xe9,
0xe6,0xeb,
0xe7,0xed,
0xe8,0xef,
0xe9,0xf1,
0xea,0xf3,
0xeb,0xf5,
0xec,0xf7,
0xed,0xf9,
0xee,0xfb,
0xef,0xfd,
    );

    %Ken_Lunde_CJKV_AppA_sjis2euc1st_b = (
0x81,0xa2,
0x82,0xa4,
0x83,0xa6,
0x84,0xa8,
0x85,0xaa,
0x86,0xac,
0x87,0xae,
0x88,0xb0,
0x89,0xb2,
0x8a,0xb4,
0x8b,0xb6,
0x8c,0xb8,
0x8d,0xba,
0x8e,0xbc,
0x8f,0xbe,
0x90,0xc0,
0x91,0xc2,
0x92,0xc4,
0x93,0xc6,
0x94,0xc8,
0x95,0xca,
0x96,0xcc,
0x97,0xce,
0x98,0xd0,
0x99,0xd2,
0x9a,0xd4,
0x9b,0xd6,
0x9c,0xd8,
0x9d,0xda,
0x9e,0xdc,
0x9f,0xde,
0xe0,0xe0,
0xe1,0xe2,
0xe2,0xe4,
0xe3,0xe6,
0xe4,0xe8,
0xe5,0xea,
0xe6,0xec,
0xe7,0xee,
0xe8,0xf0,
0xe9,0xf2,
0xea,0xf4,
0xeb,0xf6,
0xec,0xf8,
0xed,0xfa,
0xee,0xfc,
0xef,0xfe,
    );

    %Ken_Lunde_CJKV_AppA_sjis2euc2nd_a = (
0x40,0xa1,
0x41,0xa2,
0x42,0xa3,
0x43,0xa4,
0x44,0xa5,
0x45,0xa6,
0x46,0xa7,
0x47,0xa8,
0x48,0xa9,
0x49,0xaa,
0x4a,0xab,
0x4b,0xac,
0x4c,0xad,
0x4d,0xae,
0x4e,0xaf,
0x4f,0xb0,
0x50,0xb1,
0x51,0xb2,
0x52,0xb3,
0x53,0xb4,
0x54,0xb5,
0x55,0xb6,
0x56,0xb7,
0x57,0xb8,
0x58,0xb9,
0x59,0xba,
0x5a,0xbb,
0x5b,0xbc,
0x5c,0xbd,
0x5d,0xbe,
0x5e,0xbf,
0x5f,0xc0,
0x60,0xc1,
0x61,0xc2,
0x62,0xc3,
0x63,0xc4,
0x64,0xc5,
0x65,0xc6,
0x66,0xc7,
0x67,0xc8,
0x68,0xc9,
0x69,0xca,
0x6a,0xcb,
0x6b,0xcc,
0x6c,0xcd,
0x6d,0xce,
0x6e,0xcf,
0x6f,0xd0,
0x70,0xd1,
0x71,0xd2,
0x72,0xd3,
0x73,0xd4,
0x74,0xd5,
0x75,0xd6,
0x76,0xd7,
0x77,0xd8,
0x78,0xd9,
0x79,0xda,
0x7a,0xdb,
0x7b,0xdc,
0x7c,0xdd,
0x7d,0xde,
0x7e,0xdf,
0x80,0xe0,
0x81,0xe1,
0x82,0xe2,
0x83,0xe3,
0x84,0xe4,
0x85,0xe5,
0x86,0xe6,
0x87,0xe7,
0x88,0xe8,
0x89,0xe9,
0x8a,0xea,
0x8b,0xeb,
0x8c,0xec,
0x8d,0xed,
0x8e,0xee,
0x8f,0xef,
0x90,0xf0,
0x91,0xf1,
0x92,0xf2,
0x93,0xf3,
0x94,0xf4,
0x95,0xf5,
0x96,0xf6,
0x97,0xf7,
0x98,0xf8,
0x99,0xf9,
0x9a,0xfa,
0x9b,0xfb,
0x9c,0xfc,
0x9d,0xfd,
0x9e,0xfe,
    );

    %Ken_Lunde_CJKV_AppA_sjis2euc2nd_b = (
0x9f,0xa1,
0xa0,0xa2,
0xa1,0xa3,
0xa2,0xa4,
0xa3,0xa5,
0xa4,0xa6,
0xa5,0xa7,
0xa6,0xa8,
0xa7,0xa9,
0xa8,0xaa,
0xa9,0xab,
0xaa,0xac,
0xab,0xad,
0xac,0xae,
0xad,0xaf,
0xae,0xb0,
0xaf,0xb1,
0xb0,0xb2,
0xb1,0xb3,
0xb2,0xb4,
0xb3,0xb5,
0xb4,0xb6,
0xb5,0xb7,
0xb6,0xb8,
0xb7,0xb9,
0xb8,0xba,
0xb9,0xbb,
0xba,0xbc,
0xbb,0xbd,
0xbc,0xbe,
0xbd,0xbf,
0xbe,0xc0,
0xbf,0xc1,
0xc0,0xc2,
0xc1,0xc3,
0xc2,0xc4,
0xc3,0xc5,
0xc4,0xc6,
0xc5,0xc7,
0xc6,0xc8,
0xc7,0xc9,
0xc8,0xca,
0xc9,0xcb,
0xca,0xcc,
0xcb,0xcd,
0xcc,0xce,
0xcd,0xcf,
0xce,0xd0,
0xcf,0xd1,
0xd0,0xd2,
0xd1,0xd3,
0xd2,0xd4,
0xd3,0xd5,
0xd4,0xd6,
0xd5,0xd7,
0xd6,0xd8,
0xd7,0xd9,
0xd8,0xda,
0xd9,0xdb,
0xda,0xdc,
0xdb,0xdd,
0xdc,0xde,
0xdd,0xdf,
0xde,0xe0,
0xdf,0xe1,
0xe0,0xe2,
0xe1,0xe3,
0xe2,0xe4,
0xe3,0xe5,
0xe4,0xe6,
0xe5,0xe7,
0xe6,0xe8,
0xe7,0xe9,
0xe8,0xea,
0xe9,0xeb,
0xea,0xec,
0xeb,0xed,
0xec,0xee,
0xed,0xef,
0xee,0xf0,
0xef,0xf1,
0xf0,0xf2,
0xf1,0xf3,
0xf2,0xf4,
0xf3,0xf5,
0xf4,0xf6,
0xf5,0xf7,
0xf6,0xf8,
0xf7,0xf9,
0xf8,0xfa,
0xf9,0xfb,
0xfa,0xfc,
0xfb,0xfd,
0xfc,0xfe,
    );

    %Ken_Lunde_CJKV_AppA_euc2sjis1st = (
0xa1,0x81,
0xa2,0x81,
0xa3,0x82,
0xa4,0x82,
0xa5,0x83,
0xa6,0x83,
0xa7,0x84,
0xa8,0x84,
0xa9,0x85,
0xaa,0x85,
0xab,0x86,
0xac,0x86,
0xad,0x87,
0xae,0x87,
0xaf,0x88,
0xb0,0x88,
0xb1,0x89,
0xb2,0x89,
0xb3,0x8a,
0xb4,0x8a,
0xb5,0x8b,
0xb6,0x8b,
0xb7,0x8c,
0xb8,0x8c,
0xb9,0x8d,
0xba,0x8d,
0xbb,0x8e,
0xbc,0x8e,
0xbd,0x8f,
0xbe,0x8f,
0xbf,0x90,
0xc0,0x90,
0xc1,0x91,
0xc2,0x91,
0xc3,0x92,
0xc4,0x92,
0xc5,0x93,
0xc6,0x93,
0xc7,0x94,
0xc8,0x94,
0xc9,0x95,
0xca,0x95,
0xcb,0x96,
0xcc,0x96,
0xcd,0x97,
0xce,0x97,
0xcf,0x98,
0xd0,0x98,
0xd1,0x99,
0xd2,0x99,
0xd3,0x9a,
0xd4,0x9a,
0xd5,0x9b,
0xd6,0x9b,
0xd7,0x9c,
0xd8,0x9c,
0xd9,0x9d,
0xda,0x9d,
0xdb,0x9e,
0xdc,0x9e,
0xdd,0x9f,
0xde,0x9f,
0xdf,0xe0,
0xe0,0xe0,
0xe1,0xe1,
0xe2,0xe1,
0xe3,0xe2,
0xe4,0xe2,
0xe5,0xe3,
0xe6,0xe3,
0xe7,0xe4,
0xe8,0xe4,
0xe9,0xe5,
0xea,0xe5,
0xeb,0xe6,
0xec,0xe6,
0xed,0xe7,
0xee,0xe7,
0xef,0xe8,
0xf0,0xe8,
0xf1,0xe9,
0xf2,0xe9,
0xf3,0xea,
0xf4,0xea,
0xf5,0xeb,
0xf6,0xeb,
0xf7,0xec,
0xf8,0xec,
0xf9,0xed,
0xfa,0xed,
0xfb,0xee,
0xfc,0xee,
0xfd,0xef,
0xfe,0xef,
    );

    %Ken_Lunde_CJKV_AppA_euc2sjis2nd_odd = (
0xa1,0x40,
0xa2,0x41,
0xa3,0x42,
0xa4,0x43,
0xa5,0x44,
0xa6,0x45,
0xa7,0x46,
0xa8,0x47,
0xa9,0x48,
0xaa,0x49,
0xab,0x4a,
0xac,0x4b,
0xad,0x4c,
0xae,0x4d,
0xaf,0x4e,
0xb0,0x4f,
0xb1,0x50,
0xb2,0x51,
0xb3,0x52,
0xb4,0x53,
0xb5,0x54,
0xb6,0x55,
0xb7,0x56,
0xb8,0x57,
0xb9,0x58,
0xba,0x59,
0xbb,0x5a,
0xbc,0x5b,
0xbd,0x5c,
0xbe,0x5d,
0xbf,0x5e,
0xc0,0x5f,
0xc1,0x60,
0xc2,0x61,
0xc3,0x62,
0xc4,0x63,
0xc5,0x64,
0xc6,0x65,
0xc7,0x66,
0xc8,0x67,
0xc9,0x68,
0xca,0x69,
0xcb,0x6a,
0xcc,0x6b,
0xcd,0x6c,
0xce,0x6d,
0xcf,0x6e,
0xd0,0x6f,
0xd1,0x70,
0xd2,0x71,
0xd3,0x72,
0xd4,0x73,
0xd5,0x74,
0xd6,0x75,
0xd7,0x76,
0xd8,0x77,
0xd9,0x78,
0xda,0x79,
0xdb,0x7a,
0xdc,0x7b,
0xdd,0x7c,
0xde,0x7d,
0xdf,0x7e,
0xe0,0x80,
0xe1,0x81,
0xe2,0x82,
0xe3,0x83,
0xe4,0x84,
0xe5,0x85,
0xe6,0x86,
0xe7,0x87,
0xe8,0x88,
0xe9,0x89,
0xea,0x8a,
0xeb,0x8b,
0xec,0x8c,
0xed,0x8d,
0xee,0x8e,
0xef,0x8f,
0xf0,0x90,
0xf1,0x91,
0xf2,0x92,
0xf3,0x93,
0xf4,0x94,
0xf5,0x95,
0xf6,0x96,
0xf7,0x97,
0xf8,0x98,
0xf9,0x99,
0xfa,0x9a,
0xfb,0x9b,
0xfc,0x9c,
0xfd,0x9d,
0xfe,0x9e,
    );

    %Ken_Lunde_CJKV_AppA_euc2sjis2nd_even = (
0xa1,0x9f,
0xa2,0xa0,
0xa3,0xa1,
0xa4,0xa2,
0xa5,0xa3,
0xa6,0xa4,
0xa7,0xa5,
0xa8,0xa6,
0xa9,0xa7,
0xaa,0xa8,
0xab,0xa9,
0xac,0xaa,
0xad,0xab,
0xae,0xac,
0xaf,0xad,
0xb0,0xae,
0xb1,0xaf,
0xb2,0xb0,
0xb3,0xb1,
0xb4,0xb2,
0xb5,0xb3,
0xb6,0xb4,
0xb7,0xb5,
0xb8,0xb6,
0xb9,0xb7,
0xba,0xb8,
0xbb,0xb9,
0xbc,0xba,
0xbd,0xbb,
0xbe,0xbc,
0xbf,0xbd,
0xc0,0xbe,
0xc1,0xbf,
0xc2,0xc0,
0xc3,0xc1,
0xc4,0xc2,
0xc5,0xc3,
0xc6,0xc4,
0xc7,0xc5,
0xc8,0xc6,
0xc9,0xc7,
0xca,0xc8,
0xcb,0xc9,
0xcc,0xca,
0xcd,0xcb,
0xce,0xcc,
0xcf,0xcd,
0xd0,0xce,
0xd1,0xcf,
0xd2,0xd0,
0xd3,0xd1,
0xd4,0xd2,
0xd5,0xd3,
0xd6,0xd4,
0xd7,0xd5,
0xd8,0xd6,
0xd9,0xd7,
0xda,0xd8,
0xdb,0xd9,
0xdc,0xda,
0xdd,0xdb,
0xde,0xdc,
0xdf,0xdd,
0xe0,0xde,
0xe1,0xdf,
0xe2,0xe0,
0xe3,0xe1,
0xe4,0xe2,
0xe5,0xe3,
0xe6,0xe4,
0xe7,0xe5,
0xe8,0xe6,
0xe9,0xe7,
0xea,0xe8,
0xeb,0xe9,
0xec,0xea,
0xed,0xeb,
0xee,0xec,
0xef,0xed,
0xf0,0xee,
0xf1,0xef,
0xf2,0xf0,
0xf3,0xf1,
0xf4,0xf2,
0xf5,0xf3,
0xf6,0xf4,
0xf7,0xf5,
0xf8,0xf6,
0xf9,0xf7,
0xfa,0xf8,
0xfb,0xf9,
0xfc,0xfa,
0xfd,0xfb,
0xfe,0xfc,
    );

    # package jacode;
    # sub AUTOLOAD {
    #     $AUTOLOAD =~ s/^jcode::/jacode::/;
    #     goto &$AUTOLOAD;
    # }
    if ($support_jcode_package_too) {
        *jcode'getcode_utashiro_2000_09_29 =
        *jcode'getcode_utashiro_2000_09_29 =
        *jacode'getcode_utashiro_2000_09_29;
        *jcode'init           = *jcode'init           = *jacode'init;
        *jcode'jis_inout      = *jcode'jis_inout      = *jacode'jis_inout;
        *jcode'get_inout      = *jcode'get_inout      = *jacode'get_inout;
        *jcode'getcode        = *jcode'getcode        = *jacode'getcode;
        *jcode'convert        = *jcode'convert        = *jacode'convert;
        *jcode'jis            = *jcode'jis            = *jacode'jis;
        *jcode'euc            = *jcode'euc            = *jacode'euc;
        *jcode'sjis           = *jcode'sjis           = *jacode'sjis;
        *jcode'utf8           = *jcode'utf8           = *jacode'utf8;
        *jcode'to             = *jcode'to             = *jacode'to;
        *jcode'what           = *jcode'what           = *jacode'what;
        *jcode'trans          = *jcode'trans          = *jacode'trans;
        *jcode'sjis2jis       = *jcode'sjis2jis       = *jacode'sjis2jis;
        *jcode'euc2jis        = *jcode'euc2jis        = *jacode'euc2jis;
        *jcode'jis2euc        = *jcode'jis2euc        = *jacode'jis2euc;
        *jcode'jis2sjis       = *jcode'jis2sjis       = *jacode'jis2sjis;
        *jcode'sjis2euc       = *jcode'sjis2euc       = *jacode'sjis2euc;
        *jcode's2e            = *jcode's2e            = *jacode's2e;
        *jcode'euc2sjis       = *jcode'euc2sjis       = *jacode'euc2sjis;
        *jcode'e2s            = *jcode'e2s            = *jacode'e2s;
        *jcode'utf82jis       = *jcode'utf82jis       = *jacode'utf82jis;
        *jcode'utf82euc       = *jcode'utf82euc       = *jacode'utf82euc;
        *jcode'u2e            = *jcode'u2e            = *jacode'u2e;
        *jcode'utf82sjis      = *jcode'utf82sjis      = *jacode'utf82sjis;
        *jcode'u2s            = *jcode'u2s            = *jacode'u2s;
        *jcode'jis2utf8       = *jcode'jis2utf8       = *jacode'jis2utf8;
        *jcode'euc2utf8       = *jcode'euc2utf8       = *jacode'euc2utf8;
        *jcode'e2u            = *jcode'e2u            = *jacode'e2u;
        *jcode'sjis2utf8      = *jcode'sjis2utf8      = *jacode'sjis2utf8;
        *jcode's2u            = *jcode's2u            = *jacode's2u;
        *jcode'jis2jis        = *jcode'jis2jis        = *jacode'jis2jis;
        *jcode'sjis2sjis      = *jcode'sjis2sjis      = *jacode'sjis2sjis;
        *jcode'euc2euc        = *jcode'euc2euc        = *jacode'euc2euc;
        *jcode'utf82utf8      = *jcode'utf82utf8      = *jacode'utf82utf8;
        *jcode'cache          = *jcode'cache          = *jacode'cache;
        *jcode'nocache        = *jcode'nocache        = *jacode'nocache;
        *jcode'flush          = *jcode'flush          = *jacode'flush;
        *jcode'flushcache     = *jcode'flushcache     = *jacode'flushcache;
        *jcode'h2z_jis        = *jcode'h2z_jis        = *jacode'h2z_jis;
        *jcode'h2z_euc        = *jcode'h2z_euc        = *jacode'h2z_euc;
        *jcode'h2z_sjis       = *jcode'h2z_sjis       = *jacode'h2z_sjis;
        *jcode'h2z_utf8       = *jcode'h2z_utf8       = *jacode'h2z_utf8;
        *jcode'z2h_jis        = *jcode'z2h_jis        = *jacode'z2h_jis;
        *jcode'z2h_euc        = *jcode'z2h_euc        = *jacode'z2h_euc;
        *jcode'z2h_sjis       = *jcode'z2h_sjis       = *jacode'z2h_sjis;
        *jcode'z2h_utf8       = *jcode'z2h_utf8       = *jacode'z2h_utf8;
        *jcode'init_z2h_euc   = *jcode'init_z2h_euc   = *jacode'init_z2h_euc;
        *jcode'init_z2h_sjis  = *jcode'init_z2h_sjis  = *jacode'init_z2h_sjis;
        *jcode'init_z2h_utf8  = *jcode'init_z2h_utf8  = *jacode'init_z2h_utf8;
        *jcode'init_h2z_utf8  = *jcode'init_h2z_utf8  = *jacode'init_h2z_utf8;
        *jcode'init_sjis2utf8 = *jcode'init_sjis2utf8 = *jacode'init_sjis2utf8;
        *jcode'init_utf82sjis = *jcode'init_utf82sjis = *jacode'init_utf82sjis;
        *jcode'init_k2u       = *jcode'init_k2u       = *jacode'init_k2u;
        *jcode'init_u2k       = *jcode'init_u2k       = *jacode'init_u2k;
        *jcode'tr             = *jcode'tr             = *jacode'tr;
        *jcode'convf          = *jcode'convf          = *jacode'convf;
        *jcode'z2hf           = *jcode'z2hf           = *jacode'z2hf;
        *jcode'h2zf           = *jcode'h2zf           = *jacode'h2zf;
    }
}

#---------------------------------------------------------------------
# Set escape sequences which should be put before and after Japanese
# (JIS X0208) string
#---------------------------------------------------------------------
sub jis_inout {
    $esc_0208 = shift || $esc_0208;

    local (%esc_0208) = (
        '@', $re_esc_jis0208_1978,        # JIS C 6226-1978
        'B', $re_esc_jis0208_1983,        # JIS X 0208-1983
        '&', $re_esc_jis0208_1990,        # JIS X 0208-1990
        'O', $re_esc_jis0213_2000_plane1, # JIS X 0213:2000 plane1
        'Q', $re_esc_jis0213_2004_plane1, # JIS X 0213:2004 plane1
    );
    $esc_0208 = $esc_0208{$esc_0208} if defined($esc_0208{$esc_0208});

    $esc_asc = shift || $esc_asc;
    $esc_asc = "\e\($esc_asc" if length($esc_asc) == 1;
    ( $esc_0208, $esc_asc );
}

#---------------------------------------------------------------------
# Get JIS Kanji start and ASCII start sequences from the string
#---------------------------------------------------------------------
sub get_inout {
    local ( $esc_0208, $esc_asc );
    local ($_) = @_;
    if (/($re_esc_jis0208)/o) {
        $esc_0208 = $1;
    }
    if (/($re_esc_asc)/o) {
        $esc_asc = $1;
    }
    ( $esc_0208, $esc_asc );
}

#---------------------------------------------------------------------
# Recognize character code (Kazumasa Utashiro 2000/09/29)
#---------------------------------------------------------------------
sub getcode_utashiro_2000_09_29 {
    local (*s) = @_;
    local ( $matched, $code );

    # not Japanese
    if ( $s !~ /[\e\200-\377]/ ) {
        $matched = 0;
        $code    = undef;
    }

    # 'jis'
    elsif ( $s =~ /$re_esc_jp|$re_esc_asc|$re_esc_kana/o ) {
        $matched = 1;
        $code    = 'jis';
    }

    # 'binary'
    elsif ( $s =~ /$re_bin/o ) {
        $matched = 0;
        $code    = 'binary';
    }

    # should be 'euc' or 'sjis'
    else {
        local ( $sjis, $euc ) = ( 0, 0 );
        while ( $s =~ /(($re_sjis_c)+)/go ) {
            $sjis += length($1);
        }
        while ( $s =~ /(($re_euc_c|$re_euc_kana|$re_euc_0212)+)/go ) {
            $euc += length($1);
        }
        $matched = &max_utashiro_2000_09_29($sjis, $euc);
        $code = ( 'euc', undef, 'sjis' )[ ( $sjis <=> $euc ) + $[ + 1 ];
    }

    wantarray ? ( $matched, $code ) : $code;
}

#---------------------------------------------------------------------
# Returns max value of $_[$[] and $_[$[+1] w('o')w
#---------------------------------------------------------------------
sub max_utashiro_2000_09_29 {

# if $[ is 0
#   $_[ 0  + ($_[ 0  ] < $_[ 0  + 1 ]) ];

# if $[ is 1
#   $_[ 1  + ($_[ 1  ] < $_[ 1  + 1 ]) ];

    $_[ $[ + ($_[ $[ ] < $_[ $[ + 1 ]) ];
}

#---------------------------------------------------------------------
# Recognize character code
#---------------------------------------------------------------------
sub getcode {
    local (*s) = @_;
    local ( $matched, $encoding );

    # not Japanese
    if ( $s !~ /[\e\x80-\xff]/ ) {
        $matched  = 0;
        $encoding = undef;
    }

    # 'jis'
    elsif ( $s =~ /$re_esc_jp|$re_esc_asc|$re_esc_kana/o ) {
        $matched  = 1;
        $encoding = 'jis';
    }

    # 'binary'
    elsif ( $s =~ /$re_bin/o ) {
        $matched  = 0;
        $encoding = 'binary';
    }

    # should be 'euc' or 'sjis' or 'utf8'
    else {
        local ( $sjis, $euc, $utf8 ) = ( 0, 0, 0 );

        # Id: getcode.pl,v 0.01 1998/03/17 gama Exp
        # http://www2d.biglobe.ne.jp/~gama/cgi/jcode/jcode.htm

        while ( $s =~ /(($re_sjis_c|$re_sjis_ank)+)/go ) {
            $sjis += length($1);
        }
        while ( $s =~ /(($re_euc_c|$re_euc_kana|$re_ascii|$re_euc_0212)+)/go ) {
            $euc += length($1);
        }

        # 2011/12/06 Improvement proposal from Hanada Masaaki
        # before: while ( $s =~ /(($re_utf8_c)+)/go ) {

        while ( $s =~ /(($re_utf8_c|$re_ascii)+)/go ) {
            $utf8 += length($1);
        }

        if ( $sjis > $euc ) {
            if ( $sjis > $utf8 ) {
                $matched  = $sjis;
                $encoding = 'sjis';
            }
            elsif ( $sjis == $utf8 ) {
                $matched = $sjis;
                if ( $s =~ /^($re_utf8_c|$re_ascii)+$/o ) {
                    $encoding = 'utf8';
                }
                elsif ( $s =~ /^($re_sjis_c|$re_sjis_ank)+$/o ) {
                    $encoding = 'sjis';
                }
                elsif ( ( length($s) >= 30 ) && ( $matched >= 15 ) ) {
                    $encoding = 'utf8';
                }
                else {
                    $encoding = undef;
                }
            }
            else {
                $matched  = $utf8;
                $encoding = 'utf8';
            }
        }
        elsif ( $sjis == $euc ) {
            if ( $sjis > $utf8 ) {
                $matched = $sjis;

# http://www.srekcah.org/jcode/2.13.3/
#
#! ;; $rcsid = q$Id: jcode.pl,v 2.13.3.2 2002/04/07 08:13:57 utashiro Exp $;
# *** 370,375 ****
# --- 370,390 ----
#   elsif ($s =~ /$re_bin/o) { # 'binary'
#       $matched = 0;
#       $code = 'binary';
#+  }
#+  elsif ($s =~ /[\201-\215\220-\240]/) {
#+      $code = 'sjis';
#+  }
#+  elsif ($s =~ /\216[^\241-\337]/) {
#+    $code = 'sjis';
#+  }
#+  elsif ($s =~ /\217[^\241-\376]/) {
#+      $code = 'sjis';
#+  }
#+  elsif ($s =~ /\217[\241-\376][^\241-\376]/) {
#+      $code = 'sjis';
#+  }
#+  elsif ($s =~ /(^|[\000-\177])[\241-\374]((\216[\241-\374]){2})*([\000-\177]|$)/) {
#+      $code = 'sjis';
#   }
#   else { # should be 'euc' or 'sjis'
#       local($sjis, $euc) = (0, 0);

# jcodeg.diff by Gappai
# http://www.vector.co.jp/soft/win95/prog/se347514.html

# Id: getcode.pl,v 0.01 1998/03/17 gama Exp
# http://www2d.biglobe.ne.jp/~gama/cgi/jcode/jcode.htm

                if ( $s =~ /[\x80-\x8d\x90-\xa0]/ ) {
                    $encoding = 'sjis';
                }
                elsif ( $s =~ /\x8e[^\xa1-\xdf]/ ) {
                    $encoding = 'sjis';
                }
                elsif ( $s =~ /\x8f[^\xa1-\xfe]/ ) {
                    $encoding = 'sjis';
                }
                elsif ( $s =~ /\x8f[\xa1-\xfe][^\xa1-\xfe]/ ) {
                    $encoding = 'sjis';
                }
                elsif ( $s =~
/(^|[^\x81-\x9f\xa1-\xdf\xe0-\xfc])[\xa1-\xdf]([\xa1-\xdf][\xa1-\xdf])*([^\xa1-\xdf]|$)/
                  )
                {
                    $encoding = 'sjis';
                }

                # Perl memo by OHZAKI Hiroki
                # http://www.din.or.jp/~ohzaki/perl.htm#JP_Code

                elsif ( $s =~
/^([\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]|[\xa1-\xdf]|[\x00-\x7f])*$/
                  )
                {
                    if ( $s !~
/^([\xa1-\xfe][\xa1-\xfe]|\x8e[\xa1-\xdf]|\x8f[\xa1-\xfe][\xa1-\xfe]|[\x00-\x7f])*$/
                      )
                    {
                        $encoding = 'sjis';
                    }
                    else {
                        $encoding = 'euc';
                    }
                }
                else {
                    $encoding = 'euc';
                }
            }
            elsif ( $sjis == $utf8 ) {
                $matched = $sjis;
                if ( $s =~ /^($re_utf8_c|$re_ascii)+$/o ) {
                    $encoding = 'utf8';
                }
                elsif ( $s =~ /^($re_sjis_c|$re_sjis_ank)+$/o ) {
                    $encoding = 'sjis';
                }
                elsif ( ( length($s) >= 30 ) && ( $matched >= 15 ) ) {
                    $encoding = 'utf8';
                }
                else {
                    $encoding = undef;
                }
            }
            else {
                $matched  = $utf8;
                $encoding = 'utf8';
            }
        }
        else {
            if ( $euc > $utf8 ) {
                $matched  = $euc;
                $encoding = 'euc';
            }
            elsif ( $euc == $utf8 ) {
                $matched = $euc;
                if ( ( length($s) >= 30 ) && ( $matched >= 15 ) ) {
                    $encoding = 'utf8';
                }
                else {
                    $encoding = undef;
                }
            }
            else {
                $matched  = $utf8;
                $encoding = 'utf8';
            }
        }
    }

    return wantarray ? ( $matched, $encoding ) : $encoding;
}

#---------------------------------------------------------------------
# Convert any code to specified code
#---------------------------------------------------------------------
sub convert {
    local ( *s, $OUTPUT_encoding, $INPUT_encoding, $option ) = @_;
    return ( undef, undef ) unless $INPUT_encoding = $INPUT_encoding || &getcode(*s);
    return ( undef, $INPUT_encoding ) if $INPUT_encoding eq 'binary';
    $OUTPUT_encoding = 'jis' unless $OUTPUT_encoding;
    $OUTPUT_encoding = $INPUT_encoding if $OUTPUT_encoding eq 'noconv';
    local (*f) = $convf{ $INPUT_encoding, $OUTPUT_encoding };
    if ( $INPUT_encoding eq 'utf8' ) {

        # http://blog.livedoor.jp/dankogai/archives/50116398.html
        # http://blog.livedoor.jp/dankogai/archives/51004472.html

        if ($] >= 5.008) {
            eval q<
                require Encode;
                if (Encode::is_utf8($s)) {
                    $s = Encode::encode_utf8($s);
                }
            >;
        }
    }
    if ( $convf{ $INPUT_encoding, $OUTPUT_encoding } ) {
        &f( *s, $option );
    }
    else {
        eval q{ use Encode; };
        unless ($@) {
            eval q{ Encode::from_to( $s, $INPUT_encoding, $OUTPUT_encoding ); };
        }
    }

    wantarray ? ( *f, $INPUT_encoding ) : $INPUT_encoding;
}

#---------------------------------------------------------------------
# Easy return-by-value interfaces
#---------------------------------------------------------------------
sub jis  { &to( 'jis',  @_ ); }
#---------------------------------------------------------------------
sub euc  { &to( 'euc',  @_ ); }
#---------------------------------------------------------------------
sub sjis { &to( 'sjis', @_ ); }
#---------------------------------------------------------------------
sub utf8 { &to( 'utf8', @_ ); }

#---------------------------------------------------------------------
sub to {
    local ( $OUTPUT_encoding, $s, $INPUT_encoding, $option ) = @_;
    &convert( *s, $OUTPUT_encoding, $INPUT_encoding, $option );
    $s;
}

#---------------------------------------------------------------------
sub what {
    local ($s) = @_;
    &getcode(*s);
}

#---------------------------------------------------------------------
sub trans {
    local ($s) = shift;
    &tr( *s, @_ );
    $s;
}

#---------------------------------------------------------------------
# SJIS to JIS
#---------------------------------------------------------------------
sub sjis2jis {
    local ( *s, $option ) = @_;
    &sjis2sjis( *s, $option ) if $option;
    local ($n) = 0;
    $s =~ s/(($re_sjis_c)+|($re_ascii)+|($re_sjis_kana)+)/&_sjis2jis($1)/geo;
    $s .= $esc_asc;
    $n;
}

#---------------------------------------------------------------------
sub _sjis2jis {
    local ($s) = shift;
    if ( $s =~ /^$re_ascii/o ) {
        $esc_asc . $s;
    }
    elsif ( $s =~ /^$re_sjis_kana/o ) {
        $s =~ tr/\xa1-\xdf/\x21-\x5f/;
        $n += length($s);
        $esc_kana . $s;
    }
    else {
        $s =~ s/($re_sjis_c)/$n++, ($s2e{$1}||&s2e($1))/geo;
        $s =~ tr/\xa1-\xfe/\x21-\x7e/;
        $esc_0208 . $s;
    }
}

#---------------------------------------------------------------------
# EUC-JP to JIS
#---------------------------------------------------------------------
sub euc2jis {
    local ( *s, $option ) = @_;
    &euc2euc( *s, $option ) if $option;
    local ($n) = 0;
    $s =~ s/(($re_euc_c)+|($re_ascii)+|($re_euc_kana)+|($re_euc_0212)+)/&_euc2jis($1)/geo;
    $s .= $esc_asc;
    $n;
}

#---------------------------------------------------------------------
sub _euc2jis {
    local ($s) = shift;
    if ( $s =~ tr/\x8e//d ) {
        $s =~ tr/\xa1-\xfe/\x21-\x7e/;
        $n += length($s);
        $esc_kana . $s;
    }
    elsif ( $s =~ tr/\x8f//d ) {
        $s =~ tr/\xa1-\xfe/\x21-\x7e/;
        $n += length($s) / 2;
        $esc_0212 . $s;
    }
    elsif ( $s =~ /^$re_ascii/ ) {
        $esc_asc . $s;
    }
    else {
        $s =~ tr/\xa1-\xfe/\x21-\x7e/;
        $n += length($s) / 2;
        $esc_0208 . $s;
    }
}

#---------------------------------------------------------------------
# JIS to EUC-JP
#---------------------------------------------------------------------
sub jis2euc {
    local ( *s, $option ) = @_;
    &jis2jis( *s, $option ) if $option;
    local ($n) = 0;
    $s =~ s/($re_esc_jp|$re_esc_asc|$re_esc_kana)([^\e]*)/&_jis2euc($1,$2)/geo;
    $n;
}

#---------------------------------------------------------------------
sub _jis2euc {
    local ( $esc, $s ) = @_;
    if ( $esc =~ /^$re_esc_asc/o ) {
    }
    elsif ( $esc =~ /^$re_esc_kana/o ) {
        $s =~ tr/\x21-\x7e/\xa1-\xfe/;
        $s =~ s/([\xa1-\xdf])/$n++, "\x8e$1"/ge;
    }
    elsif ( $esc =~ /^$re_esc_jis0212/o ) {
        $s =~ tr/\x21-\x7e/\xa1-\xfe/;
        $s =~ s/([\xa1-\xfe][\xa1-\xfe])/$n++, "\x8f$1"/ge;
    }
    else {
        $s =~ tr/\x21-\x7e/\xa1-\xfe/;
        $n += length($s) / 2;
    }
    $s;
}

#---------------------------------------------------------------------
# JIS to SJIS
#---------------------------------------------------------------------
sub jis2sjis {
    local ( *s, $option ) = @_;
    &jis2jis( *s, $option ) if $option;
    local ($n) = 0;
    $s =~ s/($re_esc_jp|$re_esc_asc|$re_esc_kana)([^\e]*)/&_jis2sjis($1,$2)/geo;
    $n;
}

#---------------------------------------------------------------------
sub _jis2sjis {

# fixing bug of jcode.pl (1 of 2)
# miscounting $n
# http://srekcah.org/jcode/2.13.1/
#
#! ;; $rcsid = q$Id: jcode.pl,v 2.13.1.4 2002/04/07 07:27:00 utashiro Exp $;
# *** 516,522 ****
#   local($esc, $s) = @_;
#   if ($esc =~ /^$re_jis0212/o) {
#       $s =~ s/../$undef_sjis/g;
#!      $n = length;
#   }
#   elsif ($esc !~ /^$re_asc/o) {
#       $n += $s =~ tr/\041-\176/\241-\376/;
# --- 516,522 ----
#   local($esc, $s) = @_;
#   if ($esc =~ /^$re_jis0212/o) {
#       $s =~ s/../$undef_sjis/g;
#!      $n = length($s);
#   }
#   elsif ($esc !~ /^$re_asc/o) {
#       $n += $s =~ tr/\041-\176/\241-\376/;

    local ( $esc, $s ) = @_;

    if ( $esc =~ /^$re_esc_asc/o ) {
    }
    elsif ( $esc =~ /^$re_esc_kana/o ) {
        $s =~ tr/\x21-\x7e/\xa1-\xfe/;
        $n += length($s);
    }
    elsif ( $esc =~ /^$re_esc_jis0212/o ) {
        $s =~ s/[\x00-\xff][\x00-\xff]/$n++, $undef_sjis/ge;
    }
    else {
        $s =~ tr/\x21-\x7e/\xa1-\xfe/;
        $s =~ s/($re_euc_c)/$n++, ($e2s{$1}||&e2s($1))/geo;
    }
    $s;
}

#---------------------------------------------------------------------
# SJIS to EUC-JP
#---------------------------------------------------------------------
sub sjis2euc {
    local ( *s, $option ) = @_;
    &sjis2sjis( *s, $option ) if $option;
    local ($n) = 0;
    $s =~ s/($re_sjis_c|$re_sjis_kana)/$n++, &s2e($1)/geo;
    $n;
}

#---------------------------------------------------------------------
sub s2e {
    local ( $c1, $c2, $code );
    ( $c1, $c2 ) = unpack( 'CC', $code = shift );
    if ( $code =~ /^$re_ascii/ ) {
        $code;
    }
    elsif ($s2e{$code}) {
        $s2e{$code};
    }
    elsif ( $code gt "\xea\xa4" ) {
        $undef_euc;
    }
    else {
        if ( 0xa1 <= $c1 && $c1 <= 0xdf ) {
            $c2 = $c1;
            $c1 = 0x8e;
        }

        elsif ( $Ken_Lunde_CJKV_AppA_sjis2euc2nd_a{$c2} ) {
            ( $c1, $c2 ) = (
                $Ken_Lunde_CJKV_AppA_sjis2euc1st_a{$c1},
                $Ken_Lunde_CJKV_AppA_sjis2euc2nd_a{$c2},
            );
        }
        elsif ( $Ken_Lunde_CJKV_AppA_sjis2euc2nd_b{$c2} ) {
            ( $c1, $c2 ) = (
                $Ken_Lunde_CJKV_AppA_sjis2euc1st_b{$c1},
                $Ken_Lunde_CJKV_AppA_sjis2euc2nd_b{$c2},
            );
        }

        elsif ( 0x9f <= $c2 ) {
            $c1 = $c1 * 2 - ( $c1 >= 0xe0 ? 0xe0 : 0x60 );
            $c2 += 2;
        }
        else {
            $c1 = $c1 * 2 - ( $c1 >= 0xe0 ? 0xe1 : 0x61 );
            $c2 += 0x60 + ( $c2 < 0x7f );
        }

        if ($cache) {
            $s2e{$code} = pack( 'CC', $c1, $c2 );
        }
        else {
            pack( 'CC', $c1, $c2 );
        }
    }
}

#---------------------------------------------------------------------
# EUC-JP to SJIS
#---------------------------------------------------------------------
sub euc2sjis {
    local ( *s, $option ) = @_;
    &euc2euc( *s, $option ) if $option;
    local ($n) = 0;
    $s =~ s/($re_euc_c|$re_euc_kana|$re_euc_0212)/$n++, &e2s($1)/geo;
    $n;
}

#---------------------------------------------------------------------
sub e2s {
    local ( $c1, $c2, $code );
    ( $c1, $c2 ) = unpack( 'CC', $code = shift );
    if ( $code =~ /^$re_ascii/ ) {
        return $code;
    }
    elsif ($e2s{$code}) {
        return $e2s{$code};
    }
    elsif ( $c1 == 0x8e ) {    # SS2
        return substr( $code, 1, 1 );
    }
    elsif ( $c1 == 0x8f ) {    # SS3
        return $undef_sjis;
    }

    elsif ( $Ken_Lunde_CJKV_AppA_euc2sjis1st{$c1} ) {
        if ($c1 & 0x01) {
            ( $c1, $c2 ) = (
                $Ken_Lunde_CJKV_AppA_euc2sjis1st    {$c1},
                $Ken_Lunde_CJKV_AppA_euc2sjis2nd_odd{$c2},
            );
        }
        else {
            ( $c1, $c2 ) = (
                $Ken_Lunde_CJKV_AppA_euc2sjis1st     {$c1},
                $Ken_Lunde_CJKV_AppA_euc2sjis2nd_even{$c2},
            );
        }
    }

    elsif ( $c1 % 2 ) {
        $c1 = ( $c1 >> 1 ) + ( $c1 < 0xdf ? 0x31 : 0x71 );
        $c2 -= 0x60 + ( $c2 < 0xe0 );
    }
    else {
        $c1 = ( $c1 >> 1 ) + ( $c1 < 0xdf ? 0x30 : 0x70 );
        $c2 -= 2;
    }

    if ($cache) {
        $e2s{$code} = pack( 'CC', $c1, $c2 );
    }
    else {
        pack( 'CC', $c1, $c2 );
    }
}

#---------------------------------------------------------------------
# UTF-8 to JIS
#---------------------------------------------------------------------
sub utf82jis {
    local ( *u, $option ) = @_;
    &utf82utf8( *u, $option ) if $option;
    local ($n) = 0;
    $u =~ s/(($re_ascii)+|($re_utf8_kana)+|($re_utf8_c)+)/&_utf82jis($1)/geo;
    $u .= $esc_asc;
    $n;
}

#---------------------------------------------------------------------
sub _utf82jis {
    local ($u) = @_;
    if ( $u =~ /^$re_ascii/o ) {
        $esc_asc . $u;
    }
    elsif ( $u =~ /^$re_utf8_kana/o ) {
        &init_u2k unless %u2k;
        $u =~ s/($re_utf8_kana)/$n++, $u2k{$1}/geo;
        $u =~ tr/\xa1-\xfe/\x21-\x7e/;
        $esc_kana . $u;
    }
    else {
        $u =~ s/($re_utf8_c)/$n++, ($u2e{$1}||&u2e($1))/geo;
        $u =~ tr/\xa1-\xfe/\x21-\x7e/;
        $esc_0208 . $u;
    }
}

#---------------------------------------------------------------------
# UTF-8 to EUC-JP
#---------------------------------------------------------------------
sub utf82euc {
    local ( *u, $option ) = @_;
    &utf82utf8( *u, $option ) if $option;
    local ($n) = 0;
    $u =~ s/($re_utf8_kana|$re_utf8_not_kana)/$n++, &_utf82euc($1)/geo;
    $n;
}

#---------------------------------------------------------------------
sub _utf82euc {
    local ($u) = @_;
    if ( $u =~ /^$re_utf8_kana/o ) {
        &init_u2k unless %u2k;
        $u =~ s/($re_utf8_kana)/"\x8e".$u2k{$1}/geo;
    }
    else {
        $u =~ s/($re_utf8_not_kana)/$u2e{$1}||&u2e($1)/geo;
    }
    $u;
}

#---------------------------------------------------------------------
sub u2e {
    local ($code) = @_;
    if ($cache) {
        $u2e{$code} =
          (      $s2e{ $u2s{$code} || &u2s($code) }
              || &s2e( $u2s{$code} || &u2s($code) ) );
    }
    else {
        $s2e{ $u2s{$code} || &u2s($code) }
          || &s2e( $u2s{$code} || &u2s($code) );
    }
}

#---------------------------------------------------------------------
# UTF-8 to SJIS
#---------------------------------------------------------------------
sub utf82sjis {
    local ( *u, $option ) = @_;
    &utf82utf8( *u, $option ) if $option;
    local ($n) = 0;
    $u =~ s/($re_utf8_c)/$n++, &u2s($1)/geo;
    $n;
}

#---------------------------------------------------------------------
sub u2s {
    local ($utf8);
    local ($code) = @_;
    &init_utf82sjis unless %utf82sjis_1;
    $utf8 = unpack( 'H*', $code );
    if ($u2s{$code}) {
        $u2s{$code};
    }
    elsif ( defined $JP170559{$utf8} ) {
        if ($cache) {
            $u2s{$code} = pack( 'H*', $JP170559{$utf8} );
        }
        else {
            pack( 'H*', $JP170559{$utf8} );
        }
    }
    elsif ( defined $utf82sjis_1{$utf8} ) {
        if ($cache) {
            $u2s{$code} = pack( 'H*', $utf82sjis_1{$utf8} );
        }
        else {
            pack( 'H*', $utf82sjis_1{$utf8} );
        }
    }
    elsif ( defined $utf82sjis_2{$utf8} ) {
        if ($cache) {
            $u2s{$code} = pack( 'H*', $utf82sjis_2{$utf8} );
        }
        else {
            pack( 'H*', $utf82sjis_2{$utf8} );
        }
    }
    else {
        $undef_sjis;
    }
}

#---------------------------------------------------------------------
# JIS to UTF-8
#---------------------------------------------------------------------
sub jis2utf8 {
    local ( *u, $option ) = @_;
    &jis2jis( *u, $option ) if $option;
    local ($n) = 0;
    $u =~ s/($re_esc_jp|$re_esc_asc|$re_esc_kana)([^\e]*)/&_jis2utf8($1,$2)/geo;
    $n;
}

#---------------------------------------------------------------------
sub _jis2utf8 {
    local ( $esc, $s ) = @_;
    if ( $esc =~ /^$re_esc_asc/o ) {
    }
    elsif ( $esc =~ /^$re_esc_kana/o ) {
        &init_k2u unless %k2u;
        $s =~ tr/\x21-\x7e/\xa1-\xfe/;
        $s =~ s/([\x00-\xff])/$n++, $k2u{$1}/ge;
    }
    elsif ( $esc =~ /^$re_esc_jis0212/o ) {
        $s =~ s/[\x00-\xff][\x00-\xff]/$n++, $undef_utf8/ge;
    }
    else {
        $s =~ tr/\x21-\x7e/\xa1-\xfe/;
        $s =~ s/($re_euc_c)/$n++, ($e2u{$1}||&e2u($1))/geo;
    }
    $s;
}

#---------------------------------------------------------------------
# EUC-JP to UTF-8
#---------------------------------------------------------------------
sub euc2utf8 {
    local ( *u, $option ) = @_;
    &euc2euc( *u, $option ) if $option;
    local ($n) = 0;
    $u =~ s/($re_euc_c|$re_euc_kana|$re_euc_0212)/$n++, &_euc2utf8($1)/geo;
    $n;
}

#---------------------------------------------------------------------
sub _euc2utf8 {
    local ($s) = @_;
    if ( $s =~ /^$re_euc_0212/o ) {
        $s =~ s/[\x00-\xff][\x00-\xff]/$undef_utf8/g;
    }
    elsif ( $s =~ /^$re_euc_kana/o ) {
        &init_k2u unless %k2u;
        $s =~ s/\x8e([\x00-\xff])/$k2u{$1}/ge;
    }
    else {
        $s =~ s/($re_euc_c)/$e2u{$1}||&e2u($1)/geo;
    }
    $s;
}

#---------------------------------------------------------------------
sub e2u {
    local ( $c1, $c2, $euc, $sjis );
    ( $c1, $c2 ) = unpack( 'CC', $euc = shift );
    if ( $c1 % 2 ) {
        $c1 = ( $c1 >> 1 ) + ( $c1 < 0xdf ? 0x31 : 0x71 );
        $c2 -= 0x60 + ( $c2 < 0xe0 );
    }
    else {
        $c1 = ( $c1 >> 1 ) + ( $c1 < 0xdf ? 0x30 : 0x70 );
        $c2 -= 2;
    }
    &init_sjis2utf8 unless %sjis2utf8_1;
    $sjis = unpack( 'H*', pack( 'CC', $c1, $c2 ) );
    if ( defined $sjis2utf8_1{$sjis} ) {
        if ($cache) {
            $e2u{$euc} = pack( 'H*', $sjis2utf8_1{$sjis} );
        }
        else {
            pack( 'H*', $sjis2utf8_1{$sjis} );
        }
    }
    elsif ( defined $sjis2utf8_2{$sjis} ) {
        if ($cache) {
            $e2u{$euc} = pack( 'H*', $sjis2utf8_2{$sjis} );
        }
        else {
            pack( 'H*', $sjis2utf8_2{$sjis} );
        }
    }
    else {
        $undef_utf8;
    }
}

#---------------------------------------------------------------------
# SJIS to UTF-8
#---------------------------------------------------------------------
sub sjis2utf8 {
    local ( *s, $option ) = @_;
    &sjis2sjis( *s, $option ) if $option;
    local ($n) = 0;
    $s =~ s/($re_sjis_c|$re_sjis_kana)/$n++, &s2u($1)/geo;
    $n;
}

#---------------------------------------------------------------------
sub s2u {
    local ($sjis);
    local ($code) = @_;
    &init_k2u unless %k2u;
    &init_sjis2utf8 unless %sjis2utf8_1;
    $sjis = unpack( 'H*', $code );
    if ($s2u{$code}) {
        $s2u{$code};
    }
    elsif ($k2u{$code}) {
        $k2u{$code};
    }
    elsif ( defined $sjis2utf8_1{$sjis} ) {
        if ($cache) {
            $s2u{$code} = pack( 'H*', $sjis2utf8_1{$sjis} );
        }
        else {
            pack( 'H*', $sjis2utf8_1{$sjis} );
        }
    }
    elsif ( defined $sjis2utf8_2{$sjis} ) {
        if ($cache) {
            $s2u{$code} = pack( 'H*', $sjis2utf8_2{$sjis} );
        }
        else {
            pack( 'H*', $sjis2utf8_2{$sjis} );
        }
    }
    else {
        $undef_utf8;
    }
}

#---------------------------------------------------------------------
# JIS to JIS, SJIS to SJIS, EUC-JP to EUC-JP, UTF-8 to UTF-8
#---------------------------------------------------------------------
sub jis2jis {
    local ( *s, $option ) = @_;
    local ($n) = 0;
    $s =~ s/$re_esc_jis0208/$esc_0208/go;
    $s =~ s/$re_esc_asc/$esc_asc/go;
    if ( defined $option ) {
        if ( $option =~ /z/ ) {
            &h2z_jis(*s);
        }
        elsif ( $option =~ /h/ ) {
            &z2h_jis(*s);
        }
    }
    $n;
}

#---------------------------------------------------------------------
sub sjis2sjis {
    local ( *s, $option ) = @_;
    local ($n) = 0;
    if ( defined $option ) {
        if ( $option =~ /z/ ) {
            &h2z_sjis(*s);
        }
        elsif ( $option =~ /h/ ) {
            &z2h_sjis(*s);
        }
    }
    $n;
}

#---------------------------------------------------------------------
sub euc2euc {
    local ( *s, $option ) = @_;
    local ($n) = 0;
    if ( defined $option ) {
        if ( $option =~ /z/ ) {
            &h2z_euc(*s);
        }
        elsif ( $option =~ /h/ ) {
            &z2h_euc(*s);
        }
    }
    $n;
}

#---------------------------------------------------------------------
sub utf82utf8 {
    local ( *s, $option ) = @_;
    local ($n) = 0;
    if ( defined $option ) {
        if ( $option =~ /z/ ) {
            &h2z_utf8(*s);
        }
        elsif ( $option =~ /h/ ) {
            &z2h_utf8(*s);
        }
    }
    $n;
}

#---------------------------------------------------------------------
# Cache control functions
#---------------------------------------------------------------------
sub cache {
    local ($previous) = $cache;
    $cache = 1;
    $previous;
}

#---------------------------------------------------------------------
sub nocache {
    local ($previous) = $cache;
    $cache = 0;
    $previous;
}

#---------------------------------------------------------------------
sub flush {
    &flushcache();
}

#---------------------------------------------------------------------
sub flushcache {
    undef %e2s;
    undef %s2e;
    undef %e2u;
    undef %u2e;
    undef %s2u;
    undef %u2s;
}

#---------------------------------------------------------------------
# JIS X0201 -> JIS X0208 KANA conversion routines
#---------------------------------------------------------------------
sub h2z_jis {
    local ( *s, $n ) = @_;
    if ( $s =~ s/$re_esc_kana([^\e]*)/$esc_0208 . &_h2z_jis($1)/geo ) {
        1 while $s =~ s/(($re_esc_jis0208)[^\e]*)($re_esc_jis0208)/$1/o;
    }
    $n;
}

#---------------------------------------------------------------------
sub _h2z_jis {
    local ($s) = @_;
    $s =~ s/(([\x21-\x5f])([\x5e\x5f])?)/
    $n++, ($h2z{$1} || $h2z{$2} . $h2z{$3})
    /ge;
    $s;
}

# Ad hoc patch for reduce waring on h2z_euc
# http://white.niu.ne.jp/yapw/yapw.cgi/jcode.pl%A4%CE%A5%A8%A5%E9%A1%BC%CD%DE%C0%A9
# by NAKATA Yoshinori

#---------------------------------------------------------------------
sub h2z_euc {
    local ( *s, $n ) = @_;
    $s =~ s/\x8e([\xa1-\xdf])(\x8e([\xde\xdf]))?/
    ($n++, defined($3) ? ($h2z{"$1$3"} || $h2z{$1} . $h2z{$3}) : $h2z{$1})
    /ge;
    $n;
}

#---------------------------------------------------------------------
sub h2z_sjis {
    local ( *s, $n ) = @_;
    $s =~ s/(($re_sjis_c)+)|(([\xa1-\xdf])([\xde\xdf])?)/
    $1 || ($n++, $h2z{$3} ? $e2s{$h2z{$3}} || &e2s($h2z{$3})
                  : &e2s($h2z{$4}) . ($5 && &e2s($h2z{$5})))
    /geo;
    $n;
}

#---------------------------------------------------------------------
sub h2z_utf8 {
    local ( *s, $n ) = @_;
    &init_h2z_utf8 unless %h2z_utf8;
    $s =~
s/($re_utf8_voiced_kana|$re_utf8_c)/$h2z_utf8{$1} ? ($n++, $h2z_utf8{$1}) : $1/geo;
    $n;
}

#---------------------------------------------------------------------
# JIS X0208 -> JIS X0201 KANA conversion routines
#---------------------------------------------------------------------
sub z2h_jis {
    local ( *s, $n ) = @_;
    $s =~ s/($re_esc_jis0208)([^\e]+)/&_z2h_jis($2)/geo;
    $n;
}

#---------------------------------------------------------------------
sub _z2h_jis {
    local ($s) = @_;
    $s =~ s/((\%[!-~]|![\#\"&VW+,<])+|([^!%][!-~]|![^\#\"&VW+,<])+)/
    &__z2h_jis($1)
    /ge;
    $s;
}

#---------------------------------------------------------------------
sub __z2h_jis {
    local ($s) = @_;
    return $esc_0208 . $s unless $s =~ /^%/ || $s =~ /^![\#\"&VW+,<]/;
    $n += length($s) / 2;
    $s =~ s/([\x00-\xff][\x00-\xff])/$z2h{$1}/g;
    $esc_kana . $s;
}

#---------------------------------------------------------------------
sub z2h_euc {
    local ( *s, $n ) = @_;
    &init_z2h_euc unless %z2h_euc;
    $s =~ s/($re_euc_c|$re_euc_kana)/
    $z2h_euc{$1} ? ($n++, $z2h_euc{$1}) : $1
    /geo;
    $n;
}

#---------------------------------------------------------------------
sub z2h_sjis {
    local ( *s, $n ) = @_;
    &init_z2h_sjis unless %z2h_sjis;
    $s =~ s/($re_sjis_c)/$z2h_sjis{$1} ? ($n++, $z2h_sjis{$1}) : $1/geo;
    $n;
}

#---------------------------------------------------------------------
sub z2h_utf8 {
    local ( *s, $n ) = @_;
    &init_z2h_utf8 unless %z2h_utf8;
    $s =~ s/($re_utf8_c)/$z2h_utf8{$1} ? ($n++, $z2h_utf8{$1}) : $1/geo;
    $n;
}

#
# Initializing JIS X0208 to JIS X0201 KANA table for EUC-JP and SJIS
# and UTF-8
# This can be done in &init but it's not worth doing.  Similarly,
# precalculated table is not worth to occupy the file space and
# reduce the readability.  The author personnaly discourages to use
# JIS X0201 Kana character in the any situation.
#

#---------------------------------------------------------------------
sub init_z2h_euc {
    local ( $k, $s );
    while ( ( $k, $s ) = each %z2h ) {
        $s =~ s/([\xa1-\xdf])/\x8e$1/g && ( $z2h_euc{$k} = $s );
    }
}

#---------------------------------------------------------------------
sub init_z2h_sjis {
    local ( $s, $v );
    while ( ( $s, $v ) = each %z2h ) {
        $s =~ /[\x80-\xff]/ && ( $z2h_sjis{ &e2s($s) } = $v );
    }
}

%_z2h_utf8 = split( /\s+/, <<'END' );
e38082 efbda1
e3808c efbda2
e3808d efbda3
e38081 efbda4
e383bb efbda5
e383b2 efbda6
e382a1 efbda7
e382a3 efbda8
e382a5 efbda9
e382a7 efbdaa
e382a9 efbdab
e383a3 efbdac
e383a5 efbdad
e383a7 efbdae
e38383 efbdaf
e383bc efbdb0
e382a2 efbdb1
e382a4 efbdb2
e382a6 efbdb3
e382a8 efbdb4
e382aa efbdb5
e382ab efbdb6
e382ad efbdb7
e382af efbdb8
e382b1 efbdb9
e382b3 efbdba
e382b5 efbdbb
e382b7 efbdbc
e382b9 efbdbd
e382bb efbdbe
e382bd efbdbf
e382bf efbe80
e38381 efbe81
e38384 efbe82
e38386 efbe83
e38388 efbe84
e3838a efbe85
e3838b efbe86
e3838c efbe87
e3838d efbe88
e3838e efbe89
e3838f efbe8a
e38392 efbe8b
e38395 efbe8c
e38398 efbe8d
e3839b efbe8e
e3839e efbe8f
e3839f efbe90
e383a0 efbe91
e383a1 efbe92
e383a2 efbe93
e383a4 efbe94
e383a6 efbe95
e383a8 efbe96
e383a9 efbe97
e383aa efbe98
e383ab efbe99
e383ac efbe9a
e383ad efbe9b
e383af efbe9c
e383b3 efbe9d
e3829b efbe9e
e3829c efbe9f
e383b4 efbdb3efbe9e
e382ac efbdb6efbe9e
e382ae efbdb7efbe9e
e382b0 efbdb8efbe9e
e382b2 efbdb9efbe9e
e382b4 efbdbaefbe9e
e382b6 efbdbbefbe9e
e382b8 efbdbcefbe9e
e382ba efbdbdefbe9e
e382bc efbdbeefbe9e
e382be efbdbfefbe9e
e38380 efbe80efbe9e
e38382 efbe81efbe9e
e38385 efbe82efbe9e
e38387 efbe83efbe9e
e38389 efbe84efbe9e
e38390 efbe8aefbe9e
e38393 efbe8befbe9e
e38396 efbe8cefbe9e
e38399 efbe8defbe9e
e3839c efbe8eefbe9e
e38391 efbe8aefbe9f
e38394 efbe8befbe9f
e38397 efbe8cefbe9f
e3839a efbe8defbe9f
e3839d efbe8eefbe9f
END

if ( scalar(keys %_z2h_utf8) != 89 ) {
    die "scalar(keys %_z2h_utf8) is ", scalar(keys %_z2h_utf8), ".";
}

#---------------------------------------------------------------------
sub init_z2h_utf8 {
    if (%h2z_utf8) {
        %z2h_utf8 = reverse %h2z_utf8;
        if ( scalar( keys %z2h_utf8 ) != scalar( keys %h2z_utf8 ) ) {
            die "scalar(keys %z2h_utf8) != scalar(keys %h2z_utf8).";
        }
    }
    else {
        local ( $z, $h );
        while ( ( $z, $h ) = each %_z2h_utf8 ) {
            $z2h_utf8{ pack( 'H*', $z ) } = pack( 'H*', $h );
        }
    }
}

#---------------------------------------------------------------------
sub init_h2z_utf8 {
    if (%z2h_utf8) {
        %h2z_utf8 = reverse %z2h_utf8;
        if ( scalar( keys %h2z_utf8 ) != scalar( keys %z2h_utf8 ) ) {
            die "scalar(keys %h2z_utf8) != scalar(keys %z2h_utf8).";
        }
    }
    else {
        local ( $z, $h );
        while ( ( $z, $h ) = each %_z2h_utf8 ) {
            $h2z_utf8{ pack( 'H*', $h ) } = pack( 'H*', $z );
        }
    }
}

# http://unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP932.TXT
#
#    Name:     cp932 to Unicode table
#    Unicode version: 2.0
#    Table version: 2.01
#    Table format:  Format A
#    Date:          04/15/98
#
#    Contact:       Shawn.Steele@microsoft.com
#
#    General notes: none
#
#    Format: Three tab-separated columns
#        Column #1 is the cp932 code (in hex)
#        Column #2 is the Unicode (in hex as 0xXXXX)
#        Column #3 is the Unicode name (follows a comment sign, '#')
#
#    The entries are in cp932 order
#

#---------------------------------------------------------------------
sub init_sjis2utf8 {

    # (1 of 2) avoid "Allocation too large" of perl 4.036

    %sjis2utf8_1 = split( /\s+/, <<'END' );
a1 efbda1
a2 efbda2
a3 efbda3
a4 efbda4
a5 efbda5
a6 efbda6
a7 efbda7
a8 efbda8
a9 efbda9
aa efbdaa
ab efbdab
ac efbdac
ad efbdad
ae efbdae
af efbdaf
b0 efbdb0
b1 efbdb1
b2 efbdb2
b3 efbdb3
b4 efbdb4
b5 efbdb5
b6 efbdb6
b7 efbdb7
b8 efbdb8
b9 efbdb9
ba efbdba
bb efbdbb
bc efbdbc
bd efbdbd
be efbdbe
bf efbdbf
c0 efbe80
c1 efbe81
c2 efbe82
c3 efbe83
c4 efbe84
c5 efbe85
c6 efbe86
c7 efbe87
c8 efbe88
c9 efbe89
ca efbe8a
cb efbe8b
cc efbe8c
cd efbe8d
ce efbe8e
cf efbe8f
d0 efbe90
d1 efbe91
d2 efbe92
d3 efbe93
d4 efbe94
d5 efbe95
d6 efbe96
d7 efbe97
d8 efbe98
d9 efbe99
da efbe9a
db efbe9b
dc efbe9c
dd efbe9d
de efbe9e
df efbe9f
8140 e38080
8141 e38081
8142 e38082
8143 efbc8c
8144 efbc8e
8145 e383bb
8146 efbc9a
8147 efbc9b
8148 efbc9f
8149 efbc81
814a e3829b
814b e3829c
814c c2b4
814d efbd80
814e c2a8
814f efbcbe
8150 efbfa3
8151 efbcbf
8152 e383bd
8153 e383be
8154 e3829d
8155 e3829e
8156 e38083
8157 e4bb9d
8158 e38085
8159 e38086
815a e38087
815b e383bc
815c e28095
815d e28090
815e efbc8f
815f efbcbc
8160 efbd9e
8161 e288a5
8162 efbd9c
8163 e280a6
8164 e280a5
8165 e28098
8166 e28099
8167 e2809c
8168 e2809d
8169 efbc88
816a efbc89
816b e38094
816c e38095
816d efbcbb
816e efbcbd
816f efbd9b
8170 efbd9d
8171 e38088
8172 e38089
8173 e3808a
8174 e3808b
8175 e3808c
8176 e3808d
8177 e3808e
8178 e3808f
8179 e38090
817a e38091
817b efbc8b
817c efbc8d
817d c2b1
817e c397
8180 c3b7
8181 efbc9d
8182 e289a0
8183 efbc9c
8184 efbc9e
8185 e289a6
8186 e289a7
8187 e2889e
8188 e288b4
8189 e29982
818a e29980
818b c2b0
818c e280b2
818d e280b3
818e e28483
818f efbfa5
8190 efbc84
8191 efbfa0
8192 efbfa1
8193 efbc85
8194 efbc83
8195 efbc86
8196 efbc8a
8197 efbca0
8198 c2a7
8199 e29886
819a e29885
819b e2978b
819c e2978f
819d e2978e
819e e29787
819f e29786
81a0 e296a1
81a1 e296a0
81a2 e296b3
81a3 e296b2
81a4 e296bd
81a5 e296bc
81a6 e280bb
81a7 e38092
81a8 e28692
81a9 e28690
81aa e28691
81ab e28693
81ac e38093
81b8 e28888
81b9 e2888b
81ba e28a86
81bb e28a87
81bc e28a82
81bd e28a83
81be e288aa
81bf e288a9
81c8 e288a7
81c9 e288a8
81ca efbfa2
81cb e28792
81cc e28794
81cd e28880
81ce e28883
81da e288a0
81db e28aa5
81dc e28c92
81dd e28882
81de e28887
81df e289a1
81e0 e28992
81e1 e289aa
81e2 e289ab
81e3 e2889a
81e4 e288bd
81e5 e2889d
81e6 e288b5
81e7 e288ab
81e8 e288ac
81f0 e284ab
81f1 e280b0
81f2 e299af
81f3 e299ad
81f4 e299aa
81f5 e280a0
81f6 e280a1
81f7 c2b6
81fc e297af
824f efbc90
8250 efbc91
8251 efbc92
8252 efbc93
8253 efbc94
8254 efbc95
8255 efbc96
8256 efbc97
8257 efbc98
8258 efbc99
8260 efbca1
8261 efbca2
8262 efbca3
8263 efbca4
8264 efbca5
8265 efbca6
8266 efbca7
8267 efbca8
8268 efbca9
8269 efbcaa
826a efbcab
826b efbcac
826c efbcad
826d efbcae
826e efbcaf
826f efbcb0
8270 efbcb1
8271 efbcb2
8272 efbcb3
8273 efbcb4
8274 efbcb5
8275 efbcb6
8276 efbcb7
8277 efbcb8
8278 efbcb9
8279 efbcba
8281 efbd81
8282 efbd82
8283 efbd83
8284 efbd84
8285 efbd85
8286 efbd86
8287 efbd87
8288 efbd88
8289 efbd89
828a efbd8a
828b efbd8b
828c efbd8c
828d efbd8d
828e efbd8e
828f efbd8f
8290 efbd90
8291 efbd91
8292 efbd92
8293 efbd93
8294 efbd94
8295 efbd95
8296 efbd96
8297 efbd97
8298 efbd98
8299 efbd99
829a efbd9a
829f e38181
82a0 e38182
82a1 e38183
82a2 e38184
82a3 e38185
82a4 e38186
82a5 e38187
82a6 e38188
82a7 e38189
82a8 e3818a
82a9 e3818b
82aa e3818c
82ab e3818d
82ac e3818e
82ad e3818f
82ae e38190
82af e38191
82b0 e38192
82b1 e38193
82b2 e38194
82b3 e38195
82b4 e38196
82b5 e38197
82b6 e38198
82b7 e38199
82b8 e3819a
82b9 e3819b
82ba e3819c
82bb e3819d
82bc e3819e
82bd e3819f
82be e381a0
82bf e381a1
82c0 e381a2
82c1 e381a3
82c2 e381a4
82c3 e381a5
82c4 e381a6
82c5 e381a7
82c6 e381a8
82c7 e381a9
82c8 e381aa
82c9 e381ab
82ca e381ac
82cb e381ad
82cc e381ae
82cd e381af
82ce e381b0
82cf e381b1
82d0 e381b2
82d1 e381b3
82d2 e381b4
82d3 e381b5
82d4 e381b6
82d5 e381b7
82d6 e381b8
82d7 e381b9
82d8 e381ba
82d9 e381bb
82da e381bc
82db e381bd
82dc e381be
82dd e381bf
82de e38280
82df e38281
82e0 e38282
82e1 e38283
82e2 e38284
82e3 e38285
82e4 e38286
82e5 e38287
82e6 e38288
82e7 e38289
82e8 e3828a
82e9 e3828b
82ea e3828c
82eb e3828d
82ec e3828e
82ed e3828f
82ee e38290
82ef e38291
82f0 e38292
82f1 e38293
8340 e382a1
8341 e382a2
8342 e382a3
8343 e382a4
8344 e382a5
8345 e382a6
8346 e382a7
8347 e382a8
8348 e382a9
8349 e382aa
834a e382ab
834b e382ac
834c e382ad
834d e382ae
834e e382af
834f e382b0
8350 e382b1
8351 e382b2
8352 e382b3
8353 e382b4
8354 e382b5
8355 e382b6
8356 e382b7
8357 e382b8
8358 e382b9
8359 e382ba
835a e382bb
835b e382bc
835c e382bd
835d e382be
835e e382bf
835f e38380
8360 e38381
8361 e38382
8362 e38383
8363 e38384
8364 e38385
8365 e38386
8366 e38387
8367 e38388
8368 e38389
8369 e3838a
836a e3838b
836b e3838c
836c e3838d
836d e3838e
836e e3838f
836f e38390
8370 e38391
8371 e38392
8372 e38393
8373 e38394
8374 e38395
8375 e38396
8376 e38397
8377 e38398
8378 e38399
8379 e3839a
837a e3839b
837b e3839c
837c e3839d
837d e3839e
837e e3839f
8380 e383a0
8381 e383a1
8382 e383a2
8383 e383a3
8384 e383a4
8385 e383a5
8386 e383a6
8387 e383a7
8388 e383a8
8389 e383a9
838a e383aa
838b e383ab
838c e383ac
838d e383ad
838e e383ae
838f e383af
8390 e383b0
8391 e383b1
8392 e383b2
8393 e383b3
8394 e383b4
8395 e383b5
8396 e383b6
839f ce91
83a0 ce92
83a1 ce93
83a2 ce94
83a3 ce95
83a4 ce96
83a5 ce97
83a6 ce98
83a7 ce99
83a8 ce9a
83a9 ce9b
83aa ce9c
83ab ce9d
83ac ce9e
83ad ce9f
83ae cea0
83af cea1
83b0 cea3
83b1 cea4
83b2 cea5
83b3 cea6
83b4 cea7
83b5 cea8
83b6 cea9
83bf ceb1
83c0 ceb2
83c1 ceb3
83c2 ceb4
83c3 ceb5
83c4 ceb6
83c5 ceb7
83c6 ceb8
83c7 ceb9
83c8 ceba
83c9 cebb
83ca cebc
83cb cebd
83cc cebe
83cd cebf
83ce cf80
83cf cf81
83d0 cf83
83d1 cf84
83d2 cf85
83d3 cf86
83d4 cf87
83d5 cf88
83d6 cf89
8440 d090
8441 d091
8442 d092
8443 d093
8444 d094
8445 d095
8446 d081
8447 d096
8448 d097
8449 d098
844a d099
844b d09a
844c d09b
844d d09c
844e d09d
844f d09e
8450 d09f
8451 d0a0
8452 d0a1
8453 d0a2
8454 d0a3
8455 d0a4
8456 d0a5
8457 d0a6
8458 d0a7
8459 d0a8
845a d0a9
845b d0aa
845c d0ab
845d d0ac
845e d0ad
845f d0ae
8460 d0af
8470 d0b0
8471 d0b1
8472 d0b2
8473 d0b3
8474 d0b4
8475 d0b5
8476 d191
8477 d0b6
8478 d0b7
8479 d0b8
847a d0b9
847b d0ba
847c d0bb
847d d0bc
847e d0bd
8480 d0be
8481 d0bf
8482 d180
8483 d181
8484 d182
8485 d183
8486 d184
8487 d185
8488 d186
8489 d187
848a d188
848b d189
848c d18a
848d d18b
848e d18c
848f d18d
8490 d18e
8491 d18f
849f e29480
84a0 e29482
84a1 e2948c
84a2 e29490
84a3 e29498
84a4 e29494
84a5 e2949c
84a6 e294ac
84a7 e294a4
84a8 e294b4
84a9 e294bc
84aa e29481
84ab e29483
84ac e2948f
84ad e29493
84ae e2949b
84af e29497
84b0 e294a3
84b1 e294b3
84b2 e294ab
84b3 e294bb
84b4 e2958b
84b5 e294a0
84b6 e294af
84b7 e294a8
84b8 e294b7
84b9 e294bf
84ba e2949d
84bb e294b0
84bc e294a5
84bd e294b8
84be e29582
8740 e291a0
8741 e291a1
8742 e291a2
8743 e291a3
8744 e291a4
8745 e291a5
8746 e291a6
8747 e291a7
8748 e291a8
8749 e291a9
874a e291aa
874b e291ab
874c e291ac
874d e291ad
874e e291ae
874f e291af
8750 e291b0
8751 e291b1
8752 e291b2
8753 e291b3
8754 e285a0
8755 e285a1
8756 e285a2
8757 e285a3
8758 e285a4
8759 e285a5
875a e285a6
875b e285a7
875c e285a8
875d e285a9
875f e38d89
8760 e38c94
8761 e38ca2
8762 e38d8d
8763 e38c98
8764 e38ca7
8765 e38c83
8766 e38cb6
8767 e38d91
8768 e38d97
8769 e38c8d
876a e38ca6
876b e38ca3
876c e38cab
876d e38d8a
876e e38cbb
876f e38e9c
8770 e38e9d
8771 e38e9e
8772 e38e8e
8773 e38e8f
8774 e38f84
8775 e38ea1
877e e38dbb
8780 e3809d
8781 e3809f
8782 e28496
8783 e38f8d
8784 e284a1
8785 e38aa4
8786 e38aa5
8787 e38aa6
8788 e38aa7
8789 e38aa8
878a e388b1
878b e388b2
878c e388b9
878d e38dbe
878e e38dbd
878f e38dbc
8790 e28992
8791 e289a1
8792 e288ab
8793 e288ae
8794 e28891
8795 e2889a
8796 e28aa5
8797 e288a0
8798 e2889f
8799 e28abf
879a e288b5
879b e288a9
879c e288aa
889f e4ba9c
88a0 e59496
88a1 e5a883
88a2 e998bf
88a3 e59380
88a4 e6849b
88a5 e68ca8
88a6 e5a7b6
88a7 e980a2
88a8 e891b5
88a9 e88c9c
88aa e7a990
88ab e682aa
88ac e68fa1
88ad e6b8a5
88ae e697ad
88af e891a6
88b0 e88aa6
88b1 e9afb5
88b2 e6a293
88b3 e59ca7
88b4 e696a1
88b5 e689b1
88b6 e5ae9b
88b7 e5a790
88b8 e899bb
88b9 e9a3b4
88ba e7b5a2
88bb e7b6be
88bc e9ae8e
88bd e68896
88be e7b29f
88bf e8a2b7
88c0 e5ae89
88c1 e5bab5
88c2 e68c89
88c3 e69a97
88c4 e6a188
88c5 e99787
88c6 e99e8d
88c7 e69d8f
88c8 e4bba5
88c9 e4bc8a
88ca e4bd8d
88cb e4be9d
88cc e58189
88cd e59bb2
88ce e5a4b7
88cf e5a794
88d0 e5a881
88d1 e5b089
88d2 e6839f
88d3 e6848f
88d4 e685b0
88d5 e69893
88d6 e6a485
88d7 e782ba
88d8 e7958f
88d9 e795b0
88da e7a7bb
88db e7b6ad
88dc e7b7af
88dd e88383
88de e8908e
88df e8a1a3
88e0 e8ac82
88e1 e98195
88e2 e981ba
88e3 e58cbb
88e4 e4ba95
88e5 e4baa5
88e6 e59f9f
88e7 e882b2
88e8 e98381
88e9 e7a3af
88ea e4b880
88eb e5a3b1
88ec e6baa2
88ed e980b8
88ee e7a8b2
88ef e88ca8
88f0 e88a8b
88f1 e9b0af
88f2 e58581
88f3 e58db0
88f4 e592bd
88f5 e593a1
88f6 e59ba0
88f7 e5a7bb
88f8 e5bc95
88f9 e9a3b2
88fa e6b7ab
88fb e883a4
88fc e894ad
8940 e999a2
8941 e999b0
8942 e99aa0
8943 e99fbb
8944 e5908b
8945 e58fb3
8946 e5ae87
8947 e7838f
8948 e7bebd
8949 e8bf82
894a e99ba8
894b e58daf
894c e9b59c
894d e7aaba
894e e4b891
894f e7a293
8950 e887bc
8951 e6b8a6
8952 e59898
8953 e59484
8954 e6ac9d
8955 e8949a
8956 e9b0bb
8957 e5a7a5
8958 e58ea9
8959 e6b5a6
895a e7939c
895b e9968f
895c e59982
895d e4ba91
895e e9818b
895f e99bb2
8960 e88d8f
8961 e9a48c
8962 e58fa1
8963 e596b6
8964 e5acb0
8965 e5bdb1
8966 e698a0
8967 e69bb3
8968 e6a084
8969 e6b0b8
896a e6b3b3
896b e6b4a9
896c e7919b
896d e79b88
896e e7a98e
896f e9a0b4
8970 e88bb1
8971 e8a19b
8972 e8a9a0
8973 e98bad
8974 e6b6b2
8975 e796ab
8976 e79b8a
8977 e9a785
8978 e682a6
8979 e8ac81
897a e8b68a
897b e996b2
897c e6a68e
897d e58ead
897e e58686
8980 e59c92
8981 e5a0b0
8982 e5a584
8983 e5aeb4
8984 e5bbb6
8985 e680a8
8986 e68ea9
8987 e68fb4
8988 e6b2bf
8989 e6bc94
898a e7828e
898b e78494
898c e78599
898d e78795
898e e78cbf
898f e7b881
8990 e889b6
8991 e88b91
8992 e89697
8993 e981a0
8994 e9899b
8995 e9b49b
8996 e5a1a9
8997 e696bc
8998 e6b19a
8999 e794a5
899a e587b9
899b e5a4ae
899c e5a5a5
899d e5be80
899e e5bf9c
899f e68abc
89a0 e697ba
89a1 e6a8aa
89a2 e6aca7
89a3 e6aeb4
89a4 e78e8b
89a5 e7bf81
89a6 e8a596
89a7 e9b4ac
89a8 e9b48e
89a9 e9bb84
89aa e5b2a1
89ab e6b296
89ac e88dbb
89ad e58484
89ae e5b18b
89af e686b6
89b0 e88786
89b1 e6a1b6
89b2 e789a1
89b3 e4b999
89b4 e4bfba
89b5 e58db8
89b6 e681a9
89b7 e6b8a9
89b8 e7a98f
89b9 e99fb3
89ba e4b88b
89bb e58c96
89bc e4bbae
89bd e4bd95
89be e4bcbd
89bf e4bea1
89c0 e4bdb3
89c1 e58aa0
89c2 e58faf
89c3 e59889
89c4 e5a48f
89c5 e5ab81
89c6 e5aeb6
89c7 e5afa1
89c8 e7a791
89c9 e69a87
89ca e69e9c
89cb e69eb6
89cc e6ad8c
89cd e6b2b3
89ce e781ab
89cf e78f82
89d0 e7a68d
89d1 e7a6be
89d2 e7a8bc
89d3 e7ae87
89d4 e88ab1
89d5 e88b9b
89d6 e88c84
89d7 e88db7
89d8 e88faf
89d9 e88f93
89da e89da6
89db e8aab2
89dc e598a9
89dd e8b2a8
89de e8bfa6
89df e9818e
89e0 e99c9e
89e1 e89a8a
89e2 e4bf84
89e3 e5b3a8
89e4 e68891
89e5 e78999
89e6 e794bb
89e7 e887a5
89e8 e88abd
89e9 e89bbe
89ea e8b380
89eb e99b85
89ec e9a493
89ed e9a795
89ee e4bb8b
89ef e4bc9a
89f0 e8a7a3
89f1 e59b9e
89f2 e5a18a
89f3 e5a38a
89f4 e5bbbb
89f5 e5bfab
89f6 e680aa
89f7 e68294
89f8 e681a2
89f9 e68790
89fa e68892
89fb e68b90
89fc e694b9
8a40 e9ad81
8a41 e699a6
8a42 e6a2b0
8a43 e6b5b7
8a44 e781b0
8a45 e7958c
8a46 e79a86
8a47 e7b5b5
8a48 e88aa5
8a49 e89fb9
8a4a e9968b
8a4b e99a8e
8a4c e8b29d
8a4d e587b1
8a4e e58abe
8a4f e5a496
8a50 e592b3
8a51 e5aeb3
8a52 e5b496
8a53 e685a8
8a54 e6a682
8a55 e6b6af
8a56 e7a28d
8a57 e8938b
8a58 e8a197
8a59 e8a9b2
8a5a e98ea7
8a5b e9aab8
8a5c e6b5ac
8a5d e9a6a8
8a5e e89b99
8a5f e59ea3
8a60 e69fbf
8a61 e89b8e
8a62 e9888e
8a63 e58a83
8a64 e59a87
8a65 e59084
8a66 e5bb93
8a67 e68ba1
8a68 e692b9
8a69 e6a0bc
8a6a e6a0b8
8a6b e6aebb
8a6c e78db2
8a6d e7a2ba
8a6e e7a9ab
8a6f e8a69a
8a70 e8a792
8a71 e8b5ab
8a72 e8bc83
8a73 e983ad
8a74 e996a3
8a75 e99a94
8a76 e99da9
8a77 e5ada6
8a78 e5b2b3
8a79 e6a5bd
8a7a e9a18d
8a7b e9a18e
8a7c e68e9b
8a7d e7aca0
8a7e e6a8ab
8a80 e6a9bf
8a81 e6a2b6
8a82 e9b08d
8a83 e6bd9f
8a84 e589b2
8a85 e5969d
8a86 e681b0
8a87 e68bac
8a88 e6b4bb
8a89 e6b887
8a8a e6bb91
8a8b e8919b
8a8c e8a490
8a8d e8bd84
8a8e e4b894
8a8f e9b0b9
8a90 e58fb6
8a91 e6a49b
8a92 e6a8ba
8a93 e99e84
8a94 e6a0aa
8a95 e5859c
8a96 e7ab83
8a97 e892b2
8a98 e9879c
8a99 e98e8c
8a9a e5999b
8a9b e9b4a8
8a9c e6a0a2
8a9d e88c85
8a9e e890b1
8a9f e7b2a5
8aa0 e58888
8aa1 e88b85
8aa2 e793a6
8aa3 e4b9be
8aa4 e4be83
8aa5 e586a0
8aa6 e5af92
8aa7 e5888a
8aa8 e58b98
8aa9 e58ba7
8aaa e5b7bb
8aab e5969a
8aac e5a0aa
8aad e5a7a6
8aae e5ae8c
8aaf e5ae98
8ab0 e5af9b
8ab1 e5b9b2
8ab2 e5b9b9
8ab3 e682a3
8ab4 e6849f
8ab5 e685a3
8ab6 e686be
8ab7 e68f9b
8ab8 e695a2
8ab9 e69f91
8aba e6a193
8abb e6a3ba
8abc e6acbe
8abd e6ad93
8abe e6b197
8abf e6bca2
8ac0 e6be97
8ac1 e6bd85
8ac2 e792b0
8ac3 e79498
8ac4 e79ba3
8ac5 e79c8b
8ac6 e7abbf
8ac7 e7aea1
8ac8 e7b0a1
8ac9 e7b7a9
8aca e7bcb6
8acb e7bfb0
8acc e8829d
8acd e889a6
8ace e88e9e
8acf e8a6b3
8ad0 e8ab8c
8ad1 e8b2ab
8ad2 e98284
8ad3 e99191
8ad4 e99693
8ad5 e99691
8ad6 e996a2
8ad7 e999a5
8ad8 e99f93
8ad9 e9a4a8
8ada e88898
8adb e4b8b8
8adc e590ab
8add e5b2b8
8ade e5b78c
8adf e78ea9
8ae0 e7998c
8ae1 e79cbc
8ae2 e5b2a9
8ae3 e7bfab
8ae4 e8b48b
8ae5 e99b81
8ae6 e9a091
8ae7 e9a194
8ae8 e9a198
8ae9 e4bc81
8aea e4bc8e
8aeb e58db1
8aec e5969c
8aed e599a8
8aee e59fba
8aef e5a587
8af0 e5ac89
8af1 e5af84
8af2 e5b290
8af3 e5b88c
8af4 e5b9be
8af5 e5bf8c
8af6 e68fae
8af7 e69cba
8af8 e69797
8af9 e697a2
8afa e69c9f
8afb e6a38b
8afc e6a384
8b40 e6a99f
8b41 e5b8b0
8b42 e6af85
8b43 e6b097
8b44 e6b1bd
8b45 e795bf
8b46 e7a588
8b47 e5ada3
8b48 e7a880
8b49 e7b480
8b4a e5bebd
8b4b e8a68f
8b4c e8a898
8b4d e8b2b4
8b4e e8b5b7
8b4f e8bb8c
8b50 e8bc9d
8b51 e9a3a2
8b52 e9a88e
8b53 e9acbc
8b54 e4ba80
8b55 e581bd
8b56 e58480
8b57 e5a693
8b58 e5ae9c
8b59 e688af
8b5a e68a80
8b5b e693ac
8b5c e6acba
8b5d e78aa0
8b5e e79691
8b5f e7a587
8b60 e7bea9
8b61 e89fbb
8b62 e8aabc
8b63 e8adb0
8b64 e68eac
8b65 e88f8a
8b66 e99ea0
8b67 e59089
8b68 e59083
8b69 e596ab
8b6a e6a194
8b6b e6a998
8b6c e8a9b0
8b6d e7a0a7
8b6e e69db5
8b6f e9bb8d
8b70 e58db4
8b71 e5aea2
8b72 e8849a
8b73 e89990
8b74 e98086
8b75 e4b898
8b76 e4b985
8b77 e4bb87
8b78 e4bc91
8b79 e58f8a
8b7a e590b8
8b7b e5aeae
8b7c e5bc93
8b7d e680a5
8b7e e69591
8b80 e69cbd
8b81 e6b182
8b82 e6b1b2
8b83 e6b3a3
8b84 e781b8
8b85 e79083
8b86 e7a9b6
8b87 e7aaae
8b88 e7ac88
8b89 e7b49a
8b8a e7b3be
8b8b e7b5a6
8b8c e697a7
8b8d e7899b
8b8e e58ebb
8b8f e5b185
8b90 e5b7a8
8b91 e68b92
8b92 e68ba0
8b93 e68c99
8b94 e6b8a0
8b95 e8999a
8b96 e8a8b1
8b97 e8b79d
8b98 e98bb8
8b99 e6bc81
8b9a e7a6a6
8b9b e9ad9a
8b9c e4baa8
8b9d e4baab
8b9e e4baac
8b9f e4be9b
8ba0 e4bea0
8ba1 e58391
8ba2 e58587
8ba3 e7abb6
8ba4 e585b1
8ba5 e587b6
8ba6 e58d94
8ba7 e58ca1
8ba8 e58dbf
8ba9 e58fab
8baa e596ac
8bab e5a283
8bac e5b3a1
8bad e5bcb7
8bae e5bd8a
8baf e680af
8bb0 e68190
8bb1 e681ad
8bb2 e68c9f
8bb3 e69599
8bb4 e6a98b
8bb5 e6b381
8bb6 e78b82
8bb7 e78bad
8bb8 e79faf
8bb9 e883b8
8bba e88485
8bbb e88888
8bbc e8958e
8bbd e983b7
8bbe e98fa1
8bbf e99fbf
8bc0 e9a597
8bc1 e9a99a
8bc2 e4bbb0
8bc3 e5879d
8bc4 e5b0ad
8bc5 e69a81
8bc6 e6a5ad
8bc7 e5b180
8bc8 e69bb2
8bc9 e6a5b5
8bca e78e89
8bcb e6a190
8bcc e7b281
8bcd e58385
8bce e58ba4
8bcf e59d87
8bd0 e5b7be
8bd1 e98ca6
8bd2 e696a4
8bd3 e6aca3
8bd4 e6acbd
8bd5 e790b4
8bd6 e7a681
8bd7 e7a6bd
8bd8 e7ad8b
8bd9 e7b78a
8bda e88ab9
8bdb e88f8c
8bdc e8a1bf
8bdd e8a59f
8bde e8acb9
8bdf e8bf91
8be0 e98791
8be1 e5909f
8be2 e98a80
8be3 e4b99d
8be4 e580b6
8be5 e58fa5
8be6 e58cba
8be7 e78b97
8be8 e78e96
8be9 e79fa9
8bea e88ba6
8beb e8baaf
8bec e9a786
8bed e9a788
8bee e9a792
8bef e585b7
8bf0 e6849a
8bf1 e8999e
8bf2 e596b0
8bf3 e7a9ba
8bf4 e581b6
8bf5 e5af93
8bf6 e98187
8bf7 e99a85
8bf8 e4b8b2
8bf9 e6ab9b
8bfa e987a7
8bfb e5b191
8bfc e5b188
8c40 e68e98
8c41 e7aa9f
8c42 e6b293
8c43 e99db4
8c44 e8bda1
8c45 e7aaaa
8c46 e7868a
8c47 e99a88
8c48 e7b282
8c49 e6a097
8c4a e7b9b0
8c4b e6a191
8c4c e98dac
8c4d e58bb2
8c4e e5909b
8c4f e896ab
8c50 e8a893
8c51 e7bea4
8c52 e8bb8d
8c53 e983a1
8c54 e58da6
8c55 e8a288
8c56 e7a581
8c57 e4bf82
8c58 e582be
8c59 e58891
8c5a e58584
8c5b e59593
8c5c e59cad
8c5d e78faa
8c5e e59e8b
8c5f e5a591
8c60 e5bda2
8c61 e5be84
8c62 e681b5
8c63 e685b6
8c64 e685a7
8c65 e686a9
8c66 e68eb2
8c67 e690ba
8c68 e695ac
8c69 e699af
8c6a e6a182
8c6b e6b893
8c6c e795a6
8c6d e7a8bd
8c6e e7b3bb
8c6f e7b58c
8c70 e7b699
8c71 e7b98b
8c72 e7bdab
8c73 e88c8e
8c74 e88d8a
8c75 e89b8d
8c76 e8a888
8c77 e8a9a3
8c78 e8ada6
8c79 e8bbbd
8c7a e9a09a
8c7b e9b68f
8c7c e88ab8
8c7d e8bf8e
8c7e e9afa8
8c80 e58a87
8c81 e6889f
8c82 e69283
8c83 e6bf80
8c84 e99a99
8c85 e6a181
8c86 e58291
8c87 e6aca0
8c88 e6b1ba
8c89 e6bd94
8c8a e7a9b4
8c8b e7b590
8c8c e8a180
8c8d e8a8a3
8c8e e69c88
8c8f e4bbb6
8c90 e580b9
8c91 e580a6
8c92 e581a5
8c93 e585bc
8c94 e588b8
8c95 e589a3
8c96 e596a7
8c97 e59c8f
8c98 e5a085
8c99 e5ab8c
8c9a e5bbba
8c9b e686b2
8c9c e687b8
8c9d e68bb3
8c9e e68db2
8c9f e6a49c
8ca0 e6a8a9
8ca1 e789bd
8ca2 e78aac
8ca3 e78cae
8ca4 e7a094
8ca5 e7a1af
8ca6 e7b5b9
8ca7 e79c8c
8ca8 e882a9
8ca9 e8a68b
8caa e8ac99
8cab e8b3a2
8cac e8bb92
8cad e981a3
8cae e98db5
8caf e999ba
8cb0 e9a195
8cb1 e9a893
8cb2 e9b9b8
8cb3 e58583
8cb4 e58e9f
8cb5 e58eb3
8cb6 e5b9bb
8cb7 e5bca6
8cb8 e6b89b
8cb9 e6ba90
8cba e78e84
8cbb e78fbe
8cbc e7b583
8cbd e888b7
8cbe e8a880
8cbf e8abba
8cc0 e99990
8cc1 e4b98e
8cc2 e5808b
8cc3 e58fa4
8cc4 e591bc
8cc5 e59bba
8cc6 e5a791
8cc7 e5ada4
8cc8 e5b7b1
8cc9 e5baab
8cca e5bca7
8ccb e688b8
8ccc e69585
8ccd e69eaf
8cce e6b996
8ccf e78b90
8cd0 e7b38a
8cd1 e8a2b4
8cd2 e882a1
8cd3 e883a1
8cd4 e88fb0
8cd5 e8998e
8cd6 e8aa87
8cd7 e8b7a8
8cd8 e988b7
8cd9 e99b87
8cda e9a1a7
8cdb e9bc93
8cdc e4ba94
8cdd e4ba92
8cde e4bc8d
8cdf e58d88
8ce0 e59189
8ce1 e590be
8ce2 e5a8af
8ce3 e5be8c
8ce4 e5bea1
8ce5 e6829f
8ce6 e6a2a7
8ce7 e6aa8e
8ce8 e7919a
8ce9 e7a281
8cea e8aa9e
8ceb e8aaa4
8cec e8adb7
8ced e98690
8cee e4b99e
8cef e9af89
8cf0 e4baa4
8cf1 e4bdbc
8cf2 e4beaf
8cf3 e58099
8cf4 e58096
8cf5 e58589
8cf6 e585ac
8cf7 e58a9f
8cf8 e58ab9
8cf9 e58bbe
8cfa e58e9a
8cfb e58fa3
8cfc e59091
8d40 e5908e
8d41 e59689
8d42 e59d91
8d43 e59ea2
8d44 e5a5bd
8d45 e5ad94
8d46 e5ad9d
8d47 e5ae8f
8d48 e5b7a5
8d49 e5b7a7
8d4a e5b7b7
8d4b e5b9b8
8d4c e5ba83
8d4d e5ba9a
8d4e e5bab7
8d4f e5bc98
8d50 e68192
8d51 e6858c
8d52 e68a97
8d53 e68b98
8d54 e68ea7
8d55 e694bb
8d56 e69882
8d57 e69983
8d58 e69bb4
8d59 e69dad
8d5a e6a0a1
8d5b e6a297
8d5c e6a78b
8d5d e6b19f
8d5e e6b4aa
8d5f e6b5a9
8d60 e6b8af
8d61 e6ba9d
8d62 e794b2
8d63 e79a87
8d64 e7a1ac
8d65 e7a8bf
8d66 e7b3a0
8d67 e7b485
8d68 e7b498
8d69 e7b59e
8d6a e7b6b1
8d6b e88095
8d6c e88083
8d6d e882af
8d6e e882b1
8d6f e88594
8d70 e8868f
8d71 e888aa
8d72 e88d92
8d73 e8a18c
8d74 e8a1a1
8d75 e8ac9b
8d76 e8b2a2
8d77 e8b3bc
8d78 e9838a
8d79 e985b5
8d7a e989b1
8d7b e7a0bf
8d7c e98bbc
8d7d e996a4
8d7e e9998d
8d80 e9a085
8d81 e9a699
8d82 e9ab98
8d83 e9b4bb
8d84 e5899b
8d85 e58aab
8d86 e58fb7
8d87 e59088
8d88 e5a395
8d89 e68bb7
8d8a e6bfa0
8d8b e8b1aa
8d8c e8bd9f
8d8d e9bab9
8d8e e5858b
8d8f e588bb
8d90 e5918a
8d91 e59bbd
8d92 e7a980
8d93 e985b7
8d94 e9b5a0
8d95 e9bb92
8d96 e78d84
8d97 e6bc89
8d98 e885b0
8d99 e79491
8d9a e5bfbd
8d9b e6839a
8d9c e9aaa8
8d9d e78b9b
8d9e e8bebc
8d9f e6ada4
8da0 e9a083
8da1 e4bb8a
8da2 e59bb0
8da3 e59da4
8da4 e5a2be
8da5 e5a99a
8da6 e681a8
8da7 e68787
8da8 e6988f
8da9 e69886
8daa e6a0b9
8dab e6a2b1
8dac e6b7b7
8dad e79795
8dae e7b4ba
8daf e889ae
8db0 e9ad82
8db1 e4ba9b
8db2 e4bd90
8db3 e58f89
8db4 e59486
8db5 e5b5af
8db6 e5b7a6
8db7 e5b7ae
8db8 e69fbb
8db9 e6b299
8dba e791b3
8dbb e7a082
8dbc e8a990
8dbd e98e96
8dbe e8a39f
8dbf e59d90
8dc0 e5baa7
8dc1 e68cab
8dc2 e582b5
8dc3 e582ac
8dc4 e5868d
8dc5 e69c80
8dc6 e59389
8dc7 e5a19e
8dc8 e5a6bb
8dc9 e5aeb0
8dca e5bda9
8dcb e6898d
8dcc e68ea1
8dcd e6a0bd
8dce e6adb3
8dcf e6b888
8dd0 e781bd
8dd1 e98787
8dd2 e78a80
8dd3 e7a095
8dd4 e7a0a6
8dd5 e7a5ad
8dd6 e6968e
8dd7 e7b4b0
8dd8 e88f9c
8dd9 e8a381
8dda e8bc89
8ddb e99a9b
8ddc e589a4
8ddd e59ca8
8dde e69d90
8ddf e7bdaa
8de0 e8b2a1
8de1 e586b4
8de2 e59d82
8de3 e998aa
8de4 e5a0ba
8de5 e6a68a
8de6 e882b4
8de7 e592b2
8de8 e5b48e
8de9 e59fbc
8dea e7a295
8deb e9b7ba
8dec e4bd9c
8ded e5898a
8dee e5928b
8def e690be
8df0 e698a8
8df1 e69c94
8df2 e69fb5
8df3 e7aa84
8df4 e7ad96
8df5 e7b4a2
8df6 e98caf
8df7 e6a19c
8df8 e9aead
8df9 e7acb9
8dfa e58c99
8dfb e5868a
8dfc e588b7
8e40 e5af9f
8e41 e68bb6
8e42 e692ae
8e43 e693a6
8e44 e69cad
8e45 e6aeba
8e46 e896a9
8e47 e99b91
8e48 e79a90
8e49 e9af96
8e4a e68d8c
8e4b e98c86
8e4c e9aeab
8e4d e79abf
8e4e e69992
8e4f e4b889
8e50 e58298
8e51 e58f82
8e52 e5b1b1
8e53 e683a8
8e54 e69292
8e55 e695a3
8e56 e6a19f
8e57 e787a6
8e58 e78f8a
8e59 e794a3
8e5a e7ae97
8e5b e7ba82
8e5c e89a95
8e5d e8ae83
8e5e e8b39b
8e5f e985b8
8e60 e9a490
8e61 e696ac
8e62 e69aab
8e63 e6ae8b
8e64 e4bb95
8e65 e4bb94
8e66 e4bcba
8e67 e4bdbf
8e68 e588ba
8e69 e58fb8
8e6a e58fb2
8e6b e597a3
8e6c e59b9b
8e6d e5a3ab
8e6e e5a78b
8e6f e5a789
8e70 e5a7bf
8e71 e5ad90
8e72 e5b18d
8e73 e5b882
8e74 e5b8ab
8e75 e5bf97
8e76 e6809d
8e77 e68c87
8e78 e694af
8e79 e5ad9c
8e7a e696af
8e7b e696bd
8e7c e697a8
8e7d e69e9d
8e7e e6ada2
8e80 e6adbb
8e81 e6b08f
8e82 e78d85
8e83 e7a589
8e84 e7a781
8e85 e7b3b8
8e86 e7b499
8e87 e7b4ab
8e88 e882a2
8e89 e88482
8e8a e887b3
8e8b e8a696
8e8c e8a99e
8e8d e8a9a9
8e8e e8a9a6
8e8f e8aa8c
8e90 e8abae
8e91 e8b387
8e92 e8b39c
8e93 e99b8c
8e94 e9a3bc
8e95 e6adaf
8e96 e4ba8b
8e97 e4bcbc
8e98 e4be8d
8e99 e58590
8e9a e5ad97
8e9b e5afba
8e9c e68588
8e9d e68c81
8e9e e69982
8e9f e6aca1
8ea0 e6bb8b
8ea1 e6b2bb
8ea2 e788be
8ea3 e792bd
8ea4 e79794
8ea5 e7a381
8ea6 e7a4ba
8ea7 e8808c
8ea8 e880b3
8ea9 e887aa
8eaa e89294
8eab e8be9e
8eac e6b190
8ead e9b9bf
8eae e5bc8f
8eaf e8ad98
8eb0 e9b4ab
8eb1 e7abba
8eb2 e8bbb8
8eb3 e5ae8d
8eb4 e99bab
8eb5 e4b883
8eb6 e58fb1
8eb7 e59fb7
8eb8 e5a4b1
8eb9 e5ab89
8eba e5aea4
8ebb e68289
8ebc e6b9bf
8ebd e6bc86
8ebe e796be
8ebf e8b3aa
8ec0 e5ae9f
8ec1 e89480
8ec2 e7afa0
8ec3 e581b2
8ec4 e69fb4
8ec5 e88a9d
8ec6 e5b1a1
8ec7 e8958a
8ec8 e7b89e
8ec9 e8888e
8eca e58699
8ecb e5b084
8ecc e68da8
8ecd e8b5a6
8ece e6969c
8ecf e785ae
8ed0 e7a4be
8ed1 e7b497
8ed2 e88085
8ed3 e8ac9d
8ed4 e8bb8a
8ed5 e981ae
8ed6 e89b87
8ed7 e982aa
8ed8 e5809f
8ed9 e58bba
8eda e5b0ba
8edb e69d93
8edc e781bc
8edd e788b5
8ede e9858c
8edf e98788
8ee0 e98cab
8ee1 e88ba5
8ee2 e5af82
8ee3 e5bcb1
8ee4 e683b9
8ee5 e4b8bb
8ee6 e58f96
8ee7 e5ae88
8ee8 e6898b
8ee9 e69cb1
8eea e6ae8a
8eeb e78ba9
8eec e78fa0
8eed e7a8ae
8eee e885ab
8eef e8b6a3
8ef0 e98592
8ef1 e9a696
8ef2 e58492
8ef3 e58f97
8ef4 e591aa
8ef5 e5afbf
8ef6 e68e88
8ef7 e6a8b9
8ef8 e7b6ac
8ef9 e99c80
8efa e59b9a
8efb e58f8e
8efc e591a8
8f40 e5ae97
8f41 e5b0b1
8f42 e5b79e
8f43 e4bfae
8f44 e68481
8f45 e68bbe
8f46 e6b4b2
8f47 e7a780
8f48 e7a78b
8f49 e7b582
8f4a e7b98d
8f4b e7bf92
8f4c e887ad
8f4d e8889f
8f4e e89290
8f4f e8a186
8f50 e8a5b2
8f51 e8ae90
8f52 e8b9b4
8f53 e8bcaf
8f54 e980b1
8f55 e9858b
8f56 e985ac
8f57 e99b86
8f58 e9869c
8f59 e4bb80
8f5a e4bd8f
8f5b e58585
8f5c e58d81
8f5d e5be93
8f5e e6888e
8f5f e69f94
8f60 e6b181
8f61 e6b88b
8f62 e78da3
8f63 e7b8a6
8f64 e9878d
8f65 e98a83
8f66 e58f94
8f67 e5a499
8f68 e5aebf
8f69 e6b791
8f6a e7a59d
8f6b e7b8ae
8f6c e7b29b
8f6d e5a1be
8f6e e7869f
8f6f e587ba
8f70 e8a193
8f71 e8bfb0
8f72 e4bf8a
8f73 e5b3bb
8f74 e698a5
8f75 e79eac
8f76 e7aba3
8f77 e8889c
8f78 e9a7bf
8f79 e58786
8f7a e5beaa
8f7b e697ac
8f7c e6a5af
8f7d e6ae89
8f7e e6b7b3
8f80 e6ba96
8f81 e6bda4
8f82 e79bbe
8f83 e7b494
8f84 e5b7a1
8f85 e981b5
8f86 e98687
8f87 e9a086
8f88 e587a6
8f89 e5889d
8f8a e68980
8f8b e69a91
8f8c e69b99
8f8d e6b89a
8f8e e5bab6
8f8f e7b792
8f90 e7bdb2
8f91 e69bb8
8f92 e896af
8f93 e897b7
8f94 e8abb8
8f95 e58aa9
8f96 e58f99
8f97 e5a5b3
8f98 e5ba8f
8f99 e5be90
8f9a e68195
8f9b e98ba4
8f9c e999a4
8f9d e582b7
8f9e e5849f
8f9f e58b9d
8fa0 e58ca0
8fa1 e58d87
8fa2 e58fac
8fa3 e593a8
8fa4 e59586
8fa5 e594b1
8fa6 e59897
8fa7 e5a5a8
8fa8 e5a6be
8fa9 e5a8bc
8faa e5aeb5
8fab e5b086
8fac e5b08f
8fad e5b091
8fae e5b09a
8faf e5ba84
8fb0 e5ba8a
8fb1 e5bba0
8fb2 e5bdb0
8fb3 e689bf
8fb4 e68a84
8fb5 e68b9b
8fb6 e68e8c
8fb7 e68db7
8fb8 e69887
8fb9 e6988c
8fba e698ad
8fbb e699b6
8fbc e69dbe
8fbd e6a2a2
8fbe e6a89f
8fbf e6a8b5
8fc0 e6b2bc
8fc1 e6b688
8fc2 e6b889
8fc3 e6b998
8fc4 e784bc
8fc5 e784a6
8fc6 e785a7
8fc7 e79787
8fc8 e79c81
8fc9 e7a19d
8fca e7a481
8fcb e7a5a5
8fcc e7a7b0
8fcd e7aba0
8fce e7ac91
8fcf e7b2a7
8fd0 e7b4b9
8fd1 e88296
8fd2 e88f96
8fd3 e8928b
8fd4 e89589
8fd5 e8a19d
8fd6 e8a3b3
8fd7 e8a89f
8fd8 e8a8bc
8fd9 e8a994
8fda e8a9b3
8fdb e8b1a1
8fdc e8b39e
8fdd e986a4
8fde e989a6
8fdf e98dbe
8fe0 e99098
8fe1 e99a9c
8fe2 e99e98
8fe3 e4b88a
8fe4 e4b888
8fe5 e4b89e
8fe6 e4b997
8fe7 e58697
8fe8 e589b0
8fe9 e59f8e
8fea e5a0b4
8feb e5a38c
8fec e5aca2
8fed e5b8b8
8fee e68385
8fef e693be
8ff0 e69da1
8ff1 e69d96
8ff2 e6b584
8ff3 e78ab6
8ff4 e795b3
8ff5 e7a9a3
8ff6 e892b8
8ff7 e8adb2
8ff8 e986b8
8ff9 e98ca0
8ffa e598b1
8ffb e59fb4
8ffc e9a3be
9040 e68bad
9041 e6a48d
9042 e6ae96
9043 e787ad
9044 e7b994
9045 e881b7
9046 e889b2
9047 e8a7a6
9048 e9a39f
9049 e89d95
904a e8beb1
904b e5b0bb
904c e4bcb8
904d e4bfa1
904e e4beb5
904f e59487
9050 e5a8a0
9051 e5af9d
9052 e5afa9
9053 e5bf83
9054 e6858e
9055 e68caf
9056 e696b0
9057 e6998b
9058 e6a3ae
9059 e6a69b
905a e6b5b8
905b e6b7b1
905c e794b3
905d e796b9
905e e79c9f
905f e7a59e
9060 e7a7a6
9061 e7b4b3
9062 e887a3
9063 e88aaf
9064 e896aa
9065 e8a6aa
9066 e8a8ba
9067 e8baab
9068 e8be9b
9069 e980b2
906a e9879d
906b e99c87
906c e4baba
906d e4bb81
906e e58883
906f e5a1b5
9070 e5a3ac
9071 e5b08b
9072 e7949a
9073 e5b0bd
9074 e8858e
9075 e8a88a
9076 e8bf85
9077 e999a3
9078 e99dad
9079 e7aca5
907a e8ab8f
907b e9a088
907c e985a2
907d e59bb3
907e e58ea8
9080 e98097
9081 e590b9
9082 e59e82
9083 e5b8a5
9084 e68ea8
9085 e6b0b4
9086 e7828a
9087 e79da1
9088 e7b28b
9089 e7bfa0
908a e8a1b0
908b e98182
908c e98594
908d e98c90
908e e98c98
908f e99a8f
9090 e7919e
9091 e9ab84
9092 e5b487
9093 e5b5a9
9094 e695b0
9095 e69ea2
9096 e8b6a8
9097 e99b9b
9098 e68dae
9099 e69d89
909a e6a499
909b e88f85
909c e9a097
909d e99b80
909e e8a3be
909f e6be84
90a0 e691ba
90a1 e5afb8
90a2 e4b896
90a3 e780ac
90a4 e7959d
90a5 e698af
90a6 e58784
90a7 e588b6
90a8 e58ba2
90a9 e5a793
90aa e5be81
90ab e680a7
90ac e68890
90ad e694bf
90ae e695b4
90af e6989f
90b0 e699b4
90b1 e6a3b2
90b2 e6a096
90b3 e6ada3
90b4 e6b885
90b5 e789b2
90b6 e7949f
90b7 e79b9b
90b8 e7b2be
90b9 e88196
90ba e5a3b0
90bb e8a3bd
90bc e8a5bf
90bd e8aaa0
90be e8aa93
90bf e8ab8b
90c0 e9809d
90c1 e98692
90c2 e99d92
90c3 e99d99
90c4 e69689
90c5 e7a88e
90c6 e88486
90c7 e99abb
90c8 e5b8ad
90c9 e6839c
90ca e6889a
90cb e696a5
90cc e69894
90cd e69e90
90ce e79fb3
90cf e7a98d
90d0 e7b18d
90d1 e7b8be
90d2 e8848a
90d3 e8b2ac
90d4 e8b5a4
90d5 e8b7a1
90d6 e8b99f
90d7 e7a2a9
90d8 e58887
90d9 e68b99
90da e68ea5
90db e69182
90dc e68a98
90dd e8a8ad
90de e7aa83
90df e7af80
90e0 e8aaac
90e1 e99baa
90e2 e7b5b6
90e3 e8888c
90e4 e89d89
90e5 e4bb99
90e6 e58588
90e7 e58d83
90e8 e58da0
90e9 e5aea3
90ea e5b082
90eb e5b096
90ec e5b79d
90ed e688a6
90ee e68987
90ef e692b0
90f0 e6a093
90f1 e6a0b4
90f2 e6b389
90f3 e6b585
90f4 e6b497
90f5 e69f93
90f6 e6bd9c
90f7 e7858e
90f8 e785bd
90f9 e6978b
90fa e7a9bf
90fb e7aead
90fc e7b79a
9140 e7b98a
9141 e7bea8
9142 e885ba
9143 e8889b
9144 e888b9
9145 e896a6
9146 e8a9ae
9147 e8b38e
9148 e8b7b5
9149 e981b8
914a e981b7
914b e98aad
914c e98a91
914d e99683
914e e9aeae
914f e5898d
9150 e59684
9151 e6bcb8
9152 e784b6
9153 e585a8
9154 e7a685
9155 e7b995
9156 e886b3
9157 e7b38e
9158 e5998c
9159 e5a191
915a e5b2a8
915b e68eaa
915c e69bbe
915d e69bbd
915e e6a59a
915f e78b99
9160 e7968f
9161 e7968e
9162 e7a48e
9163 e7a596
9164 e7a79f
9165 e7b297
9166 e7b4a0
9167 e7b584
9168 e89887
9169 e8a8b4
916a e998bb
916b e981a1
916c e9bca0
916d e583a7
916e e589b5
916f e58f8c
9170 e58fa2
9171 e58089
9172 e596aa
9173 e5a3ae
9174 e5a58f
9175 e788bd
9176 e5ae8b
9177 e5b1a4
9178 e58c9d
9179 e683a3
917a e683b3
917b e68d9c
917c e68e83
917d e68cbf
917e e68ebb
9180 e6938d
9181 e697a9
9182 e69bb9
9183 e5b7a3
9184 e6a78d
9185 e6a7bd
9186 e6bc95
9187 e787a5
9188 e4ba89
9189 e797a9
918a e79bb8
918b e7aa93
918c e7b39f
918d e7b78f
918e e7b69c
918f e881a1
9190 e88d89
9191 e88d98
9192 e891ac
9193 e892bc
9194 e897bb
9195 e8a385
9196 e8b5b0
9197 e98081
9198 e981ad
9199 e98e97
919a e99c9c
919b e9a892
919c e5838f
919d e5a297
919e e6868e
919f e88793
91a0 e894b5
91a1 e8b488
91a2 e980a0
91a3 e4bf83
91a4 e581b4
91a5 e58987
91a6 e58db3
91a7 e681af
91a8 e68d89
91a9 e69d9f
91aa e6b8ac
91ab e8b6b3
91ac e9809f
91ad e4bf97
91ae e5b19e
91af e8b38a
91b0 e6978f
91b1 e7b69a
91b2 e58d92
91b3 e8a296
91b4 e585b6
91b5 e68f83
91b6 e5ad98
91b7 e5adab
91b8 e5b08a
91b9 e6908d
91ba e69d91
91bb e9819c
91bc e4bb96
91bd e5a49a
91be e5a4aa
91bf e6b1b0
91c0 e8a991
91c1 e594be
91c2 e5a095
91c3 e5a6a5
91c4 e683b0
91c5 e68993
91c6 e69f81
91c7 e888b5
91c8 e6a595
91c9 e99980
91ca e9a784
91cb e9a8a8
91cc e4bd93
91cd e5a086
91ce e5afbe
91cf e88090
91d0 e5b2b1
91d1 e5b8af
91d2 e5be85
91d3 e680a0
91d4 e6858b
91d5 e688b4
91d6 e69bbf
91d7 e6b3b0
91d8 e6bb9e
91d9 e8838e
91da e885bf
91db e88b94
91dc e8a28b
91dd e8b2b8
91de e98080
91df e980ae
91e0 e99a8a
91e1 e9bb9b
91e2 e9af9b
91e3 e4bba3
91e4 e58fb0
91e5 e5a4a7
91e6 e7acac
91e7 e9868d
91e8 e9a18c
91e9 e9b7b9
91ea e6bb9d
91eb e780a7
91ec e58d93
91ed e59584
91ee e5ae85
91ef e68998
91f0 e68a9e
91f1 e68b93
91f2 e6b2a2
91f3 e6bfaf
91f4 e790a2
91f5 e8a897
91f6 e990b8
91f7 e6bf81
91f8 e8abbe
91f9 e88cb8
91fa e587a7
91fb e89bb8
91fc e58faa
9240 e58fa9
9241 e4bd86
9242 e98194
9243 e8beb0
9244 e5a5aa
9245 e884b1
9246 e5b7bd
9247 e7abaa
9248 e8bebf
9249 e6a39a
924a e8b0b7
924b e78bb8
924c e9b188
924d e6a8bd
924e e8aab0
924f e4b8b9
9250 e58d98
9251 e59886
9252 e59da6
9253 e68b85
9254 e68ea2
9255 e697a6
9256 e6ad8e
9257 e6b7a1
9258 e6b99b
9259 e782ad
925a e79fad
925b e7abaf
925c e7aeaa
925d e7b6bb
925e e880bd
925f e88386
9260 e89b8b
9261 e8aa95
9262 e98d9b
9263 e59ba3
9264 e5a387
9265 e5bcbe
9266 e696ad
9267 e69a96
9268 e6aa80
9269 e6aeb5
926a e794b7
926b e8ab87
926c e580a4
926d e79fa5
926e e59cb0
926f e5bc9b
9270 e681a5
9271 e699ba
9272 e6b1a0
9273 e797b4
9274 e7a89a
9275 e7bdae
9276 e887b4
9277 e89c98
9278 e98185
9279 e9a6b3
927a e7af89
927b e7959c
927c e7abb9
927d e7ad91
927e e89384
9280 e98090
9281 e7a7a9
9282 e7aa92
9283 e88cb6
9284 e5aba1
9285 e79d80
9286 e4b8ad
9287 e4bbb2
9288 e5ae99
9289 e5bfa0
928a e68abd
928b e698bc
928c e69fb1
928d e6b3a8
928e e899ab
928f e8a1b7
9290 e8a8bb
9291 e9858e
9292 e98bb3
9293 e9a790
9294 e6a897
9295 e780a6
9296 e78caa
9297 e88ba7
9298 e89197
9299 e8b2af
929a e4b881
929b e58586
929c e5878b
929d e5968b
929e e5afb5
929f e5b896
92a0 e5b8b3
92a1 e5ba81
92a2 e5bc94
92a3 e5bcb5
92a4 e5bdab
92a5 e5beb4
92a6 e687b2
92a7 e68c91
92a8 e69aa2
92a9 e69c9d
92aa e6bdae
92ab e78992
92ac e794ba
92ad e79cba
92ae e881b4
92af e884b9
92b0 e885b8
92b1 e89db6
92b2 e8aabf
92b3 e8ab9c
92b4 e8b685
92b5 e8b7b3
92b6 e98a9a
92b7 e995b7
92b8 e9a082
92b9 e9b3a5
92ba e58b85
92bb e68d97
92bc e79bb4
92bd e69c95
92be e6b288
92bf e78f8d
92c0 e8b383
92c1 e98eae
92c2 e999b3
92c3 e6b4a5
92c4 e5a29c
92c5 e6a48e
92c6 e6a78c
92c7 e8bfbd
92c8 e98e9a
92c9 e7979b
92ca e9809a
92cb e5a19a
92cc e6a082
92cd e68eb4
92ce e6a7bb
92cf e4bd83
92d0 e6bcac
92d1 e69f98
92d2 e8bebb
92d3 e894a6
92d4 e7b6b4
92d5 e98d94
92d6 e6a4bf
92d7 e6bdb0
92d8 e59daa
92d9 e5a3b7
92da e5acac
92db e7b4ac
92dc e788aa
92dd e5908a
92de e987a3
92df e9b6b4
92e0 e4baad
92e1 e4bd8e
92e2 e5819c
92e3 e581b5
92e4 e58983
92e5 e8b29e
92e6 e59188
92e7 e5a0a4
92e8 e5ae9a
92e9 e5b89d
92ea e5ba95
92eb e5baad
92ec e5bbb7
92ed e5bc9f
92ee e6828c
92ef e68ab5
92f0 e68cba
92f1 e68f90
92f2 e6a2af
92f3 e6b180
92f4 e7a287
92f5 e7a68e
92f6 e7a88b
92f7 e7b7a0
92f8 e88987
92f9 e8a882
92fa e8aba6
92fb e8b984
92fc e98093
9340 e982b8
9341 e984ad
9342 e98798
9343 e9bc8e
9344 e6b3a5
9345 e69198
9346 e693a2
9347 e695b5
9348 e6bbb4
9349 e79a84
934a e7ac9b
934b e981a9
934c e98f91
934d e6baba
934e e593b2
934f e5beb9
9350 e692a4
9351 e8bd8d
9352 e8bfad
9353 e98984
9354 e585b8
9355 e5a1ab
9356 e5a4a9
9357 e5b195
9358 e5ba97
9359 e6b7bb
935a e7ba8f
935b e7949c
935c e8b2bc
935d e8bba2
935e e9a19b
935f e782b9
9360 e4bc9d
9361 e6aebf
9362 e6beb1
9363 e794b0
9364 e99bbb
9365 e5858e
9366 e59090
9367 e5a0b5
9368 e5a197
9369 e5a6ac
936a e5b1a0
936b e5be92
936c e69697
936d e69d9c
936e e6b8a1
936f e799bb
9370 e88f9f
9371 e8b3ad
9372 e98094
9373 e983bd
9374 e98d8d
9375 e7a0a5
9376 e7a0ba
9377 e58aaa
9378 e5baa6
9379 e59c9f
937a e5a5b4
937b e68092
937c e58092
937d e5859a
937e e586ac
9380 e5878d
9381 e58880
9382 e59490
9383 e5a194
9384 e5a198
9385 e5a597
9386 e5ae95
9387 e5b3b6
9388 e5b68b
9389 e682bc
938a e68a95
938b e690ad
938c e69db1
938d e6a183
938e e6a2bc
938f e6a39f
9390 e79b97
9391 e6b798
9392 e6b9af
9393 e6b69b
9394 e781af
9395 e78788
9396 e5bd93
9397 e79798
9398 e7a5b7
9399 e7ad89
939a e7ad94
939b e7ad92
939c e7b396
939d e7b5b1
939e e588b0
939f e891a3
93a0 e895a9
93a1 e897a4
93a2 e8a88e
93a3 e8ac84
93a4 e8b186
93a5 e8b88f
93a6 e98083
93a7 e9808f
93a8 e99099
93a9 e999b6
93aa e9a0ad
93ab e9a8b0
93ac e99798
93ad e5838d
93ae e58b95
93af e5908c
93b0 e5a082
93b1 e5b08e
93b2 e686a7
93b3 e6929e
93b4 e6b49e
93b5 e79eb3
93b6 e7aba5
93b7 e883b4
93b8 e89084
93b9 e98193
93ba e98a85
93bb e5b3a0
93bc e9b487
93bd e58cbf
93be e5be97
93bf e5beb3
93c0 e6b69c
93c1 e789b9
93c2 e79da3
93c3 e7a6bf
93c4 e7afa4
93c5 e6af92
93c6 e78bac
93c7 e8aaad
93c8 e6a083
93c9 e6a9a1
93ca e587b8
93cb e7aa81
93cc e6a4b4
93cd e5b18a
93ce e9b3b6
93cf e88bab
93d0 e5af85
93d1 e98589
93d2 e7809e
93d3 e599b8
93d4 e5b1af
93d5 e68387
93d6 e695a6
93d7 e6b28c
93d8 e8b19a
93d9 e98181
93da e9a093
93db e59191
93dc e69b87
93dd e9888d
93de e5a588
93df e982a3
93e0 e58685
93e1 e4b98d
93e2 e587aa
93e3 e89699
93e4 e8ac8e
93e5 e78198
93e6 e68dba
93e7 e98d8b
93e8 e6a5a2
93e9 e9a6b4
93ea e7b884
93eb e795b7
93ec e58d97
93ed e6a5a0
93ee e8bb9f
93ef e99ba3
93f0 e6b19d
93f1 e4ba8c
93f2 e5b0bc
93f3 e5bc90
93f4 e8bfa9
93f5 e58c82
93f6 e8b391
93f7 e88289
93f8 e899b9
93f9 e5bbbf
93fa e697a5
93fb e4b9b3
93fc e585a5
9440 e5a682
9441 e5b0bf
9442 e99fae
9443 e4bbbb
9444 e5a68a
9445 e5bf8d
9446 e8aa8d
9447 e6bfa1
9448 e7a6b0
9449 e7a5a2
944a e5afa7
944b e891b1
944c e78cab
944d e786b1
944e e5b9b4
944f e5bfb5
9450 e68dbb
9451 e6929a
9452 e78783
9453 e7b298
9454 e4b983
9455 e5bbbc
9456 e4b98b
9457 e59f9c
9458 e59aa2
9459 e682a9
945a e6bf83
945b e7b48d
945c e883bd
945d e884b3
945e e886bf
945f e8beb2
9460 e8a697
9461 e89aa4
9462 e5b7b4
9463 e68a8a
9464 e692ad
9465 e8a687
9466 e69db7
9467 e6b3a2
9468 e6b4be
9469 e790b6
946a e7a0b4
946b e5a986
946c e7bdb5
946d e88aad
946e e9a6ac
946f e4bfb3
9470 e5bb83
9471 e68b9d
9472 e68e92
9473 e69597
9474 e69daf
9475 e79b83
9476 e7898c
9477 e8838c
9478 e882ba
9479 e8bca9
947a e9858d
947b e5808d
947c e59fb9
947d e5aa92
947e e6a285
9480 e6a5b3
9481 e785a4
9482 e78bbd
9483 e8b2b7
9484 e5a3b2
9485 e8b3a0
9486 e999aa
9487 e98099
9488 e89dbf
9489 e7a7a4
948a e79fa7
948b e890a9
948c e4bcaf
948d e589a5
948e e58d9a
948f e68b8d
9490 e69f8f
9491 e6b38a
9492 e799bd
9493 e7ae94
9494 e7b295
9495 e888b6
9496 e89684
9497 e8bfab
9498 e69b9d
9499 e6bca0
949a e78886
949b e7b89b
949c e88eab
949d e9a781
949e e9baa6
949f e587bd
94a0 e7aeb1
94a1 e7a1b2
94a2 e7aeb8
94a3 e88287
94a4 e7ad88
94a5 e6aba8
94a6 e5b9a1
94a7 e8828c
94a8 e79591
94a9 e795a0
94aa e585ab
94ab e989a2
94ac e6ba8c
94ad e799ba
94ae e98697
94af e9abaa
94b0 e4bc90
94b1 e7bdb0
94b2 e68a9c
94b3 e7ad8f
94b4 e996a5
94b5 e9b3a9
94b6 e599ba
94b7 e5a199
94b8 e89ba4
94b9 e99abc
94ba e4bcb4
94bb e588a4
94bc e58d8a
94bd e58f8d
94be e58f9b
94bf e5b886
94c0 e690ac
94c1 e69691
94c2 e69dbf
94c3 e6b0be
94c4 e6b18e
94c5 e78988
94c6 e78aaf
94c7 e78fad
94c8 e79594
94c9 e7b981
94ca e888ac
94cb e897a9
94cc e8b2a9
94cd e7af84
94ce e98786
94cf e785a9
94d0 e9a092
94d1 e9a3af
94d2 e68cbd
94d3 e699a9
94d4 e795aa
94d5 e79ba4
94d6 e7a390
94d7 e89583
94d8 e89bae
94d9 e58caa
94da e58d91
94db e590a6
94dc e5a683
94dd e5ba87
94de e5bdbc
94df e682b2
94e0 e68989
94e1 e689b9
94e2 e68aab
94e3 e69690
94e4 e6af94
94e5 e6b38c
94e6 e796b2
94e7 e79aae
94e8 e7a291
94e9 e7a798
94ea e7b78b
94eb e7bdb7
94ec e882a5
94ed e8a2ab
94ee e8aab9
94ef e8b2bb
94f0 e981bf
94f1 e99d9e
94f2 e9a39b
94f3 e6a88b
94f4 e7b0b8
94f5 e58299
94f6 e5b0be
94f7 e5beae
94f8 e69e87
94f9 e6af98
94fa e790b5
94fb e79c89
94fc e7be8e
9540 e9bcbb
9541 e69f8a
9542 e7a897
9543 e58cb9
9544 e7968b
9545 e9abad
9546 e5bda6
9547 e8869d
9548 e88fb1
9549 e88298
954a e5bcbc
954b e5bf85
954c e795a2
954d e7ad86
954e e980bc
954f e6a1a7
9550 e5a7ab
9551 e5aa9b
9552 e7b490
9553 e799be
9554 e8acac
9555 e4bfb5
9556 e5bdaa
9557 e6a899
9558 e6b0b7
9559 e6bc82
955a e793a2
955b e7a5a8
955c e8a1a8
955d e8a995
955e e8b1b9
955f e5bb9f
9560 e68f8f
9561 e79785
9562 e7a792
9563 e88b97
9564 e98ca8
9565 e98bb2
9566 e8929c
9567 e89bad
9568 e9b0ad
9569 e59381
956a e5bdac
956b e6968c
956c e6b59c
956d e78095
956e e8b2a7
956f e8b393
9570 e9a0bb
9571 e6958f
9572 e793b6
9573 e4b88d
9574 e4bb98
9575 e59fa0
9576 e5a4ab
9577 e5a9a6
9578 e5af8c
9579 e586a8
957a e5b883
957b e5ba9c
957c e68096
957d e689b6
957e e695b7
9580 e696a7
9581 e699ae
9582 e6b5ae
9583 e788b6
9584 e7aca6
9585 e88590
9586 e8869a
9587 e88a99
9588 e8ad9c
9589 e8b2a0
958a e8b3a6
958b e8b5b4
958c e9989c
958d e99984
958e e4beae
958f e692ab
9590 e6ada6
9591 e8889e
9592 e891a1
9593 e895aa
9594 e983a8
9595 e5b081
9596 e6a593
9597 e9a2a8
9598 e891ba
9599 e89597
959a e4bc8f
959b e589af
959c e5bea9
959d e5b985
959e e69c8d
959f e7a68f
95a0 e885b9
95a1 e8a487
95a2 e8a686
95a3 e6b7b5
95a4 e5bc97
95a5 e68995
95a6 e6b2b8
95a7 e4bb8f
95a8 e789a9
95a9 e9ae92
95aa e58886
95ab e590bb
95ac e599b4
95ad e5a2b3
95ae e686a4
95af e689ae
95b0 e7849a
95b1 e5a5ae
95b2 e7b289
95b3 e7b39e
95b4 e7b49b
95b5 e99bb0
95b6 e69687
95b7 e8819e
95b8 e4b899
95b9 e4bdb5
95ba e585b5
95bb e5a180
95bc e5b9a3
95bd e5b9b3
95be e5bc8a
95bf e69f84
95c0 e4b8a6
95c1 e894bd
95c2 e99689
95c3 e9999b
95c4 e7b1b3
95c5 e9a081
95c6 e583bb
95c7 e5a381
95c8 e79996
95c9 e7a2a7
95ca e588a5
95cb e79ea5
95cc e89491
95cd e7ae86
95ce e5818f
95cf e5a489
95d0 e78987
95d1 e7af87
95d2 e7b7a8
95d3 e8beba
95d4 e8bf94
95d5 e9818d
95d6 e4bebf
95d7 e58b89
95d8 e5a8a9
95d9 e5bc81
95da e99ead
95db e4bf9d
95dc e88897
95dd e98baa
95de e59c83
95df e68d95
95e0 e6ada9
95e1 e794ab
95e2 e8a39c
95e3 e8bc94
95e4 e7a982
95e5 e58b9f
95e6 e5a293
95e7 e68595
95e8 e6888a
95e9 e69aae
95ea e6af8d
95eb e7b0bf
95ec e88fa9
95ed e580a3
95ee e4bfb8
95ef e58c85
95f0 e59186
95f1 e5a0b1
95f2 e5a589
95f3 e5ae9d
95f4 e5b3b0
95f5 e5b3af
95f6 e5b4a9
95f7 e5ba96
95f8 e68ab1
95f9 e68da7
95fa e694be
95fb e696b9
95fc e69c8b
9640 e6b395
9641 e6b3a1
9642 e783b9
9643 e7a0b2
9644 e7b8ab
9645 e8839e
9646 e88ab3
9647 e8908c
9648 e893ac
9649 e89c82
964a e8a492
964b e8a8aa
964c e8b18a
964d e982a6
964e e98b92
964f e9a3bd
9650 e9b3b3
9651 e9b5ac
9652 e4b98f
9653 e4baa1
9654 e5828d
9655 e58996
9656 e59d8a
9657 e5a6a8
9658 e5b8bd
9659 e5bf98
965a e5bf99
965b e688bf
965c e69ab4
965d e69c9b
965e e69f90
965f e6a392
9660 e58692
9661 e7b4a1
9662 e882aa
9663 e886a8
9664 e8ac80
9665 e8b28c
9666 e8b2bf
9667 e989be
9668 e998b2
9669 e590a0
966a e9a0ac
966b e58c97
966c e58395
966d e58d9c
966e e5a2a8
966f e692b2
9670 e69cb4
9671 e789a7
9672 e79da6
9673 e7a986
9674 e987a6
9675 e58b83
9676 e6b2a1
9677 e6ae86
9678 e5a080
9679 e5b98c
967a e5a594
967b e69cac
967c e7bfbb
967d e587a1
967e e79b86
9680 e691a9
9681 e7a3a8
9682 e9ad94
9683 e9babb
9684 e59f8b
9685 e5a6b9
9686 e698a7
9687 e69e9a
9688 e6af8e
9689 e593a9
968a e6a799
968b e5b995
968c e8869c
968d e69e95
968e e9aeaa
968f e69fbe
9690 e9b192
9691 e6a19d
9692 e4baa6
9693 e4bfa3
9694 e58f88
9695 e68ab9
9696 e69cab
9697 e6b2ab
9698 e8bf84
9699 e4bead
969a e7b9ad
969b e9babf
969c e4b887
969d e685a2
969e e6ba80
969f e6bcab
96a0 e89493
96a1 e591b3
96a2 e69caa
96a3 e9ad85
96a4 e5b7b3
96a5 e7ae95
96a6 e5b2ac
96a7 e5af86
96a8 e89c9c
96a9 e6b98a
96aa e89391
96ab e7a894
96ac e88488
96ad e5a699
96ae e7b28d
96af e6b091
96b0 e79ca0
96b1 e58b99
96b2 e5a4a2
96b3 e784a1
96b4 e7899f
96b5 e79f9b
96b6 e99ca7
96b7 e9b5a1
96b8 e6a48b
96b9 e5a9bf
96ba e5a898
96bb e586a5
96bc e5908d
96bd e591bd
96be e6988e
96bf e79b9f
96c0 e8bfb7
96c1 e98a98
96c2 e9b3b4
96c3 e5a7aa
96c4 e7899d
96c5 e6bb85
96c6 e5858d
96c7 e6a389
96c8 e7b6bf
96c9 e7b7ac
96ca e99da2
96cb e9baba
96cc e691b8
96cd e6a8a1
96ce e88c82
96cf e5a684
96d0 e5ad9f
96d1 e6af9b
96d2 e78c9b
96d3 e79bb2
96d4 e7b6b2
96d5 e88097
96d6 e89299
96d7 e584b2
96d8 e69ca8
96d9 e9bb99
96da e79bae
96db e69da2
96dc e58bbf
96dd e9a485
96de e5b0a4
96df e688bb
96e0 e7b1be
96e1 e8b2b0
96e2 e5958f
96e3 e682b6
96e4 e7b48b
96e5 e99680
96e6 e58c81
96e7 e4b99f
96e8 e586b6
96e9 e5a49c
96ea e788ba
96eb e880b6
96ec e9878e
96ed e5bca5
96ee e79fa2
96ef e58e84
96f0 e5bdb9
96f1 e7b484
96f2 e896ac
96f3 e8a8b3
96f4 e8ba8d
96f5 e99d96
96f6 e69fb3
96f7 e896ae
96f8 e99193
96f9 e68489
96fa e68488
96fb e6b2b9
96fc e79992
9740 e8abad
9741 e8bcb8
9742 e594af
9743 e4bd91
9744 e584aa
9745 e58b87
9746 e58f8b
9747 e5aea5
9748 e5b9bd
9749 e682a0
974a e68682
974b e68f96
974c e69c89
974d e69f9a
974e e6b9a7
974f e6b68c
9750 e78cb6
9751 e78cb7
9752 e794b1
9753 e7a590
9754 e8a395
9755 e8aa98
9756 e9818a
9757 e98291
9758 e983b5
9759 e99b84
975a e89e8d
975b e5a495
975c e4ba88
975d e4bd99
975e e4b88e
975f e8aa89
9760 e8bcbf
9761 e9a090
9762 e582ad
9763 e5b9bc
9764 e5a696
9765 e5aeb9
9766 e5bab8
9767 e68f9a
9768 e68fba
9769 e69381
976a e69b9c
976b e6a58a
976c e6a798
976d e6b48b
976e e6bab6
976f e78694
9770 e794a8
9771 e7aaaf
9772 e7be8a
9773 e88080
9774 e89189
9775 e89389
9776 e8a681
9777 e8aca1
9778 e8b88a
9779 e981a5
977a e999bd
977b e9a48a
977c e685be
977d e68a91
977e e6acb2
9780 e6b283
9781 e6b5b4
9782 e7bf8c
9783 e7bfbc
9784 e6b780
9785 e7be85
9786 e89eba
9787 e8a3b8
9788 e69da5
9789 e88eb1
978a e9a0bc
978b e99bb7
978c e6b49b
978d e7b5a1
978e e890bd
978f e985aa
9790 e4b9b1
9791 e58db5
9792 e5b590
9793 e6ac84
9794 e6bfab
9795 e8978d
9796 e898ad
9797 e8a6a7
9798 e588a9
9799 e5908f
979a e5b1a5
979b e69d8e
979c e6a2a8
979d e79086
979e e79283
979f e797a2
97a0 e8a38f
97a1 e8a3a1
97a2 e9878c
97a3 e99ba2
97a4 e999b8
97a5 e5be8b
97a6 e78e87
97a7 e7ab8b
97a8 e8918e
97a9 e68ea0
97aa e795a5
97ab e58a89
97ac e6b581
97ad e6ba9c
97ae e79089
97af e79599
97b0 e7a1ab
97b1 e7b292
97b2 e99a86
97b3 e7ab9c
97b4 e9be8d
97b5 e4beb6
97b6 e685ae
97b7 e69785
97b8 e8999c
97b9 e4ba86
97ba e4baae
97bb e5839a
97bc e4b8a1
97bd e5878c
97be e5afae
97bf e69699
97c0 e6a281
97c1 e6b6bc
97c2 e78c9f
97c3 e79982
97c4 e79ead
97c5 e7a89c
97c6 e7b3a7
97c7 e889af
97c8 e8ab92
97c9 e981bc
97ca e9878f
97cb e999b5
97cc e9a098
97cd e58a9b
97ce e7b791
97cf e580ab
97d0 e58e98
97d1 e69e97
97d2 e6b78b
97d3 e78790
97d4 e790b3
97d5 e887a8
97d6 e8bcaa
97d7 e99aa3
97d8 e9b197
97d9 e9ba9f
97da e791a0
97db e5a181
97dc e6b699
97dd e7b4af
97de e9a19e
97df e4bba4
97e0 e4bcb6
97e1 e4be8b
97e2 e586b7
97e3 e58ab1
97e4 e5b6ba
97e5 e6809c
97e6 e78eb2
97e7 e7a4bc
97e8 e88b93
97e9 e988b4
97ea e99ab7
97eb e99bb6
97ec e99c8a
97ed e9ba97
97ee e9bda2
97ef e69aa6
97f0 e6adb4
97f1 e58897
97f2 e58aa3
97f3 e78388
97f4 e8a382
97f5 e5bb89
97f6 e6818b
97f7 e68690
97f8 e6bca3
97f9 e78589
97fa e7b0be
97fb e7b7b4
97fc e881af
9840 e893ae
9841 e980a3
9842 e98cac
9843 e59182
9844 e9adaf
9845 e6ab93
9846 e78289
9847 e8b382
9848 e8b7af
9849 e99cb2
984a e58ab4
984b e5a981
984c e5bb8a
984d e5bc84
984e e69c97
984f e6a5bc
9850 e6a694
9851 e6b5aa
9852 e6bc8f
9853 e789a2
9854 e78bbc
9855 e7afad
9856 e88081
9857 e881be
9858 e89d8b
9859 e9838e
985a e585ad
985b e9ba93
985c e7a684
985d e8828b
985e e98cb2
985f e8ab96
9860 e580ad
9861 e5928c
9862 e8a9b1
9863 e6adaa
9864 e8b384
9865 e88487
9866 e68391
9867 e69ea0
9868 e9b7b2
9869 e4ba99
986a e4ba98
986b e9b090
986c e8a9ab
986d e89781
986e e895a8
986f e6a480
9870 e6b9be
9871 e7a297
9872 e88595
END

    if ( scalar(keys %sjis2utf8_1) != 3635 ) {
        die "scalar(keys %sjis2utf8_1) is ", scalar(keys %sjis2utf8_1), ".";
    }

    # (2 of 2) avoid "Allocation too large" of perl 4.036

    %sjis2utf8_2 = split( /\s+/, <<'END' );
989f e5bc8c
98a0 e4b890
98a1 e4b895
98a2 e4b8aa
98a3 e4b8b1
98a4 e4b8b6
98a5 e4b8bc
98a6 e4b8bf
98a7 e4b982
98a8 e4b996
98a9 e4b998
98aa e4ba82
98ab e4ba85
98ac e8b1ab
98ad e4ba8a
98ae e88892
98af e5bc8d
98b0 e4ba8e
98b1 e4ba9e
98b2 e4ba9f
98b3 e4baa0
98b4 e4baa2
98b5 e4bab0
98b6 e4bab3
98b7 e4bab6
98b8 e4bb8e
98b9 e4bb8d
98ba e4bb84
98bb e4bb86
98bc e4bb82
98bd e4bb97
98be e4bb9e
98bf e4bbad
98c0 e4bb9f
98c1 e4bbb7
98c2 e4bc89
98c3 e4bd9a
98c4 e4bcb0
98c5 e4bd9b
98c6 e4bd9d
98c7 e4bd97
98c8 e4bd87
98c9 e4bdb6
98ca e4be88
98cb e4be8f
98cc e4be98
98cd e4bdbb
98ce e4bda9
98cf e4bdb0
98d0 e4be91
98d1 e4bdaf
98d2 e4be86
98d3 e4be96
98d4 e58498
98d5 e4bf94
98d6 e4bf9f
98d7 e4bf8e
98d8 e4bf98
98d9 e4bf9b
98da e4bf91
98db e4bf9a
98dc e4bf90
98dd e4bfa4
98de e4bfa5
98df e5809a
98e0 e580a8
98e1 e58094
98e2 e580aa
98e3 e580a5
98e4 e58085
98e5 e4bc9c
98e6 e4bfb6
98e7 e580a1
98e8 e580a9
98e9 e580ac
98ea e4bfbe
98eb e4bfaf
98ec e58091
98ed e58086
98ee e58183
98ef e58187
98f0 e69c83
98f1 e58195
98f2 e58190
98f3 e58188
98f4 e5819a
98f5 e58196
98f6 e581ac
98f7 e581b8
98f8 e58280
98f9 e5829a
98fa e58285
98fb e582b4
98fc e582b2
9940 e58389
9941 e5838a
9942 e582b3
9943 e58382
9944 e58396
9945 e5839e
9946 e583a5
9947 e583ad
9948 e583a3
9949 e583ae
994a e583b9
994b e583b5
994c e58489
994d e58481
994e e58482
994f e58496
9950 e58495
9951 e58494
9952 e5849a
9953 e584a1
9954 e584ba
9955 e584b7
9956 e584bc
9957 e584bb
9958 e584bf
9959 e58580
995a e58592
995b e5858c
995c e58594
995d e585a2
995e e7abb8
995f e585a9
9960 e585aa
9961 e585ae
9962 e58680
9963 e58682
9964 e59b98
9965 e5868c
9966 e58689
9967 e5868f
9968 e58691
9969 e58693
996a e58695
996b e58696
996c e586a4
996d e586a6
996e e586a2
996f e586a9
9970 e586aa
9971 e586ab
9972 e586b3
9973 e586b1
9974 e586b2
9975 e586b0
9976 e586b5
9977 e586bd
9978 e58785
9979 e58789
997a e5879b
997b e587a0
997c e89995
997d e587a9
997e e587ad
9980 e587b0
9981 e587b5
9982 e587be
9983 e58884
9984 e5888b
9985 e58894
9986 e5888e
9987 e588a7
9988 e588aa
9989 e588ae
998a e588b3
998b e588b9
998c e5898f
998d e58984
998e e5898b
998f e5898c
9990 e5899e
9991 e58994
9992 e589aa
9993 e589b4
9994 e589a9
9995 e589b3
9996 e589bf
9997 e589bd
9998 e58a8d
9999 e58a94
999a e58a92
999b e589b1
999c e58a88
999d e58a91
999e e8bea8
999f e8bea7
99a0 e58aac
99a1 e58aad
99a2 e58abc
99a3 e58ab5
99a4 e58b81
99a5 e58b8d
99a6 e58b97
99a7 e58b9e
99a8 e58ba3
99a9 e58ba6
99aa e9a3ad
99ab e58ba0
99ac e58bb3
99ad e58bb5
99ae e58bb8
99af e58bb9
99b0 e58c86
99b1 e58c88
99b2 e794b8
99b3 e58c8d
99b4 e58c90
99b5 e58c8f
99b6 e58c95
99b7 e58c9a
99b8 e58ca3
99b9 e58caf
99ba e58cb1
99bb e58cb3
99bc e58cb8
99bd e58d80
99be e58d86
99bf e58d85
99c0 e4b897
99c1 e58d89
99c2 e58d8d
99c3 e58796
99c4 e58d9e
99c5 e58da9
99c6 e58dae
99c7 e5a498
99c8 e58dbb
99c9 e58db7
99ca e58e82
99cb e58e96
99cc e58ea0
99cd e58ea6
99ce e58ea5
99cf e58eae
99d0 e58eb0
99d1 e58eb6
99d2 e58f83
99d3 e7b092
99d4 e99b99
99d5 e58f9f
99d6 e69bbc
99d7 e787ae
99d8 e58fae
99d9 e58fa8
99da e58fad
99db e58fba
99dc e59081
99dd e590bd
99de e59180
99df e590ac
99e0 e590ad
99e1 e590bc
99e2 e590ae
99e3 e590b6
99e4 e590a9
99e5 e5909d
99e6 e5918e
99e7 e5928f
99e8 e591b5
99e9 e5928e
99ea e5919f
99eb e591b1
99ec e591b7
99ed e591b0
99ee e59292
99ef e591bb
99f0 e59280
99f1 e591b6
99f2 e59284
99f3 e59290
99f4 e59286
99f5 e59387
99f6 e592a2
99f7 e592b8
99f8 e592a5
99f9 e592ac
99fa e59384
99fb e59388
99fc e592a8
9a40 e592ab
9a41 e59382
9a42 e592a4
9a43 e592be
9a44 e592bc
9a45 e59398
9a46 e593a5
9a47 e593a6
9a48 e5948f
9a49 e59494
9a4a e593bd
9a4b e593ae
9a4c e593ad
9a4d e593ba
9a4e e593a2
9a4f e594b9
9a50 e59580
9a51 e595a3
9a52 e5958c
9a53 e594ae
9a54 e5959c
9a55 e59585
9a56 e59596
9a57 e59597
9a58 e594b8
9a59 e594b3
9a5a e5959d
9a5b e59699
9a5c e59680
9a5d e592af
9a5e e5968a
9a5f e5969f
9a60 e595bb
9a61 e595be
9a62 e59698
9a63 e5969e
9a64 e596ae
9a65 e595bc
9a66 e59683
9a67 e596a9
9a68 e59687
9a69 e596a8
9a6a e5979a
9a6b e59785
9a6c e5979f
9a6d e59784
9a6e e5979c
9a6f e597a4
9a70 e59794
9a71 e59894
9a72 e597b7
9a73 e59896
9a74 e597be
9a75 e597bd
9a76 e5989b
9a77 e597b9
9a78 e5998e
9a79 e59990
9a7a e7879f
9a7b e598b4
9a7c e598b6
9a7d e598b2
9a7e e598b8
9a80 e599ab
9a81 e599a4
9a82 e598af
9a83 e599ac
9a84 e599aa
9a85 e59a86
9a86 e59a80
9a87 e59a8a
9a88 e59aa0
9a89 e59a94
9a8a e59a8f
9a8b e59aa5
9a8c e59aae
9a8d e59ab6
9a8e e59ab4
9a8f e59b82
9a90 e59abc
9a91 e59b81
9a92 e59b83
9a93 e59b80
9a94 e59b88
9a95 e59b8e
9a96 e59b91
9a97 e59b93
9a98 e59b97
9a99 e59bae
9a9a e59bb9
9a9b e59c80
9a9c e59bbf
9a9d e59c84
9a9e e59c89
9a9f e59c88
9aa0 e59c8b
9aa1 e59c8d
9aa2 e59c93
9aa3 e59c98
9aa4 e59c96
9aa5 e59787
9aa6 e59c9c
9aa7 e59ca6
9aa8 e59cb7
9aa9 e59cb8
9aaa e59d8e
9aab e59cbb
9aac e59d80
9aad e59d8f
9aae e59da9
9aaf e59f80
9ab0 e59e88
9ab1 e59da1
9ab2 e59dbf
9ab3 e59e89
9ab4 e59e93
9ab5 e59ea0
9ab6 e59eb3
9ab7 e59ea4
9ab8 e59eaa
9ab9 e59eb0
9aba e59f83
9abb e59f86
9abc e59f94
9abd e59f92
9abe e59f93
9abf e5a08a
9ac0 e59f96
9ac1 e59fa3
9ac2 e5a08b
9ac3 e5a099
9ac4 e5a09d
9ac5 e5a1b2
9ac6 e5a0a1
9ac7 e5a1a2
9ac8 e5a18b
9ac9 e5a1b0
9aca e6af80
9acb e5a192
9acc e5a0bd
9acd e5a1b9
9ace e5a285
9acf e5a2b9
9ad0 e5a29f
9ad1 e5a2ab
9ad2 e5a2ba
9ad3 e5a39e
9ad4 e5a2bb
9ad5 e5a2b8
9ad6 e5a2ae
9ad7 e5a385
9ad8 e5a393
9ad9 e5a391
9ada e5a397
9adb e5a399
9adc e5a398
9add e5a3a5
9ade e5a39c
9adf e5a3a4
9ae0 e5a39f
9ae1 e5a3af
9ae2 e5a3ba
9ae3 e5a3b9
9ae4 e5a3bb
9ae5 e5a3bc
9ae6 e5a3bd
9ae7 e5a482
9ae8 e5a48a
9ae9 e5a490
9aea e5a49b
9aeb e6a2a6
9aec e5a4a5
9aed e5a4ac
9aee e5a4ad
9aef e5a4b2
9af0 e5a4b8
9af1 e5a4be
9af2 e7ab92
9af3 e5a595
9af4 e5a590
9af5 e5a58e
9af6 e5a59a
9af7 e5a598
9af8 e5a5a2
9af9 e5a5a0
9afa e5a5a7
9afb e5a5ac
9afc e5a5a9
9b40 e5a5b8
9b41 e5a681
9b42 e5a69d
9b43 e4bd9e
9b44 e4beab
9b45 e5a6a3
9b46 e5a6b2
9b47 e5a786
9b48 e5a7a8
9b49 e5a79c
9b4a e5a68d
9b4b e5a799
9b4c e5a79a
9b4d e5a8a5
9b4e e5a89f
9b4f e5a891
9b50 e5a89c
9b51 e5a889
9b52 e5a89a
9b53 e5a980
9b54 e5a9ac
9b55 e5a989
9b56 e5a8b5
9b57 e5a8b6
9b58 e5a9a2
9b59 e5a9aa
9b5a e5aa9a
9b5b e5aabc
9b5c e5aabe
9b5d e5ab8b
9b5e e5ab82
9b5f e5aabd
9b60 e5aba3
9b61 e5ab97
9b62 e5aba6
9b63 e5aba9
9b64 e5ab96
9b65 e5abba
9b66 e5abbb
9b67 e5ac8c
9b68 e5ac8b
9b69 e5ac96
9b6a e5acb2
9b6b e5ab90
9b6c e5acaa
9b6d e5acb6
9b6e e5acbe
9b6f e5ad83
9b70 e5ad85
9b71 e5ad80
9b72 e5ad91
9b73 e5ad95
9b74 e5ad9a
9b75 e5ad9b
9b76 e5ada5
9b77 e5ada9
9b78 e5adb0
9b79 e5adb3
9b7a e5adb5
9b7b e5adb8
9b7c e69688
9b7d e5adba
9b7e e5ae80
9b80 e5ae83
9b81 e5aea6
9b82 e5aeb8
9b83 e5af83
9b84 e5af87
9b85 e5af89
9b86 e5af94
9b87 e5af90
9b88 e5afa4
9b89 e5afa6
9b8a e5afa2
9b8b e5af9e
9b8c e5afa5
9b8d e5afab
9b8e e5afb0
9b8f e5afb6
9b90 e5afb3
9b91 e5b085
9b92 e5b087
9b93 e5b088
9b94 e5b08d
9b95 e5b093
9b96 e5b0a0
9b97 e5b0a2
9b98 e5b0a8
9b99 e5b0b8
9b9a e5b0b9
9b9b e5b181
9b9c e5b186
9b9d e5b18e
9b9e e5b193
9b9f e5b190
9ba0 e5b18f
9ba1 e5adb1
9ba2 e5b1ac
9ba3 e5b1ae
9ba4 e4b9a2
9ba5 e5b1b6
9ba6 e5b1b9
9ba7 e5b28c
9ba8 e5b291
9ba9 e5b294
9baa e5a69b
9bab e5b2ab
9bac e5b2bb
9bad e5b2b6
9bae e5b2bc
9baf e5b2b7
9bb0 e5b385
9bb1 e5b2be
9bb2 e5b387
9bb3 e5b399
9bb4 e5b3a9
9bb5 e5b3bd
9bb6 e5b3ba
9bb7 e5b3ad
9bb8 e5b68c
9bb9 e5b3aa
9bba e5b48b
9bbb e5b495
9bbc e5b497
9bbd e5b59c
9bbe e5b49f
9bbf e5b49b
9bc0 e5b491
9bc1 e5b494
9bc2 e5b4a2
9bc3 e5b49a
9bc4 e5b499
9bc5 e5b498
9bc6 e5b58c
9bc7 e5b592
9bc8 e5b58e
9bc9 e5b58b
9bca e5b5ac
9bcb e5b5b3
9bcc e5b5b6
9bcd e5b687
9bce e5b684
9bcf e5b682
9bd0 e5b6a2
9bd1 e5b69d
9bd2 e5b6ac
9bd3 e5b6ae
9bd4 e5b6bd
9bd5 e5b690
9bd6 e5b6b7
9bd7 e5b6bc
9bd8 e5b789
9bd9 e5b78d
9bda e5b793
9bdb e5b792
9bdc e5b796
9bdd e5b79b
9bde e5b7ab
9bdf e5b7b2
9be0 e5b7b5
9be1 e5b88b
9be2 e5b89a
9be3 e5b899
9be4 e5b891
9be5 e5b89b
9be6 e5b8b6
9be7 e5b8b7
9be8 e5b984
9be9 e5b983
9bea e5b980
9beb e5b98e
9bec e5b997
9bed e5b994
9bee e5b99f
9bef e5b9a2
9bf0 e5b9a4
9bf1 e5b987
9bf2 e5b9b5
9bf3 e5b9b6
9bf4 e5b9ba
9bf5 e9babc
9bf6 e5b9bf
9bf7 e5baa0
9bf8 e5bb81
9bf9 e5bb82
9bfa e5bb88
9bfb e5bb90
9bfc e5bb8f
9c40 e5bb96
9c41 e5bba3
9c42 e5bb9d
9c43 e5bb9a
9c44 e5bb9b
9c45 e5bba2
9c46 e5bba1
9c47 e5bba8
9c48 e5bba9
9c49 e5bbac
9c4a e5bbb1
9c4b e5bbb3
9c4c e5bbb0
9c4d e5bbb4
9c4e e5bbb8
9c4f e5bbbe
9c50 e5bc83
9c51 e5bc89
9c52 e5bd9d
9c53 e5bd9c
9c54 e5bc8b
9c55 e5bc91
9c56 e5bc96
9c57 e5bca9
9c58 e5bcad
9c59 e5bcb8
9c5a e5bd81
9c5b e5bd88
9c5c e5bd8c
9c5d e5bd8e
9c5e e5bcaf
9c5f e5bd91
9c60 e5bd96
9c61 e5bd97
9c62 e5bd99
9c63 e5bda1
9c64 e5bdad
9c65 e5bdb3
9c66 e5bdb7
9c67 e5be83
9c68 e5be82
9c69 e5bdbf
9c6a e5be8a
9c6b e5be88
9c6c e5be91
9c6d e5be87
9c6e e5be9e
9c6f e5be99
9c70 e5be98
9c71 e5bea0
9c72 e5bea8
9c73 e5bead
9c74 e5bebc
9c75 e5bf96
9c76 e5bfbb
9c77 e5bfa4
9c78 e5bfb8
9c79 e5bfb1
9c7a e5bf9d
9c7b e682b3
9c7c e5bfbf
9c7d e680a1
9c7e e681a0
9c80 e68099
9c81 e68090
9c82 e680a9
9c83 e6808e
9c84 e680b1
9c85 e6809b
9c86 e68095
9c87 e680ab
9c88 e680a6
9c89 e6808f
9c8a e680ba
9c8b e6819a
9c8c e68181
9c8d e681aa
9c8e e681b7
9c8f e6819f
9c90 e6818a
9c91 e68186
9c92 e6818d
9c93 e681a3
9c94 e68183
9c95 e681a4
9c96 e68182
9c97 e681ac
9c98 e681ab
9c99 e68199
9c9a e68281
9c9b e6828d
9c9c e683a7
9c9d e68283
9c9e e6829a
9c9f e68284
9ca0 e6829b
9ca1 e68296
9ca2 e68297
9ca3 e68292
9ca4 e682a7
9ca5 e6828b
9ca6 e683a1
9ca7 e682b8
9ca8 e683a0
9ca9 e68393
9caa e682b4
9cab e5bfb0
9cac e682bd
9cad e68386
9cae e682b5
9caf e68398
9cb0 e6858d
9cb1 e68495
9cb2 e68486
9cb3 e683b6
9cb4 e683b7
9cb5 e68480
9cb6 e683b4
9cb7 e683ba
9cb8 e68483
9cb9 e684a1
9cba e683bb
9cbb e683b1
9cbc e6848d
9cbd e6848e
9cbe e68587
9cbf e684be
9cc0 e684a8
9cc1 e684a7
9cc2 e6858a
9cc3 e684bf
9cc4 e684bc
9cc5 e684ac
9cc6 e684b4
9cc7 e684bd
9cc8 e68582
9cc9 e68584
9cca e685b3
9ccb e685b7
9ccc e68598
9ccd e68599
9cce e6859a
9ccf e685ab
9cd0 e685b4
9cd1 e685af
9cd2 e685a5
9cd3 e685b1
9cd4 e6859f
9cd5 e6859d
9cd6 e68593
9cd7 e685b5
9cd8 e68699
9cd9 e68696
9cda e68687
9cdb e686ac
9cdc e68694
9cdd e6869a
9cde e6868a
9cdf e68691
9ce0 e686ab
9ce1 e686ae
9ce2 e6878c
9ce3 e6878a
9ce4 e68789
9ce5 e687b7
9ce6 e68788
9ce7 e68783
9ce8 e68786
9ce9 e686ba
9cea e6878b
9ceb e7bdb9
9cec e6878d
9ced e687a6
9cee e687a3
9cef e687b6
9cf0 e687ba
9cf1 e687b4
9cf2 e687bf
9cf3 e687bd
9cf4 e687bc
9cf5 e687be
9cf6 e68880
9cf7 e68888
9cf8 e68889
9cf9 e6888d
9cfa e6888c
9cfb e68894
9cfc e6889b
9d40 e6889e
9d41 e688a1
9d42 e688aa
9d43 e688ae
9d44 e688b0
9d45 e688b2
9d46 e688b3
9d47 e68981
9d48 e6898e
9d49 e6899e
9d4a e689a3
9d4b e6899b
9d4c e689a0
9d4d e689a8
9d4e e689bc
9d4f e68a82
9d50 e68a89
9d51 e689be
9d52 e68a92
9d53 e68a93
9d54 e68a96
9d55 e68b94
9d56 e68a83
9d57 e68a94
9d58 e68b97
9d59 e68b91
9d5a e68abb
9d5b e68b8f
9d5c e68bbf
9d5d e68b86
9d5e e69394
9d5f e68b88
9d60 e68b9c
9d61 e68b8c
9d62 e68b8a
9d63 e68b82
9d64 e68b87
9d65 e68a9b
9d66 e68b89
9d67 e68c8c
9d68 e68bae
9d69 e68bb1
9d6a e68ca7
9d6b e68c82
9d6c e68c88
9d6d e68baf
9d6e e68bb5
9d6f e68d90
9d70 e68cbe
9d71 e68d8d
9d72 e6909c
9d73 e68d8f
9d74 e68e96
9d75 e68e8e
9d76 e68e80
9d77 e68eab
9d78 e68db6
9d79 e68ea3
9d7a e68e8f
9d7b e68e89
9d7c e68e9f
9d7d e68eb5
9d7e e68dab
9d80 e68da9
9d81 e68ebe
9d82 e68fa9
9d83 e68f80
9d84 e68f86
9d85 e68fa3
9d86 e68f89
9d87 e68f92
9d88 e68fb6
9d89 e68f84
9d8a e69096
9d8b e690b4
9d8c e69086
9d8d e69093
9d8e e690a6
9d8f e690b6
9d90 e6949d
9d91 e69097
9d92 e690a8
9d93 e6908f
9d94 e691a7
9d95 e691af
9d96 e691b6
9d97 e6918e
9d98 e694aa
9d99 e69295
9d9a e69293
9d9b e692a5
9d9c e692a9
9d9d e69288
9d9e e692bc
9d9f e6939a
9da0 e69392
9da1 e69385
9da2 e69387
9da3 e692bb
9da4 e69398
9da5 e69382
9da6 e693b1
9da7 e693a7
9da8 e88889
9da9 e693a0
9daa e693a1
9dab e68aac
9dac e693a3
9dad e693af
9dae e694ac
9daf e693b6
9db0 e693b4
9db1 e693b2
9db2 e693ba
9db3 e69480
9db4 e693bd
9db5 e69498
9db6 e6949c
9db7 e69485
9db8 e694a4
9db9 e694a3
9dba e694ab
9dbb e694b4
9dbc e694b5
9dbd e694b7
9dbe e694b6
9dbf e694b8
9dc0 e7958b
9dc1 e69588
9dc2 e69596
9dc3 e69595
9dc4 e6958d
9dc5 e69598
9dc6 e6959e
9dc7 e6959d
9dc8 e695b2
9dc9 e695b8
9dca e69682
9dcb e69683
9dcc e8ae8a
9dcd e6969b
9dce e6969f
9dcf e696ab
9dd0 e696b7
9dd1 e69783
9dd2 e69786
9dd3 e69781
9dd4 e69784
9dd5 e6978c
9dd6 e69792
9dd7 e6979b
9dd8 e69799
9dd9 e697a0
9dda e697a1
9ddb e697b1
9ddc e69db2
9ddd e6988a
9dde e69883
9ddf e697bb
9de0 e69db3
9de1 e698b5
9de2 e698b6
9de3 e698b4
9de4 e6989c
9de5 e6998f
9de6 e69984
9de7 e69989
9de8 e69981
9de9 e6999e
9dea e6999d
9deb e699a4
9dec e699a7
9ded e699a8
9dee e6999f
9def e699a2
9df0 e699b0
9df1 e69a83
9df2 e69a88
9df3 e69a8e
9df4 e69a89
9df5 e69a84
9df6 e69a98
9df7 e69a9d
9df8 e69b81
9df9 e69ab9
9dfa e69b89
9dfb e69abe
9dfc e69abc
9e40 e69b84
9e41 e69ab8
9e42 e69b96
9e43 e69b9a
9e44 e69ba0
9e45 e698bf
9e46 e69ba6
9e47 e69ba9
9e48 e69bb0
9e49 e69bb5
9e4a e69bb7
9e4b e69c8f
9e4c e69c96
9e4d e69c9e
9e4e e69ca6
9e4f e69ca7
9e50 e99cb8
9e51 e69cae
9e52 e69cbf
9e53 e69cb6
9e54 e69d81
9e55 e69cb8
9e56 e69cb7
9e57 e69d86
9e58 e69d9e
9e59 e69da0
9e5a e69d99
9e5b e69da3
9e5c e69da4
9e5d e69e89
9e5e e69db0
9e5f e69ea9
9e60 e69dbc
9e61 e69daa
9e62 e69e8c
9e63 e69e8b
9e64 e69ea6
9e65 e69ea1
9e66 e69e85
9e67 e69eb7
9e68 e69faf
9e69 e69eb4
9e6a e69fac
9e6b e69eb3
9e6c e69fa9
9e6d e69eb8
9e6e e69fa4
9e6f e69f9e
9e70 e69f9d
9e71 e69fa2
9e72 e69fae
9e73 e69eb9
9e74 e69f8e
9e75 e69f86
9e76 e69fa7
9e77 e6aa9c
9e78 e6a09e
9e79 e6a186
9e7a e6a0a9
9e7b e6a180
9e7c e6a18d
9e7d e6a0b2
9e7e e6a18e
9e80 e6a2b3
9e81 e6a0ab
9e82 e6a199
9e83 e6a1a3
9e84 e6a1b7
9e85 e6a1bf
9e86 e6a29f
9e87 e6a28f
9e88 e6a2ad
9e89 e6a294
9e8a e6a29d
9e8b e6a29b
9e8c e6a283
9e8d e6aaae
9e8e e6a2b9
9e8f e6a1b4
9e90 e6a2b5
9e91 e6a2a0
9e92 e6a2ba
9e93 e6a48f
9e94 e6a28d
9e95 e6a1be
9e96 e6a481
9e97 e6a38a
9e98 e6a488
9e99 e6a398
9e9a e6a4a2
9e9b e6a4a6
9e9c e6a3a1
9e9d e6a48c
9e9e e6a38d
9e9f e6a394
9ea0 e6a3a7
9ea1 e6a395
9ea2 e6a4b6
9ea3 e6a492
9ea4 e6a484
9ea5 e6a397
9ea6 e6a3a3
9ea7 e6a4a5
9ea8 e6a3b9
9ea9 e6a3a0
9eaa e6a3af
9eab e6a4a8
9eac e6a4aa
9ead e6a49a
9eae e6a4a3
9eaf e6a4a1
9eb0 e6a386
9eb1 e6a5b9
9eb2 e6a5b7
9eb3 e6a59c
9eb4 e6a5b8
9eb5 e6a5ab
9eb6 e6a594
9eb7 e6a5be
9eb8 e6a5ae
9eb9 e6a4b9
9eba e6a5b4
9ebb e6a4bd
9ebc e6a599
9ebd e6a4b0
9ebe e6a5a1
9ebf e6a59e
9ec0 e6a59d
9ec1 e6a681
9ec2 e6a5aa
9ec3 e6a6b2
9ec4 e6a6ae
9ec5 e6a790
9ec6 e6a6bf
9ec7 e6a781
9ec8 e6a793
9ec9 e6a6be
9eca e6a78e
9ecb e5afa8
9ecc e6a78a
9ecd e6a79d
9ece e6a6bb
9ecf e6a783
9ed0 e6a6a7
9ed1 e6a8ae
9ed2 e6a691
9ed3 e6a6a0
9ed4 e6a69c
9ed5 e6a695
9ed6 e6a6b4
9ed7 e6a79e
9ed8 e6a7a8
9ed9 e6a882
9eda e6a89b
9edb e6a7bf
9edc e6ac8a
9edd e6a7b9
9ede e6a7b2
9edf e6a7a7
9ee0 e6a885
9ee1 e6a6b1
9ee2 e6a89e
9ee3 e6a7ad
9ee4 e6a894
9ee5 e6a7ab
9ee6 e6a88a
9ee7 e6a892
9ee8 e6ab81
9ee9 e6a8a3
9eea e6a893
9eeb e6a984
9eec e6a88c
9eed e6a9b2
9eee e6a8b6
9eef e6a9b8
9ef0 e6a987
9ef1 e6a9a2
9ef2 e6a999
9ef3 e6a9a6
9ef4 e6a988
9ef5 e6a8b8
9ef6 e6a8a2
9ef7 e6aa90
9ef8 e6aa8d
9ef9 e6aaa0
9efa e6aa84
9efb e6aaa2
9efc e6aaa3
9f40 e6aa97
9f41 e89897
9f42 e6aabb
9f43 e6ab83
9f44 e6ab82
9f45 e6aab8
9f46 e6aab3
9f47 e6aaac
9f48 e6ab9e
9f49 e6ab91
9f4a e6ab9f
9f4b e6aaaa
9f4c e6ab9a
9f4d e6abaa
9f4e e6abbb
9f4f e6ac85
9f50 e89896
9f51 e6abba
9f52 e6ac92
9f53 e6ac96
9f54 e9acb1
9f55 e6ac9f
9f56 e6acb8
9f57 e6acb7
9f58 e79b9c
9f59 e6acb9
9f5a e9a3ae
9f5b e6ad87
9f5c e6ad83
9f5d e6ad89
9f5e e6ad90
9f5f e6ad99
9f60 e6ad94
9f61 e6ad9b
9f62 e6ad9f
9f63 e6ada1
9f64 e6adb8
9f65 e6adb9
9f66 e6adbf
9f67 e6ae80
9f68 e6ae84
9f69 e6ae83
9f6a e6ae8d
9f6b e6ae98
9f6c e6ae95
9f6d e6ae9e
9f6e e6aea4
9f6f e6aeaa
9f70 e6aeab
9f71 e6aeaf
9f72 e6aeb2
9f73 e6aeb1
9f74 e6aeb3
9f75 e6aeb7
9f76 e6aebc
9f77 e6af86
9f78 e6af8b
9f79 e6af93
9f7a e6af9f
9f7b e6afac
9f7c e6afab
9f7d e6afb3
9f7e e6afaf
9f80 e9babe
9f81 e6b088
9f82 e6b093
9f83 e6b094
9f84 e6b09b
9f85 e6b0a4
9f86 e6b0a3
9f87 e6b19e
9f88 e6b195
9f89 e6b1a2
9f8a e6b1aa
9f8b e6b282
9f8c e6b28d
9f8d e6b29a
9f8e e6b281
9f8f e6b29b
9f90 e6b1be
9f91 e6b1a8
9f92 e6b1b3
9f93 e6b292
9f94 e6b290
9f95 e6b384
9f96 e6b3b1
9f97 e6b393
9f98 e6b2bd
9f99 e6b397
9f9a e6b385
9f9b e6b39d
9f9c e6b2ae
9f9d e6b2b1
9f9e e6b2be
9f9f e6b2ba
9fa0 e6b39b
9fa1 e6b3af
9fa2 e6b399
9fa3 e6b3aa
9fa4 e6b49f
9fa5 e8a18d
9fa6 e6b4b6
9fa7 e6b4ab
9fa8 e6b4bd
9fa9 e6b4b8
9faa e6b499
9fab e6b4b5
9fac e6b4b3
9fad e6b492
9fae e6b48c
9faf e6b5a3
9fb0 e6b693
9fb1 e6b5a4
9fb2 e6b59a
9fb3 e6b5b9
9fb4 e6b599
9fb5 e6b68e
9fb6 e6b695
9fb7 e6bfa4
9fb8 e6b685
9fb9 e6b7b9
9fba e6b895
9fbb e6b88a
9fbc e6b6b5
9fbd e6b787
9fbe e6b7a6
9fbf e6b6b8
9fc0 e6b786
9fc1 e6b7ac
9fc2 e6b79e
9fc3 e6b78c
9fc4 e6b7a8
9fc5 e6b792
9fc6 e6b785
9fc7 e6b7ba
9fc8 e6b799
9fc9 e6b7a4
9fca e6b795
9fcb e6b7aa
9fcc e6b7ae
9fcd e6b8ad
9fce e6b9ae
9fcf e6b8ae
9fd0 e6b899
9fd1 e6b9b2
9fd2 e6b99f
9fd3 e6b8be
9fd4 e6b8a3
9fd5 e6b9ab
9fd6 e6b8ab
9fd7 e6b9b6
9fd8 e6b98d
9fd9 e6b89f
9fda e6b983
9fdb e6b8ba
9fdc e6b98e
9fdd e6b8a4
9fde e6bbbf
9fdf e6b89d
9fe0 e6b8b8
9fe1 e6ba82
9fe2 e6baaa
9fe3 e6ba98
9fe4 e6bb89
9fe5 e6bab7
9fe6 e6bb93
9fe7 e6babd
9fe8 e6baaf
9fe9 e6bb84
9fea e6bab2
9feb e6bb94
9fec e6bb95
9fed e6ba8f
9fee e6baa5
9fef e6bb82
9ff0 e6ba9f
9ff1 e6bd81
9ff2 e6bc91
9ff3 e7818c
9ff4 e6bbac
9ff5 e6bbb8
9ff6 e6bbbe
9ff7 e6bcbf
9ff8 e6bbb2
9ff9 e6bcb1
9ffa e6bbaf
9ffb e6bcb2
9ffc e6bb8c
e040 e6bcbe
e041 e6bc93
e042 e6bbb7
e043 e6be86
e044 e6bdba
e045 e6bdb8
e046 e6be81
e047 e6be80
e048 e6bdaf
e049 e6bd9b
e04a e6bfb3
e04b e6bdad
e04c e6be82
e04d e6bdbc
e04e e6bd98
e04f e6be8e
e050 e6be91
e051 e6bf82
e052 e6bda6
e053 e6beb3
e054 e6bea3
e055 e6bea1
e056 e6bea4
e057 e6beb9
e058 e6bf86
e059 e6beaa
e05a e6bf9f
e05b e6bf95
e05c e6bfac
e05d e6bf94
e05e e6bf98
e05f e6bfb1
e060 e6bfae
e061 e6bf9b
e062 e78089
e063 e7808b
e064 e6bfba
e065 e78091
e066 e78081
e067 e7808f
e068 e6bfbe
e069 e7809b
e06a e7809a
e06b e6bdb4
e06c e7809d
e06d e78098
e06e e7809f
e06f e780b0
e070 e780be
e071 e780b2
e072 e78191
e073 e781a3
e074 e78299
e075 e78292
e076 e782af
e077 e783b1
e078 e782ac
e079 e782b8
e07a e782b3
e07b e782ae
e07c e7839f
e07d e7838b
e07e e7839d
e080 e78399
e081 e78489
e082 e783bd
e083 e7849c
e084 e78499
e085 e785a5
e086 e78595
e087 e78688
e088 e785a6
e089 e785a2
e08a e7858c
e08b e78596
e08c e785ac
e08d e7868f
e08e e787bb
e08f e78684
e090 e78695
e091 e786a8
e092 e786ac
e093 e78797
e094 e786b9
e095 e786be
e096 e78792
e097 e78789
e098 e78794
e099 e7878e
e09a e787a0
e09b e787ac
e09c e787a7
e09d e787b5
e09e e787bc
e09f e787b9
e0a0 e787bf
e0a1 e7888d
e0a2 e78890
e0a3 e7889b
e0a4 e788a8
e0a5 e788ad
e0a6 e788ac
e0a7 e788b0
e0a8 e788b2
e0a9 e788bb
e0aa e788bc
e0ab e788bf
e0ac e78980
e0ad e78986
e0ae e7898b
e0af e78998
e0b0 e789b4
e0b1 e789be
e0b2 e78a82
e0b3 e78a81
e0b4 e78a87
e0b5 e78a92
e0b6 e78a96
e0b7 e78aa2
e0b8 e78aa7
e0b9 e78ab9
e0ba e78ab2
e0bb e78b83
e0bc e78b86
e0bd e78b84
e0be e78b8e
e0bf e78b92
e0c0 e78ba2
e0c1 e78ba0
e0c2 e78ba1
e0c3 e78bb9
e0c4 e78bb7
e0c5 e5808f
e0c6 e78c97
e0c7 e78c8a
e0c8 e78c9c
e0c9 e78c96
e0ca e78c9d
e0cb e78cb4
e0cc e78caf
e0cd e78ca9
e0ce e78ca5
e0cf e78cbe
e0d0 e78d8e
e0d1 e78d8f
e0d2 e9bb98
e0d3 e78d97
e0d4 e78daa
e0d5 e78da8
e0d6 e78db0
e0d7 e78db8
e0d8 e78db5
e0d9 e78dbb
e0da e78dba
e0db e78f88
e0dc e78eb3
e0dd e78f8e
e0de e78ebb
e0df e78f80
e0e0 e78fa5
e0e1 e78fae
e0e2 e78f9e
e0e3 e792a2
e0e4 e79085
e0e5 e791af
e0e6 e790a5
e0e7 e78fb8
e0e8 e790b2
e0e9 e790ba
e0ea e79195
e0eb e790bf
e0ec e7919f
e0ed e79199
e0ee e79181
e0ef e7919c
e0f0 e791a9
e0f1 e791b0
e0f2 e791a3
e0f3 e791aa
e0f4 e791b6
e0f5 e791be
e0f6 e7928b
e0f7 e7929e
e0f8 e792a7
e0f9 e7938a
e0fa e7938f
e0fb e79394
e0fc e78fb1
e140 e793a0
e141 e793a3
e142 e793a7
e143 e793a9
e144 e793ae
e145 e793b2
e146 e793b0
e147 e793b1
e148 e793b8
e149 e793b7
e14a e79484
e14b e79483
e14c e79485
e14d e7948c
e14e e7948e
e14f e7948d
e150 e79495
e151 e79493
e152 e7949e
e153 e794a6
e154 e794ac
e155 e794bc
e156 e79584
e157 e7958d
e158 e7958a
e159 e79589
e15a e7959b
e15b e79586
e15c e7959a
e15d e795a9
e15e e795a4
e15f e795a7
e160 e795ab
e161 e795ad
e162 e795b8
e163 e795b6
e164 e79686
e165 e79687
e166 e795b4
e167 e7968a
e168 e79689
e169 e79682
e16a e79694
e16b e7969a
e16c e7969d
e16d e796a5
e16e e796a3
e16f e79782
e170 e796b3
e171 e79783
e172 e796b5
e173 e796bd
e174 e796b8
e175 e796bc
e176 e796b1
e177 e7978d
e178 e7978a
e179 e79792
e17a e79799
e17b e797a3
e17c e7979e
e17d e797be
e17e e797bf
e180 e797bc
e181 e79881
e182 e797b0
e183 e797ba
e184 e797b2
e185 e797b3
e186 e7988b
e187 e7988d
e188 e79889
e189 e7989f
e18a e798a7
e18b e798a0
e18c e798a1
e18d e798a2
e18e e798a4
e18f e798b4
e190 e798b0
e191 e798bb
e192 e79987
e193 e79988
e194 e79986
e195 e7999c
e196 e79998
e197 e799a1
e198 e799a2
e199 e799a8
e19a e799a9
e19b e799aa
e19c e799a7
e19d e799ac
e19e e799b0
e19f e799b2
e1a0 e799b6
e1a1 e799b8
e1a2 e799bc
e1a3 e79a80
e1a4 e79a83
e1a5 e79a88
e1a6 e79a8b
e1a7 e79a8e
e1a8 e79a96
e1a9 e79a93
e1aa e79a99
e1ab e79a9a
e1ac e79ab0
e1ad e79ab4
e1ae e79ab8
e1af e79ab9
e1b0 e79aba
e1b1 e79b82
e1b2 e79b8d
e1b3 e79b96
e1b4 e79b92
e1b5 e79b9e
e1b6 e79ba1
e1b7 e79ba5
e1b8 e79ba7
e1b9 e79baa
e1ba e898af
e1bb e79bbb
e1bc e79c88
e1bd e79c87
e1be e79c84
e1bf e79ca9
e1c0 e79ca4
e1c1 e79c9e
e1c2 e79ca5
e1c3 e79ca6
e1c4 e79c9b
e1c5 e79cb7
e1c6 e79cb8
e1c7 e79d87
e1c8 e79d9a
e1c9 e79da8
e1ca e79dab
e1cb e79d9b
e1cc e79da5
e1cd e79dbf
e1ce e79dbe
e1cf e79db9
e1d0 e79e8e
e1d1 e79e8b
e1d2 e79e91
e1d3 e79ea0
e1d4 e79e9e
e1d5 e79eb0
e1d6 e79eb6
e1d7 e79eb9
e1d8 e79ebf
e1d9 e79ebc
e1da e79ebd
e1db e79ebb
e1dc e79f87
e1dd e79f8d
e1de e79f97
e1df e79f9a
e1e0 e79f9c
e1e1 e79fa3
e1e2 e79fae
e1e3 e79fbc
e1e4 e7a08c
e1e5 e7a092
e1e6 e7a4a6
e1e7 e7a0a0
e1e8 e7a4aa
e1e9 e7a185
e1ea e7a28e
e1eb e7a1b4
e1ec e7a286
e1ed e7a1bc
e1ee e7a29a
e1ef e7a28c
e1f0 e7a2a3
e1f1 e7a2b5
e1f2 e7a2aa
e1f3 e7a2af
e1f4 e7a391
e1f5 e7a386
e1f6 e7a38b
e1f7 e7a394
e1f8 e7a2be
e1f9 e7a2bc
e1fa e7a385
e1fb e7a38a
e1fc e7a3ac
e240 e7a3a7
e241 e7a39a
e242 e7a3bd
e243 e7a3b4
e244 e7a487
e245 e7a492
e246 e7a491
e247 e7a499
e248 e7a4ac
e249 e7a4ab
e24a e7a580
e24b e7a5a0
e24c e7a597
e24d e7a59f
e24e e7a59a
e24f e7a595
e250 e7a593
e251 e7a5ba
e252 e7a5bf
e253 e7a68a
e254 e7a69d
e255 e7a6a7
e256 e9bd8b
e257 e7a6aa
e258 e7a6ae
e259 e7a6b3
e25a e7a6b9
e25b e7a6ba
e25c e7a789
e25d e7a795
e25e e7a7a7
e25f e7a7ac
e260 e7a7a1
e261 e7a7a3
e262 e7a888
e263 e7a88d
e264 e7a898
e265 e7a899
e266 e7a8a0
e267 e7a89f
e268 e7a680
e269 e7a8b1
e26a e7a8bb
e26b e7a8be
e26c e7a8b7
e26d e7a983
e26e e7a997
e26f e7a989
e270 e7a9a1
e271 e7a9a2
e272 e7a9a9
e273 e9be9d
e274 e7a9b0
e275 e7a9b9
e276 e7a9bd
e277 e7aa88
e278 e7aa97
e279 e7aa95
e27a e7aa98
e27b e7aa96
e27c e7aaa9
e27d e7ab88
e27e e7aab0
e280 e7aab6
e281 e7ab85
e282 e7ab84
e283 e7aabf
e284 e98283
e285 e7ab87
e286 e7ab8a
e287 e7ab8d
e288 e7ab8f
e289 e7ab95
e28a e7ab93
e28b e7ab99
e28c e7ab9a
e28d e7ab9d
e28e e7aba1
e28f e7aba2
e290 e7aba6
e291 e7abad
e292 e7abb0
e293 e7ac82
e294 e7ac8f
e295 e7ac8a
e296 e7ac86
e297 e7acb3
e298 e7ac98
e299 e7ac99
e29a e7ac9e
e29b e7acb5
e29c e7aca8
e29d e7acb6
e29e e7ad90
e29f e7adba
e2a0 e7ac84
e2a1 e7ad8d
e2a2 e7ac8b
e2a3 e7ad8c
e2a4 e7ad85
e2a5 e7adb5
e2a6 e7ada5
e2a7 e7adb4
e2a8 e7ada7
e2a9 e7adb0
e2aa e7adb1
e2ab e7adac
e2ac e7adae
e2ad e7ae9d
e2ae e7ae98
e2af e7ae9f
e2b0 e7ae8d
e2b1 e7ae9c
e2b2 e7ae9a
e2b3 e7ae8b
e2b4 e7ae92
e2b5 e7ae8f
e2b6 e7ad9d
e2b7 e7ae99
e2b8 e7af8b
e2b9 e7af81
e2ba e7af8c
e2bb e7af8f
e2bc e7aeb4
e2bd e7af86
e2be e7af9d
e2bf e7afa9
e2c0 e7b091
e2c1 e7b094
e2c2 e7afa6
e2c3 e7afa5
e2c4 e7b1a0
e2c5 e7b080
e2c6 e7b087
e2c7 e7b093
e2c8 e7afb3
e2c9 e7afb7
e2ca e7b097
e2cb e7b08d
e2cc e7afb6
e2cd e7b0a3
e2ce e7b0a7
e2cf e7b0aa
e2d0 e7b09f
e2d1 e7b0b7
e2d2 e7b0ab
e2d3 e7b0bd
e2d4 e7b18c
e2d5 e7b183
e2d6 e7b194
e2d7 e7b18f
e2d8 e7b180
e2d9 e7b190
e2da e7b198
e2db e7b19f
e2dc e7b1a4
e2dd e7b196
e2de e7b1a5
e2df e7b1ac
e2e0 e7b1b5
e2e1 e7b283
e2e2 e7b290
e2e3 e7b2a4
e2e4 e7b2ad
e2e5 e7b2a2
e2e6 e7b2ab
e2e7 e7b2a1
e2e8 e7b2a8
e2e9 e7b2b3
e2ea e7b2b2
e2eb e7b2b1
e2ec e7b2ae
e2ed e7b2b9
e2ee e7b2bd
e2ef e7b380
e2f0 e7b385
e2f1 e7b382
e2f2 e7b398
e2f3 e7b392
e2f4 e7b39c
e2f5 e7b3a2
e2f6 e9acbb
e2f7 e7b3af
e2f8 e7b3b2
e2f9 e7b3b4
e2fa e7b3b6
e2fb e7b3ba
e2fc e7b486
e340 e7b482
e341 e7b49c
e342 e7b495
e343 e7b48a
e344 e7b585
e345 e7b58b
e346 e7b4ae
e347 e7b4b2
e348 e7b4bf
e349 e7b4b5
e34a e7b586
e34b e7b5b3
e34c e7b596
e34d e7b58e
e34e e7b5b2
e34f e7b5a8
e350 e7b5ae
e351 e7b58f
e352 e7b5a3
e353 e7b693
e354 e7b689
e355 e7b59b
e356 e7b68f
e357 e7b5bd
e358 e7b69b
e359 e7b6ba
e35a e7b6ae
e35b e7b6a3
e35c e7b6b5
e35d e7b787
e35e e7b6bd
e35f e7b6ab
e360 e7b8bd
e361 e7b6a2
e362 e7b6af
e363 e7b79c
e364 e7b6b8
e365 e7b69f
e366 e7b6b0
e367 e7b798
e368 e7b79d
e369 e7b7a4
e36a e7b79e
e36b e7b7bb
e36c e7b7b2
e36d e7b7a1
e36e e7b885
e36f e7b88a
e370 e7b8a3
e371 e7b8a1
e372 e7b892
e373 e7b8b1
e374 e7b89f
e375 e7b889
e376 e7b88b
e377 e7b8a2
e378 e7b986
e379 e7b9a6
e37a e7b8bb
e37b e7b8b5
e37c e7b8b9
e37d e7b983
e37e e7b8b7
e380 e7b8b2
e381 e7b8ba
e382 e7b9a7
e383 e7b99d
e384 e7b996
e385 e7b99e
e386 e7b999
e387 e7b99a
e388 e7b9b9
e389 e7b9aa
e38a e7b9a9
e38b e7b9bc
e38c e7b9bb
e38d e7ba83
e38e e7b795
e38f e7b9bd
e390 e8beae
e391 e7b9bf
e392 e7ba88
e393 e7ba89
e394 e7ba8c
e395 e7ba92
e396 e7ba90
e397 e7ba93
e398 e7ba94
e399 e7ba96
e39a e7ba8e
e39b e7ba9b
e39c e7ba9c
e39d e7bcb8
e39e e7bcba
e39f e7bd85
e3a0 e7bd8c
e3a1 e7bd8d
e3a2 e7bd8e
e3a3 e7bd90
e3a4 e7bd91
e3a5 e7bd95
e3a6 e7bd94
e3a7 e7bd98
e3a8 e7bd9f
e3a9 e7bda0
e3aa e7bda8
e3ab e7bda9
e3ac e7bda7
e3ad e7bdb8
e3ae e7be82
e3af e7be86
e3b0 e7be83
e3b1 e7be88
e3b2 e7be87
e3b3 e7be8c
e3b4 e7be94
e3b5 e7be9e
e3b6 e7be9d
e3b7 e7be9a
e3b8 e7bea3
e3b9 e7beaf
e3ba e7beb2
e3bb e7beb9
e3bc e7beae
e3bd e7beb6
e3be e7beb8
e3bf e8adb1
e3c0 e7bf85
e3c1 e7bf86
e3c2 e7bf8a
e3c3 e7bf95
e3c4 e7bf94
e3c5 e7bfa1
e3c6 e7bfa6
e3c7 e7bfa9
e3c8 e7bfb3
e3c9 e7bfb9
e3ca e9a39c
e3cb e88086
e3cc e88084
e3cd e8808b
e3ce e88092
e3cf e88098
e3d0 e88099
e3d1 e8809c
e3d2 e880a1
e3d3 e880a8
e3d4 e880bf
e3d5 e880bb
e3d6 e8818a
e3d7 e88186
e3d8 e88192
e3d9 e88198
e3da e8819a
e3db e8819f
e3dc e881a2
e3dd e881a8
e3de e881b3
e3df e881b2
e3e0 e881b0
e3e1 e881b6
e3e2 e881b9
e3e3 e881bd
e3e4 e881bf
e3e5 e88284
e3e6 e88286
e3e7 e88285
e3e8 e8829b
e3e9 e88293
e3ea e8829a
e3eb e882ad
e3ec e58690
e3ed e882ac
e3ee e8839b
e3ef e883a5
e3f0 e88399
e3f1 e8839d
e3f2 e88384
e3f3 e8839a
e3f4 e88396
e3f5 e88489
e3f6 e883af
e3f7 e883b1
e3f8 e8849b
e3f9 e884a9
e3fa e884a3
e3fb e884af
e3fc e8858b
e440 e99a8b
e441 e88586
e442 e884be
e443 e88593
e444 e88591
e445 e883bc
e446 e885b1
e447 e885ae
e448 e885a5
e449 e885a6
e44a e885b4
e44b e88683
e44c e88688
e44d e8868a
e44e e88680
e44f e88682
e450 e886a0
e451 e88695
e452 e886a4
e453 e886a3
e454 e8859f
e455 e88693
e456 e886a9
e457 e886b0
e458 e886b5
e459 e886be
e45a e886b8
e45b e886bd
e45c e88780
e45d e88782
e45e e886ba
e45f e88789
e460 e8878d
e461 e88791
e462 e88799
e463 e88798
e464 e88788
e465 e8879a
e466 e8879f
e467 e887a0
e468 e887a7
e469 e887ba
e46a e887bb
e46b e887be
e46c e88881
e46d e88882
e46e e88885
e46f e88887
e470 e8888a
e471 e8888d
e472 e88890
e473 e88896
e474 e888a9
e475 e888ab
e476 e888b8
e477 e888b3
e478 e88980
e479 e88999
e47a e88998
e47b e8899d
e47c e8899a
e47d e8899f
e47e e889a4
e480 e889a2
e481 e889a8
e482 e889aa
e483 e889ab
e484 e888ae
e485 e889b1
e486 e889b7
e487 e889b8
e488 e889be
e489 e88a8d
e48a e88a92
e48b e88aab
e48c e88a9f
e48d e88abb
e48e e88aac
e48f e88ba1
e490 e88ba3
e491 e88b9f
e492 e88b92
e493 e88bb4
e494 e88bb3
e495 e88bba
e496 e88e93
e497 e88c83
e498 e88bbb
e499 e88bb9
e49a e88b9e
e49b e88c86
e49c e88b9c
e49d e88c89
e49e e88b99
e49f e88cb5
e4a0 e88cb4
e4a1 e88c96
e4a2 e88cb2
e4a3 e88cb1
e4a4 e88d80
e4a5 e88cb9
e4a6 e88d90
e4a7 e88d85
e4a8 e88caf
e4a9 e88cab
e4aa e88c97
e4ab e88c98
e4ac e88e85
e4ad e88e9a
e4ae e88eaa
e4af e88e9f
e4b0 e88ea2
e4b1 e88e96
e4b2 e88ca3
e4b3 e88e8e
e4b4 e88e87
e4b5 e88e8a
e4b6 e88dbc
e4b7 e88eb5
e4b8 e88db3
e4b9 e88db5
e4ba e88ea0
e4bb e88e89
e4bc e88ea8
e4bd e88fb4
e4be e89093
e4bf e88fab
e4c0 e88f8e
e4c1 e88fbd
e4c2 e89083
e4c3 e88f98
e4c4 e8908b
e4c5 e88f81
e4c6 e88fb7
e4c7 e89087
e4c8 e88fa0
e4c9 e88fb2
e4ca e8908d
e4cb e890a2
e4cc e890a0
e4cd e88ebd
e4ce e890b8
e4cf e89486
e4d0 e88fbb
e4d1 e891ad
e4d2 e890aa
e4d3 e890bc
e4d4 e8959a
e4d5 e89284
e4d6 e891b7
e4d7 e891ab
e4d8 e892ad
e4d9 e891ae
e4da e89282
e4db e891a9
e4dc e89186
e4dd e890ac
e4de e891af
e4df e891b9
e4e0 e890b5
e4e1 e8938a
e4e2 e891a2
e4e3 e892b9
e4e4 e892bf
e4e5 e8929f
e4e6 e89399
e4e7 e8938d
e4e8 e892bb
e4e9 e8939a
e4ea e89390
e4eb e89381
e4ec e89386
e4ed e89396
e4ee e892a1
e4ef e894a1
e4f0 e893bf
e4f1 e893b4
e4f2 e89497
e4f3 e89498
e4f4 e894ac
e4f5 e8949f
e4f6 e89495
e4f7 e89494
e4f8 e893bc
e4f9 e89580
e4fa e895a3
e4fb e89598
e4fc e89588
e540 e89581
e541 e89882
e542 e8958b
e543 e89595
e544 e89680
e545 e896a4
e546 e89688
e547 e89691
e548 e8968a
e549 e896a8
e54a e895ad
e54b e89694
e54c e8969b
e54d e897aa
e54e e89687
e54f e8969c
e550 e895b7
e551 e895be
e552 e89690
e553 e89789
e554 e896ba
e555 e8978f
e556 e896b9
e557 e89790
e558 e89795
e559 e8979d
e55a e897a5
e55b e8979c
e55c e897b9
e55d e8988a
e55e e89893
e55f e8988b
e560 e897be
e561 e897ba
e562 e89886
e563 e898a2
e564 e8989a
e565 e898b0
e566 e898bf
e567 e8998d
e568 e4b995
e569 e89994
e56a e8999f
e56b e899a7
e56c e899b1
e56d e89a93
e56e e89aa3
e56f e89aa9
e570 e89aaa
e571 e89a8b
e572 e89a8c
e573 e89ab6
e574 e89aaf
e575 e89b84
e576 e89b86
e577 e89ab0
e578 e89b89
e579 e8a0a3
e57a e89aab
e57b e89b94
e57c e89b9e
e57d e89ba9
e57e e89bac
e580 e89b9f
e581 e89b9b
e582 e89baf
e583 e89c92
e584 e89c86
e585 e89c88
e586 e89c80
e587 e89c83
e588 e89bbb
e589 e89c91
e58a e89c89
e58b e89c8d
e58c e89bb9
e58d e89c8a
e58e e89cb4
e58f e89cbf
e590 e89cb7
e591 e89cbb
e592 e89ca5
e593 e89ca9
e594 e89c9a
e595 e89da0
e596 e89d9f
e597 e89db8
e598 e89d8c
e599 e89d8e
e59a e89db4
e59b e89d97
e59c e89da8
e59d e89dae
e59e e89d99
e59f e89d93
e5a0 e89da3
e5a1 e89daa
e5a2 e8a085
e5a3 e89ea2
e5a4 e89e9f
e5a5 e89e82
e5a6 e89eaf
e5a7 e89f8b
e5a8 e89ebd
e5a9 e89f80
e5aa e89f90
e5ab e99b96
e5ac e89eab
e5ad e89f84
e5ae e89eb3
e5af e89f87
e5b0 e89f86
e5b1 e89ebb
e5b2 e89faf
e5b3 e89fb2
e5b4 e89fa0
e5b5 e8a08f
e5b6 e8a08d
e5b7 e89fbe
e5b8 e89fb6
e5b9 e89fb7
e5ba e8a08e
e5bb e89f92
e5bc e8a091
e5bd e8a096
e5be e8a095
e5bf e8a0a2
e5c0 e8a0a1
e5c1 e8a0b1
e5c2 e8a0b6
e5c3 e8a0b9
e5c4 e8a0a7
e5c5 e8a0bb
e5c6 e8a184
e5c7 e8a182
e5c8 e8a192
e5c9 e8a199
e5ca e8a19e
e5cb e8a1a2
e5cc e8a1ab
e5cd e8a281
e5ce e8a1be
e5cf e8a29e
e5d0 e8a1b5
e5d1 e8a1bd
e5d2 e8a2b5
e5d3 e8a1b2
e5d4 e8a282
e5d5 e8a297
e5d6 e8a292
e5d7 e8a2ae
e5d8 e8a299
e5d9 e8a2a2
e5da e8a28d
e5db e8a2a4
e5dc e8a2b0
e5dd e8a2bf
e5de e8a2b1
e5df e8a383
e5e0 e8a384
e5e1 e8a394
e5e2 e8a398
e5e3 e8a399
e5e4 e8a39d
e5e5 e8a3b9
e5e6 e8a482
e5e7 e8a3bc
e5e8 e8a3b4
e5e9 e8a3a8
e5ea e8a3b2
e5eb e8a484
e5ec e8a48c
e5ed e8a48a
e5ee e8a493
e5ef e8a583
e5f0 e8a49e
e5f1 e8a4a5
e5f2 e8a4aa
e5f3 e8a4ab
e5f4 e8a581
e5f5 e8a584
e5f6 e8a4bb
e5f7 e8a4b6
e5f8 e8a4b8
e5f9 e8a58c
e5fa e8a49d
e5fb e8a5a0
e5fc e8a59e
e640 e8a5a6
e641 e8a5a4
e642 e8a5ad
e643 e8a5aa
e644 e8a5af
e645 e8a5b4
e646 e8a5b7
e647 e8a5be
e648 e8a683
e649 e8a688
e64a e8a68a
e64b e8a693
e64c e8a698
e64d e8a6a1
e64e e8a6a9
e64f e8a6a6
e650 e8a6ac
e651 e8a6af
e652 e8a6b2
e653 e8a6ba
e654 e8a6bd
e655 e8a6bf
e656 e8a780
e657 e8a79a
e658 e8a79c
e659 e8a79d
e65a e8a7a7
e65b e8a7b4
e65c e8a7b8
e65d e8a883
e65e e8a896
e65f e8a890
e660 e8a88c
e661 e8a89b
e662 e8a89d
e663 e8a8a5
e664 e8a8b6
e665 e8a981
e666 e8a99b
e667 e8a992
e668 e8a986
e669 e8a988
e66a e8a9bc
e66b e8a9ad
e66c e8a9ac
e66d e8a9a2
e66e e8aa85
e66f e8aa82
e670 e8aa84
e671 e8aaa8
e672 e8aaa1
e673 e8aa91
e674 e8aaa5
e675 e8aaa6
e676 e8aa9a
e677 e8aaa3
e678 e8ab84
e679 e8ab8d
e67a e8ab82
e67b e8ab9a
e67c e8abab
e67d e8abb3
e67e e8aba7
e680 e8aba4
e681 e8abb1
e682 e8ac94
e683 e8aba0
e684 e8aba2
e685 e8abb7
e686 e8ab9e
e687 e8ab9b
e688 e8ac8c
e689 e8ac87
e68a e8ac9a
e68b e8aba1
e68c e8ac96
e68d e8ac90
e68e e8ac97
e68f e8aca0
e690 e8acb3
e691 e99eab
e692 e8aca6
e693 e8acab
e694 e8acbe
e695 e8aca8
e696 e8ad81
e697 e8ad8c
e698 e8ad8f
e699 e8ad8e
e69a e8ad89
e69b e8ad96
e69c e8ad9b
e69d e8ad9a
e69e e8adab
e69f e8ad9f
e6a0 e8adac
e6a1 e8adaf
e6a2 e8adb4
e6a3 e8adbd
e6a4 e8ae80
e6a5 e8ae8c
e6a6 e8ae8e
e6a7 e8ae92
e6a8 e8ae93
e6a9 e8ae96
e6aa e8ae99
e6ab e8ae9a
e6ac e8b0ba
e6ad e8b181
e6ae e8b0bf
e6af e8b188
e6b0 e8b18c
e6b1 e8b18e
e6b2 e8b190
e6b3 e8b195
e6b4 e8b1a2
e6b5 e8b1ac
e6b6 e8b1b8
e6b7 e8b1ba
e6b8 e8b282
e6b9 e8b289
e6ba e8b285
e6bb e8b28a
e6bc e8b28d
e6bd e8b28e
e6be e8b294
e6bf e8b1bc
e6c0 e8b298
e6c1 e6889d
e6c2 e8b2ad
e6c3 e8b2aa
e6c4 e8b2bd
e6c5 e8b2b2
e6c6 e8b2b3
e6c7 e8b2ae
e6c8 e8b2b6
e6c9 e8b388
e6ca e8b381
e6cb e8b3a4
e6cc e8b3a3
e6cd e8b39a
e6ce e8b3bd
e6cf e8b3ba
e6d0 e8b3bb
e6d1 e8b484
e6d2 e8b485
e6d3 e8b48a
e6d4 e8b487
e6d5 e8b48f
e6d6 e8b48d
e6d7 e8b490
e6d8 e9bd8e
e6d9 e8b493
e6da e8b38d
e6db e8b494
e6dc e8b496
e6dd e8b5a7
e6de e8b5ad
e6df e8b5b1
e6e0 e8b5b3
e6e1 e8b681
e6e2 e8b699
e6e3 e8b782
e6e4 e8b6be
e6e5 e8b6ba
e6e6 e8b78f
e6e7 e8b79a
e6e8 e8b796
e6e9 e8b78c
e6ea e8b79b
e6eb e8b78b
e6ec e8b7aa
e6ed e8b7ab
e6ee e8b79f
e6ef e8b7a3
e6f0 e8b7bc
e6f1 e8b888
e6f2 e8b889
e6f3 e8b7bf
e6f4 e8b89d
e6f5 e8b89e
e6f6 e8b890
e6f7 e8b89f
e6f8 e8b982
e6f9 e8b8b5
e6fa e8b8b0
e6fb e8b8b4
e6fc e8b98a
e740 e8b987
e741 e8b989
e742 e8b98c
e743 e8b990
e744 e8b988
e745 e8b999
e746 e8b9a4
e747 e8b9a0
e748 e8b8aa
e749 e8b9a3
e74a e8b995
e74b e8b9b6
e74c e8b9b2
e74d e8b9bc
e74e e8ba81
e74f e8ba87
e750 e8ba85
e751 e8ba84
e752 e8ba8b
e753 e8ba8a
e754 e8ba93
e755 e8ba91
e756 e8ba94
e757 e8ba99
e758 e8baaa
e759 e8baa1
e75a e8baac
e75b e8bab0
e75c e8bb86
e75d e8bab1
e75e e8babe
e75f e8bb85
e760 e8bb88
e761 e8bb8b
e762 e8bb9b
e763 e8bba3
e764 e8bbbc
e765 e8bbbb
e766 e8bbab
e767 e8bbbe
e768 e8bc8a
e769 e8bc85
e76a e8bc95
e76b e8bc92
e76c e8bc99
e76d e8bc93
e76e e8bc9c
e76f e8bc9f
e770 e8bc9b
e771 e8bc8c
e772 e8bca6
e773 e8bcb3
e774 e8bcbb
e775 e8bcb9
e776 e8bd85
e777 e8bd82
e778 e8bcbe
e779 e8bd8c
e77a e8bd89
e77b e8bd86
e77c e8bd8e
e77d e8bd97
e77e e8bd9c
e780 e8bda2
e781 e8bda3
e782 e8bda4
e783 e8be9c
e784 e8be9f
e785 e8bea3
e786 e8bead
e787 e8beaf
e788 e8beb7
e789 e8bf9a
e78a e8bfa5
e78b e8bfa2
e78c e8bfaa
e78d e8bfaf
e78e e98287
e78f e8bfb4
e790 e98085
e791 e8bfb9
e792 e8bfba
e793 e98091
e794 e98095
e795 e980a1
e796 e9808d
e797 e9809e
e798 e98096
e799 e9808b
e79a e980a7
e79b e980b6
e79c e980b5
e79d e980b9
e79e e8bfb8
e79f e9818f
e7a0 e98190
e7a1 e98191
e7a2 e98192
e7a3 e9808e
e7a4 e98189
e7a5 e980be
e7a6 e98196
e7a7 e98198
e7a8 e9819e
e7a9 e981a8
e7aa e981af
e7ab e981b6
e7ac e99aa8
e7ad e981b2
e7ae e98282
e7af e981bd
e7b0 e98281
e7b1 e98280
e7b2 e9828a
e7b3 e98289
e7b4 e9828f
e7b5 e982a8
e7b6 e982af
e7b7 e982b1
e7b8 e982b5
e7b9 e983a2
e7ba e983a4
e7bb e68988
e7bc e9839b
e7bd e98482
e7be e98492
e7bf e98499
e7c0 e984b2
e7c1 e984b0
e7c2 e9858a
e7c3 e98596
e7c4 e98598
e7c5 e985a3
e7c6 e985a5
e7c7 e985a9
e7c8 e985b3
e7c9 e985b2
e7ca e9868b
e7cb e98689
e7cc e98682
e7cd e986a2
e7ce e986ab
e7cf e986af
e7d0 e986aa
e7d1 e986b5
e7d2 e986b4
e7d3 e986ba
e7d4 e98780
e7d5 e98781
e7d6 e98789
e7d7 e9878b
e7d8 e98790
e7d9 e98796
e7da e9879f
e7db e987a1
e7dc e9879b
e7dd e987bc
e7de e987b5
e7df e987b6
e7e0 e9889e
e7e1 e987bf
e7e2 e98894
e7e3 e988ac
e7e4 e98895
e7e5 e98891
e7e6 e9899e
e7e7 e98997
e7e8 e98985
e7e9 e98989
e7ea e989a4
e7eb e98988
e7ec e98a95
e7ed e988bf
e7ee e9898b
e7ef e98990
e7f0 e98a9c
e7f1 e98a96
e7f2 e98a93
e7f3 e98a9b
e7f4 e9899a
e7f5 e98b8f
e7f6 e98ab9
e7f7 e98ab7
e7f8 e98ba9
e7f9 e98c8f
e7fa e98bba
e7fb e98d84
e7fc e98cae
e840 e98c99
e841 e98ca2
e842 e98c9a
e843 e98ca3
e844 e98cba
e845 e98cb5
e846 e98cbb
e847 e98d9c
e848 e98da0
e849 e98dbc
e84a e98dae
e84b e98d96
e84c e98eb0
e84d e98eac
e84e e98ead
e84f e98e94
e850 e98eb9
e851 e98f96
e852 e98f97
e853 e98fa8
e854 e98fa5
e855 e98f98
e856 e98f83
e857 e98f9d
e858 e98f90
e859 e98f88
e85a e98fa4
e85b e9909a
e85c e99094
e85d e99093
e85e e99083
e85f e99087
e860 e99090
e861 e990b6
e862 e990ab
e863 e990b5
e864 e990a1
e865 e990ba
e866 e99181
e867 e99192
e868 e99184
e869 e9919b
e86a e991a0
e86b e991a2
e86c e9919e
e86d e991aa
e86e e988a9
e86f e991b0
e870 e991b5
e871 e991b7
e872 e991bd
e873 e9919a
e874 e991bc
e875 e991be
e876 e99281
e877 e991bf
e878 e99682
e879 e99687
e87a e9968a
e87b e99694
e87c e99696
e87d e99698
e87e e99699
e880 e996a0
e881 e996a8
e882 e996a7
e883 e996ad
e884 e996bc
e885 e996bb
e886 e996b9
e887 e996be
e888 e9978a
e889 e6bfb6
e88a e99783
e88b e9978d
e88c e9978c
e88d e99795
e88e e99794
e88f e99796
e890 e9979c
e891 e997a1
e892 e997a5
e893 e997a2
e894 e998a1
e895 e998a8
e896 e998ae
e897 e998af
e898 e99982
e899 e9998c
e89a e9998f
e89b e9998b
e89c e999b7
e89d e9999c
e89e e9999e
e89f e9999d
e8a0 e9999f
e8a1 e999a6
e8a2 e999b2
e8a3 e999ac
e8a4 e99a8d
e8a5 e99a98
e8a6 e99a95
e8a7 e99a97
e8a8 e99aaa
e8a9 e99aa7
e8aa e99ab1
e8ab e99ab2
e8ac e99ab0
e8ad e99ab4
e8ae e99ab6
e8af e99ab8
e8b0 e99ab9
e8b1 e99b8e
e8b2 e99b8b
e8b3 e99b89
e8b4 e99b8d
e8b5 e8a58d
e8b6 e99b9c
e8b7 e99c8d
e8b8 e99b95
e8b9 e99bb9
e8ba e99c84
e8bb e99c86
e8bc e99c88
e8bd e99c93
e8be e99c8e
e8bf e99c91
e8c0 e99c8f
e8c1 e99c96
e8c2 e99c99
e8c3 e99ca4
e8c4 e99caa
e8c5 e99cb0
e8c6 e99cb9
e8c7 e99cbd
e8c8 e99cbe
e8c9 e99d84
e8ca e99d86
e8cb e99d88
e8cc e99d82
e8cd e99d89
e8ce e99d9c
e8cf e99da0
e8d0 e99da4
e8d1 e99da6
e8d2 e99da8
e8d3 e58b92
e8d4 e99dab
e8d5 e99db1
e8d6 e99db9
e8d7 e99e85
e8d8 e99dbc
e8d9 e99e81
e8da e99dba
e8db e99e86
e8dc e99e8b
e8dd e99e8f
e8de e99e90
e8df e99e9c
e8e0 e99ea8
e8e1 e99ea6
e8e2 e99ea3
e8e3 e99eb3
e8e4 e99eb4
e8e5 e99f83
e8e6 e99f86
e8e7 e99f88
e8e8 e99f8b
e8e9 e99f9c
e8ea e99fad
e8eb e9bd8f
e8ec e99fb2
e8ed e7ab9f
e8ee e99fb6
e8ef e99fb5
e8f0 e9a08f
e8f1 e9a08c
e8f2 e9a0b8
e8f3 e9a0a4
e8f4 e9a0a1
e8f5 e9a0b7
e8f6 e9a0bd
e8f7 e9a186
e8f8 e9a18f
e8f9 e9a18b
e8fa e9a1ab
e8fb e9a1af
e8fc e9a1b0
e940 e9a1b1
e941 e9a1b4
e942 e9a1b3
e943 e9a2aa
e944 e9a2af
e945 e9a2b1
e946 e9a2b6
e947 e9a384
e948 e9a383
e949 e9a386
e94a e9a3a9
e94b e9a3ab
e94c e9a483
e94d e9a489
e94e e9a492
e94f e9a494
e950 e9a498
e951 e9a4a1
e952 e9a49d
e953 e9a49e
e954 e9a4a4
e955 e9a4a0
e956 e9a4ac
e957 e9a4ae
e958 e9a4bd
e959 e9a4be
e95a e9a582
e95b e9a589
e95c e9a585
e95d e9a590
e95e e9a58b
e95f e9a591
e960 e9a592
e961 e9a58c
e962 e9a595
e963 e9a697
e964 e9a698
e965 e9a6a5
e966 e9a6ad
e967 e9a6ae
e968 e9a6bc
e969 e9a79f
e96a e9a79b
e96b e9a79d
e96c e9a798
e96d e9a791
e96e e9a7ad
e96f e9a7ae
e970 e9a7b1
e971 e9a7b2
e972 e9a7bb
e973 e9a7b8
e974 e9a881
e975 e9a88f
e976 e9a885
e977 e9a7a2
e978 e9a899
e979 e9a8ab
e97a e9a8b7
e97b e9a985
e97c e9a982
e97d e9a980
e97e e9a983
e980 e9a8be
e981 e9a995
e982 e9a98d
e983 e9a99b
e984 e9a997
e985 e9a99f
e986 e9a9a2
e987 e9a9a5
e988 e9a9a4
e989 e9a9a9
e98a e9a9ab
e98b e9a9aa
e98c e9aaad
e98d e9aab0
e98e e9aabc
e98f e9ab80
e990 e9ab8f
e991 e9ab91
e992 e9ab93
e993 e9ab94
e994 e9ab9e
e995 e9ab9f
e996 e9aba2
e997 e9aba3
e998 e9aba6
e999 e9abaf
e99a e9abab
e99b e9abae
e99c e9abb4
e99d e9abb1
e99e e9abb7
e99f e9abbb
e9a0 e9ac86
e9a1 e9ac98
e9a2 e9ac9a
e9a3 e9ac9f
e9a4 e9aca2
e9a5 e9aca3
e9a6 e9aca5
e9a7 e9aca7
e9a8 e9aca8
e9a9 e9aca9
e9aa e9acaa
e9ab e9acae
e9ac e9acaf
e9ad e9acb2
e9ae e9ad84
e9af e9ad83
e9b0 e9ad8f
e9b1 e9ad8d
e9b2 e9ad8e
e9b3 e9ad91
e9b4 e9ad98
e9b5 e9adb4
e9b6 e9ae93
e9b7 e9ae83
e9b8 e9ae91
e9b9 e9ae96
e9ba e9ae97
e9bb e9ae9f
e9bc e9aea0
e9bd e9aea8
e9be e9aeb4
e9bf e9af80
e9c0 e9af8a
e9c1 e9aeb9
e9c2 e9af86
e9c3 e9af8f
e9c4 e9af91
e9c5 e9af92
e9c6 e9afa3
e9c7 e9afa2
e9c8 e9afa4
e9c9 e9af94
e9ca e9afa1
e9cb e9b0ba
e9cc e9afb2
e9cd e9afb1
e9ce e9afb0
e9cf e9b095
e9d0 e9b094
e9d1 e9b089
e9d2 e9b093
e9d3 e9b08c
e9d4 e9b086
e9d5 e9b088
e9d6 e9b092
e9d7 e9b08a
e9d8 e9b084
e9d9 e9b0ae
e9da e9b09b
e9db e9b0a5
e9dc e9b0a4
e9dd e9b0a1
e9de e9b0b0
e9df e9b187
e9e0 e9b0b2
e9e1 e9b186
e9e2 e9b0be
e9e3 e9b19a
e9e4 e9b1a0
e9e5 e9b1a7
e9e6 e9b1b6
e9e7 e9b1b8
e9e8 e9b3a7
e9e9 e9b3ac
e9ea e9b3b0
e9eb e9b489
e9ec e9b488
e9ed e9b3ab
e9ee e9b483
e9ef e9b486
e9f0 e9b4aa
e9f1 e9b4a6
e9f2 e9b6af
e9f3 e9b4a3
e9f4 e9b49f
e9f5 e9b584
e9f6 e9b495
e9f7 e9b492
e9f8 e9b581
e9f9 e9b4bf
e9fa e9b4be
e9fb e9b586
e9fc e9b588
ea40 e9b59d
ea41 e9b59e
ea42 e9b5a4
ea43 e9b591
ea44 e9b590
ea45 e9b599
ea46 e9b5b2
ea47 e9b689
ea48 e9b687
ea49 e9b6ab
ea4a e9b5af
ea4b e9b5ba
ea4c e9b69a
ea4d e9b6a4
ea4e e9b6a9
ea4f e9b6b2
ea50 e9b784
ea51 e9b781
ea52 e9b6bb
ea53 e9b6b8
ea54 e9b6ba
ea55 e9b786
ea56 e9b78f
ea57 e9b782
ea58 e9b799
ea59 e9b793
ea5a e9b7b8
ea5b e9b7a6
ea5c e9b7ad
ea5d e9b7af
ea5e e9b7bd
ea5f e9b89a
ea60 e9b89b
ea61 e9b89e
ea62 e9b9b5
ea63 e9b9b9
ea64 e9b9bd
ea65 e9ba81
ea66 e9ba88
ea67 e9ba8b
ea68 e9ba8c
ea69 e9ba92
ea6a e9ba95
ea6b e9ba91
ea6c e9ba9d
ea6d e9baa5
ea6e e9baa9
ea6f e9bab8
ea70 e9baaa
ea71 e9baad
ea72 e99da1
ea73 e9bb8c
ea74 e9bb8e
ea75 e9bb8f
ea76 e9bb90
ea77 e9bb94
ea78 e9bb9c
ea79 e9bb9e
ea7a e9bb9d
ea7b e9bba0
ea7c e9bba5
ea7d e9bba8
ea7e e9bbaf
ea80 e9bbb4
ea81 e9bbb6
ea82 e9bbb7
ea83 e9bbb9
ea84 e9bbbb
ea85 e9bbbc
ea86 e9bbbd
ea87 e9bc87
ea88 e9bc88
ea89 e79ab7
ea8a e9bc95
ea8b e9bca1
ea8c e9bcac
ea8d e9bcbe
ea8e e9bd8a
ea8f e9bd92
ea90 e9bd94
ea91 e9bda3
ea92 e9bd9f
ea93 e9bda0
ea94 e9bda1
ea95 e9bda6
ea96 e9bda7
ea97 e9bdac
ea98 e9bdaa
ea99 e9bdb7
ea9a e9bdb2
ea9b e9bdb6
ea9c e9be95
ea9d e9be9c
ea9e e9bea0
ea9f e5a0af
eaa0 e6a787
eaa1 e98199
eaa2 e791a4
eaa3 e5879c
eaa4 e78699
ed40 e7ba8a
ed41 e8a49c
ed42 e98d88
ed43 e98a88
ed44 e8939c
ed45 e4bf89
ed46 e782bb
ed47 e698b1
ed48 e6a388
ed49 e98bb9
ed4a e69bbb
ed4b e5bd85
ed4c e4b8a8
ed4d e4bba1
ed4e e4bbbc
ed4f e4bc80
ed50 e4bc83
ed51 e4bcb9
ed52 e4bd96
ed53 e4be92
ed54 e4be8a
ed55 e4be9a
ed56 e4be94
ed57 e4bf8d
ed58 e58180
ed59 e580a2
ed5a e4bfbf
ed5b e5809e
ed5c e58186
ed5d e581b0
ed5e e58182
ed5f e58294
ed60 e583b4
ed61 e58398
ed62 e5858a
ed63 e585a4
ed64 e5869d
ed65 e586be
ed66 e587ac
ed67 e58895
ed68 e58a9c
ed69 e58aa6
ed6a e58b80
ed6b e58b9b
ed6c e58c80
ed6d e58c87
ed6e e58ca4
ed6f e58db2
ed70 e58e93
ed71 e58eb2
ed72 e58f9d
ed73 efa88e
ed74 e5929c
ed75 e5928a
ed76 e592a9
ed77 e593bf
ed78 e59686
ed79 e59d99
ed7a e59da5
ed7b e59eac
ed7c e59f88
ed7d e59f87
ed7e efa88f
ed80 efa890
ed81 e5a29e
ed82 e5a2b2
ed83 e5a48b
ed84 e5a593
ed85 e5a59b
ed86 e5a59d
ed87 e5a5a3
ed88 e5a6a4
ed89 e5a6ba
ed8a e5ad96
ed8b e5af80
ed8c e794af
ed8d e5af98
ed8e e5afac
ed8f e5b09e
ed90 e5b2a6
ed91 e5b2ba
ed92 e5b3b5
ed93 e5b4a7
ed94 e5b593
ed95 efa891
ed96 e5b582
ed97 e5b5ad
ed98 e5b6b8
ed99 e5b6b9
ed9a e5b790
ed9b e5bca1
ed9c e5bcb4
ed9d e5bda7
ed9e e5beb7
ed9f e5bf9e
eda0 e6819d
eda1 e68285
eda2 e6828a
eda3 e6839e
eda4 e68395
eda5 e684a0
eda6 e683b2
eda7 e68491
eda8 e684b7
eda9 e684b0
edaa e68698
edab e68893
edac e68aa6
edad e68fb5
edae e691a0
edaf e6929d
edb0 e6938e
edb1 e6958e
edb2 e69880
edb3 e69895
edb4 e698bb
edb5 e69889
edb6 e698ae
edb7 e6989e
edb8 e698a4
edb9 e699a5
edba e69997
edbb e69999
edbc efa892
edbd e699b3
edbe e69a99
edbf e69aa0
edc0 e69ab2
edc1 e69abf
edc2 e69bba
edc3 e69c8e
edc4 efa4a9
edc5 e69da6
edc6 e69ebb
edc7 e6a192
edc8 e69f80
edc9 e6a081
edca e6a184
edcb e6a38f
edcc efa893
edcd e6a5a8
edce efa894
edcf e6a698
edd0 e6a7a2
edd1 e6a8b0
edd2 e6a9ab
edd3 e6a986
edd4 e6a9b3
edd5 e6a9be
edd6 e6aba2
edd7 e6aba4
edd8 e6af96
edd9 e6b0bf
edda e6b19c
eddb e6b286
eddc e6b1af
eddd e6b39a
edde e6b484
eddf e6b687
ede0 e6b5af
ede1 e6b696
ede2 e6b6ac
ede3 e6b78f
ede4 e6b7b8
ede5 e6b7b2
ede6 e6b7bc
ede7 e6b8b9
ede8 e6b99c
ede9 e6b8a7
edea e6b8bc
edeb e6babf
edec e6be88
eded e6beb5
edee e6bfb5
edef e78085
edf0 e78087
edf1 e780a8
edf2 e78285
edf3 e782ab
edf4 e7848f
edf5 e78484
edf6 e7859c
edf7 e78586
edf8 e78587
edf9 efa895
edfa e78781
edfb e787be
edfc e78ab1
ee40 e78abe
ee41 e78ca4
ee42 efa896
ee43 e78db7
ee44 e78ebd
ee45 e78f89
ee46 e78f96
ee47 e78fa3
ee48 e78f92
ee49 e79087
ee4a e78fb5
ee4b e790a6
ee4c e790aa
ee4d e790a9
ee4e e790ae
ee4f e791a2
ee50 e79289
ee51 e7929f
ee52 e79481
ee53 e795af
ee54 e79a82
ee55 e79a9c
ee56 e79a9e
ee57 e79a9b
ee58 e79aa6
ee59 efa897
ee5a e79d86
ee5b e58aaf
ee5c e7a0a1
ee5d e7a18e
ee5e e7a1a4
ee5f e7a1ba
ee60 e7a4b0
ee61 efa898
ee62 efa899
ee63 efa89a
ee64 e7a694
ee65 efa89b
ee66 e7a69b
ee67 e7ab91
ee68 e7aba7
ee69 efa89c
ee6a e7abab
ee6b e7ae9e
ee6c efa89d
ee6d e7b588
ee6e e7b59c
ee6f e7b6b7
ee70 e7b6a0
ee71 e7b796
ee72 e7b992
ee73 e7bd87
ee74 e7bea1
ee75 efa89e
ee76 e88c81
ee77 e88da2
ee78 e88dbf
ee79 e88f87
ee7a e88fb6
ee7b e89188
ee7c e892b4
ee7d e89593
ee7e e89599
ee80 e895ab
ee81 efa89f
ee82 e896b0
ee83 efa8a0
ee84 efa8a1
ee85 e8a087
ee86 e8a3b5
ee87 e8a892
ee88 e8a8b7
ee89 e8a9b9
ee8a e8aaa7
ee8b e8aabe
ee8c e8ab9f
ee8d efa8a2
ee8e e8abb6
ee8f e8ad93
ee90 e8adbf
ee91 e8b3b0
ee92 e8b3b4
ee93 e8b492
ee94 e8b5b6
ee95 efa8a3
ee96 e8bb8f
ee97 efa8a4
ee98 efa8a5
ee99 e981a7
ee9a e9839e
ee9b efa8a6
ee9c e98495
ee9d e984a7
ee9e e9879a
ee9f e98797
eea0 e9879e
eea1 e987ad
eea2 e987ae
eea3 e987a4
eea4 e987a5
eea5 e98886
eea6 e98890
eea7 e9888a
eea8 e988ba
eea9 e98980
eeaa e988bc
eeab e9898e
eeac e98999
eead e98991
eeae e988b9
eeaf e989a7
eeb0 e98aa7
eeb1 e989b7
eeb2 e989b8
eeb3 e98ba7
eeb4 e98b97
eeb5 e98b99
eeb6 e98b90
eeb7 efa8a7
eeb8 e98b95
eeb9 e98ba0
eeba e98b93
eebb e98ca5
eebc e98ca1
eebd e98bbb
eebe efa8a8
eebf e98c9e
eec0 e98bbf
eec1 e98c9d
eec2 e98c82
eec3 e98db0
eec4 e98d97
eec5 e98ea4
eec6 e98f86
eec7 e98f9e
eec8 e98fb8
eec9 e990b1
eeca e99185
eecb e99188
eecc e99692
eecd efa79c
eece efa8a9
eecf e99a9d
eed0 e99aaf
eed1 e99cb3
eed2 e99cbb
eed3 e99d83
eed4 e99d8d
eed5 e99d8f
eed6 e99d91
eed7 e99d95
eed8 e9a197
eed9 e9a1a5
eeda efa8aa
eedb efa8ab
eedc e9a4a7
eedd efa8ac
eede e9a69e
eedf e9a98e
eee0 e9ab99
eee1 e9ab9c
eee2 e9adb5
eee3 e9adb2
eee4 e9ae8f
eee5 e9aeb1
eee6 e9aebb
eee7 e9b080
eee8 e9b5b0
eee9 e9b5ab
eeea efa8ad
eeeb e9b899
eeec e9bb91
eeef e285b0
eef0 e285b1
eef1 e285b2
eef2 e285b3
eef3 e285b4
eef4 e285b5
eef5 e285b6
eef6 e285b7
eef7 e285b8
eef8 e285b9
eef9 efbfa2
eefa efbfa4
eefb efbc87
eefc efbc82
fa40 e285b0
fa41 e285b1
fa42 e285b2
fa43 e285b3
fa44 e285b4
fa45 e285b5
fa46 e285b6
fa47 e285b7
fa48 e285b8
fa49 e285b9
fa4a e285a0
fa4b e285a1
fa4c e285a2
fa4d e285a3
fa4e e285a4
fa4f e285a5
fa50 e285a6
fa51 e285a7
fa52 e285a8
fa53 e285a9
fa54 efbfa2
fa55 efbfa4
fa56 efbc87
fa57 efbc82
fa58 e388b1
fa59 e28496
fa5a e284a1
fa5b e288b5
fa5c e7ba8a
fa5d e8a49c
fa5e e98d88
fa5f e98a88
fa60 e8939c
fa61 e4bf89
fa62 e782bb
fa63 e698b1
fa64 e6a388
fa65 e98bb9
fa66 e69bbb
fa67 e5bd85
fa68 e4b8a8
fa69 e4bba1
fa6a e4bbbc
fa6b e4bc80
fa6c e4bc83
fa6d e4bcb9
fa6e e4bd96
fa6f e4be92
fa70 e4be8a
fa71 e4be9a
fa72 e4be94
fa73 e4bf8d
fa74 e58180
fa75 e580a2
fa76 e4bfbf
fa77 e5809e
fa78 e58186
fa79 e581b0
fa7a e58182
fa7b e58294
fa7c e583b4
fa7d e58398
fa7e e5858a
fa80 e585a4
fa81 e5869d
fa82 e586be
fa83 e587ac
fa84 e58895
fa85 e58a9c
fa86 e58aa6
fa87 e58b80
fa88 e58b9b
fa89 e58c80
fa8a e58c87
fa8b e58ca4
fa8c e58db2
fa8d e58e93
fa8e e58eb2
fa8f e58f9d
fa90 efa88e
fa91 e5929c
fa92 e5928a
fa93 e592a9
fa94 e593bf
fa95 e59686
fa96 e59d99
fa97 e59da5
fa98 e59eac
fa99 e59f88
fa9a e59f87
fa9b efa88f
fa9c efa890
fa9d e5a29e
fa9e e5a2b2
fa9f e5a48b
faa0 e5a593
faa1 e5a59b
faa2 e5a59d
faa3 e5a5a3
faa4 e5a6a4
faa5 e5a6ba
faa6 e5ad96
faa7 e5af80
faa8 e794af
faa9 e5af98
faaa e5afac
faab e5b09e
faac e5b2a6
faad e5b2ba
faae e5b3b5
faaf e5b4a7
fab0 e5b593
fab1 efa891
fab2 e5b582
fab3 e5b5ad
fab4 e5b6b8
fab5 e5b6b9
fab6 e5b790
fab7 e5bca1
fab8 e5bcb4
fab9 e5bda7
faba e5beb7
fabb e5bf9e
fabc e6819d
fabd e68285
fabe e6828a
fabf e6839e
fac0 e68395
fac1 e684a0
fac2 e683b2
fac3 e68491
fac4 e684b7
fac5 e684b0
fac6 e68698
fac7 e68893
fac8 e68aa6
fac9 e68fb5
faca e691a0
facb e6929d
facc e6938e
facd e6958e
face e69880
facf e69895
fad0 e698bb
fad1 e69889
fad2 e698ae
fad3 e6989e
fad4 e698a4
fad5 e699a5
fad6 e69997
fad7 e69999
fad8 efa892
fad9 e699b3
fada e69a99
fadb e69aa0
fadc e69ab2
fadd e69abf
fade e69bba
fadf e69c8e
fae0 efa4a9
fae1 e69da6
fae2 e69ebb
fae3 e6a192
fae4 e69f80
fae5 e6a081
fae6 e6a184
fae7 e6a38f
fae8 efa893
fae9 e6a5a8
faea efa894
faeb e6a698
faec e6a7a2
faed e6a8b0
faee e6a9ab
faef e6a986
faf0 e6a9b3
faf1 e6a9be
faf2 e6aba2
faf3 e6aba4
faf4 e6af96
faf5 e6b0bf
faf6 e6b19c
faf7 e6b286
faf8 e6b1af
faf9 e6b39a
fafa e6b484
fafb e6b687
fafc e6b5af
fb40 e6b696
fb41 e6b6ac
fb42 e6b78f
fb43 e6b7b8
fb44 e6b7b2
fb45 e6b7bc
fb46 e6b8b9
fb47 e6b99c
fb48 e6b8a7
fb49 e6b8bc
fb4a e6babf
fb4b e6be88
fb4c e6beb5
fb4d e6bfb5
fb4e e78085
fb4f e78087
fb50 e780a8
fb51 e78285
fb52 e782ab
fb53 e7848f
fb54 e78484
fb55 e7859c
fb56 e78586
fb57 e78587
fb58 efa895
fb59 e78781
fb5a e787be
fb5b e78ab1
fb5c e78abe
fb5d e78ca4
fb5e efa896
fb5f e78db7
fb60 e78ebd
fb61 e78f89
fb62 e78f96
fb63 e78fa3
fb64 e78f92
fb65 e79087
fb66 e78fb5
fb67 e790a6
fb68 e790aa
fb69 e790a9
fb6a e790ae
fb6b e791a2
fb6c e79289
fb6d e7929f
fb6e e79481
fb6f e795af
fb70 e79a82
fb71 e79a9c
fb72 e79a9e
fb73 e79a9b
fb74 e79aa6
fb75 efa897
fb76 e79d86
fb77 e58aaf
fb78 e7a0a1
fb79 e7a18e
fb7a e7a1a4
fb7b e7a1ba
fb7c e7a4b0
fb7d efa898
fb7e efa899
fb80 efa89a
fb81 e7a694
fb82 efa89b
fb83 e7a69b
fb84 e7ab91
fb85 e7aba7
fb86 efa89c
fb87 e7abab
fb88 e7ae9e
fb89 efa89d
fb8a e7b588
fb8b e7b59c
fb8c e7b6b7
fb8d e7b6a0
fb8e e7b796
fb8f e7b992
fb90 e7bd87
fb91 e7bea1
fb92 efa89e
fb93 e88c81
fb94 e88da2
fb95 e88dbf
fb96 e88f87
fb97 e88fb6
fb98 e89188
fb99 e892b4
fb9a e89593
fb9b e89599
fb9c e895ab
fb9d efa89f
fb9e e896b0
fb9f efa8a0
fba0 efa8a1
fba1 e8a087
fba2 e8a3b5
fba3 e8a892
fba4 e8a8b7
fba5 e8a9b9
fba6 e8aaa7
fba7 e8aabe
fba8 e8ab9f
fba9 efa8a2
fbaa e8abb6
fbab e8ad93
fbac e8adbf
fbad e8b3b0
fbae e8b3b4
fbaf e8b492
fbb0 e8b5b6
fbb1 efa8a3
fbb2 e8bb8f
fbb3 efa8a4
fbb4 efa8a5
fbb5 e981a7
fbb6 e9839e
fbb7 efa8a6
fbb8 e98495
fbb9 e984a7
fbba e9879a
fbbb e98797
fbbc e9879e
fbbd e987ad
fbbe e987ae
fbbf e987a4
fbc0 e987a5
fbc1 e98886
fbc2 e98890
fbc3 e9888a
fbc4 e988ba
fbc5 e98980
fbc6 e988bc
fbc7 e9898e
fbc8 e98999
fbc9 e98991
fbca e988b9
fbcb e989a7
fbcc e98aa7
fbcd e989b7
fbce e989b8
fbcf e98ba7
fbd0 e98b97
fbd1 e98b99
fbd2 e98b90
fbd3 efa8a7
fbd4 e98b95
fbd5 e98ba0
fbd6 e98b93
fbd7 e98ca5
fbd8 e98ca1
fbd9 e98bbb
fbda efa8a8
fbdb e98c9e
fbdc e98bbf
fbdd e98c9d
fbde e98c82
fbdf e98db0
fbe0 e98d97
fbe1 e98ea4
fbe2 e98f86
fbe3 e98f9e
fbe4 e98fb8
fbe5 e990b1
fbe6 e99185
fbe7 e99188
fbe8 e99692
fbe9 efa79c
fbea efa8a9
fbeb e99a9d
fbec e99aaf
fbed e99cb3
fbee e99cbb
fbef e99d83
fbf0 e99d8d
fbf1 e99d8f
fbf2 e99d91
fbf3 e99d95
fbf4 e9a197
fbf5 e9a1a5
fbf6 efa8aa
fbf7 efa8ab
fbf8 e9a4a7
fbf9 efa8ac
fbfa e9a69e
fbfb e9a98e
fbfc e9ab99
fc40 e9ab9c
fc41 e9adb5
fc42 e9adb2
fc43 e9ae8f
fc44 e9aeb1
fc45 e9aebb
fc46 e9b080
fc47 e9b5b0
fc48 e9b5ab
fc49 efa8ad
fc4a e9b899
fc4b e9bb91
END

    if ( scalar(keys %sjis2utf8_2) != 4152 ) {
        die "scalar(keys %sjis2utf8_2) is ", scalar(keys %sjis2utf8_2), ".";
    }
}

#---------------------------------------------------------------------
sub init_utf82sjis {
    &init_sjis2utf8 unless %sjis2utf8_1;
    %utf82sjis_1 = reverse %sjis2utf8_1;
    %utf82sjis_2 = reverse %sjis2utf8_2;

    # JP170559 CodePage 932 : 398 non-round-trip mappings
    # http://support.microsoft.com/kb/170559/ja

    %JP170559 = split( /\s+/, <<'END' );
e28992 81e0
e289a1 81df
e288ab 81e7
e2889a 81e3
e28aa5 81db
e288a0 81da
e288b5 81e6
e288a9 81bf
e288aa 81be
e7ba8a fa5c
e8a49c fa5d
e98d88 fa5e
e98a88 fa5f
e8939c fa60
e4bf89 fa61
e782bb fa62
e698b1 fa63
e6a388 fa64
e98bb9 fa65
e69bbb fa66
e5bd85 fa67
e4b8a8 fa68
e4bba1 fa69
e4bbbc fa6a
e4bc80 fa6b
e4bc83 fa6c
e4bcb9 fa6d
e4bd96 fa6e
e4be92 fa6f
e4be8a fa70
e4be9a fa71
e4be94 fa72
e4bf8d fa73
e58180 fa74
e580a2 fa75
e4bfbf fa76
e5809e fa77
e58186 fa78
e581b0 fa79
e58182 fa7a
e58294 fa7b
e583b4 fa7c
e58398 fa7d
e5858a fa7e
e585a4 fa80
e5869d fa81
e586be fa82
e587ac fa83
e58895 fa84
e58a9c fa85
e58aa6 fa86
e58b80 fa87
e58b9b fa88
e58c80 fa89
e58c87 fa8a
e58ca4 fa8b
e58db2 fa8c
e58e93 fa8d
e58eb2 fa8e
e58f9d fa8f
efa88e fa90
e5929c fa91
e5928a fa92
e592a9 fa93
e593bf fa94
e59686 fa95
e59d99 fa96
e59da5 fa97
e59eac fa98
e59f88 fa99
e59f87 fa9a
efa88f fa9b
efa890 fa9c
e5a29e fa9d
e5a2b2 fa9e
e5a48b fa9f
e5a593 faa0
e5a59b faa1
e5a59d faa2
e5a5a3 faa3
e5a6a4 faa4
e5a6ba faa5
e5ad96 faa6
e5af80 faa7
e794af faa8
e5af98 faa9
e5afac faaa
e5b09e faab
e5b2a6 faac
e5b2ba faad
e5b3b5 faae
e5b4a7 faaf
e5b593 fab0
efa891 fab1
e5b582 fab2
e5b5ad fab3
e5b6b8 fab4
e5b6b9 fab5
e5b790 fab6
e5bca1 fab7
e5bcb4 fab8
e5bda7 fab9
e5beb7 faba
e5bf9e fabb
e6819d fabc
e68285 fabd
e6828a fabe
e6839e fabf
e68395 fac0
e684a0 fac1
e683b2 fac2
e68491 fac3
e684b7 fac4
e684b0 fac5
e68698 fac6
e68893 fac7
e68aa6 fac8
e68fb5 fac9
e691a0 faca
e6929d facb
e6938e facc
e6958e facd
e69880 face
e69895 facf
e698bb fad0
e69889 fad1
e698ae fad2
e6989e fad3
e698a4 fad4
e699a5 fad5
e69997 fad6
e69999 fad7
efa892 fad8
e699b3 fad9
e69a99 fada
e69aa0 fadb
e69ab2 fadc
e69abf fadd
e69bba fade
e69c8e fadf
efa4a9 fae0
e69da6 fae1
e69ebb fae2
e6a192 fae3
e69f80 fae4
e6a081 fae5
e6a184 fae6
e6a38f fae7
efa893 fae8
e6a5a8 fae9
efa894 faea
e6a698 faeb
e6a7a2 faec
e6a8b0 faed
e6a9ab faee
e6a986 faef
e6a9b3 faf0
e6a9be faf1
e6aba2 faf2
e6aba4 faf3
e6af96 faf4
e6b0bf faf5
e6b19c faf6
e6b286 faf7
e6b1af faf8
e6b39a faf9
e6b484 fafa
e6b687 fafb
e6b5af fafc
e6b696 fb40
e6b6ac fb41
e6b78f fb42
e6b7b8 fb43
e6b7b2 fb44
e6b7bc fb45
e6b8b9 fb46
e6b99c fb47
e6b8a7 fb48
e6b8bc fb49
e6babf fb4a
e6be88 fb4b
e6beb5 fb4c
e6bfb5 fb4d
e78085 fb4e
e78087 fb4f
e780a8 fb50
e78285 fb51
e782ab fb52
e7848f fb53
e78484 fb54
e7859c fb55
e78586 fb56
e78587 fb57
efa895 fb58
e78781 fb59
e787be fb5a
e78ab1 fb5b
e78abe fb5c
e78ca4 fb5d
efa896 fb5e
e78db7 fb5f
e78ebd fb60
e78f89 fb61
e78f96 fb62
e78fa3 fb63
e78f92 fb64
e79087 fb65
e78fb5 fb66
e790a6 fb67
e790aa fb68
e790a9 fb69
e790ae fb6a
e791a2 fb6b
e79289 fb6c
e7929f fb6d
e79481 fb6e
e795af fb6f
e79a82 fb70
e79a9c fb71
e79a9e fb72
e79a9b fb73
e79aa6 fb74
efa897 fb75
e79d86 fb76
e58aaf fb77
e7a0a1 fb78
e7a18e fb79
e7a1a4 fb7a
e7a1ba fb7b
e7a4b0 fb7c
efa898 fb7d
efa899 fb7e
efa89a fb80
e7a694 fb81
efa89b fb82
e7a69b fb83
e7ab91 fb84
e7aba7 fb85
efa89c fb86
e7abab fb87
e7ae9e fb88
efa89d fb89
e7b588 fb8a
e7b59c fb8b
e7b6b7 fb8c
e7b6a0 fb8d
e7b796 fb8e
e7b992 fb8f
e7bd87 fb90
e7bea1 fb91
efa89e fb92
e88c81 fb93
e88da2 fb94
e88dbf fb95
e88f87 fb96
e88fb6 fb97
e89188 fb98
e892b4 fb99
e89593 fb9a
e89599 fb9b
e895ab fb9c
efa89f fb9d
e896b0 fb9e
efa8a0 fb9f
efa8a1 fba0
e8a087 fba1
e8a3b5 fba2
e8a892 fba3
e8a8b7 fba4
e8a9b9 fba5
e8aaa7 fba6
e8aabe fba7
e8ab9f fba8
efa8a2 fba9
e8abb6 fbaa
e8ad93 fbab
e8adbf fbac
e8b3b0 fbad
e8b3b4 fbae
e8b492 fbaf
e8b5b6 fbb0
efa8a3 fbb1
e8bb8f fbb2
efa8a4 fbb3
efa8a5 fbb4
e981a7 fbb5
e9839e fbb6
efa8a6 fbb7
e98495 fbb8
e984a7 fbb9
e9879a fbba
e98797 fbbb
e9879e fbbc
e987ad fbbd
e987ae fbbe
e987a4 fbbf
e987a5 fbc0
e98886 fbc1
e98890 fbc2
e9888a fbc3
e988ba fbc4
e98980 fbc5
e988bc fbc6
e9898e fbc7
e98999 fbc8
e98991 fbc9
e988b9 fbca
e989a7 fbcb
e98aa7 fbcc
e989b7 fbcd
e989b8 fbce
e98ba7 fbcf
e98b97 fbd0
e98b99 fbd1
e98b90 fbd2
efa8a7 fbd3
e98b95 fbd4
e98ba0 fbd5
e98b93 fbd6
e98ca5 fbd7
e98ca1 fbd8
e98bbb fbd9
efa8a8 fbda
e98c9e fbdb
e98bbf fbdc
e98c9d fbdd
e98c82 fbde
e98db0 fbdf
e98d97 fbe0
e98ea4 fbe1
e98f86 fbe2
e98f9e fbe3
e98fb8 fbe4
e990b1 fbe5
e99185 fbe6
e99188 fbe7
e99692 fbe8
efa79c fbe9
efa8a9 fbea
e99a9d fbeb
e99aaf fbec
e99cb3 fbed
e99cbb fbee
e99d83 fbef
e99d8d fbf0
e99d8f fbf1
e99d91 fbf2
e99d95 fbf3
e9a197 fbf4
e9a1a5 fbf5
efa8aa fbf6
efa8ab fbf7
e9a4a7 fbf8
efa8ac fbf9
e9a69e fbfa
e9a98e fbfb
e9ab99 fbfc
e9ab9c fc40
e9adb5 fc41
e9adb2 fc42
e9ae8f fc43
e9aeb1 fc44
e9aebb fc45
e9b080 fc46
e9b5b0 fc47
e9b5ab fc48
efa8ad fc49
e9b899 fc4a
e9bb91 fc4b
e285b0 fa40
e285b1 fa41
e285b2 fa42
e285b3 fa43
e285b4 fa44
e285b5 fa45
e285b6 fa46
e285b7 fa47
e285b8 fa48
e285b9 fa49
efbfa2 81ca
efbfa4 fa55
efbc87 fa56
efbc82 fa57
e285a0 8754
e285a1 8755
e285a2 8756
e285a3 8757
e285a4 8758
e285a5 8759
e285a6 875a
e285a7 875b
e285a8 875c
e285a9 875d
efbfa2 81ca
e388b1 878a
e28496 8782
e284a1 8784
e288b5 81e6
END

    if ( scalar(keys %JP170559) != 396 ) {
        die "scalar(keys %JP170559) is ", scalar(keys %JP170559), ".";
    }
}

%kana2utf8 = split( /\s+/, <<'END' );
a1 efbda1
a2 efbda2
a3 efbda3
a4 efbda4
a5 efbda5
a6 efbda6
a7 efbda7
a8 efbda8
a9 efbda9
aa efbdaa
ab efbdab
ac efbdac
ad efbdad
ae efbdae
af efbdaf
b0 efbdb0
b1 efbdb1
b2 efbdb2
b3 efbdb3
b4 efbdb4
b5 efbdb5
b6 efbdb6
b7 efbdb7
b8 efbdb8
b9 efbdb9
ba efbdba
bb efbdbb
bc efbdbc
bd efbdbd
be efbdbe
bf efbdbf
c0 efbe80
c1 efbe81
c2 efbe82
c3 efbe83
c4 efbe84
c5 efbe85
c6 efbe86
c7 efbe87
c8 efbe88
c9 efbe89
ca efbe8a
cb efbe8b
cc efbe8c
cd efbe8d
ce efbe8e
cf efbe8f
d0 efbe90
d1 efbe91
d2 efbe92
d3 efbe93
d4 efbe94
d5 efbe95
d6 efbe96
d7 efbe97
d8 efbe98
d9 efbe99
da efbe9a
db efbe9b
dc efbe9c
dd efbe9d
de efbe9e
df efbe9f
END

if ( scalar(keys %kana2utf8) != 63 ) {
    die "scalar(keys %kana2utf8) is ", scalar(keys %kana2utf8), ".";
}

#---------------------------------------------------------------------
sub init_k2u {
    if (%u2k) {
        %k2u = reverse %u2k;
        if ( scalar( keys %k2u ) != scalar( keys %u2k ) ) {
            die "scalar(keys %k2u) != scalar(keys %u2k).";
        }
    }
    else {
        local ( $k, $u );
        while ( ( $k, $u ) = each %kana2utf8 ) {
            $k2u{ pack( 'H*', $k ) } = pack( 'H*', $u );
        }
    }
}

#---------------------------------------------------------------------
sub init_u2k {
    if (%k2u) {
        %u2k = reverse %k2u;
        if ( scalar( keys %u2k ) != scalar( keys %k2u ) ) {
            die "scalar(keys %u2k) != scalar(keys %k2u).";
        }
    }
    else {
        local ( $k, $u );
        while ( ( $k, $u ) = each %kana2utf8 ) {
            $u2k{ pack( 'H*', $u ) } = pack( 'H*', $k );
        }
    }
}

#---------------------------------------------------------------------
# TR function for 2-byte code
#---------------------------------------------------------------------
sub tr {

    # $prev_from, $prev_to, %table are persistent variables
    local ( *s, $from, $to, $option ) = @_;
    local ( @from, @to );
    local ( $jis, $n ) = ( 0, 0 );

# fixing bug of jcode.pl (2 of 2)
# mis-caching table
# http://srekcah.org/jcode/2.13.1/
#
#! ;; $rcsid = q$Id: jcode.pl,v 2.13.1.4 2002/04/07 07:27:00 utashiro Exp $;
# *** 727,734 ****
#   $jis++, &jis2euc(*s) if $s =~ /$re_jp|$re_asc|$re_kana/o;
#   $jis++ if $to =~ /$re_jp|$re_asc|$re_kana/o;
#
#!  if (!defined($prev_from) || $from ne $prev_from || $to ne $prev_to) {
#!      ($prev_from, $prev_to) = ($from, $to);
#       undef %table;
#       &_maketable;
#   }
# --- 727,735 ----
#   $jis++, &jis2euc(*s) if $s =~ /$re_jp|$re_asc|$re_kana/o;
#   $jis++ if $to =~ /$re_jp|$re_asc|$re_kana/o;
#
#!  if (!defined($prev_from) ||
#!      $from ne $prev_from || $to ne $prev_to || $opt ne $prev_opt) {
#!      ($prev_from, $prev_to, $prev_opt) = ($from, $to, $opt);
#       undef %table;
#       &_maketable;
#   }

# jcodeg.diff by Gappai
# http://www.vector.co.jp/soft/win95/prog/se347514.html

    $jis++, &jis2euc(*s) if $s =~ /$re_esc_jp|$re_esc_asc|$re_esc_kana/o;
    $jis++ if $to =~ /$re_esc_jp|$re_esc_asc|$re_esc_kana/o;

    if (   !defined($prev_from)
        || $from   ne $prev_from
        || $to     ne $prev_to
        || $option ne $prev_opt )
    {
        ( $prev_from, $prev_to, $prev_opt ) = ( $from, $to, $option );
        undef %table;
        &_maketable;
    }

    $s =~ s/([\x80-\xff][\x00-\xff]|[\x00-\xff])/
    defined($table{$1}) && ++$n ? $table{$1} : $1
    /ge;

    &euc2jis(*s) if $jis;

    $n;
}

#---------------------------------------------------------------------
sub _maketable {
    local ($ascii) = '(\\\\[\\-\\\\]|[\0-\x5b\x5d-\x7f])';

    &jis2euc(*to)   if $to   =~ /$re_esc_jp|$re_esc_asc|$re_esc_kana/o;
    &jis2euc(*from) if $from =~ /$re_esc_jp|$re_esc_asc|$re_esc_kana/o;

    grep( s/(([\x80-\xff])[\x80-\xff]-\2[\x80-\xff])/&_expnd2($1)/ge,
        $from, $to );
    grep( s/($ascii-$ascii)/&_expnd1($1)/geo, $from, $to );

    @to   = $to   =~ /[\x80-\xff][\x00-\xff]|[\x00-\xff]/g;
    @from = $from =~ /[\x80-\xff][\x00-\xff]|[\x00-\xff]/g;
    push( @to, ( $option =~ /d/ ? '' : $to[$#to] ) x ( @from - @to ) )
      if @to < @from;
    @table{@from} = @to;
}

#---------------------------------------------------------------------
sub _expnd1 {
    local ($s) = @_;
    $s =~ s/\\([\x00-\xff])/$1/g;
    local ( $c1, $c2 ) = unpack( 'CxC', $s );
    if ( $c1 <= $c2 ) {
        for ( $s = '' ; $c1 <= $c2 ; $c1++ ) {
            $s .= pack( 'C', $c1 );
        }
    }
    $s;
}

#---------------------------------------------------------------------
sub _expnd2 {
    local ($s) = @_;
    local ( $c1, $c2, $c3, $c4 ) = unpack( 'CCxCC', $s );
    if ( $c1 == $c3 && $c2 <= $c4 ) {
        for ( $s = '' ; $c2 <= $c4 ; $c2++ ) {
            $s .= pack( 'CC', $c1, $c2 );
        }
    }
    $s;
}

1;

__END__

=pod

=head1 NAME

jacode - Perl program for Japanese character code conversion

=head1 SYNOPSIS

    require 'jacode.pl';

    # note: You can use either of the package of 'jcode' and 'jacode'

    jacode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])
    jacode::xxx2yyy(\$line [, $option])
    jacode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])
    jacode::jis($line [, $INPUT_encoding [, $option]])
    jacode::euc($line [, $INPUT_encoding [, $option]])
    jacode::sjis($line [, $INPUT_encoding [, $option]])
    jacode::utf8($line [, $INPUT_encoding [, $option]])
    jacode::jis_inout($JIS_Kanji_IN, $ASCII_IN)
    jacode::get_inout($line)
    jacode::h2z_xxx(\$line)
    jacode::z2h_xxx(\$line)
    jacode::getcode(\$line)
    jacode::init()

    # Perl4 INTERFACE for jcode.pl users

    &jcode'getcode_utashiro_2000_09_29(*line)
    &jcode'getcode(*line)
    &jcode'convert(*line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])
    &jcode'xxx2yyy(*line [, $option])
    &jcode'to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])
    &jcode'jis($line [, $INPUT_encoding [, $option]])
    &jcode'euc($line [, $INPUT_encoding [, $option]])
    &jcode'sjis($line [, $INPUT_encoding [, $option]])
    &jcode'utf8($line [, $INPUT_encoding [, $option]])
    &jcode'jis_inout($JIS_Kanji_IN, $ASCII_IN)
    &jcode'get_inout($line)
    &jcode'cache()
    &jcode'nocache()
    &jcode'flushcache()
    &jcode'flush()
    &jcode'h2z_xxx(*line)
    &jcode'z2h_xxx(*line)
    &jcode'tr(*line, $from, $to [, $option])
    &jcode'trans($line, $from, $to [, $option])
    &jcode'init()

    $jcode'convf{'xxx', 'yyy'}
    $jcode'z2hf{'xxx'}
    $jcode'h2zf{'xxx'}

    # Perl5 INTERFACE for jcode.pl users

    jcode::getcode_utashiro_2000_09_29(\$line)
    jcode::getcode(\$line)
    jcode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])
    jcode::xxx2yyy(\$line [, $option])
    jcode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])
    jcode::jis($line [, $INPUT_encoding [, $option]])
    jcode::euc($line [, $INPUT_encoding [, $option]])
    jcode::sjis($line [, $INPUT_encoding [, $option]])
    jcode::utf8($line [, $INPUT_encoding [, $option]])
    jcode::jis_inout($JIS_Kanji_IN, $ASCII_IN)
    jcode::get_inout($line)
    jcode::cache()
    jcode::nocache()
    jcode::flushcache()
    jcode::flush()
    jcode::h2z_xxx(\$line)
    jcode::z2h_xxx(\$line)
    jcode::tr(\$line, $from, $to [, $option])
    jcode::trans($line, $from, $to [, $option])
    jcode::init()

    &{$jcode::convf{'xxx', 'yyy'}}(\$line)
    &{$jcode::z2hf{'xxx'}}(\$line)
    &{$jcode::h2zf{'xxx'}}(\$line)

=head1 ABSTRACT

This software has upper compatibility to jcode.pl and multiple
inheritance both stable jcode.pl library and active Encode module.

'Ja' is a meaning of 'Japanese' in ISO 639-1 code and is unrelated
to 'JA Group Organization'.

The code conversion from 'sjis' to 'utf8' is done by using following
table.

L<http://unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP932.TXT>

From 'utf8' to 'sjis' is done by using the CP932.TXT and following
table.

PRB: Conversion Problem Between Shift-JIS and Unicode

L<http://support.microsoft.com/kb/170559/en-us>

What's this software good for ...

=over 2

=item * jcode.pl upper compatible

=item * pkf command upper compatible

=item * Perl4 script also Perl5 script

=item * Powered by Encode::from_to (Yes, not only Japanese!)

=item * Support HALFWIDTH KATAKANA

=item * Support UTF-8

=item * Hidden UTF8 flag

=item * No object-oriented programming

=item * Possible to re-use past code and how to

=back

=head1 DEPENDENCIES

This software requires perl 4.036 or later.

=head1 INTERFACE for newcomers

=over 2

=item jacode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])

  Convert the contents of $line to the specified Japanese
  encoding given in the second argument $OUTPUT_encoding.
  $OUTPUT_encoding can be any of "jis", "sjis", "euc" or "utf8",
  or use "noconv" when you don't want the encoding conversion.
  
  Input encoding is recognized semi-automatically from the
  $line itself when $INPUT_encoding is not supplied. It is
  better to specify $INPUT_encoding, since jacode::getcode's
  guess is not always right. xxx2yyy routine is more efficient
  when both codes are known.
  
  It returns the encoding of input string in scalar context,
  and a list of pointer of convert subroutine and the
  input encoding in array context.
  
  Japanese character encoding JIS X0201, X0208, X0212 and
  ASCII code are supported.  JIS X0212 characters can not
  be represented in sjis or utf8 and they will be replased
  by "geta" character when converted to sjis.
  JIS X0213 characters can not be represented in all.
  
  For perl is 5.8.1 or later, jacode::convert acts as a wrapper
  to Encode::from_to. When $OUTPUT_encoding or $INPUT_encoding
  is neither "jis", "sjis", "euc" nor "utf8", and Encode module
  can be used,
  
  Encode::from_to( $line, $INPUT_encoding, $OUTPUT_encoding )
  
  is executed instead of
 
  jacode::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, $option).
 
  In this case, there is no effective return value of pointer
  of convert subroutine in array context.
  
  Fourth $option parameter is just forwarded to conversion
  routine. See next paragraph for detail.

=item jacode::xxx2yyy(\$line [, $option])

  Convert the Japanese code from xxx to yyy.  String xxx
  and yyy are any convination from "jis", "euc", "sjis"
  or "utf8". They return *approximate* number of converted
  bytes.  So return value 0 means the line was not
  converted at all.
  
  Optional parameter $option is used to specify optional
  conversion method.  String "z" is for JIS X0201 KANA
  to JIS X0208 KANA, and "h" is for reverse.

=item jacode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])

=item jacode::jis($line [, $INPUT_encoding [, $option]])

=item jacode::euc($line [, $INPUT_encoding [, $option]])

=item jacode::sjis($line [, $INPUT_encoding [, $option]])

=item jacode::utf8($line [, $INPUT_encoding [, $option]])

  These functions are prepared for easy use of
  call/return-by-value interface.  You can use these
  funcitons in s///e operation or any other place for
  convenience.

=item jacode::jis_inout($JIS_Kanji_IN, $ASCII_IN)

  Set or inquire JIS Kanji start and ASCII start sequences.
  Default is "ESC-$-B" and "ESC-(-B".  "ASCII start" is used
  instead of "JIS Kanji OUT".  If specified in the short form
  of one character, and is set by being converted into full
  sequence.

  -----------------------------------------------
  short  full sequence    means
  -----------------------------------------------
  @      ESC-$-@          JIS C 6226-1978
  B      ESC-$-B          JIS X 0208-1983
  &      ESC-&@-ESC-$-B   JIS X 0208-1990
  O      ESC-$-(-O        JIS X 0213:2000 plane1
  Q      ESC-$-(-Q        JIS X 0213:2004 plane1
  -----------------------------------------------

=item jacode::get_inout($line)

  Get JIS Kanji start and ASCII start sequences from $line.

=item jacode::h2z_xxx(\$line)

  JIS X0201 KANA (so-called Hankaku-KANA) to JIS X0208 KANA
  (Zenkaku-KANA) code conversion routine.  String xxx is
  any of "jis", "sjis", "euc" and "utf8".  From the difficulty
  of recognizing code set from 1-byte KATAKANA string,
  automatic code recognition is not supported.

=item jacode::z2h_xxx(\$line)

  JIS X0208 to JIS X0201 KANA code conversion routine.
  String xxx is any of "jis", "sjis", "euc" and "utf8".

=item jacode::getcode(\$line)

  Return 'jis', 'sjis', 'euc', 'utf8' or undef according
  to Japanese character code in $line.  Return 'binary' if
  the data has non-character code.
  
  When evaluated in array context, it returns a list
  contains two items.  First value is the number of
  characters which matched to the expected code, and
  second value is the code name.  It is useful if and
  only if the number is not 0 and the code is undef;
  that case means it couldn't tell 'euc' or 'sjis'
  because the evaluation score was exactly same.  This
  interface is too tricky, though.
  
  Code detection between euc and sjis is very difficult
  or sometimes impossible or even lead to wrong result
  when it includes JIS X0201 KANA characters.

=item jacode::init()

  Initialize the variables used in this package.  You
  don't have to call this when using jocde.pl by `do' or
  `require' interface.  Call it first if you embedded
  the jacode.pl at the end of your script.

=back

=head1 INTERFACE for backward compatibility

=over 2

=item jacode::getcode_utashiro_2000_09_29(\$line)

  Original &getcode() of jcode.pl.

=item jacode::cache()

=item jacode::nocache()

=item jacode::flushcache()

=item jacode::flush()

  Usually, converted character is cached in memory to
  avoid same calculations have to be done many times.
  To disable this caching, call jacode::nocache().  It
  can be revived by jacode::cache() and cache is flushed
  by calling jacode::flushcache().  jacode::cache() and
  jacode::nocache() functions return previous caching
  state. jacode::flush() is an alias of jacode::flushcache()
  to save old documents.

=item jacode::tr(\$line, $from, $to [, $option])

  jacode::tr emulates tr operator for 2 byte code.  Only 'd'
  is interpreted as an option.

  Range operator like `A-Z' for 2 byte code is partially
  supported.  Code must be JIS or EUC-JP, and first byte
  have to be same on first and last character.

  CAUTION: Handling range operator is a kind of trick
  and it is not perfect.  So if you need to transfer `-'
  character, please be sure to put it at the beginning
  or the end of $from and $to strings.

=item jacode::trans($line, $from, $to [, $option])

  Same as jacode::tr but accept string and return string
  after translation.

=item $jacode::convf{'xxx', 'yyy'}

  The value of this associative array is pointer to the
  subroutine jacode::xxx2yyy().

=item $jacode::z2hf{'xxx'}

=item $jacode::h2zf{'xxx'}

  These are pointer to the corresponding function just
  as $jacode::convf.

=back

=head1 PERL4 INTERFACE for jcode.pl users

=over 2

=item &jcode'getcode_utashiro_2000_09_29(*line)

=item &jcode'getcode(*line)

=item &jcode'convert(*line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])

=item &jcode'xxx2yyy(*line [, $option])

=item $jcode'convf{'xxx', 'yyy'}

=item &jcode'to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])

=item &jcode'jis($line [, $INPUT_encoding [, $option]])

=item &jcode'euc($line [, $INPUT_encoding [, $option]])

=item &jcode'sjis($line [, $INPUT_encoding [, $option]])

=item &jcode'utf8($line [, $INPUT_encoding [, $option]])

=item &jcode'jis_inout($JIS_Kanji_IN, $ASCII_IN)

=item &jcode'get_inout($line)

=item &jcode'cache()

=item &jcode'nocache()

=item &jcode'flushcache()

=item &jcode'flush()

=item &jcode'h2z_xxx(*line)

=item &jcode'z2h_xxx(*line)

=item $jcode'z2hf{'xxx'}

=item $jcode'h2zf{'xxx'}

=item &jcode'tr(*line, $from, $to [, $option])

=item &jcode'trans($line, $from, $to [, $option])

=item &jcode'init()

=back

=head1 PERL5 INTERFACE for jcode.pl users

Current jacode.pl is written in Perl 4 but it is possible to use
from Perl 5 using `references'.  Fully perl5 capable version is
future issue.

Since lexical variable is not a subject of typeglob, *string style
call doesn't work if the variable is declared as `my'.  Same thing
happens to special variable $_ if the perl is compiled to use
thread capability.  So using reference is generally recommented to
avoid the mysterious error.

=over 2

=item jcode::getcode_utashiro_2000_09_29(\$line)

=item jcode::getcode(\$line)

=item jcode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])

=item jcode::xxx2yyy(\$line [, $option])

=item &{$jcode::convf{'xxx', 'yyy'}}(\$line)

=item jcode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])

=item jcode::jis($line [, $INPUT_encoding [, $option]])

=item jcode::euc($line [, $INPUT_encoding [, $option]])

=item jcode::sjis($line [, $INPUT_encoding [, $option]])

=item jcode::utf8($line [, $INPUT_encoding [, $option]])

=item jcode::jis_inout($JIS_Kanji_IN, $ASCII_IN)

=item jcode::get_inout($line)

=item jcode::cache()

=item jcode::nocache()

=item jcode::flushcache()

=item jcode::flush()

=item jcode::h2z_xxx(\$line)

=item jcode::z2h_xxx(\$line)

=item &{$jcode::z2hf{'xxx'}}(\$line)

=item &{$jcode::h2zf{'xxx'}}(\$line)

=item jcode::tr(\$line, $from, $to [, $option])

=item jcode::trans($line, $from, $to [, $option])

=item jcode::init()

=back

=head1 SAMPLES

Convert SJIS to JIS and print each line with code name

  #require 'jcode.pl';
  require 'jacode.pl';
  while (defined($s = <>)) {
      $code = &jcode'convert(*s, 'jis', 'sjis');
      print $code, "\t", $s;
  }

Convert all lines to JIS according to the first recognized line

  #require 'jcode.pl';
  require 'jacode.pl';
  while (defined($s = <>)) {
      print, next unless $s =~ /[\x1b\x80-\xff]/;
      (*f, $INPUT_encoding) = &jcode'convert(*s, 'jis');
      print;
      defined(&f) || next;
      while (<>) { &f(*s); print; }
      last;
  }

The safest way of JIS conversion

  #require 'jcode.pl';
  require 'jacode.pl';
  while (defined($s = <>)) {
      ($matched, $INPUT_encoding) = &jcode'getcode(*s);
      if (@buf == 0 && $matched == 0) {
          print $s;
          next;
      }
      push(@buf, $s);
      next unless $INPUT_encoding;
      while (defined($s = shift(@buf))) {
          &jcode'convert(*s, 'jis', $INPUT_encoding);
          print $s;
      }
      while (defined($s = <>)) {
          &jcode'convert(*s, 'jis', $INPUT_encoding);
          print $s;
      }
      last;
  }
  print @buf if @buf;

Convert SJIS to UTF-8 and print each line by perl 4.036 or later

  #retire 'jcode.pl';
  require 'jacode.pl';
  while (defined($s = <>)) {
      &jcode'convert(*s, 'utf8', 'sjis');
      print $s;
  }

Convert SJIS to UTF16-BE and print each line by perl 5.8.1 or later

  require 'jacode.pl';
  use 5.8.1;
  while (defined($s = <>)) {
      jacode::convert(\$s, 'UTF16-BE', 'sjis');
      print $s;
  }

Convert SJIS to MIME-Header-ISO_2022_JP and print each line by perl 5.8.1 or later

  require 'jacode.pl';
  use 5.8.1;
  while (defined($s = <>)) {
      jacode::convert(\$s, 'MIME-Header-ISO_2022_JP', 'sjis');
      print $s;
  }

=head1 STYLES

Traditional style of file I/O

  require 'jacode.pl';
  open(FILE,'input.txt');
  while (<FILE>) {
      chomp;
      jacode::convert(\$_,'sjis','utf8');
      ...
  }

Minimalist style

  open(FILE,'perl jacode.pl -ws input.txt | ');

=head1 BUGS AND LIMITATIONS

You must use -Llatin switch if you use on the JPerl4.
You must use -b switch if you use on the JPerl5.

I have tested and verified this software using the best of my ability.
However, a software containing much code is bound to contain some bugs.
Thus, if you happen to find a bug that's in jacode.pl and not your own
program, you can try to reduce it to a minimal test case and then report
it to the following author's address. If you have an idea that could make
this a more useful tool, please let everyone share it.

=head1 SOFTWARE LIFE CYCLE

                                         Jacode.pm
                    jcode.pl  Encode.pm  jacode.pl  Jacode4e  Jacode4e::RoundTrip
  --------------------------------------------------------------------------------
  1993 Perl4.036       |                     |                                    
    :     :            :                     :                                    
  1999 Perl5.00503     |                     |         |               |          
  2000 Perl5.6         |                     |         |               |          
  2002 Perl5.8         |         Born        |         |               |          
  2007 Perl5.10        V          |          |         |               |          
  2010 Perl5.12       EOL         |         Born       |               |          
  2011 Perl5.14                   |          |         |               |          
  2012 Perl5.16                   |          |         |               |          
  2013 Perl5.18                   |          |         |               |          
  2014 Perl5.20                   |          |         |               |          
  2015 Perl5.22                   |          |         |               |          
  2016 Perl5.24                   |          |         |               |          
  2017 Perl5.26                   |          |         |               |          
  2018 Perl5.28                   |          |        Born            Born        
  2019 Perl5.30                   |          |         |               |          
  2020 Perl5.32                   :          :         :               :          
  2030 Perl5.52                   :          :         :               :          
  2040 Perl5.72                   :          :         :               :          
  2050 Perl5.92                   :          :         :               :          
  2060 Perl5.112                  :          :         :               :          
  2070 Perl5.132                  :          :         :               :          
  2080 Perl5.152                  :          :         :               :          
  2090 Perl5.172                  :          :         :               :          
  2100 Perl5.192                  :          :         :               :          
  2110 Perl5.212                  :          :         :               :          
  2120 Perl5.232                  :          :         :               :          
    :     :                       V          V         V               V          
  --------------------------------------------------------------------------------

=head1 SOFTWARE COVERAGE

When you lost your way, you can see this matrix and find your way.

  Skill/Use  Amateur    Semipro    Pro        Enterprise  Enterprise(round-trip)
  -------------------------------------------------------------------------------
  Expert     jacode.pl  Encode.pm  Encode.pm  Jacode4e    Jacode4e::RoundTrip
  -------------------------------------------------------------------------------
  Middle     jacode.pl  jacode.pl  Encode.pm  Jacode4e    Jacode4e::RoundTrip
  -------------------------------------------------------------------------------
  Beginner   jacode.pl  jacode.pl  jacode.pl  Jacode4e    Jacode4e::RoundTrip
  -------------------------------------------------------------------------------

=head1 AUTHOR

This project was originated by Kazumasa Utashiro E<lt>utashiro@iij.ad.jpE<gt>.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Copyright (c) 2010, 2011, 2014, 2015, 2016, 2017, 2018 INABA Hitoshi E<lt>ina@cpan.org>E<gt> in a CPAN

The latest version is available here:

L<http://search.cpan.org/dist/jacode/>

 *** ATTENTION ***
 This software is not "jcode.pl"
 Thus don't redistribute this software renaming as "jcode.pl"
 Moreover, this software IS NOT "jacode4e.pl"
 If you want "jacode4e.pl", search it on CPAN again.

Original version `jcode.pl' is ...

Copyright (c) 2002 Kazumasa Utashiro
http://web.archive.org/web/20090608090304/http://srekcah.org/jcode/

Copyright (c) 1995-2000 Kazumasa Utashiro E<lt>utashiro@iij.ad.jpE<gt>
Internet Initiative Japan Inc.
3-13 Kanda Nishiki-cho, Chiyoda-ku, Tokyo 101-0054, Japan

Copyright (c) 1992,1993,1994 Kazumasa Utashiro
Software Research Associates, Inc.

Use and redistribution for ANY PURPOSE are granted as long as all
copyright notices are retained.  Redistribution with modification
is allowed provided that you make your modified version obviously
distinguishable from the original one.  THIS SOFTWARE IS PROVIDED
BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES ARE
DISCLAIMED.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Original version was developed under the name of srekcah@sra.co.jp
February 1992 and it was called kconv.pl at the beginning.  This
address was a pen name for group of individuals and it is no longer
valid.

The latest version is available here:

L<ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/>

=head1 SEE ALSO

 UNIX MAGAZINE
 1992 Apr
 Pages: 148
 T1008901040810 ZASSHI 08901-4
 http://ascii.asciimw.jp/books/books/detail/978-4-7561-5008-0.shtml

 Programming Perl, Second Edition
 By Larry Wall, Tom Christiansen, Randal L. Schwartz
 October 1996
 Pages: 670
 ISBN 10: 1-56592-149-6 | ISBN 13: 9781565921498
 http://shop.oreilly.com/product/9781565921498.do

 Programming Perl, Third Edition
 By Larry Wall, Tom Christiansen, Jon Orwant
 Third Edition  July 2000
 Pages: 1104
 ISBN 10: 0-596-00027-8 | ISBN 13: 9780596000271
 http://shop.oreilly.com/product/9780596000271.do

 Programming Perl, 4th Edition
 By: Tom Christiansen, brian d foy, Larry Wall, Jon Orwant
 Publisher: O'Reilly Media
 Formats: Print, Ebook, Safari Books Online
 Print: January 2012
 Ebook: March 2012
 Pages: 1130
 Print ISBN: 978-0-596-00492-7 | ISBN 10: 0-596-00492-3
 Ebook ISBN: 978-1-4493-9890-3 | ISBN 10: 1-4493-9890-1
 http://shop.oreilly.com/product/9780596004927.do

 Perl Cookbook, Second Edition
 By Tom Christiansen, Nathan Torkington
 Second Edition  August 2003
 Pages: 964
 ISBN 10: 0-596-00313-7 | ISBN 13: 9780596003135
 http://shop.oreilly.com/product/9780596003135.do

 Perl in a Nutshell, Second Edition
 By Stephen Spainhour, Ellen Siever, Nathan Patwardhan
 Second Edition  June 2002
 Pages: 760
 Series: In a Nutshell
 ISBN 10: 0-596-00241-6 | ISBN 13: 9780596002411
 http://shop.oreilly.com/product/9780596002411.do

 Learning Perl on Win32 Systems
 By Randal L. Schwartz, Erik Olson, Tom Christiansen
 August 1997
 Pages: 306
 ISBN 10: 1-56592-324-3 | ISBN 13: 9781565923249
 http://shop.oreilly.com/product/9781565923249.do

 Learning Perl, Fifth Edition
 By Randal L. Schwartz, Tom Phoenix, brian d foy
 June 2008
 Pages: 352
 Print ISBN:978-0-596-52010-6 | ISBN 10: 0-596-52010-7
 Ebook ISBN:978-0-596-10316-3 | ISBN 10: 0-596-10316-6
 http://shop.oreilly.com/product/9780596520113.do

 Perl RESOURCE KIT UNIX EDITION
 Futato, Irving, Jepson, Patwardhan, Siever
 ISBN 10: 1-56592-370-7
 http://shop.oreilly.com/product/9781565923706.do

 Understanding Japanese Information Processing
 By Ken Lunde
 O'Reilly Media
 September 1993
 Pages: 470
 ISBN: 978-1-56592-043-9 | ISBN 10:1-56592-043-0
 http://shop.oreilly.com/product/9781565920439.do

 CJKV Information Processing Chinese, Japanese, Korean & Vietnamese Computing
 By Ken Lunde
 O'Reilly Media
 Print: January 1999
 Ebook: June 2009
 Pages: 1128
 Print ISBN:978-1-56592-224-2 | ISBN 10:1-56592-224-7
 Ebook ISBN:978-0-596-55969-4 | ISBN 10:0-596-55969-0
 http://shop.oreilly.com/product/9781565922242.do

 CJKV Information Processing, 2nd Edition
 By Ken Lunde
 O'Reilly Media
 Print: December 2008
 Ebook: June 2009
 Pages: 912
 Print ISBN: 978-0-596-51447-1 | ISBN 10:0-596-51447-6
 Ebook ISBN: 978-0-596-15782-1 | ISBN 10:0-596-15782-7
 http://shop.oreilly.com/product/9780596514471.do

 Mastering Regular Expressions, Second Edition
 By Jeffrey E. F. Friedl
 Second Edition  July 2002
 Pages: 484
 ISBN 10: 0-596-00289-0 | ISBN 13: 9780596002893
 http://shop.oreilly.com/product/9780596002893.do

 Mastering Regular Expressions, Third Edition
 By Jeffrey E. F. Friedl
 Third Edition  August 2006
 Pages: 542
 ISBN 10: 0-596-52812-4 | ISBN 13:9780596528126
 http://shop.oreilly.com/product/9780596528126.do

 Regular Expressions Cookbook
 By Jan Goyvaerts, Steven Levithan
 May 2009
 Pages: 512
 ISBN 10:0-596-52068-9 | ISBN 13: 978-0-596-52068-7
 http://shop.oreilly.com/product/9780596520694.do

 PERL PUROGURAMINGU
 Larry Wall, Randal L.Schwartz, Yoshiyuki Kondo
 December 1997
 ISBN 4-89052-384-7
 http://www.context.co.jp/~cond/books/old-books.html

 JIS KANJI JITEN
 Kouji Shibano
 Pages: 1456
 ISBN 4-542-20129-5
 http://www.webstore.jsa.or.jp/lib/lib.asp?fn=/manual/mnl01_12.htm

 UNIX MAGAZINE
 1993 Aug
 Pages: 172
 T1008901080816 ZASSHI 08901-8
 http://ascii.asciimw.jp/books/books/detail/978-4-7561-5008-0.shtml

 MacPerl Power and Ease
 By Vicki Brown, Chris Nandor
 April 1998
 Pages: 350
 ISBN 10: 1881957322 | ISBN 13: 978-1881957324
 http://www.amazon.com/Macperl-Power-Ease-Vicki-Brown/dp/1881957322

 Other Tools
 http://search.cpan.org/dist/Char/
 http://search.cpan.org/dist/Char-Sjis/
 http://search.cpan.org/dist/Modern-Open/
 http://search.cpan.org/dist/jacode4e/

 BackPAN
 http://backpan.perl.org/authors/id/I/IN/INA/

=head1 ACKNOWLEDGEMENTS

This software was made referring to software and the document that the
following hackers or persons had made.
I am thankful to all persons.

 Larry Wall, Perl
 http://www.perl.org/

 mikeneko creator club, Private manual of jcode.pl
 http://mikeneko.creator.club.ne.jp/~lab/kcode/jcode.html

 gama, getcode.pl
 http://www2d.biglobe.ne.jp/~gama/cgi/jcode/jcode.htm

 Gappai, jcodeg.diff
 http://www.vector.co.jp/soft/win95/prog/se347514.html

 OHZAKI Hiroki, Perl memo
 http://www.din.or.jp/~ohzaki/perl.htm#JP_Code

 NAKATA Yoshinori, Ad hoc patch for reduce waring on h2z_euc
 http://white.niu.ne.jp/yapw/yapw.cgi/jcode.pl%A4%CE%A5%A8%A5%E9%A1%BC%CD%DE%C0%A9

 Dan Kogai, Jcode module and Encode module
 http://search.cpan.org/dist/Jcode/
 http://search.cpan.org/dist/Encode/
 http://blog.livedoor.jp/dankogai/archives/50116398.html
 http://blog.livedoor.jp/dankogai/archives/51004472.html

 Donzoko CGI+--, Jcode like Encode Wrapper
 http://www.donzoko.net/cgi/jencode/

 Yusuke Kawasaki, Encode561 module
 http://www.kawa.net/works/perl/i18n-emoji/i18n-emoji.html#Encode561

 Tokyo-pm archive
 http://mail.pm.org/pipermail/tokyo-pm/

 utf8_possible_story, Perl de Nihongo Aruaru
 http://aizen.likk.jp/slide/utf8_possible_story/

 Very old fj.kanji discussion
 http://www.ie.u-ryukyu.ac.jp/~kono/fj/fj.kanji/index.html

 TechLION vol.26
 https://type.jp/et/feature/1569

 jcode.pl: Perl library for Japanese character code conversion, Kazumasa Utashiro
 ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/
 http://web.archive.org/web/20090608090304/http://srekcah.org/jcode/
 ftp://ftp.oreilly.co.jp/pcjp98/utashiro/
 http://mail.pm.org/pipermail/tokyo-pm/2002-March/001319.html
 https://twitter.com/uta46/status/11578906320

 jacode - Perl program for Japanese character code conversion
 https://metacpan.org/search?q=jacode.pl

 Jacode4e - jacode.pl-like program for enterprise
 https://metacpan.org/pod/Jacode4e

 Jacode4e::RoundTrip - Jacode4e for round-trip conversion in JIS X 0213
 https://metacpan.org/pod/Jacode4e::RoundTrip

 Modern::Open - Autovivification, Autodie, and 3-args open support
 https://metacpan.org/pod/Modern::Open

=cut
