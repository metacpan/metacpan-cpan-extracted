# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::MkTempO;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $object = File::MkTempO->new('MkTempO_XXXXXX','./t/');

if ($object){
  print "ok 2\n";
}else{
  print "not ok 2\n";
}

my $tempfile = $object->mktemp;

if ($tempfile){
  print "ok 3\n";
}else{
  print "not ok 3\n";
}

my $sfh = $object->mkstemp;
if ($sfh){
  print "ok 4\n";
}else{
  print "not ok 4\n";
}

if (print $sfh $object->fhtmpl . "\n"){
  print "ok 5\n";
}else{
  print "not ok 5\n";
}

if (print $sfh $object->fhdirtmpl . "\n"){
  print "ok 6\n";
}else{
  print "not ok 6\n";
}

if (print $sfh $object->template . "\n"){
  print "ok 7\n";
}else{
  print "not ok 7\n";
}

if (print $sfh $object->dir . "\n"){
  print "ok 8\n";
}else{
  print "not ok 8\n";
}

if ($sfh->close){
  print "ok 9\n";
}else{
  print "not ok 9\n";
}

open(FH,$object->fhdirtmpl);

my @stemphandle = <FH>;

if (@stemphandle){
  print "ok 10\n";
}else{
  print "not ok 10\n";
}

chop($stemphandle[0]);

if ($object->fhtmpl eq $stemphandle[0]){
  print "ok 11\n";
}else{
  print "not ok 11\n";
}

chop($stemphandle[1]);

if ($object->fhdirtmpl eq $stemphandle[1]){
  print "ok 12\n";
}else{
  print "not ok 12\n";
}

chop($stemphandle[2]);

if ($object->template eq $stemphandle[2]){
  print "ok 13\n";
}else{
  print "not ok 13\n";
}
chop($stemphandle[3]);

if ($object->dir eq $stemphandle[3]){
  print "ok 14\n";
}else{
  print "not ok 14\n";
}
