=head1 NAME

Gtk2::CV::PostScript - a class for writing postscript files

=head1 SYNOPSIS

  use Gtk2::CV::PostScript;

  # nothing gets exported

=head1 DESCRIPTION

=head2 FUNCTIONS

=over 4

=cut

package Gtk2::CV::PostScript;

use common::sense;
use Carp;

my @papersize = map [
                       $_->[0],
                       $_->[1],
                       __PACKAGE__->ps2mm (@_[2,3]),
                    ],
(
   ["maximize", "Maximize", 0, 0],
   ["a0", "A0", 2384, 3370], ["a1", "A1", 1684, 2384], ["a2", "A2", 1191, 1684],
   ["a3", "A3", 842, 1191], ["a4", "A4", 595, 842], ["a5", "A5", 420, 595],
   ["a6", "A6", 297, 420], ["a7", "A7", 210, 297], ["a8", "A8", 148, 210],
   ["a9", "A9", 105, 148], ["a10", "A10", 73, 105],

   ["b0", "B0", 2835, 4008], ["b1", "B1", 2004, 2835], ["b2", "B2", 1417, 2004],
   ["b3", "B3", 1001, 1417], ["b4", "B4", 709, 1001], ["b5", "B5", 499, 709],
   ["b6", "B6", 354, 499],

   ["c0", "C0", 2599, 3677], ["c1", "C1", 1837, 2599], ["c2", "C2", 1298, 1837],
   ["c3", "C3", 918, 1298], ["c4", "C4", 649, 918], ["c5", "C5", 459, 649],
   ["c6", "C6", 323, 459],

   ["jisb0", "B0 (jis)", 2920, 4127], ["jisb1", "B1 (jis)", 2064, 2920], ["jisb2", "B2 (jis)", 1460, 2064],
   ["jisb3", "B3 (jis)", 1032, 1460], ["jisb4", "B4 (jis)", 729, 1032], ["jisb5", "B5 (jis)", 516, 729],
   ["jisb6", "B6 (jis)", 363, 516],

   ["archE", "Arch E", 2592, 3456], ["archD", "Arch D", 1728, 2592], ["archC", "Arch C", 1296, 1728],
   ["archB", "Arch B", 864, 1296], ["archA", "Arch A", 648, 864],

   ["11x17", "11x17", 792, 1224], ["ledger", "Ledger", 1224, 792], ["legal", "Legal", 612, 1008],
   ["letter", "Letter", 612, 792], ["foolscap", "Fools Cap", 612, 936], ["halfletter", "Half Letter", 396, 612],
);

=item Gtk2::CV::PostScript::papersizes

Return an array of paper sizes. Each element contains an arrayref:

  [$name, $description, $width_mm, $height_mm]

i.e.:

   ["a0", "A0", 2384, 3370]

=cut

sub papersizes {
   @papersize
}

=item new Gtk2::CV::PostScript fh => $filehandle, pixbuf => $gdk_pixbuf_object, ...

 fh => $filehandle
 pixbuf => $pixbuf
 size =>
 aspect =>
 binary =>
 interpolate =>
 margin =>

=cut

sub new {
   my $class = shift;

   my $self = bless { @_ }, $class;

   $self->{fh} or croak "required argument 'fh' mising";
   $self->{pixbuf} or croak "required argument 'pixbuf' missing";

   $self;
}

sub mm2ps {
   shift; map $_ * (72 / 25.4), @_;
}

sub ps2mm {
   shift; map $_ * (2.54 / 72), @_;
}

=item $ps->print

Write the pixbuf.

=cut

sub print {
   my ($self) = @_;

   my $fh = $self->{fh};
   my $pb = $self->{pixbuf};

   my ($iw, $ih) = ($pb->get_width, $pb->get_height);

   $a = $self->{aspect} || $iw / $ih;

   my $mb = 1024 * 1024 * $self->{interpolate};

   $mb *= 4/5 unless $self->{binary};

   if ($mb) {
      if ($iw * $ih * 3 < $mb) {
         $iw = int 0.5 + sqrt $mb / ($a * 3);
         $ih = int 0.5 + $iw * $a;
         $pb = $pb->scale_simple ($iw, $ih, "hyper");
      }
   }

   $self->print_top;

   my ($w, $h) = $self->mm2ps ($self->{size} ? @{$self->{size}}[-2,-1] : (0, 0));

   $self->print_detectpage;

   if (my ($m) = $self->mm2ps ($self->{margin})) {
      print $fh <<EOF;
/x x $m 2 div add def /w w $m sub def
/y y $m 2 div add def /h h $m sub def
EOF
   }

   if ($w && $h) {
      print $fh <<EOF;
/x x w $w sub 2 div add def /w $w def
/y y h $h sub 2 div add def /h $h def
EOF
   }

   print $fh <<EOF;
/a $a def

a 1 gt w h div 1 gt eq
   {
     x y translate

     /W w def
     /H h def
   }
   {
     x w add y translate

     /W h def
     /H w def
     90 rotate
   }
ifelse

a W H div gt
  {
    W
    W a div
  }
  {
    H a mul
    H
  }
ifelse

2 copy
exch W sub neg 2 div
exch H sub neg 2 div translate
scale
    
$iw $ih 8
[ $iw 0 0 -$ih 0 $ih ]
EOF
   if ($self->{binary}) {
      my $operator = <<EOF;
currentfile
false 3
colorimage
EOF
      my $len = $iw * $ih * 3 + length $operator;
      print $fh "%%BeginData: $len Binary Bytes\n$operator";
      dump_binary $fh, $pb;
      print $fh "\n%%EndData\n";
   } else {
      print $fh <<EOF;
currentfile /ASCII85Decode filter
false 3
colorimage
EOF
      dump_ascii85 $fh, $pb;
   }

   $self->print_bot;
}

sub print_top {
   my ($self) = @_;

   # I use %%Page: xyz without the second agrument to get a better response
   # from gv. If this is a problem, mail me at <cv@plan9.de>.

   print {$self->{fh}} <<EOF;
%!PS-Adobe-3.0
%%Pages: 1
%%Creator: Gtk2::CV::PostScript
%%DocumentData: ${\($self->{binary} ? "Binary" : "Clean7Bit")}
%%LanguageLevel: 2
%%EndComments

%%Page: img

%%BeginPageSetup
/pgsave save def
%%EndPageSetup

EOF
}

sub print_detectpage {
   print {$_[0]{fh}} <<EOF;
newpath clippath pathbbox
/y2 exch def
/x2 exch def
/y exch def
/x exch def

/w x2 x sub def
/h y2 y sub def

EOF
}

sub print_bot {
   print {$_[0]{fh}} <<EOF;

pgsave restore
showpage

%%EOF
EOF
}

=back

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=cut

1
