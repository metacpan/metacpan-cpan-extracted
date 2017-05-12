use strict;
use Embedix::ECD;
use Data::Dumper;

print "1..5\n";
my $test = 1;

# construct parser singleton
my $parser = Embedix::ECD->parser();

# start w/ simple tests, and progress in difficulty

# comments
my $comment = Embedix::ECD->consFromFile('t/data/comment.ecd');
print "ok $test\n";
$test++;

# nodes qw(autovar group component option)
my $node = Embedix::ECD->consFromFile('t/data/node.ecd');
print "ok $test\n";
$test++;

# nodes containing attributes
my $attribute = Embedix::ECD->newFromFile('t/data/build_vars.ecd');
print "ok $test\n";
$test++;

# all at once embedix_gui.ecd
my $eb = Embedix::ECD->newFromFile('t/data/embedix_gui.ecd');
print "ok $test\n";
$test++;

# the dreated ltgt.ecd
my $ltgt = Embedix::ECD->newFromFile('t/data/ltgt.ecd');
print "ok $test\n";
$test++;


# vim:syntax=perl
