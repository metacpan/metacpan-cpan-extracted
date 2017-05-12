#!env perl
use File::Copy;
use File::Path;

mkpath 'bin';
copy('scripts/mcrcon.pl','bin/mcrcon.pl') or die("Could not create bin/mcrcon.pl");
chmod(0755,'bin/mcrcon.pl');

