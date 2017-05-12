#!/usr/bin/perl -w


use Geo::E00;

use Data::Dumper;

	my $e = new Geo::E00;


	my $fh = $e->open($ARGV[0]);

	if (defined $fh)
	{
		my $edata = $e->parse;

#		print STDERR Data::Dumper->Dump( [ $edata ] );

		my $arcsets = $edata->{'arc'};

		my $table = "test";
		my $db = "gistest";

		my $ct = "CREATE TABLE $table (num int4, id int4, fnode int4, tnode int4, lpoly int4, rpoly int4, npoints int4);";
		my $gc = "SELECT AddGeometryColumn('$db','$table','the_geom','-1','LINESTRING',2);";

		print "$ct\n$gc\nBEGIN;\n";

		foreach my $set (@$arcsets)
		{
			# Collect the values for the INSERT statement

			my $values = join(",", @$set{
						'cov-num',
						'cov-id',
						'node-from',
						'node-to',
						'poly-left',
						'poly-right',
						'npoints'}
					);


			my @points = ();

			for (my $i = 0; $i < $set->{'npoints'}; $i++)
			{
				# +0 is used to force perl to convert 
				# the string to a number.

				my $x = $set->{'points'}[(2*$i)+0] + 0;
				my $y = $set->{'points'}[(2*$i)+1] + 0;

				push @points, "$x $y";
			}

			my $ls = "GeometryFromText('LINESTRING(" . join(",", @points) . ")',-1)";

			my $q = "INSERT INTO $table VALUES($values,$ls);";

			print "$q\n"; 			

#			print STDERR Data::Dumper->Dump( [ $set ] );
		}
	
		print "COMMIT;\n";
	}

__END__;

CREATE TABLE sample__arc (_arcnum INTEGER, _arcid INTEGER, _fnode INTEGER,
_tnode INTEGER, _lpoly INTEGER, _rpoly INTEGER, _ncoord INTEGER);
SELECT
AddGeometryColumn('__E_dbname__','sample__arc','_geom','__E_srid__','LINESTRING',2);
'LINESTRING(340199.78 4100000,340299.94 4100199.8)',__E_srid__));

select
AddGeometryColumn('gistest','parchi','the_geom','-1','MULTIPOLYGON',2);