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
my $tmpfile = "$eg/test.htm";
END { unlink $tmpfile }
blurt(<<EOT, $tmpfile);
<A HREF="foo">def<!--comment--></A>
<CENTER>
<HTML> <!--another comment--><!--and yet another
<A>--><B>
EOT

my $chunks = $snoop->comments($tmpfile);

is(scalar @$chunks, 3, "find HTML comments");
is($chunks->[0], "comment", "HTML comment");
is($chunks->[1], "another comment", "HTML comment");
is($chunks->[2], "and yet another\n<A>",   "HTML comment");

my $stripped = $snoop->stripped($tmpfile);
is($stripped, qq{<html><head></head><body><a href="foo">def</a><center> </center><b></b></body> </html>}, "stripped HTML comments");

