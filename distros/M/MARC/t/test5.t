#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

use lib  '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..109\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 1.07;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
#
#Added tests should have an comment matching /# \d/
#If so, the following will renumber all the tests
#to match Perl's idea of test:
#perl -pi.bak -e 'BEGIN{$i=1};next if /^#/;if (/# \d/){ $i++};s/# \d+/# $i/' test5.t
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

sub array_eq_str {
    my ($ra1,$ra2)=@_;
    my @a1= @$ra1;
    my @a2= @$ra2;
    return 0 unless (scalar(@a1) == scalar(@a2));
    for my $i (0..scalar(@a1)-1) {
	return 0 unless ($a1[$i] eq $a2[$i]);
    }
    return 1;
}
sub printarr {
    my @b=@_;
    print "(",(join ", ",grep {s/^/'/;s/$/'/} @b),")";
}

my $file = "marc4.dat";
my $testfile = "t/marc4.dat";
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
unlink 'output4.txt','output4.mkr';

   # Create the new MARC object. You can use any variable name you like...
   # Read the MARC file into the MARC object.

unless (is_ok ($x = MARC->new ($file))) {			# 2
    printf "could not create MARC from $file\n";
    exit 1;
    # next test would die at runtime without $x
}

   #Output the MARC object to an ascii file
is_ok ($x->output({file=>">output4.txt",'format'=>"ASCII"}));	# 3

   #Output the MARC object to a marcmaker file
is_ok ($x->output({file=>">output4.mkr",'format'=>"marcmaker"}));	# 4

is_ok (-s 'output4.txt');					# 5
is_ok (-s 'output4.mkr');					# 6
my @a1 = ('1',2,'b');
my @a2 = (1,2,'b');
my @b1 = ('1',2);
my @b2 = ('1',2,'c');
is_ok ( array_eq_str(\@a1,\@a2) );                            # 7
is_bad( array_eq_str(\@a1,\@b1) );                            # 8
is_bad( array_eq_str(\@a1,\@b2) );                            # 9

# I have found updatefirst/deletefirst functionality very tricky to
# implement.  And this is the second time I have implemented it. There
# are several semantics that can go either way.  These tests are
# intended to cover all semantic choices and data dependencies,
# providing reasonable evidence that any straightforward
# implementation is correct.

# Note to implementors. You should maintain a couple of obvious
# invariants by construction. Don't change any but the current record
# and don't change any but the current field (and subfield if it
# exists). Not hard to do, but someone has to say it....  If you need
# to violate the subfield constraint (possible if you put extra
# information in the field to reflect workflow) do it in updatehook().

## 9. Tests are for "all significant variations", which we 
# split by function: deletion or update
# Given deletion the variations are:
# da. tag < or > 10,                  (tags 1 090)
# db. 0,1, or more  matches                 (tags 2 11 3 49 500)
# dc. subfield spec or not                  (tags 5 245)  
# dd. indicator or not in the subfield spec (tag > 10)
# de. last subfield or not                  (tags 3 049)
# df. match in the first field or not.      (tags 500 subfield c and a)

# Given update the variations are:
# ua. to be tag < or > 10,                  (tags 1 3 5 8)
# ub. 0,1, or more  matches                 (tags 2 11 3 49 500)
# uc. subfield spec or not                  (tags 4   
# ud. indicator or not in the subfield spec
# uf. match in the first field or not.      (tags 500 subfield c and a)

# This gives an upper bound of 2*3*2*2*2*2 + 2*3*2*2*2 = 96+48 = 148
# tests. (There is some collapse possible, so we may get away with
# (much) less.) (Currently we have 16 deletes and 14 updates. Better...)


## 9. What needs to be tested.
# We must check that only the affected fields and subfields are 
# touched. Therefore we need to check, e.g. the 008 field when
# we are munging the 245's. From the structure of current code
# this is provably correct, but subclasses my override this...

my ($m008) = $x->getvalue({field=>'008',record=>1,delimeter=>"\c_"});

# Deletion.
#da1.db3 not currently tested. Check with a repeat 006 sometime.
#da1.db1.dc1
#da1.db1.dc2
#da1.db2.dc1
#da1.db2.dc2

#da2.db1.dc1.dd1
#da2.db1.dc1.dd2
#da2.db1.dc2

#da2.db2.dc1.dd1
#da2.db2.dc1.dd2.de1
#da2.db2.dc1.dd2.de2
#da2.db2.dc2
#da2.db3.dc1.dd1
#da2.db3.dc1.dd2
#da2.db3.dc1.dd2.de1
#da2.db3.dc1.dd2.de2.df1
#da2.db3.dc1.dd2.de2.df2

# Update.
#ua1.ub3 not currently tested. Check with a repeat 006 sometime.
#ua1.ub1.uc1
#ua1.ub1.uc2
#ua1.ub2.uc1
#ua1.ub2.uc2

