package Ecma48::Util;

use strict;
use warnings;
use 5.014;
# ^- * short names for control chars @ 5.14 (but full only in 5.16...)??XXX
#    * charnames::string_vianame @ 5.14
#    * s///r @ 5.14
#use feature ':5.10';
use Exporter 'import';
use Carp;
use charnames qw(:full :short);
#use Taint::Util 'untaint'; use Data::Dump 'dump';
our @EXPORT_OK=qw(remove_seqs move_seqs_before_lastnl split_seqs
                  ensure_terminating_nl remove_terminating_nl
                  quotectrl quote_ctrl quote_nongraph
                  ctrl_chars ctrl_regex seq_regex
                  remove_bs_bolding replace_bs_bolding closing_seq
                  remove_fillchars *PREFER_UNICODE_SYMBOLS); # $PREFER_UNICODE_SYMBOLS
our %EXPORT_TAGS=(ALL => [ grep /^[^*$@%]/,@EXPORT_OK ], # except vars
                  NL  => [qw(ensure_terminating_nl remove_terminating_nl
                             move_seqs_before_lastnl)],
                  DEL => [qw(remove_seqs remove_terminating_nl
                             remove_bs_bolding remove_fillchars)],
                  BS  => [qw(remove_bs_bolding replace_bs_bolding)],
                  QUOT=> [qw(quotectrl quote_ctrl quote_nongraph)],
                  INFO=> [qw(ctrl_chars closing_seq)],
                  RE  => [qw(ctrl_chars ctrl_regex seq_regex)],
                  VAR => [qw(*PREFER_UNICODE_SYMBOLS)]
                 );
%EXPORT_TAGS=(%EXPORT_TAGS, (map { lc $_ => $EXPORT_TAGS{$_} } keys %EXPORT_TAGS));

our $VERSION='0.01';

#~~ protos
sub closing_seq ($);
sub quotectrl ($); sub quote_ctrl ($);

#~~ Control variables
our $PREFER_UNICODE_SYMBOLS=0;

# ---------------------------------------------------------------------------

#~~ helper subs
#*** _name2code *** js<10.10.2012
our %metactrl=(DMI => '`', INT => 'a', EMI => 'b', RIS => 'c', CMD => 'd',
               LS2 => 'n', LS3 => 'o', LS3R => '|', LS2R => '}', LS1R => '~');
our %xtractrl=(EM => "\cY", IS4 => "\c\\", IS3 => "\c]", IS2 => "\c^", IS1 => "\c_",
                            FS  => "\c\\", GS  => "\c]", RS  => "\c^", US  => "\c_");
sub _name2code ($)
{ my $n=shift;
  #use charnames qw(:full :short);
  return $xtractrl{$n}      if exists $xtractrl{$n};
  return "\e".$metactrl{$n} if exists $metactrl{$n};
  return charnames::string_vianame($n);
}

#*** _code2name *** js<10.10.2012
sub _code2name ($)
{ use re 'taint';
  my $c=shift; my $name;
  state $n={ # EM as EOM, IS4..IS1 as FS GS RS US for "\N{...}" compliance
             # would prefer TAB over HT, but TAB not available before perl v5.16
             # also added PAD,HOP&IND&SGC, not part of ECMA48
             # SGC=SINGLE GRAPHIC CHARACTER INTRODUCER
            (#map { charnames::vianame($_)//undef => $_ }
             map { _name2code $_ => $_ }
             qw(NUL SOH STX ETX EOT ENQ ACK BEL BS  HT  LF  VT  FF  CR  SO SI
                DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EOM SUB ESC FS  GS  RS US
            DEL PAD HOP BPH NBH IND NEL SSA ESA HTS HTJ VTS PLD PLU RI SS2 SS3
                DCS PU1 PU2 STS CCH MW  SPA EPA SOS SGC SCI CSI ST  OSC PM APC))
           };
  $c=chr $c if $c=~/^\d+$/;
  $name=$n->{$c} if exists $n->{$c};
  $name//=$metactrl{$1} if $c=~/^\e(.)$/ && exists $metactrl{$1};
  $name//=charnames::viacode ord $c;
  #$name=~s/CHARACTER$/CHAR/;
  return $name;
}

