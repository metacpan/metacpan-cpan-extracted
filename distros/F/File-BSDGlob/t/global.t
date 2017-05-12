#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

## why do I have to do this?!?
use lib qw( ./blib/lib ./blib/arch );
BEGIN {print "1..10\n";}
END {print "not ok 1\n" unless $loaded;}

BEGIN {
    *CORE::GLOBAL::glob = sub { "Just another Perl hacker," };
}

BEGIN {
    if ("Just another Perl hacker," ne (<*>)[0]) {
        die <<EOMessage;
Your version of perl ($]) doesn't seem to allow extensions to override
the core glob operator.
EOMessage
    }
}

use File::BSDGlob 'globally';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$_ = "t/*.t";
my @r = glob;
print "not " if $_ ne 't/*.t';
print "ok 2\n";

# we should have at least basic.t, global.t, taint.t
print "# |@r|\nnot " if @r < 3;
print "ok 3\n";

# check if <*/*> works
@r = <*/*.t>;
# at least t/global.t t/basic.t, t/taint.t
print "not " if @r < 3;
print "ok 4\n";
my $r = scalar @r;

# check if scalar context works
@r = ();
while (defined($_ = <*/*.t>)) {
    print "# $_\n";
    push @r, $_;
}
print "not " if @r != $r;
print "ok 5\n";

# check if array context works
@r = ();
for (<*/*.t>) {
    print "# $_\n";
    push @r, $_;
}
print "not " if @r != $r;
print "ok 6\n";

# test if implicit assign to $_ in while() works
@r = ();
while (<*/*.t>) {
    print "# $_\n";
    push @r, $_;
}
print "not " if @r != $r;
print "ok 7\n";

# test if explicit glob() gets assign magic too
my @s = ();
while (glob '*/*.t') {
    print "# $_\n";
    push @s, $_;
}
print "not " if "@r" ne "@s";
print "ok 8\n";

# how about in a different package, like?
package Foo;
use File::BSDGlob 'globally';
@s = ();
while (glob '*/*.t') {
    print "# $_\n";
    push @s, $_;
}
print "not " if "@r" ne "@s";
print "ok 9\n";

# test if different glob ops maintain independent contexts
@s = ();
while (<*/*.t>) {
    my $i = 0;
    print "# $_ <";
    push @s, $_;
    while (<*/*.t>) {
        print " $_";
        $i++;
    }
    print " >\n";
}
print "not " if "@r" ne "@s";
print "ok 10\n";
