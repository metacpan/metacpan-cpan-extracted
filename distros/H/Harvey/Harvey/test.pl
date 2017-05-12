#!/usr/bin/perl
# use 5.006;
use strict;
use warnings;
use Harvey;
my $L;
my $M;
my $H = Harvey->new();
$L = $H->rdialog("he would have like to have been able to be eager to work");

# get data that should match $L
while (<DATA>) {
    $M .= $_;
}

if ($M eq $L ) {
    print "Harvey: success\n";
}
else {
    print "Harvey: module failed test\n$L\n$M\n";
}


__DATA__
present subjunctive modality for the requirement modality for the perfect ability modality for the want modality for the infinitive of work
This is a statement
Verb pattern from left is: 00000000000000000001111111110110
Persons (3pl,2pl,1pl,3sing,2sing,1sing): 00000000000000000000000000111111