#ua2.ub1.uc1.ud1
#ua2.ub1.uc1.ud2
#ua2.ub1.uc2

#ua2.ub2.uc1.ud1
#ua2.ub2.uc1.ud2
#ua2.ub2.uc2
#ua2.ub3.uc1.ud1
#ua2.ub3.uc1.ud2.uf1
#ua2.ub3.uc1.ud2.uf2

my %o=();
for (qw(001 002 005 049 090 245 247 500)) {
    my @tmp = $x->getupdate({record=>1,field=>$_});
    $o{$_}=\@tmp;
}

my $templc1d1 = {record=>1,field=>245,subfield=>'i1'};
my $templc1d2 = {record=>1,field=>245,subfield=>'a'};
my $templc2    = {record=>1,field=>245};
my $subfieldf1  = 'a';
my $subfieldf2  = 'c';
my $fieldf  = 500;

#F u a1.b1.c2    002 a
my $ftempl = {record=>1,field=>'002'};
my $templ  = {record=>1,field=>'002'};
$templ->{subfield}= 'a';
undef $@;
eval{$x->updatefirst($templ,('002',"x","y", a =>"zz"));};
is_ok( $@ =~/Cannot update subfields of control fields/);  # 10
my @new =$x->getupdate($ftempl);
my $ranew = \@new;

my ($indi1) = $x->getvalue({field=>'245',record=>1,subfield=>'i1'});
my ($indi2) = $x->getvalue({field=>'245',record=>1,subfield=>'i2'});

is_ok($indi1 eq "1");						# 11
is_ok($indi2 eq "4");						# 12

my @m245 = $x->getvalue({field=>'245',record=>1,subfield=>'a',delimiter=>"\c_"});
my @m247 = $x->getvalue({field=>'245',record=>1,subfield=>'a',delimiter=>"\c_"});
my @m500 = $x->getvalue({field=>'245',record=>1,subfield=>'a',delimiter=>"\c_"});

$x->updatefirst({field=>'245',record=>1,subfield => 'a'}, ('245','a','b', a=>'foo'));    

($indi1) = $x->getvalue({field=>'245',record=>1,subfield=>'i1'});
($indi2) = $x->getvalue({field=>'245',record=>1,subfield=>'i2'});

is_ok($indi1 eq "1");						# 13
is_ok($indi2 eq "4");						# 14
my ($m245_a) = $x->getvalue({field=>'245',record=>1,subfield=>'a'});

$x->deletefirst({field=>'500',record=>1});    
$x->updatefirst({field=>'247',record=>1},
		 (i1=>1,i2=>" ", a =>"Photo marchive"));        

$x->updatefirst({field=>'500',record=>1},
		 (i1=>1,i2=>" ", a =>"First English Fed."));    

is_ok($m008 eq "741021s1884    enkaf         000 1 eng d");	# 15



my ($m100a) = $x->getvalue({field=>'100',record=>1,subfield=>'a'});
my ($m100d) = $x->getvalue({field=>'100',record=>1,subfield=>'d'});
my ($m100e) = $x->getvalue({field=>'100',record=>1,subfield=>'e'});

is_ok($m100a eq "Twain, Mark,");				# 16
is_ok($m100d eq "1835-1910.");					# 17
is_bad(defined $m100e);						# 18

my @m246a = $x->getvalue({field=>'246',record=>2,subfield=>'a'});
is_ok(3 == scalar @m246a);					# 19
is_ok($m246a[0] eq "Photo archive");				# 20
is_ok($m246a[1] eq "Associated Press photo archive");		# 21
is_ok($m246a[2] eq "AP photo archive");				# 22

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

my $update246 = {field=>'246',record=>2,ordered=>'y'};
my @u246 = $x->getupdate($update246);
is_ok(21 ==  @u246);						# 23


is_ok($u246[0] eq "i1");					# 24
is_ok($u246[1] eq "3");						# 25
is_ok($u246[2] eq "i2");					# 26
is_ok($u246[3] eq "0");						# 27
is_ok($u246[4] eq "a");						# 28
is_ok($u246[5] eq "Photo archive");				# 29
is_ok($u246[6] eq "\036");					# 30


is_ok($u246[7] eq "i1");					# 31
is_ok($u246[8] eq "3");						# 32
is_ok($u246[9] eq "i2");					# 33
is_ok($u246[10] eq " ");					# 34
is_ok($u246[11] eq "a");					# 35
is_ok($u246[12] eq "Associated Press photo archive");		# 36
is_ok($u246[13] eq "\036");					# 37

