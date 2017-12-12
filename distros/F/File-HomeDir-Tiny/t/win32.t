#!perl -wT

BEGIN {
 # On Perl 5.14-, our own home() implementation is based on $^O (which we
 # can fake here), but on Perl 5.16+, the module uses the built-in <~>
 # exclusively, the behaviour of which is determined at perl¢s com-
 # pile time.
 print("1..0 # Skip This is a Win32-only test on Perl 5.16+\n"),exit
  if "$]" >= 5.016;
}

BEGIN { $^O = Win32 => }
use File'HomeDir::Tiny;

print "1..5\n";

local @ENV{HOME,USERPROFILE} = qw\ /hoose /proofile \;
print "not " unless home eq '/hoose';
print "ok 1\n";
{
 local $ENV{HOME};
 print "not " unless home eq '/proofile';
 print "ok 2\n";
 {
  local $ENV{HOME} = 'C:\Documents and Settings\Tedret';
  print "not " unless home eq 'C:\Documents and Settings\Tedret';
  print "ok 3\n";
 }
 print "not " unless home eq '/proofile';
 print "ok 4\n";
}
print "not " unless home eq '/hoose';
print "ok 5\n";
