use strict;
use warnings;
use Test::More tests => 2;

use Debian::Packages;
my $pkgs_file = Debian::Packages->new();

isa_ok($pkgs_file, 'Debian::Packages');
my @methods = qw(read);
map { can_ok($pkgs_file, $_) } @methods;
