package XTestUtils;

use strict;
use warnings;

use Test::More;
use Test::Differences;

use TestInfo;
use XTestInfo;

sub runAsNonFieldedDbTests
{
	my $name = shift;
	
	my @data = @{TestInfo::getData($name)};
	my @tests = @{TestInfo::getTests($name)};
	my $dbCreator = XTestInfo::getDbCreator($name);
	my $dbExecutor = XTestInfo::getDbExecutor($name);
	 
	my $dbh = $dbCreator->($name, \@data);
	
	plan tests => scalar(@tests);

	foreach my $t (@tests)
	{
		if ($t->{dbq})
		{
			my $dbmatches = $dbExecutor->($dbh, $t->{dbq});
			eq_or_diff($dbmatches, $t->{e}, $t->{dbq});
		}
		else
		{
			pass("(no db query defined)");
		}
	}
	
	$dbh->disconnect();
}

sub runAsFieldedDbTests
{
	my $name = shift;
	
	my %data = %{TestInfo::getData($name)};
	my @tests = @{TestInfo::getTests($name)};
	my $dbCreator = XTestInfo::getDbCreator($name);
	my $dbExecutor = XTestInfo::getDbExecutor($name);
	 
	my $dbh = $dbCreator->($name, \%data);
	
	plan tests => scalar(@tests);

	foreach my $t (@tests)
	{
		if ($t->{dbq})
		{
			my $dbmatches = $dbExecutor->($dbh, $t->{dbq});
			eq_or_diff($dbmatches, $t->{e}, $t->{dbq});
		}
		else
		{
			pass("(no db query defined)");
		}
	}
	
	$dbh->disconnect();
}

1;
