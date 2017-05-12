# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Devel-Monitor.t'

######################################################
# IMPORTANT
# Set this variables to the number of tests to execute
######################################################

use Test::More tests => 0 + #BEGIN block
                        5 + #Devel::Monitor::monitor tests
                        13; #Devel::Monitor::print_circular_ref tests

######################################################

BEGIN { 
    #use_ok('Devel::Monitor', qw(:all));
    #use_ok('Error');
    #require_ok('Tie::Array');
    #require_ok('Tie::Hash');
    #require_ok('Tie::Scalar');
};

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#Devel::Monitor::monitor tests
ok(MonitorTests->testMonitorScalar(), 'monitor scalar');
ok(MonitorTests->testMonitorArray(), 'monitor array');
ok(MonitorTests->testMonitorHash(), 'monitor hash');
ok(MonitorTests->testMonitorCode(), 'monitor code');
ok(MonitorTests->testMonitorObject(), 'monitor object');

#Devel::Monitor::print_circular_ref tests
ok(MonitorTests->testPCRScalarWithoutCircRef(), 'print circular ref for a scalar without circular ref');
ok(MonitorTests->testPCRScalarWithBasicCircRef(), 'print circular ref for a scalar with a basic circular ref');
ok(MonitorTests->testPCRScalarWithCircRef(), 'print circular ref for a scalar with a circular ref');
ok(MonitorTests->testPCRArrayWithoutCircRef(), 'print circular ref for an array without circular ref');
ok(MonitorTests->testPCRArrayWithBasicCircRef(), 'print circular ref for an array with a basic circular ref');
ok(MonitorTests->testPCRArrayWithCircRef(), 'print circular ref for an array with a circular ref');
ok(MonitorTests->testPCRHashWithoutCircRef(), 'print circular ref for an hash without circular ref');
ok(MonitorTests->testPCRHashWithBasicCircRef(), 'print circular ref for an hash with a basic circular ref');
ok(MonitorTests->testPCRHashWithCircRef(), 'print circular ref for an hash with a circular ref');
ok(MonitorTests->testPCRCode(), 'print circular ref for some code');
ok(MonitorTests->testPCRObjectWithoutCircRef(), 'print circular ref for an object without a circular ref');
ok(MonitorTests->testPCRObjectWithCircRef(), 'print circular ref for an object with a circular ref');
ok(MonitorTests->testPCR(), 'print circular ref');

package MonitorTests;
use strict;
use warnings;

use Devel::Monitor qw(:all);

use constant CONST => [1,2,3];

#We only verify that the code works
sub testMonitorScalar {
    my $a = 'value';
    monitor('var $a' => \$a);
    return 1;
}

#We only verify that the code works
sub testMonitorArray {
    my @a;
    $a[5] = \@a;
    monitor('var @a' => \@a);
    return 1;
}

#We only verify that the code works
sub testMonitorHash {
    my %a;
    $a{key} = \%a;
    monitor('var %a' => \%a);
    return 1;
}

#We only verify that the code works
sub testMonitorCode {
    monitor('var CONST' => \&CONST);
    return 1;
}

sub testMonitorObject {
    my $a = ClassA->new();
    my $b = $a->getClassB();
    monitor('var $b' => \$b);
    return 1;    
}

sub testPCRScalarWithoutCircRef {
    my $a;
    print_circular_ref(\$a);
    return 1;
}

sub testPCRScalarWithBasicCircRef {
    my $a;
    $a = \$a;
    print_circular_ref(\$a);
    return 1;
}

sub testPCRScalarWithCircRef {
    my ($a, $b, $c);
    $a = \$b;
    $b = \$c;
    $c = \$a;
    print_circular_ref(\$a);
    return 1;
}

sub testPCRArrayWithoutCircRef {
    my @a;
    print_circular_ref(\@a);
    return 1;
}

sub testPCRArrayWithBasicCircRef {
    my @a;
    $a[3] = \@a;
    print_circular_ref(\@a);
    return 1;
}

