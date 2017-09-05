#
# MIME/AltWords.pm -- a lot of fixes on MIME::Words
# by pts@fazekas.hu at Fri Jan 20 11:35:08 UTC 2006
# -- Fri Mar 31 18:41:14 CEST 2006
#
# Dat: this assumes Perl v5.8 or later
# Dat: run the unit tests with:  ./pts-test.pl AltMIMEWords.pm
# Dat: see `perldoc MIME::Words' for the original documentation
# Dat: a raw string has bytes in 0..255, and it is already encoded in some
#      encoding
# SUXX: perldoc doesn't respect `=encoding utf-8'
#       lib/MIME/AltWords.pm:30: Unknown command paragraph "=encoding utf8"
# !! why `,' in teszt a =?ISO-8859-2?Q?lev=E9lben=2C_t=F6r=F6lhet=F5?= ?? is it standard?
# !! document all
# !! document test cases
# !! MANIFEST etc.
#

package MIME::AltWords;
use v5.8; # Dat: Unicode string support etc.
use integer;
use strict;
use MIME::Base64;
use MIME::QuotedPrint;
use Encode;
use warnings;
use Exporter;
no warnings qw(prototype redefine);

=pod

=encoding utf8

=head1 NAME

MIME::AltWords - properly deal with RFC-1522 encoded words

=head1 SYNOPSIS

The Perl module L<MIME::AltWords> is recommended for encoding and
decoding MIME words (such as C<=?ISO-8859-2?Q?_=E1ll_e=E1r?=>) found in
e-mail message headers (mostly Subject, From and To).

L<MIME::AltWords> is similar to L<MIME::Words> in
L<MIME::Tools>, but it provides an alternate implementation that follows the
MIME specification more carefully, and it is actually compatible with
existing mail software (tested with Mutt, Pine, JavaMail and OpenWebmail).
L<MIME::AltWords> extends the functionality of L<MIME::Words> (version
5.420) by adding more functions and more options to existing functions. The
original interface is changed in an upward-compatible way.

Before reading further, you should see L<MIME::Tools> to make sure that 
you understand where this module fits into the grand scheme of things.
Go on, do it now.  I'll wait.  

Ready?  Ok...

    use MIME::AltWords qw(:all);   
     
    ### Decode the string into another string, forgetting the charsets:
    $decoded = decode_mimewords(
          'To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>',
          );
    
    ### Split string into array of decoded [DATA,CHARSET] pairs:
    @decoded = decode_mimewords(
          'To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>',
          );
     
    ### Encode a single unsafe word:
    $encoded = encode_mimeword("\xABFran\xE7ois\xBB");
    
    ### Encode a string, trying to find the unsafe words inside it: 
    $encoded = encode_mimewords("Me and \xABFran\xE7ois\xBB in town");



=head1 DESCRIPTION

Fellow Americans, you probably won't know what the hell this module
is for.  Europeans, Russians, et al, you probably do.  C<:-)>. 

For example, here's a valid MIME header you might get:

      From: =?US-ASCII?Q?Keith_Moore?= <moore@cs.utk.edu>
      To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>
      CC: =?ISO-8859-1?Q?Andr=E9_?= Pirard <PIRARD@vm1.ulg.ac.be>
      Subject: =?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=
       =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=
       =?US-ASCII?Q?.._cool!?=

