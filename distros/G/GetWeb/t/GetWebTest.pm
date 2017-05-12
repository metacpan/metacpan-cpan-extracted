#!/usr/bin/perl5

package t::GetWebTest;

use Net::Domain qw( hostfqdn );
use Cwd;

my $cwd = Cwd::fastcwd();
$gRoot = "$cwd/t/testRoot";
my $pgRoot = \$gRoot;

use strict;
use t::GT;

sub t;

my @mod = ( qw( NOMIME SOURCE ), 'TO getweb_discard' );
my $modCount = @mod;
my $testCount = 1 << $modCount;

my $test;
my $max;

sub go
{
    my $body = shift;
    my $subject = shift;
    $max = shift;
    my $inFile = shift;
    my $mode = shift;
    my $spool = shift;

    defined $max or $max = 2 * $modCount + 2;

    my $id = $0;
    $id =~ s/.+\///;
    $id =~ s/\.t$//;
    $test = new t::GT;

    my $healthnetIgnore = '/home/rolf/dev/getweb/';
    my $localIgnore = $cwd;

    $healthnetIgnore =~ s/\\/\\\\/g;
    $localIgnore =~ s/\\/\\\\/g;

    # $test -> ignore('id=','Message-ID:','References:');
    $test -> ignore(qw( ---------- healthnet.org ),
		       $healthnetIgnore, $localIgnore, hostfqdn);

    $test -> count($max);
    $test -> run();

    t($id,$body,$subject,$inFile,$mode,$spool);
}

sub t
{
    my $id = shift;
    my $body = shift;
    my $subject = shift;  # optional
    my $inFile = shift;   # optional
    my $mode = shift;     # optional
    my $spool = shift;    # optional
    
    my $i;
    for ($i = 0; $i < $testCount; $i++)
    {
	last unless $max--;

	if ($inFile)
	{
	    open(STDIN,$inFile) or die "could not open $inFile: $!";
	}

	my @modList;
        # print STDERR "i is $i $testCount\n";

	# to avoid taking exponential time...
	next unless ($i <= $modCount or
		     $testCount - $i - 1 <= $modCount );

	my $j = 0;
	while ($j < $modCount)
	{
	    push(@modList,$mod[$j])
		if ($i & (1 << $j));  # bitwise AND
	    $j++;
	}
	my $modString = join(' ',@modList,"file://test");
	# print STDERR "modstring is $modString\n";
	my $idSuffix = $modString;
	$idSuffix =~ s/\W/\./g;
	$idSuffix =~ s/file\.\.\.test$//;
	$idSuffix =~ s/\.$//;
	
	my $newBody = $body;
	$newBody =~ s/TEST/$modString/g;
	my $newSubject = $subject;
	$newSubject =~ s/TEST/$modString/g;

	my $switch;
	if ($mode eq 'cgi')
	{
	    $switch = '-c 2> /dev/null';
	}
	elsif ($mode eq 'spool')
	{
	    system("cp $spool.orig $spool");
	    system("/bin/rm -f $$pgRoot/spool/rfc822.in");
	    $switch = "-f $spool ";
	}
	elsif ($mode eq 'mail')
	{
	    $switch = '';
	}
	else
	{
	    $switch = "-i -s '$newSubject' -b '$newBody'";
	}

	my $cmd = "$^X ./getweb.pl -r $$pgRoot $switch";
	if ($ENV{GT_VERBOSE})
	{
	    print STDERR "command is: $cmd\n";
	}

	$test -> checkSys("ref.$idSuffix",$cmd);
    }
}

1;
