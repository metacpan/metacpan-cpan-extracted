#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

use lib '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..79\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARCopt;		# check inheritance & export
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;

my $tc = 2;		# next test number

sub is_ok {
    my $result = shift;
    printf (($result ? "" : "not ")."ok %d\n",$tc++);
    return $result;
}

sub is_zero {
    my $result = shift;
    if (defined $result) {
        return is_ok ($result == 0);
    }
    else {
        printf ("not ok %d\n",$tc++);
    }
}

sub is_bad {
    my $result = shift;
    printf (($result ? "not " : "")."ok %d\n",$tc++);
    return (not $result);
}

sub filestring {
    my $file = shift;
    local $/ = undef;
    unless (open(YY, $file)) {warn "Can't open file $file: $!\n"; return;}
    binmode YY;
    my $yy = <YY>;
    unless (close YY) {warn "Can't close file $file: $!\n"; return;}
    return $yy;
}

my $file = "marc.dat";
my $testfile = "t/marc.dat";
if (-e $testfile) {
    $file = $testfile;
}
unless (-e $file) {
    die "No MARC sample file found\n";
}

my $naptime = 0;	# pause between output pages
if (@ARGV) {
    $naptime = shift @ARGV;
    unless ($naptime =~ /^[0-5]$/) {
	die "Usage: perl test?.t [ page_delay (0..5) ]";
    }
}

my $x;
unlink 'output.txt', 'output.html', 'output.xml', 'output.isbd',
       'output.urls', 'output2.html', 'output.mkr';

   # Create the new MARCopt object. You can use any variable name you like...
   # Read the MARC file into the MARCopt object.

unless (is_ok ($x = MARCopt->new ($file))) {			# 2
    printf "could not create MARCopt from $file\n";
    exit 1;
    # next test would die at runtime without $x
}

is_ok (2 == $x->marc_count);					# 3

   #Output the MARCopt object to an ascii file
is_ok ($x->output({file=>">output.txt",'format'=>"ASCII"}));	# 4

   #Output the MARCopt object to an html file
is_ok ($x->output({file=>">output.html",'format'=>"HTML"}));	# 5

   #Try to output the MARCopt object to an xml file
my $quiet = $^W;
$^W = 0;
is_bad ($x->output({file=>">output.xml",'format'=>"XML"}));	# 6
$^W = $quiet;

   #Output the MARCopt object to an url file
is_ok ($x->output({file=>">output.urls",'format'=>"URLS"}));	# 7

   #Output the MARCopt object to an isbd file
is_ok ($x->output({file=>">output.isbd",'format'=>"ISBD"}));	# 8

   #Output the MARCopt object to a marcmaker file
is_ok ($x->output({file=>">output.mkr",'format'=>"marcmaker"}));	# 9

   #Output the MARCopt object to an html file with titles
is_ok ($x->output({file=>">output2.html", 
                   'format'=>"HTML","245"=>"TITLE:"}));		# 10

is_ok (-s 'output.txt');					# 11
is_ok (-s 'output.html');					# 12
is_bad (-e 'output.xml');					# 13
is_ok (-s 'output.urls');					# 14

   #Append the MARCopt object to an html file with titles
is_ok ($x->output({file=>">>output2.html",
                   'format'=>"HTML","245"=>"TITLE:"}));		# 15

   #Append to an html file with titles incrementally
is_ok ($x->output({file=>">output.html",'format'=>"HTML_START"}));	# 16
is_ok ($x->output({file=>">>output.html",
                   'format'=>"HTML_BODY","245"=>"TITLE:"}));		# 17
is_ok ($x->output({file=>">>output.html",'format'=>"HTML_FOOTER"}));	# 18

my ($y1, $y2, $yy);
is_ok ($y1 = $x->output({'format'=>"HTML","245"=>"TITLE:"}));	# 19
$y2 = "$y1$y1";
is_ok ($yy = filestring ("output2.html"));			# 20
is_ok ($yy eq $y2);						# 21

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok ($yy = filestring ("output.html"));			# 22
is_ok ($y1 eq $yy);						# 23

#Simple test of (un)?pack.*
my $rhldr = $x->unpack_ldr(1);
is_ok('c' eq ${$rhldr}{RecStat});				# 24
is_ok('a' eq ${$rhldr}{Type});					# 25
is_ok('m' eq ${$rhldr}{BLvl});				        # 26

my $rhff  = $x->unpack_008(1);
is_ok('741021' eq ${$rhff}{Entered});				# 27
is_ok('s' eq ${$rhff}{DtSt});					# 28
is_ok('1884' eq ${$rhff}{Date1});				# 29

