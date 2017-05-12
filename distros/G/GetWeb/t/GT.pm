# generic tester

package t::GT;

use strict;

my $gUpdate = 0;

sub new
{
    my $type = shift;

    if ($ENV{GT_UPDATE})
    {
	$gUpdate = 1;
    }

    my $self = {
	# NUM_TEST = $numTest
	TEST_COUNT => 0,
	IGNORE => [ ]
	};
    bless($self,$type);
}

my $gOK = 0;

sub ignore
{
    my $self = shift;
    my $paIgnore = $$self{IGNORE};
    push(@$paIgnore,@_);
}

sub ok
{
    $gOK++;
    print STDOUT "ok $gOK\n\n";
}

sub count
{
    my $self = shift;
    $$self{TEST_COUNT} = shift;
}

sub END
{
    my $tmpDir = "t/tmp.$$";
    rmdir($tmpDir) or warn "could not remove $tmpDir";
}

sub run
{
    my $self = shift;
    my $count = $$self{TEST_COUNT};

    my $tmpDir = "t/tmp.$$";
    mkdir($tmpDir,0777) or die "could not create $tmpDir";

    print STDOUT "1..", $count+1, "\n";
    $self -> ok;
}

sub checkSys
{
    my $self = shift;
    my $id = shift;
    my $cmdLine = shift;

    $self -> checkFH($id);
    open(IN,"$cmdLine |");
    print (<IN>);
    close(IN);
    my $retVal = $? >> 8;
    die "$cmdLine returned $retVal" if $retVal;
    $self -> done();
}

sub checkFH
{
    my $self = shift;
    my $id = shift;

    $$self{ID} = $id;

    my $tmpDir = "t/tmp.$$";
    (-d $tmpDir) or die "no such dir: $tmpDir";

    my $outFile = "$tmpDir/$id";

    open(OUT,">$outFile") or die "could not open $outFile";
    select(OUT);
}

sub done
{
    my $self = shift;

    my $id = $$self{ID};
    defined $id or die "no id defined";

    close(OUT);
    select(STDOUT);

    my $tmpDir = "t/tmp.$$";
    (-d $tmpDir) or die "no such dir: $tmpDir";

    my $refDir = $0;
    $refDir =~ s/\.t$//;
    $refDir =~ s/.+\///;
    $refDir = "t/ref." . $refDir;
    if (! -d $refDir)
    {
	$gUpdate or die "no such dir: $refDir";
	mkdir($refDir,0777) or die "could not make $refDir: $!";
    }

    my $outFile = "$tmpDir/$id";
    my $refFile = "$refDir/$id";

    if ($gUpdate)
    {
	system("cp $outFile $refFile");
    }
    else
    {
	my $paIgnore = $$self{IGNORE};
	my $diff = "diff";

	if (@$paIgnore)
	{
	    my $pattern = "'\\(" . join('\)\|\(',@$paIgnore) . "\\)'";
	    $diff .= " -I $pattern --ignore-blank-lines";
	}

	$diff = "$diff $outFile $refFile";

	# print STDERR $diff;

	my $retVal = system($diff) >> 8;
	$retVal and die "diff returned $retVal, stopped";
	#open(DIFF,"$diff |") or die "could not open $diff";
	#my @val = <DIFF>;
	#@val and die "diff found differences since last ref version";
    }
    
    $self -> ok;

    unlink($outFile);
}

1;
