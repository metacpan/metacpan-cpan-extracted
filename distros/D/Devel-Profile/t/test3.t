# -*- perl -*-

print "1..2\n";
# read the prof.out created by test2.t
open( F, "prof.out" ) || die "cannot open prof.out: $!\n";

# skip top header
while( <F> ){ last if /^\s*$/ }

# skip info header
scalar <F>;

my $pt = 0;
my %f;
while( <F> ){
    chop;
    my @x = split;

    $pt += $x[0];
    $f{$x[-1]} = 1;
}
close F;
unlink "prof.out";

# make sure percents are ok
if( $pt < 98 || $pt > 102 ){
    print "not ok 1\n";
}else{
    print "ok 1\n";
}

# make sure we saw all 3 funcs
if( $f{main::foo} && $f{main::bar} && $f{main::baz} ){
    print "ok 2\n";
}else{
    print "not ok 2\n";
}
