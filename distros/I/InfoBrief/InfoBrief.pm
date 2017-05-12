#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
# InfoBrief.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Dec  4 13:40:41 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu Jan 16 16:20:10 1997
# Language        : CPerl
# Update Count    : 79
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker$
# $Log$
# 

=head1 NAME

InfoBrief - Perl extension for printing envelopes for Infobrief mailings according to the standards of the Deutsche Bundespost 

=head1 SYNOPSIS

  use InfoBrief;
  $x = new InfoBrief %OPTIONS;
  print $x->preamble;
  print $x->page(@address);
  print $x->trailer;

=head1 DESCRIPTION

This modules is probably not very useful outside of Germany. It is a
tool dedicated for printing envelopes for Infobrief mailings according
to the standards of the Deutsche Bundespost. You may customize it for
other standards though.

The output generated is Postscript level 2 and conforms to EPSF 1.2.
Since C<copypage> ist used, the single pages contain only the new
address and running number and the size of the postscript file is
modest.

=head1 OPTIONS

The Constructor C<new> take a few options to customize the output:

=over 5

=item B<a4>

=item B<a5>

Generate A4 rsp. A5 output. Default is C5.

=item B<width> I<number>

=item B<height> I<number>

Custom output size. Units are Postscript dots (72 dpi).

=item B<border> I<number>

Set custom border size. Default is C<20>.

=item B<amt> I<string>

Set the Postamt for the "Entgelt bezahlt" stamp. Default is C<'44227
Dortmund 52'>.

=item B<stempel>

Add/Omit the "Entgelt bezahlt" stamp. Default is C<true>.

=item B<infobrief>

Add/Omit the "Infobrief" banner. Default is C<false> since the banner
is not required.

=item B<numbering>

Add/Omit a running number on each envelope. Default is C<true>. 

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@ls6.informatik.uni-dortmund.de>E<gt>

=head1 SEE ALSO

perl(1).

=cut

package InfoBrief;
use strict;
use vars qw($VERSION);

$VERSION = '0.14';

my $POSTAMT = '44227 Dortmund 52';
my $STEMPEL;
my $PROLOG;
# a4 paper size
my $a4_width  = 595;
my $a4_height = 842;
# a5 paper size
my $a5_width     = $a4_height/2;
my $a5_height    = $a4_width;
# c5 paper size
my $c5_width     = 459;
my $c5_height    = 649;

# b5j paper size
my $b5j_width     = 516;
my $b5j_height    = 729;

# b5 paper size
my $b5_width     = 499;
my $b5_height    = 708;

# c6 paper size (309,613)
my $c6_width     = 312;
my $c6_height    = 624;

my $border       = 20;
my $width        = $c5_width;
my $height       = $c5_height;
my $s_s          = 4;           # scale stamp
my $stempel      = 1;           # stamp 'Gebühr bezahlt'
my $infobrief    = 0;           # banner 'Infobief'
my $numbering    = 1;           # running numbers?
{
#  no strict;
  local ($/) = "\n%--\n";
  ($PROLOG, $STEMPEL) = <DATA>;
  close DATA;
  #$PROLOG =~ s/\$(\w+)/eval "\$$1"/eg;
}

my @sender = (
              'Fachbereich Informatik Lehrstuhl VI',
              'UNIVERSITÄT DORTMUND',
              'Aug.-Schmidt-Str. 12, 44221 Dortmund',
             );

sub preamble {
  my $self = shift;
  $self->{preamble};
}

