#
# The following variable needs to be set full a full test.
# It needs to be set to a ISAM file with an internal resource structure
#
$testIfile = "/appl/plexar/master/custgrp.dat";

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..last\n"; }
END {print "not ok 1\n" unless $loaded;}

use Db::Ctree qw(:ALL);

$loaded = 1;
$t=0;
printf "test %2d %-20s",$t++,"Load ";
print "ok \n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# ISAM Function tests
#
   $pfile="$ENV{PWD}/ctperl.p";
   print "Ctree parameter file $pfile not found" unless -e $pfile;

   printf "test %2d %-20s",$t++,"CreateISAM ";
   if ($status = CreateISAM($pfile) )
   {
       if ($status == &DOPN_ERR)
       {
          print "File Already Exists\n";
       }
       else
       {
          printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
          die "Fatal Error!\n"
       }
   }
   else
   {
        print "OK\n";
        CloseISAM();
   }

#-----------------------
   printf "test %2d %-20s",$t++,"OpenISAM  ";
   if ($status = OpenISAM($pfile) )
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
      die "Fatal Error!\n"
   }
   print "OK\n";

#-----------------------
   printf "test %2d %-20s",$t++,"AddRecord  ";
   $record = sprintf ("a%29s","".localtime());
   if ($status = AddRecord(1,$record ))
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
   }
   print "OK $record\n";

#-----------------------
   printf "test %2d %-20s",$t++,"AddRecord(2)  ";
   $record = sprintf ("b%29s","".localtime());
   if ($status = AddRecord(1,$record ))
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
   }
   print "OK $record\n";

#-----------------------
   printf "test %2d %-20s",$t++,"FirstRecord  ";
   $record = " "x30;
   if ($status = FirstRecord(2,$record ))
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
   }
   print "OK $record\n";

#-----------------------
   printf "test %2d %-20s",$t++,"NextRecord  ";
   $record = " "x30;
   if ($status = NextRecord(2,$record ))
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
   }
   print "OK $record\n";

#-----------------------
   printf "test %2d %-20s",$t++,"LastRecord  ";
   $record = " "x30;
   if ($status = LastRecord(2,$record ))
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
      die "Fatal Error!\n"
   }
   print "OK $record\n";

#-----------------------
   printf "test %2d %-20s",$t++,"PreviousRecord  ";
   $record = " "x30;
   if ($status = PreviousRecord(2,$record ))
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
      die "Fatal Error!\n"
   }
   print "OK $record\n";
   CloseISAM();

#-----------------------
#
# Further tests require an existing datafile with a resource structure!
#
   print "\n\nfollowing tests use $testIfile\n";
   die "\nfile not found.. cannot test advanced functions\n"
         unless -e $testIfile;

#-----------------------
   printf "test %2d %-20s",$t++,"Initisam  ";
   $init=&InitISAM(10,2,4);
   if (! defined $init)
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
      die "Fatal Error!\n"
   }
   print "OK $record\n";

#-----------------------
   Db::Ctree::DEBUG(5);
   printf "test %2d %-20s",$t++,"tied hash open";
   $dbptr  = tie %hash, "Db::Ctree",2, $testIfile,&SHARED;
   if (! defined %hash)
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
      die "Fatal Error!\n"
   }
   print "OK\n";

#-----------------------
   printf "test %2d %-20s",$t++,"Hash keys";
   @key= keys(%hash);
   if ($#key)
   {
      printf "OK %d found\n",$#key+1;
   }
   else
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
   }

#-----------------------
   printf "test %2d %-20s",$t++,"Hash fetch";
   $record  = $hash{$key[0]};
   if ($record)
   {
      print "OK $record\n";
   }
   else
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
   }

#-----------------------
   printf "test %2d %-20s",$t++,"unpack record";
   %record  = $dbptr -> unpack_record($record);
   if (defined %record)
   {
      @col = keys(%record);
      printf "OK %d columns unpacked\n",$#col+1;
   }
   else
   {
      printf "failed -- IFIL structure loaded?\n";
   }

#-----------------------
   printf "test %2d %-20s",$t++,"CloseISAM ";
   if (&CloseISAM() )
   {
      printf "Failed isam_err=%d, isam_fil=%d\n",&isam_err,&isam_fil;
   }
   else
   {
      print "OK\n";
   }


