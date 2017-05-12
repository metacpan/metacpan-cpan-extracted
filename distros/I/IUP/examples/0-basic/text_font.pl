# IUP::Text (font) example

use strict;
use warnings;

use IUP ':all';

my $l = IUP::List->new(
  DROPDOWN=>"YES",
  1 =>"HELVETICA_NORMAL_8",
  2 =>"COURIER_NORMAL_8",
  3 =>"TIMES_NORMAL_8",
  4 =>"HELVETICA_ITALIC_8",
  5 =>"COURIER_ITALIC_8",
  6 =>"TIMES_ITALIC_8",
  7 =>"HELVETICA_BOLD_8",
  8 =>"COURIER_BOLD_8",
  9 =>"TIMES_BOLD_8",
  10=>"HELVETICA_NORMAL_10",
  11=>"COURIER_NORMAL_10",
  12=>"TIMES_NORMAL_10",
  13=>"HELVETICA_ITALIC_10",
  14=>"COURIER_ITALIC_10",
  15=>"TIMES_ITALIC_10",
  16=>"HELVETICA_BOLD_10",
  17=>"COURIER_BOLD_10",
  18=>"TIMES_BOLD_10",
  19=>"HELVETICA_NORMAL_12",
  20=>"COURIER_NORMAL_12",
  21=>"TIMES_NORMAL_12",
  22=>"HELVETICA_ITALIC_12",
  23=>"COURIER_ITALIC_12",
  24=>"TIMES_ITALIC_12",
  25=>"HELVETICA_BOLD_12",
  26=>"COURIER_BOLD_12",
  27=>"TIMES_BOLD_12",
  28=>"HELVETICA_NORMAL_14",
  29=>"COURIER_NORMAL_14",
  30=>"TIMES_NORMAL_14",
  31=>"HELVETICA_ITALIC_14",
  32=>"COURIER_ITALIC_14",
  33=>"TIMES_ITALIC_14",
  34=>"HELVETICA_BOLD_14",
  35=>"COURIER_BOLD_14",
  36=>"TIMES_BOLD_14"
);

my $dg = IUP::Dialog->new( child=>$l );
$dg->TITLE("title");

my $dg2;

$l->ACTION( sub {
  my ($self, $t, $i, $v) = @_;

  $dg2->Hide if ($dg2);

  if ($v == 1) {
    my $ml = IUP::Text->new( MULTILINE=>'Yes', SIZE=>"200x200", VALUE=>"1234\nmmmmm\niiiii", FONT=>$t );
    $dg2 = IUP::Dialog->new( child=>$ml, TITLE=>$t );
    $dg2->Show();
    $self->SetFocus();
  }
} );

$dg->Show();

IUP->MainLoop;
