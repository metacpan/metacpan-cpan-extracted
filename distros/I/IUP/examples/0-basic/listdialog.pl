# IUP->ListDialog example

use strict;
use warnings;

use IUP ':all';

my $marks = [0, 1, 0, 0, 1, 1, 0, 0];
my $options = ["Blue", "Red", "Green", "Yellow", "Black", "White", "Gray", "Brown"];

# single selection example
my $single = IUP->ListDialog("Color selection [SINGLE]", $options, 5, 8); # 5-selected item, 8-max_lines
if ($single<0) {
  IUP->Message("IupListDialog", "Operation canceled");
}
else {
  IUP->Message("Selected options", $options->[$single]);
}

# multi selection example
my @multi = IUP->ListDialog("Color selection [MULTI]", $options, $marks, 10, 20); # 10-max_lines, 20-max_cols
if ($multi[0]<0) {
  IUP->Message("IupListDialog", "Operation canceled");
}
else {
  my $selection = '';
  for my $i (0..scalar(@multi)-1) {    
    $selection .= $options->[$i] . "\n" if $multi[$i];
  }
  if ($selection eq '') {
    IUP->Message("IupListDialog", "No option selected");
  }
  else {
    IUP->Message("Selected options", $selection);
  }
}
