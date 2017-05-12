!! CZECH: Comprehensive Z-machine Emulation CHecker
!!
!! Tests not requiring user interaction.
!!
!! Amir Karger
!! See README.txt for license. (Basically, use/copy/modify, but be nice.)

! ----------------------------------------------------------------------
! These subs run tests on a particular set of ops
! First argument is whether to skip the tests

[ test_jumps do_this i;
   print "Jumps";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";
   print "jump";
   jump j2; ! Using "@jump" with label name crashes
   .j1;
   print "bad!"; @quit;
   .j2; p();

   ! Note that some of these jumps are > 63 bytes away, some less,
   ! so we'll test short and long form of branching.
   print "je";
   ! TODO test "je sp a b c" to make sure not multi-popping stack, etc.
   @je  5  5 ?~bad; p();
   @je  5 n5 ?bad; p();
   @je n5  5 ?bad; p();
   @je n5 n5 ?~bad; p();
   @je  32767 n32768 ?bad; p();
   @je n32768 n32768 ?~bad; p();
   @je 5 4 5 ?~bad; p();
   @je 5 4 3 5 ?~bad; p();
   @je 5 4 5 3 ?~bad; p();
   @je 5 4 3 2 ?bad; p();
   
   print "jg";
   @jg  5  5 ?bad; p();
   @jg  1  0 ?~bad; p();
   @jg  0  1 ?bad; p();
   @jg n1 n2 ?~bad; p();
   @jg n2 n1 ?bad; p();
   @jg  1 n1 ?~bad; p();
   @jg n1  1 ?bad; p();
   
   print "jl";
   @jl  5  5 ?bad; p();
   @jl  1  0 ?bad; p();
   @jl  0  1 ?~bad; p();
   @jl n1 n2 ?bad; p();
   @jl n2 n1 ?~bad; p();
   @jl  1 n1 ?bad; p();
   @jl n1  1 ?~bad; p();
   
   print "jz";
   @jz 0 ?~bad; p();
   @jz 1 ?bad; p();
   @jz n4 ?bad; p();

   print "offsets";
   i = do_jump_return(0);
   assert0(i, 0, "branch 0");
   i = do_jump_return(1);
   assert0(i, 1, "branch 1");
   rtrue;

.bad;
   print "^bad [", Testnum, "]!^";
   @print "Quitting tests because jumps don't work!";
   @quit;   

];

! Test that offset of 0/1 returns instead of branching.
! TODO in theory we should test all jump opcodes to make sure they can
! return false/true
[ do_jump_return i;
   @je i 0 ?~j1;
   @jz 0 ?rfalse;
   return 97;
   .j1;
   @je i 1 ?~j2;
   @jz 0 ?rtrue;
   return 98;
   .j2;
   return 99;
];

! ---- VARIABLES ----------------------------------
[ test_variables do_this i n;
   print "Variables";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   print "push/pull";
   @push 9;
   @push 8;
   @pull i;
   assert0(i, 8, "pull to local");
   @pull Gtemp;
   assert0(Gtemp, 9, "pull to global");

#Ifndef V5PLUS;
   print "pop";
   @push 7;
   @push 6;
   @pop; ! popped value gets thrown away
   @pull i;
   assert0(i, 7);
#Endif;

   print "store";
   @store i 5;
   assert0(i, 5);
   print "load";
   n = 5; i = 6;
   @load i sp;
   @pull n;
   assert0(i, n);

   print "dec";
   do_dec( 5,  4);
   do_dec( 0, -1);
   do_dec(-8, -9);
   do_dec(-32768, 32767);  
   ! Should decrement top of stack and not pop it
   @push 1;
   @push 10;
   @dec sp;
   @pull n;
   assert0(n, 9, "dec sp");
   @pull n;
   assert0(n, 1, "dec sp");
   count = 3;
   @dec count;
   assert0(count, 2, "dec global");

   print "inc";
   do_inc( 5,  6);
   do_inc(-1,  0);
   do_inc(-8, -7);
   do_inc(32767, -32768);  
   @push 1;
   @push 10;
   @inc sp;
   @pull n;
   assert0(n, 11, "inc sp");
   @pull n;
   assert0(n, 1, "inc sp");
   count = 3;
   @inc count;
   assert0(count, 4, "inc global");
   
   print "^    dec_chk";
   n = 3;
   @dec_chk n 1000 ?~bad1; p(); !  2
   @dec_chk n    1 ?bad1;  p(); !  1
   @dec_chk n    1 ?~bad1; p(); !  0
   @dec_chk n    0 ?~bad1; p(); ! -1
   @dec_chk n   n2 ?bad1;  p(); ! -2
   @dec_chk n   n2 ?~bad1; p(); ! -3
   @dec_chk n 1000 ?~bad1; p(); ! -4
   @dec_chk n n500 ?bad1;  p(); ! -5
   @push 1;
   @push 10;
   @dec_chk sp 5 ?bad1; p();
   @pull n;
   assert0(n, 9, "dec_chk sp");
   @pull n;
   assert0(n, 1, "dec_chk sp");
   jump not_bad1;
.bad1;
   f("dec_chk");
.not_bad1;
   
   print "inc_chk";
   n = -6;
   @inc_chk n n500 ?~bad2; p(); ! -5
   @inc_chk n 1000 ?bad2;  p(); ! -4
   @inc_chk n   n3 ?bad2;  p(); ! -3
   @inc_chk n   n3 ?~bad2; p(); ! -2
   @inc_chk n    0 ?bad2;  p(); ! -1
   @inc_chk n    1 ?bad2;  p(); !  0
   @inc_chk n    1 ?bad2;  p(); !  1
   @inc_chk n    1 ?~bad2; p(); !  2
   @inc_chk n 1000 ?bad2;  p(); !  3
   jump not_bad2;
.bad2;
   print "^bad [", Testnum, "]!^";
   f("inc_chk");
.not_bad2;

   rtrue;
];
   
