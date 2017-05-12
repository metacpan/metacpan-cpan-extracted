#!/usr/bin/perl -w

# This example script will export from Address Book
# and generate the html pages into the out directory.

use strict;

use Mac::Glue::Apps::AddressBookExport;

my $exporter = Mac::Glue::Apps::AddressBookExport->new({
	out_file        => '/tmp/address.vcf',
	glue_name       => 'Address Book',
	skip_with_image => 1,

	# Templates
        template_root => './templates',
	out_dir         => './out',

});

$exporter->export_address_book();