The fields basically decode to (sorry, I can only approximate the
Latin characters with 7 bit sequences /o and 'e):

      From: Keith Moore <moore@cs.utk.edu>
      To: Keld J/orn Simonsen <keld@dkuug.dk>
      CC: Andr'e  Pirard <PIRARD@vm1.ulg.ac.be>
      Subject: If you can read this you understand the example... cool!


=head1 PUBLIC INTERFACE

=over 4

=cut


use vars qw($NONPRINT $VERSION);

### The package version, both in 1.23 style *and* usable by MakeMaker:
BEGIN { # vvv Dat: MakeMaker needs $VERSION in a separate line
$VERSION = "0.14"
}

# Dat: MIME::Words has [\x00-\x1F\x7F-\xFF]. We prepare for Unicode.
$NONPRINT=qr{(?:[^\x20-\x7E]|=)};
#$NONPRINT=qr{(?:[^\x20-\x7E]|[=](?=[?]))}; # Imp: is a bare `=' legal?

#** @param $_[0] charset name
#** @return MIME canonical charset name
sub canonical_charset($) {
  my $S=$_[0];
  if ($S=~/\A(?:iso-?(?:8859-?)?|8859-?)(\d+)\Z(?!\n)/i) { "ISO-8859-$1" }
  elsif ($S=~/\AUTF-?8\Z(?!\n)/i) { "UTF-8" }
  elsif ($S=~/\A(?:US-)ASCII\Z(?!\n)/i) { "US-ASCII" }
  else { uc $S }
}

#** @param $_[0] string.
#** @param $_[1] hashref. options
#** @param $_[2] string to append to
sub append_encoded_word($$$) {
  my($word,$opts,$dst)=@_;
  if ($opts->{Encoding} eq "B") {
    $word=MIME::Base64::encode_base64($word, ''); # Dat: empty EOL, as requested by MIME
    $word=~s@\s+@@g;
    $$dst.=$word
  } elsif ($opts->{Encoding} eq "Q") {
    # Dat: improved MIME::Words::_encode_Q
    $word =~ s{( )|([_\?\=]|$NONPRINT)}{defined $1 ? "_" # Dat: "_" is an improvement
      : sprintf("=%02X", ord($2))}eog;
    $$dst.=$word
  } else { die }
  undef
}

#use vars qw($old_encode_mimewords);
#BEGIN { $old_encode_mimewords=\&MIME::AltWords::encode_mimewords }

#** @param $_[0] string. Unicode
#** @param $_[1] hashref. options preprocessed by out encode_mimewords()
#** @return 0..255 string, ends with $opts->{Space} if $opts->{Shorts}
sub encode_mimeword1($$) {
  my($src,$opts)=@_;
  # Imp: warning if Encode::encode cannot represent character
  my $dst="";
  my $open="=?$opts->{Charset}?$opts->{Encoding}?";
  my $maxlen=64; # Dat: good for a subject line !! 63 or 62
  # ^^^ Dat: $maxlen=75 works fine in postfix 2.1.5 + pine 4.64
  # ^^^ Dat: one quoted word shouldn't be too long
  # ^^^ Dat: Subject: =?B?C?3412341234123412341234123412341234123412341234123412341234?=
  $maxlen-=length($open);
  $maxlen=int(($maxlen+3)/4)*3 if $opts->{Encoding} eq "B"; # Dat: `use integer;' anyway
  #print STDERR "($src) $maxlen\n";

  $src=Encode::encode($opts->{Charset},$src);
  if ($opts->{Shorts}) {
    my $I=0;
    while ($I<length($src)) {
      # Dat: split result for too long consecutive headers (i.e. long Subject: line)
      my $J=$I+$maxlen;
      $J=length($src) if $J>length($src);
      if ($opts->{Charset} eq "UTF-8") { # Dat: UTF-8 is multibyte, it cannot split anywhere
        if (substr($src,$J,1)=~y/\x80-\xbf//) { # Dat: a half-cut UTF-8 byte sequence
          $J-- while $J>$I+1 and substr($src,$J-1,1)=~y/\x80-\xbf//;
          $J-- if    $J>$I+1 and substr($src,$J-1,1)=~y/\xc0-\xff//;
          # ^^^Dat: `$I+1': avoid infinite loop in `$I<$maxlen'
        }
      }
      # Imp: else: fix for other multibyte encodings
      $dst.=$open;
      my $addlen=-length($dst);
      append_encoded_word(substr($src,$I,$J-$I),$opts,\$dst);
      $addlen+=length($dst);
      if ($opts->{Encoding} eq "Q" and $addlen>$maxlen and $addlen>3) {
        # Dat: too many hex `=..' triplets, become too long
        my $K=length($dst);
        while ($addlen>$maxlen) {
          if (substr($dst,$K-3,1)eq"=") { $addlen-=3; $K-=3; $J-- }
          else { $addlen--; $K--; $J-- }
        }
        substr($dst,$K)="";
        # Imp: more efficient, don't process the same data many times
      }
      $dst.="?="; $dst.=$opts->{Space};
      $I=$J;
    }
  } else { $dst.=$open; append_encoded_word($src,$opts,\$dst); $dst.="?=" }
  $dst
}

#** @returns the specified string quoted in double quotes. All characters
#**   are printable ASCII.
sub dumpstr($) {
  my $S=$_[0];
  $S=~s@(["\\])|([^ -~])@
    defined $2 ? sprintf("\\x{%X}",ord($2)) # Imp: Unicode chars
               : "\\$1" # Imp: Unicode chars
  @ge;
  "\"$S\"" #"
}

#** Splits a string on spaces into lines so no line is longer than the maximum
#** (except if there is no space nearby).
#** Only the 1st space is converted to $_[2] at each break.
#** @param $_[0] string. to split
#** @param $_[1] integer. maximum # chars in a line (not counting the terminating newline)
#** @param $_[2] chars to replace a space with -- not being added to the
#**   maximum line length
sub split_words($$$) {
  my($S,$maxlen,$nl)=@_;
  my $lastpos=0;  my $I=0; my $J;
  #** Position after last space to split at, or $I
  my $K;
  my $ret="";
  while (1) { # Imp: faster implementation
    $K=$J=$I;
    $J++ while $J<length($S) and substr($S,$J,1)=~/[ \n]/;
    while ($K==$I ? ($J<length($S)) : ($J+$maxlen<length($S) and $J<=$I+$maxlen)) {
      my $C=substr($S,$J,1);
      if ($C eq"\n") { $K=$I=++$J }
      elsif ($C eq " ") { $K=++$J }
      else { $J++ }
    }
    if ($K>$I and $J>$I+$maxlen) {
      $ret.=substr($S,$I,$K-1-$I);
      $ret.=$nl;
      $I=$K; # Imp: skip more
    }
    if ($J+$maxlen>=length($S)) { $ret.=substr($S,$I); last } # Dat: found last line, no way to split
  }
  $ret
}

=item encode_mimewords RAW, [OPTS]

I<Function.>
Given a RAW string, try to find and encode all "unsafe" sequences 
of characters:

    ### Encode a string with some unsafe "words":
    $encoded = encode_mimewords("Me and \xABFran\xE7ois\xBB");

Returns the encoded string.
Any arguments past the RAW string are taken to define a hash of options:

=over 4

=item Charset

Encode all unsafe stuff with this charset.  Default is 'ISO-8859-1',
a.k.a. "Latin-1".

=item Encoding

The encoding to use, C<"q"> or C<"b">.  The default is C<"q">.

=item Field

Name of the mail field this string will be used in.  I<Currently ignored.>

=back

B<Note:> this is a stable, tested, widely compatible solution. Strict
compliance with RFC-1522 (regarding the use of encoded words in message
headers), however, was not proven, but strings returned by this function
work properly and identically with Mutt, Pine, JavaMail and OpenWebmail. The
recommended way is to use this function instead of C<encode_mimeword()> or
L<MIME::Words/encode_mimewords>.

=cut


#** Dat: no prototype, because original encode_mimewords() doesn't have it
#**      a prototype either
#** @param $_[0] string|raw string. raw
#** @param $_[1].. list of key-value pairs. options
#**   Keys documented in `perldoc MIME::Words'': Charset, Encoding, Field.
#**   Charset is now autodetected (not always ISO-8859-1)
#**   New key: Raw:
#**     -- 1 (default): true: $_[0] is already a raw, encoded string
#**     -- 0: false: $_[0] is a Perl unicode string, it needs to be filtered
#          with Encode::encode(Charset)
#**   New key: Shorts:
#**     -- 1 (default for encode_mimewords)
#**     -- 0 (default for encode_mimeword)
#**   New key: Whole: (is respected iff Shorts==0)
#**     -- 1 (default): quote the string as a whole word (not default in the original!)
#**     -- 0: encode subwords
#**   New key: Keeptrailnl
#**     -- 0: treat trailing newline as unprintable
#**     -- 1 (default, as in original MIME::Words, as expected by Sympla 4):
#          keep trailing newline at the end
#** !! doc more, including new keys
sub encode_mimewords_low {
  my($S,%opts)=@_;
  return undef if !defined($S);
  # die "no word for encode_mimewords" if !defined $S; # Dat: Sympa calls us with undef
  #die unless open LOG, ">> /tmp/b.log";
  #die unless print LOG "=> ".dumpstr($S)."\n";
  #die unless close LOG;
  #$opts{Charset}="ISO-8859-1" if !defined $opts{Charset};
  $opts{Raw}=1 if !defined $opts{Raw};
  $opts{Charset}=get_best_encode_charset($S) if !defined $opts{Charset};
  die if !defined $opts{Charset};
  $opts{Charset}=canonical_charset($opts{Charset});
  if ($opts{Raw}) { # Dat: improvement
    $opts{Raw}=0;
    #die if !defined $S;
    $S=Encode::decode($opts{Charset}, $S);
    # ^^^ Dat: better do a Unicode regexp match
  }
  $opts{Encoding}=defined($opts{Encoding}) ? uc($opts{Encoding}) : "Q";
  $opts{Encoding}="Q" if $opts{Encoding} ne "B"; # Dat: improvement
  $opts{Encoding}="B" if $opts{Encoding} eq "Q" and $opts{Charset} eq "UTF-8";
  # ^^^ Dat: UTF-8 encoded MimeWords must be in base64 -- quoted-printable is
  #     bad, Pine doesn't display quoted-printable properly
  #     (it assumes ISO-8859-1 for quoted-printable chars), and Mutt does it
  #     the other way;
  #     We need Base64 "=?UTF-8?B?".MIME::Base64::encode_base64("Unicode string")."?=
  $opts{Shorts}=1 if !defined $opts{Shorts};
  $opts{Whole}=1 if !defined $opts{Whole};
  $opts{Space}=" " if !defined $opts{Space}; # Dat: empty =?...?==?...?= in the original MIME::Words
  $opts{Split}=66 if !defined $opts{Split}; # Dat: split at this many chars
  $opts{Keeptrailnl}=1 if !defined $opts{Keeptrailnl};
  my $toend="";
  $toend=$1 if $opts{Keeptrailnl} and $S=~s@(\n)\Z(?!\n)@@;
  if (!$opts{Shorts}) {
    $S=encode_mimeword1($S,\%opts)
  } elsif ($opts{Whole}) {
    if ($S=~/$NONPRINT/o) {
      $S=encode_mimeword1($S,\%opts);
      substr($S,-1)=""; # Dat: remove last space
    }
    $S=split_words($S, $opts{Split}, "\n ") if $opts{Split};
  } else {
    my $lastpos=0;
    while ($S=~/($NONPRINT[^ ]* *)/go) {
      # ^^^ Dat: having ` *' is a must here, other clients just forget about it
      my $I=pos($S)-length($1);
      $I-- while $I>$lastpos and substr($S,$I-1,1)ne' ';
      my $pos=pos($S); my $D;
      1 while ($pos=pos($S)) and $S=~/ |\Z(?!\n)|($NONPRINT)/goc and defined($D=$1)
        and $S=~/\G[^ ]* */goc;
      pos($S)=$pos if !defined $D;
      my $srclen=pos($S)-$I;
      my $src=substr($S,$I,$srclen);
      ##print STDERR "D($src)(".substr($S,$I+$srclen).")\n";
      if ($I+$srclen!=length($S) and substr($src,-1)eq' ' and $S=~/ |\Z(?!\n)|($NONPRINT)/goc and !defined($1)) {
        ##print STDERR "Strip ending space\n";
        substr($src,-1)=""; # Dat: see test case 'ignore_space'
      }
      # Dat: now pos($S) is invalid
      die if 1>length($src);
      ##print STDERR "E($src)(".substr($S,$I+$srclen).")\n";
      my $dst=encode_mimeword1($src,\%opts); # Dat: with trailing space
      ##print STDERR substr($S,$I,$srclen),";;\n";
      substr($S,$I,$srclen)=$dst; # Imp: do with less copying
      $lastpos=pos($S)=$I+length($dst);
    }
    substr($S,-length($opts{Space}))="" if
      0<length($opts{Space}) and length($S)==$lastpos; # Dat: remove trailing space of MIME word
    $S=split_words($S, $opts{Split}, "\n ") if $opts{Split};
  }
  $S.=$toend;
  #$S=~s@ @\n @g; # !! debug
  #die unless open LOG, ">> /tmp/b.log";
  #die unless print LOG "T> ".dumpstr($S)."\n";
  #die unless close LOG;
  $S
}

#use vars qw($old_encode_mimeword);
#BEGIN { $old_encode_mimeword=\&MIME::AltWords::encode_mimeword }

=item encode_mimeword RAW, [ENCODING], [CHARSET]

I<Function.>
Encode a single RAW "word" that has unsafe characters.
The "word" will be encoded in its entirety.

    ### Encode "<<Franc,ois>>":
    $encoded = encode_mimeword("\xABFran\xE7ois\xBB");

You may specify the ENCODING (C<"Q"> or C<"B">), which defaults to C<"Q">.
You may specify the CHARSET, which defaults to C<iso-8859-1>.

=cut


#** Dat: no prototype, because original encode_mimeword() doesn't have it
#**      a prototype either
#** @param $_[0] raw string. raw
#** @param $_[1] string. Encoding: "Q" or "B", defaults to "Q"
#** @param $_[2] string. Charset: defaults to "ISO-8859-1" (as in MIME::Words code,
#**   not as in its documentation
sub encode_mimeword {
  #sub encode_mimeword($;$$) {
  encode_mimewords($_[0],Encoding=>$_[1],Charset=>$_[2],Shorts=>0);
}

# ---

# $MIME_WORDS VERSION = "5.420";

# _decode_Q STRING
#     Private: used by _decode_header() to decode "Q" encoding, which is
#     almost, but not exactly, quoted-printable.  :-P
sub _decode_Q {
    my $str = shift;
    $str =~ s/_/\x20/g;                                # RFC-1522, Q rule 2
    $str =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;  # RFC-1522, Q rule 1
    $str;
}

# _encode_Q STRING
#     Private: used by _encode_header() to decode "Q" encoding, which is
#     almost, but not exactly, quoted-printable.  :-P
sub _encode_Q {
    my $str = shift;
    $str =~ s{([_\?\=\x00-\x1F\x7F-\xFF])}{sprintf("=%02X", ord($1))}eg;
    $str;
}

# _decode_B STRING
#     Private: used by _decode_header() to decode "B" encoding.
sub _decode_B {
    my $str = shift;
    decode_base64($str);
}

# _encode_B STRING
#     Private: used by _decode_header() to decode "B" encoding.
sub _encode_B {
    my $str = shift;
    encode_base64($str, '');
}

# Copied from MIME::Words.
sub decode_mimewords_wantarray_low {
    my $encstr = shift;
    my %params = @_;
    my @tokens;
    $@ = '';           ### error-return

    ### Collapse boundaries between adjacent encoded words:
    $encstr =~ s{(\?\=)\s*(\=\?)}{$1$2}gs;
    pos($encstr) = 0;
    ### print STDOUT "ENC = [", $encstr, "]\n";

    ### Decode:
    my ($charset, $encoding, $enc, $dec);
    while (1) {
	last if (pos($encstr) >= length($encstr));
	my $pos = pos($encstr);               ### save it

	### Case 1: are we looking at "=?..?..?="?
	if ($encstr =~    m{\G             # from where we left off..
			    =\?([^?]*)     # "=?" + charset +
			     \?([bq])      #  "?" + encoding +
			     \?([^?]+)     #  "?" + data maybe with spcs +
			     \?=           #  "?="
			    }xgi) {
	    ($charset, $encoding, $enc) = ($1, lc($2), $3);
	    $dec = (($encoding eq 'q') ? _decode_Q($enc) : _decode_B($enc));
	    push @tokens, [$dec, $charset];
	    next;
	}

	### Case 2: are we looking at a bad "=?..." prefix? 
	### We need this to detect problems for case 3, which stops at "=?":
	pos($encstr) = $pos;               # reset the pointer.
	if ($encstr =~ m{\G=\?}xg) {
	    $@ .= qq|unterminated "=?..?..?=" in "$encstr" (pos $pos)\n|;
	    push @tokens, ['=?'];
	    next;
	}

	### Case 3: are we looking at ordinary text?
	pos($encstr) = $pos;               # reset the pointer.
	if ($encstr =~ m{\G                # from where we left off...
			 ([\x00-\xFF]*?    #   shortest possible string,
			  \n*)             #   followed by 0 or more NLs,
		         (?=(\Z|=\?))      # terminated by "=?" or EOS
			}xg) {
	    length($1) or die "MIME::AltWords: internal logic err: empty token\n";
	    push @tokens, [$1];
	    next;
	}
	
	if ($encstr=~m{\G([\x00-\xFF]*)[^\x00-\xFF]+}g) { #### pts ####
	    $@.=qq|wide character in encoded string\n|;
	    push @tokens, [$1] if 0!=length($1);
	    next;
	}

	### Case 4: bug!
	die "MIME::AltWords: unexpected case:\n($encstr) pos $pos\n\t".
	    "Please alert developer.\n";
    }
    return (wantarray ? @tokens : join('',map {$_->[0]} @tokens));
}

#** Dat: function added by #### pts ####
#** @param $_[0] a mimewords-encoded string
#** @return a canonical encoding name with which the string can be re-encoded
sub get_best_decode_charset($) {
  my $encodedstr=$_[0];
  my @L;
  for my $token (decode_mimewords($encodedstr)) {
     my $charset=canonical_charset($token->[1] or "");
     push @L, $charset if $charset and (!@L or $L[-1] ne $charset);
  }
  @L=canonical_charset('UTF-8') if @L!=1; # Dat: default, can accomodate any charset
  $L[0]
}

=item decode_mimewords ENCODED, [OPTS...]

I<Function.>
Go through the string looking for RFC-1522-style "Q"
(quoted-printable, sort of) or "B" (base64) encoding, and decode them.

B<In an array context,> splits the ENCODED string into a list of decoded 
C<[DATA, CHARSET]> pairs, and returns that list.  Unencoded 
data are returned in a 1-element array C<[DATA]>, giving an effective 
CHARSET of C<undef>.

    $enc = '=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>';
    foreach (decode_mimewords($enc)) {
        print "", ($_[1] || 'US-ASCII'), ": ", $_[0], "\n";
    }

B<In a scalar context,> joins the "data" elements of the above list
together, and returns that. I<Note: this is not information-lossy,> it
sanitizes the returned string to use a specific, single charset, either
specified using the C<Charset> option, or autodetecting one (ISO-8859-1,
ISO-8859-2 or UTF-8) which can accomodate all characters. In case of charset
autodetection, C<get_best_decode_charset(ENCODED)> can be used to query the charset
autodetected.

You might want to see L<MIME::WordDecoder/unmime> as an alternate of
L<MIME::AltWords::encode_mimewords>.

In the event of a syntax error, $@ will be set to a description 
of the error, but parsing will continue as best as possible (so as to
get I<something> back when decoding headers).
$@ will be false if no error was detected.

Any arguments past the ENCODED string are taken to define a hash of options:

=over 4

=item Field

Name of the mail field this string came from.  I<Currently ignored.>

=back

=cut

#** Dat: no prototype, because original decode_mimewords() doesn't have it
#**      a prototype either
#** Dat: it is unsafe to use this without the Raw=>1 option. Search for
#**      MIME::WordDecoder in `perldoc MIME::Words'.
#** @param $_[0] a mimewords-encoded string
#** @param $_[1]... list of options (key=>value pairs).
#**   Keys documented in `perldoc MIME::Words'': Charset, Encoding, Field.
#**   New key: Raw:
#**     -- 1 (default): true: return a raw, encoded string. The encoding will
#**        be Charset, or the one returned by get_best_decode_charset().
#**        This is an improvement
#**        by #### pts #### -- the original decode_mimewords() didn't return
#**        the string in a consistent encoding.
#**     -- 0: false: $_[0] is a Perl unicode string, it needs to be filtered
#**        with Encode::encode(Charset)
#**   New key: Charset: specific charset name for Raw=1 (ignored for Raw=0)
sub decode_mimewords_low {
  return decode_mimewords_wantarray_low(@_) if wantarray;
  my($encodedstr,%opts)=@_;
  $opts{Raw}=1 if !defined $opts{Raw}; # Dat: default
  my $ret='';
  # vvv Dat: not mutually recursive, because get_best_decode_charset() calls
  #          decode_mimewords() in list context, so this line won't be
  #          reached.
  $opts{Charset}=get_best_decode_charset($encodedstr) if
    $opts{Raw} and !defined $opts{Charset};
  my $S;
  for my $token (decode_mimewords_wantarray_low($encodedstr,%opts)) { # Dat: $charset in $token->[1]
    $S=$token->[1] ? Encode::decode($token->[1], $token->[0]) : $token->[0];
    $S=Encode::encode($opts{Charset}, $S) if $opts{Raw};
    $ret.=$S
  }
  $ret
}

use vars qw(@encode_subject_opts);
BEGIN { @encode_subject_opts=(Keeptrailnl=>1, Whole=>1); }

#** Dat: function added by #### pts ####
#** @param $_[0] String. A mimewords-encoded e-mail subject.
#** @return String. better mimewords-encoded
sub fix_subject($) {
  my $encodedstr=$_[0];
  my $best_charset=get_best_decode_charset($encodedstr);
  my $decoded=decode_mimewords($encodedstr, Raw=>0);
  encode_mimewords($decoded, Charset=>$best_charset, Raw=>0, @encode_subject_opts);
}

use vars qw(@encode_addresses_opts);
BEGIN { @encode_addresses_opts=(Keeptrailnl=>1, Whole=>0); }

#** Dat: function added by #### pts ####
#** @param $_[0] String. A mimewords-encoded e-mail address (or address list),
#**   e.g. "=?ISO-8859-1?Q?foo?= bar <foo@bar.dom>, foo2 bar2 <foo2@bar2.dom>"
#** @return String. better mimewords-encoded
sub fix_addresses($) {
  my $encodedstr=$_[0];
  my $best_charset=get_best_decode_charset($encodedstr);
  my $decoded=decode_mimewords($encodedstr, Raw=>0);
  #print STDERR "DE($decoded)\n";
  #chomp $decoded;
  #$decoded.=" alma ";
  encode_mimewords($decoded, Charset=>$best_charset, Raw=>0, @encode_addresses_opts);
}

#** Dat: function added by #### pts ####
#** @param $_[0] a Unicode string
#** @param $_[1] a charset
#** @return Boolean: is it encodable?
sub is_encodable($$) {
  my $charset=uc$_[1];
  my $S=$_[0]; # Dat: must be copied for Encode::encode
  return 1 if $charset eq 'UTF-8' or $charset eq 'UTF8';
  eval { Encode::encode($charset, $S, Encode::FB_CROAK) };
  $@ ? 0 : 1
}

#** Please don't include US-ASCII.
#** Specify UTF-8 last (because get_best_encode_charset() ignores everything
#** after the first UTF-8).
use vars qw(@encode_charsets);
BEGIN { @encode_charsets=qw(ISO-8859-1 ISO-8859-2 UTF-8) }

#** Dat: function added by #### pts ####
#** @param $_[0] string to try
sub get_best_encode_charset($) {
  for my $charset (@encode_charsets) {
    return $charset if is_encodable($_[0], $charset);
  }
  return 'UTF-8'
}

#** Dat: function added by #### pts ####
#** @param $_[0] String. Perl Unicode-string
#** @param $_[1] encode mode: 'subject' or 'addresses'
#** @return String. better mimewords-encoded with the best charset
sub encode_unicode($$) {
  my $str=$_[0];
  my $modeary=($_[1] eq 'addresses' ? \@encode_addresses_opts : \@encode_subject_opts);
  my $best_charset=get_best_encode_charset($str);
  encode_mimewords($str, Charset=>$best_charset, Raw=>0, @$modeary);
}

#** Dat: function added by #### pts ####
#** @param $_[0] String. Perl 8-bit string, encoded in $charset
#** @param $_[1] encode mode: 'subject' or 'addresses'
#** @param $_[2] $charset;
#** @return String. better mimewords-encoded with the best charset
sub encode_8bit($$$) {
  my $str=$_[0];
  my $charset=$_[2];
  my $modeary=($_[1] eq 'addresses' ? \@encode_addresses_opts : \@encode_subject_opts);
  $charset=canonical_charset($charset);
  my $best_charset;
  for my $charset2 (@encode_charsets) {
    if (canonical_charset($charset2) eq $charset) {
      $best_charset=$charset; last
    }
  }
  $best_charset=canonical_charset(get_best_encode_charset($str)) if
    !defined $best_charset;
  ($charset eq $best_charset) ? # Imp: find badly encoded string...
    encode_mimewords($str, Charset=>$best_charset, Raw=>1, @$modeary) :
    encode_mimewords(Encode::decode($charset, $str), Charset=>$best_charset, Raw=>0, @$modeary)
}

# --- Logging...

BEGIN { *encode_mimewords=\&encode_mimewords_low }
BEGIN { *decode_mimewords=\&decode_mimewords_low }

BEGIN { if ($main::DEBUG) {

#use vars qw($orig_encode_mimewords $orig_decode_mimewords);
no warnings qw(prototype redefine);

#BEGIN { $orig_encode_mimewords=\&encode_mimewords }
*encode_mimewords=sub {
  require Carp;
  my $dump="\n\n[".scalar(localtime)."] encode_mimewords(@_) = ";
  my $ret=&encode_mimewords_low(@_); # Dat: we need `&' to ignore prototype
  $dump.=$ret."\n";
  if (open(my($log), ">> /tmp/em.log")) {
    local *STDERR; open STDERR, ">&".fileno($log);
    select(STDERR); $|=1; select($log); $|=1;
    binmode($log, ':utf8');
    print $log $dump;
    Carp::cluck("^^^ encode_mimewords() ");
    close $log;
  }
  $ret
};

#BEGIN { $orig_decode_mimewords=\&decode_mimewords }
# Imp: copy prototype of original...
*decode_mimewords=sub {
  require Carp;
  my $dump="\n\n[".scalar(localtime)."] decode_mimewords(@_) = ";
  if (wantarray) {
    my @L=(&decode_mimewords_low(@_));
    $dump.="@L (ary)\n";
    if (open(my($log), ">> /tmp/em.log")) {
      local *STDERR; open STDERR, ">&".fileno($log);
      select(STDERR); $|=1; select($log); $|=1;
      binmode($log, ':utf8');
      print $log $dump;
      Carp::cluck("^^^ decode_mimewords() ");
      close $log;
    }
    @L
  } else {
    my $ret=decode_mimewords_low(@_);
    $dump.=$ret."\n";
    if (open(my($log), ">> /tmp/em.log")) {
      local *STDERR; open STDERR, ">&".fileno($log);
      select(STDERR); $|=1; select($log); $|=1;
      binmode($log, ':utf8');
      print $log $dump;
      Carp::cluck("^^^ decode_mimewords() ");
      close $log;
    }
    $ret
  }
};

} }

# ---

=back

=head1 NOTES

Exports its principle functions by default, in keeping with 
L<MIME::Base64> and L<MIME::QuotedPrint>.

Doesn't depend on L<MIME::Words> or L<MIME::Tools>.

See also L<http://www.szszi.hu/wiki/Sympa4Patches> for the previous version
of L<MIME::AltWords> integrated into the Sympa 4 mailing list software.

=head1 AUTHOR

L<MIME::AltWords> was written by
PÃ©ter SzabÃ³ (F<pts@fazekas.hu>) in 2006, and it has been uploaded to CPAN on
2006-09-27.

L<MIME::AltWords> uses code from L<MIME::Words> (in the function
C<decode_mimewords_wantarray>) and it uses documentation from L<MIME::Words>
(in the file C<lib/MIME/AltWords.pm>).

Here is the original author and copyright information for L<MIME::Words>.

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
David F. Skoll (dfs@roaringpenguin.com) http://www.roaringpenguin.com

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

Thanks also to...

      Kent Boortz        For providing the idea, and the baseline 
                         RFC-1522-decoding code!
      KJJ at PrimeNet    For requesting that this be split into
                         its own module.
      Stephane Barizien  For reporting a nasty bug.


=head1 VERSION

See $VERSION in C<lib/MIME/AltWords.pm> .

=cut

=begin testing

is(MIME::AltWords::encode_mimewords("foo-b\x{E9}r"), "=?ISO-8859-1?Q?foo-b=E9r?=");
is(MIME::AltWords::encode_mimewords("foo  bar"), "foo  bar");
is(MIME::AltWords::encode_mimeword("foo  bar"), "=?ISO-8859-1?Q?foo__bar?="); # Dat: improvement over MIME::AltWords
is(MIME::AltWords::encode_mimeword("foo__bar "), "=?ISO-8859-1?Q?foo=5F=5Fbar_?="); # Dat: improvement over MIME::AltWords
is(MIME::AltWords::encode_mimewords("az ûrkikötõ földi adatai",Whole=>0), "az =?ISO-8859-1?Q?=FBrkik=F6t=F5_f=F6ldi?= adatai");
is(MIME::AltWords::decode_mimewords("az =?ISO-8859-1?Q?=FBrkik=F6t=F5_f=F6ldi_?= adatai", Charset=>'ISO-8859-2'),
  "az ?rkiköt? földi  adatai");
is(MIME::AltWords::decode_mimewords("az =?ISO-8859-2?Q?=FBrkik=F6t=F5_f=F6ldi_?= adatai", Charset=>'ISO-8859-1'),
  "az ?rkiköt? földi  adatai");
is(MIME::AltWords::decode_mimewords("az =?ISO-8859-1?Q?=FBrkik=F6t=F5_f=F6ldi_?= adatai", Charset=>'ISO-8859-1'),
  "az ûrkikötõ földi  adatai");
is(MIME::AltWords::decode_mimewords("az =?ISO-8859-2?Q?=FBrkik=F6t=F5_f=F6ldi_?= adatai", Charset=>'ISO-8859-2'),
  "az ûrkikötõ földi  adatai");
is(MIME::AltWords::decode_mimewords("az =?ISO-8859-2?Q?=FBrkik=F6t=F5_f=F6ldi_?= adatai"),
  "az ûrkikötõ földi  adatai"); # Dat: guess Charset to ISO-8859-2
is(MIME::AltWords::encode_mimewords("az ûrkikötõ földi adatai"), "=?ISO-8859-1?Q?az_=FBrkik=F6t=F5_f=F6ldi_adatai?=");
is(MIME::AltWords::encode_mimewords("az ûrkikötõ földi",Whole=>0), "az =?ISO-8859-1?Q?=FBrkik=F6t=F5_f=F6ldi?=");
is(MIME::AltWords::encode_mimewords("az ûrkikötõ földi"), "=?ISO-8859-1?Q?az_=FBrkik=F6t=F5_f=F6ldi?=");
is(MIME::AltWords::encode_mimewords("foo  b\x{E1}r",Whole=>0), "foo  =?ISO-8859-1?Q?b=E1r?=");
is(MIME::AltWords::encode_mimewords("foo  b\x{E1}r"), "=?ISO-8859-1?Q?foo__b=E1r?=");
is(MIME::AltWords::encode_mimewords( "b\x{F5}r  foo",Charset=>"ISO-8859-1",Whole=>0), "=?ISO-8859-1?Q?b=F5r_?= foo");
is(MIME::AltWords::encode_mimewords( "b\x{F5}r  foo",Charset=>"ISO-8859-1"), "=?ISO-8859-1?Q?b=F5r__foo?=");
{ my $S; eval { $S=MIME::AltWords::encode_mimewords("b\x{151}r  foo",Charset=>"ISO-8859-2"); };
  ok($@=~/^Wide character /); # Dat: Encode::decode fails
}
is(MIME::AltWords::encode_mimewords("b\x{151}r  foo",Charset=>"ISO-8859-2",Raw=>0,Whole=>0), "=?ISO-8859-2?Q?b=F5r_?= foo");
is(MIME::AltWords::encode_mimewords("b\x{151}r  foo",Charset=>"ISO-8859-2",Raw=>0), "=?ISO-8859-2?Q?b=F5r__foo?=");
is(MIME::AltWords::encode_mimewords("ha a sz\x{F3}t ~ jel",Charset=>"ISO-8859-2",Whole=>0),
  "ha a =?ISO-8859-2?Q?sz=F3t?= ~ jel",'ignore_space');
is(MIME::AltWords::encode_mimewords("ha a sz\x{F3}t ~ jel",Charset=>"ISO-8859-2"),
  "=?ISO-8859-2?Q?ha_a_sz=F3t_~_jel?=",'ignore_space2');
is(MIME::AltWords::encode_mimewords("ha a sz\x{F3}t ",Whole=>0,Charset=>"ISO-8859-1"),
  "ha a =?ISO-8859-1?Q?sz=F3t_?=", "ends with one space");
is(MIME::AltWords::encode_mimewords("ha a sz\x{F3}t  ",Whole=>0,Charset=>"ISO-8859-1"),
  "ha a =?ISO-8859-1?Q?sz=F3t__?=", "ends with two spaces");
is(MIME::AltWords::encode_mimewords("ha a sz\x{F3}t ",Charset=>"ISO-8859-1"),
  "=?ISO-8859-1?Q?ha_a_sz=F3t_?=");
is(MIME::AltWords::encode_mimewords("dokumentumok kezel\x{E9}se",Whole=>0), "dokumentumok =?ISO-8859-1?Q?kezel=E9se?=");
is(MIME::AltWords::encode_mimewords("dokumentumok kezel\x{E9}se"), "=?ISO-8859-1?Q?dokumentumok_kezel=E9se?=");
is(MIME::AltWords::encode_mimewords("tartalmaz\x{F3} dokumentumok kezel\x{E9}se",Whole=>0), "=?ISO-8859-1?Q?tartalmaz=F3?= dokumentumok =?ISO-8859-1?Q?kezel=E9se?=");
is(MIME::AltWords::encode_mimewords("tartalmaz\x{F3} dokumentumok kezel\x{E9}se"), "=?ISO-8859-1?Q?tartalmaz=F3_dokumentumok_kezel=E9se?="); # Imp: unify printable and nonprintable to save space

is(MIME::AltWords::encode_mimewords("A keresési eredményekb\x{151}l bizonyos ".
  "szavakat tartalmazó dokumentumok kizárhatók, ha a szót ~ jel el\x{151}zi ".
  "meg. Figyelem! A kizárás csak akkor eredményez találatot, ha és (& vagy ".
  "szóköz) kapcsolatban áll egy nem kizárással.",
  Charset=>"ISO-8859-2",Raw=>0,Whole=>0),
  "A =?ISO-8859-2?Q?keres=E9si_eredm=E9nyekb=F5l?= bizonyos szavakat\n =?ISO-8859-2?Q?tartalmaz=F3?= dokumentumok\n =?ISO-8859-2?Q?kiz=E1rhat=F3k,?= ha a =?ISO-8859-2?Q?sz=F3t?= ~\n jel =?ISO-8859-2?Q?el=F5zi?= meg. Figyelem! A\n =?ISO-8859-2?Q?kiz=E1r=E1s?= csak akkor\n =?ISO-8859-2?Q?eredm=E9nyez_tal=E1latot,?= ha\n =?ISO-8859-2?Q?=E9s?= (& vagy =?ISO-8859-2?Q?sz=F3k=F6z)?=\n kapcsolatban =?ISO-8859-2?Q?=E1ll?= egy nem =?ISO-8859-2?Q?kiz=E1r=E1ssal.?=");

is(MIME::AltWords::encode_mimewords("A keresési eredményekb\x{151}l bizonyos ".
  "szavakat tartalmazó dokumentumok kizárhatók, ha a szót ~ jel el\x{151}zi ".
  "meg. Figyelem! A kizárás csak akkor eredményez találatot, ha és (& vagy ".
  "szóköz) kapcsolatban áll egy nem kizárással.",
  Charset=>"ISO-8859-2",Raw=>0),
  "=?ISO-8859-2?Q?A_keres=E9si_eredm=E9nyekb=F5l_bizonyos_szavakat_?=\n =?ISO-8859-2?Q?tartalmaz=F3_dokumentumok_kiz=E1rhat=F3k,_ha_a_sz?=\n =?ISO-8859-2?Q?=F3t_~_jel_el=F5zi_meg._Figyelem!_A_kiz=E1r=E1s_c?=\n =?ISO-8859-2?Q?sak_akkor_eredm=E9nyez_tal=E1latot,_ha_=E9s_(&_va?=\n =?ISO-8859-2?Q?gy_sz=F3k=F6z)_kapcsolatban_=E1ll_egy_nem_kiz=E1r?=\n =?ISO-8859-2?Q?=E1ssal.?=");
# vvv Dat: composing with Pine emits:
#is(MIME::AltWords::encode_mimewords("A keresési eredményekbõl bizonyos szavakat tartalmazó dokumentumok kizárhatók, ha a szót ~ jel elõzi meg. Figyelem! A kizárás csak akkor eredményez találatot, ha és (& vagy szóköz) kapcsolatban áll egy nem kizárással.",
#"=?ISO-8859-2?Q?A_keres=E9si_eredm=E9nyekb=F5l_bizonyos_szavakat?=
# =?ISO-8859-2?Q?_tartalmaz=F3_dokumentumok_kiz=E1rhat=F3k=2C_ha_?=        
# =?ISO-8859-2?Q?a_sz=F3t_~_jel_el=F5zi_meg=2E_Figyelem!_A_?=
# =?ISO-8859-2?Q?kiz=E1r=E1s_csak_akkor_eredm=E9nyez_tal=E1latot=2C?=
# =?ISO-8859-2?Q?_ha_=E9s_=28&_vagy_sz=F3k=F6z=29_kapcsolatban?=
# =?ISO-8859-2?Q?_=E1ll_egy_nem_kiz=E1r=E1ssal=2E?=

is(MIME::AltWords::encode_mimewords("Árvízt\x{171}r\x{151} egy tükörfúrógép",
  Charset=>"UTF-8",Raw=>0,Whole=>0),"=?UTF-8?B?w4FydsOtenTFsXLFkQ==?= egy =?UTF-8?B?dMO8a8O2cmbDunLDs2fDqXA=?=");
is(MIME::AltWords::encode_mimewords("Árvízt\x{171}r\x{151} egy tükörfúrógép",
  Charset=>"UTF-8",Raw=>0),"=?UTF-8?B?w4FydsOtenTFsXLFkSBlZ3kgdMO8a8O2cmbDunLDs2fDqXA=?=");

is(MIME::AltWords::split_words("fo ot bar aaaaaaaaab  cccccccccdddddd e f g  ",8,"xy"),"fo otxybarxyaaaaaaaaabxy cccccccccddddddxye f g  ",'split_words()');

is(MIME::AltWords::encode_mimewords("Szab\x{F3} P\x{E9}ter <pts\@our.um>",Charset=>"UTF-8",Raw=>0),
 "=?UTF-8?B?U3phYsOzIFDDqXRlciA8cHRzQG91ci51bT4=?=");
is(MIME::AltWords::encode_mimewords("Szab\x{F3} P\x{E9}ter<pts\@our.um>",Charset=>"UTF-8",Raw=>0),
  "=?UTF-8?B?U3phYsOzIFDDqXRlcjxwdHNAb3VyLnVtPg==?="); # Dat: this is what compose_mail returns
is(MIME::AltWords::encode_mimewords("Szab\x{F3} P\x{E9}ter <pts\@our.um>",Charset=>"UTF-8",Raw=>0,Whole=>0),
  "=?UTF-8?B?U3phYsOzIFDDqXRlcg==?= <pts\@our.um>");
is(MIME::AltWords::encode_mimewords("Szab\x{F3} P\x{E9}ter  <pts\@our.um>",Charset=>"UTF-8",Raw=>0,Whole=>0),
  "=?UTF-8?B?U3phYsOzIFDDqXRlciA=?= <pts\@our.um>");

SKIP: {
  eval { require Mail::Address };
  skip "Mail::Address not installed", 1 if $@;
  my @sender_hdr = Mail::Address->parse("=?UTF-8?B?U3phYsOzIFDDqXRlciA=?= <pts\@our.um>");
  my $address=@sender_hdr ? $sender_hdr[0]->address : undef;
  $address="undef" if !defined $address;
  is($address, "pts\@our.um");
}

is(scalar MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("\x{171}",Charset=>"UTF-8",Raw=>0)),
  "\x{C5}\x{B1}", 'decode_mimewords()');
is(scalar MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("\x{171}",Charset=>"UTF-8",Raw=>0),Raw=>0),
  "\x{171}", 'decode_mimewords()');

is(MIME::AltWords::get_best_decode_charset(MIME::AltWords::encode_mimewords("f\x{171} fa t\x{F6}lgy",Charset=>"ISO-8859-2",Raw=>0,Whole=>0)),
  'ISO-8859-2', 'get_best_decode_charset()');
is(MIME::AltWords::get_best_decode_charset("=?ISO-8859-2?Q?f=FB?= fa =?ISO-8859-1?Q?t=F6lgy?="),
  'UTF-8', 'get_best_decode_charset()');
is(MIME::AltWords::get_best_decode_charset("fa"), 'UTF-8', 'get_best_decode_charset()');

is(MIME::AltWords::fix_addresses("=?ISO-8859-2?Q?f=FB?= fa =?ISO-8859-1?Q?t=F6lgy?="),
  "=?UTF-8?B?ZsWx?= fa =?UTF-8?B?dMO2bGd5?=", 'fix_addresses()');
is(MIME::AltWords::fix_addresses("=?UTF-8?B?U3phYsOzIFDDqXRlciA8cHRzQG91ci51bT4=?="),
  "=?UTF-8?B?U3phYsOzIFDDqXRlcg==?= <pts\@our.um>", 'fix_addresses()');
is(MIME::AltWords::fix_addresses("=?UTF-8?B?U3phYsOzIFDDqXRlciA8cHRzQG91ci51bT4K?="),
  "=?UTF-8?B?U3phYsOzIFDDqXRlcg==?= <pts\@our.um>\n", 'fix_addresses() Keeptrailnl');
is(MIME::AltWords::fix_subject("=?ISO-8859-2?Q?f=FB?= fa =?ISO-8859-1?Q?t=F6lgy?="),
  "=?UTF-8?B?ZsWxIGZhIHTDtmxneQ==?=", 'fix_subject()');

is(MIME::AltWords::decode_mimewords("=?UTF-8?B?ZsWx?= fa =?UTF-8?B?dMO2bGd5?=",Raw=>1),
  "f\x{C5}\x{B1} fa t\x{C3}\x{B6}lgy", 'decode_mimewords()');
is(MIME::AltWords::decode_mimewords("=?ISO-8859-2?Q?f=FB?= fa =?ISO-8859-1?Q?t=F6lgy?=",Raw=>0),
  "f\x{171} fa t\x{F6}lgy", 'decode_mimewords()');
#die "".MIME::AltWords::decode_mimewords("=?UTF-8?B?U3phYsOzIFDDqXRlciA8cHRzQG91ci51bT4=?=");
is(MIME::AltWords::decode_mimewords("=?UTF-8?B?U3phYsOzIFDDqXRlcg==?=",Raw=>0),
  "Szabó Péter", 'decode_mimewords()');

is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("f\x{E9}l",Charset=>"UTF-8",Raw=>0)),
  "f\x{C3}\x{A9}l", 'encode+decode mimewords');
