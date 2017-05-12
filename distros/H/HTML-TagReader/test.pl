# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..24\n"; }
END {print "nok ok 1\n" unless $loaded;}
use HTML::TagReader;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "nok ok 13") depending on the success of chunk 13
# of the test code):
my $tf=".pltest.$$";
open(OUT,"> $tf")||die "ERROR: can not write $tf\n";
print OUT "bla < <tag \t\n1>\n";
print OUT " <a href=\"http://linuxfocus.org\">\n";
print OUT "<!-- <br> ------>\n";
close OUT;

my $ptr=new HTML::TagReader "$tf";
my $i=2;
my $tmp=$ptr->gettag(0);
if ($tmp eq "<tag 1>"){
	print "ok $i\n";
}else{
	print "nok $i \[$tmp\]\n";
}
$i++;


my @tag;
@tag = $ptr->gettag(1);
if ($tag[1] == 3){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

# " <a hre starts at pas 2
if ($tag[2] == 2){
	print "ok $i\n";
}else{
	print "nok $i\n";
}
$i++;

if ($tag[0] eq "<a href=\"http://linuxfocus.org\">"){
	print "ok $i\n";
}else{
	print "nok $i\n";
}
$i++;



@tag = $ptr->gettag(1);
#print "dbg:$tag[0]:dbg\n";
if (scalar @tag == 0){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;


$tmp=$ptr->gettag(1);
#print "dbg:$tmp:dbg\n";
if ($tmp eq ""){
	print "ok $i\n";
}else{
	print "nok $i\n";
}
$i++;


unlink("$tf");

$tf=".pltest_getbytoken.$$";
open(OUT,"> $tf")||die "ERROR: can not write $tf\n";
print OUT "<bla a=x> < <tag \t\n1>\n";
print OUT "<!DOCTYPE xx><TITLE>The web</TITLE>\n";
print OUT "<a href=\"http://linuxfocus.org\">\n";
print OUT "<!--- <br> ------>\n \n<ende><H2>\n";
close OUT;

my $p=new HTML::TagReader "$tf";
#7
@tag = $p->getbytoken("x");
if ($tag[0] eq "<bla a=x>" && $tag[1] eq "bla" && $tag[2] == 1){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

$tmp = $p->getbytoken(0);
if ($tmp eq " < "){
	print "ok $i\n";
}else{
	print "nok $i\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "<tag \t\n1>" && $tag[1] eq "tag" && $tag[2] == 1){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
@tag = $p->getbytoken(1);
if ($tag[0] eq "<!DOCTYPE xx>" && $tag[1] eq "!doctype" && $tag[2] == 3){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
@tag = $p->getbytoken(1);
if ($tag[0] eq "The web" && $tag[1] eq "" && $tag[2] == 3){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

# "The web" starts at charpos 21
if ($tag[3] == 21){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "</TITLE>" && $tag[1] eq "/title" && $tag[2] == 3){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "\n" && $tag[1] eq "" && $tag[2] == 3){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "<a href=\"http://linuxfocus.org\">" && $tag[1] eq "a" && $tag[2] == 4){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "\n" && $tag[1] eq "" && $tag[2] == 4){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "<!--- <br> ------>" && $tag[1] eq "!--" && $tag[2] == 5){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "\n \n" && $tag[1] eq "" && $tag[2] == 5){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "<ende>" && $tag[1] eq "ende" && $tag[2] == 7){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "<H2>" && $tag[1] eq "h2" && $tag[2] == 7){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

@tag = $p->getbytoken(1);
if ($tag[0] eq "\n" && $tag[1] eq "" && $tag[2] == 7){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;

unless (@tag = $p->getbytoken(1)){
	print "ok $i\n";
}else{
	print "nok $i (@tag)\n";
}
$i++;


unlink("$tf");

$tf=".pltest_getbytoken2.$$";
open(OUT,"> $tf")||die "ERROR: can not write $tf\n";
my $entirefile="<bla a=x> < <tag \t\n1>\n<!DOCTYPE xx><TITLE>The web</TITLE>\n";
print OUT $entirefile;
close OUT;

$p=new HTML::TagReader "$tf";

my $readfile="";
while(@tag = $p->getbytoken(0)){
	$readfile.=$tag[0];
}
if ($readfile eq $entirefile){
	print "ok $i\n";
}else{
	print "nok $i (orig:\"$entirefile\" and re-read:\"$readfile\" differ)\n";
}
$i++;

unlink("$tf");
