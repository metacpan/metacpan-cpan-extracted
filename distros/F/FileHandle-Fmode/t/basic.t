use strict;
use FileHandle::Fmode qw(:all);

# Same tests as binmode.t - but no binmode() on the handles

print "1..52\n";

my $no_skip = ($] < 5.006001 && $^O =~ /mswin32/i) ? 0 : 1;

my ($rd, $wr, $rw, $one, $undef, $null, $mem, $var);

open(RD, "Makefile.PL") or die "Can't open Makefile.PL for reading: $!";
unless($] < 5.006) {open($rd, "Fmode.pm") or die "Can't open Fmode.pm for reading: $!";}
else {$rd = \*RD}

#binmode(RD);
#binmode($rd);

if(is_FH(\*RD) && is_arg_ok(\*RD) && is_R(\*RD) && is_RO(\*RD) && !is_W(\*RD) && !is_WO(\*RD) && !is_RW(\*RD)) {print "ok 1\n"}
else {print "not ok 1\n"}

if(is_FH($rd) && is_arg_ok($rd) && is_R($rd) && is_RO($rd) && !is_W($rd) && !is_WO($rd) && !is_RW($rd)) {print "ok 2\n"}
else {print "not ok 2\n"}

if($no_skip) {
  if(!is_A(\*RD) && !is_A($rd)) {print "ok 3\n"}
  else {print "not ok 3\n"}
}
else {print "ok 3 - skipped, pre-5.6.1 Win32 perl\n"}

close(RD) or die "Can't close Makefile.PL after opening for reading: $!";
unless($] < 5.006) {close($rd) or die "Can't close Fmode.pm after opening for reading: $!";}

open(RD, "<Makefile.PL") or die "Can't open makefile.PL for reading: $!";
unless($] < 5.006) {open($rd, "<Fmode.pm") or die "Can't open Fmode.pm for reading: $!";}
else {$rd = \*RD}

#binmode(RD);
#binmode($rd);

if(is_FH(\*RD) && is_arg_ok(\*RD) && is_R(\*RD) && is_RO(\*RD) && !is_W(\*RD) && !is_WO(\*RD) && !is_RW(\*RD)) {print "ok 4\n"}
else {print "not ok 4\n"}

if(is_FH($rd) && is_arg_ok($rd) && is_R($rd) && is_RO($rd) && !is_W($rd) && !is_WO($rd) && !is_RW($rd)) {print "ok 5\n"}
else {print "not ok 5\n"}

if($no_skip) {
  if(!is_A(\*RD) && !is_A($rd)) {print "ok 6\n"}
  else {print "not ok 6\n"}
}
else {print "ok 6 - skipped, pre-5.6.1 Win32 perl\n"}

close(RD) or die "Can't close Makefile.PL after opening for reading: $!";
unless($] < 5.006) {close($rd) or die "Can't close Fmode.pm after opening for reading: $!";}

#####################################################

open(WR, ">temp.txt") or die "Can't open temp.txt for writing: $!";
unless($] < 5.006) {open($wr, ">temp2.txt") or die "Can't open temp2.txt for writing: $!";}
else {$wr = \*WR}

#binmode(WR);
#binmode($wr);

if(is_FH(\*WR) && is_arg_ok(\*WR) && is_W(\*WR) && is_WO(\*WR)) {print "ok 7\n"}
else {print "not ok 7\n"}

if(is_FH($wr) && is_arg_ok($wr) && is_W($wr) && is_WO($wr)) {print "ok 8\n"}
else {print "not ok 8\n"}

if(!is_RO(\*WR) && !is_R(\*WR) && !is_RW(\*WR)) {print "ok 9\n"}
else {print "not ok 9\n"}

if(!is_RO($wr) && !is_R($wr) && !is_RW($wr)) {print "ok 10\n"}
else {print "not ok 10\n"}

if($no_skip) {
  if(!is_A(\*WR) && !is_A($wr)) {print "ok 11\n"}
  else {print "not ok 11\n"}
}
else {print "ok 11 - skipped, pre-5.6.1 Win32 perl\n"}

