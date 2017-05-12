#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV and $ARGV[0] =~ /^\s*--yes\s*/i) {
	print <<'HERE';
In order to recompile the Yapp.yp grammar, you need to install
the Parse::Yapp module and then run this script with the
  --yes
parameter *from this directory*.
HERE
	exit(1);
}

opendir(DH, '.') or die $!;
if (not grep {/^Yapp\.yp$/} readdir DH) {
	print "The program needs to be run from the Math::Symbolic\n"
	."distribution root directory.\n";
	exit(1);
}
close DH;

system('yapp -s -n -m Math::Symbolic::Parser::Yapp -o lib/Math/Symbolic/Parser/Yapp.pm Yapp.yp');

open my $fh, '+<', 'lib/Math/Symbolic/Parser/Yapp.pm' or die $!;
local $/ = undef;
my $code = <$fh>;
seek $fh, 0, 0;
truncate $fh, 0;
$code =~ s/(?<!# Module )Parse::Yapp::Driver/Math::Symbolic::Parser::Yapp::Driver/g;

print $fh <<HERE;
package Math::Symbolic::Parser::Yapp::Driver;
use strict;
our \$VERSION = '1.05';

HERE
print $fh $code;
close $fh;

print "Compilation successful.\n";

