#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

use lib '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..116\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 1.03;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
#
#Added tests should have an comment matching /# \d/
#If so, the following will renumber all the tests
#to match Perl's idea of test:
#perl -pi.bak -e 'BEGIN{$i=1};if (/# \d/){ $i++};s/# \d+/# $i/' test4.t
#
######################### End of test renumber.

use strict;

my $tc = 2;		# next test number
my $WCB = 0;

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
	print "WCB: a1 = $a1[$i]...\n" if $WCB;
	print "WCB: a2 = $a2[$i]...\n" if $WCB;
	return 0 unless ($a1[$i] eq $a2[$i]);
    }
    return 1;
}
sub printarr {
    my @b=@_;
    print "(",(join ", ",grep {s/^/'/;s/$/'/} @b),")";
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
unlink 'output4.txt','output4.mkr','output4a.txt';

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


delete $x->[1]{500};

for (@{$x->[1]{array}}) {
    $x->add_map(1,$_) if $_->[0] eq '500';
}

is_ok(${$x->[1]{500}{'a'}[0]} eq 'First English ed.'); # 10
${$x->[1]{500}{'a'}[0]} ="boo";
is_ok(${$x->[1]{500}{'a'}[0]} eq 'boo'); # 11
my @new500=(500,'x','y',a=>"foo",b=>"bar");
$x->add_map(1,[@new500]);       

is_ok(  array_eq_str($x->[1]{500}{field}[4],\@new500) );                            # 12
$x->rebuild_map(1,500);       
my @add008 = ('008',"abcde");
$x->add_map(1,[@add008]);       

is_ok( array_eq_str($x->[1]{'008'}{field}[1],\@add008) );                            # 13
#delete $x->[1]{'008'};
$x->rebuild_map(1,'008');      
my @m008 = ('008', '741021s1884    enkaf         000 1 eng d'); 
is_ok( array_eq_str($x->[1]{'008'}{field}[0],\@m008) );                            # 14

is_ok( !defined($x->[1]{'008'}{field}[1]));                                         # 15

my @m5000 = (500, ' ', ' ', a=> 'boo');
is_ok( array_eq_str($x->[1]{'500'}{field}[0],\@m5000) );                            # 16

my @m5001 = (500, ' ', ' ', a=>'State B; gatherings saddle-stitched with wire staples.');
is_ok( array_eq_str($x->[1]{'500'}{field}[1],\@m5001) );                            # 17

my @m5002 = (500, ' ', ' ', a=> 'Advertisements on p. [1]-32 at end.');
is_ok( array_eq_str($x->[1]{'500'}{field}[2],\@m5002) );                            # 18

my @m5003 = (500, ' ', ' ', a=> 'Bound in red S cloth; stamped in black and gold.');
is_ok( array_eq_str($x->[1]{'500'}{field}[3],\@m5003) );                            # 19

is_ok( $x->deletefirst({field=>'500',record=>1}) );    # 20
$x->updatefirst({field=>'247',record=>1, rebuild_map =>0},
		 ('xxx',1," ", a =>"Photo marchive"));

$x->updatefirst({field=>'500',record=>1, rebuild_map =>0},
		 ('xxx',1," ", a =>"First English Fed."));

is_ok( $x->updatefirst({field=>'500',subfield=>"h",record=>1, rebuild_map =>0},
		 ('xxx',1," ", a =>"First English Fed.",h=>"foobar,the fed")) );    # 21
is_ok( $x->updatefirst({field=>'500',subfield=>"k",record=>1, rebuild_map =>0},
		 ('xxx',1," ", a =>"First English Fed.",k=>"koobar,the fed")) );    # 22

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

## is_ok($m008 eq "741021s1884    enkaf         000 1 eng d");

my ($m100a) = $x->getvalue({field=>'100',record=>1,subfield=>'a'});
my ($m100d) = $x->getvalue({field=>'100',record=>1,subfield=>'d'});
my ($m100e) = $x->getvalue({field=>'100',record=>1,subfield=>'e'});

is_ok($m100a eq "Twain, Mark,");				# 23
is_ok($m100d eq "1835-1910.");					# 24
is_bad(defined $m100e);						# 25

my @m246a = $x->getvalue({field=>'246',record=>2,subfield=>'a'});
is_ok(3 == scalar @m246a);					# 26
is_ok($m246a[0] eq "Photo archive");				# 27
is_ok($m246a[1] eq "Associated Press photo archive");		# 28
is_ok($m246a[2] eq "AP photo archive");				# 29

is_ok ($x->output({file=>">output4a.txt",'format'=>"ASCII"}));	# 30

my $update246 = {field=>'246',record=>2,ordered=>'y'};
my @u246 = $x->getupdate($update246);
is_ok(21 ==  @u246);						# 31


is_ok($u246[0] eq "i1");					# 32
is_ok($u246[1] eq "3");						# 33
is_ok($u246[2] eq "i2");					# 34
is_ok($u246[3] eq "0");						# 35
is_ok($u246[4] eq "a");						# 36
is_ok($u246[5] eq "Photo archive");				# 37
is_ok($u246[6] eq "\036");					# 38


is_ok($u246[7] eq "i1");					# 39
is_ok($u246[8] eq "3");						# 40
is_ok($u246[9] eq "i2");					# 41
is_ok($u246[10] eq " ");					# 42
is_ok($u246[11] eq "a");					# 43
is_ok($u246[12] eq "Associated Press photo archive");		# 44

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[13] eq "\036");					# 45
is_ok($u246[14] eq "i1");					# 46
is_ok($u246[15] eq "3");					# 47
is_ok($u246[16] eq "i2");					# 48
is_ok($u246[17] eq "0");					# 49
is_ok($u246[18] eq "a");					# 50
is_ok($u246[19] eq "AP photo archive");				# 51
is_ok($u246[20] eq "\036");					# 52

