#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use HTML::Valid::Tagset '%isHTML5';
if ($isHTML5{canvas}) {
    print "<canvas> is OK.\n"; 
}
if ($isHTML5{a}) {
    print "<a> is OK.\n";
}
if ($isHTML5{plaintext}) {
    print "OH NO!"; 
}
else {
    print "<plaintext> went out with scrambled eggs.\n";
}
