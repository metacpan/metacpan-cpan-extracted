#!perl -w
use Math::JSpline;
my ($x)=&JSpline(1,0.5,0.5,3,[1,2,3,4]);
print join(" ",@{$x});
# returns 1.25 1.375 2 2.5 3 3.625 3.75 2.5 1.25
