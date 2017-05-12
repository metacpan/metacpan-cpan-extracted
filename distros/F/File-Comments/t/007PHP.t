######################################################################
# Test suite for File::Comments
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Sysadm::Install qw(:all);

BEGIN { use_ok('File::Comments') };

my $eg = "eg";
$eg = "../eg" unless -d $eg;

my $snoop = File::Comments->new();

######################################################################
my $tmpfile = "$eg/test.php";
END { unlink $tmpfile }
blurt(<<EOT, $tmpfile);
/* Some comment */
    // single
    // line
foo(); // in-line
}
/* multi
 * line
 * comment
 */
EOT

my $chunks = $snoop->comments($tmpfile);

ok($chunks, "find c comments");
is($chunks->[0], " Some comment ", "single line comment");
is($chunks->[1], " single", "single line comment");
is($chunks->[2], " line",   "single line comment");
is($chunks->[3], " in-line",   "in-line comment");
is($chunks->[4], " multi\n * line\n * comment\n ", "multi line comment");