sub new {
  my $type = shift;
  my %parm = @_;
  my $self = {};
  my $date = `date`;
  my $PROLOG = $PROLOG;

  chomp($date);

  if (exists $parm{a4}) {
    $width  = $a4_width;
    $height = $a4_height;
  } elsif (exists $parm{a5}) {
    $width  = $a5_width;
    $height = $a5_height;
  } elsif (exists $parm{b5}) {
    $width  = $b5_width;
    $height = $b5_height;
  } elsif (exists $parm{c6}) {
    $width  = $c6_width;
    $height = $c6_height;
  } 
  $self->{width}   = $parm{width}  || $width;
  $self->{height}  = $parm{height} || $height;
  $self->{border}  = $parm{border} || $border;
  my $amt          = $parm{amt}    || $POSTAMT;
  my $scale        = $parm{scale}  || $s_s;
  $self->{numbering} =
    ((exists $parm{numbering})?$parm{numbering}:$numbering)?'true':'false';
  $self->{stempel} =
    ((exists $parm{stempel})?$parm{stempel}:$stempel)?'true':'false';
  $self->{infobrief} =
    ((exists $parm{infobrief})?$parm{infobrief}:$infobrief)?'true':'false';
  $PROLOG =~ s/\$(\w+)/$self->{$1}/g;

  my @sender = @sender;
  if ($parm{sender}) {
    @sender = @{$parm{sender}};
  }
  my ($SENDER,$line);
  for ($line=0;$line<@sender;$line++) {
    $SENDER .= "$line ($sender[$line]) Cshow\n";
  }
  $self->{'preamble'} = <<EOF
%!PS-Adobe-2.0 EPSF-1.2
%%Title: (FGIR Umschlaege)
%%Pages: (atend)
%%Creator: $0
%%CreationDate: $date
%%BoundingBox: 0 0 $self->{width} $self->{height}
%%Pages: (atend)
%%EndComments

%%BeginProlog
$PROLOG
%%EndProlog

%%BeginSetup
Rotate {
0 $width 2 mul translate
-90 rotate
} if
% a5 background
Background
  {
    gsave
    newpath
    0 0 moveto
    $width $height  Rechteck
    0.95 setgray
    fill
    grestore
  } if

% STEMPEL
% P4 568 328

gsave
328 $scale div $border add $height 568 $scale div $border add sub translate
90 rotate
gsave
568 $scale div 328 $scale div scale
$STEMPEL
grestore
17 18 moveto
Stempel {
  /AvantGarde-Demi-ISO findfont 8 scalefont setfont
  ($amt) show
} {
  newpath
  0 0 moveto
  568 $scale div 328 $scale div Rechteck
  1 setgray
  fill
} ifelse
grestore
% LS6 Stempel
gsave
/AvantGarde-Demi-ISO findfont 9 scalefont setfont
%$border 3 mul $border 3 mul moveto
%90 rotate
$SENDER
grestore

% INFOBRIEF
Infobrief {
  gsave
  /AvantGarde-Demi-ISO findfont 28 scalefont setfont
  $border 3 mul $height 2 div (Infobrief) stringwidth pop 2 div sub moveto
  90 rotate
  (Infobrief) show
  grestore
  } if
%%EndSetup

EOF
  ;
  $self->{page} = 0;
  bless $self, $type;
}

my %DEC = ("„" => "ä",
        "" => "ü",
        "”" => "ö",
        '-'    => "­",
        "á"    => "ß",
        );

my $DEC = join '|', keys %DEC;

sub ps_string
{
   # Prepare text for printing
   local($_) = shift;
   s/($DEC)/$DEC{$1}/eg;
   s/[\\\(\)]/\\$&/g;
   s/[\001-\037\177-\377]/sprintf("\\%03o",ord($&))/ge;
   $_;    # return string
}

