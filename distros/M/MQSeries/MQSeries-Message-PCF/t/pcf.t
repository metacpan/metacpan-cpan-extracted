#
# $Id: pcf.t,v 33.9 2012/09/26 16:10:12 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

#
# The 19 has to be updated experimentally if the tests are extended.
#
BEGIN {
    print "1..19\n";
}

#
# We need this to pick up the PERL_DL_NONLAZY definition,
# conditionally.
#
BEGIN {
    require "../util/parse_config";
}

END { print "not ok 1\n" unless $loaded; }
use MQSeries::Message::PCF 1.34 qw(MQEncodePCF MQDecodePCF);
$loaded = 1;
print "ok 1\n";

#
# Here's the data we're going to feed into MQEncodePCF, and expect
# MQDecodePCF to reproduce.  The values are all bogus, of course.
#
my $headerin = 
  {
   Type		=> 1,
   Command	=> 2,
  };

my $paramsin =
  [
   # MQCFST
   {
    Parameter	=> 1,
    String	=> "a",
   },
   # MQCFIN
   {
    Parameter	=> 2,
    Value	=> 2,
   },
   # MQCFSL
   {
    Parameter	=> 3,
    Strings	=> [qw( FOO BAR BAZ BLEGH )],
   },
   # MQCFIL
   {
    Parameter	=> 4,
    Values	=> [1..4],
   },
  ];

#
# Test 2 -- verify basic MQEncodePCF functionality.
#
my $pcfout = MQEncodePCF($headerin,$paramsin);

unless ( defined $pcfout ) {
    print "Basic MQEncodePCF test failed!!\n";
    print "not ok 2\n";
    # Can't go any further if this is broken
    exit 0;
}

print "ok 2\n";

#
# Test 3 -- verify basic MQDecodePCF functionality.
#
my ($headerout,$paramsout) = MQDecodePCF($pcfout);

unless ( ref $headerout eq "HASH" && ref $paramsout eq "ARRAY" ) {
    print "Basic MQDecodePCF test failed!!\n";
    print "not ok 3\n";
    # Can't go any further if this is broken
    exit 0;
}

print "ok 3\n";

#
# Tests x..y -- verify reversible encode/decode of individual MQCF*
# structures.
#
# First, check the Header
#
$curtest = 4;

foreach my $key ( keys %$headerin ) {

    if (
	exists $headerout->{$key} &&
	$headerin->{$key} == $headerout->{$key}
       ) {
	print "ok $curtest\n";
    }
    else {
	print("Header key '$key' doesn't match:\n" .
	      "Input value  => '$headerin->{$key}'\n" .
	      "Output value => '$headerout->{$key}'\n");
	print "not ok $curtest\n";
    }

    $curtest++;
    
}

#
# Next check the Parameters
#
for ( my $index = 0 ; $index < scalar(@$paramsin) ; $index++ ) {

    unless ( $paramsin->[$index]->{Parameter} == $paramsout->[$index]->{Parameter} ) {
	print("Parameters do not match:\n" .
	      "Input Parameter  => '$paramsin->[$index]->{Parameter}'\n" .
	      "Output Parameter => '$paramsout->[$index]->{Parameter}'\n");
	print "not ";
    }
    print "ok $curtest\n";
    $curtest++;

    if ( exists $paramsin->[$index]->{String} ) {
	unless ( $paramsin->[$index]->{String} eq $paramsout->[$index]->{String} ) {
	    print("String doesn't match:\n" .
		  "Input String  => '$paramsin->[$index]->{String}'\n" .
		  "Output String => '$paramsout->[$index]->{String}'\n");
	    print "not ";
	}
	print "ok $curtest\n";
	$curtest++;
    }

    if ( exists $paramsin->[$index]->{Value} ) {
	unless ( $paramsin->[$index]->{Value} == $paramsout->[$index]->{Value} ) {
	    print("Value doesn't match:\n" .
		  "Input Value  => '$paramsin->[$index]->{Value}'\n" .
		  "Output Value => '$paramsout->[$index]->{Value}'\n");
	    print "not ";
	}
	print "ok $curtest\n";
	$curtest++;
    }

    if ( exists $paramsin->[$index]->{Strings} ) {
	
	for ( my $subindex = 0 ; $subindex < scalar(@{$paramsin->[$index]->{Strings}}) ; $subindex++ ) {
	    unless ( 
		    $paramsin->[$index]->{Strings}->[$subindex] eq
		    $paramsout->[$index]->{Strings}->[$subindex]
		   ) {
		print("Strings $subindex doesn't match:\n" .
		      "Input String  => '$paramsin->[$index]->{Strings}->[$subindex]'\n" .
		      "Output String => '$paramsout->[$index]->{Strings}->[$subindex]'\n" .
		      "Input Length  => " . length($paramsin->[$index]->{Strings}->[$subindex]) . "\n" .
		      "Output Length => " . length($paramsout->[$index]->{Strings}->[$subindex]) . "\n");
		print "not ";
	    }
	    print "ok $curtest\n";
	    $curtest++;
	}

    }

    if ( exists $paramsin->[$index]->{Values} ) {

	for ( my $subindex = 0 ; $subindex < scalar(@{$paramsin->[$index]->{Values}}) ; $subindex++ ) {
	    unless ( 
		    $paramsin->[$index]->{Values}->[$subindex] ==
		    $paramsout->[$index]->{Values}->[$subindex]
		   ) {
		print("Values $subindex doesn't match:\n" .
		      "Input Value  => '$paramsin->[$index]->{Values}->[$subindex]'\n" .
		      "Output Value => ' $paramsout->[$index]->{Values}->[$subindex]'\n");
		print "not ";
	    }
	    print "ok $curtest\n";
	    $curtest++;
	}

    }

}