is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("f\x{E9}l ",Charset=>"UTF-8",Raw=>0)),
  "f\x{C3}\x{A9}l ", 'encode+decode mimewords');
is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("f\x{E9}l  ",Charset=>"UTF-8",Raw=>0)),
  "f\x{C3}\x{A9}l  ", 'encode+decode mimewords');
is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("f\x{E9}l <",Charset=>"UTF-8",Raw=>0)),
  "f\x{C3}\x{A9}l <", 'encode+decode mimewords');
is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("f\x{E9}l <",Charset=>"UTF-8",Raw=>0,Whole=>0)),
  "f\x{C3}\x{A9}l <", 'encode+decode mimewords');
is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("d\x{E9}l < ",Charset=>"UTF-8",Raw=>0,Whole=>0)),
  "d\x{C3}\x{A9}l < ", 'encode+decode mimewords');
is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("d\x{E9}l <  ",Charset=>"UTF-8",Raw=>0,Whole=>0)),
  "d\x{C3}\x{A9}l <  ", 'encode+decode mimewords');

is(MIME::AltWords::encode_mimewords("[nekem] pr\x{F3}ba h\x{E1}romra\n",Keeptrailnl=>1),
  "=?ISO-8859-1?Q?[nekem]_pr=F3ba_h=E1romra?=\n", "encode_mimewords() Keeptrailnl=1");
