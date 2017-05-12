#!/usr/bin/perl -w
use strict;
use Digest::JHash 'jhash';

if ($ARGV[0]) {
    if ( -f $ARGV[0] ) {
        local $/;
        open F, $ARGV[0] or die "Can't read $ARGV[0] $!\n";
        my $data = <F>;
        close F;
        printf "File: $ARGV[0] => %u\n", jhash($data);
    }
    else {
        printf "String: $ARGV[0] => %u\n", jhash($ARGV[0]);
    }
}
else {
    print "Usage $0 <file or string>\n";
}

