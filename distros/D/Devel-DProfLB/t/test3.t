# -*- perl -*-

print "1..1\n";
# read the tmon.out created by test2.t
open( F, "tmon.out" ) || die "cannot open tmon.out: $!\n";

# skip top header
while( <F> ){ last if /^PART2$/ }

my $et = 0;
my %f;
while( <F> ){
    chop;
    my @x = split;

    $et = $x[3];
    $f{$x[-1]} = 1;
}
close F;
unlink "tmon.out";


# make sure we saw all 3 funcs
if( $f{main::foo} && $f{main::bar} && $f{main::baz} ){
    print "ok 1\n";
}else{
    print "not ok 1\n";
}
