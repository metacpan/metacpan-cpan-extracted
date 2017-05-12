# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::MkTemp;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#Setup variables that are going to be used in the testing process:

my ($string,$fh,$sfh,$tempfile,@temphandle);

#Test mktemp - Does it return anything? Does it change the template?

$string = File::MkTemp::mktemp('MkTemp_XXXXXX','./t/');
if ($string){
  print "ok 2\n";
}else{
  print "not ok 2\n";
}

if ($string eq 'MkTemp_XXXXXX'){
  print "not ok 3\n";
}else{
  print "ok 3\n";
}

#Test mktemp with an extention

undef $string;

$string = File::MkTemp::mktemp('MkTemp_XXXXXX','./t/','.html');
if ($string){
  print "ok 4\n";
}else{
  print "not ok 4\n";
}

if ($string eq 'MkTemp_XXXXXX.html'){
  print "not ok 5\n";
}else{
  print "ok 5\n";
}

#Test mkstemp - Does it return a file handle? Can you print to the file
#               handle?  Can you close the file handle?

$fh = File::MkTemp::mkstemp('MkTemp_mkstemp_XXXXXX','./t/');
if ($fh){
  print "ok 6\n";
}else{
  print "not ok 6\n";
}

if (print $fh "Printing to fh\n"){
  print "ok 7\n";
}else{
  print "not ok 7\n"
}

if ($fh->close){
  print "ok 8\n";
}else{
  print "not ok 8\n";
}

#Test mkstemp with an extention

undef $fh;

$fh = File::MkTemp::mkstemp('MkTemp_mkstemp_XXXXXX','./t/','.html');
if ($fh){
  print "ok 9\n";
}else{
  print "not ok 9\n";
}

if (print $fh "Printing to fh.html\n"){
  print "ok 10\n";
}else{
  print "not ok 10\n"
}

if ($fh->close){
  print "ok 11\n";
}else{
  print "not ok 11\n";
}

#Test mkstempt - Does it return a file handle and the name of the file? Can
#                you print the name of the file into the file (ie put data
#                in the file)? Can you close the file handle?  Can you open
#                the file handle?  Can you read the data in the file handle
#                into an array?  Is the data in the file handle the name of
#                the file?

($sfh,$tempfile) = File::MkTemp::mkstempt('MkTemp_mkstempt_XXXXXX','./t/');
if ($sfh){
  print "ok 12\n";
}else{
  print "not ok 12\n";
}

if (print $sfh $tempfile){
  print "ok 13\n";
}else{
  print "not ok 13\n"
}

if ($sfh->close){
  print "ok 14\n";
}else{
  print "not ok 14\n";
}

open(FH,"./t/$tempfile");

@temphandle = <FH>;

if (@temphandle){
  print "ok 15\n";
}else{
  print "not ok 15\n";
}

if ($temphandle[0] eq $tempfile){
  print "ok 16\n";
}else{
  print "not ok 16\n";
}

#Test mkstempt with an extention

undef $sfh;
undef $tempfile;
undef @temphandle;

($sfh,$tempfile) = File::MkTemp::mkstempt('MkTemp_mkstempt_XXXXXX','./t/','.html');
if ($sfh){
  print "ok 17\n";
}else{
  print "not ok 17\n";
}

if (print $sfh $tempfile){
  print "ok 18\n";
}else{
  print "not ok 18\n"
}

if ($sfh->close){
  print "ok 19\n";
}else{
  print "not ok 19\n";
}

open(FH,"./t/$tempfile");

@temphandle = <FH>;

if (@temphandle){
  print "ok 20\n";
}else{
  print "not ok 20\n";
}

if ($temphandle[0] eq $tempfile){
  print "ok 21\n";
}else{
  print "not ok 21\n";
}
