######################################################################
# Test suite for File::Comments
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

BEGIN { use_ok('File::Comments') };

my $eg = "eg";
$eg = "../eg" unless -d $eg;

my $snoop = File::Comments->new();

######################################################################
my $tmpfile = "$eg/test.js";
END { unlink $tmpfile }
blurt(<<EOT, $tmpfile);
    // single
    // line
EOT

my $chunks = $snoop->comments($tmpfile);

is(scalar @$chunks, 2, "find javascript comments");
is($chunks->[0], " single", "single line comment");
is($chunks->[1], " line",   "single line comment");