#*** _re_clear *** js14.10.2012
#sub _re_clear (@) {
#  local $"='|'; my $re=@_==1 ? $_[0] : qr(@_);
#  my $ch=qr([^\\] | \\x[\dA-F]{2} | \\0[0-7]{0,3})xai;
#  $re=~s/(?:\(\?\^\w*?:|\|)\K ((?:$ch\|)+$ch) (?= \||\)$ )/'['.$1=~s(\|)()gr.']'/gex;
#  $re=~s/ (?<! [^\\] \\) \]\|\[//xg;
#  #return bless \$re, 'Regexp';
#  return $re; # qr($re)
#}
# s{(?:^[^:]*:|\|)\K ((?:[^\\]\|)+[^\\]) (?= \||\)$ )}{'['.$1=~s(\|)()gr.']'}gerx

#*** _ctrlcharvisu *** ausgelagert js15.10.2012
#* \e => \\e and so on, see quotectrl for more info
sub _ctrlcharsymb ($) # prefer unicode symbols
{ my $c=shift;
  return chr(0x2400+ord $c) if $c=~/[\00-\x20]/;
  return "\x{2421}" if $c eq "\x7F";
  return # No symbol available
}
sub _ctrlcharvisu ($)
{ state $h={ "\e" => '\\e', "\a" => '\\a', "\r" => '\\r',
             "\cH" => '\\cH', "\00" => '\\00' };
  my $c=shift; my $v; $v=$c if substr($c,-1)=~/^[\n\f\t]$/;
  $v//=_ctrlcharsymb($c) if $PREFER_UNICODE_SYMBOLS;
  $v//=$h->{$c} if exists $h->{$c};
  my $name=$v ? '' : _code2name $c;
  $v//=$name ? "\\N{$name}" : sprintf '\\x%02x', ord $c;
  return $v
}
# ---------------------------------------------------------------------------

#*** ctrl_chars, ctrl_regex ***  js<10.10.2012
#* return a regex with matches the Ctrlchars and its 7bit-Equivalents.
#* param: @_...as Names like CAN, as Number or as String
#*             A new param for each Ctrlchar is needed.
#* invariant: GIGO
sub ctrl_chars (@)
{ use charnames qw(:full :short);
  my @re=map { $_,  $_=~/^[\x80-\x9f]$/ ? "\e$_"^"\00\xC0" : () } # add 7bit
         map { $_=~/^\w\w|^U\+/a ? _name2code($_) :
               $_=~/^\d+$/a      ? chr($_)        : $_ } @_;
  local $"='|'; return wantarray ? @re : qr(@re)
}
sub ctrl_regex (@) { return scalar ctrl_chars @_ }

#{ use charnames qw(:full :short);
#  my $re=join '|',
#         map { $_,  $_=~/^[\x80-\x9f]$/ ? "\e$_"^"\00\xC0" : () } # add 7bit
#         map { $_=~/^\w\w|U\+/ ? _name2code($_) :
#               $_=~/^\d+$/     ? chr($_)        : $_ } @_;
#  return qr($re)
#}

#*** quotectrl *** js<10.10.2012
# comment: to it late to minify ... of diff. of what it does and what you thing it does.
sub quote_ctrl ($) # \r for \n, \n, \f, (NEL 0x85??), (DEL 0x7f??)
{ # [[:cntrl:]]?? instead [\00-\x1F\x7F-\x9F]? -v
  my $re=qr/((?:\r*\n)|[\00-\x1F\x7F-\x9F])/;
  return defined wantarray ? $_[0]=~s{$re}{ _ctrlcharvisu $1 }ger
                           : $_[0]=~s{$re}{ _ctrlcharvisu $1 }ge;
  #my $r=...; untaint $r; return $r;
}
*quotectrl=\&quote_ctrl;

sub quote_nongraph ($) # \r for \n, \n, \f, (NEL 0x85??), (DEL 0x7f??)
{ # [[:cntrl:]]?? instead [\00-\x1F\x7F-\x9F]? -v
  my $re=qr/((?:\r*\n)|[^[:graph:]])/;
  return defined wantarray ? $_[0]=~s{$re}{ _ctrlcharvisu $1 }ger
                           : $_[0]=~s{$re}{ _ctrlcharvisu $1 }ge;
  #my $r=...; untaint $r; return $r;
}

