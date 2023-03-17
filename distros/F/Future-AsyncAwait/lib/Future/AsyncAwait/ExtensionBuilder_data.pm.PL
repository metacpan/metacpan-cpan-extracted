#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

use v5.14;
use warnings;

open my $outh, ">", $ARGV[0] or
   die "Cannot write $ARGV[0] - $!\n";

local $/;

$outh->print( scalar do { <DATA> } );

$outh->print( scalar do {
   open my $in_h, "<", "lib/Future/AsyncAwait.h" or
      die "Cannot open AsyncAwait.h - $!";
   <$in_h> } );

__DATA__
package Future::AsyncAwait::ExtensionBuilder_data 0.65;

use v5.14;
use warnings;

# The contents of the "AsyncAwait.h" file
my $AsyncAwait_h = do {
   local $/;
   readline DATA;
};
sub ASYNCAWAIT_H() { $AsyncAwait_h }

0x55AA;

__DATA__
