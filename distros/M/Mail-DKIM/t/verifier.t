#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::More tests => 105;

use Mail::DKIM::Verifier;

my $homedir = (-d "t") ? "t" : ".";

my $dkim = Mail::DKIM::Verifier->new();
ok($dkim, "new() works");

$dkim = Mail::DKIM::Verifier->new_object();
ok($dkim, "new_object() works");

my $sample_email = read_file("$homedir/test5.txt");
ok($sample_email, "able to read sample email");
ok($sample_email =~ /\015\012/, "sample has proper line endings");

$dkim->PRINT($sample_email);
$dkim->CLOSE;

my $result = $dkim->result;
ok($result, "result() works");

SKIP: 
{
	skip "older-prestandard DKIM signatures", 5;
	test_email("good_ietf00_1.txt", "pass");
	test_email("good_ietf00_2.txt", "pass");
	test_email("good_ietf00_3.txt", "pass");
	test_email("good_ietf00_4.txt", "pass");
	test_email("good_ietf00_5.txt", "pass");
}

test_email("mine_ietf01_1.txt", "pass");
test_email("mine_ietf01_2.txt", "pass");
test_email("mine_ietf01_3.txt", "pass");
test_email("mine_ietf01_4.txt", "pass");
test_email("mine_ietf05_1.txt", "pass");
test_email("good_ietf01_1.txt", "pass");
test_email("good_ietf01_2.txt", "pass");
test_email("good_rfc4871_3.txt", "pass");  # tests extra tags in signature
test_email("good_rfc4871_4.txt", "pass");  # case-differing domain name
test_email("good_1878523.txt", "pass");    # test issue #1878523
test_email("good_83176.txt", "pass");      # test issue #83176
test_email("multiple_1.txt", "pass");
test_email("multiple_2.txt", "pass");
my @sigs = $dkim->signatures;
ok($sigs[0]->result eq "invalid", "first signature is 'invalid'");
ok($sigs[1]->result eq "pass", "second signature is 'pass'");
ok($sigs[2]->result eq "fail", "third signature is 'fail'");
test_email("good_qp_1.txt", "pass");   # tests i= quoted-printable value
test_email("good_qp_2.txt", "pass");   # tests i= quoted-printable value
test_email("good_qp_3.txt", "pass");   # tests i= quoted-printable value

test_email("bad_ietf01_1.txt", "fail");
ok($dkim->result_detail =~ /body/, "determined body had been altered");
test_email("bad_ietf01_2.txt", "fail");
ok($dkim->result_detail =~ /message/, "determined message had been altered");
test_email("bad_ietf01_3.txt", "fail");
ok($dkim->result_detail =~ /RSA/, "determined RSA failure");
test_email("bad_1.txt", "fail"); #openssl error
print "# " . $dkim->result_detail . "\n";
SKIP:
{
	skip "did not recognize OpenSSL error", 1
		unless ($dkim->result_detail =~ /OpenSSL/i);
	like($dkim->result_detail,
		qr/OpenSSL/i,
		"determined OpenSSL error");
}
test_email("bad_1878954.txt", "fail");  # shouldn't die

# test older DomainKeys messages, from Gmail and Yahoo!
test_email("good_dk_gmail.txt", "pass");
test_email("good_dk_yahoo.txt", "pass");
test_email("good_dk_1.txt", "pass");
test_email("good_dk_2.txt", "pass");
test_email("good_dk_3.txt", "pass"); # key with g= tag (ident in From header)
test_email("good_dk_4.txt", "pass"); # key with g= tag (ident in Sender head)
test_email("good_dk_5.txt", "pass"); # key with empty g=
test_email("good_dk_6.txt", "pass"); # no h= tag
test_email("good_dk_7.txt", "pass"); # case-differing domain names
test_email("dk_headers_1.txt", "pass");
test_email("dk_headers_2.txt", "pass");
test_email("bad_dk_1.txt", "invalid"); # sig. domain != From header (no Sender)
test_email("bad_dk_2.txt", "invalid"); # added Sender header, no h= tag
SKIP: 
{
	skip "missing q= tag on DomainKey signature accepted", 1;
	test_email("bad_dk_3.txt", "invalid"); # no q= tag
}
test_email("bad_dk_4.txt", "invalid"); # empty q= tag
test_email("bad_dk_5.txt", "invalid"); # unrecognized q= tag
test_email("dk_multiple_1.txt", "pass");
my @dksigs = $dkim->signatures;
ok(@dksigs == 2, "found two signatures");
ok($dksigs[0]->result eq "pass", "first signature is 'pass'");
ok($dksigs[1]->result eq "pass", "second signature is 'pass'");

# test empty/missing body - simple canonicalization
test_email("no_body_1.txt", "pass");
test_email("no_body_2.txt", "pass");
test_email("no_body_3.txt", "pass");

