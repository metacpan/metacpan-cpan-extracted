#!/usr/bin/perl
# 
# Very simple test to reduce file size

use File::SetSize;

 
$file_name = "blar.txt";
$keepatsize = 20; # in bytes

setsize($file_name,$keepatsize);
