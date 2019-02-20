package Mail::DKIM::Iterator;
use v5.10.0;

our $VERSION = '1.004';

use strict;
use warnings;
use Crypt::OpenSSL::RSA;
use Scalar::Util 'dualvar';

# critical header fields which should be well protected
my @critical_headers = qw(from subject content-type content-transfer-encoding);
my $critical_headers_rx = do {
    my $rx = join("|",@critical_headers);
    qr{$rx}i;
};
# all header fields which should be included in the signature
my @sign_headers = (@critical_headers, 'to', 'cc', 'date');

use Exporter 'import';
our @EXPORT = qw(
    DKIM_POLICY
    DKIM_PERMERROR
    DKIM_NEUTRAL
    DKIM_TEMPERROR
    DKIM_FAIL
    DKIM_PASS
);

use constant {
    DKIM_POLICY      => dualvar(-4,'policy'),
    DKIM_PERMERROR   => dualvar(-3,'permerror'),
    DKIM_NEUTRAL     => dualvar(-2,'neutral'),
    DKIM_TEMPERROR   => dualvar(-1,'temperror'),
    DKIM_FAIL        => dualvar( 0,'fail'),
    DKIM_PASS        => dualvar( 1,'pass'),
};

# compability to versions 1.003 and lower
push @EXPORT, qw(
    DKIM_INVALID_HDR
    DKIM_TEMPFAIL
    DKIM_SOFTFAIL
    DKIM_PERMFAIL
    DKIM_SUCCESS
);

use constant {
    DKIM_INVALID_HDR => DKIM_PERMERROR,
    DKIM_TEMPFAIL    => DKIM_TEMPERROR,
    DKIM_SOFTFAIL    => DKIM_NEUTRAL,
    DKIM_PERMFAIL    => DKIM_FAIL,
    DKIM_SUCCESS     => DKIM_PASS,
};


# create new object
sub new {
    my ($class,%args) = @_;
    my $self = bless {
	records => $args{dns} || {}, # mapping (dnsname,dkim_key)
	extract_sig => 1,            # extract signatures from mail header
	filter => $args{filter},     # filter which signatures are relevant
	# sig => [...],              # list of signatures from header or to sign
	_hdrbuf => '',               # used while collecting the mail header
    }, $class;

    if (my $sig = delete $args{sign}) {
	# signatures given for signing, either as [{},...] or {}
	# add to self.sig
	$sig = [$sig] if ref($sig) ne 'ARRAY';
	$self->{extract_sig} = delete $args{sign_and_verify};
	my $error;
	for(@$sig) {
	    $_->{h} //= 'from' if ref($_); # minimal
	    my $s = parse_signature($_,\$error,1);
	    die "bad signature '$_': $error" if !$s;
	    $s->{h_auto} //= 1; # secure version will be detected based on mail
	    push @{$self->{sig}}, $s
	}
    }
    return $self;
}

# Iterator: feed object with information and get back what to do next
sub next {
    my $self = shift;
    my $rv;
    while (@_) {
	my $arg = shift;
	if (ref($arg)) {
	    # ref: mapping (host,dkim_key)
	    while (my ($k,$v) = each %$arg) {
		$self->{records}{$k} = $v;
	    }
	    $rv = _compute_result($self);
	} else {
	    # string: append data from mail
	    if (defined $self->{_hdrbuf}) {
		# header not fully read: append and try to find end of header
		$self->{_hdrbuf} .= $arg;
		$self->{_hdrbuf} =~m{(\r?\n)\1}g or last; # no end of header

		# Extract header into self.header and look for DKIM signatures
		# inside. The rest of _hdrbuf will be appended as part of the
		# body and the attribute _hdrbuf itself is no longer needed
		$self->{header} = substr($self->{_hdrbuf},0,$+[0],'');
		if ($self->{extract_sig}
		    and my @sig = _parse_header($self->{header})) {
		    if (my $f = $self->{filter}) {
			@sig = grep { $f->($_,$self->{header}) } @sig;
		    }
		    push @{$self->{sig} ||= []}, @sig if @sig;
		}
		$arg = delete $self->{_hdrbuf};
		_append_body($self,$arg) if $arg ne '';

	    } else {
		# header already read: append as part of body
		_append_body($self,$arg);
	    }

	    if (!$self->{sig}) {
		# No signatures found in body -> empty return list
		$rv = [];
	    } else {
		$rv = _compute_result($self);
	    }
	}
    }
    $rv = _compute_result($self) if ! @_;

    # If we have no results yet just return that we need more data
    $rv or return ([],\'');

    # Extract the DNS names for the partial results where the DKIM key is needed
    # and return the as todo. If the body hash could not yet computed for a
    # signature mark also that we need more data
    my (%need_dns,$need_more_data);
    for(@$rv) {
	$_->status and next;
	my $sig = $_->sig;

	# Need more data to compute the body hash?
	$need_more_data = 1 if !$sig->{'bh:computed'};

	# Need to get DKIM key to validate signature?
	# Only if we have sig.b, i.e. an extracted signature from the header.
	if ($sig->{b}) {
	    my $name = $_->dnsname;
	    $need_dns{$name}++ if ! $self->{records}{$name};
	}
    }

    # return preliminary results and @todo
    return ($rv,$need_more_data ? (\''):(),sort keys %need_dns);
}

