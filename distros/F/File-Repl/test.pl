# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use lib 'blib/lib';
use File::HomeDir;
BEGIN { $| = 1; print "1..16\n"; }
my($testno);
END {
  unless ($ok){
    print "not ok $testno\n";
    print "All further tests skipped\n";
  }
}
# #####################################################################
######################## First test - check the module loads
$testno = 1;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
use File::Repl;
$ok = 1;
print "\n\tok $testno - File::Repl module loaded\n";
######################## Alternative way to test module is installed
#eval
#{
#  require Term::ReadKey;
#  Term::ReadKey->import();
#};
#unless($@)
#{
#  # Term::ReadKey loaded and imported successfully
#  ...
#}

#
######################### End of black magic.


######################## test 2 - check File::Temp module loads
# this is required to create temporary data structure for remaining tests
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - loaded module File::Temp required for testing\n";
use File::Temp qw/ tempfile tempdir /;
$ok = 1;
print "\n\tok $testno - loaded module File::Temp required for testing\n";

######################## - check File::Find module loads
# this is required to search/find files created during testing
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - loaded module File::Find required for testing\n";

use File::Find;
$ok = 1;
print "\n\tok $testno - loaded module File::Find required for testing\n";

######################## - check use File::Compare; module loads
# this is required to test files comparisons following replication
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - loaded module File::Compare required for testing\n";
use File::Compare;
$ok = 1;
print "\n\tok $testno - loaded module File::Compare required for testing\n";

######################## - Create common directories/variables for testing
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - created temporary directory $dir and variables for testing\n";
$dir = tempdir ( CLEANUP => 1);
$dira       = $dir . '/file-repl.tsta';
$dirb       = $dir . '/file-repl.tstb';
$atarget    = $dira . '/a/b/c/d/e';
$btarget    = $dirb . '/a/b/c/d/e';
@files      = qw( foo.tst ABCDE.XYZ abcde.xyz bar.pl dummy.c );
$debug      = 1;
$result     = 0;
mkdir $dira;
mkdir $dirb;

my(%hash);
%hash = (
  'dira',      $dira,
  'dirb',      $dirb,
  'age',       '10',
  verbose => 1,
);

