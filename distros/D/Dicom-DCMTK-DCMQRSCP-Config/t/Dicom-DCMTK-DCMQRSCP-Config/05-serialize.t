# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::DCMTK::DCMQRSCP::Config;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Dicom::DCMTK::DCMQRSCP::Config->new(
	'ae_table' => {
		'NTS_PACS_QR' => {
			'Access' => 'RW',
			'Peers' => 'ANY',
			'Quota' => {
				'maxBytesPerStudy' => '1024mb',
				'maxStudies' => '200',
			},
			'StorageArea' => '/var/lib/nts/dcmqrscp/',
		},
	},
	'comment' => 1,
	'global' => {
		'GroupName' => undef,
		'MaxAssociations' => 16,
		'MaxPDUSize' => 16384,
		'NetworkTCPPort' => 105,
		'UserName' => undef,
	},
	'host_table' => {
		'server' => [
			'NTS_PACS_QR',
			'nts',
			'105',
		],
	},
	'host_table_symb' => {},
	'vendor_table' => {},
);
my $ret = $obj->serialize;
my $right_ret = <<'END';
# Global Configuration Parameters.
MaxAssociations = 16
MaxPDUSize = 16384
NetworkTCPPort = 105

# Host Table.
HostTable BEGIN
server = (NTS_PACS_QR, nts, 105)
HostTable END

# AE Table.
AETable BEGIN
NTS_PACS_QR /var/lib/nts/dcmqrscp/ RW (200, 1024mb) ANY
AETable END
END
chomp $right_ret;
is($ret, $right_ret, 'Serialize simple configuration with comments.');

# Test.
$obj = Dicom::DCMTK::DCMQRSCP::Config->new(
	'ae_table' => {
		'NTS_PACS_QR' => {
			'Access' => 'RW',
			'Peers' => 'ANY',
			'Quota' => {
				'maxBytesPerStudy' => '1024mb',
				'maxStudies' => '200',
			},
			'StorageArea' => '/var/lib/nts/dcmqrscp/',
		},
	},
	'comment' => 0,
	'global' => {
		'GroupName' => undef,
		'MaxAssociations' => 16,
		'MaxPDUSize' => 16384,
		'NetworkTCPPort' => 105,
		'UserName' => undef,
	},
	'host_table' => {
		'server' => [
			'NTS_PACS_QR',
			'nts',
			'105',
		],
	},
	'host_table_symb' => {},
	'vendor_table' => {},
);
$ret = $obj->serialize;
$right_ret = <<'END';
MaxAssociations = 16
MaxPDUSize = 16384
NetworkTCPPort = 105
HostTable BEGIN
server = (NTS_PACS_QR, nts, 105)
HostTable END
AETable BEGIN
NTS_PACS_QR /var/lib/nts/dcmqrscp/ RW (200, 1024mb) ANY
AETable END
END
chomp $right_ret;
is($ret, $right_ret, 'Serialize simple configuration without comments.');

# Test.
$obj = Dicom::DCMTK::DCMQRSCP::Config->new(
	'ae_table' => {
		'NTS_PACS_QR' => {
			'Access' => 'RW',
			'Peers' => 'ANY',
			'Quota' => {
				'maxBytesPerStudy' => '1024mb',
				'maxStudies' => '200',
			},
			'StorageArea' => '/var/lib/nts/dcmqrscp/',
		},
	},
	'comment' => 1,
	'global' => {
		'GroupName' => undef,
		'MaxAssociations' => 16,
		'MaxPDUSize' => 16384,
		'NetworkTCPPort' => 105,
		'UserName' => undef,
	},
	'host_table' => {
		'server' => [
			'NTS_PACS_QR',
			'nts',
			'105',
		],
		'synedra' => [
			'SYNEDRA',
			'10.0.0.189',
			'104',
		],
	},
	'host_table_symb' => {},
	'vendor_table' => {},
);
$ret = $obj->serialize;
$right_ret = <<'END';
# Global Configuration Parameters.
MaxAssociations = 16
MaxPDUSize = 16384
NetworkTCPPort = 105

# Host Table.
HostTable BEGIN
server = (NTS_PACS_QR, nts, 105)
synedra = (SYNEDRA, 10.0.0.189, 104)
HostTable END

# AE Table.
AETable BEGIN
NTS_PACS_QR /var/lib/nts/dcmqrscp/ RW (200, 1024mb) ANY
AETable END
END
chomp $right_ret;
is($ret, $right_ret, 'Serialize another configuration with comments.');

# Test.
$obj = Dicom::DCMTK::DCMQRSCP::Config->new(
	'ae_table' => {
		'ACME_PUB' => {
			'Access' => 'R',
			'Peers' => 'ANY',
			'Quota' => {
				'maxBytesPerStudy' => '24mb',
				'maxStudies' => '10',
			},
			'StorageArea' => '/dicom/ACME_PUB',
		},
		'ACME_PRV' => {
			'Access' => 'RW',
			'Peers' => 'Acme',
			'Quota' => {
				'maxBytesPerStudy' => '24mb',
				'maxStudies' => '10',
			},
			'StorageArea' => '/dicom/ACME_PRV',
		},
	},
	'comment' => 1,
	'global' => {
		'GroupName' => 'dcmtk',
		'MaxAssociations' => 20,
		'MaxPDUSize' => 8192,
		'NetworkTCPPort' => 104,
		'UserName' => 'dcmtk',
	},
	'host_table' => {
		'Acme_1' => [
			'ACME_DN1',
			'acme',
			10001
		],
		'Acme_2' => [
			'ACME_DN2',
			'acme',
			10001
		],
		'Acme_3' => [
			'ACME_DN3',
			'acme',
			10001
		],
	},
	'host_table_symb' => {
		'Acme' => [
			'Acme_1',
			'Acme_2',
			'Acme_3',
		],
	},
	'vendor_table' => {
		'Acme' => 'ACME CT Company',
	},
);
$ret = $obj->serialize;
$right_ret = <<'END';
# Global Configuration Parameters.
GroupName = "dcmtk"
MaxAssociations = 20
MaxPDUSize = 8192
NetworkTCPPort = 104
UserName = "dcmtk"

# Host Table.
HostTable BEGIN
Acme_1 = (ACME_DN1, acme, 10001)
Acme_2 = (ACME_DN2, acme, 10001)
Acme_3 = (ACME_DN3, acme, 10001)
Acme = Acme_1, Acme_2, Acme_3
HostTable END

# Vendor Table.
VendorTable BEGIN
"ACME CT Company" = Acme
VendorTable END

# AE Table.
AETable BEGIN
ACME_PRV /dicom/ACME_PRV RW (10, 24mb) Acme
ACME_PUB /dicom/ACME_PUB R (10, 24mb) ANY
AETable END
END
chomp $right_ret;
is($ret, $right_ret, 'Serialize advanced configuration with comments.');