is(MIME::AltWords::encode_mimewords("[nekem] pr\x{F3}ba h\x{E1}romra\n",Keeptrailnl=>0),
  "=?ISO-8859-1?Q?[nekem]_pr=F3ba_h=E1romra=0A?=", "encode_mimewords() Keeptrailnl=0");
is(MIME::AltWords::encode_mimewords("[nekem] pr\x{F3}ba h\x{E1}romra\n"),
  "=?ISO-8859-1?Q?[nekem]_pr=F3ba_h=E1romra?=\n", "encode_mimewords() Keeptrailnl=default");

is(MIME::AltWords::decode_mimewords("=?ISO-8859-2?Q?m=E1sik_pr=F3b=E1cska?=\n"),
  "m\x{E1}sik pr\x{F3}b\x{E1}cska\n", "decode_mimewords ISO-8859-2");

is(MIME::AltWords::get_best_encode_charset("hello\t\n"), "ISO-8859-1", "get_best_encode_charset() ASCII");
is(MIME::AltWords::get_best_encode_charset("hell\x{F3}, w\x{F6}rld\t\n"), "ISO-8859-1", "get_best_encode_charset() ISO-8859-1");
is(MIME::AltWords::get_best_encode_charset("hell\x{151}, w\x{F6}rld\t\n"), "ISO-8859-2", "get_best_encode_charset() ISO-8859-2");
is(MIME::AltWords::get_best_encode_charset("hell\x{151}, w\x{F5}rld\t\n"), "UTF-8", "get_best_encode_charset() UTF-8");

