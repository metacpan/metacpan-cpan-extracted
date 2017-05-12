use strict;
use Embedix::ECD;

print "1..1\n";
my $test = 1;

my $x = Embedix::ECD->newFromFile('t/data/tinylogin.ecd');
my $y = Embedix::ECD->newFromFile('t/data/embedix_gui.ecd');
my $z = Embedix::ECD->new(name => 'ecd');
my $za = Embedix::ECD::Group->new(name => 'System');
my $zb = Embedix::ECD::Group->new(name => 'Utilities');
my $zc = Embedix::ECD::Component->new(name => 'tinylogin', specpatch => 'foo');
$z->addChild($za);
$z->System->addChild($zb);
$z->System->Utilities->addChild($zc);
$x->mergeWith($y);
$x->mergeWith($z);
print "not " unless (
        $x->Applications->Browser->embedix_gui
    &&  $x->System->Utilities->tinylogin
    &&  $x->System->Utilities->tinylogin->specpatch() eq 'foo'
);
print "ok $test\n";
$test++;

# vim:syntax=perl
