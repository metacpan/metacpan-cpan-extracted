# to use these testcases (only MS SQL server), create a database pubs in the local sql server instance where the current account has dbo rights (tables are created/dropped)
use strict; use warnings;
use EAI::DB; use Test::More; use Data::Dumper; use feature 'unicode_strings'; use utf8;

if ($ENV{EAI_WRAP_AUTHORTEST}) {
	plan tests => 20;
} else {
	plan skip_all => "tests not automatic in non-author environment";
}
require './t/setup.pl';
chdir "./t";
newDBH({}, 'driver={SQL Server};Server=.;database=pubs;TrustedConnection=Yes;');
my ($dbHandle, $DSN) = getConn();
doInDB({doString => "DROP TABLE [dbo].[theTestTable];"});
my $createStmt = "CREATE TABLE [dbo].[theTestTable]([selDate] [datetime] NOT NULL,[ID0] [varchar](4) NOT NULL,[ID1] [bigint] NOT NULL,[ID2] [char](3) NOT NULL,[Number] [int] NOT NULL, [Amount] [decimal](28, 2) NOT NULL, [UTF8_ÄÖÜ] [varchar](20) NULL, CONSTRAINT [PK_theTestTable] PRIMARY KEY CLUSTERED (selDate ASC)) ON [PRIMARY]";
# 1 successful creation of table with doInDB
is(doInDB({doString => $createStmt}),1,'doInDB');
my $data = [{'selDate' => '20190618','ID0' => 'ABCD','ID1' => 5456,'ID2' => 'ZYX','Number' => 1,'Amount' => 123456.12, 'UTF8_ÄÖÜ' => 'UTF8_Data1:äöü'},
            {'selDate' => '20190619','ID0' => 'ABCD','ID1' => 5856,'ID2' => 'XYY','Number' => 1,'Amount' => 65432.1, 'UTF8_ÄÖÜ' => 'UTF8_Data2:ßÄÖÜ'},
           ];
# 2 insert
is(storeInDB({tablename => "dbo.theTestTable", upsert=>0, primkey=>"selDate = ?"},$data),1,'storeInDB insert');
# 3 upsert
is(storeInDB({tablename => "dbo.theTestTable", upsert=>1, primkey=>"selDate = ?"},$data),1,'storeInDB upsert');
# 4 Syntax error
is(storeInDB({tablename => "dbo.theTestTable", upsert=>1, primkey=>"selDtae = ?"},$data),0,'storeInDB error');
# 5 duplicate error
is(storeInDB({tablename => "dbo.theTestTable", upsert=>0, primkey=>"selDate = ?"},$data),0,'storeInDB duplicate error');

# 6 Data error
$data = [{'selDate' => '20190620','ID0' => 'ABCD_WayTooLongField','ID1' => 5456,'ID2' => 'XZY','Number' => 1,'Amount' => 123456.12}
		];
is(storeInDB({tablename => "dbo.theTestTable", upsert=>0, primkey=>"selDate = ?", debugKeyIndicator=>"selDate=? ID1=?"}, $data),0,'storeInDB Datenfehler');

# 7 update in Database
my $upddata = { '20190618' => {'selDate' => '2019-06-18','ID0' => 'ABCD','ID1' => 5456,'ID2' => 'ZYX','Number' => 2,'Amount' => 123456789.12},
				'20190619' => {'selDate' => '2019-06-19','ID0' => 'ABCD','ID1' => 5856,'ID2' => 'XYZ','Number' => 1,'Amount' => 65432.1},
			  };
is(updateInDB({tablename => "dbo.theTestTable", keyfields=>["selDate"]},$upddata),1,'updateInDB');

# 8 results from readFromDB (array)
my @columnnames;
my $query = "SELECT selDate,ID0,ID1,ID2,Number,Amount,UTF8_ÄÖÜ from dbo.theTestTable WHERE selDate = '20190619'";
my @result;
my $expected_result=[{Number=>1,ID0=>'ABCD',selDate=>'2019-06-19 00:00:00.000',Amount=>'65432.10',ID1=>'5856',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}];

# 9 results from readFromDB
readFromDB({query=>$query, columnnames=>\@columnnames}, \@result);
is_deeply(\@result,$expected_result,"readFromDB");
is("@columnnames","selDate ID0 ID1 ID2 Number Amount UTF8_ÄÖÜ","columnnames returned correctly from readFromDB");