[ do_inc a expect;
   Ga = a;
   @inc a;
   assert1(a, expect, "++");
];

[ do_dec a expect;
   Ga = a;
   @dec a;
   assert1(a, expect, "--");
];

! ---- ARITH ----------------------------------
[ test_arithmetic do_this;
   print "Arithmetic ops";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   print "add";
   do_add( 5,  3,  8);
   do_add( 3,  5,  8);
   do_add(-5,  3, -2);
   do_add(-5, -3, -8);
   do_add(-3, -5, -8);
   do_add(-3,  5,  2);
   do_add(32765, 6, -32765);
   
   print "sub";
   do_sub(8,   5,  3);
   do_sub(8,   3,  5);
   do_sub(-2, -5,  3);
   do_sub(-8, -5, -3);
   do_sub(-8, -3, -5);
   do_sub(2,  -3,  5);
   do_sub(-32765, 32765, 6);

   print "^    mul";
   do_mul(  0, 123,   0);
   do_mul(123,   0,   0);
   do_mul(  8,   9,  72);
   do_mul(  9,   8,  72);
   do_mul( 11,  -5, -55);
   do_mul(-11,   5, -55);
   do_mul(-11,  -5,  55);
   do_mul(-32768, -1, -32768);
   
   print "div";
   do_div(-11,  2, -5);
   do_div(-11, -2,  5);
   do_div( 11, -2, -5);
   do_div(  5,  1,  5);
   do_div(  5,  2,  2);
   do_div(  5,  3,  1);
   do_div(  5,  5,  1);
   do_div(  5,  6,  0);
   do_div(5, 32767, 0);
   do_div(32767, -32768, 0);
   do_div(-32768, 32767, -1);
!   do_div(-32768, -1, -32768);

   print "mod";
   do_mod(-13,  5, -3);
   do_mod( 13, -5,  3);
   do_mod(-13, -5, -3);
   do_mod(  5,  1,  0);
   do_mod(  5,  2,  1);
   do_mod(  5,  3,  2);
   do_mod(  5,  5,  0);
   do_mod(  5,  6,  5);
   do_mod(5, 32767, 5);
   do_mod(32767, -32768, 32767);
   do_mod(-32768, 32767, -1);
!   do_mod(-32768, -1, 0);

   rtrue;
];
   
[ do_add a b expect c;
   @add a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "+");
];

[ do_sub a b expect c;
   @sub a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "-");
];

[ do_mul a b expect c;
   @mul a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "*");
];

[ do_div a b expect c;
   @div a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "/");
];

[ do_mod a b expect c;
   @mod a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "%");
];

! ---- LOGICAL ----------------------------------
[ test_logical do_this;
   print "Logical ops";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   print "not";
   do_not(0, ~0);
   do_not(123, ~123);
   do_not($5555, $aaaa);
   do_not($aaaa, $5555);
   
   print "and";
   do_and( 5,  3,  1);
   do_and( 3,  5,  1);
   do_and(-3, -3, -3);
   do_and(-3,  5,  5);
   do_and(-3, -5, -7);
   
   print "or";
   do_or($1234, $4321, $5335);
   do_or($4321, $1234, $5335);
   do_or($1234,     0, $1234);
   do_or($1030, $ffff, $ffff);
   do_or($ffff, $0204, $ffff);
   
#Ifdef V5PLUS;
   print "art_shift";
   do_art( 0,  1,  0);
   do_art( 0, -1,  0);
   do_art( 1,  5, 32);
   do_art( 1, -1,  0);
   do_art(85,  1, 170);
   do_art(85, -2, 21);
   do_art(-9,  5, -288);
   do_art(-9, -5, -1);
   
   print "log_shift";
   do_log( 0,  1,  0);
   do_log( 0, -1,  0);
   do_log( 1,  5, 32);
   do_log( 1, -1,  0);
   do_log(85,  1, 170);
   do_log(85, -2, 21);
   do_log(-9,  5, -288);
   do_log(-9, -5, 2047);
#Endif;

   rtrue;
];
   
#Ifdef V5PLUS;
[ do_art a b expect c;
   @art_shift a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "<<");
];

[ do_log a b expect c; 
   @log_shift a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "<<");
];
#Endif;

! Write 'not' instead of '~' so we can print with print_paddr
[ do_not a expect c;
   !@"VAR:56S" a -> c;     !   @not a -> c;   (bug in inform)
   @not a -> c; !  (No longer a bug in inform?)
   Ga = a;
   assert1(c, expect, "not");
];

[ do_and a b expect c;
   @and a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "&");
];

[ do_or a b expect c;
   @or a b -> c; Ga = a; Gb = b;
   assert2(c, expect, "|");
];

