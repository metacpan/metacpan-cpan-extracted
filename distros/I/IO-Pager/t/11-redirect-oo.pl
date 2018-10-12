use blib;
use IO::Pager;

our $txt; require './t/08-redirect.pl';

my $FH = new IO::Pager;
$FH->print($txt);
