#!/usr/local/bin/perl -w
###########################################################################
# File    - test.pl
#	    Created 12 Feb, 2000, Brent B. Powers
#
# Purpose - test for Memoize::ExpireLRU
#
# ToDo    - Test when tied to other module
#
#
###########################################################################
use strict;
use Memoize;

my $n = 0;
use vars qw($dbg);
$dbg = 0;
$| = 1;

print "1..46\n";

use Memoize::ExpireLRU;
++$n;
print "ok $n\n";

my %CALLS = ();
sub routine ( $ ) {
    return shift;
}
sub routine3 ( $ ) {
    return shift;
}

my($flag) = 1; ## 1 gives routine2 as a list, 0 as a scalar
sub routine2 ( $ ) {
    if ($flag) {
	my($z) = shift;
	return (1, $z);
    } else {
	return shift;
    }
}

sub show ( $ ) {
    print "not " unless shift;
    ++$n;
    print "ok $n\n";
}

{
tie my %cache, 'Memoize::ExpireLRU',
         CACHESIZE => 4,
         TUNECACHESIZE => 6,
         INSTANCE => 'routine',
         ;
memoize('routine',
	SCALAR_CACHE => ['HASH' => \%cache],
	LIST_CACHE => 'FAULT');
}

if ($flag) {
    tie my %cache, 'Memoize::ExpireLRU',
        CACHESIZE => 1,
        TUNECACHESIZE => 5,
        INSTANCE => 'routine2';
    memoize('routine2',
	    LIST_CACHE   => ['HASH' => \%cache],
	    SCALAR_CACHE => 'FAULT',);
} else {
    tie my %cache, 'Memoize::ExpireLRU',
        CACHESIZE => 1,
        TUNECACHESIZE => 5,
        INSTANCE => 'routine2';
    memoize('routine2',
	    SCALAR_CACHE => ['HASH' => \%cache],
	    LIST_CACHE   => 'FAULT');
}

{
tie my %cache, 'Memoize::ExpireLRU',
    CACHESIZE => 4,
    INSTANCE => 'routine3';
memoize('routine3',
	SCALAR_CACHE => ['HASH' => \%cache],
	LIST_CACHE   => 'FAULT');
}

$Memoize::ExpireLRU::DEBUG = 1;
$Memoize::ExpireLRU::DEBUG = 0;
show(1);

# 3--6
## Fill the cache
for (0..3) {
    show(routine($_) == $_);
    $CALLS{$_} = $_;
}


# 7--10
## Ensure that the return values were correct
for (keys %CALLS) {
    show($CALLS{$_} == (0,1,2,3)[$_]);
}

# 11--14
## Check returns from the cache
for (0..3) {
  show(routine($_) == $_);
}

# 15--18
## Make sure we can get each one of the array
foreach (0,2,0,0) {
    show(routine($_) == $_);
}

## Make sure we can get each one of the aray, where the timestamps are
## different
my($i);
for (0..3) {
#     sleep(1);
    $i = routine($_);
}

# 19
show(1);

# 20-23
for (0,2,0,0) {
    show(routine($_) == $_);
}

## Check getting a new one
## Force the order
for (3,2,1,0) {
    $i = routine($_);
}

# 24--25
## Push off the last one, and ensure that the
## one we pushed off is really pushed off
for (4, 3) {
    show(routine($_) == $_);
}


# 26--30
## Play with the second function
## First, fill it
my(@a);
for (5,4,3,2,1,0) {
    if ($flag) {
	show((routine2($_))[1] == $_);
    } else {
	show($_ == routine2($_));
    }
}


## Now, hit each of them, in order
# 31 -- 35
## Force at least one cache hit
if ($flag) {
    @a = routine2(0);
} else {
    routine2(0);
}

for (1..4) {
    if ($flag) {
	show((routine2($_))[1] == $_);
    } else {
	show($_ == routine2($_));
    }
}

## 36-44
for (0,1,2,3,4,5,5,4,3) {
    show($_ == routine3($_));
}

my($q) = <<EOT;
routine2:
    Cache Keys:
        '4'
    Test Cache Keys:
        '3'
        '2'
        '1'
        '0'
EOT

# 45
show($q eq Memoize::ExpireLRU::DumpCache('routine2'));

$q = <<EOT;
ExpireLRU Statistics:

                   ExpireLRU instantiation: routine
                                Cache Size: 4
                   Experimental Cache Size: 6
                                Cache Hits: 20
                              Cache Misses: 6
Additional Cache Hits at Experimental Size: 1
                             Distribution : Hits
                                        0 : 3
                                        1 : 2
                                        2 : 5
                                        3 : 10
                                     ----   -----
                                        4 : 1
                                        5 : 0

                   ExpireLRU instantiation: routine2
                                Cache Size: 1
                   Experimental Cache Size: 5
                                Cache Hits: 1
                              Cache Misses: 10
Additional Cache Hits at Experimental Size: 4
                             Distribution : Hits
                                        0 : 1
                                     ----   -----
                                        1 : 1
                                        2 : 1
                                        3 : 1
                                        4 : 1
EOT

# 46
show($q eq Memoize::ExpireLRU::ShowStats);
