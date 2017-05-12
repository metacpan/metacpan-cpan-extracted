#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'perl5-porters', 'list name');
is($list->listsoftware, 'ezmlm', 'list software');
is($list->posting_address, 'perl5-porters@perl.org', 'perl5-porters');

# This email used with permission, and must not be distributed or
# reproduced separately from this archive without the author's permission

__DATA__
From nick@ccl4.org Sat Jan 20 22:25:52 2001
Envelope-to: mstevens@firedrake.org
Received: from paladin.globnix.org [195.11.247.40] 
	by dayspring.firedrake.org with esmtp (Exim 3.12 #1 (Debian))
	id 14K6SG-0006b2-00; Sat, 20 Jan 2001 22:25:52 +0000
Received: from tmtowtdi.perl.org ([209.85.3.25] ident=qmailr)
	from qmailr by paladin.globnix.org with smtp id 14K6SF-0008JY-00
	for mstevens@globnix.org; Sat, 20 Jan 2001 22:25:52 +0000
Received: (qmail 6144 invoked by uid 508); 20 Jan 2001 22:25:48 -0000
Mailing-List: contact perl5-porters-help@perl.org; run by ezmlm
Precedence: bulk
list-help: <mailto:perl5-porters-help@perl.org>
list-unsubscribe: <mailto:perl5-porters-unsubscribe@perl.org>
list-post: <mailto:perl5-porters@perl.org>
Delivered-To: mailing list perl5-porters@perl.org
Received: (qmail 6135 invoked from network); 20 Jan 2001 22:25:47 -0000
Received: from plum.flirble.org (exim@195.40.6.20)
  by tmtowtdi.perl.org with SMTP; 20 Jan 2001 22:25:47 -0000
Received: from nick by plum.flirble.org with local (Exim 3.20 #3)
	id 14K6SA-0003BQ-00
	for perl5-porters@perl.org; Sat, 20 Jan 2001 22:25:46 +0000
Date: Sat, 20 Jan 2001 22:22:51 +0000
From: Nicholas Clark <nick@ccl4.org>
To: perlbug@perl.org
Subject: qu() exposes utf8 hash key problem
Message-ID: <20010120222250.A10531@plum.flirble.org>
Mime-Version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
User-Agent: Mutt/1.2.5i
X-Organisation: Tetrachloromethane
Resent-From: nick@plum.flirble.org
Resent-Date: Sat, 20 Jan 2001 22:25:46 +0000
Resent-To: perl5-porters@perl.org
Resent-Message-Id: <E14K6SA-0003BQ-00@plum.flirble.org>
Status: RO

This is a bug report for perl from nick@talking.bollo.cx,
generated with the help of perlbug 1.33 running under perl v5.7.0.


-----------------------------------------------------------------
[Please enter your report here]

using the utf8 representation of codepoints 128-255 as a hash key seems to
produce some undesirable effects.
[I'm using a '£' (pound sterling) as my test character - if this gets stripped
to 7 bit you will see hash '#'. The next hash after this sentence is in
the OS version "2.2.17-rmk1 #9"]

I assume that these occur with substr and utf8 scalars, but they are very
easy to make with the new qu operator

the strings are equal, which (I believe) is correct:

perl -le '$uni = qu(£); $eight = "£"; print $uni eq $eight'
1

however, interesting things start happening with hash keys:

perl  -MDevel::Peek -le '$a{qu(£)} = "foo"; $a{"£"} = "bar" ; foreach (keys %a) {Dump($_)}'
SV = PVIV(0x20d8690) at 0x20d7e94
  REFCNT = 2
  FLAGS = (POK,FAKE,READONLY,pPOK)
  IV = 168
  PV = 0x20e40a0 "\243"
  CUR = 1
  LEN = 0
SV = PVIV(0x20d86e0) at 0x20e25d0
  REFCNT = 2
  FLAGS = (POK,FAKE,READONLY,pPOK,UTF8)
  IV = 6770
  PV = 0x20e3eb8 "\302\243"
  CUR = 2
  LEN = 0

I shouldn't get 2 hash entries should I?
[for the FAKE,READONLY SV the hash value is cached in the IV, so you can see
that the two representations have hashed to different numbers]

perl -wle '$a{qu(£)} = "foo"; $a{qw(£)} = "bar" ; foreach (keys %a) {print $_};'
£
£
Attempt to free non-existent shared string '£'.

perl -wle '$uni = qu(£); $eight = "£"; $a{$uni} = "foo"; $a{$eight} = "bar"; foreach (keys %a) {print $a{$_}}' 
bar
foo

perl -wle '$uni = qu(£); $eight = "£"; $a{$uni} = "foo"; $a{$eight} = "bar"; foreach (keys %a) {print $_; print $a{$_}}'
£
bar
£
Use of uninitialized value in print at -e line 1.

Attempt to free non-existent shared string '£'.

the warnings are explained by:

perl -MDevel::Peek -wle '$uni = qu(£); $eight = "£"; $a{$uni} = "foo"; $a{$eight} = "bar"; foreach (keys %a) {print $_; Dump($_)}'
£
SV = PVIV(0x20d8690) at 0x20d7e94
  REFCNT = 2
  FLAGS = (POK,FAKE,READONLY,pPOK)
  IV = 168
  PV = 0x20e07e0 "\243"
  CUR = 1
  LEN = 0
£
SV = PVIV(0x20d86c0) at 0x20e25f8
  REFCNT = 2
  FLAGS = (POK,FAKE,READONLY,pPOK)
  IV = 6770
  PV = 0x20dbd88 "\243"
  CUR = 1
  LEN = 0
Attempt to free non-existent shared string '£'.


*something* is feeling quite happy to mess with a readonly scalar

for information

1: it seems no errors are currently being generated if shared strings remain
   at global destruction time.
2: SvREADONLY_off() is a scary thing. Perl_ck_require uses it indiscriminately
   without force_normal to append ".pm" (would a patch be wanted for that?
   It doesn't affect anything *yet*). I'm guessing something else is doing
   something equally horrible on output.

I guess we need a canonical representation for hash keys which at least
one codepoint in the range 128-255 but none >255. Possibly downgraded to
8 bit. Or possibly upgraded to utf8.


Sorry, I have not patches for the above things.

Nicholas Clark

[Please do not change anything below this line]
-----------------------------------------------------------------
---
Flags:
    category=core
    severity=medium
---
Site configuration information for perl v5.7.0:

Configured by nick at Thu Jan 18 19:24:14 GMT 2001.

Summary of my perl5 (revision 5.0 version 7 subversion 0) configuration:
  Platform:
    osname=linux, osvers=2.2.17-rmk1, archname=armv4l-linux
    uname='linux bagpuss.unfortu.net 2.2.17-rmk1 #9 fri dec 8 23:52:12 gmt 2000 armv4l unknown '
    config_args='-Dusedevel -Ubincompat5005 -Uinstallusrbinperl -Dcf_email=nick@talking.bollo.cx -Dperladmin=nick@talking.bollo.cx -Dinc_version_list=  -Dinc_version_list_init=0 -Duseperlio -des'
    hint=recommended, useposix=true, d_sigaction=define
    usethreads=undef use5005threads=undef useithreads=undef usemultiplicity=undef
    useperlio=define d_sfio=undef uselargefiles=define usesocks=undef
    use64bitint=undef use64bitall=undef uselongdouble=undef
  Compiler:
    cc='cc', ccflags ='-fno-strict-aliasing -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64',
    optimize='-O2',
    cppflags='-fno-strict-aliasing -I/usr/local/include'
    ccversion='', gccversion='2.95.2 20000220 (Debian GNU/Linux)', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=1234
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=8
    ivtype='long', ivsize=4, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=4, usemymalloc=n, prototype=define
  Linker and Libraries:
    ld='cc', ldflags =' -L/usr/local/lib'
    libpth=/usr/local/lib /lib /usr/lib
    libs=-lnsl -lndbm -ldb -ldl -lm -lc -lposix -lcrypt -lutil
    perllibs=-lnsl -ldl -lm -lc -lposix -lcrypt -lutil
    libc=/lib/libc-2.1.3.so, so=so, useshrplib=false, libperl=libperl.a
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-rdynamic'
    cccdlflags='-fpic', lddlflags='-shared -L/usr/local/lib'

Locally applied patches:
    DEVEL8452

---
@INC for perl v5.7.0:
    /usr/local/lib/perl5/5.7.0/armv4l-linux
    /usr/local/lib/perl5/5.7.0
    /usr/local/lib/perl5/site_perl/5.7.0/armv4l-linux
    /usr/local/lib/perl5/site_perl/5.7.0
    /usr/local/lib/perl5/site_perl
    .

---
Environment for perl v5.7.0:
    HOME=/home/nick
    LANG (unset)
    LANGUAGE (unset)
    LC_CTYPE=en_GB.ISO-8859-1
    LD_LIBRARY_PATH (unset)
    LOGDIR (unset)
    PATH=/home/nick/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/usr/games:/sbin:/usr/sbin:/usr/local/sbin
    PERL_BADLANG (unset)
    SHELL=/bin/bash

