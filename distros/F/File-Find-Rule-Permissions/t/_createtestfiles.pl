#!perl

use strict;
use warnings;
use vars qw($testfiledir);

use File::Temp;

sub makefiles {
    my($user, $group) = @_;
    $testfiledir = File::Temp->newdir(CLEANUP => 1);
    foreach my $mode (0 .. 0777) {
        my $filename = sprintf("%04o", $mode);
        open(FILE, ">$testfiledir/$filename") ||
            die("Can't create $testfiledir/$filename: $!\n");
        print FILE $filename;
        close(FILE);
        if(defined($user) && $> == 0) { # if running as root ...
            chmod($mode, "$testfiledir/$filename");
            chown($user, $group, "$testfiledir/$filename");
        }
    }
}

1;