#####################################################

close(WR) or die "Can't close temp.txt after opening for writing: $!";
unless($] < 5.006) {close($wr) or die "Can't close temp2.txt after opening for writing: $!";}

open(WR, ">>temp.txt") or die "Can't open temp.txt for writing: $!";
unless($] < 5.006) {open($wr, ">>temp2.txt") or die "Can't open temp2.txt for writing: $!";}
else {$wr = \*WR}

#binmode(WR);
#binmode($wr);

if(is_FH(\*WR) && is_arg_ok(\*WR) && is_W(\*WR) && is_WO(\*WR)) {print "ok 12\n"}
else {print "not ok 12\n"}

if(is_FH($wr) && is_arg_ok($wr) && is_W($wr) && is_WO($wr)) {print "ok 13\n"}
else {print "not ok 13\n"}

if(!is_RO(\*WR) && !is_R(\*WR) && !is_RW(\*WR)) {print "ok 14\n"}
else {print "not ok 14\n"}

if(!is_RO($wr) && !is_R($wr) && !is_RW($wr)) {print "ok 15\n"}
else {print "not ok 15\n"}

if($no_skip) {
  if(is_A(\*WR) && is_A($wr)) {print "ok 16\n"}
  else {print "not ok 16\n"}
}
else {print "ok 16 - skipped, pre-5.6.1 Win32 perl\n"}

close(WR) or die "Can't close temp.txt after opening for appending: $!";
unless($] < 5.006) {close($wr) or die "Can't close temp2.txt after opening for appending: $!";}

#####################################################

open(RW, "+>temp.txt") or die "Can't open temp.txt for reading/writing: $!";
unless($] < 5.006) {open($rw, "+>temp2.txt") or die "Can't open temp2.txt for reading/writing: $!";}
else {$rw = \*RW}

#binmode(RW);
#binmode($rw);

if(is_FH(\*RW) && is_arg_ok(\*RW) && is_RW(\*RW) && is_W(\*RW) && is_R(\*RW)) {print "ok 17\n"}
else {print "not ok 17\n"}

if(is_FH($rw) && is_arg_ok($rw) && is_RW($rw) && is_W($rw) && is_R($rw)) {print "ok 18\n"}
else {print "not ok 18\n"}

if(!is_RO(\*RW) && !is_WO(\*RW)) {print "ok 19\n"}
else {print "not ok 19\n"}

if(!is_RO($rw) && !is_WO($rw)) {print "ok 20\n"}
else {print "not ok 20\n"}

if($no_skip) {
  if(!is_A(\*RW) && !is_A($rw)) {print "ok 21\n"}
  else {print "not ok 21\n"}
}
else {print "ok 21 - skipped, pre-5.6.1 Win32 perl\n"}

close(RW) or die "Can't close temp.txt after opening for reading/writing: $!";
unless($] < 5.006) {close($rw) or die "Can't close temp2.txt after opening for reading/writing: $!";}

#####################################################

open(RW, "+<temp.txt") or die "Can't open temp.txt for reading/writing: $!";
unless($] < 5.006) {open($rw, "+<temp2.txt") or die "Can't open temp2.txt for reading/writing: $!";}
else {$rw = \*RW}

#binmode(RW);
#binmode($rw);

if(is_FH(\*RW) && is_arg_ok(\*RW) && is_RW(\*RW) && is_W(\*RW) && is_R(\*RW)) {print "ok 22\n"}
else {print "not ok 22\n"}

if(is_FH($rw) && is_arg_ok($rw) && is_RW($rw) && is_W($rw) && is_R($rw)) {print "ok 23\n"}
else {print "not ok 23\n"}

if(!is_RO(\*RW) && !is_WO(\*RW)) {print "ok 24\n"}
else {print "not ok 24\n"}

if(!is_RO($rw) && !is_WO($rw)) {print "ok 25\n"}
else {print "not ok 25\n"}