is(MIME::AltWords::encode_unicode("[foo] hell\x{151}, w\x{F5}rld\t\n", 'addresses'), "[foo] =?UTF-8?B?aGVsbMWRLCB3w7VybGQJ?=\n", "encode_addresses() UTF-8");
is(MIME::AltWords::encode_unicode("[foo] hell\x{151}, w\x{F5}rld\t\n", 'subject'), "=?UTF-8?B?W2Zvb10gaGVsbMWRLCB3w7VybGQJ?=\n", "encode_subject() UTF-8");
is(MIME::AltWords::encode_unicode("[foo] hell\x{151}, w\x{F6}rld\t\n", 'subject'), "=?ISO-8859-2?Q?[foo]_hell=F5,_w=F6rld=09?=\n", "encode_subject() ISO-8859-2");
is(MIME::AltWords::encode_unicode("[foo] hell\x{F3}, w\x{F6}rld\t\n", 'subject'), "=?ISO-8859-1?Q?[foo]_hell=F3,_w=F6rld=09?=\n", "encode_subject() ISO-8859-1");

is(MIME::AltWords::encode_unicode("toast =?FOO-42?Q?bar=35?= me?\n", 'addresses'), "toast =?ISO-8859-1?Q?=3D=3FFOO-42=3FQ=3Fbar=3D35=3F=3D?= me?\n", "encode_addresses() with mimewords");
is(MIME::AltWords::encode_unicode("toast =?FOO-42?Q?b\x{E1}r=35?= me?\n", 'addresses'), "toast =?ISO-8859-1?Q?=3D=3FFOO-42=3FQ=3Fb=E1r=3D35=3F=3D?= me?\n", "encode_addresses() with mimewords");

