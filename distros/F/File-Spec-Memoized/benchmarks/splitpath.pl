#!perl -w
use strict;
use Benchmark qw(:all);
use Config; printf "Perl/%vd (%s)\n", $^V, $Config{archname};

use File::Spec::Memoized;
BEGIN{
    package File::Spec::Original;
    our @ISA = @File::Spec::Memoized::ISA;
}

my $arg = $INC{'File/Spec.pm'};

print "For splitpath($arg)\n";

cmpthese timethese -1 => {
    'Original' => sub{
        foreach (1 .. 1000) {
            my @x = File::Spec::Original->splitpath($arg);
        }
    },
    'Memoized' => sub{
        foreach (1 .. 1000) {
            my @x = File::Spec::Memoized->splitpath($arg);
        }
    },
};

if(grep { $_ eq '--dump-cache' } @ARGV){
    require Data::Dumper;
    my $dd = Data::Dumper->new([File::Spec::Memoized->__cache], ['*cache']);
    $dd->Indent(1);
    $dd->Useqq(1);
    print $dd->Dump;
}
