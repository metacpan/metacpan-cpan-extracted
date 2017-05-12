#!/usr/bin/perl
my %list = (
test2 =>
qq{  pool: test2
 state: ONLINE
  scan: resilvered 1.06G in 0h4m with 0 errors on Fri Aug 29 10:54:59 2014
config:

	NAME        STATE     READ WRITE CKSUM
	test2       ONLINE       0     0     0
	  raidz2-0  ONLINE       0     0     0
	    loop1   ONLINE       0     0     0
	    loop19  ONLINE       0     0     0
	    loop3   ONLINE       0     0     0
	    loop4   ONLINE       0     0     0
	    loop5   ONLINE       0     0     0

errors: No known data errors
},

test3 =>
qq{  pool: test3
 state: ONLINE
  scan: resilvered 21K in 0h0m with 0 errors on Fri Aug 29 11:36:48 2014
config:

	NAME        STATE     READ WRITE CKSUM
	test3       ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    loop6   ONLINE       0     0     0
	    loop7   ONLINE       0     0     0
	  mirror-1  ONLINE       0     0     0
	    loop8   ONLINE       0     0     0
	    loop9   ONLINE       0     0     0
	  mirror-2  ONLINE       0     0     0
	    loop10  ONLINE       0     0     0
	    loop11  ONLINE       0     0     0
	logs
	  loop12    ONLINE       0     0     0
	cache
	  loop14    ONLINE       0     0     0
	spares
	  loop13    AVAIL   

errors: No known data errors
},

test4 =>
qq{  pool: test4
 state: ONLINE
status: One or more devices is currently being resilvered.  The pool will
	continue to function, possibly in a degraded state.
action: Wait for the resilver to complete.
  scan: resilver in progress since Fri Aug 29 11:18:24 2014
    1.04G scanned out of 7.81G at 42.7M/s, 0h2m to go
    267M resilvered, 13.34% done
config:

	NAME           STATE     READ WRITE CKSUM
	test4          ONLINE       0     0     0
	  loop15       ONLINE       0     0     0
	  loop16       ONLINE       0     0     0
	  loop17       ONLINE       0     0     0
	  replacing-3  ONLINE       0     0     0
	    loop2      ONLINE       0     0     0
	    loop18     ONLINE       0     0     0  (resilvering)

errors: No known data errors
},

test5 =>
qq{  pool: test5
 state: ONLINE
  scan: resilvered 1.95G in 0h2m with 0 errors on Fri Aug 29 11:21:18 2014
config:

	NAME        STATE     READ WRITE CKSUM
	test4       ONLINE       0     0     0
	  loop15    ONLINE       0     0     0
	  loop16    ONLINE       0     0     0
	  loop17    ONLINE       0     0     0
	  loop18    ONLINE       0     0     0

errors: No known data errors
},

test =>
qq{  pool: test
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	test        ONLINE       0     0     0
	  loop0     ONLINE       0     0     0

errors: No known data errors
},

test2 =>
qq{  pool: test2
 state: ONLINE
status: One or more devices is currently being resilvered.  The pool will
	continue to function, possibly in a degraded state.
action: Wait for the resilver to complete.
  scan: resilver in progress since Fri Aug 29 10:30:35 2014
    1.36G scanned out of 5.30G at 23.7M/s, 0h2m to go
    279M resilvered, 25.74% done
config:

	NAME             STATE     READ WRITE CKSUM
	test2            ONLINE       0     0     0
	  raidz2-0       ONLINE       0     0     0
	    loop1        ONLINE       0     0     0
	    loop2        ONLINE       0     0     0
	    loop3        ONLINE       0     0     0
	    loop4        ONLINE       0     0     0
	    replacing-4  ONLINE       0     0     0
	      loop19     ONLINE       0     0     0
	      loop5      ONLINE       0     0     0  (resilvering)

errors: No known data errors
});

if($ARGV[1] eq '-x'){
	print "all pools are healthy\n";
} else {
	print $list{ $ARGV[2] };
}