if($no_skip) {
  if(!is_A(\*RW) && !is_A($rw)) {print "ok 26\n"}
  else {print "not ok 26\n"}
}
else {print "ok 26 - skipped, pre-5.6.1 Win32 perl\n"}

close(RW) or die "Can't close temp.txt after opening for reading/writing: $!";
unless($] < 5.006) {close($rw) or die "Can't close temp2.txt after opening for reading/writing: $!";}

#####################################################

open(RW, "+>>temp.txt") or die "Can't open temp.txt for reading/writing: $!";
unless($] < 5.006) {open($rw, "+>>temp2.txt") or die "Can't open temp2.txt for reading/writing: $!";}
else {$rw = \*RW}

#binmode(RW);
#binmode($rw);

if(is_FH(\*RW) && is_arg_ok(\*RW) && is_RW(\*RW) && is_W(\*RW) && is_R(\*RW)) {print "ok 27\n"}
else {print "not ok 27\n"}

if(is_FH($rw) && is_arg_ok($rw) && is_RW($rw) && is_W($rw) && is_R($rw)) {print "ok 28\n"}
else {print "not ok 28\n"}

if(!is_RO(\*RW) && !is_WO(\*RW)){print "ok 29\n"}
else {print "not ok 29\n"}

if(!is_RO($rw) && !is_WO($rw)) {print "ok 30\n"}
else {print "not ok 30\n"}

if($no_skip) {
  if(is_A(\*RW) && is_A($rw)) {print "ok 31\n"}
  else {print "not ok 31\n"}
}
else {print "ok 31 - skipped, pre-5.6.1 Win32 perl\n"}

close(RW) or die "Can't close temp.txt after opening for reading/writing: $!";
unless($] < 5.006) {close($rw) or die "Can't close temp2.txt after opening for reading/writing: $!";}

eval {is_R($undef)};
if($@ && !is_arg_ok($undef)){print "ok 32\n"}
else {print "not ok 32\n"}

eval {is_RO($undef)};
if($@){print "ok 33\n"}
else {print "not ok 33\n"}

eval {is_W($undef)};
if($@){print "ok 34\n"}
else {print "not ok 34\n"}

eval {is_WO($undef)};
if($@){print "ok 35\n"}
else {print "not ok 35\n"}

eval {is_RW($undef)};
if($@){print "ok 36\n"}
else {print "not ok 36\n"}

if($no_skip){
  eval {is_A($undef)};
  if($@){print "ok 37\n"}
  else {print "not ok 37\n"}
}
else {print "ok 37 - skipped, pre-5.6.1 Win32 perl\n"}

$one = 1;

eval {is_R($one)};
if($@ && !is_arg_ok($one)){print "ok 38\n"}
else {print "not ok 38\n"}

eval {is_RO($one)};
if($@){print "ok 39\n"}
else {print "not ok 39\n"}

eval {is_W($one)};
if($@){print "ok 40\n"}
else {print "not ok 40\n"}

eval {is_WO($one)};
if($@){print "ok 41\n"}
else {print "not ok 41\n"}

eval {is_RW($one)};
if($@){print "ok 42\n"}
else {print "not ok 42\n"}

if($no_skip){
  eval {is_A($one)};
  if($@){print "ok 43\n"}
  else {print "not ok 43\n"}
}
else {print "ok 43 - skipped, pre-5.6.1 Win32 perl\n"}