sub filter {
    my ($self,$filter) = @_;
    $self->{filter} = $filter;
    @{$self->{sig}} = grep { $filter->($_,$self->{header}) } @{$self->{sig}}
	if $self->{header} && $self->{sig};
}

sub result {
    my $self = shift;
    return $self->{_last_result};
}

sub authentication_results {
    return join(";\n",map {
	my $ar = $_->authentication_results;
	$ar ? (' '.$ar) : (),
    } @{shift->result || []});
}

# Compute result based on current data.
# This might add more DKIM records to validate signatures.
sub _compute_result {
    my $self = shift;
    return if defined $self->{_hdrbuf}; # need more header
    return [] if !$self->{sig};         # nothing to verify

    my @rv;
    for my $sig (@{$self->{sig}}) {

	# use final result if we have one already
	if ($sig->{':result'}) {
	    push @rv, $sig->{':result'};
	    next;
	}

	if (!$sig->{b}) {
	    # sig is not for verification but for signing
	    if (!$sig->{'bh:computed'}) {
		# incomplete: still need more data to compute signature
		push @rv, Mail::DKIM::Iterator::SignRecord->new($sig);
	    } else {
		# complete: compute signature and save it in :result
		my $err;
		my $dkim_sig = sign($sig,$sig->{':key'},$self->{header},\$err);
		push @rv, $sig->{':result'} =
		    Mail::DKIM::Iterator::SignRecord->new(
			$dkim_sig ? ($sig,$dkim_sig,DKIM_PASS)
			    : ($sig,undef,DKIM_FAIL,$err)
		    );
	    }
	    next;
	}

	if ($sig->{error}) {
	    # something wrong with the DKIM-Signature header, return error
	    push @rv, $sig->{':result'} =
		Mail::DKIM::Iterator::VerifyRecord->new(
		    $sig,
		    ($sig->{s}//'UNKNOWN')."_domainkey".($sig->{d}//'UNKNOWN'),
		    DKIM_PERMERROR,
		    $sig->{error}
		);
	    next;
	}

	my $dns = "$sig->{s}._domainkey.$sig->{d}";

	if ($sig->{x} && $sig->{x} < time()) {
	    push @rv, $sig->{':result'} = Mail::DKIM::Iterator::VerifyRecord
		->new($sig,$dns, DKIM_POLICY, "signature e[x]pired");
	    next;
	}

	if (my $txt = $self->{records}{$dns}) {
	    if (!ref($txt) || ref($txt) eq 'ARRAY') {
		# Take the first syntactically valid DKIM key from the list of
		# TXT records.
		my $error = "no TXT records";
		for(ref($txt) ? @$txt:$txt) {
		    if (my $r = parse_dkimkey($_,\$error)) {
			$self->{records}{$dns} = $txt = $r;
			$error = undef;
			last;
		    }
		}
		if ($error) {
		    $self->{records}{$dns} = $txt = { permfail => $error };
		}
	    }

	    my @v = _verify_sig($sig,$txt);
	    push @rv, Mail::DKIM::Iterator::VerifyRecord->new($sig,$dns,@v);
	    $sig->{':result'} = $rv[-1] if @v; # final result

	} elsif (exists $self->{records}{$dns}) {
	    # cannot get DKIM record
	    push @rv, $sig->{':result'} = Mail::DKIM::Iterator::VerifyRecord
		->new($sig,$dns, DKIM_TEMPERROR, "dns lookup failed");
	} else {
	    # no DKIM record yet known for $dns - preliminary result
	    push @rv, Mail::DKIM::Iterator::VerifyRecord->new($sig,$dns);
	}
    }
    return ($self->{_last_result} = \@rv);
}

# Parse DKIM-Signature value into hash and fill in necessary default values.
# Input can be string or hash.
sub parse_signature {
    my ($v,$error,$for_signing) = @_;
    $v = parse_taglist($v,$error) or return if !ref($v);

    if ($for_signing) {
	# some defaults
	$v->{v} //= '1';
    }

    if (($v->{v}//'') ne '1') {
	$$error = "bad DKIM signature version: ".($v->{v}||'<undef>');
    } elsif (!$v->{d}) {
	$$error = "required [d]omain not given";
    } elsif (!$v->{s}) {
	$$error = "required [s]elector not given";
    } elsif (!$v->{h}) {
	$$error = "required [h]eader fields not given";
    } elsif ($v->{l} && $v->{l} !~m{^\d{1,76}\z}) {
	$$error = "invalid body [l]ength";
    } elsif (do {
	$v->{q} = lc($v->{q}//'dns/txt');
	$v->{q} ne 'dns/txt'
    }) {
	$$error = "unsupported query method $v->{q}";
    }
    return if $$error;

    $v->{d} = lc($v->{d});
    $v->{a} = lc($v->{a}//'rsa-sha256');
    $v->{c} = lc($v->{c}//'simple/simple');

    my @h = split(/\s*:\s*/,lc($v->{h}));
    $$error = "'from' missing from [h]eader fields"
	if ! grep { $_ eq 'from' } @h;
    $v->{'h:list'} = \@h;

    if ($for_signing) {
	delete $v->{b};
	delete $v->{bh};
	$v->{t} = undef if exists $v->{t};
	if (defined $v->{x} && $v->{x} !~m{^\+?\d{1,12}\z}) {
	    $$error = "invalid e[x]piration time";
	}
    } else {
	if (!$v->{b} or not $v->{'b:bin'} = _decode64($v->{b})) {
	    $$error = "invalid body signature: ".($v->{b}||'<undef>');
	} elsif (!$v->{bh} or not $v->{'bh:bin'} = _decode64($v->{bh})) {
	    $$error = "invalid header signature: ".($v->{bh}||'<undef>');
	} elsif ($v->{t} && $v->{t} !~m{^\d{1,12}\z}) {
	    $$error = "invalid [t]imestamp";
	} elsif ($v->{x}) {
	    if ($v->{x} !~m{^\d{1,12}\z}) {
		$$error = "invalid e[x]piration time";
	    } elsif ($v->{t} && $v->{x} < $v->{t}) {
		$$error = "expiration precedes timestamp";
	    }
	}

	if ($v->{i}) {
	    $v->{i} = _decodeQP($v->{i});
	    if (lc($v->{i}) =~m{\@([^@]+)$}) {
		$v->{'i:domain'} = $1;
		$$error ||= "[i]dentity does not match [d]omain"
		    if $v->{'i:domain'} !~m{^(.+\.)?\Q$v->{d}\E\z};
	    } else {
		$$error = "no domain in identity";
	    }
	} else {
	    $v->{i} = '@'.$v->{d};
	}
    }

    my ($hdrc,$bodyc) = $v->{c}
	=~m{^(relaxed|simple)(?:/(relaxed|simple))?$} or do {
	$$error ||= "invalid canonicalization $v->{c}";
    };
    $bodyc ||= 'simple';
    my ($kalgo,$halgo) = $v->{a} =~m{^(rsa)-(sha(?:1|256))$} or do {
	$$error ||= "unsupported algorithm $v->{a}";
    };
    return if $$error;

    $v->{'c:hdr'}  = $hdrc;
    $v->{'c:body'} = $bodyc;
    $v->{'a:key'}  = $kalgo;
    $v->{'a:hash'} = $halgo;

    # ignore: z
    return $v;
}

# Parse DKIM key into hash and fill in necessary default values.
# Input can be string or hash.
sub parse_dkimkey {
    my ($v,$error) = @_;
    $v = parse_taglist($v,$error) or return if !ref($v);
    if (!$v || !%$v) {
	$$error = "invalid or empty DKIM record";
	return;
    }

    if (($v->{v}||='DKIM1') ne 'DKIM1') {
	$$error = "bad DKIM record version: $v->{v}";
    } elsif (($v->{k}//='rsa') ne 'rsa') {
	$$error = "unsupported key type $v->{k}";
    } else {
	if (exists $v->{g}) {
	    # g is deprecated in RFC 6376
	    if (1) {
		delete $v->{g}
	    } else {
		$v->{g} = ($v->{g}//'') =~m{^(.*)\*(.*)$}
		    ? qr{^\Q$1\E.*\Q$2\E\@[^@]+\z}
		    : qr{^\Q$v->{g}\E\@[^@]+\z};
	    }
	}
	$v->{t} = { map { $_ => 1 } split(':',lc($v->{t} || '')) };
	$v->{h} = { map { $_ => 1 } split(':',lc($v->{h} || 'sha1:sha256')) };
	$v->{s} = { map { $_ => 1 } split(':',lc($v->{s} || '*')) };
	if (!$v->{s}{'*'} && !$v->{s}{email}) {
	    $$error = "service type " . join(':',keys %{$v->{s}})
		. " does not match";
	    return;
	}
	return $v;
    }
    return;
}

# Finalize signature, i.e add the 'b' parameter.
# Input is signature (hash or string), the private key (PEM or
# Crypto::OpenSSL::RSA object) and the mail header.
# Output is "DKIM-Signature: .... " string with proper line length so that it
# can be inserted into the mail header.
sub sign {
    my ($sig,$key,$hdr,$error) = @_;
    if (ref($sig) && $sig->{h_auto}) {
	# add a useful default based on the header which makes sure that no all
	# relevant headers are covered and no additional important headers can
	# be added
	my (%oh,@nh);
	$oh{lc($_)}++ for split(':',$sig->{h} ||'');
	for my $k (@sign_headers) {
	    for($hdr =~m{^($k):}mgi) {
		push @nh,$k; # cover each instance in header
	    }
	    push @nh,$k; # cover non-existance so that no instance can be added
	    delete $oh{$k} if exists $oh{$k} and --$oh{$k} == 0;
	}
	push @nh,($_) x $oh{$_} for keys %oh;
	$sig->{h} = join(':',@nh);
    }
    $sig = parse_signature($sig,$error,1) or return;


    my %sig = %$sig;
    $sig{t} = time() if !$sig{t} && exists $sig{t};
    $sig{x} = ($sig{t} || time()) + $1
	if $sig{x} && $sig{x} =~m{^\+(\d+)$};
    $sig{'a:key'} eq 'rsa' or do {
	$$error = "unsupported algorithm ".$sig{'a:key'};
	return;
    };
    delete $sig{b};
    $sig{i} = _encodeQP($sig{':i'}) if $sig{':i'};
    $sig{z} = _encodeQP($sig{':z'}) if $sig{':z'};
    $sig{bh} = _encode64($sig{'bh:computed'} || $sig{'bh:bin'});
    $sig{h} = join(':',@{$sig{'h:list'}});

    my @v;
    for (qw(v a c d q s t x h l i z bh)) {
	my $v = delete $sig{$_} // next;
	push @v, "$_=$v"
    }
    for(sort keys %sig) {
	m{:} and next;
	my $v = _encodeQP(delete $sig{$_} // next);
	push @v, "$_=$v"
    }

    my @lines = shift(@v);
    for(@v,"b=") {
	$lines[-1] .= ';';
	my $append = " $_";
	my $x80 = (@lines == 1 ? 64 : 80) - length($lines[-1]);
	if (length($append)<=$x80) {
	    $lines[-1] .= $append;
	} elsif (length($append)<=80) {
	    push @lines,$append;
	} else {
	    while (1) {
		if ( $x80>10) {
		    $lines[-1] .= substr($append,0,$x80,'');
		    $append eq '' and last;
		}
		push @lines,' ';
		$x80 = 80;
	    }
	}
    }

    my $dkh = 'DKIM-Signature: '.join("\r\n",@lines);
    $sig->{'a:key'} eq 'rsa' or do {
	$$error = "unsupported signature algorithm $sig->{'a:key'}";
	return;
    };
    my $hash = _compute_hdrhash($hdr,
	$sig{'h:list'},$sig->{'a:hash'},$sig->{'c:hdr'},$dkh);

    my $priv = ref($key) ? $key : Crypt::OpenSSL::RSA->new_private_key($key);
    $priv or do {
	$$error = "using private key failed";
	return;
    };
    $priv->use_no_padding;

    my $data = _encode64($priv->decrypt(
	_emsa_pkcs1_v15($sig->{'a:hash'},$hash,$priv->size)));

    my $x80 = 80 - ($dkh =~m{\n([^\n]+)\z} && length($1));
    while ($data ne '') {
	$dkh .= substr($data,0,$x80,'') if $x80>10;
	$dkh .= "\r\n " if $data ne '';
	$x80 = 80;
    }
    $dkh .= "\r\n";
    return $dkh;
}

# Verify a DKIM signature (hash from parse_signature) using a DKIM key (hash
# from parse_dkimkey). Output is (error_code,error_string) or simply
# (DKIM_PASS) in case of no error.
sub _verify_sig {
    my ($sig,$param) = @_;
    return (DKIM_PERMERROR,"none or invalid dkim record") if ! %$param;
    return (DKIM_TEMPERROR,$param->{tempfail}) if $param->{tempfail};
    return (DKIM_PERMERROR,$param->{permfail}) if $param->{permfail};

    my $FAIL = $param->{t}{y} ? DKIM_NEUTRAL : DKIM_FAIL;
    return ($FAIL,"key revoked") if ! $param->{p};

    return ($FAIL,"hash algorithm not allowed")
	if ! $param->{h}{$sig->{'a:hash'}};

    return ($FAIL,"identity does not match domain") if $param->{t}{s}
	&& $sig->{'i:domain'} && $sig->{'i:domain'} ne $sig->{d};

    return ($FAIL,"identity does not match granularity")
	if $param->{g} && $sig->{i} !~ $param->{g};

    # pre-computed hash over body
    return if ! defined $sig->{'bh:computed'}; # not yet computed
    if ($sig->{'bh:computed'} ne $sig->{'bh:bin'}) {
	return ($FAIL,'body hash mismatch');
    }

    my $rsa = Crypt::OpenSSL::RSA->new_public_key(do {
	local $_ = $param->{p};
	s{\s+}{}g;
	s{(.{1,64})}{$1\n}g;
	"-----BEGIN PUBLIC KEY-----\n$_-----END PUBLIC KEY-----\n";
    });
    $rsa or return ($FAIL,"using public key failed");
    $rsa->use_no_padding;
    my $bencrypt = $rsa->encrypt($sig->{'b:bin'});
    my $expect = _emsa_pkcs1_v15(
	$sig->{'a:hash'},$sig->{'h:hash'},$rsa->size);
    if ($expect ne $bencrypt) {
	# warn "expect= "._encode64($expect)."\n";
	# warn "encrypt="._encode64($bencrypt)."\n";
	return ($FAIL,'header sig mismatch');
    }
    return (DKIM_PASS, join(' + ', @{$sig->{':warning'} || []}));
}

# parse the header and extract
sub _parse_header {
    my $hdr = shift;
    my %all_critical = map { $_ => 0 } @critical_headers;
    $all_critical{lc($_)}-- for $hdr =~m{^($critical_headers_rx):}mig;
    my @sig;
    while ( $hdr =~m{^(DKIM-Signature:\s*(.*\n(?:[ \t].*\n)*))}mig ) {
	my $dkh = $1; # original value to exclude it when computing hash

	my $error;
	my $sig = parse_signature($2,\$error);
	if ($sig) {
	    $sig->{'h:hash'} = _compute_hdrhash($hdr,
		$sig->{'h:list'},$sig->{'a:hash'},$sig->{'c:hdr'},$dkh);

	    my %critical = %all_critical;
	    $critical{$_}++ for @{$sig->{'h:list'}};
	    if (my @h = grep { $critical{$_} < 0 } keys %critical) {
		push @{$sig->{':warning'}},
		    "unprotected critical header ".join(",",sort @h);
	    }
	} else {
	    $sig = { error => "invalid DKIM-Signature header: $error" };
	}

	push @sig,$sig;
    }
    return @sig;
}

{
    # EMSA-PKCS1-v1_5 encapsulation, see RFC 3447 9.2
    my %sig_prefix = (
	'sha1'   => pack("H*","3021300906052B0E03021A05000414"),
	'sha256' => pack("H*","3031300d060960864801650304020105000420"),
    );
    sub _emsa_pkcs1_v15 {
	my ($algo,$hash,$len) = @_;
	my $t = ($sig_prefix{$algo} || die "unsupport digest $algo") . $hash;
	my $pad = $len - length($t) -3;
	$pad < 8 and die;
	return "\x00\x01" . ("\xff" x $pad) . "\x00" . $t;
    }
}

{

    # simple header canonicalization:
    my $simple_hdrc = sub {
	my $line = shift;
	$line =~s{(?<!\r)\n}{\r\n}g;  # normalize line end
	return $line;
    };

    # relaxed header canonicalization:
    my $relaxed_hdrc = sub {
	my ($k,$v) = shift() =~m{\A([^:]+:[ \t]*)?(.*)\z}s;
	$v =~s{\r?\n([ \t])}{$1}g;  # unfold lines
	$v =~s{[ \t]+}{ }g;      # WSP+ -> SP
	$v =~s{\s+\z}{\r\n};     # eliminate all WS from end, normalize line end
	$k = lc($k||'');         # lower case key
	$k=~s{[ \t]*:[ \t]*}{:}; # remove white-space around colon
	return $k.$v;
    };

    my %hdrc = (
	simple => $simple_hdrc,
	relaxed => $relaxed_hdrc,
    );

    use Digest::SHA;
    my %digest = (
	sha1   => sub { Digest::SHA->new(1) },
	sha256 => sub { Digest::SHA->new(256) },
    );

    # compute the hash over the header
    sub _compute_hdrhash {
	my ($hdr,$headers,$hash,$canon,$dkh) = @_;
	#warn "XXX $hash | $canon";
	$hash = $digest{$hash}();
	$canon = $hdrc{$canon};
	my @hdr;
	my %kv;
	for my $k (@$headers) {
	    if ($k eq 'dkim-signature') {
		for($hdr =~m{^($k:[^\n]*\n(?:[ \t][^\n]*\n)*)}mig) {
		    $_ eq $dkh and next;
		    push @hdr,$_;
		}
	    } else {
		my $v = $kv{$k} ||=
		    [ $hdr =~m{^($k:[^\n]*\n(?:[ \t][^\n]*\n)*)}mig ];
		# take last matching kv in mail header
		push @hdr, pop(@$v) // '';
	    }
	}
	$dkh =~s{([ \t;:]b=)([a-zA-Z0-9/+= \t\r\n]+)}{$1};
	$dkh =~s{[\r\n]+\z}{};
	push @hdr,$dkh;
	$_ = $canon->($_) for (@hdr);
	#warn Dumper(\@hdr); use Data::Dumper;
	$hash->add(@hdr);
	return $hash->digest;
    }

    # simple body canonicalization:
    # - normalize to \r\n line end
    # - remove all empty lines at the end
    # - make sure that body consists at least of a single empty line
    # relaxed body canonicalization:
    # - like simple, but additionally...
    # - remove any white-space at the end of a line (excluding \r\n)
    # - compact any white-space inside the line to a single space

    my $bodyc = sub {
	my $relaxed = shift;
	my $empty = my $no_line_yet = '';
	my $realdata;
	sub {
	    my $data = shift;
	    if ($data eq '') {
		return $no_line_yet if $realdata;
		return "\r\n";
	    }
	    my $nl = rindex($data,"\n");
	    if ($nl == -1) {
		$no_line_yet .= $data;
		return '';
	    }

	    if ($nl == length($data)-1) {
		# newline at end of data
		$data = $no_line_yet . $data if $no_line_yet ne '';
		$no_line_yet = '';
	    } else {
		# newline somewhere inside
		$no_line_yet .= substr($data,0,$nl+1,'');
		($data,$no_line_yet) = ($no_line_yet,$data);
	    }

	    $data =~s{(?<!\r)\n}{\r\n}g; # normalize line ends
	    if ($relaxed) {
		$data =~s{[ \t]+}{ }g;   # compact WSP+ to SP
		$data =~s{ \r\n}{\r\n}g; # remove WSP+ at eol
	    }

	    if ($data =~m{(^|\n)(?:\r\n)+\z}) {
		if (!$+[1]) {
		    # everything empty
		    $empty .= $data;
		    return '';
		} else {
		    # part empty
		    $empty .= substr($data,0,$+[1],'');
		    ($empty,$data) = ($data,$empty);
		}
	    } else {
		# nothing empty
		if ($empty ne '') {
		    $data = $empty . $data;
		    $empty = '';
		}
	    }
	    $realdata = 1;
	    return $data;
	};
    };

    my %bodyc = (
	simple  => sub { $bodyc->(0) },
	relaxed => sub { $bodyc->(1) },
    );

    # add data to the body
    sub _append_body {
	my ($self,$buf) = @_;
	for my $sig (@{$self->{sig}}) {
	    $sig->{'bh:computed'} and next;
	    my $bh = $sig->{'bh:collecting'} ||= do {
		if (!$sig->{error} and
		    my $digest = $digest{$sig->{'a:hash'}}() and
		    my $transform = $bodyc{$sig->{'c:body'}}()
		) {
		    {
			digest => $digest,
			transform => $transform,
			$sig->{l} ? (l => $sig->{l}) :
			defined($sig->{l}) ? (l => \$sig->{l}) :  # capture l
			(),
		    };
		} else {
		    { done => 1 };
		}
	    };

	    $bh->{done} and next;
	    if ($buf eq '') {
		$bh->{done} = 1;
		goto compute_signature;
	    }
	    my $tbuf = $bh->{transform}($buf);
	    $tbuf eq '' and next;
	    {
		defined $bh->{l} or last;
		if (ref $bh->{l}) {
		    ${$bh->{l}} += length($tbuf);
		    next;
		}
		if ($bh->{l} > 0) {
		    last if ($bh->{l} -= length($tbuf))>0;
		    $bh->{_data_after_l} ||=
			substr($tbuf,$bh->{l},-$bh->{l},'') =~m{\S} & 1;
		    $bh->{l} = 0;
		} else {
		    $bh->{_data_after_l} ||= $tbuf =~m{\S} & 1;
		    $tbuf = '';
		}
		$bh->{done} = 1;
	    }
	    $bh->{digest}->add($tbuf) if $tbuf ne '';
	    $bh->{done} or next;

	    compute_signature:
	    delete $sig->{'bh:collecting'};
	    $sig->{'bh:computed'} = $bh->{digest}->digest;
	    push @{$sig->{':warning'}}, 'data after signed body'
		if $bh->{_data_after_l};
	}
    }
}

{

    # parse_taglist($val,\$error)
    # Parse a tag-list, like in the DKIM signature and in the DKIM key.
    # Returns a hash of the parsed list. If error occur $error will be set and
    # undef will be returned.

    my $fws = qr{
	[ \t]+ (?:\r?\n[ \t]+)? |
	\r?\n[ \t]+
    }x;
    my $tagname = qr{[a-z]\w*}i;
    my $tval = qr{[\x21-\x3a\x3c-\x7e]+};
    my $tagval = qr{$tval(?:$fws$tval)*};
    my $end = qr{(?:\r?\n)?\z};
    my $delim_or_end = qr{ $fws? (?: $end | ; (?: $fws?$end|)) }x;

    sub parse_taglist {
	my ($v,$error) = @_;
	my %v;
	while ( $v =~m{\G $fws? (?:
	    ($tagname) $fws?=$fws? ($tagval?) $delim_or_end |
	    | (.+)
	)}xgcs) {
	    if (defined $3) {
		$$error = "invalid data at end: '$3'";
		return;
	    }
	    last if ! defined $1;
	    exists($v{$1}) && do {
		$$error = "duplicate key $1";
		return;
	    };
	    $v{$1} = $2;
	}
	#warn Dumper(\%v); use Data::Dumper;
	return \%v;
    }
}

sub _encode64 {
    my $data = shift;
    my $pad = ( 3 - length($data) % 3 ) % 3;
    $data = pack('u',$data);
    $data =~s{(^.|\n)}{}mg;
    $data =~tr{` -_}{AA-Za-z0-9+/};
    substr($data,-$pad) = '=' x $pad if $pad;
    return $data;
}

sub _decode64 {
    my $data = shift;
    $data =~s{\s+}{}g;
    $data =~s{=+$}{};
    $data =~tr{A-Za-z0-9+/}{`!-_};
    $data =~s{(.{1,60})}{ chr(32 + length($1)*3/4) . $1 . "\n" }eg;
    return unpack("u",$data);
}

sub _encodeQP {
    (my $data = shift)
	=~s{([^\x21-\x3a\x3c\x3e-\x7e])}{ sprintf('=%02X',ord($1)) }esg;
    return $data;
}

sub _decodeQP {
    my $data = shift;
    $data =~s{\s+}{}g;
    $data =~s{=([0-9A-F][0-9A-F])}{ chr(hex($1)) }esg;
    return $data;
}


# ResultRecord for verification.
package Mail::DKIM::Iterator::VerifyRecord;
sub new {
    my $class = shift;
    bless [@_],$class;
}
sub sig       { shift->[0] }
sub domain    { shift->[0]{d} }
sub dnsname   { shift->[1] }
sub status    { shift->[2] }
sub error     { $_[0]->[2] >0 ? undef : $_[0]->[3] }
sub warning   { $_[0]->[2] >0 ? $_[0]->[3] : undef }

sub authentication_results {
    my $self = shift;
    return if ! $self->[2];
    my $ar = "dkim=$self->[2]";
    $ar .= " ($self->[3])" if defined $self->[3] and $self->[3] ne '';
    $ar .= " header.d=".$self->[0]{d};
    return $ar;
}

# ResultRecord for signing.
package Mail::DKIM::Iterator::SignRecord;
sub new {
    my $class = shift;
    bless [@_],$class;
}
sub sig       { shift->[0] }
sub domain    { shift->[0]{d} }
sub dnsname   {
    my $sig = shift->[0];
    return ($sig->{s} || 'UNKNOWN').'_domainkey'.($sig->{d} || 'UNKNOWN');
}
sub signature { shift->[1] }
sub status    { shift->[2] }
sub error     { shift->[3] }

1;

__END__

=head1 NAME

Mail::DKIM::Iterator - Iterative DKIM validation or signing.

=head1 SYNOPSIS

    # ---- Verify all DKIM signature headers found within a mail -----------

    my $mailfile = $ARGV[0];

    use Mail::DKIM::Iterator;
    use Net::DNS;

    my %dnscache;
    my $res = Net::DNS::Resolver->new;

    # Create a new Mail::DKIM::Iterator object.
    # Feed parts from the mail and results from DNS lookups into the object
    # until we have the final result.

    open( my $fh,'<',$mailfile) or die $!;
    my $dkim = Mail::DKIM::Iterator->new(dns => \%dnscache);
    my $rv;
    my @todo = \'';
    while (@todo) {
	my $todo = shift(@todo);
	if (ref($todo)) {
	    # need more data from mail
	    if (read($fh,$buf,8192)) {
		($rv,@todo) = $dkim->next($buf);
	    } else {
		($rv,@todo) = $dkim->next('');
	    }
	} else {
	    # need a DNS lookup
	    if (my $q = $res->query($todo,'TXT')) {
		# successful lookup
		($rv,@todo) = $dkim->next({
		    $todo => [
			map { $_->type eq 'TXT' ? ($_->txtdata) : () }
			$q->answer
		    ]
		});
	    } else {
		# failed lookup
		($rv,@todo) = $dkim->next({ $todo => undef });
	    }
	}
    }

    # This final result consists of a VerifyRecord for each DKIM signature
    # in the header, which provides access to the status. Status is one of
    # of DKIM_FAIL, DKIM_FAIL, DKIM_PERMERROR, DKIM_TEMPERROR, DKIM_NEUTRAL or
    # DKIM_POLICY. In case of error $record->error contains a string
    # representation of the error.

    for(@$rv) {
	my $status = $_->status;
	my $name = $_->domain;
	if (!defined $status) {
	    print STDERR "$mailfile: $name UNKNOWN\n";
	} elsif ($status == DKIM_PASS) {
	    # fully validated
	    print STDERR "$mailfile: $name OK ".$_->warning".\n";
	} elsif ($status == DKIM_FAIL) {
	    # hard error
	    print STDERR "$mailfile: $name FAIL ".$_->error."\n";
	} else {
	    # soft-fail, temp-fail, invalid-header
	    print STDERR "$mailfile: $name $status ".$_->error."\n";
	}
    }


    # ---- Create signature for a mail -------------------------------------

    my $mailfile = $ARGV[0];

    use Mail::DKIM::Iterator;

    my $dkim = Mail::DKIM::Iterator->new(sign => {
	c => 'relaxed/relaxed',
	a => 'rsa-sha1',
	d => 'example.com',
	s => 'foobar',
	':key' => PEM string for private key or Crypt::OpenSSL::RSA object
    });

    open(my $fh,'<',$mailfile) or die $!;
    my $rv;
    my @todo = \'';
    while (@todo) {
	my $todo = shift @todo;
	die "DNS lookups should not be needed here" if !ref($todo);
	# need more data from mail
	if (read($fh,$buf,8192)) {
	    ($rv,@todo) = $dkim->next($buf);
	} else {
	    ($rv,@todo) = $dkim->next('');
	}
    }
    for(@$rv) {
	my $status = $_->status;
	my $name = $_->domain;
	if (!defined $status) {
	    print STDERR "$mailfile: $name UNKNOWN\n";
	} elsif (status != DKIM_PASS) {
	    print STDERR "$mailfile: $name $status - ".$_->error."\n";
	} else {
	    # show signature
	    print $_->signature;
	}
    }

=head1 DESCRIPTION

With this module one can validate DKIM Signatures in mails and also create DKIM
signatures for mails.

The main difference to L<Mail::DKIM> is that the validation can be done
iterative, that is the mail can be streamed into the object and if DNS lookups
are necessary their results can be added to the DKIM object asynchronously.
There are no blocking operation or waiting for input, everything is directly
driven by the user/application feeding the DKIM object with data.

This module implements only DKIM according to RFC 6376.
It does not support the historic DomainKeys standard (RFC 4870).

The following methods are relevant.
For details of their use see the examples in the SYNOPSIS.

=over 4

=item new(%args) -> $dkim

This will create a new object. The following arguments are supported

=over 8

=item dns => \%hash

A hash with the DNS name as key and the DKIM record for this name as value.
This can be used as a common DNS cache shared over multiple instances of the
class. If none is given only a local hash will be created inside the object.

=item sign => \@dkim_sig

List of DKIM signatures which should be used for signing the mail (usually only
a single one). These can be given as string or hash (see C<parse_signature>
below). These DKIM signatures are only used to collect the relevant information
from the header and body of the mail, the actual signing is done in the
SignRecord object (see below).

=item sign_and_verify => 0|1

Usually it either signs the mail (if C<sign> is given) or validates signatures
inside the mail. When this option is true it will validate existing signatures
additionally to creating new signatures if C<sign> is used.

=item filter => $sub

A filter function which gets applied to all signatures.
Signatures not matching the filter will be removed.
The function is called as C<< $sub->(\%sig,$header) >> where C<%sig> is the
signature hash and C<$header> the header of the mail (which can be considered
the same over all calls of C<$sub>). Typically this is used to exclude any
signatures which don't match the domain of the From header, i.e. check against
C<$sig{d}>.

=back

=item $dkim->next([ $mailchunk | \%dns ]*) -> ($rv,@todo)

This is used to add new information to the DKIM object.
These information can be a new chunk from the mail (string), the signal for end
of mail input (empty string C<''>) or a mapping between the name and the record
for a DKIM key.

If there are still things todo to get the final result C<@todo> will get the
necessary instructions, either as a string containing a DNS name which should be
used to lookup a DKIM key record, or a reference to a scalar C<\''> to signal
that more data from the mail are needed.
C<$rv> might already contain preliminary results.

Once the final result could be computed C<@todo> will be empty and C<$rv> will
contain the results as a list. Each of the objects in the list is either a
VerifyRecord (in case of DKIM verification) or a SignRecord (in case of DKIM
signing).

Both VerifyRecord and SignRecord have the following methods:

=over 8

=item status - undef if no DKIM result is yet known for the record (preliminary
result). Otherwise any of DKIM_PASS, DKIM_FAIL, DKIM_NEUTRAL, DKIM_TEMPERROR,
DKIM_POLICY, DKIM_PERMERROR.

=item error - an error description in case the status shows an error, i.e. with
all status values except undef and DKIM_PASS.

=item sig - the DKIM signature as hash

=item domain - the domain value from the DKIM signature

=item dnsname - the dnsname value, i.e. based on domain and selector

=back

A SignRecord has additionally the following methods:

=over 8

=item signature - the DKIM-Signature value, only if DKIM_PASS

=back

A VerifyRecord has additionally the following methods:

=over 8

=item warning - possible warnings if DKIM_PASS

Currently this is used to provide information if critical header fields in
the mail are not convered by the signature and thus might have been changed
or added. It will also warn if the signature uses the C<l> attribute to
limit whch part of the body is included in the signature and there are
non-white-space data after the signed body.

=item authentication_results

returns a line usable in Authentication-Results header

=back

=item result

Will return the latest computed result, i.e. like C<next>.

=item authentication_results

Will return a string which can be used for the C<Authentication-Results>
header, see RFC 7601.

=item filter($sub)

Sets a filter function and applies it immediately if the mail header is already
known.  See C<filter> argument of C<new> for more details.

=back

Apart from these methods the following utility functions are provided

=over 4

=item parse_signature($dkim_sig,\$error) -> \%dkim_sig|undef

This parses the value from the DKIM-Signature field of mail and returns it as a
hash. On any problems while interpreting the value undef will be returned and
C<$error> will be filled with a string representation of the problem.

=item parse_dkimkey($dkim_key,\$error) -> \%dkim_key|undef

This parses a DKIM key which is usually found as a TXT record in DNS and
returns it as a hash. On any problems while interpreting the value undef will be
returned and C<$error> will be filled with a string representation of the
problem.

=item parse_taglist($string,\$error) -> \%hash

This parses a tag list like found in DKIM record, DKIM signatures or DMARC
records and returns it as a hash.

=item sign($dkim_sig,$priv_key,$hdr,\$error) -> $signed_dkim_sig

This takes a DKIM signature C<$dkim_sig> (as string or hash), an RSA private key
C<$priv_key> (as PEM string or Crypt::OpenSSL::RSA object) and the header of the
mail and computes the signature. The result C<$signed_dkim_sig> will be a
signature string which can be put on top of the mail.

If C<< $hdr->{l} >> is defined and C<0> then the signature will contain an 'l'
attribute with the full length of the body.

If C<< $hdr->{h_auto} >> is true it will determine the necessary minimal
protection needed for the headers, i.e. critical headers will be included in
the C<h> attribute one more time than they are set to protect against an
additional definition. To achieve a secure by default behavior
C<< $hdr->{h_auto} >> is true by default and need to be explicitly set to false
to achieve potential insecure behavior.

if C<< $hdr->{h} >> is set any headers in C<< $hdr->{h} >> which are not yet
in the C<h> attribute due to C<< $hdr->{h_auto} >> will be added also.

On errors $error will be set and undef will returned.

=back

=head1 SECURITY

The protection offered by DKIM can be easily be weakened by using insufficient
header protection in the C<h> attribute of the signature of by using the C<l>
attribute and having data which are not covered by the body hash.

C<Mail::DKIM::Iterator> will warn if it detects insufficent protection inside
the DKIM signature, i.e. if critical headers are not signed or if the body has
non-white-space data not covered by the body hash. Check the C<warning> function
on the result to get these warnings.
As critical are considered from, subject, content-type and
content-transfer-encoding since changes to these can significantly change the
interpretation of the mail by the MUA or user.

When signing C<Mail::DKIM::Iterator> will also protect all critical headers
against modification and adding extra fields as described in RFC 6376 section
8.15. In addition to the critical headers checked when validating a signature it
will also properly protect C<to> and C<cc> by default.

=head1 SEE ALSO

L<Mail::DKIM>

L<Mail::SPF::Iterator>

=head1 AUTHOR

Steffen Ullrich <sullr[at]cpan[dot]org>

=head1 COPYRIGHT

Steffen Ullrich, 2015..2019

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