is_ok(3 == $x->deletemarc($update246));				# 53
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
is_ok(21 == @u246);						# 54

is_ok($u246[0] eq "i1");					# 55
is_ok($u246[1] eq "3");						# 56
is_ok($u246[2] eq "i2");					# 57
is_ok($u246[3] eq "0");						# 58
is_ok($u246[4] eq "a");						# 59
is_ok($u246[5] eq "Photo archive");				# 60
is_ok($u246[6] eq "\036");					# 61

is_ok($u246[7] eq "i1");					# 62
is_ok($u246[8] eq "3");						# 63
is_ok($u246[9] eq "i2");					# 64
is_ok($u246[10] eq " ");					# 65
is_ok($u246[11] eq "a");					# 66

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[12] eq "Associated Press photo archive");		# 67
is_ok($u246[13] eq "\036");					# 68

is_ok($u246[14] eq "i1");					# 69
is_ok($u246[15] eq "3");					# 70
is_ok($u246[16] eq "i2");					# 71
is_ok($u246[17] eq "0");					# 72
is_ok($u246[18] eq "a");					# 73

is_ok($u246[19] eq "AP photo archive");				# 74
is_ok($u246[20] eq "\036");					# 75


is_ok($x->addfield({record=>1, field=>"999", ordered=>"n", 
                    i1=>"5", i2=>"3", value=>[c=>"wL70",
		    d=>"AR Clinton PL",f=>"53525"]}));		# 76

is_ok($x->addfield({record=>1, field=>"900", ordered=>"y", 
                    i1=>"6", i2=>"7", value=>[z=>"part 1",
		    z=>"part 2",z=>"part 3"]}));		# 77

is_ok($x->addfield({record=>2, field=>"900", ordered=>"y", 
                    i1=>"9", i2=>"8", value=>[z=>"part 4"]}));	# 78

@records = $x->searchmarc({field=>'900'});
is_ok(2 == @records);						# 79
@records = $x->searchmarc({field=>'999'});
is_ok(1 == @records);						# 80

@records = $x->getupdate({field=>'900',record=>1});
is_ok(11 == @records);						# 81

is_ok($records[0] eq "i1");					# 82
is_ok($records[1] eq "6");					# 83
is_ok($records[2] eq "i2");					# 84
is_ok($records[3] eq "7");					# 85
is_ok($records[4] eq "z");					# 86
is_ok($records[5] eq "part 1");					# 87
is_ok($records[6] eq "z");					# 88

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[7] eq "part 2");					# 89
is_ok($records[8] eq "z");					# 90
is_ok($records[9] eq "part 3");					# 91
is_ok($records[10] eq "\036");					# 92

@records = $x->getupdate({field=>'900',record=>2});
is_ok(7 == @records);						# 93

is_ok($records[0] eq "i1");					# 94
is_ok($records[1] eq "9");					# 95
is_ok($records[2] eq "i2");					# 96
is_ok($records[3] eq "8");					# 97
is_ok($records[4] eq "z");					# 98

is_ok($records[5] eq "part 4");					# 99
is_ok($records[6] eq "\036");					# 100

@records = $x->getupdate({field=>'999',record=>1});
is_ok(11 == @records);						# 101

is_ok($records[0] eq "i1");					# 102
is_ok($records[1] eq "5");					# 103
is_ok($records[2] eq "i2");					# 104
is_ok($records[3] eq "3");					# 105
is_ok($records[4] eq "c");					# 106
is_ok($records[5] eq "wL70");					# 107
is_ok($records[6] eq "d");					# 108
is_ok($records[7] eq "AR Clinton PL");				# 109
is_ok($records[8] eq "f");					# 110

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[9] eq "53525");					# 111
is_ok($records[10] eq "\036");					# 112

@records = $x->getupdate({field=>'999',record=>2});
is_ok(0 == @records);						# 113

@records = $x->getupdate({field=>'001',record=>2});
is_ok(2 == @records);						# 114
is_ok($records[0] eq "ocm40139019 ");				# 115
is_ok($records[1] eq "\036");					# 116

