BEGIN { $| = 1; print "1..4\n"; }

use Devel::FindRef;
use Scalar::Util qw(weaken);

my $y;
my @y = (2, \$y, [4, 5, \$y, \$y], {a => \$y});
weaken $y[2][2];

#print
Devel::FindRef::track \$y;
print "ok 1\n";

sub THREE { 3 }

#print
Devel::FindRef::track \THREE;

print "ok 2\n";

my $sub; $sub = sub {
    if( $_[0] ) {
        my $x = \$_[0];
        --$$x;
        $sub->($_[0]);
    } else {
        #print
        Devel::FindRef::track \$_[0];
    }
};

my $level = 3;
$sub->($level);

print "ok 3\n";

sub {
    my $a = \$_[0];
    my $b = \$a;
    #print
    Devel::FindRef::track \$_[0];
}->(20);
print "ok 4\n";
