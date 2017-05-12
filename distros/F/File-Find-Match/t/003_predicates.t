#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use Test::More;

my @Files = qw( Build.PL README );
my @Dirs  = qw( lib t );

plan tests => ( (@Files * 3) + (@Dirs * 3) + 8);


use File::Find::Match;
my $finder = new File::Find::Match;


# Test 'dir' named predicate
my $dirp = $finder->_make_predicate('-d');
foreach my $dir (@Dirs) {
    ok($dirp->($dir), "Testing 'dir' predicate on $dir");
}
foreach my $file (@Files) {
    ok(! $dirp->($file), "Testing 'dir' predicate on $file");
}



# Test 'file' named predicate.
my $filep = $finder->_make_predicate('-f');
foreach my $file (@Files) {
    ok($filep->($file), "Testing 'file' predicate on $file");
}
foreach my $dir (@Dirs) {
    ok(! $filep->($dir), "Testing 'file' predicate on $dir");
}

# Test filetest operators / eval of perl code.
my $rp = $finder->_make_predicate('-r');
foreach my $file (@Files, @Dirs) {
    ok($rp->($file), "Testing '-r' predicate on $file");
}

# Test regex.
my $regp = $finder->_make_predicate(qr/\.pod$/);
ok($regp->('foobar.pod'), 'Testing regex /\.pod$/ on foobar.pod');


# Make sure invalid eval'd perl code predicates die.
eval {
    $finder->_make_predicate('34234 < ! >');
};
if ($@) {
    pass("eval failed (good)");
} else {
    fail("eval did not fail (bad)");
}

# Should die if predicate is undefined.
eval {
    $finder->_make_predicate(undef);
};
if ($@) {
    pass("undef pred died. Yay!");
} else {
    fail("undef pred should die! Bah.");
}


# Should die if predicate is array or hashref.
eval {
    $finder->_make_predicate([]);
};
if ($@) {
    pass("[] pred died. Yay!");
} else {
    fail("[] pred should die! Bah.");
}

# Test code predicates.
my $true  = sub { 1 };
my $false = sub { 0 };
my $fun   = sub {
    # only matches filenames with even number of characters.
    my $file = shift;
    (length($file) % 2) == 0;
};

my $truep = $finder->_make_predicate($true);
my $falsep = $finder->_make_predicate($false);
my $funp = $finder->_make_predicate($fun);
ok($truep->(),      'code pred 1');
ok(!$falsep->(),    'code pred 2');
ok($funp->('quux'), 'code pred 3');
ok(!$funp->('bar'), 'code pred 3');




