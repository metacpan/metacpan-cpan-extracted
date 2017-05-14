#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

use lib '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..187\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 1.03;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
#
#Added tests should have an comment matching /# \d/
#If so, the following will renumber all the tests
#to match Perl's idea of test:
#perl -pe 'BEGIN{$i=1};if (/# \d/){ $i++};s/# \d+/# $i/' test1.t > test1.t1
#
######################### End of test renumber.

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
my $file2 = "badmarc.dat";
my $testdir = "t";
if (-d $testdir) {
    $file = "$testdir/$file";
    $file2 = "$testdir/$file2";
}
unless (-e $file) {
    die "No MARC sample file found\n";
}
unless (-e $file2) {
    die "Missing bad sample file for MARC tests: $file2\n";
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

   # Create the new MARC object. You can use any variable name you like...
   # Read the MARC file into the MARC object.

unless (is_ok ($x = MARC->new ($file))) {			# 2
    printf "could not create MARC from $file\n";
    exit 1;
    # next test would die at runtime without $x
}

is_ok (2 == $x->marc_count);					# 3

   #Output the MARC object to an ascii file
is_ok ($x->output({file=>">output.txt",'format'=>"ASCII"}));	# 4

   #Output the MARC object to an html file
is_ok ($x->output({file=>">output.html",'format'=>"HTML"}));	# 5

   #Try to output the MARC object to an xml file
my $quiet = $^W;
$^W = 0;
is_bad ($x->output({file=>">output.xml",'format'=>"XML"}));	# 6
$^W = $quiet;

   #Output the MARC object to an url file
is_ok ($x->output({file=>">output.urls",'format'=>"URLS"}));	# 7

   #Output the MARC object to an isbd file
is_ok ($x->output({file=>">output.isbd",'format'=>"ISBD"}));	# 8

   #Output the MARC object to a marcmaker file
is_ok ($x->output({file=>">output.mkr",'format'=>"marcmaker"}));	# 9

   #Output the MARC object to an html file with titles
is_ok ($x->output({file=>">output2.html", 
                   'format'=>"HTML","245"=>"TITLE:"}));		# 10

is_ok (-s 'output.txt');					# 11
is_ok (-s 'output.html');					# 12
is_bad (-e 'output.xml');					# 13
is_ok (-s 'output.urls');					# 14

   #Append the MARC object to an html file with titles
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
my $mldr = $x->ldr(1);
my $rhldr = $x->unpack_ldr(1);
is_ok('c' eq ${$rhldr}{RecStat});				# 24
is_ok('a' eq ${$rhldr}{Type});				        # 25
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

$x->pack_ldr(1);
is_ok($x->ldr(1) eq $mldr);                                     # 38
$x->pack_008(1);
my ($cmp008) = $x->getvalue({field=>'008',record=>1});
is_ok($cmp008 eq $m008);                                        # 39

my ($indi1) = $x->getvalue({field=>'245',record=>1,subfield=>'i1'});
my ($indi2) = $x->getvalue({field=>'245',record=>1,subfield=>'i2'});
my ($indi12) = $x->getvalue({field=>'245',record=>1,subfield=>'i12'});

is_ok($indi1 eq "1");						# 40
is_ok($indi2 eq "4");						# 41
is_ok($indi12 eq "14");						# 42

my ($m100a) = $x->getvalue({field=>'100',record=>1,subfield=>'a'});
my ($m100d) = $x->getvalue({field=>'100',record=>1,subfield=>'d'});
my ($m100e) = $x->getvalue({field=>'100',record=>1,subfield=>'e'});

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($m100a eq "Twain, Mark,");				# 43
is_ok($m100d eq "1835-1910.");					# 44
is_bad(defined $m100e);						# 45

my @ind12 = $x->getvalue({field=>'246',record=>2,subfield=>'i12'});
is_ok(3 == scalar @ind12);					# 46
is_ok($ind12[0] eq "30");					# 47
is_ok($ind12[1] eq "3 ");					# 48
is_ok($ind12[2] eq "30");					# 49

my @m246a = $x->getvalue({field=>'246',record=>2,subfield=>'a'});
is_ok(3 == scalar @m246a);					# 50
is_ok($m246a[0] eq "Photo archive");				# 51
is_ok($m246a[1] eq "Associated Press photo archive");		# 52
is_ok($m246a[2] eq "AP photo archive");				# 53

my @records=$x->searchmarc({field=>"245"});
is_ok(2 == scalar @records);					# 54
is_ok($records[0] == 1);					# 55
is_ok($records[1] == 2);					# 56

@records=$x->searchmarc({field=>"245",subfield=>"a"});
is_ok(2 == scalar @records);					# 57
is_ok($records[0] == 1);					# 58
is_ok($records[1] == 2);					# 59

@records=$x->searchmarc({field=>"245",subfield=>"b"});
is_ok(1 == scalar @records);					# 60
is_ok($records[0] == 1);					# 61

@records=$x->searchmarc({field=>"245",subfield=>"h"});
is_ok(1 == scalar @records);					# 62
is_ok($records[0] == 2);					# 63

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

@records=$x->searchmarc({field=>"246",subfield=>"a"});
is_ok(1 == scalar @records);					# 64
is_ok($records[0] == 2);					# 65

@records=$x->searchmarc({field=>"245",regex=>"/huckleberry/i"});
is_ok(1 == scalar @records);					# 66
is_ok($records[0] == 1);					# 67

@records=$x->searchmarc({field=>"260",subfield=>"c",regex=>"/19../"});
is_ok(1 == scalar @records);					# 68
is_ok($records[0] == 2);					# 69

@records=$x->searchmarc({field=>"245",notregex=>"/huckleberry/i"});
is_ok(1 == scalar @records);					# 70
is_ok($records[0] == 2);					# 71

@records=$x->searchmarc({field=>"260",subfield=>"c",notregex=>"/19../"});
is_ok(1 == scalar @records);					# 72
is_ok($records[0] == 1);					# 73

@records=$x->searchmarc({field=>"900",subfield=>"c"});
is_ok(0 == scalar @records);					# 74
is_bad(defined $records[0]);					# 75

@records=$x->searchmarc({field=>"999"});
is_ok(0 == scalar @records);					# 76
is_bad(defined $records[0]);					# 77

is_ok (-s 'output.isbd');					# 78
is_ok (-s 'output.mkr');					# 79

my $update246 = {field=>'246',record=>2,ordered=>'y'};
my @u246 = $x->getupdate($update246);
is_ok(21 ==  @u246);						# 80

is_ok(1 == $x->searchmarc($update246));				# 81
is_ok(3 == $x->deletemarc($update246));				# 82

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[0] eq "i1");					# 83
is_ok($u246[1] eq "3");						# 84
is_ok($u246[2] eq "i2");					# 85
is_ok($u246[3] eq "0");						# 86
is_ok($u246[4] eq "a");						# 87
is_ok($u246[5] eq "Photo archive");				# 88
is_ok($u246[6] eq "\036");					# 89

