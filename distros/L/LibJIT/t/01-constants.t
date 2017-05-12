# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl LibJIT.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('LibJIT', ':all') };


my $fail = 0;
foreach my $constname (qw(
	JIT_PROT_EXEC_READ JIT_PROT_EXEC_READ_WRITE JIT_PROT_NONE JIT_PROT_READ
	JIT_PROT_READ_WRITE jit_abi_cdecl jit_abi_fastcall jit_abi_stdcall
	jit_abi_vararg)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined LibJIT macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

