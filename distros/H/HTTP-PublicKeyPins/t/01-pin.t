#!perl 
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Crypt::PKCS10();
use HTTP::PublicKeyPins qw(pin_sha256);
use FileHandle();
use File::Spec();

plan tests => 40;

MAIN: {
	diag(`openssl version`);
	foreach my $path ('t/certs/duckduckgo.pem', 't/certs/dsa.pem', 't/certs/google.pem',
									't/certs/trusted.pem', # /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
									't/certs/x509.pem', # RFC 7468
									't/certs/x509_1.pem') # RFC 7468
	{
		test_certificate($path);
	}
	foreach my $path ('t/reqs/rsa.pem', 't/reqs/new.pem') {
		test_request($path);
	}
	test_rsa_pub_key('duckduckgo');
	test_rsa_key('test.key');
	eval {
		pin_sha256('t/certs/missing.pem');
	};
	chomp $@;
	ok($@ =~ /Failed to open/, "Correctly threw an exception:$@");
	eval {
		pin_sha256('t/certs/corrupt.pem');
	};
	chomp $@;
	ok($@ =~ /is not an X.509 Certificate/, "Correctly threw an exception:$@");
	my $handle = FileHandle->new("$^X -Ilib bin/hpkp_pin_sha256 t/certs/duckduckgo.pem |");
	my $pin = <$handle>;
	chomp $pin;
	ok($pin eq 'lVqQMd3vaHRYd9jjtXDTwNiwip6JfWXwiOInf0+ebSU=', "Correctly ran the hpkp_pin_sha256 binary");
}

sub test_request {
	my ($path) = @_;
	SKIP: {
		my $temp_der_pub_path = 't/test_der.pub';
		my $temp_pem_pub_path = 't/test_pem.pub';
		diag("Testing Request $path");
		diag(`openssl req -noout -in $path -pubkey >$temp_pem_pub_path`);
		if ($? != 0) {
			unlink $temp_pem_pub_path;
			diag(`openssl req -noout -in $path -pubkey`);
			skip("openssl is not available or does not support the certificate request in $path", 5);
		}
		unlink $temp_pem_pub_path or die "Failed to unlink $temp_pem_pub_path:$!";
		my $test_pin_sha256 = pin_sha256($path);
		`openssl req -noout -in $path -pubkey | openssl asn1parse -noout -inform pem -out $temp_der_pub_path`;
		my $rfc_7469_pin_sha256 = `openssl dgst -sha256 -binary $temp_der_pub_path | openssl enc -base64`;
		chomp $rfc_7469_pin_sha256;
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "$path produced the correct HPKP pin:$rfc_7469_pin_sha256");
		`openssl req -noout -in $path -pubkey >$temp_pem_pub_path`;
		$test_pin_sha256 = pin_sha256($temp_pem_pub_path);
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "The extracted public key from $path produced the correct HPKP pin:$rfc_7469_pin_sha256");
		$test_pin_sha256 = pin_sha256($path);
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "The certificate request in $path produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_pem_pub_path or die "Failed to unlink $temp_pem_pub_path:$!";
		my $temp_der_req_path = 't/test_der.req';
		`openssl req -inform pem -in $path -outform DER -out $temp_der_req_path`;
		$test_pin_sha256 = pin_sha256($temp_der_req_path);
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "$path when converted to DER format produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_der_req_path or die "Failed to unlink $temp_der_req_path:$!";
		$test_pin_sha256 = pin_sha256($temp_der_pub_path);
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "The extracted public key from $path when converted to DER format produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_der_pub_path or die "Failed to unlink $temp_der_pub_path:$!";
	}
}