my ($m000) = $x->getvalue({field=>'000',record=>1});
my ($m001) = $x->getvalue({field=>'001',record=>1});
my ($m003) = $x->getvalue({field=>'003',record=>1});
my ($m005) = $x->getvalue({field=>'005',record=>1});
my ($m008) = $x->getvalue({field=>'008',record=>1});

is_ok($m000 eq "00901cam  2200241Ia 45e0");			# 30
is_ok($m001 eq "ocm01047729 ");					# 31
is_ok($m003 eq "OCoLC");					# 32
is_ok($m005 eq "19990808143752.0");				# 33
is_ok($m008 eq "741021s1884    enkaf         000 1 eng d");	# 34

is_ok($x->_pack_ldr($rhldr) eq $m000);				# 35
is_ok($x->_pack_ldr($rhldr) eq $x->ldr(1));			# 36
is_ok($x->_pack_008($m000,$rhff) eq $m008);			# 37

my ($indi1) = $x->getvalue({field=>'245',record=>1,subfield=>'i1'});
my ($indi2) = $x->getvalue({field=>'245',record=>1,subfield=>'i2'});
my ($indi12) = $x->getvalue({field=>'245',record=>1,subfield=>'i12'});

is_ok($indi1 eq "1");						# 38
is_ok($indi2 eq "4");						# 39
is_ok($indi12 eq "14");						# 40

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

my ($m100a) = $x->getvalue({field=>'100',record=>1,subfield=>'a'});
my ($m100d) = $x->getvalue({field=>'100',record=>1,subfield=>'d'});
my ($m100e) = $x->getvalue({field=>'100',record=>1,subfield=>'e'});

is_ok($m100a eq "Twain, Mark,");				# 41
is_ok($m100d eq "1835-1910.");					# 42
is_bad(defined $m100e);						# 43

my @ind12 = $x->getvalue({field=>'246',record=>2,subfield=>'i12'});
is_ok(3 == scalar @ind12);					# 44
is_ok($ind12[0] eq "30");					# 45
is_ok($ind12[1] eq "3 ");					# 46
is_ok($ind12[2] eq "30");					# 47

my @m246a = $x->getvalue({field=>'246',record=>2,subfield=>'a'});
is_ok(3 == scalar @m246a);					# 48
is_ok($m246a[0] eq "Photo archive");				# 49
is_ok($m246a[1] eq "Associated Press photo archive");		# 50
is_ok($m246a[2] eq "AP photo archive");				# 51

my @records=$x->searchmarc({field=>"245"});
is_ok(2 == scalar @records);					# 52
is_ok($records[0] == 1);					# 53
is_ok($records[1] == 2);					# 54

@records=$x->searchmarc({field=>"245",subfield=>"a"});
is_ok(2 == scalar @records);					# 55
is_ok($records[0] == 1);					# 56
is_ok($records[1] == 2);					# 57

@records=$x->searchmarc({field=>"245",subfield=>"b"});
is_ok(1 == scalar @records);					# 58
is_ok($records[0] == 1);					# 59

@records=$x->searchmarc({field=>"245",subfield=>"h"});
is_ok(1 == scalar @records);					# 60
is_ok($records[0] == 2);					# 61

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

@records=$x->searchmarc({field=>"246",subfield=>"a"});
is_ok(1 == scalar @records);					# 62
is_ok($records[0] == 2);					# 63

@records=$x->searchmarc({field=>"245",regex=>"/huckleberry/i"});
is_ok(1 == scalar @records);					# 64
is_ok($records[0] == 1);					# 65

@records=$x->searchmarc({field=>"260",subfield=>"c",regex=>"/19../"});
is_ok(1 == scalar @records);					# 66
is_ok($records[0] == 2);					# 67

@records=$x->searchmarc({field=>"245",notregex=>"/huckleberry/i"});
is_ok(1 == scalar @records);					# 68
is_ok($records[0] == 2);					# 69

@records=$x->searchmarc({field=>"260",subfield=>"c",notregex=>"/19../"});
is_ok(1 == scalar @records);					# 70
is_ok($records[0] == 1);					# 71

@records=$x->searchmarc({field=>"900",subfield=>"c"});
is_ok(0 == scalar @records);					# 72
is_bad(defined $records[0]);					# 73

@records=$x->searchmarc({field=>"999"});
is_ok(0 == scalar @records);					# 74
is_bad(defined $records[0]);					# 75

is_ok (-s 'output.isbd');					# 76
is_ok (-s 'output.mkr');					# 77

is_ok ($y1 = $x->output({'format'=>"HTML_HEADER"}));		# 78
is_ok ($y1 eq "Content-type: text/html\015\012\015\012");	# 79