is_ok($u246[7] eq "i1");					# 90
is_ok($u246[8] eq "3");						# 91
is_ok($u246[9] eq "i2");					# 92
is_ok($u246[10] eq " ");					# 93
is_ok($u246[11] eq "a");					# 94
is_ok($u246[12] eq "Associated Press photo archive");		# 95
is_ok($u246[13] eq "\036");					# 96

is_ok($u246[14] eq "i1");					# 97
is_ok($u246[15] eq "3");					# 98
is_ok($u246[16] eq "i2");					# 99
is_ok($u246[17] eq "0");					# 100
is_ok($u246[18] eq "a");					# 101
is_ok($u246[19] eq "AP photo archive");				# 102
is_ok($u246[20] eq "\036");					# 103

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok ($y1 = $x->output({'format'=>"HTML_HEADER"}));		# 104
my $header = "Content-type: text/html\015\012\015\012";
is_ok ($y1 eq $header);						# 105

is_ok ($y1 = $x->output({'format'=>"HTML_START"}));		# 106
$header = "<html><body>";
is_ok ($y1 eq $header);						# 107

is_ok ($y1 = $x->output({'format'=>"HTML_START",'title'=>"Testme"}));	# 108
$header = "<html><head><title>Testme</title></head>\n<body>";
is_ok ($y1 eq $header);						# 109

is_ok ($y1 = $x->output({'format'=>"HTML_FOOTER"}));		# 110
$header = "\n</body></html>\n";
is_ok ($y1 eq $header);						# 111

is_ok(0 == $x->searchmarc($update246));				# 112
@records = $x->getupdate($update246);
is_ok(0 == @records);						# 113

    # prototype setupdate()
@records = ();
foreach $y1 (@u246) {
    unless ($y1 eq "\036") {
	push @records, $y1;
	next;
    }
    $x->addfield($update246, @records) || warn "not added\n";
    @records = ();
}

@u246 = $x->getupdate($update246);
is_ok(21 == @u246);						# 114

