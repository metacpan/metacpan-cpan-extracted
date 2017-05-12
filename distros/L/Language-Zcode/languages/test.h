!! CZECH: Comprehensive Z-machine Emulation CHecker
!!
!! Testing routines that are in all test program
!!
!! Amir Karger
!! See README.txt for license. (Basically, use/copy/modify, but be nice.)


! Force Inform to use abbreviations
Switches e;

Constant TEST_VERSION "0.8";

! Version-specific constants - Ifdef these to test only certain versions
! Someday, we'll need a IS_V6 here for V6-specific opcodes.
Iftrue #version_number >= 4;
   Constant V4PLUS = 1;
Endif;
Iftrue #version_number >= 5;
   Constant V5PLUS = 1;
Endif;

! [Evin] couldn't figure out how to do negative numbers in inform assembly, so
! here's constants for the numbers I use
Constant n1 -1;
Constant n2 -2;
Constant n3 -3;
Constant n4 -4;
Constant n5 -5;
Constant n500 -500;
Constant n32768 -32768;

! CAREFUL about declaring new globals! Declaration order matters, e.g.
! for "@load [i] -> j", where i refers to a Global var.
Global count;
Global Testnum;
Global Passed;
Global Failed;
Global Print_Tests;
Global Gtemp;
!Global Gtemp2;
Global Ga; Global Gb; ! hack used to get assert routines to work in v3
!Global Standard;

Abbreviate "xyzzy";

Array mytable -> 256;
Array mysecond -> 256;

! Object stuff
Attribute attr1;
Attribute attr2;
Attribute attr3;
Attribute attr4;
Property propa 11;
Property propb 12;
Property propc 13;
Property propd 14;
Property prope 15;

Object Obj1 "Test Object #1"
  has   attr1 attr2
  with  propa 1,
	propb 2,
	propd 4 5 6;

Object Obj2 "Test Object #2" Obj1
  has   attr3 attr4
  with  propa 2,
	propd 4;

Object Obj3 "Test Object #3" Obj1
  with  propa 3,
	propd 4;

Object Obj4 "Test Object #4" Obj3
  with  propa 4,
	propd 4;

#Ifdef V4PLUS; ! limit of 4-byte properties
! This object is only valid on standard 1.0 interpreters because of
! the 64 byte property.
Object Obj5 ""
 with  propa 1,
       propb 1 2 3,
       propc 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29,
       prope 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32;
#Endif;

Object Obj6 "test of an object with a shortname which is about as long as they get these days even though this one only uses the first alphabet which means this is destined to be a runon sentence since i am not using any punctuation or uppercase well i guess that means this is more boring than it need be but it makes the size calculation easier on me when i am writing this program and this mostly assumes your zmachine is capabable of outputting text with correct zscii decoding because after all if it could not then you probably would not even be running this program because it would definitely be too boring to run something which cannot even communicate its results to you when you really want to know what they are abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrs the end"
 with  prope 10000;

! ----------------------------------------------------------------------
! Assert Routines: did we get expected output?

! Main assert function.
! desc is an optional arg which is a short string describing the exact
! test run. Note that the program already writes which opcode we're testing,
! so only use this for saying what *aspect* of that opcode is being tested.
! See calls in the code for examples.
[ assert0 actual expected desc;
   if (expected ~= actual) {
      print "^^ERROR [",Testnum,"] ";
      ! Print description if we got one
#Ifdef V5PLUS;
      @check_arg_count 3 ?~no_desc;
#Ifnot; ! fake a check_arg_count
      @jz desc ?no_desc;
#Endif;
      print "(";
      @print_paddr desc;
      print ")";

      .no_desc;
      f();
      print " Expected ", expected, "; got ", actual, "^^";
      !@quit;
   } else {
       p();
   }
];

! Problem: the "(string)" command requires Inform to pull in a whole
! bunch of code requiring a whole bunch of new ops, which I don't want
! to use for assert commands

! Special assert for Unary ops
! TODO allow this to take an optional desc also, to give the test's REASON.
[ assert1 actual expected op a;
    a = Ga; ! Hack so we can call with only 3 args for v3.
    if (expected ~= actual) {
       f();
       !print (string) op, a;
       print "^^ERROR [", Testnum, "] (";
       @print_paddr op;
       print " ", a, ")";
       print " Expected ", expected, "; got ", actual, "^";
       !@quit;
    } else {
        p();
    }
];

! Special assert for Binary ops
! TODO allow this to take an optional desc also, to give the test's REASON.
[ assert2 actual expected op a b;
    a = Ga; b = Gb; ! Hack so we can call with only 3 args for v3.
    if (expected ~= actual) {
       f();
!      print a, (string) op, b;
       print "^^[", Testnum, "] (";
       print a, " ";
       @print_paddr op;
       print " ", b, ")";
       print " Expected ", expected, "; got ", actual, "^";
       !@quit;
    } else {
        p();
    }
];

! For a print test, don't print out a dot & don't try and figure out
! if it was successful
[ pt;
    Testnum++;
    Print_Tests++;
];

! Passed a test
[ p;
    @print ".";
    Testnum++;
    Passed++;
];

! Failed a test
[ f;
    Testnum++;
    Failed++;
];


! ----------------------------------------------------------------------
! MAIN calls a bunch of subs. Each one runs a set of related tests.
!---------------------- MAIN

[ start_test;
   Testnum = 0; Passed = 0; Failed = 0; Print_Tests = 0;
   @print "CZECH: the Comprehensive Z-machine Emulation CHecker, version ";
   ! It's not entirely cool to be using print_paddr before testing.
   ! So sue me.
   @print_paddr TEST_VERSION;
   @print "^Test numbers appear in [brackets].^";
];

[ end_test;
   print "^^Performed ", Testnum, " tests.^";
   print "Passed: ", Passed, ", Failed: ", Failed;
   print ", Print tests: ", Print_Tests, "^";
   if (Passed + Failed + Print_Tests ~= Testnum) {
      @print "^ERROR - Total number of tests should equal";
      @print " passed + failed + print tests.^^";
   }
];

! vim: tw=78 sw=3 ft=inform