is(MIME::AltWords::encode_8bit("[foo] hell\x{C5}\x{91}, w\x{C3}\x{B5}rld\t\n", 'addresses', 'uTf8'), "[foo] =?UTF-8?B?aGVsbMWRLCB3w7VybGQJ?=\n", "encode_8bit() addresses UTF-8");
is(MIME::AltWords::encode_8bit("[foo] hell\x{C5}\x{91}, w\x{C3}\x{B5}rld\t\n", 'subject',   'uTf8'), "=?UTF-8?B?W2Zvb10gaGVsbMWRLCB3w7VybGQJ?=\n", "encode_8bit() subject UTF-8");
is(MIME::AltWords::encode_8bit("[foo] hell\x{F5}, w\x{F6}rld\t\n", 'subject', '88592'), "=?ISO-8859-2?Q?[foo]_hell=F5,_w=F6rld=09?=\n", "encode_8bit() subject ISO-8859-2");
is(MIME::AltWords::encode_8bit("[foo] hell\x{F3}, w\x{F6}rld\t\n", 'subject', '88591'), "=?ISO-8859-1?Q?[foo]_hell=F3,_w=F6rld=09?=\n", "encode_8bit() subject ISO-8859-1");
is(MIME::AltWords::encode_8bit("toast =?FOO-42?Q?bar=35?= me?\n", 'addresses', 'us-ascii'), "toast =?ISO-8859-1?Q?=3D=3FFOO-42=3FQ=3Fbar=3D35=3F=3D?= me?\n", "encode_8bit() addresses with mimewords");
is(MIME::AltWords::encode_8bit("toast =?FOO-42?Q?b\x{E1}r=35?= me?\n", 'addresses', '88591'), "toast =?ISO-8859-1?Q?=3D=3FFOO-42=3FQ=3Fb=E1r=3D35=3F=3D?= me?\n", "encode_8bit() addresses with mimewords");

