#!/usr/bin/perl

# Load postponed just to show postponed
use Data::Dumper;

sub foo {
    my $i;
    $i = 1_000_000;
    $i-- while $i > 0;
    return;
}

sub bar {
    my $a = "foobar";
    return \$a;
}

sub baz {
    sleep $_[0];
}

sub random {
    my @func = ( \&foo, \&bar, \&baz, \&random );
   
    $func[ rand @func ]->(@_);
} 

print "Running with pid: $$\n";

while(1) {
    foo();
    bar();
    baz(1);
    random(2);
}
