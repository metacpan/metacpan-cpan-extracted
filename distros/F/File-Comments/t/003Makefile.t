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
use File::Comments::Plugin;

my $eg = "eg";
$eg = "../eg" unless -d $eg;

my $snoop = File::Comments->new();

######################################################################
my $tmpfile = "$eg/Makefile";
END { unlink $tmpfile }
blurt(<<EOT, $tmpfile);
# First comment
all:
	cc foo bar
# Second
# Third
EOT

my $chunks = $snoop->comments($tmpfile);

ok($chunks, "find make comments");
is($chunks->[0], " First comment", "hashed comment");
is($chunks->[1], " Second", "hashed comment");
is($chunks->[2], " Third",   "hashed comment");

my $stripped = $snoop->stripped($tmpfile);
is($stripped, "all:\n\tcc foo bar\n", "stripped comments");
