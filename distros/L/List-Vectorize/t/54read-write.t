use Test::More tests => 31;
use FindBin qw($Bin);
use strict;

BEGIN {
	use_ok ( 'List::Vectorize' );
}

my $mat = [[1, 2, 3],
           [4, 5, 6],
		   [7, 8, 9]];
my $rownames = ["r1", "r2", "r3"];
my $colnames = ["c1", "c2", "c3"];


ok( write_table($mat, "file" => "$Bin/.f1") );
ok( write_table($mat, "file" => "$Bin/.f2", "quote" => "'") );
ok( write_table($mat, "file" => "$Bin/.f3", "sep" => ",", "quote" => "\"") );
ok( write_table($mat, "file" => "$Bin/.f4", "row.names" => $rownames) );
ok( write_table($mat, "file" => "$Bin/.f5", "col.names" => $colnames) );
ok( write_table($mat, "file" => "$Bin/.f6", "row.names" => $rownames, "col.names" => $colnames) );

my $m;
my $rn;
my $cn;
ok( ($m, $cn, $rn) = read_table("$Bin/.f1") );
is_deeply($m, [[1, 2, 3],
               [4, 5, 6],
			   [7, 8, 9]]);
is($cn, undef);
is($rn, undef);

ok( ($m, $cn, $rn) = read_table("$Bin/.f2", "quote" => "'") );
is_deeply($m, [[1, 2, 3],
               [4, 5, 6],
			   [7, 8, 9]]);
is($cn, undef);
is($rn, undef);

ok( ($m, $cn, $rn) = read_table("$Bin/.f3", "quote" => "\"", "sep" => ",") );
is_deeply($m, [[1, 2, 3],
               [4, 5, 6],
			   [7, 8, 9]]);
is($cn, undef);
is($rn, undef);

ok( ($m, $cn, $rn) = read_table("$Bin/.f4", "row.names" => 1) );
is_deeply($m, [[1, 2, 3],
               [4, 5, 6],
			   [7, 8, 9]]);
is($cn, undef);
is_deeply($rn, ["r1", "r2", "r3"]);

ok( ($m, $cn, $rn) = read_table("$Bin/.f5", "col.names" => 1) );
is_deeply($m, [[1, 2, 3],
               [4, 5, 6],
			   [7, 8, 9]]);
is_deeply($cn, ["c1", "c2", "c3"]);
is($rn, undef);

ok( ($m, $cn, $rn) = read_table("$Bin/.f6", "col.names" => 1, "row.names" => 1) );
is_deeply($m, [[1, 2, 3],
               [4, 5, 6],
			   [7, 8, 9]]);
is_deeply($cn, ["c1", "c2", "c3"]);
is_deeply($rn, ["r1", "r2", "r3"]);

unlink("$Bin/.f1") if(-e "$Bin/.f1");
unlink("$Bin/.f2") if(-e "$Bin/.f2");
unlink("$Bin/.f3") if(-e "$Bin/.f3");
unlink("$Bin/.f4") if(-e "$Bin/.f4");
unlink("$Bin/.f5") if(-e "$Bin/.f5");
unlink("$Bin/.f6") if(-e "$Bin/.f6");
unlink("$Bin/.f7") if(-e "$Bin/.f7");
unlink("$Bin/.f8") if(-e "$Bin/.f8");