! ---- MEMORY ACCESS ----------------------------------
[ test_memory do_this i j k n;
   print "Memory";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   print "loadw";
   ! Bytes 04-05 of file are beg. of high mem.
   ! Bytes 06-07 are address of main.
   ! main() is guaranteed to be first sub in Inform!
   @loadw 0 2 -> i;
   @loadw 0 3 -> j;
   @add i 1 -> k;
   assert0(j, k);

   print "loadb";
   @loadb 0 4 -> j;
   @loadb 0 5 -> k;
   @mul j 256 -> sp;
   @add sp k -> k;
   assert0(i, k);
   @loadb  mytable 0 -> n;
   assert0(n, 0);

   print "storeb";
   @storeb mytable 0 123;
   @loadb  mytable 0 -> n;
   assert0(n, 123);
   @loadw  mytable 0 -> n;
   assert0(n, $7b00, "word from two bytes");
   print "storew";
   @storew mytable 5 $1234;
   @loadw  mytable 5 -> n;
   assert0(n, $1234);
   @loadb  mytable 10 -> n;
   assert0(n, $12, "first byte of stored word");
   @loadb  mytable 11 -> n;
   assert0(n, $34, "second byte of stored word");
   ! TODO load/store numbers > 32K

   rtrue;
];

! ---- SUBROUTINES ----------------------------------
[ test_subroutines do_this i n;
   print "Subroutines";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   i = 0;
   Gtemp = 0;
#Ifdef V4PLUS;
   print "call_1s";
   Gtemp = 2;
   @call_1s do_call_1s -> i;
   assert0(Gtemp, 3);
   print "call_2s";
   @call_2s do_call_2s 6 -> i;
   assert0(i, 5);

   print "call_vs2";
   i = 0;
   @call_vs2 do_call_vs2 1 2 3 4 5 6 7 ->i;
   assert0(Gtemp, 9);
   assert0(i, 5);
   print "call_vs";
   i = 0;
   @call_vs do_call 1 2 3 ->i;
   assert0(i, 5);

#Ifnot; ! v3
   print "call";
   @call do_call 1 2 3 ->i;
#Endif;

   ! Test results of call/call_vs, depending on game version
   assert0(Gtemp, 7);
   print "ret";
   assert0(i, 5);
   ! TODO call_vs2 with fewer than 7 args. Make sure locals don't get set etc.

#Ifdef V5PLUS;
   print "^    call_1n";
   @call_1n do_call_1n;
   assert0(Gtemp, 1);
   print "call_2n";
   @call_2n do_call_2n 6;
   assert0(Gtemp, 5);
   print "call_vn";
   @call_vn do_call_vn 1 2 3;
   assert0(Gtemp, 10);
   print "call_vn2";
   @call_vn2 do_call_vn2 1 2 3 4 5 6 7;
   assert0(Gtemp, 11);
#Endif;

   print "^    ";
   print "rtrue";
   i = 2;
   i = do_rtrue();
   assert0(i, 1);
   i = 2;
   print "rfalse";
   i = do_rfalse();
   assert0(i, 0);
   i = do_ret_popped();
   assert0(i, 5, "return from ret_popped");

   ! Computed calls
   print "^    Computed call";
   i = 1;
   n = do_computed_call1;
#Ifdef V4PLUS; @call_1s n -> i; #Ifnot; @call n -> i; #Endif;
   assert0(i, 5);
   @push 1;
   @push do_computed_call2;
#Ifdef V4PLUS; @call_1s sp -> i; #Ifnot; @call sp -> i; #Endif;
   assert0(i, 6);
   @pull i;
   assert0(i, 1);
   ! Call 0 (Most likely will be called as a computed call) should do nothing
   @push 2;
   @push 0;
#Ifdef V4PLUS; @call_1s sp -> i; #Ifnot; @call sp -> i; #Endif;
   @pull i;
   assert0(i, 2, "call 0");
   ! TODO Spec14 describes @call_1s [i] syntax. Is that different than above?

   ! TODO test call_v's more extensively. call with variables (and stack?)
   ! Make sure variables don't get changed! Call with too many args.

#Ifdef V5PLUS;
   print "^    check_arg_count";
   count = 0; do_check_check_arg_count();
   count = 1; do_check_check_arg_count(1);
   count = 2; do_check_check_arg_count(2, 1);
   count = 3; do_check_check_arg_count(3, 2, 1);
   count = 4; do_check_check_arg_count(4, 3, 2, 1);
   count = 5; do_check_check_arg_count(5, 4, 3, 2, 1);
   count = 6; do_check_check_arg_count(6, 5, 4, 3, 2, 1);
   count = 7; do_check_check_arg_count(7, 6, 5, 4, 3, 2, 1);
#Endif;
   
   rtrue;
]; ! end of test_subroutines

#Ifdef V5PLUS;
[ do_check_check_arg_count a b c d e g h n;
   for(n = 1: n <= count: n++) {
      @check_arg_count n ?~bad;
   }
   p();
   for(: n <= 7: n++) {
      @check_arg_count n ?bad;
   }
   p();
   a=b=c=d=e=h=g=0; ! make compiler happy
   return;

   .bad;
   f();

   print " # claimed argument ", n, " was ";
   if(n <= count)
      print "not given when it was.^";
   else
      print "given when it was not.^";
   !@quit;
];
#Endif;

#Ifdef V5PLUS;
[ do_call_1n;
   Gtemp = 1;
];

[ do_call_2n arg0;
   assert0(arg0, 6);
   Gtemp = 5;
];

[ do_call_vn a b c;
   a=b; ! keep compiler quiet
   assert0(c, 3);
   Gtemp = 10;
];

