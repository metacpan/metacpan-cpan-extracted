#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use File::Versions 'make_backup';
my $backup = make_backup ("$Bin/file");
# If the environment variable 'VERSION_CONTROL' is set to
# 'numbered', 'file' is moved to 'file.~1~'. The value of the new
# file name is put into '$backup'.