is_ok($u246[0] eq "i1");					# 115
is_ok($u246[1] eq "3");						# 116
is_ok($u246[2] eq "i2");					# 117
is_ok($u246[3] eq "0");						# 118
is_ok($u246[4] eq "a");						# 119
is_ok($u246[5] eq "Photo archive");				# 120
is_ok($u246[6] eq "\036");					# 121

is_ok($u246[7] eq "i1");					# 122
is_ok($u246[8] eq "3");						# 123

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[9] eq "i2");					# 124
is_ok($u246[10] eq " ");					# 125
is_ok($u246[11] eq "a");					# 126
is_ok($u246[12] eq "Associated Press photo archive");		# 127
is_ok($u246[13] eq "\036");					# 128

is_ok($u246[14] eq "i1");					# 129
is_ok($u246[15] eq "3");					# 130
is_ok($u246[16] eq "i2");					# 131
is_ok($u246[17] eq "0");					# 132
is_ok($u246[18] eq "a");					# 133

is_ok($u246[19] eq "AP photo archive");				# 134
is_ok($u246[20] eq "\036");					# 135

@records = $x->searchmarc({field=>'900'});
is_ok(0 == @records);						# 136
@records = $x->searchmarc({field=>'999'});
is_ok(0 == @records);						# 137

is_ok($x->addfield({record=>1, field=>"999", ordered=>"n", 
                    i1=>"5", i2=>"3", value=>[c=>"wL70",
		    d=>"AR Clinton PL",f=>"53525"]}));		# 138

is_ok($x->addfield({record=>1, field=>"900", ordered=>"y", 
                    i1=>"6", i2=>"7", value=>[z=>"part 1",
		    z=>"part 2",z=>"part 3"]}));		# 139

is_ok($x->addfield({record=>2, field=>"900", ordered=>"y", 
                    i1=>"9", i2=>"8", value=>[z=>"part 4"]}));	# 140

@records = $x->searchmarc({field=>'900'});
is_ok(2 == @records);						# 141
@records = $x->searchmarc({field=>'999'});
is_ok(1 == @records);						# 142

@records = $x->getupdate({field=>'900',record=>1});
is_ok(11 == @records);						# 143

is_ok($records[0] eq "i1");					# 144
is_ok($records[1] eq "6");					# 145

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[2] eq "i2");					# 146
is_ok($records[3] eq "7");					# 147
is_ok($records[4] eq "z");					# 148
is_ok($records[5] eq "part 1");					# 149
is_ok($records[6] eq "z");					# 150
is_ok($records[7] eq "part 2");					# 151
is_ok($records[8] eq "z");					# 152
is_ok($records[9] eq "part 3");					# 153
is_ok($records[10] eq "\036");					# 154

@records = $x->getupdate({field=>'900',record=>2});
is_ok(7 == @records);						# 155

is_ok($records[0] eq "i1");					# 156
is_ok($records[1] eq "9");					# 157
is_ok($records[2] eq "i2");					# 158
is_ok($records[3] eq "8");					# 159
is_ok($records[4] eq "z");					# 160

is_ok($records[5] eq "part 4");					# 161
is_ok($records[6] eq "\036");					# 162

@records = $x->getupdate({field=>'999',record=>1});
is_ok(11 == @records);						# 163

is_ok($records[0] eq "i1");					# 164
is_ok($records[1] eq "5");					# 165
is_ok($records[2] eq "i2");					# 166
is_ok($records[3] eq "3");					# 167

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[4] eq "c");					# 168
is_ok($records[5] eq "wL70");					# 169
is_ok($records[6] eq "d");					# 170
is_ok($records[7] eq "AR Clinton PL");				# 171
is_ok($records[8] eq "f");					# 172
is_ok($records[9] eq "53525");					# 173
is_ok($records[10] eq "\036");					# 174

@records = $x->getupdate({field=>'999',record=>2});
is_ok(0 == @records);						# 175

@records = $x->getupdate({field=>'001',record=>2});
is_ok(2 == @records);						# 176
is_ok($records[0] eq "ocm40139019 ");				# 177
is_ok($records[1] eq "\036");					# 178

is_ok(2 == $x->deletemarc());					# 179
is_zero($x->marc_count);					# 180

$MARC::TEST = 1;
is_ok('0 but true' eq $x->openmarc({file=>$file2,
				    'format'=>"usmarc"}));	# 181
is_ok(-1 == $x->nextmarc(2));					# 182
is_ok(1 == $x->marc_count);					# 183
is_bad(defined $x->nextmarc(1));				# 184
is_ok(1 == $x->nextmarc(2));					# 185
is_ok(2 == $x->marc_count);					# 186
is_ok($x->closemarc);						# 187