is_ok($u246[14] eq "i1");					# 38
is_ok($u246[15] eq "3");					# 39
is_ok($u246[16] eq "i2");					# 40
is_ok($u246[17] eq "0");					# 41
is_ok($u246[18] eq "a");					# 42
is_ok($u246[19] eq "AP photo archive");				# 43
is_ok($u246[20] eq "\036");					# 44

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok(3 == $x->deletemarc($update246));				# 45
my @records = ();
foreach my $y1 (@u246) {
    unless ($y1 eq "\036") {
	push @records, $y1;
	next;
    }
    $x->addfield($update246, @records) || warn "not added\n";
    @records = ();
}

@u246 = $x->getupdate($update246);
is_ok(21 == @u246);						# 46

is_ok($u246[0] eq "i1");					# 47
is_ok($u246[1] eq "3");						# 48
is_ok($u246[2] eq "i2");					# 49
is_ok($u246[3] eq "0");						# 50
is_ok($u246[4] eq "a");						# 51
is_ok($u246[5] eq "Photo archive");				# 52
is_ok($u246[6] eq "\036");					# 53

is_ok($u246[7] eq "i1");					# 54
is_ok($u246[8] eq "3");						# 55
is_ok($u246[9] eq "i2");					# 56
is_ok($u246[10] eq " ");					# 57
is_ok($u246[11] eq "a");					# 58
is_ok($u246[12] eq "Associated Press photo archive");		# 59
is_ok($u246[13] eq "\036");					# 60

is_ok($u246[14] eq "i1");					# 61
is_ok($u246[15] eq "3");					# 62
is_ok($u246[16] eq "i2");					# 63
is_ok($u246[17] eq "0");					# 64
is_ok($u246[18] eq "a");					# 65

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[19] eq "AP photo archive");				# 66
is_ok($u246[20] eq "\036");					# 67


is_ok($x->addfield({record=>1, field=>"999", ordered=>"n", 
                    i1=>"5", i2=>"3", value=>[c=>"wL70",
		    d=>"AR Clinton PL",f=>"53525"]}));		# 68

is_ok($x->addfield({record=>1, field=>"900", ordered=>"y", 
                    i1=>"6", i2=>"7", value=>[z=>"part 1",
		    z=>"part 2",z=>"part 3"]}));		# 69

is_ok($x->addfield({record=>2, field=>"900", ordered=>"y", 
                    i1=>"9", i2=>"8", value=>[z=>"part 4"]}));	# 70

@records = $x->searchmarc({field=>'900'});
is_ok(2 == @records);						# 71
@records = $x->searchmarc({field=>'999'});
is_ok(1 == @records);						# 72

@records = $x->getupdate({field=>'900',record=>1});
is_ok(11 == @records);						# 73

is_ok($records[0] eq "i1");					# 74
is_ok($records[1] eq "6");					# 75
is_ok($records[2] eq "i2");					# 76
is_ok($records[3] eq "7");					# 77
is_ok($records[4] eq "z");					# 78
is_ok($records[5] eq "part 1");					# 79
is_ok($records[6] eq "z");					# 80
is_ok($records[7] eq "part 2");					# 81
is_ok($records[8] eq "z");					# 82
is_ok($records[9] eq "part 3");					# 83
is_ok($records[10] eq "\036");					# 84

@records = $x->getupdate({field=>'900',record=>2});
is_ok(7 == @records);						# 85

is_ok($records[0] eq "i1");					# 86
is_ok($records[1] eq "9");					# 87

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[2] eq "i2");					# 88
is_ok($records[3] eq "8");					# 89
is_ok($records[4] eq "z");					# 90

is_ok($records[5] eq "part 4");					# 91
is_ok($records[6] eq "\036");					# 92

@records = $x->getupdate({field=>'999',record=>1});
is_ok(11 == @records);						# 93

is_ok($records[0] eq "i1");					# 94
is_ok($records[1] eq "5");					# 95
is_ok($records[2] eq "i2");					# 96
is_ok($records[3] eq "3");					# 97
is_ok($records[4] eq "c");					# 98
is_ok($records[5] eq "wL70");					# 99
is_ok($records[6] eq "d");					# 100
is_ok($records[7] eq "AR Clinton PL");				# 101
is_ok($records[8] eq "f");					# 102
is_ok($records[9] eq "53525");					# 103
is_ok($records[10] eq "\036");					# 104

is_ok($MARC::VERSION == $MARC::Rec::VERSION);			# 105

@records = $x->getupdate({field=>'999',record=>2});
is_ok(0 == @records);						# 106

@records = $x->getupdate({field=>'001',record=>2});
is_ok(2 == @records);						# 107
is_ok($records[0] eq "ocm40139019 ");				# 108
is_ok($records[1] eq "\036");					# 109
my $string_rec = $x->[1]->as_string();
my $tmp_rec=$x->[0]{proto_rec}->copy_struct();
$tmp_rec->from_string($string_rec);
1;# for debug