[ do_call_vn2 a b c d e f g;
   a=b=c=d=e=f; ! keep compiler quiet
   assert0(g, 7);
   Gtemp = 11;
];
#Endif;

#Ifdef V4PLUS;
[ do_call_1s;
   Gtemp = 3;
   @ret 5;
];

[ do_call_2s arg0;
   assert0(arg0, 6);
   @ret 5;
];

[ do_call_vs2 a b c d e f g;
   a=b=c=d=e=f; ! keep compiler quiet
   assert0(g, 7);
   Gtemp = 9;
   @ret 5;
];

#Endif;

[ do_call i j k; ! called by call OR call_vs
   assert0(i, 1);
   assert0(j, 2);
   assert0(k, 3);
   Gtemp = 7;
   @ret 5;
];

[ do_rtrue;
   @rtrue;
];

[ do_rfalse;
   @rfalse;
];

[ do_ret_popped;
   @push 5;
   print "ret_popped";
   @ret_popped;
];

[ do_computed_call1;
    @ret 5;
];

[ do_computed_call2;
    @ret 6;
];

! ---- OBJECTS ----------------------------------
[ test_objects do_this;
   print "Objects";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   ! TODO Copy tests from test.inf.
   ! TODO Test object 0
   ! TODO object with no properties
   ! TODO pass an optional desc - subs check_arg_count & pass desc to assert
   ! LOTS OF STUFF!!!
   print "get_parent";
   do_get_parent(Obj1, 0);
   do_get_parent(Obj2, Obj1);
   do_get_parent(Obj3, Obj1);
   do_get_parent(Obj4, Obj3);
   print "get_sibling";
   do_get_sibling(Obj1, 0);
   do_get_sibling(Obj2, Obj3);
   do_get_sibling(Obj3, 0);
   do_get_sibling(Obj4, 0);
   print "get_child";
   do_get_child(Obj1, Obj2);
   do_get_child(Obj2, 0);
   do_get_child(Obj3, Obj4);
   do_get_child(Obj4, 0);
   print "jin";
   do_jin(Obj1, Obj2, 0);
   do_jin(Obj1, Obj1, 0);
   do_jin(Obj2, Obj1, 1);
   do_jin(Obj2, Obj3, 0);
   do_jin(Obj3, Obj1, 1);
   do_jin(Obj4, Obj3, 1);
   do_jin(Obj4, Obj1, 0); ! must be *direct* parent

   print "^    test_attr";
   do_test_attr(Obj1, attr1, 1);
   do_test_attr(Obj1, attr2, 1);
   do_test_attr(Obj1, attr3, 0);
   do_test_attr(Obj1, attr4, 0);
   do_test_attr(Obj2, attr1, 0);
   do_test_attr(Obj2, attr3, 1);
   print "set_attr";
   do_set_attr(Obj1, attr3);
   do_set_attr(Obj1, attr4);
   do_set_attr(Obj1, attr1); ! test setting already set bit
   do_set_attr(Obj1, attr2);
   print "clear_attr";
   do_clear_attr(Obj2, attr3);
   do_clear_attr(Obj2, attr4);
   do_clear_attr(Obj2, attr1); ! test clearing already unset bit
   do_clear_attr(Obj2, attr2);
   print "set/clear/test_attr";
   do_big_attr_test(Obj3);

   print "^    get_next_prop";
   do_get_next_prop(Obj1, 0, propd);
   do_get_next_prop(Obj1, propd, propb);
   do_get_next_prop(Obj1, propb, propa);
   do_get_next_prop(Obj1, propa, 0);
   do_get_next_prop(Obj6, 0, prope);
   do_get_next_prop(Obj6, prope, 0);

   ! TODO figure out how to get a one-byte property
   ! Test stuffing a word into one-byte property.
   print "get_prop_len/get_prop_addr";
   do_prop_len(Obj1, propa, 2);
   do_prop_len(Obj1, propb, 2);
   do_prop_len(Obj1, propd, 6);
   do_prop_len(Obj6, prope, 2);
   
   print "^    get_prop";
   do_prop(Obj1, propa, 1);
   do_prop(Obj1, propb, 2);
   do_prop(Obj1, propc, 13);
   do_prop(Obj2, propd, 4);
   do_prop(Obj1, prope, 15);
   do_prop(Obj6, propa, 11);
   do_prop(Obj6, propb, 12);
   do_prop(Obj6, propc, 13);
   do_prop(Obj6, propd, 14);
   do_prop(Obj6, prope, 10000);

   print "put_prop";
   @put_prop Obj1 propa 2;
   do_prop(Obj1, propa, 2);
   @put_prop Obj1 propb 4;
   do_prop(Obj1, propb, 4);
   @put_prop Obj2 propd 8;
   do_prop(Obj2, propd, 8);
   @put_prop Obj6 prope 5000;       
   do_prop(Obj6, prope, 5000);   
   ! Test other things didn't change
   do_prop(Obj1, propc, 13);
   do_prop(Obj1, prope, 15);
   do_prop(Obj6, propa, 11);
   do_prop(Obj6, propb, 12);
   do_prop(Obj6, propc, 13);
   do_prop(Obj6, propd, 14);

   print "^    remove";
   @remove_obj Obj3;
   do_get_parent(Obj3, 0);
   do_get_parent(Obj4, Obj3); ! confirm didn't change
   print "insert";
   @insert_obj Obj4 Obj1;
   do_get_parent(Obj4, Obj1);
   do_get_sibling(Obj4, Obj2);
   do_get_sibling(Obj2, 0);
   do_get_child(Obj1, Obj4);
   @insert_obj Obj3 Obj4; ! insert parentless object
   do_get_child(Obj4, Obj3);
   do_get_parent(Obj3, Obj4);

#Ifdef V4PLUS;
!   if(Standard >= 1) {
   print "^    Spec1.0 length-64 props";
      do_get_next_prop(Obj5, 0, prope);
      do_get_next_prop(Obj5, prope, propc);
      do_get_next_prop(Obj5, propc, propb);
      do_get_next_prop(Obj5, propb, propa);
      do_get_next_prop(Obj5, propa, 0);
      do_prop_len(Obj5, propa, 2);
      do_prop_len(Obj5, propb, 6);
      do_prop_len(Obj5, propc, 58);
      do_prop_len(Obj5, prope, 64);
      do_prop(Obj5, propa, 1);
      @put_prop Obj5 propa 3;
      do_prop(Obj5, propa, 3);
!   }
#Endif;

   rtrue;
];

