######################################################################
# Test suite for Gaim::Log::Finder
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
use Gaim::Log::Finder;

my $EG = "eg";
$EG = "../eg" unless -d $EG;

use Test::More;

plan tests => 2;

my $canned = "$EG/canned/proto/from_user/to_user/2005-10-29.230219.txt";

my @found;
my $p = Gaim::Log::Finder->new(
    start_dir => "$EG/canned",
    callback  => sub { push @found, $_[1] if $_[1] =~ /219/},
);

$p->find();

is(scalar @found, 1, "1 txt files found");
like($found[0], qr/2005-10-29.230219/, "found txt file");
