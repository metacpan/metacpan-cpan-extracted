#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 96;
use File::Strmode;

while (<DATA>) {
    chomp;
    /^(\d+)\s+=>\s+(.*)$/ or next;
    is(strmode(int $1), "$2 ");
}

__DATA__
4480 => prw-------
4512 => prw-r-----
16384 => d---------
16704 => dr-x------
16713 => dr-x--x--x
16832 => drwx------
16840 => drwx--x---
16872 => drwxr-x---
16877 => drwxr-xr-x
16888 => drwxrwx---
16893 => drwxrwxr-x
16895 => drwxrwxrwx
17368 => drwx-wx--T
17400 => drwxrwx--T
17407 => drwxrwxrwt
17896 => drwxr-s---
17901 => drwxr-sr-x
17912 => drwxrws---
17917 => drwxrwsr-x
32768 => ----------
32896 => --w-------
33024 => -r--------
33056 => -r--r-----
33060 => -r--r--r--
33133 => -r-xr-xr-x
33152 => -rw-------
33184 => -rw-r-----
33188 => -rw-r--r--
33200 => -rw-rw----
33204 => -rw-rw-r--
33216 => -rwx------
33252 => -rwxr--r--
33256 => -rwxr-x---
33261 => -rwxr-xr-x
33277 => -rwxrwxr-x
34285 => -rwxr-sr-x
35273 => -rws--x--x
35304 => -rwsr-x---
35308 => -rwsr-xr--
35309 => -rwsr-xr-x
36333 => -rwsr-sr-x
41471 => lrwxrwxrwx
49536 => srw-------
49590 => srw-rw-rw-
49600 => srwx------
49645 => srwxr-xr-x
49663 => srwxrwxrwx
4480 => prw-------
4512 => prw-r-----
16384 => d---------
16704 => dr-x------
16713 => dr-x--x--x
16813 => drw-r-xr-x
16832 => drwx------
16840 => drwx--x---
16872 => drwxr-x---
16877 => drwxr-xr-x
16888 => drwxrwx---
16893 => drwxrwxr-x
16895 => drwxrwxrwx
17368 => drwx-wx--T
17400 => drwxrwx--T
17407 => drwxrwxrwt
17896 => drwxr-s---
17901 => drwxr-sr-x
17912 => drwxrws---
17917 => drwxrwsr-x
18429 => drwxrwsr-t
32768 => ----------
32896 => --w-------
33024 => -r--------
33056 => -r--r-----
33060 => -r--r--r--
33133 => -r-xr-xr-x
33152 => -rw-------
33184 => -rw-r-----
33188 => -rw-r--r--
33200 => -rw-rw----
33204 => -rw-rw-r--
33216 => -rwx------
33252 => -rwxr--r--
33256 => -rwxr-x---
33261 => -rwxr-xr-x
33277 => -rwxrwxr-x
34285 => -rwxr-sr-x
35273 => -rws--x--x
35304 => -rwsr-x---
35308 => -rwsr-xr--
35309 => -rwsr-xr-x
36333 => -rwsr-sr-x
41471 => lrwxrwxrwx
49536 => srw-------
49590 => srw-rw-rw-
49600 => srwx------
49645 => srwxr-xr-x
49663 => srwxrwxrwx
