#! /usr/bin/perl -w
# Basic test suite
# Copyright (c) 2019-2021 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 4 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
our ($LOCALEDIR, $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# bindtextdomain
$r = eval {
    my ($mo_file0, $mo_file1, $size, $atime, $mtime0, $mtime1);
    my ($FH, $content);
    
    $mo_file0 = catfile($LOCALEDIR, "en", "LC_MESSAGES", "test.mo");
    $mo_file1 = catfile($LOCALEDIR, "en", "LC_MESSAGES", "test-cache.mo");
    ($atime, $mtime0, $size) = (stat $mo_file0)[8,9,7];
    open $FH, $mo_file0                 or die "$mo_file0: $!";
    binmode $FH                         or die "$mo_file0: $!";
    read $FH, $content, $size           or die "$mo_file0: $!";
    close $FH                           or die "$mo_file0: $!";
    open $FH, ">$mo_file1"              or die "$mo_file1: $!";
    binmode $FH                         or die "$mo_file1: $!";
    print $FH $content                  or die "$mo_file1: $!";
    close $FH                           or die "$mo_file1: $!";
    $mtime1 = (stat $mo_file1)[9];
    utime $atime, $mtime0, $mo_file1    or die "$mo_file1: $!";
    
    require T_L10N;
    @_ = qw();
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test-cache", $LOCALEDIR);
    $_->textdomain("test-cache");
    $_[0] = $_->maketext("Hello, world!");
    
    # Update the file but keep the size and mtime
    open $FH, "+<$mo_file1"             or die "$mo_file1: $!";
    binmode $FH                         or die "$mo_file1: $!";
    read $FH, $content, $size           or die "$mo_file1: $!";
    $content =~ s/Hiya/HiYa/;
    seek $FH, 0, 0                      or die "$mo_file1: $!";
    print $FH $content                  or die "$mo_file1: $!";
    close $FH                           or die "$mo_file1: $!";
    utime $atime, $mtime0, $mo_file1    or die "$mo_file1: $!";
    $_->textdomain("test-cache");
    $_[1] = $_->maketext("Hello, world!");
    
    # Update the mtime
    utime $atime, $mtime1, $mo_file1    or die "$mo_file1: $!";
    $_->textdomain("test-cache");
    $_[2] = $_->maketext("Hello, world!");
    
    # Remove the file
    unlink $mo_file1                    or die "$mo_file1: $!";
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_[0], "Hiya :)");
# 3 - cache not updated
ok($_[1], "Hiya :)");
# 4 - cache updated
ok($_[2], "HiYa :)");