# ---------------------------------------------------------------------------

#*** seq_regex *** js<10.10.2012
my  $CSI=qr(\x9b|\e\[);          # ctrl_regex 'CSI'
my  ($OSC,$APC,$DCS,$PM)=(qr"\x9d|\e]",qr"\x9f|\e_",qr"\x90|\eP",qr"\x9e|\e^");
my  $XTD=qr($OSC|$APC|$DCS|$PM); # ctrl_regex qw(OSC APC DCS PM)
my  $SOS=qr(\x98|\eX);           # Start of String
my  $CAN=qr(\cX|\ea);            # CAN:\cX=\N{CAN}, INT:\ea, CMD:\ed
my  $SFT=    "\x0f\x0e";         # join '',ctrl_regex qw(SI SO); # Kap9
my  $XTDbase="\t-\r\x20-0x7e";
#my  $G01_94=qr([\x21-\x7E\xA1-\xFE]);
#my  $G01_96=qr([\x20-\x7F\xA0-\xFF]);
my  $FIN=qr([@-~]|$CAN); # for CSI: privat p-~ mostly [a-z\@[\]^|{}_`]
my  $ST =qr(\cG|\x9c|\e\\|$CAN); # ctrl_regex qw(ST ALERT CAN)
our $SEQ=qr{ $CSI [:<=>?]? [\d;]* [\x20-/]? $FIN
           | $XTD (?:[$SFT$XTDbase]* | [\xA0-\xFE$XTDbase]*) $ST
           | $SOS [^\x98\x9c]*?            $ST
           | \e   [\x20-/]*      (?:[0-~]|$CAN) }ixa; # was: [\x20-/;]*, why?

# \e[`-~] | \e[\x20-/]*[0-_]  vs. \e[\x20-/]*[0-~] because of DEC 2nd
# \e![0-~] ... no param in ECMA-48, but many stuff with ... outside exist

#*** seq_regex *** js<10.10.2012
sub seq_regex () { $SEQ }

#*** _flip *** js17.10.2012
#* replaces < with > and so on
sub _flip ($)
{ state $OPP={ 'REVERSED '=> '', map { my @r=split '/'; @r,reverse @r }
               qw(LESS/GREATER LEFT/RIGHT LEFTWARDS/RIGHTWARDS) };
  state $OPPm=join '|',keys $OPP;
  my ($s)=@_;
  return join '', map
  { my $r=$_;
    unless ($r=~tr!´`<>\[\](){}\\\/!`´><\]\[)(}{//!) # tr: \.../ but /.../
    { my $dir; my $cname=charnames::viacode ord;
      if ($cname=~/\b($OPPm)\b/oi)
      { if (($dir=$1) && exists $OPP->{$dir=$1})
        { $cname=~s/\Q$dir\E/$OPP->{$dir}/e;
          $r=charnames::string_vianame($cname)//$_;
        }
      }
      $r=charnames::string_vianame("REVERSED $cname")//$_
         if ord>0x100 && $r eq $_; # try if unicode and we have no success so far
         # XXX
    }
    $r
  } split '', $s;
}

#*** closing_seq *** js17.10.2012
#* find counterpart for opening sequence.
sub closing_seq ($)
{ my ($open)=@_;
  state $CLS={ (map { $_=>$_+20 } 2..5,7..9),  1 => 22,  6 => 25, 20 => 23,
               (map { $_ => 10  } 11..19),    51 => 54, 52 => 54, 53 => 55,
               (map { $_ => $_<40?39:49 } 30..37,40..47),
             };
  given ($open)
  { when (/^[^\x01-\x1F\x80-\x9F]*$/ && !/^[\d;]*?\d[\d;]*$/) # no control char inside
    { return '' if $_ eq '';
      my $opp=_flip($_); # reverse all: .oO _*/
      return reverse $opp if $opp ne $_ || m{[-°^*+~_/'"[:punct:]\s]};
      carp "Don't know a fitting closing pedant, use '$_' as-is.";
      return $_
    }
    when (/^($CSI)([\d;]+)m\z/) { return $1.closing_seq($2).'m' }
    when (/^($CSI[\d;]+)h\z/)   { return "${1}l" }
    when (/^\d+$/)
    { #say "debug: _=$_".dump $CLS;
      return $CLS->{0+$_} if exists $CLS->{0+$_};
      carp "Don't know a fitting closing sequence, use reset.";
      return 0;
    }
    when (/^[\d;]*;[\d;]*\z/)
    { return 39 if /^0*38;/; # XXX
      return 49 if /^0*48;/;
      return join ';',map { closing_seq(0+$_) } grep { $_ ne '' } split ';', $open;
    }
    default
    { carp "Don't know a fitting closing sequence.";
      return
    }
  }
}

# ---------------------------------------------------------------------------

#*** remove_seqs ***  js<10.10.2012
sub remove_seqs ($)
{ use re 'taint';
  return defined wantarray ? $_[0]=~s/$SEQ//gr : $_[0]=~s/$SEQ//g;
}

#*** split_seqs ***  js<10.10.2012
#* split string and return a list where escape seq are marked by being scalar references.
sub split_seqs ($) { map { /$SEQ/ ? \$_ : $_ } split /($SEQ)/,$_[0] }

sub move_seqs_before_lastnl ($)  # e.g. color before nl
{ use re 'taint'; my $re=qr/([\s\r\n])+($SEQ)+\s*\z/m;
  return defined wantarray ? $_[0]=~s/$re/$2$1/mr : $_[0]=~s/$re/$2$1/m;
}

sub ensure_terminating_nl ($) # if not only space
{ my $test=remove_seqs $_[0];
  my $nl= $test=~m/\r?\n\h*?\z/ || $test!~/\S/ ? '' : "\n";
  return $_[0].=$nl unless defined wantarray;
  return "$_[0]$nl"
}
sub remove_terminating_nl ($)
{ use re 'taint'; my $re=qr/\r?\n((?:\h|$SEQ)*?)\z/;
  #return $_[0]=~s/\r?\n((?:\h|$SEQ)*?)\z/$1/r;
  return defined wantarray ? $_[0]=~s/$re/$1/r : $_[0]=~s/$re/$1/;
}

#*** remove_fillchar *** js15.10.2012
#* return input with removed DEL, NUL and CRs directly before other CRs
#* removed: ... and SPACE-BS pairs if the are not inside a word.
sub remove_fillchars ($)
{ use re 'taint'; my $re=qr/[\00\x7F]|\r(?=\r)/; # |(?<!\w)\x20\cH|\x20\cH(?!\w)
  return defined wantarray ? $_[0]=~s/$re//gr : $_[0]=~s/$re//g;
}

#*** remove_bs_bolding *** js15.10.2012
sub remove_bs_bolding ($) # ecma-6 not part of ecma-48
{ use re 'taint'; my $re=qr/([[:graph:]])\cH(?=\g1)/;
  return defined wantarray ? $_[0]=~s/$re//gr : $_[0]=~s/$re//g;
}

#*** replace_bs_bolding *** js17.10.2012
sub replace_bs_bolding ($;$$$) # ecma-6 not part of ecma-48
{ use re 'taint';
  my $s=defined wantarray ? \do{ my $dummy=$_[0] } : \$_[0];
  my $b=$_[1]//1; my $e=$_[2]//closing_seq($b); my $i=$_[3]//'';
  for ($b,$e) { $_="\e[${_}m" if /^[\d;]+\z/ }
  #for ($$s) { s/([[:graph:]])(?:\cH\g1)+/$b$1$e/g; s/\Q$e$b//g; }
  my $emiss=0;
  $$s=~s{(?| ([[:graph:]])(?:(\cH)\g1)+ | (.)() )}
        { my $r;
          if (!$2) { $r=($emiss ? $e : '').$1; $emiss=0; }
          else     { $r=($emiss ? $i : $b).$1; $emiss=1; }
          $r
        }gsex;
  $$s.=$e if $emiss;
  return $$s;
}

# ---------------------------------------------------------------------------
'very reduced';

__END__

=head1 NAME

Ecma48::Util - A selection of subroutines supporting ANSI escape sequence handling

=head1 SYNOPSIS

    use Ecma48::Util qw(remove_seqs move_seqs_before_lastnl ... quotectrl);

    my $nude=quotectrl remove_bs_bolding remove_seqs remove_fillchars $decorated;

=head1 DESCRIPTION

C<Ecma48::Util> contains a selection of subroutines which allow the
handling of I<Ecma-48> based markup sequences - better known as
I<ANSI escape> sequences.

It helps to separate string handling from decorating.
If you can't change the order of processing and you are forced to do your
string handling after the decoration is already in effect, then you can
find some adequate utility functions here.

=head1 USE CASES

Do you like colors in your terminal? And a nice guy has written a plugin
to bring in the color - maybe with the help of C<Term::ANSIColor>?
Unfortunately, now things like C<chomp> and
testing if a string is empty do start to fail?
Then this module is worth a look.

=head1 FUNCTIONS

By default C<Ecma48::Util> does not export any subroutines. The
subroutines defined are

=over 4

=item remove_seqs STRING

C<remove_seqs> returns a string where well-formed Ecma48 sequences from STRING
are deleted.

    $foo = remove_seqs "color\e[34;1mful\e[m example"; # colorful example

Keep in mind that this is not the right tool for secure disarmament. Not all
terminal sequences are well-formed and most terminals also accept sequences with
some errors. See L<C<quotectrl>|/"quote_ctrl STRING">.

=item split_seqs STRING

C<split_seqs> splits string and returns a list where escape sequences
are marked by being scalar references.

    @foo = split_seqs "color\e[34;1mful\e[m example";
    # ( 'color', \"\e[34;1m", 'ful', \"\e[m", ' example' )

=item ensure_terminating_nl STRING

Does a newline exist at the end of the visible part? If not C<ensure_terminating_nl>
adds one.

    $foo = ensure_terminating_nl "color\e[34;1mful\e[m";   # add \n
    $foo = ensure_terminating_nl "color\e[34;1mful\n\e[m"; # as is
    $foo = ensure_terminating_nl "color\e[34;1mful\e[m\n"; # as is

=item remove_terminating_nl STRING

Similar to C<ensure_terminating_nl> but instead of making the string terminate
with newline, it makes the string open ended without a newline at the end.

    $foo = remove_terminating_nl "color\e[34;1mful\e[m";   # as is
    $foo = remove_terminating_nl "color\e[34;1mful\n\e[m"; # as in previous example
    $foo = remove_terminating_nl "color\e[34;1mful\e[m\n"; # ditto

=item move_seqs_before_lastnl STRING

Makes your STRING C<chomp>-friendly.

    $foo = move_seqs_before_lastnl "color\e[34;1mful\n\e[m";
    # "color\e[34;1mful\e[m\n"

=item quote_ctrl STRING

Replaces control characters with a visible representation.
Traditional linebreaks (C<\n>, C<\r\n>) are reasonable exceptions.
C<quotectrl> is an alias of C<quote_ctrl>.
When C<local $Ecma48::Util::PREFER_UNICODE_SYMBOLS=1> is set,
control chars from C0 (C<\00>..C<\x1F>) and DEL (C<\x7F>)
are displayed with their unicode symbol S<e.g. \x{241B}= E<0x241B>.>

    $foo = quotectrl "color\e[34;1mful\n\e[m";
    # "color\\e[34;1mful\n\\e[m"
    local $Ecma48::Util::PREFER_UNICODE_SYMBOLS=1;
    $foo = quotectrl "color\e[34;1mful\n\e[m";
    # "color\x{241B}[34;1mful\n\x{241B}[m"

=item quote_nongraph STRING

Like C<quote_ctrl>, except for all non printable characters.
The decision is based on C<[[:graph:]]> regex class, and so depends
on settings of the L<C<locale>|locale> pragma and the
L<C<unicode_strings> feature|feature/"the 'unicode_strings' feature">.

=item ctrl_chars LIST

C<ctrl_chars> returns the requested control characters or introducers.
LIST can consist of names, the char codes or the actual control characters.
Beside the coded char the eventually existing 7-bit equivalent is also
returned.
In scalar context it returns a regex catching all
requested sequence intros including their alternatives.

    @foo = ctrl_chars 'CSI'; # "\x9b", "\e\["
    $foo = ctrl_chars 'CSI'; # as qr/\x9b|\e\[/

Multiple control characters can be given to C<ctrl_chars> as separated
parameters.

=item seq_regex

C<seq_regex> returns a regex which catch Ecma-48 sequences.

=item remove_bs_bolding STRING

In the old days you could simulate bold printing with I<BackSpace> (C<\cH>)
and overstrike with the same character. Some Terminals of the 7-bit era
simulate this behavior of that kind of printer.

    $foo = remove_bs_bolding "A\cHA\cHAB\cHB\cHCD\cHD";        # "AB\cHCD"
    $foo = remove_bs_bolding "This was b\cHbo\cHol\cHld\cHd."; # "This was bold."

BS as combiner is defined in Ecma-6 and in Ecma-43 it is mentioned that
this should not be used in 8-bit environments. It is not part of Ecma-48.
However if you have to deal with terminal sequences, you may also have
to handle such issues.

=item replace_bs_bolding STRING, [PRE, [POST], [INTER]]

Like C<remove_bs_bolding> but allows you to mark the bold substrings
in other ways. Default is bright/bold mode.

    $foo = replace_bs_bolding "This is b\cHbo\cHol\cHld\cHd.";
    # "This is \e[1mbold\e[22m."
    $foo = replace_bs_bolding "This is b\cHbo\cHol\cHld\cHd.",'*';
    # "This is *bold*."
    $foo = replace_bs_bolding "This is b\cHbo\cHol\cHld\cHd.",1,0;
    # "This is \e[1mbold\e[0m."
    $foo = replace_bs_bolding "This is b\cHbo\cHol\cHld\cHd.",'','','_';
    # "This is b_o_l_d."

If you specify PRE but not POST this function tries to guess the closing
sequence.

=item closing_seq STRING

Tries to find the sequence which resets back again what STRING had changed.

    $foo = closing_seq "\e[2m";    # "\e[22m"
    $foo = closing_seq "\e[3h";    # "\e[3l"

Of course this is only an approximation, because no strict 1:1 mapping exists.
This function is also used internally by C<replace_bs_bolding>.

As a surplus it find counterparts for braces and so on.

    $foo = closing_seq '{[(';      # ')]}'
    $foo = closing_seq '.oO ';     # ' Oo.'
    $foo = closing_seq '==>>';     # '<<=='
    $foo = closing_seq '_*/';      # '/*_'
    $foo = closing_seq "\x{25C4}"; # "\x{25BA}"
    $foo = closing_seq "\x{2767}"; # "\x{2619}"

S<\x{25C4}= E<0x25C4>,> S<\x{25BA}= E<0x25BA>,>
S<\x{2767}= E<0x2767>,> S<\x{2619}= E<0x2619>>

=item remove_fillchars STRING

C<remove_fillchars> removes NUL (C<\00>) and DEL (C<\x7F>) characters.
Also CRs (C<\r>) which are placed directly for other CRs, because CR is
idempotent.

=back

=head1 IMPORT TAGS

C<:all> exports all functions, and C<:var> exports C<$PREFER_UNICODE_SYMBOLS>.

=head1 CAVEATS

=over 4

=item Mixed 7-bit/8-bit work-flow

This module does not entirely honor the extension to handle I<Ecma-35> artefacts
in 7-bit/8-bit transformation processes. If you have to work under such strange
circumstances, try to use this module before such stuff came into effect.

=item Escape sequences outside the Ecma48 universe

Some terminal commands violate/infringe the schema, and are not matched by these
routines.

=item Different handling compared to terminal (emulators)

Most terminals execute ill-formed codes after applying some error correction.
But these sequences are ignored by this module and are returned as-is.

=item Fill-chars inside escape sequences

The standard is unclear in this respect. Anyways, nowadays it shouldn't be an issue.
However an own function C<remove_fillchar> exists for preparation.

=back

=head1 KNOWN BUGS

Returns wrong results under character sets such as I<EBCDIC>.

=head1 SEE ALSO

L<Ecma-48|http://www.ecma-international.org/publications/files/ECMA/ST/Ecma-048.pdf>,
ISO 6429, ANSI X3.64,
L<A List of many Escape Sequences|http://bjh21.me.uk/all-escapes/all-escapes.txt>

=head1 LOOSELY RELATED

L<Term::ANSIColor>, L<Win32::Console::ANSI>

=head1 COPYRIGHT

(c) 2012 Josef. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
