# IUP::Matrix (callback mode) example

use strict;
use warnings;

use IUP ':all';
use Data::Dumper;

my $matrix = IUP::Matrix->new(
    NUMLIN=>3,
    NUMCOL=>3,
    NUMLIN_VISIBLE=>3,
    NUMCOL_VISIBLE=>3,
    HEIGHT0=>10, #IMPORTANT: this tells IUP::Matrix that we are gonna have column titles at line 0
    WIDTHDEF=>30,
    SCROLLBAR=>"NO",
);

my $titles = [ "Col.A", "Col.B", "Col.C" ];

my $data = [
   [ 1.1, 1.2, 1.3 ],
   [ 2.1, 2.2, 2.3 ],
   [ 3.1, 3.2, 3.3 ],
 ];

$matrix->VALUE_CB( sub {
  my ($self, $l, $c) = @_;
  #warn "VALUE_CB: l=$l, c=$c\n";
  if ($l>0 && $c>0) {
    return $data->[$l-1]->[$c-1]; #BEWARE: data starts at index $l==1,$c==1
  }
  elsif ($l==0 && $c>0) {
    # column title
    return $titles->[$c-1];
  }
  return;  
} );

$matrix->VALUE_EDIT_CB( sub {
  my ($self, $l, $c, $newvalue) = @_;
  #warn "VALUE_EDIT_CB: l=$l, c=$c, newvalue=$newvalue\n";
  $data->[$l-1]->[$c-1] = $newvalue;
} );

my $dlg = IUP::Dialog->new( child=>$matrix, TITLE=>"IUP::Matrix in Callback Mode" );
$dlg->Show();

IUP->MainLoop;
