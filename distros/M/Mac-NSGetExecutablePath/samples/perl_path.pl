#!perl

use strict;
use warnings;

use blib;

use Cwd 'abs_path';

my $path;

if ($^O eq 'darwin') {
 require Mac::NSGetExecutablePath;
 $path = Mac::NSGetExecutablePath::NSGetExecutablePath();
} else {
 $path = $^X;
}

print abs_path($path), "\n";
