#! /bin/sh
eval '(exit $?0)' && eval 'PERL_BADLANG=x;PATH="$PATH:.";export PERL_BADLANG\
 PATH;exec perl -x -S -- "$0" ${1+"$@"};#'if 0;eval 'setenv PERL_BADLANG x\
;setenv PATH "$PATH":.;exec perl -x -S -- "$0" $argv:q;#'.q
#!perl -w
+push@INC,'.';$0=~/(.*)/s;do(index($1,"/")<0?"./$1":$1);die$@if$@__END__+if 0
;#Don't touch/remove lines 1--7: http://www.inf.bme.hu/~pts/Magic.Perl.Header
#
# pts-test-lib.t -- a simple Perl test framework based on Test::More + aspects of Test::Inline
# by pts@fazekas.hu at Mon Dec 26 17:27:27 CET 2005
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Dat: perl -MTest::Harness "-eruntests@ARGV" test1.t
#      test1.t:
#      use Test::More qw(no_plan);
#      BEGIN { use_ok( 'integer' ); }
#      is(1, 1.0, "foo");
#      isnt(1, '1.0', "bar");
# Dat: --harness should display: "pts-test....ok\n"
# Imp: plan the # tests for Test::
# Imp: skip "=begin" inside strings or otherwise quoted
# 

package PtsTestLib;
use integer;
use strict;
BEGIN {
  $main::Id='$Id: pts-test.pl,v 1.2 2006/04/26 07:42:33 pts Exp $';
  $main::VERSION=$1 if $main::Id=~/,v *([\d.]+)/;
}
my $SELF='pts-test.pl';

#** @param $_[0] output filehandle
sub banner($) {
  my $fh=$_[0];
  print $fh "This is $SELF, version $main::VERSION, by <pts\@fazekas.hu>\n"
           ."The license is GNU GPL >=2.0. It comes without warranty. USE AT YOUR OWN RISK!\n\n";
}
#** @param $_[0] output filehandle
sub usage($) {
  my $fh=$_[0];
  print $fh "Usage: $0 [<option> ...] [--] { <script.pl> | <script.t> } ...\n",
            "Options:\n",
	    "--help  this help\n",
	    "--harness  run whole test through Test::Harness\n";
}

my $do_help=0;
my $do_harness=0;
my $do_work=(defined $ENV{PTS_TEST_DO});
@ARGV=split("\n",$ENV{PTS_TEST_DO}) if !@ARGV and $do_work;

{ my $I;
  for ($I=0;$I<@ARGV;$I++) {
    if ($ARGV[$I]eq'--') { $I++; last }
    elsif (substr($ARGV[$I],0,1)ne'-') { last }
    elsif ($ARGV[$I]eq'--help') { $do_help++ }
    elsif ($ARGV[$I]eq'--harness') { $do_harness++ }
    elsif ($ARGV[$I]eq'--work') { $do_work++ }
    else { die "$SELF: unknown option: $ARGV[$I]\n" }
  }
  splice(@ARGV,0,$I);
}

if ($do_help) { #
  banner(\*STDOUT); usage(\*STDOUT); exit 0;
}

#my $perl_exe=$^X;
#$perl_exe='perl' if $^X!~m@perl[^/]*\Z(?!\n)@;
#die "$SELF: perl executable not found: $perl_exe\n" if (!-f $perl_exe);
## ^^^ Imp: test `-e' on UNIX

if ($do_harness) {
  $ENV{PTS_TEST_DO}=join("\n",@ARGV); # Imp: quoting
  require Test::Harness;
  import  Test::Harness;
  $Test::Harness::switches=""; # Dat: remove "-w", we have /bin/sh in our shebang
  runtests($0);
  exit 0;
}

# Imp: maybe in separate processes?
# vvv Dat: `use' here, would add a mandatory dependency on `Test::More', but
#     it also prints "# No tests run!" with --help.
require Test::More;
import  Test::More qw(no_plan);

$|=1;
my $errc=0;

#** @param $_[0] filename, usually a Perl script or a .pm Perl module
sub test_file($) {
  my $testfile=$_[0];
  if ($testfile=~/[\r\n"\\]/) {
    print STDERR "$SELF: special character in test filename: $testfile\n";
    $errc++; next
  } elsif (!open F, "< $testfile") {
    print STDERR "$SELF: test file missing: $testfile: $!\n";
    $errc++; next
  }
  print "# testing file: $testfile\n"; # Dat: ignored by Test::Harness
  #** Previous line was whitespace only.
  my $prevws_p=1;
  #** 0: we are outside a testing block
  #** 1: we are in a `=begin testing' block
  #** 2: we are in a `=for testing' block
  my $in_testing=0;
  my $testcode="";
  while (<F>) {
    if (!/\S/) {
      $testcode.=$_ if $in_testing!=0;
      $in_testing=0 if $in_testing==2; # Dat: paragraph of `=for' has ended
      $prevws_p=1; next
    }
    $prevws_p=0;
    if (/^=(begin|for)\s+testing\s*$/) {
      my $lineno=$.+1;
      print STDERR "$SELF: nested testing declaration in $testfile:$.\n" if $in_testing!=0;
      $testcode.="\n\n#line $lineno \"$testfile\"\n";
      $in_testing=($1 eq "begin") ? 1 : 2;
    } elsif ($in_testing==1 and /^=(?:end(?:\s+testing)?|cut)\s*$/) {
      # Dat: `=end testing' is OK, `=end' isn't, but we're not that picky
      $in_testing=0;
    } elsif ($in_testing!=0) {
      $testcode.=$_
    }
  }
  die if !close F;
  $testfile="./$testfile" if 0>index($testfile,"/");  # Dat: for better do()
  if (0==length($testcode)) {
    # Dat: no inline POD tests found
    do $testfile;
  } else {
    do $testfile; # Dat: parse definitions etc.
    die $@ if $@;
    eval $testcode;
  }
  die $@ if $@;
}

# ---

#** @param $_[1] Perl package/module name (e.g. MIME::Words)
sub test_mod($) {
  my $mod=$_[0];
  my $modfn=$mod; $modfn=~s@::@/@g; $modfn.=".pm";
  my $dirmodfn;
  for my $dir (@INC) {
    if (!ref($dir) and (-f"$dir/$modfn")) { $dirmodfn="$dir/$modfn"; last }
  }
  if (defined$dirmodfn) {
    test_file($dirmodfn);
  } else {
    print STDERR "$0: file to test not found: $modfn\n";
    $errc++;
  }
}

if ($0 eq __FILE__) {
  for my $fn (@ARGV) { test_file $fn }
  exit($errc>99 ? 100 : $errc);
}

1
