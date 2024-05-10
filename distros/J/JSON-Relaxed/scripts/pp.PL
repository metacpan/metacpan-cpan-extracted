#!/usr/bin/perl

my $src = shift;
open( my $fd, ">", $src);
open( my $fi, "<", "$src.pl" );
for ( <$fi> ) {
    $_ = "\n" if /FindBin/;
    print { $fd } $_;
}
close($fd);