is(join('  ',map{MIME::AltWords::encode_mimewords($_)}split/ +/,"[nekem] m\x{E1}sik pr\x{F3}b\x{E1}cska\n"),
  "[nekem]  =?ISO-8859-1?Q?m=E1sik?=  =?ISO-8859-1?Q?pr=F3b=E1cska?=\n", "encode_mimewords() default ISO-8859-1 a");

is(join('  ',map{MIME::AltWords::encode_mimewords($_,Raw=>0)}split/ +/,"[nekem] m\x{E1}sik pr\x{F3}b\x{151}cska\n"),
  "[nekem]  =?ISO-8859-1?Q?m=E1sik?=  =?ISO-8859-2?Q?pr=F3b=F5cska?=\n", "encode_mimewords() default ISO-8859-1,2 b");

is(MIME::AltWords::encode_mimewords("[nekem] m\x{E1}sik pr\x{F3}b\x{E1}cska\n"),
  "=?ISO-8859-1?Q?[nekem]_m=E1sik_pr=F3b=E1cska?=\n", "encode_mimewords() default ISO-8859-1 c");

is(MIME::AltWords::decode_mimewords('=?US-ASCII?Q?Keith_Moore?= <moore@cs.utk.edu>'), 'Keith Moore <moore@cs.utk.edu>', "MIME::Words test case 1");
is(MIME::AltWords::decode_mimewords('=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>'), 'Keld Jørn Simonsen <keld@dkuug.dk>', "MIME::Words test case 2");
is(MIME::AltWords::decode_mimewords('=?ISO-8859-1?Q?Andr=E9_?= Pirard <PIRARD@vm1.ulg.ac.be>'), 'André  Pirard <PIRARD@vm1.ulg.ac.be>', "MIME::Words test case 3");
is(MIME::AltWords::decode_mimewords('=?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?==?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?==?US-ASCII?Q?.._cool!?='), 'If you can read this you understand the example... cool!', "MIME::Words test case 4");
is(MIME::AltWords::encode_mimewords("\xABFran\xE7ois\xBB"), '=?ISO-8859-1?Q?=ABFran=E7ois=BB?=', "MIME::Words test case 5");
is(MIME::AltWords::encode_mimewords("Me and \xABFran\xE7ois\xBB at the beach"), '=?ISO-8859-1?Q?Me_and_=ABFran=E7ois=BB_at_the_beach?=', "MIME::Words test case 6");
# vvv !! is this correct (space after \n)?
is(MIME::AltWords::encode_mimewords("Me and \xABFran\xE7ois\xBB, down at the beach\nwith Dave <dave\@ether.net>"), "=?ISO-8859-1?Q?Me_and_=ABFran=E7ois=BB,_down_at_the_beach=0Awith?=\n =?ISO-8859-1?Q?_Dave_<dave\@ether.net>?=", "MIME::Words test case 7");
is(MIME::AltWords::decode_mimewords(MIME::AltWords::encode_mimewords("Me and \xABFran\xE7ois\xBB, down at the beach\nwith Dave <dave\@ether.net>")), "Me and \xABFran\xE7ois\xBB, down at the beach\nwith Dave <dave\@ether.net>", "MIME::Words test case 8");

