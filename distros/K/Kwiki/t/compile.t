use lib 't', 'lib';
use strict;
use warnings;
use Test::More 'no_plan'; 
use IO::All;

for (io('lib')->All_Files) {
    my $name = $_->name;
    $name =~ s/^lib\/(.*\.pm)$/$1/ or next;
    if ($name eq 'Kwiki/BrowserDetect.pm') {
        eval "require HTTP::BrowserDetect;1" or next;
    }
    eval "require '$name'; 1";
    is( $@, '', "Compile $name" );
}
