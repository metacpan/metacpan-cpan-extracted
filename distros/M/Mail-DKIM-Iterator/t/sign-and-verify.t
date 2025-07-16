use strict;
use warnings;
use Test::More;
use Mail::DKIM::Iterator;

plan tests => 24;

# basic tests with different canonicalizations and algorithms
for my $c (qw(
    simple/simple
    simple/relaxed
    relaxed/relaxed
    relaxed/simple
    relaxed
    simple
)) {
    for my $algo (qw(rsa-sha1 rsa-sha256)) {
	#diag("c=$c a=$algo");
	my $ok = do {
	    my $m = sign([ mail() ], c => $c, a => $algo );
	    verify([$m],dns());
	};
	my $err = $@ || ($ok ? '':'unknown error');
	is( $err,'', "c=$c a=$algo");
    }
}

# verification should succeed with warning if not all critical
# headers are properly covered
{
    my $ok = eval {
	my $m = sign([mail()], h => 'from:from:to:subject', h_auto => 0);
	verify(["Subject: foo\n".$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is($err,"valid warning=unprotected critical header subject\n",
	"unsigned header fields");
}

# verification should succeed with warning if non-space data after body
# signature (when 'l' is used)
{
    my $ok = eval {
	my $m = sign([mail()],
	    h => 'from:from:to:subject',
	    h_auto => 0,
	    l => 0,
	);
	$m = "Subject: foo\n".$m."foo\n";
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is($err,
	"valid warning=unprotected critical header subject + data after signed body\n",
	"data after signed body");
}

# expect verification permerror because of wrong pubkey
{
    my $ok = eval {
	my $m = sign([mail()], s => 'bad');
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=fail error=header sig mismatch\n",
	"wrong pubkey");
}

# expect verification soft-fail because signature is expired
{
    my $ok = eval {
	my $m = sign([mail()], x => time()-20 );
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=policy error=signature e[x]pired\n",
	"signature expired");
}

# expect verification temp-fail because DNS lookup failed
{
    my $ok = eval {
	my $m = sign([mail()], s => 'no-dns' );
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=temperror error=dns lookup failed\n",
	"DNS lookup failed");
}

# expect verification permerror because DKIM key has invalid syntax
{
    my $ok = eval {
	my $m = sign([mail()], s => 'invalid' );
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=permerror error=invalid or empty DKIM record\n",
	"DKIM key invalid syntax");
}

# expect verification permerror because DKIM key has invalid syntax
{
    my $ok = eval {
	my $m = sign([mail()], v => '2' );
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=permerror error=invalid DKIM-Signature header: bad DKIM signature version: 2 a=rsa-sha256\n",
	"DKIM signature invalid syntax");
}

# expect verification permerror because of broken signature
{
    my $ok = eval {
	my $m = sign([mail()], 'b' => 'foobar' );
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=permerror error=header sig corrupt\n",
	"DKIM signature corrupt b");
}

# expect verification fail because of broken hash
{
    my $ok = eval {
	my $m = sign([mail()], 'bh' => 'foobar' );
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=fail error=body hash mismatch\n",
	"DKIM signature corrupt bh");
}

# expect verification permerror because of broken pubkey in DNS
{
    my $ok = eval {
	my $m = sign([mail()], 's' => 'badkey' );
	verify([$m],dns());
    };
    my $err = $@ || ($ok ? '':'unknown error');
    is( $err,"status status=permerror error=using public key failed\n",
	"DKIM signature corrupt pubkey");
}

like(
    sign([empty_mail()], c => 'relaxed/relaxed', a => 'rsa-sha256'),
    qr{\Qbh=47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=;},
    "bh empty body relaxed/relaxed"
);

like(
    sign([empty_mail()], c => 'simple/simple', a => 'rsa-sha256'),
    qr{\Qbh=frcCV1k9oG9oKj3dpUqdJg1PxRT2RSN/XKdLCPjaYaY=;},
    "bh empty body simple/simple"
);


############################################################################
# functions
############################################################################

# create signature
sub sign {
    my ($mail,%args) = @_;
    push @$mail,'';
    my $v = delete $args{v};
    my $b = delete $args{b};
    my $bh = delete $args{bh};
    my $dkim = Mail::DKIM::Iterator->new( sign => {
	d => 'example.com',
	s => 'good',
	':key' => priv_key_pem(),
	%args,
    });

    my $rv;
    my @todo = \'';
    my $total_mail;
    while (@todo) {
	my $todo = shift(@todo);
	if (ref($todo)) {
	    die "no more data after end of mail" if !@$mail;
	    $total_mail .= $mail->[0];
	    ($rv,@todo) = $dkim->next(shift(@$mail));
	} else {
	    die "there should no no DNS lookups needed for signing\n";
	}
    }
    @todo && die "still things to do at end of mail\n";
    $rv || die "no result after end of mail\n";

    @$rv == 1 or die "expected a single result, got ".int(@$rv)."\n";
    $rv->[0]->status == DKIM_PASS
	or die "unexpected status ".( $rv->[0]->status // '<undef>' )."\n";
    my $dkim_sig = $rv->[0]->signature;
    $dkim_sig =~s{\bv=1;}{v=$v} if defined $v;
    $dkim_sig =~s{\bb=(?:[^;]+)(\z|;)}{b=$b$1} if defined $b;
    $dkim_sig =~s{\bbh=(?:[^;]+)(\z|;)}{bh=$bh$1} if defined $bh;
    #warn "XXXXX $dkim_sig\n";
    return $dkim_sig . $total_mail;
}

# validate signature
sub verify {
    my ($mail,$dns) = @_;
    push @$mail,'';
    my $dkim = Mail::DKIM::Iterator->new;

    my $rv;
    my @todo = \'';
    while (@todo) {
	my $todo = shift(@todo);
	if (ref($todo)) {
	    die "no more data after end of mail" if !@$mail;
	    ($rv,@todo) = $dkim->next(shift(@$mail));
	} else {
	    ($rv,@todo) = $dkim->next({ $todo => $dns->{$todo} });
	}
    }

    @todo && die "still things to do at end of mail\n";
    $rv || die "no result after end of mail\n";
    @$rv == 1 or die "expected a single result, got ".int(@$rv)."\n";
    $rv->[0]->status == DKIM_PASS or die
	"status status=" . ($rv->[0]->status//'<undef>')
	. " error=" . ($rv->[0]->error//'') . "\n";
    $rv->[0]->warning eq ''
	or die "valid warning=".$rv->[0]->warning."\n";
    1;
}



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

sub dns {{ 
    'good._domainkey.example.com' => <<'DKIM_KEY',
v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDOD/2mm2FfRCkBhtQkE3Wl2M3A9E8PJiSkvciLrSoTePnHC0MSLaNXYUmFHT//zT4ZebruQDgPVsLRLVmWssVaKn9EpKQcd55qVKApFNZSoev5sdzXP9g+AuZYtnkSHzlilqiSttHkadXSAyJ8WOlMC0kTPWEkL+FyWDyezKuj9QIDAQAB
DKIM_KEY
    'bad._domainkey.example.com' => <<'DKIM_KEY',
v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDwIRP/UC3SBsEmGqZ9ZJW3/DkMoGeLnQg1fWn7/zYtIxN2SnFCjxOCKG9v3b4jYfcTNh5ijSsq631uBItLa7od+v/RtdC2UzJ1lWT947qR+Rcac2gbto/NMqJ0fzfVjH4OuKhitdY9tf6mcwGjaNBcWToIMmPSPDdQPNUYckcQ2QIDAQAB
DKIM_KEY
    'badkey._domainkey.example.com' => <<'DKIM_KEY',
v=DKIM1; p=foobar
DKIM_KEY
    'no-dns._domainkey.example.com' => undef,
    'invalid._domainkey.example.com' => "And now for something completely different",
}}


# Mail contains empty lines, multiple white-space.. so that simple and
# relaxed canonicalizations are different
sub mail { <<'MAIL'; }
From: me
To:  you
To:you-too
Subject: whatever
Message-Id: <foo@bar.com>
In-Reply-To:
References:

1234
MAIL

sub empty_mail {
    return mail() =~m{\A(.*(?:\r?\n){2})}s && $1;
}