sub page {
  my $self = shift;
  $self->{page}++;
  my $page = <<EOP
%%Page: $self->{page} $self->{page}
%Begin page

gsave
newpath
Ax Ay moveto
150 250 $border add Rechteck
Background {0.95}  {1.0} ifelse
setgray
fill

% running number
Numbering {
   newpath
   $width $border 2 mul sub $border  2 mul moveto
   30 30 Rechteck
   Background {0.95}  {1.0} ifelse
   setgray
   fill
   
   0 setgray
   /AvantGarde-Demi-ISO
   findfont 8 scalefont setfont
   
   $width $border 2 mul sub $border 2 mul moveto
   ($self->{page}) show
} if

0 setgray
FNAMEFONT

EOP
;
  my $i;
  for ($i=0;$i<@_;$i++) {
    $page .= sprintf "%d (%s) Show\n", $i+1, ps_string($_[$i])
  }
  $page .= <<EOP
grestore
copypage
%End page
EOP
;
$page;
}

sub trailer {
  my $self = shift;
  <<EOT
%%Trailer
%%Pages: $self->{'page'}
EOT
;
}

__DATA__
/Ax $width  $border sub 100 sub 0.7 mul def
/Ay $height $border sub 250 sub def
/Numbering $numbering def
/Background false def
/Rotate false def
/Infobrief $infobrief def
/Stempel $stempel def                  % Entgelt bezahlt Stempel
/Show {
  gsave
  exch 15 mul
  Ax add Ay moveto
  90 rotate
  show
  grestore
} def

/Lx $border 2 mul def
/Ly 100 def
/Cshow {
  gsave
  1 index 15 mul
  Lx add
  Ly 2 index stringwidth pop 2 div sub
  moveto
  90 rotate
  show
  pop
  grestore
} def
  
/Rechteck
  {
    1 index 0 rlineto
    0 exch    rlineto
    neg     0 rlineto
    closepath
  } def

% Encoding
/NE { %def
   findfont begin
      currentdict dup length dict begin
         { %forall
            1 index/FID ne {def} {pop pop} ifelse
         } forall
         /FontName exch def
         /Encoding exch def
         currentdict dup
      end
   end
   /FontName get exch definefont pop
} bind def
ISOLatin1Encoding /AvantGarde-Demi-ISO		/AvantGarde-Demi NE
/FNAMEFONT {
  /AvantGarde-Demi-ISO
  findfont 14 scalefont setfont
} def

/rlestr1 1 string def
/readrlestring {
  /rlestr exch def
  currentfile rlestr1 readhexstring pop
  0 get
  dup 127 le {
    currentfile rlestr 0
    4 3 roll
    1 add  getinterval
    readhexstring pop
    length
  } {
    256 exch sub dup
    currentfile rlestr1 readhexstring pop
    0 get
    exch 0 exch 1 exch 1 sub {
      rlestr exch 2 index put
    } for
    pop
  } ifelse
} bind def
/readstring {
  dup length 0 {
    3 copy exch
    1 index sub
    getinterval
    readrlestring
    add
    2 copy le { exit } if
  } loop
  pop pop
} bind def
/picstr 71 string def

  
%--

