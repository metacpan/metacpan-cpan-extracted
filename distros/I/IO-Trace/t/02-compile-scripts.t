# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;

use Test::More;
my $perl_scripts = [ grep { `head -1 $_` =~ /perl/ } `cat MANIFEST` =~ m{^(?!lib/|t/)(\S+)}gm ];
plan tests => 0+@$perl_scripts;
foreach my $script (@$perl_scripts) {
    my $try = `$^X -c -Ilib $script 2>&1 | head`;
    chomp $try;
    ok (($try =~ /(syntax OK)/i), "compile $script: $try");
}