[ do_get_parent ch par i;
   @get_parent ch -> i;
   assert0(i, par);
];

[ do_get_sibling sib1 sib2 i;
   @get_sibling sib1 -> i ?sib_label;
   assert0(i, 0); ! make sure i only jumped if non-zero
   .sib_label;
   assert0(i, sib2);
];

[ do_get_child par ch i;
   @get_child par -> i ?child_label;
   assert0(i, 0); ! make sure i only jumped if non-zero
   .child_label;
   assert0(i, ch);
];

[ do_jin ch par expect;
   @jin ch par ?is_in;
   assert0(expect, 0);
   return;
   .is_in;
   assert0(expect, 1);
   return;
];

[ do_test_attr obj attr expect;
   @test_attr obj attr ?test_attr_label;
   assert0(expect, 0); ! make sure i only jumped if expect is non-zero
   return;
   .test_attr_label;
   assert0(expect, 1);
];

! This does depend on test_attr working too.
[ do_set_attr obj attr;
   @set_attr obj attr;
   @test_attr obj attr ?set_attr_label;
   f("set_attr/test_attr"); ! this should never happen!
   return;
   .set_attr_label;
   p();
];

! This does depend on test_attr working too.
[ do_clear_attr obj attr;
   @clear_attr obj attr;
   @test_attr obj attr ?~clear_attr_label;
   f("clear_attr/test_attr"); ! this should never happen!
   return;
   .clear_attr_label;
   p();
];

! Test that we can set/clear/test all attributes
[ do_big_attr_test obj i j k;
#Ifdef V4PLUS;
   k = 48;
#Ifnot;
   k = 32;
#Endif;
   @store j 0;
   for(i = 0: i < k: i++) {
      @set_attr obj i;
      @test_attr obj i ?good_set_label;
      j++; ! number of failed sets
      .good_set_label;
   }
   assert0(j, 0, "set_attr/test_attr");
   @store j 0;

   for(i = 0: i < k: i++) {
      @clear_attr obj i;
      @test_attr obj i ?~good_clear_label;
      j++; ! number of failed clears
      .good_clear_label;
   }
   assert0(j, 0, "clear_attr/test_attr");
   return;
];

[ do_prop obj prop expect i;
   @get_prop obj prop -> i; Ga = obj; Gb = prop;
   assert2(i, expect, ".");
];

[ do_get_next_prop obj prop next_prop i;
   @get_next_prop obj prop -> i; Ga = obj; Gb = prop;
   assert2(i, next_prop, "next");
];

[ do_prop_len obj prop expect i j;
   @get_prop_addr obj prop -> i;
   @get_prop_len i -> j; Ga = obj; Gb = prop;
   assert2(j, expect, ".#");
   !assert0(j, expect);
];

! ---- INDIRECT VARIABLES ----------------------------------
! Indirect-able opcodes: inc,  dec,  inc_chk,  dec_chk,  store,  pull,  load
! Spec Version 1.1 (draft7): "an indirect reference to the stack 
! pointer does not push or pull the top item of the stack - it is read
! or written in place."
! Based on my tests (see rec.arts.int-fiction 20031028), this seems to mean
! that, e.g., for load, you NEVER pop the stack, for all cases
! (a) load sp; (b) load [sp]; (c) i=0; load [i]; (d) sp=0; load [sp]; 
[ test_indirect do_this i;
   print "Indirect Opcodes";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   ! We don't have 100 tests, but we skip a bunch of i's to allow
   ! room for more tests. 
   for (i = 0: i < 100: i++) {
      do_indirect(i);
   }
];