if($] >= 5.007) {

  $var = ''; # Avoid "uninitialised" warnings.

  eval q{open($mem, '<', \$var) or die "Can't open memory object: $!";};
  die $@ if $@;
  #binmode($mem);
  if(is_FH($mem) && is_arg_ok($mem) && is_R($mem) && is_RO($mem) && !is_W($mem) && !is_WO($mem) && !is_RW($mem) && !is_A($mem)) {print "ok 44\n"}
  else {print "not ok 44\n"}
  close($mem) or die "Can't close memory object: $!";

  eval q{open($mem, '>', \$var) or die "Can't open memory object: $!";};
  die $@ if $@;
  #binmode($mem);
  if(is_arg_ok($mem) && !is_R($mem) && !is_RO($mem) && is_W($mem) && is_WO($mem) && !is_RW($mem) && !is_A($mem)) {print "ok 45\n"}
  else {print "not ok 45\n"}
  close($mem) or die "Can't close memory object: $!";

  eval q{open($mem, '>>', \$var) or die "Can't open memory object: $!";};
  die $@ if $@;
  #binmode($mem);
  if(is_FH($mem) && is_arg_ok($mem) && !is_R($mem) && !is_RO($mem) && is_W($mem) && is_WO($mem) && !is_RW($mem) && is_A($mem)) {print "ok 46\n"}
  else {print "not ok 46\n"}
  close($mem) or die "Can't close memory object: $!";

  eval q{open($mem, '+>>', \$var) or die "Can't open memory object: $!";};
  die $@ if $@;
  #binmode($mem);
  if(is_arg_ok($mem) && is_R($mem) && !is_RO($mem) && is_W($mem) && !is_WO($mem) && is_RW($mem) && is_A($mem)) {print "ok 47\n"}
  else {print "not ok 47\n"}
  close($mem) or die "Can't close memory object: $!";


  eval q{open($mem, '+>', \$var) or die "Can't open memory object: $!";};
  die $@ if $@;
  #binmode($mem);
  if(is_FH($mem) && is_arg_ok($mem) && is_R($mem) && !is_RO($mem) && is_W($mem) && !is_WO($mem) && is_RW($mem) && !is_A($mem)) {print "ok 48\n"}
  else {print "not ok 48\n"}
  close($mem) or die "Can't close memory object: $!";

  eval q{open($mem, '+<', \$var) or die "Can't open memory object: $!";};
  die $@ if $@;
  #binmode($mem);
  if(is_FH($mem) && is_arg_ok($mem) && is_R($mem) && !is_RO($mem) && is_W($mem) && !is_WO($mem) && is_RW($mem) && !is_A($mem)) {print "ok 49\n"}
  else {print "not ok 49\n"}
  close($mem) or die "Can't close memory object: $!";

}
else {
  print "ok 44 - skipped - pre-5.8 perl\n";
  print "ok 45 - skipped - pre-5.8 perl\n";
  print "ok 46 - skipped - pre-5.8 perl\n";
  print "ok 47 - skipped - pre-5.8 perl\n";
  print "ok 48 - skipped - pre-5.8 perl\n";
  print "ok 49 - skipped - pre-5.8 perl\n";
}

open(RD, "Makefile.PL") or die "Can't open Makefile.PL for reading: $!";
#binmode(RD);
eval{FileHandle::Fmode::perliol_readable(\*RD);};

if($] < 5.007) {
  if($@ =~ /perliol_readable/) {print "ok 50\n"}
  else {print "not ok 50\n"}
}
else {
  if($@) {print "not ok 50\n"}
  else {print "ok 50\n"}
}

close(RD) or die "Can't close Makefile.PL after opening for reading: $!";

open(WR, ">temp2.txt") or die "Can't open temp2.txt for writing: $!";
#binmode(WR);
eval{FileHandle::Fmode::perliol_writable(\*WR);};

if($] < 5.007) {
  if($@ =~ /perliol_writable/) {print "ok 51\n"}
  else {print "not ok 51\n"}
}
else {
  if($@) {print "not ok 51\n"}
  else {print "ok 51\n"}
}

eval{FileHandle::Fmode::win32_fmode(\*WR);};
if($^O =~ /mswin32/i) {
  if($@) {print "not ok 52\n"}
  else {print "ok 52\n"}
}
else {
  if($@ =~ /win32_fmode/) {print "ok 52\n"}
  else {print "not ok 52\n"}
}

close(WR) or die "Can't close temp2.txt after opening for writing: $!";
