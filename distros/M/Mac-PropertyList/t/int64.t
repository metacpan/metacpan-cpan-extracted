#!perl
use strict;
use warnings;

use Config qw(%Config);
use File::Spec::Functions;
use File::Temp qw(tempfile);
use Math::BigInt;
use Test::More;

my $HAS_64BIT = $Config{'ivsize'} >= 8 ? 1 : 0;
diag "64-bit is <$HAS_64BIT>";

my $HAS_PLUTIL = -x '/usr/bin/plutil';

my $class = 'Mac::PropertyList';

my %files = (
	xml    => catfile( qw(plists 64bit-xml.plist) ),
	json   => catfile( qw(plists 64bit-json.plist) ),
	binary => catfile( qw(plists 64bit-binary.plist) ),
	);

# these are strings, but we will test for strings to get around
# 32-bitedness
my %expected_hash = (
	billions     => '5123456789',
	trillions    => '8765123456789',
	quadrillions => '1298765123456789',
	big_negative => '-1234567890123',
	max_64_bit_signed_int	=> '9223372036854775807',
	min_64_bit_signed_int	=> '-9223372036854775808',
	);

subtest 'sanity' => sub {
	my @exports = qw(parse_plist parse_plist_file plist_as_string);
	use_ok $class, @exports or BAIL_OUT( "Could not compile $class: $@" );

	use_ok "${class}::$_" for map { "${_}Binary" } qw(Read Write);

	foreach my $export ( @exports ) {
		no strict 'refs';
		ok defined &{"$export"}, "<$export> is defined";
		}

	foreach my $file ( values %files ) {
		ok -e $file, "<$file> exists";
		}
	};

subtest 'read' => sub {
	subtest 'xml' => sub {
		my $file = $files{'xml'};
		ok -e $file, "<$file> exists";
		my $perl = parse_plist_file( $file );
		check_data($perl);
		};

	subtest 'binary' => sub {
		my $file = $files{'binary'};
		ok -e $file, "<$file> exists";
		my $parser = Mac::PropertyList::ReadBinary->new( $file );
		check_data($parser->plist);
		};
	};

subtest 'write' => sub {
	subtest 'xml' => sub {
		my( $fh, $filename ) = tempfile();

		my $xml = create_xml_data();
		like $xml, qr/\A\Q<?xml/, 'looks like XML';

		print {$fh} $xml;
		ok close $fh, "filehandle closed cleanly";

		ok -e $filename, "Temp file still exists";

		my $perl = parse_plist_file( $filename );
		check_data($perl);
		};

	subtest 'binary' => sub {
		my( $fh, $filename ) = tempfile();

		my $bin = create_binary_data();
		like $bin, qr/\A\Qbplist/, 'looks like binary plist';

		print {$fh} $bin;
		ok close $fh, "filehandle closed cleanly";

		ok -e $filename, "Temp file still exists";


		my $reader = 'Mac::PropertyList::ReadBinary';
		my $parser = $reader->new( $filename );
		isa_ok $parser, $reader;
		check_data($parser->plist);
		};
	};

sub check_data {
	my($data) = @_;
	subtest 'check data' => sub {
		isa_ok $data, ref {};
		foreach my $key ( keys %expected_hash ) {
			ok exists $data->{$key}, "key <$key> exists";
			cmp_ok $data->{$key}->value, '==', $expected_hash{$key}, "64-bit value <$expected_hash{$key}> matches";
			}
		};
	}

sub check_plutil {
	my( $filename ) = @_;

	SKIP: {
		subtest 'check plutil' => sub {
			skip "No plutil" unless $HAS_PLUTIL;
			my $p = `plutil -p "$filename"`;
			};
		}
	}

sub create_data {
	my $binary = defined $_[0] ? !! $_[0] : 0;

	my %hash;
	foreach my $key ( keys %expected_hash ) {
		$hash{$key} = Mac::PropertyList::integer->new( $expected_hash{$key} );
		}

	my $dict = Mac::PropertyList::dict->new(\%hash);

	my $string = $binary ?
		Mac::PropertyList::WriteBinary::as_string($dict)
		:
		plist_as_string($dict);
	}

sub create_binary_data { create_data(1) }

sub create_xml_data { create_data(0) }

done_testing();