! Run one indirect test. Push stuff onto stack, then do one command,
! see the result
! TODO add store, pull, inc, dec, inc_chk, dec_chk
! Overall rules:
! - Do NOT push/pop for "foo sp": write in place
! - DO pop for "foo [sp]". However, if top of stack is 0, only pop ONCE.
! - "bar = 0; foo [bar]" yields EXACTLY the same results as "foo sp"
!   ("push 0; foo [sp] is also identical to "foo sp".)
[ do_indirect which result local2 spointer lpointer gpointer rpointer
              top_of_stack which_str expectr expect1 expect2;
   local2 = 51;
   Gtemp = 61;
   result = 71;
   spointer = 0; ! stack
   rpointer = 2; ! points to 'result'
   lpointer = 3; ! local2
   gpointer = 21; ! '21' means 6th global, which is (hopefully!) Gtemp
   expectr = 999; ! don't test 'result' unless we change this value

   @push 41; @push 42; @push 43; @push 44; @push 45;
   switch (which) {
      ! load -> result
      0: print "load";
         @load sp -> result; ! compiles as 'load 0 -> result'
	 expectr = 45; expect1 = 45; expect2 = 44;
         which_str = "load sp -> result";
      1: @load [spointer] -> result;
	 expectr = 45; expect1 = 45; expect2 = 44;
         which_str = "load [spointer] -> result";
      2: @push lpointer; @load [sp] -> result;
	 expectr = 51; expect1 = 45; expect2 = 44;
         which_str = "load [sp=lpointer] -> result";
      3: @push spointer; @load [sp] -> result;
	 expectr = 45; expect1 = 45; expect2 = 44;
         which_str = "load [sp=spointer] -> result";

      ! load -> sp
      4: @load sp -> sp; 
	 expect1 = 45; expect2 = 45;
         which_str = "load sp -> sp";
      5: @push lpointer; @load [sp] -> sp; 
	 expect1 = 51; expect2 = 45;
         which_str = "load [sp=lpointer] -> sp";
      6: @push spointer; @load [sp] -> sp; 
	 expect1 = 45; expect2 = 45;
         which_str = "load [sp=spointer] -> sp";

      ! store
      10: print "store";
         @store sp 83;
	 expect1 = 83; expect2 = 44;
         which_str = "store sp 83";
      11: @store [spointer] 83;
	 expect1 = 83; expect2 = 44;
         which_str = "store [spointer] 83";
      12: @push spointer; @store [sp] 83;
	 expect1 = 83; expect2 = 44;
         which_str = "store [sp=spointer] 83";

      13: @store [rpointer] 83;
	 expectr = 83; expect1 = 45; expect2 = 44;
         which_str = "store [rpointer] 83";
      14: @push rpointer; @store [sp] 83;
	 expectr = 83; expect1 = 45; expect2 = 44;
         which_str = "store [sp=rpointer] 83";

      15: @store result sp;
	 expectr = 45; expect1 = 44; expect2 = 43;
         which_str = "store result sp";
      16: @store sp sp;
	 expect1 = 45; expect2 = 43;
         which_str = "store sp sp";
      17: @push spointer; @store [sp] sp;
	 expect1 = 45; expect2 = 43;
         which_str = "store [sp=spointer] sp";

      18: @store [rpointer] sp;
	 expectr = 45; expect1 = 44; expect2 = 43;
         which_str = "store [rpointer] sp";
      19: @push rpointer; @store [sp] sp;
	 expectr = 45; expect1 = 44; expect2 = 43;
         which_str = "store [sp=rpointer] sp";

      ! pull
      20: print "^    pull";
         @pull result;
	 expectr = 45; expect1 = 44; expect2 = 43;
         which_str = "pull result";
      21: @pull [rpointer];
	 expectr = 45; expect1 = 44; expect2 = 43;
         which_str = "pull [rpointer]";
      22: @push rpointer; @pull [sp];
	 expectr = 45; expect1 = 44; expect2 = 43;
         which_str = "pull [sp=rpointer]";

      23: @pull sp;
	 expect1 = 45; expect2 = 43;
         which_str = "pull sp";
      24: @push spointer; @pull [sp];
	 expect1 = 45; expect2 = 43;
         which_str = "pull [sp=spointer]";
      25: @pull [spointer];
	 expect1 = 45; expect2 = 43;
         which_str = "pull [spointer]";

      ! inc
      30: print "inc";
         @inc result;
	 expectr = 72; expect1 = 45; expect2 = 44;
	 which_str = "inc [rpointer]";
      31: @inc [rpointer];
	 expectr = 72; expect1 = 45; expect2 = 44;
	 which_str = "inc [rpointer]";
      32: @push rpointer; @inc [sp];
	 expectr = 72; expect1 = 45; expect2 = 44;
	 which_str = "inc [sp=rpointer]";

      33: @inc sp;
	 expect1 = 46; expect2 = 44;
	 which_str = "inc sp";
      34: @inc [spointer];
	 expect1 = 46; expect2 = 44;
	 which_str = "inc [spointer]";
      35: @push spointer; @inc [sp];
	 expect1 = 46; expect2 = 44;
	 which_str = "inc [sp=spointer]";

      ! dec
      40: print "dec";
         @dec result;
	 expectr = 70; expect1 = 45; expect2 = 44;
	 which_str = "dec [rpointer]";
      41: @dec [rpointer];
	 expectr = 70; expect1 = 45; expect2 = 44;
	 which_str = "dec [rpointer]";
      42: @push rpointer; @dec [sp];
	 expectr = 70; expect1 = 45; expect2 = 44;
	 which_str = "dec [sp=rpointer]";

      43: @dec sp;
	 expect1 = 44; expect2 = 44;
	 which_str = "dec sp";
      44: @dec [spointer];
	 expect1 = 44; expect2 = 44;
	 which_str = "dec [spointer]";
      45: @push spointer; @dec [sp];
	 expect1 = 44; expect2 = 44;
	 which_str = "dec [sp=spointer]";

      ! inc_chk
      50: print "^    inc_chk";
	 which_str = "inc_chk [rpointer]";
         @inc_chk result 72 ?bad_indirect_inc;
	 expectr = 72; expect1 = 45; expect2 = 44;
      51: which_str = "inc_chk [rpointer]";
         @inc_chk [rpointer] 72 ?bad_indirect_inc;
	 expectr = 72; expect1 = 45; expect2 = 44;
      52: which_str = "inc_chk [sp=rpointer]";
         @push rpointer; @inc_chk [sp] 72 ?bad_indirect_inc;
	 expectr = 72; expect1 = 45; expect2 = 44;

      53: which_str = "inc_chk sp";
         @inc_chk sp 46 ?bad_indirect_inc;
	 expect1 = 46; expect2 = 44;
      54: which_str = "inc_chk [spointer]";
         @inc_chk [spointer] 46 ?bad_indirect_inc;
	 expect1 = 46; expect2 = 44;
      55: which_str = "inc_chk [sp=spointer]";
         @push spointer; @inc_chk [sp] 46 ?bad_indirect_inc;
	 expect1 = 46; expect2 = 44;

      ! dec_chk
      60: print "dec_chk";
	 which_str = "dec_chk [rpointer]";
         @dec_chk result 70 ?bad_indirect_inc;
	 expectr = 70; expect1 = 45; expect2 = 44;
      61: which_str = "dec_chk [rpointer]";
         @dec_chk [rpointer] 70 ?bad_indirect_inc;
	 expectr = 70; expect1 = 45; expect2 = 44;
      62: which_str = "dec_chk [sp=rpointer]";
         @push rpointer; @dec_chk [sp] 70 ?bad_indirect_inc;
	 expectr = 70; expect1 = 45; expect2 = 44;

      63: which_str = "dec_chk sp";
         @dec_chk sp 44 ?bad_indirect_inc;
	 expect1 = 44; expect2 = 44;
      64: which_str = "dec_chk [spointer]";
         @dec_chk [spointer] 44 ?bad_indirect_inc;
	 expect1 = 44; expect2 = 44;
      65: which_str = "dec_chk [sp=spointer]";
         @push spointer; @dec_chk [sp] 44 ?bad_indirect_inc;
	 expect1 = 44; expect2 = 44;


      default: rfalse; ! do nothing.
   }

   ! Test results
   @je expectr 999 ?skip_expectr;
   assert0(result, expectr, which_str);
   .skip_expectr;
   @pull top_of_stack;
   assert0(top_of_stack, expect1, which_str);
   @pull top_of_stack;
   assert0(top_of_stack, expect2, which_str);
   !print which, "  ", result, "       ", top_of_stack, "       "; 
   !print stack2, "       ", stack3, "         ";
   !@print_paddr which_str;
   !print "^";

   ! TODO test "je sp a b c" to make sure not multi-popping stack, etc.
   ! TODO Test globals here

   rtrue;

   ! If you got here, inc_chk/dec_chk broke
   .bad_indirect_inc;
   ! Assert will give silly numbers, but correct which_str
   assert0(result, 123, which_str);
   rfalse;
];

! ---- MISC stuff ----------------------------------
[ test_misc do_this i j;
   print "Misc";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   print "test";
   @test $ffff $ffff ?~bad; p();
   @test $ffff     0 ?~bad; p();
   @test $1234 $4321 ?bad; p();
   jump good_test;
   .bad;
   f(" #  'test' opcode");
   .good_test;

   ! TODO randomizer table from nitfol test? 
   print "random";
   @random -32000 -> i;
   @random $100 -> i;
   @random -32000 -> j;
   @random $100 -> j;
   assert0(i, j);

   ! I can't think of a way to test for a bad checksum...
   print "verify";
   i = 0;
   @verify ?good_verify;
   i = 1;
   .good_verify;
   assert0(i, 0);

#Ifdef V5PLUS;
   print "piracy";
   i = 0;
   @piracy ?good_piracy;
   i = 1;
   .good_piracy;
   assert0(i, 0);
#Endif;

   rtrue;
];


! ---- OUTPUT STREAM stuff ----------------------------------
[ test_open_output_streams do_this;
   print "Output Stream (2 and 4)";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]^";

   @output_stream 2;
   @output_stream 4;

   rtrue;
];