my $in0 = Encode::encode("windows-1251", "\x{422}\x{435}\x{441}\x{442}\x{438}\x{440}\x{43e}\x{432}\x{430}\x{43d}\x{438}\x{435}");
my $out0b = "=?WINDOWS-1251?B?0uXx8ujw7uLg7ejl?=";
my $out0q = "=?WINDOWS-1251?Q?=D2=E5=F1=F2=E8=F0=EE=E2=E0=ED=E8=E5?=";
is(MIME::AltWords::encode_mimewords($in0, Charset=>"windows-1251", Encoding=>"B"), $out0b);
is(MIME::AltWords::encode_mimewords($in0, Charset=>"windows-1251", Encoding=>"Q"), $out0q);
is(MIME::AltWords::encode_mimewords($in0, Charset=>"windows-1251", Encoding=>"q"), $out0q);
is(MIME::AltWords::encode_mimeword($in0, "B", "windows-1251"), $out0b);
is(MIME::AltWords::encode_mimeword($in0, "Q", "windows-1251"), $out0q);
is(MIME::AltWords::encode_mimeword($in0, "q", "windows-1251"), $out0q);
is(MIME::AltWords::encode_mimewords($in0, Charset=>"windows-1251", Encoding=>"b"), $out0b);
is(MIME::AltWords::encode_mimeword($in0, "b", "windows-1251"), $out0b);

=cut

1