#
# test various problems with the signature itself
#
test_email("ignore_1.txt", "invalid"); # unsupported v= tag (v=5)
test_email("ignore_2.txt", "invalid"); # unsupported a= tag (a=rsa-md5)
test_email("ignore_3.txt", "invalid"); # unsupported a= tag (a=dsa-sha1)
test_email("ignore_4.txt", "invalid"); # unsupported c= tag (c=future)
test_email("ignore_5.txt", "invalid"); # unsupported q= tag (q=http)
test_email("ignore_6.txt", "invalid"); # unsupported q= tag (q=dns/special)
test_email("ignore_7.txt", "invalid"); # expired signature
test_email("ignore_8.txt", "invalid"); # bad i= value

#
# test variants on the public key
#
test_email("goodkey_1.txt", "pass"); # public key with s=email
test_email("goodkey_2.txt", "pass"); # public key with extra tags, h=, s=, etc.
test_email("goodkey_3.txt", "pass"); # public key with g=jl*g
test_email("goodkey_4.txt", "pass"); # public key with implied g

#
# test problems with the public key
#
test_email("badkey_1.txt", "invalid"); # public key NXDOMAIN
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_2.txt", "invalid"); # public key REVOKED
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_3.txt", "invalid"); # public key unsupported v= tag
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_4.txt", "invalid"); # public key syntax error
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_5.txt", "invalid"); # public key unsupported k= tag
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_6.txt", "invalid"); # public key unsupported s= tag
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_7.txt", "invalid"); # public key unsupported h= tag
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_8.txt", "invalid"); # public key unmatched g= tag
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_9.txt", "invalid"); # public key empty g= tag
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_10.txt", "invalid"); # public key requires i == d
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_11.txt", "invalid"); # public key unmatched h= tag
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_12.txt", "invalid"); # public key g= != i= by case
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_13.txt", "invalid"); # public key g= matches From but not i=
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
test_email("badkey_14.txt", "invalid"); # dns error (timeout)
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
ok($dkim->result_detail =~ /dns.*timed? ?out/i, "type of dns failure");
test_email("badkey_15.txt", "invalid"); # dns error (SERVFAIL)
ok($dkim->result_detail =~ /public key/, "detail mentions public key");
ok($dkim->result_detail =~ /dns.*SERVFAIL/i, "type of dns failure");


sub read_file
{
	my $srcfile = shift;
	open my $fh, "<", $srcfile
		or die "Error: can't open $srcfile: $!\n";
	binmode $fh;
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

sub test_email
{
	my ($file, $expected_result) = @_;
	print "# verifying message '$file'\n";
	$dkim = Mail::DKIM::Verifier->new();
	my $path = "$homedir/corpus/$file";
	my $email = read_file($path);
	$dkim->PRINT($email);
	$dkim->CLOSE;
	my $result = $dkim->result;
	print "#   result: " . $dkim->result_detail . "\n";
	ok($result eq $expected_result, "'$file' should '$expected_result'");
}

# override the DNS implementation, so that these tests do not
# rely on DNS servers I have no control over
my $CACHE;
sub Mail::DKIM::DNS::fake_query
{
	my ($domain, $type) = @_;
	die "can't lookup $type record" if $type ne "TXT";

	unless ($CACHE)
	{
		open my $fh, "<", "$homedir/FAKE_DNS.dat"
			or die "Error: cannot read $homedir/FAKE_DNS.dat: $!\n";
		$CACHE = {};
		while (<$fh>)
		{
			chomp;
			next if /^\s*[#;]/ || /^\s*$/;
			my ($k, $v) = split /\s+/, $_, 2;
			$CACHE->{$k} = ($v =~ /^~~(.*)~~$/) ? "$1" :
				$v eq "NXDOMAIN" ? [] :
				[ bless \$v, "FakeDNS::Record" ];
		}
		close $fh;
	}

	if (not exists $CACHE->{$domain})
	{
		warn "did not cache that DNS entry: $domain\n";
		print STDERR ">>>\n";
		my @result = Mail::DKIM::DNS::orig_query($domain, $type);
		if (!@result) {
			print STDERR "No results: $@\n";
		} else {
			foreach my $rr (@result) {
				# join with no intervening spaces, RFC 6376
				if (Net::DNS->VERSION >= 0.69) {
					# must call txtdata() in a list context
					printf STDERR ("%s\n",
						join("", $rr->txtdata));
				} else {
					# char_str_list method is 'historical'
					printf STDERR ("%s\n",
						join("", $rr->char_str_list));
				}
			}
		}
		print STDERR "<<<\n";
		die;
	}

	if (ref $CACHE->{$domain})
	{
		return @{$CACHE->{$domain}};
	}
	else
	{
		die "DNS error: $CACHE->{$domain}\n";
	}
}

BEGIN {
	unless ($ENV{use_real_dns})
	{
	*Mail::DKIM::DNS::orig_query = *Mail::DKIM::DNS::query;
	*Mail::DKIM::DNS::query = *Mail::DKIM::DNS::fake_query;
	}
}

package FakeDNS::Record;

sub type
{
	return "TXT";
}

sub char_str_list
{
	return ${$_[0]};
}

sub txtdata
{
	return ${$_[0]};
}
