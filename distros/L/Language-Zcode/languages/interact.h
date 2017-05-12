!! CZECH: Comprehensive Z-machine Emulation CHecker
!!
!! Tests requiring user interaction (input or looking at output)
!!
!! Amir Karger
!! See README.txt for license. (Basically, use/copy/modify, but be nice.)

!! TODO
!! - output_streams using different input streams
!! - exhaust input file OR switch it off manualy
!! - show_status #ifndef V4PLUS
!! - 'read' opcode using either input stream & various output streams
!! - transcript bit set/cleared correctly for stream 2
!! - 'read' word separators and space separation
!! - use set_cursor to print a magic square. Also in upper window.
!!   Also, create frame in lower window, fill in in upper
!! - text styles (in different windows (and streams?)
!! - more amusing print strings

! ---- PRINT opcodes ----------------------------------
[ test_print do_this i j;
   print "Print opcodes";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   ! Note: pt()'s best location is after you print what should come out
   ! and before you actually print it. But we may get some off-by-ones
   @print "Tests should look like... '[Test] opcode (stuff): stuff'";
   @print "^print_num (0, 1, -1, 32767,-32768, -1): "; pt();
   @print_num 0; print ", ";
   i = 1;
   @print_num i; print ", "; pt();
   @print_num n1; print ", "; pt();
   @print_num 32767; print ", "; pt();
   @print_num n32768; print ", "; pt();
   i = 65535;
   @print_num i; pt();
   print "^[", Testnum+1, "] ";
   print "print_char (abcd): ";
   @print_char 'a'; pt();
   @print_char 98; pt();
   i = 99;
   @print_char i; pt();
   @push 100; pt();
   @print_char sp;
   @print_char 13; pt();
   @print "This string should be on its own line.";
   print "^[", Testnum+1, "] ";
   print "new_line:^"; pt();
   @new_line;
   @print "There should be an empty line above this line.^";
   i = do_print_ret(); pt(); ! test printing AND return
   assert0(i, 1);

   ! TODO Once we have objects, print_addr of first word in dictionary.

   ! I could also write stuff to globalvars (as long as I knew what
   ! offset they'd have) then load the address from 0->0c and print_addr.
   @print "^print_addr (Hello.): "; pt();
   @storew mytable 0 $11aa; ! 4 13 10: Shift-He
   @storew mytable 1 $4634; ! 17 17 20: llo
   @storew mytable 2 $1645; ! 5 18 5: A2 . A2
   @storew mytable 3 $9ca5; ! 7 5 5: \n space-fill
   ! FYI xyzzy is 77df ffc5
!   print mytable->1;
   @print_addr mytable;
   @print "^print_paddr (A long string that Inform will put in high memory):^";
   pt();
   print "A long string that Inform will put in high memory";
   ! Break up print statement to NOT use abbrev in parenthetical part
   print "^Abbreviations (I love 'xyz"; print "zy' [two times]): "; pt();
   i = "I love 'xyzzy' ";
   @print_paddr i;
   pt();
   @print " I love 'xyzzy'^";
   ! TODO @print_paddr sp, global vars
   ! TODO test word wrapping

   print "^[", Testnum+1, "] ";
   @print "print_obj (Test Object #1Test Object #2): "; pt();
   @print_obj Obj1; pt();
   @print_obj Obj2;
! TODO long test object name

   ! Word wrap
   pt();
   print "^This is an extremely long string which should definitely get wrapped even if you have a whole lot of columns in your particular output device, whatever it may be.^";

   ! More
   i = 0->32;
   @je i 255 ?skip_more;
   pt();
   print "Test paging functionality^";
   for (j = 0: j < i * 2 + 5: j++) print j,"^";
   .skip_more;

   ! TODO print many more complicated things, Unicode, whatever
   ! TODO use unfinished abbreviations.

   rtrue;
];

[ do_print_ret;
   @print_ret "print_ret (should have newline after this)";
];

! ---- Header ----------------------------------


!Global standard;

[ test_header do_this flags i j;
   print "Header";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   !print " [", Testnum+1, "]: ";
   print " (No tests)";
!   standard = 0->50;
   @loadb 0 50 -> i;
   @loadb 0 51 -> j;
   if(i || j)
      print "^    standard ", i, ".", j, " ";
   !print "interpreter ", 0->30, (char) 0->31;
   @loadb 0 30 -> i;
   print "^    interpreter ", i, " "; 
   @loadb 0 31 -> i;
   @print_char i;
   @loadb 0 30 -> i;
   print " ("; say_platform(i); print ")";

   for(i = 0: i < 2: i++) {
      if(i == 0)
	 print "^    Flags on: ";
      else
	 print "^    Flags off: ";
      
      @loadb 0 1 -> flags;
#Ifdef V4PLUS;
      do_say_flags(i, flags & 1, "color");
      do_say_flags(i, flags & 2, "pictures");
      do_say_flags(i, flags & 4, "boldface");
      do_say_flags(i, flags & 8, "italic");
      do_say_flags(i, flags & 16, "fixed-space");
      do_say_flags(i, flags & 32, "sound");
      do_say_flags(i, flags & 128, "timer");
#Ifnot;
      do_say_flags(i, flags & 2, "time game");
      do_say_flags(i, flags & 4, "story file split");
      do_say_flags(i, flags & 16, "NO status");
      do_say_flags(i, flags & 32, "screen-splitting");
      do_say_flags(i, flags & 64, "variable-pitch-default");
#Endif;

      !flags2
      @loadw 0 8 -> flags;
      do_say_flags(i, flags & 1, "transcripting on");
      do_say_flags(i, flags & 2, "fixed-pitch on");
#Ifdef V5PLUS;
      ! TODO comment out v6 stuff if #version_number == 5
      do_say_flags(i, flags & 4, "redraw pending");
      do_say_flags(i, flags & 8, "using pictures");
      do_say_flags(i, flags & 16, "using undo");
      do_say_flags(i, flags & 32, "using mouse");
      do_say_flags(i, flags & 64, "using colors");
      do_say_flags(i, flags & 128, "using sound");
      do_say_flags(i, flags & 256, "using menus");
#Endif;
   }

#Ifdef V4PLUS;
   ! These are all width x height
   print "^    Screen size: ", 0->33, "x", 0->32;
#Endif;
#Ifdef V5PLUS;
   print "; in ", 0->38, "x", 0->39, " units: ", 0-->17, "x", 0-->18;
   print "^    Default color: ";
   say_color(0->45); print " on "; say_color(0->44);
#Endif;
! TODO v6 has font width/height switched

   @loadb 0 56 -> i;
   if (i) {
      print "^    User: ";
      for(i = 56: i < 64: i++)
	 @loadb 0 i -> j;
	 @print_char j;
   }
];

[ do_say_flags i cond text;
   if((~~cond) == i) {
      @print_paddr text;
      print ", ";
   }
];

#Ifdef V5PLUS;
[ say_color c;
   switch(c) {
   0: print "current"; return;
   1: print "default"; return;
   2: print "black"; return;
   3: print "red"; return;
   4: print "green"; return;
   5: print "yellow"; return;
   6: print "blue"; return;
   7: print "magenta"; return;
   8: print "cyan"; return;
   9: print "white"; return;
   10: print "light grey"; return;
   11: print "medium grey"; return;
   12: print "dark grey"; return;
   }
   print "UNKNOWN";
];
#Endif;

[ say_platform p;
   switch(p) {
   1: print "DECSystem-20"; return;
   2: print "Apple IIe"; return;
   3: print "Macintosh"; return;
   4: print "Amiga"; return;
   5: print "Atari ST"; return;
   6: print "IBM PC"; return;
   7: print "Commodore 128"; return;
   8: print "Commodore 64"; return;
   9: print "Apple IIc"; return;
   10: print "Apple IIgs"; return;
   11: print "Tandy Color"; return;
   }
];

! ---- Streams ----------------------------------
[ test_streams do_this;
   print "Streams";
   @jz do_this ?~skipped;
   print " skipped";
   rfalse;
.skipped;
   print " [", Testnum+1, "]: ";

   print "output_stream^";
   pt();
   @output_stream(-1);
   print "This shouldn't print.^"; pt();
   @output_stream(1);
   print "1 (only). "; pt();
   @output_stream(2);
   print "1 and 2. "; pt();
   ! TODO I should be calling other print calls

   @output_stream(-1);
   print "2 again (only). "; pt();
   @output_stream(-2);
   print "This shouldn't print.^"; pt();

   pt();
   @output_stream(1);
   print "1 only again.^";

!   @output_stream 3 mytable;
!   print "...looks ";
!   @output_stream 3 mysecond;
!   print " to me...";
!   @output_stream -3;
!   print "good";
!   @output_stream -3;
!   for(i = 0: i < mytable-->0: i++)
!      print (char) mytable->(i+2);
!   for(i = 0: i < mysecond-->0: i++)
!      print (char) mysecond->(i+2);
   

   rtrue;
];






! Only purpose of this sub is to use vars declared in included files
! so the compiler doesn't complain.
[ make_compiler_happy_io i;
   i = n2; i = n3; i = n4; i = n5; i = n500; i = n32768;
   i = count;
   i = Gtemp;
   i = 0; if (i) make_compiler_happy_io();
   assert1(1, 1);
   assert2(1, 1, "foo", 1, 1);
];

! vim: tw=78 sw=3 ft=Inform