[ test_close_output_streams do_this;
   print "Close Output Streams";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]^";

   @output_stream -4;
   @output_stream -1; pt();
   print "Only to stream 2.^";
   @output_stream 1; pt();
   print "Stream 1 and 2 again.";
   @output_stream -2;
   print "Only stream 1.";

   rtrue;
];

! ---- READ stuff ----------------------------------

! Just for fun: rooms for the status line in v3
Object Zork1_Room "West of House";
! TODO get correct names
! Bureaucracy room for empty string or A2 string
Object H2G2_Room "Vogon Hold";
Object Zork3_Room "Beach";

! Phrases to be typed in
!              0         1         2         3
!              012345678901234567890123456789012
Array h2g2 -> "ask hitchhiker's about babel fish";
Array sail -> " hello,sailor. ";
! Weird chars: note '~' will be replaced by quotation marks & backslash later
Array a2ch -> "type~012 345 678 9!? _#' /~- :()~";
! TODO empty line
Array none -> "";
! TODO ZSCII, accented chars

! Expected parsing results
! Conveniently set up dictionary at the same time.
! Letters in string, words in string
! Then triplets of word, word length, index in string
! Don't include 'babel', so it's an unknown word
! Use hitchhiked instead of hitchhiker's to test word length
Array h2g2test --> 33 5 
   'ask' 3 2 
   'hitchhiked' 12 6 
   'about' 5 19 
   0 5 25 
   'fish' 4 31;
