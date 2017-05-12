# IUP::MatrixList example

use strict;
use warnings;

use IUP ':all';

sub listclick_cb {
  my ($self, $lin, $col, $status) = @_;
  my $value = $self->GetAttribute($lin);
  $value = "NULL" if !$value;
  printf("click_cb(%d, %d)\n", $lin, $col);
  printf("  VALUE%d:%d = %s\n", $lin, $col, $value);
  return IUP_DEFAULT;
}

my $mlist = IUP::MatrixList->new(COUNT=>10, VISIBLELINES=>5, COLUMNORDER=>"LABEL:COLOR:IMAGE", EDITABLE=>"Yes", LISTCLICK_CB=>\&listclick_cb);

$mlist->SetAttribute(
        1 =>"AAA", COLOR1=>"255 0 0",   IMAGEVALUE1=>"ON",
        2 =>"BBB", COLOR2=>"255 255 0", IMAGEVALUE2=>"ON",
        3 =>"CCC", COLOR3=>"0 255 0",   IMAGEVALUE3=>"ON", ITEMACTIVE3=>"NO",
        4 =>"DDD", COLOR4=>"0 255 255",
        5 =>"EEE", COLOR5=>"0 0 255",
        6 =>"FFF", COLOR6=>"255 0 255",
        7 =>"GGG", COLOR7=>"255 128 0",                    ITEMACTIVE7=>"NO",
        8 =>"HHH", COLOR8=>"255 128 128",                  ITEMACTIVE8=>"NO",
        9 =>"III", COLOR9=>"0 255 128",
        10=>"JJJ", COLOR10=>"128 255 128",
);

# Shows dialog in the center of the screen
my $dlg  = IUP::Dialog->new( child=>IUP::Vbox->new(child=>$mlist), TITLE=>"IUP::MatrixList Example", MARGIN=>"10x10" );
$dlg->ShowXY (IUP_CENTER, IUP_CENTER);
IUP->MainLoop;