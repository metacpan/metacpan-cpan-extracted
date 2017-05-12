package builder::MyBuilder;

use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';
use File::Which qw/which/;

die('Java must be installed and set in your PATH!') unless which('java');

my $java_version = qx(java -version 2>&1);
die $java_version if $java_version =~ /Error occurred during initialization of VM/i;

1;