# 10 results from readFromDBHash (hash)
my %result;
$expected_result={'2019-06-19 00:00:00.000'=>{Number=>1,ID0=>'ABCD',selDate=>'2019-06-19 00:00:00.000',Amount=>'65432.10',ID1=>'5856',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}};
readFromDBHash({query=>$query, keyfields=>["selDate"]}, \%result);
is_deeply(\%result,$expected_result,"readFromDBHash");

# 11 results from readFromDBHash (hash) with unicode keyfield
%result = ();
$expected_result={'UTF8_Data2:ßÄÖÜ'=>{Number=>1,ID0=>'ABCD',selDate=>'2019-06-19 00:00:00.000',Amount=>'65432.10',ID1=>'5856',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}};
readFromDBHash({query=>$query, keyfields=>["UTF8_ÄÖÜ"]}, \%result, 1); # need additional encode_keys_utf8 flag here, because odbc driver issue
is_deeply(\%result,$expected_result,"readFromDBHash with unicode keyfield");

# 12 return values in doInDB with parameters: returns ref to array of array, containing hash refs in retvals
my @retvals;
$expected_result=[[{ID0=>'ABCD',ID1=>'5456',Number=>2,ID2=>'ZYX',selDate=>'2019-06-18 00:00:00.000',Amount=>'123456789.12','UTF8_ÄÖÜ'=>'UTF8_Data1:äöü'}]];
doInDB({doString => "select * from [dbo].[theTestTable] where ID0 = ? AND ID1 = ? AND ID2 = ?", parameters => ['ABCD',5456,'ZYX']}, \@retvals);
is_deeply(\@retvals,$expected_result,"doInDB returned values");

# 13 delete in Database
my $deldata = ['2019-06-18'];
$expected_result=[[{ID0=> 'ABCD',selDate=>'2019-06-19 00:00:00.000',Number=>1,Amount=>'65432.10',ID1=>'5856',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}]];
deleteFromDB({tablename => "dbo.theTestTable", keyfields=>["selDate"]},$deldata);
doInDB({doString => "select * from [dbo].[theTestTable]"}, \@retvals);
is_deeply(\@retvals,$expected_result,"deleteFromDB");

# 14 transaction start
beginWork();
doInDB({doString => "update [dbo].[theTestTable] set ID1='9999' where selDate='2019-06-19'"}, \@retvals);
$expected_result=[{Number=>1,ID0=>'ABCD',selDate=>'2019-06-19 00:00:00.000',Amount=>'65432.10',ID1=>'9999',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}];
readFromDB({query => "select * from [dbo].[theTestTable]", columnnames=>\@columnnames}, \@retvals);
is_deeply(\@retvals,$expected_result,"transaction start");

# 15 transaction commit
commit();
$expected_result=[{Number=>1,ID0=>'ABCD',selDate=>'2019-06-19 00:00:00.000',Amount=>'65432.10',ID1=>'9999',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}];
readFromDB({query => "select * from [dbo].[theTestTable]", columnnames=>\@columnnames}, \@retvals);
is_deeply(\@retvals,$expected_result,"transaction commit");

# 16 transaction start
beginWork();
doInDB({doString => "update [dbo].[theTestTable] set ID1='7777' where selDate='2019-06-19'"}, \@retvals);
$expected_result=[{Number=>1,ID0=>'ABCD',selDate=>'2019-06-19 00:00:00.000',Amount=>'65432.10',ID1=>'7777',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}];
readFromDB({query => "select * from [dbo].[theTestTable]", columnnames=>\@columnnames}, \@retvals);
is_deeply(\@retvals,$expected_result,"transaction start");

# 17 transaction rollback
rollback();
$expected_result=[{Number=>1,ID0=>'ABCD',selDate=>'2019-06-19 00:00:00.000',Amount=>'65432.10',ID1=>'9999',ID2=>'XYZ','UTF8_ÄÖÜ'=>'UTF8_Data2:ßÄÖÜ'}];
readFromDB({query => "select * from [dbo].[theTestTable]", columnnames=>\@columnnames}, \@retvals);
is_deeply(\@retvals,$expected_result,"transaction rollback");

# 18 set connection
is(setConn($dbHandle, $DSN),1,"setConn successful");

# 19 get connection (handle and DSN)
my ($retDBH,$retDSN) = getConn();
is_deeply($retDBH,$dbHandle,"getConn returned correct db handle");
is($retDSN,$DSN,"getConn returned correct DSN");

# cleanup
doInDB({doString => "DROP TABLE [dbo].[theTestTable]"});
unlink "config/site.config";
unlink "config/log.config";
rmdir "config";

done_testing();