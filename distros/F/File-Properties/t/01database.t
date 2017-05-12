# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01database.t'

#########################

use lib 'lib';
use Test::More tests => 22;
BEGIN { use_ok('File::Properties::Database'); };
use Error qw(:try);
use File::Temp;

#########################

## Create temporary database file and create a
## File::Properties::Database object attached to it
my $tmpdb = File::Temp->new(EXLOCK => 0, SUFFIX => '.db', UNLINK => 1);
my $opts = {};
ok(my $fpd = File::Properties::Database->new($tmpdb->filename, $opts));

# Define a simple table in the database
ok($fpd->definetable('TheTable', ['ColumnA INTEGER', 'ColumnB TEXT']));

## Generate an array of test data consisting of a unique random
## integer and a corresponding random string
my ($rndi, $rnds);
my $rdat = [];
my $ihsh = {};
foreach (my $k = 0; $k < 10; $k++) {
  do {
    $rndi = int(rand(65536));
  }  while ($ihsh->{$rndi});
  $rnds = join '', map { ('A'..'Z','a'..'z', 0..9)[rand(62)] } 1..20;
  push @$rdat, [$rndi, $rnds];
  $ihsh->{$rndi} = $rnds;
}

# Insert element 0 of the test data into the table as an array
ok($fpd->insert('TheTable', {'Data' => $rdat->[0]}));

# Insert element 1 of tge test data into the table as an array, with
# explicitly specified column names
ok($fpd->insert('TheTable', {'Data' => $rdat->[1],
			     'Columns' => ['ColumnA', 'ColumnB']}));

# Insert elements 2 to 4 of the test data into the table as an array
# of arrays
ok($fpd->insert('TheTable', {'Data' => [@{$rdat}[2..4]]}));

## Insert element 5 of the test data into the table as a hash
my $hsh0 = {'ColumnA' => $rdat->[5]->[0],
	    'ColumnB' => $rdat->[5]->[1]};
ok($fpd->insert('TheTable', {'Data' => $hsh0}));

## Insert elements 6 to 9 of the test data into the table as a hash of
## arrays
my $hsh1 = {'ColumnA' => [], 'ColumnB' => []};
map { push @{$hsh1->{'ColumnA'}}, $_->[0] } @{$rdat}[6..9];
map { push @{$hsh1->{'ColumnB'}}, $_->[1] } @{$rdat}[6..9];
ok($fpd->insert('TheTable', {'Data' => $hsh1}));


## Retrieve row (as an array) in table for which ColumnA equals the
## integer component of element 9 of the test data, and check whether
## the retrieved row matches the corresponding test data
ok(my $row = $fpd->retrieve('TheTable', {'ReturnType' => 'Array',
	       'FirstRow' => 1, 'Where' => {'ColumnA' => $rdat->[9]->[0]}}));
ok($row->[0] == $rdat->[9]->[0] and $row ->[1] eq $rdat->[9]->[1]);

## Retrieve rows (as an array of arrays) in table for which ColumnA
## equals the integer component of element 7 or element 8 of the test
## data, and check whether the retrieved rows matche the corresponding
## test data
ok($row = $fpd->retrieve('TheTable', {'ReturnType' => 'Array',
			 'Where' => "ColumnA='$rdat->[7]->[0]' OR ".
			            "ColumnA='$rdat->[8]->[0]'"}));
ok($ihsh->{$row->[0]->[0]} eq $row->[0]->[1] and
   $ihsh->{$row->[1]->[0]} eq $row->[1]->[1]);

## Retrieve row (as a hash) in table for which ColumnA equals the
## integer component of element 0 of the test data, and check whether
## the retrieved row matches the corresponding test data
ok($row = $fpd->retrieve('TheTable', {'ReturnType' => 'Hash',
	      'FirstRow' => 1, 'Where' => {'ColumnA' => $rdat->[0]->[0]}}));
ok($row->{'ColumnB'} eq $rdat->[0]->[1]);

## Retrieve rows (as a hash of arrays) in table for which ColumnA
## equals the integer component of element 1 or element 2 of the test
## data, and check whether the retrieved rows matche the corresponding
## test data
ok($row = $fpd->retrieve('TheTable', {'ReturnType' => 'Hash',
			 'Where' => "ColumnA='$rdat->[1]->[0]' OR ".
			            "ColumnA='$rdat->[2]->[0]'"}));
ok($ihsh->{$row->{'ColumnA'}->[0]} eq $row->{'ColumnB'}->[0] and
   $ihsh->{$row->{'ColumnA'}->[1]} eq $row->{'ColumnB'}->[1]);

## Update the string component of the row in the table corresponding
## to element 0 of the test data, then retrieve that row and check
## whether the updated value is correct
ok($fpd->update('TheTable', {'Data' => {'ColumnB' => 'AAA'},
			     'Where' => {'ColumnA' => $rdat->[0]->[0]}}));
ok($row = $fpd->retrieve('TheTable', {'ReturnType' => 'Array',
				      'FirstRow' => 1, 'Where' =>
				        {'ColumnA' => $rdat->[0]->[0]}}));
ok($row->[1] eq 'AAA');

## Remove the row in the table corresponding to element 0 of the test
## data, then attempt to retrieve that row to confirm that it has been
## deleted
ok($fpd->remove('TheTable', {'Where' => {'ColumnA' => $rdat->[0]->[0]}}));
ok($row = $fpd->retrieve('TheTable', {'ReturnType' => 'Array',
				      'Where' =>
				        {'ColumnA' => $rdat->[0]->[0]}}));
ok(scalar @$row == 0);

#use Data::Dumper; print Dumper($row);

exit 0;
