# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IO-Pipe-Producer.t'

#########################

use strict;
use warnings;

use Test::More tests => 10;

##
## Test 1
##

#Test to make sure we can 'use' the module
BEGIN { use_ok('IO::Pipe::Producer') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;

#Print the number of tests in a format that Module::Build understands

#Initialize vars needed by IO::Pipe::Producer
my $subroutine1_reference = \&test1;
my $subroutine2_reference = \&test2;
my @subroutine_parameters = ('testing',1,2,3);

#use the module I want to test
use IO::Pipe::Producer;

##
## Test 2
##

#Test a scalar context call to getSubroutineProducer
my $obj = new IO::Pipe::Producer();
my $stdout_fh =
  $obj->getSubroutineProducer($subroutine1_reference,@subroutine_parameters);
my @output = map {chomp;$_} <$stdout_fh>;
close($stdout_fh);

ok(equaleq(\@subroutine_parameters,\@output),
   'getSubroutineProducer() in scalar context');

##
## Test 3
##

#Test a list context call to getSubroutineProducer
$obj = new IO::Pipe::Producer();
my($stderr_fh);
($stdout_fh,$stderr_fh) =
  $obj->getSubroutineProducer($subroutine2_reference,@subroutine_parameters);
@output          = map {chomp;$_} <$stdout_fh>;
my @error_output = map {chomp;$_} <$stderr_fh>;
close($stdout_fh);
close($stderr_fh);

ok(equaleq(\@subroutine_parameters,\@output) &&
   equaleq(\@subroutine_parameters,\@error_output),
   'getSubroutineProducer() in list context');

##
## Test 4
##

#Test a scalar context call to new that returns an STDOUT handle
$stdout_fh = new IO::Pipe::Producer($subroutine1_reference,
                                    @subroutine_parameters);
@output = map {chomp;$_} <$stdout_fh>;
close($stdout_fh);

ok(equaleq(\@subroutine_parameters,\@output),
   'new() in scalar context');

##
## Test 5
##

#Test a list context call to new that returns STDOUT & STDERR handles
($stdout_fh,$stderr_fh) =
  new IO::Pipe::Producer($subroutine2_reference,@subroutine_parameters);
@output       = map {chomp;$_} <$stdout_fh>;
@error_output = map {chomp;$_} <$stderr_fh>;
close($stdout_fh);
close($stderr_fh);

ok(equaleq(\@subroutine_parameters,\@output) &&
   equaleq(\@subroutine_parameters,\@error_output),
   'new() in list context');

##
## Test 6
##

#Test a scalar context call to getSystemProducer
$obj = new IO::Pipe::Producer();
$stdout_fh = $obj->getSystemProducer("echo \"Hello World!\"");
@output = map {chomp;$_} <$stdout_fh>;
close($stdout_fh);

ok("Hello World!" eq $output[0],
   'getSystemProducer() in scalar context');

##
## Test 7
##

#Test a list context call to getSystemProducer
$obj = new IO::Pipe::Producer();
($stdout_fh,$stderr_fh) =
  $obj->getSystemProducer("perl -e 'print \"Hello World!\";" .
                          "print STDERR join(\"\\n\",(" .
                          join(',',@subroutine_parameters) .
                          "))'");
@output       = map {chomp;$_} <$stdout_fh>;
@error_output = map {chomp;$_} <$stderr_fh>;
close($stdout_fh);
close($stderr_fh);

ok("Hello World!" eq $output[0] &&
   equaleq(\@subroutine_parameters,\@error_output),
   'getSystemProducer() in list context');


##
## Test 8
##

#Test that getSystemProducer sets the exit code
$obj = new IO::Pipe::Producer();
my($pid);
#"exit" is a shell builtin. You can't just supply "exit 4" to getSystemProducer
($stdout_fh,$stderr_fh,$pid) = $obj->getSystemProducer("bash -c 'exit 4'");
my $dollar_exclamation = $!;
waitpid($pid,0);
my $exit_code = $? >> 8;
@output       = map {chomp;$_} <$stdout_fh>;
@error_output = map {chomp;$_} <$stderr_fh>;
close($stdout_fh);
close($stderr_fh);

ok($exit_code == 4 && $dollar_exclamation eq '' &&
   scalar(@output) == 0 && scalar(@error_output) == 0,
   "getSystemProducer() returns exit code 4 in \$? & \$! is cleared out");


##
## Test 9
##

#Test that getSystemProducer prints errors when invalid command supplied
$obj = new IO::Pipe::Producer();
#"exit" is a shell builtin. You can't just supply "exit 4" to getSystemProducer
($stdout_fh,$stderr_fh,$pid) = $obj->getSystemProducer("exit 4");
$dollar_exclamation = $!;
waitpid($pid,0);
$exit_code = $? >> 8;
@output       = map {chomp;$_} <$stdout_fh>;
@error_output = map {chomp;$_} <$stderr_fh>;
close($stdout_fh);
close($stderr_fh);

ok($exit_code != 0 && $dollar_exclamation eq '' &&
   scalar(@output) == 0 && scalar(@error_output) > 0 &&
   scalar(grep {/exit/} @error_output),
   "getSystemProducer() prints error to STDERR if exec fails.");


##
## Test 10
##

#Test that getSystemProducer non-zero exits when invalid command supplied and called in scalar context
$obj = new IO::Pipe::Producer();
#Suppress standard error that is expected here for clean test output...
my $orig_stderr = *STDERR;
open(STDERR,'>>','/dev/null');
#"exit" is a shell builtin. You can't just supply "exit 4" to getSystemProducer
$stdout_fh = $obj->getSystemProducer("exit 4");
#Restore STDERR
*STDERR = $orig_stderr;
print STDERR ("Test err restore");
$dollar_exclamation = $!;
$exit_code = $? >> 8;
@output = map {chomp;$_} <$stdout_fh>;
close($stdout_fh);

ok($exit_code != 0 && $dollar_exclamation eq '' && scalar(@output) == 0,
   "getSystemProducer() in scalar context non-zero exits if exec fails.");


#Subroutines that will be sent to the method calls in IO::Pipe::Producer
#They simply print the parameters sent in separated by new lines
sub test1
  {print(join("\n",@_))}
sub test2
  {
    print(join("\n",@_));
    print STDERR (join("\n",@_));
  }

#The chomp'd output of the test subroutine will be tested against the list of
#arguments sent in using this subroutine which basically does a string compare
#of array elements (and a size sompare of the two arrays sent in)
sub equaleq
  {
    my $ary1 = $_[0];
    my $ary2 = $_[1];
    my $retval = 1;

    #If the arrays aren't the same size, issue an error and return 0 (false)
    if(scalar(@$ary1) != scalar(@$ary2))
      {
        print STDERR ("Arrays are not the same size.  The first array has ",
                      scalar(@$ary1),
                      " elements and the second array has ",
                      scalar(@$ary2),
                      " elements.\n");
        $retval = 0;
      }

    #If any of the (assumed) scalar elements don't match, issue an error and
    #return 0 (false)
    foreach my $index (0..($#{$ary1} < $#{$ary2} ? $#{$ary2} : $#{$ary1}))
      {
        if($index < $#{$ary1} && $index < $#{$ary2} &&
           $ary1->[$index] ne $ary2->[$index])
          {
            print STDERR ("Elements[$index] are not the same: ",
                          "[$ary1->[$index]] ne [$ary2->[$index]].\n");
            $retval = 0;
          }
        elsif($#{$ary1} != $#{$ary2} && $index > $#{$ary2})
          {
            print STDERR ("Elements[$index] are not the same: ",
                          "Array 1: [$ary1->[$index]] Array 2: out of range.",
                          "\n");
            $retval = 0;
          }
        elsif($#{$ary1} != $#{$ary2} && $index > $#{$ary1})
          {
            print STDERR ("Elements[$index] are not the same: ",
                          "Array 1: out of range Array 2: [$ary2->[$index]].",
                          "\n");
            $retval = 0;
          }
      }

    #Return 1 (true)
    return($retval);
  }