sub test_certificate {
	my ($path) = @_;
	SKIP: {
		my $temp_der_pub_path = 't/test_der.pub';
		my $temp_pem_pub_path = 't/test_pem.pub';
		diag("Testing Certificate $path");
		my $version = `openssl x509 -noout -in $path -pubkey >$temp_pem_pub_path`;
		if ($? != 0) {
			unlink $temp_pem_pub_path;
			diag(`openssl x509 -noout -in $path -pubkey`);
			skip("openssl is not available or does not support the certificate in $path", 4);
		}
		unlink $temp_pem_pub_path or die "Failed to unlink $temp_pem_pub_path:$!";
		my $test_pin_sha256 = pin_sha256($path);
		`openssl x509 -noout -in $path -pubkey | openssl asn1parse -noout -inform pem -out $temp_der_pub_path`;
		my $rfc_7469_pin_sha256 = `openssl dgst -sha256 -binary $temp_der_pub_path | openssl enc -base64`;
		chomp $rfc_7469_pin_sha256;
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "$path produced the correct HPKP pin:$rfc_7469_pin_sha256");
		`openssl x509 -noout -in $path -pubkey >$temp_pem_pub_path`;
		$test_pin_sha256 = pin_sha256($temp_pem_pub_path);
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "The extracted public key from $path produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_pem_pub_path or die "Failed to unlink $temp_pem_pub_path:$!";
		my $temp_der_cert_path = 't/test_der.cer';
		`openssl x509 -inform pem -in $path -outform DER -out $temp_der_cert_path`;
		$test_pin_sha256 = pin_sha256($temp_der_cert_path);
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "$path when converted to DER format produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_der_cert_path or die "Failed to unlink $temp_der_cert_path:$!";
		$test_pin_sha256 = pin_sha256($temp_der_pub_path);
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "The extracted public key from $path when converted to DER format produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_der_pub_path or die "Failed to unlink $temp_der_pub_path:$!";
	}
}

sub test_rsa_pub_key {
	my ($path) = @_;
	SKIP: {
		my $temp_der_pub_path = 't/test_der.pub';
		my $temp_pem_pub_path = 't/test_pem.pub';
		my $version = `openssl x509 -noout -in t/certs/$path.pem -pubkey >$temp_pem_pub_path`;
		if ($? != 0) {
			unlink $temp_pem_pub_path;
			diag(`openssl x509 -noout -in t/certs/$path.pem -pubkey`);
			skip("openssl is not available or does not support the certificate in t/certs/$path.pub", 1);
		}
		unlink $temp_pem_pub_path;
		my $test_pin_sha256 = pin_sha256("t/keys/$path.pub");
		`openssl x509 -noout -in t/certs/$path.pem -pubkey | openssl asn1parse -noout -inform pem -out $temp_der_pub_path`;
		my $rfc_7469_pin_sha256 = `openssl dgst -sha256 -binary $temp_der_pub_path | openssl enc -base64`;
		chomp $rfc_7469_pin_sha256;
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "t/keys/$path.pub produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_der_pub_path or die "Failed to unlink $temp_der_pub_path";
	}
}

sub test_rsa_key {
	my ($path) = @_;
	SKIP: {
		my $temp_der_pub_path = 't/test_der.pub';
		my $temp_pem_pub_path = 't/test_pem.pub';
		my $dev_null = File::Spec->devnull();
		my $version = `openssl rsa -in t/keys/$path -pubout 2>$dev_null >$temp_pem_pub_path`;
		if ($? != 0) {
			unlink $temp_pem_pub_path;
			diag(`openssl rsa -in t/keys/$path -pubout 2>&1`);
			skip("openssl is not available or does not support the key in t/keys/$path", 2);
		}
		unlink $temp_pem_pub_path;
		my $test_pin_sha256 = pin_sha256("t/keys/$path");
		`openssl rsa -in t/keys/$path -pubout 2>$dev_null | openssl asn1parse -noout -inform pem -out $temp_der_pub_path`;
		my $rfc_7469_pin_sha256 = `openssl dgst -sha256 -binary $temp_der_pub_path | openssl enc -base64`;
		chomp $rfc_7469_pin_sha256;
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "t/keys/$path produced the correct HPKP pin:$rfc_7469_pin_sha256");
		unlink $temp_der_pub_path or die "Failed to unlink $temp_der_pub_path";
		my $temp_der_path = 't/test_der.key';
		`openssl rsa -inform pem -in t/keys/$path -outform DER -out $temp_der_path 2>$dev_null`;
		$test_pin_sha256 = pin_sha256("$temp_der_path");
		ok($test_pin_sha256 eq $rfc_7469_pin_sha256, "$temp_der_path produced the correct HPKP pin:$rfc_7469_pin_sha256");
	}
}