sub testPCRArrayWithCircRef {
    my (@a, @b, @c, @d);
    $a[1] = \@d;
    $a[5] = 123;
    $a[2] = \@b;
    $b[0] = 123;
    $b[1] = \@c;
    $c[99] = \@a;
    print_circular_ref(\@a);
    return 1;
}

sub testPCRHashWithoutCircRef {
    my %a;
    print_circular_ref(\%a);
    return 1;
}

sub testPCRHashWithBasicCircRef {
    my %a;
    $a{key} = \%a;
    print_circular_ref(\%a);
    return 1;
}

sub testPCRHashWithCircRef {
    my (%a, %b, %c, %d);
    $a{A} = \%d;
    $a{E} = 123;
    $a{B} = \%b;
    $b{zero} = 123;
    $b{A} = \%c;
    $c{99999} = \%a;
    print_circular_ref(\%a);
    return 1;
}

sub testPCRCode {
    print_circular_ref(\&CONST);
    return 1;
}

sub testPCRObjectWithoutCircRef {
    my $a = ClassA->new();
    print_circular_ref(\$a);
    return 1;
}

sub testPCRObjectWithCircRef {
    my $a = ClassA->new();
    my $b = $a->getClassB();
    print_circular_ref(\$a);
    return 1;
} 

##DOC 

=head2 testPCR

DESC |-----|-->a
     |     | / \
     |     |/   \
     |---->b    g
     |    / \  / \
     |   /   \/   \
     |  c<---d     h<--|
     | /            \  |
     e              i--|

     Note : Vertical lines goes up
     
     # Starting with _classB
     a,b,c,e,a (Loop on a)
     a,b,c,e,b (Loop on b)
     a,b,a     (Loop on a)
     a,b,d,e,a (Loop on a)
     a,b,d,e,b (Loop on b)
     # Starting with A1
     a,b,c,e,a (Loop on a)
     a,b,c,e,b (Loop on b)
     a,b,a     (Loop on a)
     a,b,d,e,a (Loop on a)
     a,b,d,e,b (Loop on b)
     # Starting with A2
     a,g,d,c,e,a     (Loop on a)
     a,g,d,c,e,b,c   (Loop on c)
     a,g,d,c,e,b,a   (Loop on a)
     a,g,d,c,e,b,d,c (Loop on c)
     a,g,h,i,h       (Loop on h)

=cut

sub testPCR {
    my $a = ClassA->new();
    my $b = $a->getClassB();
    my ($c, $d, @e, @f, %g, $h, $i);
    $a->{A1} = \$b;
    $a->{A2} = \%g;
    $b->{B1} = \$c;
    $b->{B2} = \$d;
    $c = \@e;
    $e[0] = \$a; 
    $e[1] = \$b; 
    $d = \$c;     
    $g{G1} = \$d; 
    $g{G2} = \$h;
    $h = \$i;
    $i = \$h;
    print_circular_ref(\$a);
    return 1;
}

#--------------------------------------------------------------------
# ClassA (Just a class with the "printSomething" method)
#--------------------------------------------------------------------
 
package ClassA;
use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
 
sub new {
    my ($class) = @_;
    my $self = {};
    bless($self => $class);
    return $self;
}
 
sub getClassB {
    my $self = shift;
    $self->{_classB} = ClassB->new($self);
    return $self->{_classB};
}
 
sub printSomething {
    print "Something\n";
}
 
#--------------------------------------------------------------------
# ClassB (A class that got a "parent" which is a ClassA instance)
#--------------------------------------------------------------------
 
package ClassB;
use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
 
sub new {
    my ($class, $classA) = @_;
    my $self = {};
    bless($self => $class);
    $self->setClassA($classA);
    return $self;
}
 
sub setClassA {
    my ($self, $classA) = @_;
    $self->{_classA} = $classA;
}
 
sub getClassA {
    return shift->{_classA};
}