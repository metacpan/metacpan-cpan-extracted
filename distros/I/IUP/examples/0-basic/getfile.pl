# IUP->GetFile example
#
# Shows a typical file-selection dialog

use strict;
use warnings;

use IUP ':all';

IUP->SetLanguage("ENGLISH");
my ($err, $f) = IUP->GetFile("*.txt");

if ( $err == 1 ) {
  IUP->Message("New file", $f);
}
elsif ( $err == 0 ) {
  IUP->Message("File already exists", $f);
}
elsif ( $err == -1 ) {
  IUP->Message("GetFile", "Operation canceled");
}
elsif ( $err == -2 ) {
  IUP->Message("GetFile", "Allocation errr");
}
elsif ( $err == -3 ) {
  IUP->Message("GetFile", "Invalid parameter");
}
