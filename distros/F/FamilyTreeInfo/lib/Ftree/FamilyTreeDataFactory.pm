package Ftree::FamilyTreeDataFactory;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');
use v5.10.1;
use experimental 'smartmatch';

sub getFamilyTree {
	my ($config) = @_;
	my $type = $config->{type};
	$type = 'csv' if ( $type eq 'txt' );

	given ($type) {
		when (/\bcsv\b/) {
			require Ftree::DataParsers::ExtendedSimonWardFormat;
			return
			  Ftree::DataParsers::ExtendedSimonWardFormat::createFamilyTreeDataFromFile(
				$config->{config} );
		}
		when (/\bexcel\b/) {
			require Ftree::DataParsers::ExcelFormat;
			return
			  Ftree::DataParsers::ExcelFormat::createFamilyTreeDataFromFile(
				$config->{config} );
		}
		when (/\bexcelx\b/) {
			require Ftree::DataParsers::ExcelxFormat;
			return
			  Ftree::DataParsers::ExcelxFormat::createFamilyTreeDataFromFile(
				$config->{config} );
		}
		when (/\bser\b/) {
			require Ftree::DataParsers::SerializerFormat;
			return
			  Ftree::DataParsers::SerializerFormat::createFamilyTreeDataFromFile(
				$config->{config} );
		}
		when (/\bgedcom\b/) {
			require Ftree::DataParsers::GedcomFormat;
			return
			  Ftree::DataParsers::GedcomFormat::createFamilyTreeDataFromFile(
				$config->{config} );
		}
		when (/\bdbi\b/) {
			require Ftree::DataParsers::DBIFormat;
			return Ftree::DataParsers::DBIFormat::getFamilyTreeData(
				$config->{config} );
		}
		default { die "Unknown type: $type" }
	}

	return;
}

1;
