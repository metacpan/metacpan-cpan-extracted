use strict;
use Embedix::ECD;

print "1..8\n";
my $test = 1;

# dealing with an undefined object
my $ecd  = Embedix::ECD->new(name => 'ecd');
my $kaka = $ecd->kaka();
print "not " if (defined $kaka);
print "ok $test\n";
$test++;

# building an object hierarchy
my $gr1 = Embedix::ECD::Group->new(name => 'system');
my $gr2 = Embedix::ECD::Group->new(name => 'utilities');
$ecd->addChild($gr1);
$ecd->system->addChild($gr2);
my $obj = $ecd->system->utilities;
print "not " if ($gr2->{name} ne $obj->{name});
print "ok $test\n";
$test++;

# instantiating an object w/ attribute values
my $busybox = Embedix::ECD::Component->new (
    name => 'busybox',
    srpm => 'busybox',
    help => 'swiss army knife or something',
);
print "not " if ($busybox->srpm ne 'busybox');
print "ok $test\n";
$test++;

# testing getNodeClass
$ecd->system->utilities->addChild($busybox);
print "not " if ($busybox->getNodeClass() ne "Component");
print "ok $test\n";
$test++;

# testing hasChildren
print "not " unless ($ecd->hasChildren());
print "ok $test\n";
$test++;

# testing hasChildren, again
print "not " if ($busybox->hasChildren());
print "ok $test\n";
$test++;

# testing evaluating getter methods
$busybox->storage_size("5000 + 40 800 + 203");
my ($size, $give_or_take) = $busybox->eval_storage_size;
print "not " unless ($size == 5040 && $give_or_take == 1003);
print "ok $test\n";
$test++;

# testing evaluating getter methods
$busybox->storage_size("5040");
($size, $give_or_take) = $busybox->eval_storage_size;
print "not " unless ($size == 5040 && $give_or_take == 0);
print "ok $test\n";
$test++;

# vim:syntax=perl
