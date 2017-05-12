# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(
	put1char
	putstring
);
use Net::DNS::ToolKit::Debug qw(print_buf);
use CTest;

$TCTEST		= 'Mail::SpamCannibal::DNSBLserver::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

=pod

This is what we are testing:

char *
name_skip(char * cp)
{
  int i;

  for(i=0;i<MAXDNAME;i++) {
    if ( ((u_char)*(cp + i)) == 0 )
      return((u_char *)(cp +i + 1));
    else if ( ((u_char)*(cp + i)) < 0xC0 )
      continue;
    else 
      return((u_char *)(cp +i + 2));
  }
/* ERROR, should not reach      */
  return(NULL);
}

=cut

## test 2	check 'zero' detect
my $buffer = '';
put1char(\$buffer,0,0);
print "exp: 1, got: $_\nnot "
	unless ($_ = &{"${TCTEST}::t_name_skip"}($buffer)) == 1;
&ok;

## test 3	check long zero
my $string = 'once upon a time';
my $off = putstring(\$buffer,0,\$string);

put1char(\$buffer,$off,0);

#print_buf(\$buffer);

my $pos = length($string) + 1;
print "exp: $pos got: $_\nnot "
	unless ($_ = &{"${TCTEST}::t_name_skip"}($buffer)) == $pos;
&ok;

## test 4		check dnptr termination
$pos += 1;
$off = put1char(\$buffer,$off,0xC0);
put1char(\$buffer,$off,0);

#print_buf(\$buffer);

print "exp: $pos got: $_\nnot "
	unless ($_ = &{"${TCTEST}::t_name_skip"}($buffer)) == $pos;
&ok;