$ok = 1;
print "\n\tok $testno - created temporary directory $dir and variables for testing\n";
#######################  - check New method
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - sucessfully created New instance of File::Repl\n";
if ($ref=File::Repl->New(\%hash)){
  $ok = 1;
  }else{
  exit;
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - sucessfully created New instance of File::Repl\n";

#######################  - check version is reported by module
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - File::Repl reports version as $ver\n";
if ($ver = $ref->Version){
  $ok = 1;
  }else{
  print "\tFile::Repl failed to report versionas\n";
  exit;
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - File::Repl reports version as $ver\n";

#######################
#   replicate files and directory structure with Update method a>b
#   should only update existing files in $dirb structure
#   (and since there are none no files should be replicated)
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - Update(a>b) method tested\n";
&_s1($dira,@files);   # Create source and data directories

$ref=File::Repl->New(\%hash);
$ref->Update('.*','a>b',1);
undef $ref;
# deem this successful if NO files have been replicated successfully from a to be
$ok = 1;
@bfiles = @files;
print "\t";
TESTA: foreach (@files) {
  if ( (&_s4($atarget . '/' . $_,  $btarget . '/' . $_)) == 2 ) {
    print "\tfile $_ did not replicate from $atarget to $btarget - ok\n" if $debug;
    print "." unless $debug;
    }else{
    print "\tfile $_ replicated from $atarget to $btarget - not ok\n";
    $ok = 0;
    last TESTA;
  }
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - Update(a>b) method tested\n";

#######################
#   Test the A>B option does not replicate if commit argument is set to 0
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - Update(A>B) with commit=0 method tested\n";
&_s1($dira,@files);   # Create source and data directories
$ref=File::Repl->New(\%hash);
$ref->Update('.*','A>B',0);
undef $ref;
# deem this successful if NO files have been replicated successfully from a to be
$ok = 1;
#print "\t";
TESTB: foreach (@files) {
  if ( (&_s4($atarget . '/' . $_,  $btarget . '/' . $_)) == 2 ) {
    print "\tfile $_ did not replicate from $atarget to $btarget - ok\n" if $debug;
    print "." unless $debug;
    }else{
    print "\tfile $_ replicated from $atarget to $btarget - not ok\n";
    $ok = 0;
    last TESTB;
  }
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - Update(A>B) with commit=0 method tested\n";

#######################
#   Test the A>B option does replicate all files if commit argument is set to 1
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - Update(A>B) with commit=1 method tested\n";
&_s1($dira,@files);   # Create source and data directories
$hashref = {
  'dira',      $dira,
  'dirb',      $dirb,
  'verbose',   4,
  'mkdirs', 0,
  'age',9999999
};
$ref=File::Repl->New($hashref);
$ref->Update('.*','A>B',1);
undef $ref;
# deem this successful if ALL files have been replicated successfully from a to be
$ok = 1;
print "\t" unless $debug;
TESTC: foreach (@files) {
  if ( (&_s4($atarget . '/' . $_,  $btarget . '/' . $_)) == 0 ) {
    print "\tfile $_ replicated from $atarget to $btarget - ok\n" if $debug;
    print "." unless $debug;
    }else{
    print "\tfile $_ did not replicate from $atarget to $btarget - not ok\n";
    $ok = 0;
    last TESTC;
  }
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - Update(A>B) with commit=1 method tested\n";
# #####################################################################
#   Test the a>b option does not replicate a file when the destination is newer
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - Update(a>b) with commit=1 method tested - does not overwrite newer file\n";
@afiles = @files;
$tstfile = pop @afiles;
$tstfilea = $atarget . '/' . $tstfile;
$tstfileb = $btarget . '/' . $tstfile;
my($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
$atime,$mtime,$ctime2,$blksize2,$blocks2)
= stat($tstfilea);

print "\trevising mtime on file $tstfileb from $mtime to" if $debug;
$mtime = $mtime +10;
print " $mtime \n" if $debug;
utime ($atime,$mtime, $tstfileb);
$hashref = {
  'dira',      $dira,
  'dirb',      $dirb
};
$ref=File::Repl->New($hashref);
$ref->Update('.*','a>b',1);
undef $ref;
# deem this successful if ALL files have been replicated successfully from a to be
$ok = 1;
print "\t" unless $debug;
TESTD: foreach (@files) {
  $result = (&_s4($atarget . '/' . $_,  $btarget . '/' . $_));
  if ( $result == 0 ) {
    if ( $tstfile eq $_ ) {
      print "\tfile $_ was replicated from $atarget to $btarget - not ok\n";
      $ok = 0;
      last TESTD;
      }else{
      print "\tfile $_ is identical in $atarget and $btarget - ok\n" if $debug;
      print "." unless $debug;
    }
    }elsif ( ($result == 5) && ( $tstfile eq $_ ) ) {
    print "\tfile $_ has not been replicated from $atarget to $btarget - ok\n" if $debug;
    print "." unless $debug;
    }else{
    print "\tfile $_ did not replicate from $atarget to $btarget - not ok\n";
    $ok = 0;
    last TESTD;
  }
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - Update(a>b) with commit=1 method tested - does not overwrite newer file\n";
# #####################################################################
#   Test the a>b option remove an older destination directory and replace it with a file
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - Update(a>b) with commit=1 method tested - remove an older destination directory and replace it with a file\n";
@afiles = @files;
$tstfile = pop @afiles;
$tstfilea = $atarget . '/' . $tstfile;
$tstfileb = $btarget . '/' . $tstfile;
my($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
$atime,$mtime,$ctime2,$blksize2,$blocks2)
= stat($tstfilea);

# replace the test file with a directory
print "\n\treplace destination file $tstfileb with a directory of the same name" if $debug;
$mtime = $mtime -10;
#print " $mtime \n" if $debug;
unlink($tstfileb) || die "   -   unable to remove $tstfileb ($!)\n";
mkdir($tstfileb) || die "   -   unable to create directory $tstfileb ($!)\n";
utime ($atime,$mtime, $tstfileb);

$hashref = {
  'dira',      $dira,
  'dirb',      $dirb,
  'verbose', 0,
};
$ref=File::Repl->New($hashref);
$ref->Update('.*','a>b',1);
undef $ref;
# deem this successful if file $tstfile has been replicated successfully from a to be
$ok = 0;
print "\t" unless $debug;
TESTE: foreach (@files) {
  $result = (&_s4($atarget . '/' . $_,  $btarget . '/' . $_));
  if ( $tstfile eq $_ ) {
    if ( $result == 0 ) {
      print "\tfile $_ was replicated from $atarget to $btarget - ok\n";
      $ok = 1;
      last TESTE;
      }else{
      print "\tfile $_ is not identical in $atarget and $btarget - not ok\n" if $debug;
      print "." unless $debug;
    }
  }
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - Update(a>b) with commit=1 method tested - remove an older destination directory and replace it with a file\n";
# #####################################################################
#   Test the a>b option - with a newer destination directory (removes it and replaces it with a file)
$testno++;
undef $ok;
print "\ntest $testno:XXX--------------------------------------------------------------------------\n";
print "\t - Update(a>b) with commit=1 method tested - with a newer destination directory (removes it and replaces it with a file)\n";
@afiles = @files;
$tstfile = pop @afiles;
$tstfilea = $atarget . '/' . $tstfile;
$tstfileb = $btarget . '/' . $tstfile;
my($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
$atime,$mtime,$ctime2,$blksize2,$blocks2)
= stat($tstfilea);

# replace the test file with a directory
print "\n\treplace destination file $tstfileb with a directory of the same name" if $debug;
$mtime = $mtime +10;
#print " $mtime \n" if $debug;
unlink($tstfileb) || die "   -   unable to remove $tstfileb ($!)\n";
mkdir($tstfileb) || die "   -   unable to create directory $tstfileb ($!)\n";
utime ($atime,$mtime, $tstfileb);


$hashref = {
  'dira',      $dira,
  'dirb',      $dirb,
  'verbose', 0,
};
$ref=File::Repl->New($hashref);
$ref->Update('.*','a>b',1);
undef $ref;
# deem this successful if file $tstfile has been replicated successfully from a to be
$ok = 0;
print "\t" unless $debug;
TESTF: foreach (@files) {
  $result = (&_s4($atarget . '/' . $_,  $btarget . '/' . $_));
  if ( $tstfile eq $_ ) {
    if ( $result == 0 ) {
      print "\ttest object $_ is a different type in $atarget and $btarget (as expected)- ok\n";
      $ok = 1;
      last TESTF;
      }else{
        print "\$result $result ($_)\n";
    }
  }
}
exit unless ( $ok eq 1 );

# restore original test dir structure




print "\n\tok $testno - Update(a>b) with commit=1 method tested - with a newer destination directory (removes it and replaces it with a file)\n";
# #####################################################################
#   Test the a>b option does replicate a file when the destination is older
#   This tests that the $tstfile from test 5, after the replica in $targetb is made
#   older than the original in $targeta, is replicated succesfully
$testno++;
undef $ok;
print "\ntest $testno:---------------------------------------------------------------------------\n";
print "\t - Update(a>b) with commit=1 method tested - does overwrite older file\n";
my($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
$atime,$mtime,$ctime2,$blksize2,$blocks2)
= stat($tstfilea);

print "\trevising mtime on file $tstfileb from $mtime to" if $debug;
$mtime = $mtime -20;
print " $mtime \n" if $debug;
utime ($atime,$mtime, $tstfileb);
$hashref = {
  'dira',      $dira,
  'dirb',      $dirb
};
$ref=File::Repl->New($hashref);
$ref->Update('.*','a>b',1);
undef $ref;
# deem this successful if ALL files in a and b are identical
$ok = 1;
print "\t" unless $debug;
TESTY: foreach (@files) {
  $result = (&_s4($atarget . '/' . $_,  $btarget . '/' . $_));
  if ( $result == 0 ) {
    print "\tfile $_ is identical in $atarget and $btarget - ok\n" if $debug;
    print "." unless $debug;
    }else{
    print "\tfile $_ in $atarget to $btarget is different- not ok\n";
    $ok = 0;
    last TESTY;
  }
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - Update(a>b) with commit=1 method tested - does overwrite older file\n";
# #####################################################################
#   Delete One file from dira and verify it is not deleted using the A>B  argument
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - Update(A>B) with commit=1 method tested - does not delete file in dirb when missing from dira\n";
$hashref = {
  'dira',      $dira,
  'dirb',      $dirb
};
$ref=File::Repl->New($hashref);
$ref->Update('.*','A>B',1);
undef $ref;
# deem this successful if ALL files have been replicated successfully from a to be
$ok = 1;
@afiles = @files;
$tstfile = pop @afiles;
$tstfile = $atarget . '/' . $tstfile;
unlink $tstfile || die "Failed to delete $tstfile ($!)\n";
print "\tTest file is $tstfile\n";
print "\t" unless $debug;
TESTF: foreach (@files) {
  if (($atarget . '/' . $_ ) eq $tstfile) {
    unless ( (&_s4($atarget . '/' . $_,  $btarget . '/' . $_)) == 0 ) {
      print "\tfile $_ did not replicate from $atarget to $btarget - ok\n" if $debug;
      print "." unless $debug;
      }else{
      print "\tfile $_ replicated from $atarget to $btarget - not ok\n";
      $ok = 0;
      last TESTF;
    }
    }else{
    if ( (&_s4($atarget . '/' . $_,  $btarget . '/' . $_)) == 0 ) {
      print "\tfile $_ replicated from $atarget to $btarget - ok\n" if $debug;
      print "." unless $debug;
      }else{
      print "\tfile $_ did not replicate from $atarget to $btarget - not ok\n";
      $ok = 0;
      last TESTF;
    }
  }
}
exit unless ( $ok eq 1 );
print "\n\tok $testno - Update(A>B) with commit=1 method tested - does not delete file in dirb when missing from dira\n";
# #####################################################################
#   Test Delete method.  Delete one file from dira
$testno++;
undef $ok;
print "\ntest $testno:--------------------------------------------------------------------------\n";
print "\t - Delete method tested\n";
&_s1($dira,@files);   # Create source and data directories
my($tfile) = "$atarget/bar.pl";
$ok = 0;
if ( -f $tfile ){
#   for the test to succeed the test file must be installed, so set to 2
  $ok = 2;
#print "test file $tfile installed\n";
}

%hash = (
  dira       => $dira,
  dirb       => $dira,
  verbose    => 0,
);
$ref=File::Repl->New(\%hash);
$ref->Delete('bar\.pl', 1);
print "." unless $debug;
if ( -f $tfile ){
  $ok = 0;
  print "test file $tfile remains\n";
  }elsif( $ok == 2) {
#   only get here if the file does not remain, but was installed
  $ok = 1;
  print "\ttest file deleted succesfully\n" if $debug;
}
print "\tfailed to remove test file\n" unless ($ok == 1);
undef $ref;

exit unless ( $ok eq 1 );
  print "\n\tok $testno - Delete method tested\n";
  $testsok ++;
# ##################################################################### if we get here then print all OK
print "\nall tests completed OK\n";

 chdir(File::HomeDir->my_home);
exit;
#########################################################################################################



#  $r1 = $ref->Update('\.p(l|m)','a<>b',1);
#  $r2 = $ref->Update('\.t.*','\.tmp$','a<>b',1);
# subs to delete and create the two test directory structures.
sub _s1 {
  my($now);
  _s3 ($dira) if -d $dira;
  _s3 ($dirb) if -d $dirb;
  _s2 ($atarget);
  _s2 ($dirb);
  $now = time;
  foreach (@files) {
    my ($file) = $atarget . '/' . $_;
    open (A,">$file") || die "Unable to create file $file ($!) \n";
    printf A "#  Test File $_\n\n\n# End of Test File $_";
    utime $now, $now, $file;
    close A;
    print "\tcreated test file $file\n";
  }
}

# sub to test a directory tree exists, and if not to create it
sub _s2 {
  my($Dir) = @_;
  return if (-d $Dir); # Quit if the directory exists
  $Dir =~ /(.*)\/([^\/]*)/;
  my($parent,$dir) = ($1,$2);
  &_s2($parent) if (!-d $parent);  # Create the parent if it does not exist
  mkdir ($Dir, 0777) || die "Unable to create directory $Dir\n";
};

#  sub to delete a directory tree
sub _s3{
  my($root)=@_;
  my(@dirlist,$dir);
  find(\&_s3b,$root);
  find(\&_s3a,$root);
  while ( @dirlist ) {
    $dir = pop(@dirlist);
    rmdir($dir) || die "   -   unable to remove $dir ($!)\n";
  }
# sub to list all directories in a directory tree
  sub _s3a {
    if ( -d ) {
      push (@dirlist,$File::Find::name);
    }
  }
# sub to delete all files in a directory tree
  sub _s3b {
    if ( -f ) {
      unlink($File::Find::name) || die "   -   unable to remove $File::Find::name ($!)\n";
    }
  }
}

# sub to compare two files - return 0 for success
sub _s4 {
  my ($file1,$file2) = @_;
  my ($debug) = 0;
  print "testing $file1 and $file2\n" if $debug;
  unless ( -e $file1 ) {
    print "   $file1 does not exist ($!)\n" if $debug;
    return 1;
  }
  unless ( -e $file2 ) {
    print "   $file1 does not exist ($!)\n" if $debug;
    return 2;
  }
  if(-f $file1 ne -f $file2){
    if ($debug){
    print "   objects $file1 and $file2 are different types\n";
    printf "\t%s %s\n",&type($file1),$file1;
    printf "\t%s %s\n",&type($file2),$file2;
  }
    return 6;   
  }elsif (compare($file1,$file2) != 0) {
    print "   files $file1 and $file2 are different\n" if $debug;
    return 3;
  }
  my($dev1,$ino1,$mode1,$nlink1,$uid1,$gid1,$rdev1,$size1,
  $atime1,$mtime1,$ctime1,$blksize1,$blocks1)
  = stat($file1);
  my($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
  $atime2,$mtime2,$ctime2,$blksize2,$blocks2)
  = stat($file2);
  if ( $mtime1 != $mtime2) {
    if ( $debug ) {
      print "   files have different mtime's\n";
      printf "      %20s  %10d\n",$file1,$mtime1;
      printf "      %20s  %10d\n",$file2,$mtime2;
    }
    if ( $mtime1 > $mtime2 ) {
      return 4;
      }else{
      return 5;
    }
  }
  return 0;
}
sub type {
  my $object = shift;
  if(-f $object){
    return "file";
  }elsif(-d $object){
    return "directory";
  }else{
    return "unknown";
  }
}
