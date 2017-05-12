use strict;
use Test::More;
use FindBin qw($Bin);

eval 'use Test::Exception';

plan (skip_all => 'Test::Exception not installed') if ($@);

use List::Vectorize;

my $mat = [[1, 2, 3],
           [4, 5, 6],
		   [7, 8, 9]];
my $rownames = ["r1", "r2", "r3"];
my $colnames = ["c1", "c2", "c3"];


eval qq` dies_ok { List::Vectorize::write_table(\$mat, "file" => "\$Bin/.f7", "row.names" => ["a", "b"])  } `;
eval qq` dies_ok { List::Vectorize::write_table(\$mat, "file" => "\$Bin/.f8", "col.names" => ["a", "b"])  } `;
eval qq` dies_ok { List::Vectorize::read_table("file_not_exist") } `;

done_testing();
