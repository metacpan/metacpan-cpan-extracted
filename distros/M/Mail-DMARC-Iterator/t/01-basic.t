use strict;
use warnings;
use Test::More;
use Mail::DMARC::Iterator;
use Mail::DKIM::Iterator;
use Data::Dumper;
#$Mail::DMARC::Iterator::DEBUG = 1;

plan tests => 27;

{
    diag("single DKIM signature - order DKIM+EOF");
    my $mail = sign(mail());
    my $dmarc = Mail::DMARC::Iterator->new(
	ip => '1.1.1.1',
	mailfrom => 'me@example.com',
	helo => 'mx.example.com'
    );

    # feed DKIM-Signature into iterator
    my ($dksig,$rest) = $mail =~m{\A
	(DKIM-Signature:.*(?:\n[ \t].*)*\n)
	((?s).*)
    }x or die "split mail";
    my @t = $dmarc->next($dksig);
    check_result(\@t,[
	undef,
	'D'
    ]);

    # feed rest of mail into iterator
    @t = $dmarc->next($rest);
    check_result(\@t,[
	undef,
	'TXT:_dmarc.example.com'
    ]);

    # feed DMARC DNS record into iterator
    @t = $dmarc->next(dnslookup($t[1]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:s1._domainkey.example.com',
	'TXT:example.com'
    ]);

    # feed DKIM DNS record into iterator
    @t = $dmarc->next(dnslookup($t[2]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:example.com'
    ]);

    # feed EOF into iterator
    @t = $dmarc->next('');
    check_result(\@t, [
	'pass',
	'DKIM',
	''
    ]);
}
{
    diag("single DKIM signature - order SPF(Fail)+DKIM+EOF");
    my $mail = sign(mail());
    my $dmarc = Mail::DMARC::Iterator->new(
	ip => '1.1.1.1',
	mailfrom => 'me@example.com',
	helo => 'mx.example.com'
    );

    # feed mail into iterator
    my @t = $dmarc->next($mail);
    check_result(\@t,[
	undef,
	'TXT:_dmarc.example.com'
    ]);

    # feed DMARC DNS record into iterator
    @t = $dmarc->next(dnslookup($t[1]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:s1._domainkey.example.com',
	'TXT:example.com'
    ]);

    # feed SPF DNS record into iterator
    @t = $dmarc->next(dnslookup($t[3]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:s1._domainkey.example.com',
    ]);

    # feed DKIM DNS record into iterator
    @t = $dmarc->next(dnslookup($t[2]));
    check_result(\@t, [
	undef,
	'D',
    ]);

    # feed EOF into iterator
    @t = $dmarc->next('');
    check_result(\@t, [
	'pass',
	'DKIM',
	''
    ]);
}
{
    diag("single DKIM signature - order SPF(Pass)");
    my $mail = sign(mail());
    my $dmarc = Mail::DMARC::Iterator->new(
	ip => '1.2.3.4',
	mailfrom => 'me@example.com',
	helo => 'mx.example.com'
    );

    # feed mail into iterator
    my @t = $dmarc->next($mail);
    check_result(\@t,[
	undef,
	'TXT:_dmarc.example.com'
    ]);

    # feed DMARC DNS record into iterator
    @t = $dmarc->next(dnslookup($t[1]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:s1._domainkey.example.com',
	'TXT:example.com'
    ]);

    # feed SPF DNS record into iterator
    @t = $dmarc->next(dnslookup($t[3]));
    check_result(\@t, [
	'pass',
	'SPF',
	''
    ]);
}
{
    diag("single DKIM signature - order SPF(Pass,not align)+DKIM+EOF");
    my $mail = sign(mail());
    my $dmarc = Mail::DMARC::Iterator->new(
	ip => '1.2.3.4',
	mailfrom => 'me@example.org',
	helo => 'mx.example.org'
    );

    # feed mail into iterator
    my @t = $dmarc->next($mail);
    check_result(\@t,[
	undef,
	'TXT:_dmarc.example.com'
    ]);

    # feed DMARC DNS record into iterator
    @t = $dmarc->next(dnslookup($t[1]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:s1._domainkey.example.com',
	'TXT:example.org'
    ]);

    # feed SPF DNS record into iterator
    @t = $dmarc->next(dnslookup($t[3]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:s1._domainkey.example.com',
    ]);

    # feed DKIM DNS record into iterator
    @t = $dmarc->next(dnslookup($t[2]));
    check_result(\@t, [
	undef,
	'D',
    ]);

    # feed EOF into iterator
    @t = $dmarc->next('');
    check_result(\@t, [
	'pass',
	'DKIM',
	''
    ]);
}
{
    diag("double DKIM signature");
    my $mail = sign(sign(mail()), d => 'example.org');
    my $dmarc = Mail::DMARC::Iterator->new();

    # feed mail into iterator
    my @t = $dmarc->next($mail);
    check_result(\@t,[
	undef,
	'TXT:_dmarc.example.com'
    ]);

    # feed DMARC DNS record into iterator
    @t = $dmarc->next(dnslookup($t[1]));
    check_result(\@t, [
	undef,
	'D',
	'TXT:s1._domainkey.example.com',
    ]);

    # feed DKIM DNS record into iterator
    @t = $dmarc->next(dnslookup($t[2]));
    check_result(\@t, [
	undef,
	'D',
    ]);

    # feed EOF into iterator
    @t = $dmarc->next('');
    check_result(\@t, [
	'pass',
	'DKIM',
	''
    ]);
}
{
    diag("external DKIM iterator - order DKIM + DMARC");
    my $mail = sign(sign(mail()), d => 'example.org');
    my @dkim_result;
    my $dkim = Mail::DKIM::Iterator->new;
    my $dmarc = Mail::DMARC::Iterator->new(
	dkim_sub => sub { $dkim_result[0] }
    );

    # feed mail into DKIM iterator
    @dkim_result = $dkim->next($mail);
    for(@dkim_result[1..$#dkim_result]) {
	ref($_) and next;
	$dkim->next({ $_ => dns()->{"TXT:$_"} });
    }
    @dkim_result = $dkim->next('');
    #warn Dumper(\@dkim_result);

    # feed mail into iterator
    my @t = $dmarc->next($mail);
    check_result(\@t,[
	undef,
	'TXT:_dmarc.example.com'
    ]);

    # feed DMARC DNS record into iterator
    @t = $dmarc->next(dnslookup($t[1]));
    check_result(\@t, [
	'pass',
	'DKIM',
	''
    ]);
}
{
    diag("external DKIM iterator - order DMARC + DKIM");
    my $mail = sign(sign(mail()), d => 'example.org');
    my @dkim_result;
    my $dkim = Mail::DKIM::Iterator->new;
    my $dmarc = Mail::DMARC::Iterator->new(
	dkim_sub => sub { $dkim_result[0] }
    );


    # feed mail into iterator
    my @t = $dmarc->next($mail);
    check_result(\@t,[
	undef,
	'TXT:_dmarc.example.com'
    ]);

    # feed DMARC DNS record into iterator
    @t = $dmarc->next(dnslookup($t[1]));
    check_result(\@t,[
	undef,
    ]);

    # feed mail into DKIM iterator
    @dkim_result = $dkim->next($mail);
    for(@dkim_result[1..$#dkim_result]) {
	ref($_) and next;
	$dkim->next({ $_ => dns()->{"TXT:$_"} });
    }
    @dkim_result = $dkim->next('');
    #warn Dumper(\@dkim_result);

    @t = $dmarc->next();
    check_result(\@t, [
	'pass',
	'DKIM',
	''
    ]);
}


sub sign {
    my ($mail,%args) = @_;
    my $dkim = Mail::DKIM::Iterator->new(sign => {
	d => 'example.com',
	s => 's1',
	':key' => priv_key_pem(),
	%args
    });
    $dkim->next($mail);
    my ($rv) = $dkim->next('');
    die "failed to create signature"
	if ! $rv or $rv->[0]->status != DKIM_SUCCESS;
    return $rv->[0]->signature . $mail;
}

sub check_result {
    my ($result,$expect,$msg) = @_;
    $msg ||= 'check result and todos';
    for my $s ($result,$expect) {
	my @ns;
	for (@$s) {
	    if (ref($_)) {
		my $q = ($_->question)[0];
		push @ns, $q->qtype.':'.$q->qname;
	    } elsif (!defined $_) {
		push @ns, '<undef>';
	    } elsif ($_ eq '') {
		push @ns, '<empty>'
	    } else {
		push @ns, $_
	    }
	}
	$s = \@ns;
    }
    if (@$result != @$expect) {
	diag(Dumper([$result,$expect]));
	fail(sprintf(
	    "%s (number of expectations(%s) != number of todos(%d)",
	    $msg, ~~@$expect, ~~@$result));
	return;
    }
    for(my $i=0;$i<@$expect;$i++) {
	my $t = $result->[$i];
	my $x = $expect->[$i];
	if ($x ne $t) {
	    diag(Dumper([$result,$expect]));
	    fail("$msg " .
		($i ? "todo[$i]":"result") .
		" expect '$x' got '$t'");
	    return
	}
    }
    pass("$msg: ".join(" + ",@$expect));
}

sub dnslookup {
    my $request = shift;
    my $q = ($request->question)[0];
    my $qtype = $q->qtype;
    my $qname = $q->qname;

    my $reply = Net::DNS::Packet->new($qname,$q->qclass,$qtype);
    $reply->header->qr(1);
    $reply->header->ra(1);
    $reply->header->rd($request->header->rd);
    $reply->header->id($request->header->id);

    my $resp = dns()->{"$qtype:$qname"};
    if (!$resp) {
	$reply->header->rcode('NXDOMAIN');
	return $reply;
    }

    $qtype eq 'TXT' or die "only TXT supported";
    $reply->push('answer',
	Net::DNS::RR->new("$qname. 10 TXT \"$resp\""));
    $reply->header->rcode('NOERROR');
    return $reply;
}

sub dns {{
    'TXT:_dmarc.example.com' => "v=DMARC1; p=none; sp=none;",
    'TXT:s1._domainkey.example.com' => <<'DKIM_KEY',
v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDOD/2mm2FfRCkBhtQkE3Wl2M3A9E8PJiSkvciLrSoTePnHC0MSLaNXYUmFHT//zT4ZebruQDgPVsLRLVmWssVaKn9EpKQcd55qVKApFNZSoev5sdzXP9g+AuZYtnkSHzlilqiSttHkadXSAyJ8WOlMC0kTPWEkL+FyWDyezKuj9QIDAQAB
DKIM_KEY
    'TXT:example.com' => "v=spf1 ip4:1.2.3.4 -all",
    'TXT:example.org' => "v=spf1 ip4:1.2.3.4 -all",
}}

sub mail { <<'MAIL' }
From: me@example.com
To: you@example.com
Subject: foo

bar
MAIL


sub priv_key_pem { <<'KEY'; }
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDOD/2mm2FfRCkBhtQkE3Wl2M3A9E8PJiSkvciLrSoTePnHC0MS
LaNXYUmFHT//zT4ZebruQDgPVsLRLVmWssVaKn9EpKQcd55qVKApFNZSoev5sdzX
P9g+AuZYtnkSHzlilqiSttHkadXSAyJ8WOlMC0kTPWEkL+FyWDyezKuj9QIDAQAB
AoGAdU+JOhZvYsrtBV962mbxrU82I8lyUM+IQPmCeHJG5/sRSA3TS0AMI6zRLCUw
0DJKTjqM/yI0SBc+pdNJk4+G5f4g6fSXIJ4ZgBOcODtfvJd/lV6wFnPkvXkwqlTg
/hdy9b0dgxNuZoroGFRmPfoyRGKJ5Ki+YljD1LsIptGwLQECQQDzjQZe9vDp+/gW
bFRdK7yLtWbStS3JQaxYbgPWKOSX8rPQecR2eRKSQlLCn6Ivwg+Dsb1ZUm6rj6x1
zraf7G7hAkEA2JhprlVSYWsu3qzzMt7UVsOqjjUdw75eoYyaftSjUouv1I5JvKb4
uUWOdBrtJnK8UzyM8U58RVuTFxoWtOl7lQJBAMkIj0mz7Ag3xAA+SyTdBTUM92LV
yoVlgC0+IkyUVJxX6bUbzd888Odpd4bO3cEuHkBGZlVkhZV3cpOLnZNERgECQEmY
+IgJa/W4UvPNNtI5T1OwJvstZ1DFFii0uyaPoHODDZsfQkT9Q5TI4s/m+mBPKljq
QUYZkjaLGF8IOWD92UUCQQDcOgnxIpRuaIfxOEy4YVIErZC4aYqFKffn2KCHIok2
mLCwzP6+EOAZvHS1y2LkY/XSRSuZCRLDb5K3Jw8fIaEF
-----END RSA PRIVATE KEY-----
KEY
