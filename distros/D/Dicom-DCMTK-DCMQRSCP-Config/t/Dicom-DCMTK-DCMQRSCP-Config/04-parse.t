# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::DCMTK::DCMQRSCP::Config;
use File::Object;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $obj = Dicom::DCMTK::DCMQRSCP::Config->new;
$obj->parse(scalar slurp($data_dir->file('ex1.conf')->s));
is_deeply(
	$obj,
	{
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
	},
	'Parse ex1.conf.'
);

# Test.
$obj->parse(scalar slurp($data_dir->file('ex2.conf')->s));
is_deeply(
	$obj,
	{
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
	},
	'Parse ex2.conf.'
);

# Test.
$obj->parse(scalar slurp($data_dir->file('ex3.conf')->s));
is_deeply(
	$obj,
	{
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
	},
	'Parse ex3.conf.'
);
