# IUP->Alarm() example
#
# Shows a dialog similar to the one shown when you exit a program without saving

use strict;
use warnings;

use IUP ':all';

my $b = IUP->Alarm("IupAlarm Example", "File not saved! Save it now?" ,"Yes" ,"No" ,"Cancel");

# Shows a message for each selected button
if ( $b == 1 ) {
  IUP->Message("Save file", "File saved successfully - leaving program");
}
elsif ( $b == 2 ) {
  IUP->Message("Save file", "File not saved - leaving program anyway");
}
elsif ( $b == 3 ) {
  IUP->Message("Save file", "Operation canceled");
}