Array sailtest --> 15 4 
   'hello' 5 3 
   ',//' 1 8 
   'sailor' 6 9 
   './/' 1 15;
Array a2chtest --> 33 10
   'type' 4 2 
   '~//' 1 6 ! ~ translates to a " in the dictionary
   '012' 3 7 
   '345' 3 11 
   '678' 3 15
   '9!?' 3 19
   '_#^' 3 23
   '/\-' 3 27
   ':()' 3 31
   '~//' 1 34;
Array nonetest --> 0 0;
! Put more stuff into dictionary that just might confuse broken progs
Array extras --> 'hit' 'hitch';
!Array mary -> "mary had a microscopic lamb";
!Array marytest --> 27 5 'mary' 4 2 0 3 7 'a//' 1 11 'microscopic' 11 13 'lamb' 4 25;

[ test_non_interactive_read do_this;
   print "Non-interactive read";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]^";
   print "Type the phrase between > and < (not counting those chars).^";
   print "Spacing must be exactly the same, but it's case-insensitive.^";

   ! Default separators: . , "

   count = H2G2_Room;
   do_ni_read(h2g2, h2g2test);
   count = Zork3_Room;
   do_ni_read(sail, sailtest);
   count = Zork1_Room;
   do_ni_read(none, nonetest);
   ! Put quotation marks and backslash into the string
   @storeb a2ch 4 34;
   @storeb a2ch 26 92;
   @storeb a2ch 32 34;
   do_ni_read(a2ch, a2chtest);

   rtrue;
];

[ do_ni_read to_type expected offset letters total_typed i j result compare
       testptr resptr strings_same;

   ! Print the string they should type
   print "^>";
   !print "Mary had a microscopic lamb";
   @loadw expected 0 -> letters; ! expected number of letters in string
   @dec letters;
   @store offset 0;
   @store j to_type;
   .str_loop;
      @loadb to_type offset -> sp;
      @print_char sp;
      @inc_chk offset letters ?~str_loop;
   .end_str_loop;
   print "<^>";

   ! Get user input
   ! v1-4, byte 0 has max letters to be typed MINUS 1
   ! In 5+, byte 0 has max letters typed
   @storeb mytable 0 100; ! number of characters allowed
   @storeb mysecond 0 20; ! number of tokens allowed
   ! Use 'read' instead of '@read' so it works in Inform for v3 AND v5
   read mytable mysecond;

   ! First test text array
   letters = 0;
#Ifdef V5PLUS; ! byte 1 has number of letters actually typed
   offset = 2;
   @loadb mytable 1 -> total_typed;
   @loadw expected 0 -> i;
   assert0(total_typed, i, "Letters typed");
!   print "Typed ", total_typed,"^";
#Ifnot;
   total_typed = 0; ! make compiler happy. We don't use total_typed for v3/4
   offset = 1;
#Endif;
   strings_same = 1;

   .letter_loop;
      @add offset letters -> sp;
      @loadb mytable sp -> i;
      @loadb to_type letters -> j; 
      ! Get out of the loop if we read a zero or have typed total_typed letters
#Ifdef V5PLUS;
      @inc_chk letters total_typed ?did_read;
#Ifnot;
      @inc letters;
      @jz i ?did_read;
#Endif;
   @je i j ?letter_loop;
   ! If we get here, strings were unequal
   strings_same = 0;
   @dec letters; ! undo the inc above so we say we mismatched at correct char

   .did_read;
   Ga = letters; ! hack to pass arg to assert1 when compiling as v3
   assert1(strings_same, 1, "strings differ at char ");

   ! test parsing array
   @loadb mysecond 1 -> i;
   @loadw expected 1 -> j;
   assert0(i, j, "Number of words in parse buffer");
   @store resptr mysecond;
   @store testptr expected; 
   @add 2 resptr -> resptr; @add 4 testptr -> testptr; ! skip length bytes
   @store j 0;
   .parse_loop;
   @je j i ?end_parse_loop;
   ! testptr has two bytes per entry. resptr is sometimes 1, sometimes 2
   ! So always inc testptr by two and use loadw
      @loadw resptr 0 -> result; @loadw testptr 0 -> compare;
      assert0(result, compare, "dict location");
      !print dict," ";
      @add 2 resptr -> resptr; @add 2 testptr -> testptr;
      @loadb resptr 0 -> result; @loadw testptr 0 -> compare;
      assert0(result, compare, "length");
      !print length," ";
      @inc resptr; @add 2 testptr -> testptr;
      @loadb resptr 0 -> result; @loadw testptr 0 -> compare;
#Ifndef V5PLUS; ! earlier versions have string index smaller by 1
      @dec compare;
#Endif;
      assert0(result, compare, "string index");
      !print position,"^";
      @inc resptr; @add 2 testptr -> testptr;
      @inc j;
   jump parse_loop;
   .end_parse_loop;

   ! TODO v5 allows read array 0, which doesn't parse
   ! TODO assert return value from read is 10
   rtrue;
];



! Only purpose of this sub is to use vars declared in included files
! so the compiler doesn't complain.
[ make_compiler_happy_non_io i j;
!   @loadw mysecond i -> j;
   i = j = 0;
   i = extras;
   if (0) make_compiler_happy_non_io();
];

! vim: tw=78 sw=3 ft=Inform