568 328 1
[ 568 0 0 -328 0 328 ]
{ picstr readstring }
image
b9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ff
b9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ff
b9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9fffdff00fec100
0301fffffffdff00fec1000301fffffffdff00fec1000301fffffffdff00
fec1000301fffffffdff00fec1000301fffffffdff00fec1000301ffffff
fdff00fec1000301fffffffdff00fec1000301fffffffdff00fec1000301
fffffffdff01fe00c3ff04fe01fffffffdff01fe00c3ff04fe01fffffffd
ff01fe00c3ff04fe01fffffffdff02fe00f0c400040e01fffffffdff02fe
00f0c400040e01fffffffdff02fe00f0c400040e01fffffffdff02fe00f1
c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff
048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e
01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ff
fffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffffff
fdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff
02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe
00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1
c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff
048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e
01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ff
fffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffffff
fdff02fe00f1d1ff02f0001ff6ff048e01fffffffdff02fe00f1d1ff0200
0001f6ff048e01fffffffdff02fe00f1d2ff04f80000003ff7ff048e01ff
fffffdff02fe00f1d2ff04c00000000ff7ff048e01fffffffdff02fe00f1
d2ff048000000003f7ff048e01fffffffdff07fe00f1ffffc0007ff6ff01
fc1ffcff02fe0007f8ff04fe0ffffc01f8ff00fefb00f7ff048e01ffffff
fdff07fe00f1ffffc0001ffbff0007fcff01fc1ffcff02fe0001f8ff0dfc
07fff0007ffffffff0003ffff8fb000d3fffc0000001ffffff8e01ffffff
fdff07fe00f1ffffc0000ffbff0007fcff01fc1ffcff02fe0000fbff10f0
fffff807ffc0003ffffffff0003ffff0fb000d1fffc0000001ffffff8e01
fffffffdff07fe00f1ffffc0000ffbff0007fcff01fc1ffcff02fe0000fb
ff10f0fffff807ffc0001ffffffff0003fffe0fb000d0fffc0000001ffff
ff8e01fffffffdff07fe00f1ffffc1fe07fbff0007fcff01fc1ffcff03fe
0fe07ffcff10f0fffff803ff80f80ffffffff0001fff80fb000d07ffc000
0001ffffff8e01fffffffdff0dfe00f1ffffc1ff03fe1fffffff07fcff01
fc1ffcff03fe0ff07ffcff0ff0fffff003ff01fc0ffffffff0001ffffa00
0d03ffc0000001ffffff8e01fffffffdff2ffe00f1ffffc1ff03f003f0fe
1c00f803ff007c100ffc03fffe0ff03f807fe01f801ffff003ff07fe07ff
fffff0001ffef9000cffc0000001ffffff8e01fffffffdff43fe00f1ffff
c1ff83e001e0fe1c00e000fe003c0007f000fffe0ff03e001fc003801fff
f001fe07ff0ffffffff0001ffc00000fff000000ffc0000001ffffff8e01
fffffffdff26fe00f1ffffc1ff83c000e0fe1c00c000fc001c0003e0007f
fe0ff03c000f8003801fffe0c1fe07fbff17f0001ff800007fffe000007f
c0000001ffffff8e01fffffffdff26fe00f1ffffc1ff8180c0e0fe1f07c0
e078000c0001e0007ffe0ff07800070001f0ffffe0c0fe0ffbff17f0001f
f80001fffffc00003fc0000001ffffff8e01fffffffdff26fe00f1ffffc1
ff8183e060fe1f07c1f0703e0c1f81c0f03ffe0fe0781e0707c1f0ffffc0
c0fe0ffbff17f0001ff00003fffffe00001fc0000001ffffff8e01ffffff
fdff43fe00f1ffffc1ff8183f060fe1f07c1f8703e0c1fc1c1f83ffe0000
703f0307e1f0ffffc1e0fe0fe00ffffffff0001ff00007ffffff80001fc0
000003ffffff8e01fffffffdff43fe00f1ffffc1ff8383f060fe1f07c01f
f07ffc1fc1c1f83ffe0000f07f8301fff0ffffc1e07e0fe007fffffff000
1fe0000fffffffc0000fc0000003ffffff8e01fffffffdff43fe00f1ffff
c1ff83000060fe1f07c003f07ffc1fc1c0001ffe0001f07f83000ff0ffff
81e07e0fe007fffffff0001fc0001fffffffe0000fc0000003ffffff8e01
fffffffdff43fe00f1ffffc1ff83000060fe1f07e000f07ffc1fc1c0001f
fe0003f07f838007f0ffff81e07e0fe007fffffff0001fc0007ffffffff0
000fc0000003ffffff8e01fffffffdff43fe00f1ffffc1ff03000060fe1f
07f000707ffc1fc1c0001ffe0ffff07f83c001f0ffff80007e0ff807ffff
fff0001f80007ffffffff80007c0000007ffffff8e01fffffffdff30fe00
f1ffffc1ff0303ffe0fe1f07fe00707ffc1fc1c1fffffe0ffff07f83f001
f0ffff00003e07ff07fffffff0001f8000fcff0ef80003c0000007ffffff
8e01fffffffdff30fe00f1ffffc1fe0787ffe0fc1f07ffe0307f0c1fc1c1
fffffe0ffff07f83fe00f0ffff00003e07ff07fffffff8001f8000fcff0e
fc000380000007ffffff8e01fffffffdff30fe00f1ffffc1fc0783f0607c
1f0783f0303e0c1fc1c1fffffe0ffff07f030fc0f0fffe00001f03fe07ff
fffff8001f0001fcff0efe000380000007ffffff8e01fffffffdff30fe00
f1ffffc0000f81e060301f0381f0703c0c1fc1c0f03ffe0ffff81e0607e0
f0fffe07f81f01f807fffffff8000f0003fcff0efe000380000007ffffff
8e01fffffffdff30fe00f1ffffc0000fc000f0001f00c00078001c1fc1e0
003ffe0ffff800070381f07ffe0ffc1f800007fffffff8000f0003fbff0d
00038000000fffffff8e01fffffffdff30fe00f1ffffc0001fc000f0001f
80c0007c001c1fc1e0007ffe0ffffc000f0001f01ffe0ffc0fc00007ffff
fff8000e0003fbff0d00018000000fffffff8e01fffffffdff30fe00f1ff
ffc0007ff003f8021f80f000fe003c1fc1f800fffe0ffffe001f8003f01f
fc0ffc0fe00087fffffffc000e0003fbff0d00018000000fffffff8e01ff
fffffdff30fe00f1ffffc003fff807fc061fc0f803ff00fc1fc1fc01fffe
0fffff003fc007f81ffc1ffe0ff00187fffffffc000e0007fbff0d000100
00000fffffff8e01fffffffdff02fe00f1e7ff03e3fff87ffaff01fe07fc
ff04fc00060007fbff0d00010000001fffffff8e01fffffffdff02fe00f1
d7ff04fe00060007fbfffb00081fffffff8e01fffffffdff02fe00f1d7ff
04fe00020007fbfffb00083fffffff8e01fffffffdff02fe00f1d7ff04fe
00020007fbfffb00083fffffff8e01fffffffdff02fe00f1d6fffd000007
fbfffb00083fffffff8e01fffffffdff02fe00f1d6fffd000003fbfffb00
087fffffff8e01fffffffdff02fe00f1d6fffd000003fbfffb00087fffff
ff8e01fffffffdff02fe00f1d6ff0380000003fcff00fefb00fcff048e01
fffffffdff02fe00f1d6ff0380000003fcff00fefb00fcff048e01ffffff
fdff02fe00f1d6ff03c0000001fcff00fefc000001fcff048e01fffffffd
ff02fe00f1d6ff03c0000000fcff00fcfc000001fcff048e01fffffffdff
02fe00f1d6ff03e0000000fcff00f8fc000003fcff048e01fffffffdff02
fe00f1d6ff08e00000007ffffffff8fc000003fcff048e01fffffffdff02
fe00f1d6ff08f00000007ffffffff0fc000007fcff048e01fffffffdff02
fe00f1d6ff08f00000003fffffffe0fc00000ffcff048e01fffffffdff02
fe00f1d6ff08f80000001fffffffc0fc00001ffcff048e01fffffffdff02
fe00f1d6ff07fc0000000ffffffffb00001ffcff048e01fffffffdff02fe
00f1d6ff07fc00000007fffffefb00003ffcff048e01fffffffdff02fe00
f1d6ff07fe00000001fffff8fb00007ffcff048e01fffffffdff02fe00f1
d5fffc00027fffe0fb00fbff048e01fffffffdff02fe00f1d5ff05800000
000ffffb000001fbff048e01fffffffdff02fe00f1d5ff0080f6000003fb
ff048e01fffffffdff02fe00f1d5ff00e0f6000007fbff048e01fffffffd
ff02fe00f1d5ff00e0f600000ffbff048e01fffffffdff02fe00f1d5ff00
f0f600001ffbff048e01fffffffdff02fe00f1d5ff00fcf600007ffbff04
8e01fffffffdff02fe00f1d5ff00fef600faff048e01fffffffdff02fe00
f1d4fff7000001faff048e01fffffffdff02fe00f1d4ff00c0f8000007fa
ff048e01fffffffdff02fe00f1d4ff00e0f800000ffaff048e01fffffffd
ff02fe00f1d4ff00f0f800003ffaff048e01fffffffdff02fe00f1d4ff00
fcf800007ffaff048e01fffffffdff02fe00f1d3fff9000001f9ff048e01
fffffffdff02fe00f1d3ff00c0fa000007f9ff048e01fffffffdff07fe00
f1ffffc0001fd8ff00f0fa00001ff9ff048e01fffffffdff07fe00f1ffff
c0001ff8ff04f83fffff83f8ff03c1fffe0ff1ff00fcfa00007ff9ff048e
01fffffffdff0bfe00f1ffffc0001ffffff07ffcff04f83c1fff83f8ff03
c1fffe0ff3ff029c0ffffb000003f8ff048e01fffffffdff0bfe00f1ffff
c0001ffffff07ffcff04f83c1fff83f8ff04c1fffe0f07f5ff04fe000fff
f0fc00031ffff000fbff048e01fffffffdff0bfe00f1ffffc0001ffffff0
7ffcff04f83c1fff83f8ff04c1fffe0f07f5ff0dfc000ffffe00000001ff
fff8007ffcff048e01fffffffdff05fe00f1ffffc1fcff01f07ffcff04f8
3c1fff83f8ff04c1fffe0f07f5ff0df8003ffffff800003ffffffc001ffc
ff048e01fffffffdff14fe00f1ffffc1ffffff0ff07fe3fffe1ff83c1fff
83f8ff04c1fffe0f07f5ff02e0003ff8ff02fe000ffcff048e01fffffffd
ff21fe00f1ffffc1fffe0c03800f8043f803f82007ff8203ff807e0003f0
0fc180fe0c00f5ff02e0007ff7ff01000ffcff048e01fffffffdff21fe00
f1ffffc1fffe0001800f0001f001f82007ff8000fe001e0003c003c0007e
0c00f5ff01c000f6ff010003fcff048e01fffffffdff21fe00f1ffffc1ff
fe0000800e0001c000f82007ff80007c000e00038001c0003e0c00f5fffc
00090f80018001f000000001fcff048e01fffffffdff21fe00f1ffffc000
1e0000f07e0001c000783c1fff80003c000e00070001c0001e0c00f6ff00
fefc00091f00018000f000000001fcff048e01fffffffdff21fe00f1ffff
c0001e07c0f07c0f0181e0783c1fff80f0381e07ff0703c1c0781e0f07f6
ff00fcfc00051e0003c00078fc00087fffffff8e01fffffffdff21fe00f1
ffffc0001e07e0f07c1f8183f0783c1fff81f8183f07fe0f07c1c0fc1e0f
07f6ff00f0fc00053c0007e0003cfc00083fffffff8e01fffffffdff21fe
00f1ffffc0001e0fe0f0781f8183f0383c1fff81f8183f07fc0fffc1c0fc
1e0f07f6ff00f0fc00057c0007f0003cfc00083fffffff8e01fffffffdff
21fe00f1ffffc1fffe0fe0f0781fc18000383c1fff83fc100007f81ff801
c0fc1e0f07f6ff00f0fc0005f8001ff0001ffc00081fffffff8e01ffffff
fdff21fe00f1ffffc1fffe0fe0f0781fc18000383c1fff83fc100003f03f
c001c1fc1e0f07f6ff00f8fc0005f0001ffc000ffc00081fffffff8e01ff
fffffdff21fe00f1ffffc1fffe0fe0f0781fc18000383c1fff83fc100003
e07f8001c1fc1e0f07f6ff17fc00000001e0003ffc0007800000003fffff
ff8e01fffffffdff21fe00f1ffffc1fffe0fe0f0781f8183fff83c1fff83
fc103fffc0ff00c1c1fc1e0f07f6ff17fe00000003c0007ffe0007c00000
007fffffff8e01fffffffdff21fe00f1ffffc1fffe0fe0f07c1f8183fff8
3c1fff83f8183fff81ff07e1c1fc1e0f07f5fffd000a078000ffff0003e0
000000fcff048e01fffffffdff21fe00f1ffffc1fffe0fe0f07c1f8183ff
f83c1fff81f8383fff03fe07c1c1fc1e0f07f5ff0d8001ffff8000ffff80
01ffff0001fcff048e01fffffffdff21fe00f1ffffc0000e0fe0f00e0601
c1f0783c1fff80f0381f0603fe07c1c1fc1e0f07f5ff0dc001ffff0001ff
ff8000ffff0003fcff048e01fffffffdff21fe00f1ffffc0000e0fe0f00e
0001c000783c07ff80007c000400030701c1fc1e0f03f5ff0de000fffe00
03ffffc000fffe0007fcff048e01fffffffdff21fe00f1ffffc0000e0fe0
f00f0001e000f83c07ff80007c000c00030001c1fc1e0f00f5ff0df0007f
fc0007ffffe0007ffc000ffcff048e01fffffffdff21fe00f1ffffc0000e
0fe0f80f8001f001f83c07ff8000fe001c00030001c1fc1e0f80f5ff0df8
003ff8000ffffff0003ff8001ffcff048e01fffffffdff02fe00f1f7ff15
e181fc07f87e07ff8303ff807c0003c060c1fc1e0fc0f5ff0dfc001ff800
1ffffff8001ff0007ffcff048e01fffffffdff02fe00f1f6ff0083e1ff0c
fe000ff8003ffffff8001ff000fbff048e01fffffffdff02fe00f1f8ff02
fe3f83cfff048e01fffffffdff02fe00f1f8ff02fc0f03cfff048e01ffff
fffdff02fe00f1f8ff02fe0003cfff048e01fffffffdff02fe00f1f8ff02
fe0007cfff048e01fffffffdff02fe00f1f7ff01000fcfff048e01ffffff
fdff02fe00f1f7ff01e07fcfff048e01fffffffdff02fe00f1c4ff048e01
fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffff
fffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffd
ff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02
fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00
f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4
ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff04
8e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01
fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffff
fffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffd
ff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02
fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00
f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4
ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff04
8e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01
fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffff
fffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffd
ff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02
fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00
f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4
ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff04
8e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01
fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffff
fffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffd
ff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02
fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00
f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4
ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff04
8e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01
fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffff
fffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffd
ff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02
fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00
f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4
ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff04
8e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01
fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffff
fffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffd
ff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02
fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00
f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4
ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff04
8e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01
fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01ffff
fffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffd
ff02fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02
fe00f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00
f1c4ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f1c4
ff048e01fffffffdff02fe00f1c4ff048e01fffffffdff02fe00f0c40004
0e01fffffffdff02fe00f0c400040e01fffffffdff02fe00f0c400040e01
fffffffdff01fe00c3ff04fe01fffffffdff01fe00c3ff04fe01fffffffd
ff01fe00c3ff04fe01fffffffdff01fe00c3ff04fe01fffffffdff00fec1
000301fffffffdff00fec1000301fffffffdff00fec1000301fffffffdff
00fec1000301fffffffdff00fec1000301fffffffdff00fec1000301ffff
fffdff00fec1000301fffffffdff00fec1000301ffffffb9ffb9ffb9ffb9
ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9
ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9ffb9
ff
