# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Devel::tkdb;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$DB::no_stop_at_start = 1;

my $tkdeb = new Devel::tkdb;
my $int = $tkdeb->{int};

my $prog = <<'EOS' .
BEGIN{
  #$^P = 0x07DF;
  print STDERR 'file is ' . __FILE__ . ";\n",$DB::window,";;\n";
  my $fn = __FILE__;
  $::deb->set_file(__FILE__,1);
}
#use strict;
$a = 'qwerty';

$DB::single = 1;
EOS
'$a++;
print $a;
' x 100;

$int->after(3000, 'set event step');
$int->after(3100, 'set event step');
$int->after(3200, 'set event step');
$int->after(3300, 'set event step');
$int->after(3400, 'set event step');
$int->after(3500, 'set event step');
$int->after(5000, 'set event run ');

$int->after(7000, 'set qwerty asdf');

$::deb = $tkdeb;
eval "$prog";
print $@;

$tkdeb->main_loop();

print STDERR "quit main loop";

$int->tkwait('variable','qwerty');

## fake 'debug' this $prog TODO
#
print "ok 2\n";

