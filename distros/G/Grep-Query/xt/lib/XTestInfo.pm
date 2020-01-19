package XTestInfo;

use strict;
use warnings;

use DBI;
use File::Temp qw(tempdir);
use Test::More;

my @FIELDNAMES = qw(name byear siblings city sex);
my %FIELDTYPES =
	(
		name => 'TEXT',
		byear => 'INTEGER',
		siblings => 'INTEGER',
		city => 'TEXT',
		sex => 'TEXT',
	);

sub getEmptyDbHandle
{
	my $name = shift;

	my $tempDir = tempdir(CLEANUP => 1);

	my $dbfile = "$tempDir/$name.DB";
	die("already exists: $dbfile") if -e $dbfile;

    note("db: $dbfile");
	
	return DBI->connect("dbi:SQLite:dbname=$dbfile",'','', {RaiseError => 1, AutoCommit => 0});
}

my $dbCreators =
	{
		numbers => sub
			{
				my $name = shift;
				my $data = shift;
				
				my $dbh = getEmptyDbHandle($name);
				
				$dbh->do("create table 'numbers' ( 'number' INTEGER )");
			
				my $sth = $dbh->prepare("insert into numbers ( number ) values ( ? )");
				$sth->execute($_) foreach @$data;
				
				$dbh->commit();
				
				return $dbh;
			},
		
		regexps => sub
			{
				my $name = shift;
				my $data = shift;
				
				my $dbh = getEmptyDbHandle($name);
				
				$dbh->do("create table 'lines' ( 'line' TEXT )");
			
				my $sth = $dbh->prepare("insert into lines ( line ) values ( ? )");
				$sth->execute($_) foreach @$data;
		
				$dbh->commit();
				
				return $dbh;
			},
			
		records => sub
			{
				my $name = shift;
				my $data = shift;

				my $dbh = getEmptyDbHandle($name);

				my @coldefs;
				foreach my $field (@FIELDNAMES)
				{
					push(@coldefs, "'$field' $FIELDTYPES{$field}");
				}
				my $coldefsAsString = join(',', @coldefs);
				$dbh->do("create table 'records' ( $coldefsAsString )");
			
				my $qmarks = join(',', split('', '?' x scalar(@FIELDNAMES)));
				my $fieldnames = join(',', @FIELDNAMES);
				my $sth = $dbh->prepare("insert into records ( $fieldnames ) values ( $qmarks )");
				
				foreach my $recName (sort(keys(%$data)))
				{
					my @bind;
					foreach my $field (@FIELDNAMES)
					{
						push(@bind, $data->{$recName}->{$field});
					}
					$sth->execute(@bind);
				}
				
				$dbh->commit();
				
				return $dbh;
			},
	};

my $dbExecutors =
	{
		numbers => sub { $_[0]->selectcol_arrayref("select number from numbers where $_[1]") },

		regexps => sub { $_[0]->selectcol_arrayref("select line from lines where $_[1]") },
			
		records => sub { $_[0]->selectall_arrayref("select " . join(',', @FIELDNAMES) . " from records where $_[1]", { Slice => {} }) },
	};

sub getDbCreator
{
	return $dbCreators->{$_[0]};
}

sub getDbExecutor
{
	return $dbExecutors->{$_[0]};
}
	
1;
