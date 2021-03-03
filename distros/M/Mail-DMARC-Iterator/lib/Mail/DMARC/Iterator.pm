package Mail::DMARC::Iterator;
use strict;
use warnings;
use Mail::DKIM::Iterator 1.002;
use Mail::SPF::Iterator 1.115 qw(:DEFAULT $DEBUG);
use Net::DNS;
use Scalar::Util 'dualvar';
use Exporter;

our $VERSION = '0.014';

# TODO
# provide some way to get reports (rua)
# But to implement this we need the crude mechanism to verify external rua


# constants pass(>0), fail(0), error(<0)
# pass: At least one of the identifier aligned DKIM or SPF reported pass
# invalid-from: Mail contains no usable From, i.e. none or multiple or invalid
# perm-error: Invalid DMARC policy record
# temp-error: No pass and at least one temporary error
# none: No DMARC policy record found
# fail: Everything else
use constant {
    DMARC_PASS         => dualvar( 1,'pass'),
    DMARC_FAIL         => dualvar( 0,'fail'),
    DMARC_INVALID_FROM => dualvar(-1,'invalid-from'),
    DMARC_NONE         => dualvar(-2,'none'),
    DMARC_PERMERROR    => dualvar(-3,'perm-error'),
    DMARC_TEMPERROR    => dualvar(-4,'temp-error'),
};

our @EXPORT_OK = qw($DEBUG);
our @EXPORT = qw(
    DMARC_PASS DMARC_FAIL
    DMARC_INVALID_FROM DMARC_PERMERROR DMARC_TEMPERROR DMARC_NONE
);

*debug = \&Mail::SPF::Iterator::DEBUG;
sub import {
    goto &Exporter::import if @_ == 1; # implicit :DEFAULT
    my $i = 1;
    while ( $i<@_ ) {
	if ( $_[$i] eq 'DebugFunc' || $_[$i] eq 'Debug' ) {
	    Mail::SPF::Iterator->import(splice( @_,$i,2 ));
	    next;
	}
	++$i;
    }
    goto &Exporter::import if @_ >1; # not implicit :DEFAULT
}


# defined at the end, based on the public suffix module we have installed
sub organizational_domain;

sub new {
    my ($class,%args) = @_;
    # for SPF: $ip, $mailfrom, $helo, [$myname]
    # If no SPF information -> try to extract from Received-SPF header in mail

    my $self = bless {
	result => undef,   # cached final result

	domain  => undef,  # \@domains extracted from mail header
	record => undef,   # DMARC record for domain
	_hdrbuf => '',     # temporary buf to collect header
	_from => undef,    # list of sender domains during collection in header
	_dmarc_domain => undef, # list of domains to check for DMARC record

	dkim => undef,     # internal DKIM object
	dkim_sub => undef, # external function which computes dkim_result
	dkim_result  => undef, # result from DKIM

	spf => undef,      # SPF object
	spf_result  => undef, # result from SPF

	dnscache => undef, # external DNS cache
	_dnsq => {},       # local mapping to DNS packet for open queries
	authentication_results => [],
    },$class;

    if ($args{spf_result}) {
	$self->{spf_result} = delete $args{spf_result};
    } elsif ($args{ip} && $args{mailfrom} && $args{helo}) {
	$self->{spf} = Mail::SPF::Iterator->new(
	    delete @args{qw(ip mailfrom helo myname)});
	$self->{spf_result} = [ $self->{spf}->next ];
    } elsif (exists $args{spf_result}) {
	# explicitely set to undef - extract from Received-SPF header
    } else {
	# we cannot lookup SPF ourself so we need to rely on DKIM only
	$self->{spf_result} = [];
    }

    if ($args{dkim_result}) {
	$self->{dkim_result}[0] = delete $args{dkim_result};
    } elsif ($args{dkim_sub}) {
	$self->{dkim_sub} = delete $args{dkim_sub};
	$self->{dkim_result}[0] = $self->{dkim_sub}();
    } else {
	$self->{dkim} = Mail::DKIM::Iterator->new;
	$self->{dkim_result} = [ $self->{dkim}->next ];
    }

    $self->{domain} = delete $args{domain};
    $self->{dnscache} = delete $args{dnscache};

    # maybe we have already enough data to compute result?
    $self->next;
    return $self;
}


# input
# - (string): data from mail
# - (Net::DNS::Packet): DNS packet with answer for DKIM or SPF
# - ([Net::DNS::Packet, error]): DNS query where lookup failed
# - ():       just recompute final result
# output:
# - ($rv,@todo) with $rv the (preliminary) results and @todo the list of things
#   to do, that is either need more data ('D') or DNS lookups (DNS query packet)
sub next {
    my ($self,@input) = @_;

    process_input:
    goto return_result if $self->{result};
    goto recalc if ! @input;

    my $data = shift(@input);

    # If we got a string append it to mail and if this is part of the header
    # extract data from it. The string '' means EOF.
    # ---------------------------------------------------------------------
    if (!ref($data)) {
	$DEBUG && debug("new mail data");
	if (!$self->{domain} && defined $self->{_hdrbuf}) {
	    # Scan for From header, fills self.domain
	    _inspect_header($self,$data);
	}
	if ($self->{dkim}) {
	    # feed into DKIM object
	    $self->{dkim_result} = [ $self->{dkim}->next($data) ];
	}
	goto process_input;
    }

    # Assume DNS packet. It might also be [ dns-question, error ].
    # Find the related callback to handle the response.
    # ---------------------------------------------------------------------
    my $error;
    if ( ! UNIVERSAL::isa( $data, 'Net::DNS::Packet' )) {
	($data,$error) = @$data;
	$error ||= 'unknown error';
	$DEBUG && debug("error for DNS response to %s: %s ",
	    ($data->question)[0]->string, $error);
    } else {
	$DEBUG && debug("got DNS response to ".($data->question)[0]->string);
    }

    my $dq = ($data->question)[0];
    my $cachekey = $dq->qtype.':'.$dq->qname;
    my $qid = $cachekey.':'.$data->header->id;
    my $cb = $self->{cb}{$qid};
    if (!$cb) {
	# undefined -> unexpected response: complain
	# defined but false -> possible duplicate: ignore
	warn "unexpected packet $qid does not match any of the todos\n"
	    if !defined $cb;
	goto process_input;
    };

    delete $self->{_dnsq}{$cachekey};
    $self->{dnscache}{$cachekey} = $data if $self->{dnscache};

    ($cb,my @arg) = @$cb;
    $cb->($self,$data,$error,@arg);
    goto process_input;


    recalc:
    goto return_result if $self->{result};
    goto compute_todos if ! $self->{domain};

    # Check if we can compute a final result based on the existing DKIM
    # and SPF results
    # ---------------------------------------------------------------------

    my $rec = $self->{record} or goto compute_todos;

    my $dkim_result;
    if ($self->{dkim_sub} and
	my $r = $self->{dkim_result}[0] = $self->{dkim_sub}()) {
	@$r = grep { $_->sig->{d} =~ $self->{domrx} } @$r if $self->{domrx};
    }
    if ($self->{dkim_result}) {
	if ($self->{dkim} and !$self->{dkim_result}[1]) {
	    push @{$self->{authentication_results}}, $_->authentication_results
		for @{ $self->{dkim_result}[0] || []};
	    $DEBUG && debug("internal dkim done");
	    delete $self->{dkim};
	}
	for(@{ $self->{dkim_result}[0] || [] }) {
	    $DEBUG && debug("got identifier aligned DKIM record, status=%s",
		$_->status // '<undef>');
	    my $st = $_->status // next;
	    if ($st == DKIM_SUCCESS) {
		# Identifier aligned DKIM-Received passed.
		# Alignment was already checked in _got_dmarc_record.
		$self->{result} = [ DMARC_PASS, 'DKIM' ];
		goto return_result;

	    } elsif ( $st == DKIM_SOFTFAIL || $st == DKIM_TEMPFAIL) {
		$dkim_result = [ DMARC_TEMPERROR, $_->error ];
	    } elsif ($st == DKIM_PERMFAIL) {
		$dkim_result = [ DMARC_FAIL, $_->error ];
	    } else {
		$dkim_result = [ DMARC_PERMERROR, $_->error ];
	    }
	}
    }

    my $spf_result;
    {
	my $sr = $self->{spf_result} or last;
	defined $sr->[0] or last;

	# check if envelope-from of SPF-Record matches from
	my $from = $sr->[2]{'envelope-from'} || $sr->[2]{helo} || last;
	$from =~s{.*\@}{};
	$from =~s{>.*}{};
	if ( $rec->{aspf} eq 's'
	    ? lc($from) ne $rec->{domain}
	    : $from !~m{^([\w\-\.]+\.)?\Q$rec->{domain}\E}i) {
	    # Identifier alignment failed
	    $DEBUG && debug("SPF identifier alignment failed");
	    $spf_result = [ DMARC_FAIL,
		'envelope-from does not match From header' ];
	    delete $self->{spf};
	    $self->{spf_result} = [];
	    last;
	}
	# Successful identifier alignment, use result from check.
	$DEBUG && debug("SPF identifier alignment sucess, status=%s",
	    $sr->[0]);
	if ($sr->[0] eq SPF_Pass) {
	    # fast pass through - it is enough if SPF passes
	    $self->{result} = [ DMARC_PASS, 'SPF' ];
	    goto return_result;
	}

	$spf_result =
	    $sr->[0] eq SPF_Fail      ? [ DMARC_FAIL, $sr->[3] // 'SPF Fail' ] :
	    $sr->[0] eq SPF_SoftFail  ? [ DMARC_FAIL, $sr->[3] // 'SPF SoftFail' ] :
	    $sr->[0] eq SPF_PermError ? [ DMARC_PERMERROR, $sr->[3] // 'SPF PermError' ] :
	    $sr->[0] eq SPF_TempError ? [ DMARC_TEMPERROR, $sr->[3] // 'SPF TempError' ] :
	    [ DMARC_NONE, "SPF result neutral or none" ];
    }

    if ($dkim_result || !$self->{dkim} and $spf_result || !$self->{spf}) {
	# We can compute the final result since we either have both DKIM and SPF
	# or we will not be able to get additional information for the missing
	# validator.
	# Pick the result with the best rating. This makes use of the fact that
	# DMARC_PASS > DMARC_FAIL > DMARC_...ERROR ..
	my $best;
	$DEBUG && debug("compute final result from dkim=%s spf=%s",
	    $dkim_result ? $dkim_result->[0] : '',
	    $spf_result ? $spf_result->[0] : '');
	for($dkim_result,$spf_result) {
	    defined $_->[0] or next;
	    if (!$best) {
		$best = $_
	    } elsif ($_->[0] && $_->[0]>$best->[0]) {
		$best = $_
	    }
	}
	if ($self->{dkim_sub} and
	    !$best || $best->[0] != DMARC_PASS and (
		! $self->{dkim_result}[0] ||
		grep { !$_->status } @{$self->{dkim_result}[0]})
	    ) {
	    $DEBUG && debug("wating with final result for DKIM to complete");
	    return (undef);
	}
	$self->{result} = $best ||
	    [ DMARC_FAIL, "neither DKIM nor SPF information" ];
	goto return_result;
    }

    compute_todos:

    # No final result yet - compute list of todos.
    # ---------------------------------------------------------------------
    my (@need_dns,$need_data,@todo) = ();
    if (!$self->{domain}) {
	# Need more data to find From header
	$DEBUG && debug("no domain yet, need more data from mail");
	$need_data++;
    } elsif (my $dom = $self->{_dmarc_domain}) {
	# Ask for the DMARC TXT record
	$DEBUG && debug("need DMARC record for @$dom");
	push @need_dns, [
	    $self->{_dnsq}{"TXT:_dmarc.$dom->[0]"}
		||= Net::DNS::Packet->new('_dmarc.'.$dom->[0],'TXT'),
	    \&_got_dmarc_record,
	    $dom
	];
    }

    # we have no DMARC record yet, so wait before handling DKIM and SPF
    goto return_todos if ! $self->{record};

    if ($self->{dkim}) {
	# Still have a DKIM object so we probably don't have the final DKIM
	# result yet. Check the first element of the result to see if the result
	# is final (defined) or if we still have something to do.
	if (!$self->{dkim_result}[1]) {
	    # no more todos from DKIM - remove DKIM object and keep result
	    $DEBUG && debug("DKIM done (no more todos)");
	    goto recalc;
	} else {
	    # Parse todos in dkim_result and translate them to local todos.
	    # Todo in dkim_result is either \'' for more data or the DNS
	    # name to look up the the DKIM record.
	    for(my $i=1;1;$i++) {
		my $todo = $self->{dkim_result}[$i] // last;
		if (ref($todo)) {
		    $DEBUG && debug("DKIM needs more mail data");
		    $need_data++;
		} else {
		    $DEBUG && debug("DKIM needs TXT record for $todo");
		    push @need_dns, [
			$self->{_dnsq}{"TXT:$todo"}
			    ||= Net::DNS::Packet->new($todo,'TXT'),
			\&_feed_dkim,
			$todo
		    ];
		}
	    }
	}
    }

    if ($self->{spf}) {
	# Still have a SPF object so we probably don't have the final SPF
	# result yet. Check the first element of the result to see if the result
	# is final (defined) or we still have something to do.
	if ($self->{spf_result}[0]) {
	    my $sr = $self->{spf_result};
	    # no more todos - remove SPF object and keep result
	    $DEBUG && debug("SPF is final - $sr->[0]");
	    push @{$self->{authentication_results}}, "spf=$sr->[0] " .
		($sr->[2] && $sr->[2]{problem} && " ($sr->[2]{problem})" || "").
		" smtp.mailfrom=$self->{spf}{sender}";
	    delete $self->{spf};
	    goto recalc;
	} else {
	    for(my $i=1;1;$i++) {
		# Todos in spf_result are Net::DNS objects.
		my $dnspkt = $self->{spf_result}[$i] // last;
		$DEBUG && debug("SPF needs DNS lookup for %s",
		    ($dnspkt->question)[0]->string);
		push @need_dns, [ $dnspkt, \&_feed_spf ]
	    }
	}
    } elsif (!$self->{spf_result}) {
	# Extract Received-SPF information from mail
	$DEBUG && debug("SPF needs more mail data to extract Received-SPF");
	$need_data++;
    }

    # Translate $need_data and @need_dns in todos we can return
    # ---------------------------------------------------------------------
    return_todos:
    push @todo,'D' if $need_data;
    my $qid2cb = $self->{cb} = {};
    for(@need_dns) {
	my ($pkt,$sub,@arg) = @$_;
	my ($q) = $pkt->question;
	$qid2cb->{ join(':', $q->qtype, $q->qname, $pkt->header->id) }
	    = [ $sub, @arg ];
	if ($self->{dnscache} and
	    my $cached = $self->{dnscache}{ $q->qtype.':'.$q->qname }) {
	    # we have a cache hit - adapt header id
	    $DEBUG && debug("answer %s:%s from dns cache",
		$q->qtype,$q->qname);
	    $cached->header->id($pkt->header->id);
	    unshift @input,$cached;
	} else {
	    push @todo,$pkt;
	    $DEBUG && debug("NEW TODO qid=".join(':',
		$q->qtype, $q->qname, $pkt->header->id)." q=".$pkt->string);
	}
    }
    goto process_input if @input; # process results from cache

    if ($DEBUG) {
	for(@todo) {
	    if (!ref($_)) {
		debug("TODO: need more mail data");
	    } else {
		debug("TODO: DNS ".($_->question)[0]->string);
	    }
	}
    }
    return (undef,@todo);

    # We have a final result
    # ---------------------------------------------------------------------
    return_result:
    $self->{result} or die "why am I here?";
    if (!defined $self->{result}[2]) {
	if ($self->{result}[0] == DMARC_FAIL) {
	    if ($rec->{sp} && $rec->{domain} ne $self->{domain}[0]) {
		$self->{result}[2] = $rec->{sp};
	    } else {
		$self->{result}[2] = $rec->{p};
	    }
	} else {
	    $self->{result}[2] = '';
	}
    }
    $DEBUG && do { no warnings; debug("final result: @{$self->{result}}"); };
    return @{$self->{result}};
}

sub authentication_results {
    my $self = shift;
    $self->{result} or return;
    return "dmarc=$self->{result}[0] header.from=" . $self->domain
	. ' reason="'.($self->{result}[1] // '').'"',
	@{$self->{authentication_results}};
}

# returns DMARC record
sub record { return shift->{record} }

# returns extracted domain
sub domain {
    my $self = shift;
    return $self->{domain} && $self->{domain}[0];
}

*parse_taglist = \&Mail::DKIM::Iterator::parse_taglist;
sub _got_dmarc_record {
    my ($self,$pkt,$error,$dom) = @_;
    goto error if $error; # NXDOMAIN or similar

    # Answer received, if we need to ask again we will set it again
    # to the new value.
    delete $self->{_dmarc_domain};

    # extract any usable DMARC records...
    my @record;
    for($pkt->answer) {
	$_->type eq 'TXT' or next;
	my $error;
	my $txt = $_->txtdata;
	$txt =~m{^\s*v=DMARC1[\s;]} or next;
	$DEBUG && debug("found possible DMARC record '$txt'");
	my $v = parse_taglist($txt,\$error) or next;
	$v = _check_dmarc_record($v) or next;
	push @record,$v;
    }

    goto error if !@record;

    # take first usable record and ignore the rest
    $record[0]{domain} = $dom->[0];
    $self->{record} = $record[0];

    if ($record[0]{pct}<100 && rand(100)<$record[0]{pct}) {
	$DEBUG && debug("skipping policy validation because of pct=%d",
	    $record[0]{pct});
	$self->{result} = [
	    DMARC_NONE,
	    'skipped policy validation due to pct<100'
	];
	return;
    }

    # if the DMARC record was for the organizational domain ignore sp
    if (@{$self->{domain}}>1 && $dom ne $self->{domain}[0]) {
	$record[0]{sp} = undef;
    }

    $DEBUG && debug("use DMARC record ".join(" ",
	map { "$_=$record[0]{$_}" } sort keys %{$record[0]}));

    # only consider DKIM signatures which match From
    my $domrx;
    if ($record[0]{adkim} eq 'r') {
	# relaxed mode - must match organizational domain
	$domrx = qr{(^|\.)\Q$self->{domain}[-1]\E\z};
    } else {
	# strict mode - must match domain of from
	$domrx = qr{^\Q$self->{domain}[0]\E\z};
    }
    $self->{domrx} = $domrx;
    if ($self->{dkim}) {
	$self->{dkim}->filter(sub { shift->{d} =~ $domrx });
	$self->{dkim_result} = [ $self->{dkim}->next ];
    } elsif ($self->{dkim_result}) {
	@{ $self->{dkim_result}[0] } = grep { $_->sig->{d} =~ $domrx }
	    @{ $self->{dkim_result}[0] };
    }

    # If we have spf_result built from Received-SPF header filter then
    # spf_result[0] contains all the Received-SPF headers found and we need
    # to extract the one which is usable for identifier alignment.
    if ($self->{spf_result} && ref($self->{spf_result}[0]) eq 'ARRAY') {
	$domrx =
	    $record[0]{aspf} eq $record[0]{adkim} ? $domrx :
	    $record[0]{aspf} eq 'r' ? qr{(^|\.)\Q$self->{domain}[-1]\E\z} :
	    qr{^\Q$self->{domain}[0]\E\z};

	my @aligned;
	for(@{ $self->{spf_result}[0] }) {
	    my $from = $_->[1]{'envelope-from'} or next;
	    $from =~s{.*\@}{}s;
	    $from =~s{>.*}{}s;
	    $from =~ $domrx or next;
	    push @aligned, $_
	}
	if (@aligned>1) {
	    # if we have multiple aligned records match the best
	    for(SPF_Pass,SPF_Fail,SPF_SoftFail) {
		my @a = grep { $_->[0] eq $_ } @aligned or next;
		@aligned = @a;
		last;
	    }
	    $DEBUG && debug(
		"multiple aligned Received-SPF found, pick $aligned[0][0]");
	} elsif (@aligned) {
	    $DEBUG && debug("found aligned Received-SPF with $aligned[0][0] ");
	} else {
	    $DEBUG && debug("none of the Received-SPF is aligned with $domrx");
	}
	$self->{spf_result} = !@aligned ? [ SPF_None ] : [
	    $aligned[0][0], # result
	    '',             # comment
	    $aligned[0][1], # hash
	];
    }
    return;

    error:
    # retry with next domain if possible
    $DEBUG && debug("error for DMARC query %s: %s - %s",
	$dom->[0],$error || 'no DMARC records',
	(@$dom>1 ? "retry with @{$dom}[1..$#$dom]":"no retries"));

    shift @$dom;
    if (@$dom) {
	$self->{_dmarc_domain} = $dom;
    } else {
	# No usable record found and no retries possible
	$self->{record} = '';
	# XXX This is not fully correct - some errors might be permanent
	# (NXDOMAIN) while others might be temporary only. For now we assume
	# that any given error is temporary only.
	$DEBUG && debug("finally no DMARC record: %s",
	    $error || 'no DMARC records');
	$self->{result} = $error
	    ? [ DMARC_TEMPERROR, $error ]
	    : [ DMARC_PERMERROR, 'no DMARC record found' ];
    }
    return;
}

sub _check_dmarc_record {
    my $v = shift;
    my %h;
    for (
	[ v     => qr{^DMARC1\z}, \'' ],
	[ adkim => qr{^[rs]\z},   'r' ],
	[ aspf  => qr{^[rs]\z},   'r' ],
	[ p     => qr{^(none|quarantine|reject)\z}, \'' ],
	[ sp    => qr{^(none|quarantine|reject)\z} ],
	# These are extracted but ignored for now
	[ fo    => qr{^[01ds]\z}, '0' ],
	[ pct   => qr{^\d+\z},    100 ],
	[ rf    => qr{^afrf\z},'afrf' ],
	[ ri    => qr{^\d+\z},  86400 ],
	[ rua   => qr{.},             ],
	[ ruf   => qr{.},             ],
    ) {
	my ($k,$rx,$default) = @$_;
	if (defined $v->{$k}) {
	    $v->{$k} =~ $rx or do {
		$DEBUG && debug("DMARC $k does not match $rx");
		return;
	    };
	    $h{$k} = $v->{$k}
	} elsif (defined $default) {
	    ref($default) and do {
		$DEBUG && debug("DMARC $k is missing but mandatory");
		return;
	    };
	    $h{$k} = $default;
	}
    }
    return \%h;
}

sub _feed_dkim {
    my ($self,$pkt,$error,$name) = @_;
    if ($error) {
	$DEBUG && debug("error getting DKIM record for $name");
	$self->{dkim_result} = [ $self->{dkim}->next({ $name => undef }) ];
    } else {
	my @txt = map { $_->type eq 'TXT' ? ($_->txtdata) : () } $pkt->answer;
	$DEBUG && debug("got %d txt records for $name",int(@txt));
	$self->{dkim_result} = [ $self->{dkim}->next({ $name => \@txt }) ];
    }
}

sub _feed_spf {
    my ($self,$pkt,$error) = @_;
    if ($error) {
	$self->{spf_result} = [ $self->{spf}->next([ $pkt,$error ]) ];
    } else {
	my @rv = $self->{spf}->next($pkt);
	# Mail::SPF::Iterator returns '' as result if there are still
	# open questions and it needs input from these
	if (!defined $rv[0] || $rv[0] ne '') {
	    $self->{spf_result} = \@rv;
	} else {
	    # ask SPF object for the open todos
	    $self->{spf_result} = [ undef, $self->{spf}->todo ];
	}
    }
}

# Extract information from header. We need:
# - domain of From header
# - information from Received-SPF header if no SPF object

sub _inspect_header {
    my ($self,$data) = @_;
    my @hdr;

    # on EOF analyze the last field in the header
    goto analyze if $data eq '';

    # Extract full headers from mail, i.e. make sure that no more parts of the
    # header line could follow (incl. line folding).
    # Look out for end of header too.
    $self->{_hdrbuf} .= $data;
    while ( $self->{_hdrbuf} =~m{\G
	(
	    (?:\S.*?)        # line starting with no space (hopefully key:...)
	    (?:\n[ \t].*?)*  # optional line folding
	)
	\r?\n
	(?=(\r?\n)|([^ \t\r\n]))
    }xgc) {
	push @hdr,$1;
	if ($2) {
	    # empty line: end of header
	    $DEBUG && debug("end of mail header");
	    $self->{_hdrbuf} = undef;
	    last;
	}
    }
    # remove what we extracted from the header
    substr($self->{_hdrbuf},0,pos($self->{_hdrbuf}),'')
	if @hdr && defined $self->{_hdrbuf};

    # Look for useful stuff in @hdr
    # RFC 2822 does not allow white-space before colon but RFC 822 did.
    # Because we never know what the MUA does we accept it for the From
    # header, but not for the Received-SPF header.
    for(@hdr) {
	($self->{spf} || $self->{spf_result})
	    ? s{^(From)\s*:\s*}{}i
	    : s{^(?:(From)\s*|Received-SPF):\s*}{}i
	    or next;
	if($1) {
	    # From
	    $DEBUG && debug("mail header from: $_");
	    push @{ $self->{_from} ||= [] }, _extract_domains_from_address($_);
	} else {
	    # Received-SPF
	    $DEBUG && debug("mail header received-spf: $_");
	    push @{ $self->{_spfr} ||= [] }, $_;
	}
    }

    analyze:
    if (defined $self->{_hdrbuf}) {
	return if $data ne ''; # no end of header yet, collect more
	# end of data = end of header - set to undef to no longer collect data
	$self->{_hdrbuf} = undef;
    }

    # header done
    if (!$self->{domain}) {
	my $from = delete $self->{_from};
	if (!$from) {
	    $DEBUG && debug("DMARC no usable From header found");
	    $self->{result} = [ DMARC_PERMERROR, 'no sender domain in From' ];
	    return;
	} elsif (@$from!=1) {
	    $DEBUG && debug("DMARC multiple domains in From");
	    $self->{result} = [ DMARC_PERMERROR,
		'multiple sender domains in From' ];
	    return;
	}
	$self->{domain} = [ $from->[0] ];
	if (my $dom = organizational_domain($from->[0])) {
	    push @{$self->{domain}}, $dom if $dom ne $from->[0];
	}
	# Check for DMARC record in from-domain. If nothing is found check in
	# organizational domain.
	$DEBUG && debug("domains from: @{$self->{domain}}");
	$self->{_dmarc_domain} = [ @{$self->{domain}} ];
    }

    if (!$self->{spf_result} && !$self->{spf}) {
	my @records;
	for(@{ delete $self->{_spfr} || [] }) {
	    my ($result,$hash) = _parse_spfreceived($_) or next;
	    my $from = $hash->{'envelope-from'} or do {
		$DEBUG && debug(
		    "skip Received-SPF because of no envelope-from: $_");
		next;
	    };
	    my @dom = _extract_domains_from_address($from);
	    @dom == 1 or next;
	    $DEBUG && debug("found Received-SPF: $result ".
		join(" ",map { "$_=$hash->{$_}" } sort keys %$hash));
	    push @records, [ $result, $hash ];
	}
	$self->{spf_result} = @records ?  [ \@records ] : [ SPF_None ];
    }
}

{
    # Extract domains from addresslist.
    my $addr = qr{[^\s<>@]+\@([\w\-.]+)};
    sub _extract_domains_from_address {
	local $_ = shift;
	s{\r?\n([ \t])}{$1}sg;
	my (@state,%domains);
	while (1) {
	    if (!@state) {
		m{\G ([^<,\"\(]*) (?: ([<\(\"]) | (,) | \z) }xgc or last;
		if ($2) {
		    push @state,$2
		} elsif ($1 ne '') {
		    $domains{lc($1)}++ if (my $x = $1) =~ m{^\s*$addr\s*\z};
		} elsif (!$3) {
		    last; # end of string
		}
	    } elsif ($state[-1] eq '<') {
		# address - extract domain
		m{\G(?: $addr | (?:[^>]*) ) > }xgc or last; # missing final '>'
		pop @state;
		$domains{lc($1)}++ if $1;
	    } elsif ($state[-1] eq '"') {
		# skip quoted text
		m{\G (?:[^"\\]+|\\.)* \"}xgc or last; # missing final \"
		pop @state;
	    } elsif ($state[-1] eq '(') {
		# skip comments (can be nested)
		m{\G .*? ([()]) }xsgc or last; # missing final ')'
		if ($1 eq ')') {
		    pop @state;
		} else {
		    push @state,'('
		}
	    }
	}
	$DEBUG && debug("extract: $_ -> ".join(" ",sort keys %domains));
	return sort keys %domains;
    }
}

{
    # Parse Received-SPF header into (result,\%hash).
    my %res;
    $res{ lc($_) } = $_ for(SPF_Pass, SPF_Fail, SPF_SoftFail, SPF_Neutral,
	SPF_None, SPF_TempError, SPF_PermError);
    my $res = join("|",keys %res);
    $res = qr{$res}i;
    my $fws = qr{(?:[ \t]*\r?\n)?[ \t]+};
    my $key = qr{\w[\w\-]*};
    my $atext = qr{[0-9a-zA-Z!#$%&'*+\-/=?^_`{|}~]+};
    my $dotatom = qr{$atext(?:\.$atext)*};
    my $qstring = qr{"(?:[^"\\]+|\\.)*"};
    my $val = qr{$dotatom|$qstring};

    sub _parse_spfreceived {
	local $_ = shift;
	m{\G($res)\s+}igc or return;
	my $result = $res{ lc($1) };
	my %hash;
	my $comment;
	while (1) {
	    if ($comment) {
		last if ! m{\G[^()]*([()])\s*}gc; # no end of comment found
		$comment += $1 eq '(' ? +1:-1;
	    } elsif (m{\G($key)$fws?=$fws?($val)\s*(;\s*)?}gc) {
		my ($k,$v,$delim) = ($1,$2,$3);
		$v =~s{\\(.)}{$1}g if $v =~s{\A\"(.*)\"\z}{$1};
		$hash{$k} = $v;
		last if ! $delim; # no delimeter-> end
	    } elsif (!%hash && !defined $comment && m{\G\(}gc) {
		$comment++;
	    } else {
		last
	    }
	}
	return ($result,\%hash);
    }
}

{
    # Define function organizational_domain based on which package we have to
    # calculate the public suffix.
    if (eval { require IO::Socket::SSL::PublicSuffix }) {
	my $ps = IO::Socket::SSL::PublicSuffix->default;
	*organizational_domain = sub {
	    return $ps->public_suffix($_[0],1) || $_[0];
	};
    } elsif (eval { require Domain::PublicSuffix }) {
	my $ps = Domain::PublicSuffix->new;
	*organizational_domain = sub {
	    return $ps->get_root_domain($_[0]) || $_[0];
	};

    } elsif (eval { require Mozilla::PublicSuffix }) {
	*organizational_domain = sub {
	    my $domain = shift;
	    if (my $suffix = Mozilla::PublicSuffix::public_suffix($domain)) {
		return $1 if $domain =~m{([^\.]+\.\Q$suffix\E$)}i;
	    }
	    return $domain;
	}
    } else {
	die "failed to find any package for calculating the public suffix";
    }
}

1;

__END__

=head1 NAME

Mail::DMARC::Iterator - Iterativ DMARC validation for mails.

=head1 SYNOPSIS

    use Mail::DMARC::Iterator;
    use Net::DNS::Resolver;

    my $resolver = Net::DNS::Resolver->new;
    my $dmarc = Mail::DMARC::Iterator->new(

	# data from SMTP dialog - used for SPF
	ip => '10.11.12.13',
	mailfrom => 'foo@example.com',
	helo => 'mx.example.com',

	# alternatively add predefined results from your own SPF validation
	# spf_result => [ 'pass',undef, { 'envelope-from' => ... } ]

	# or set to undef so that it tries to use Received-SPF header fields
	# spf_result => undef,

	# you can optionally use a global DNS cache
	# dnscache => \%global_cache
    );

    open( my $fh,'<','mail.eml');      # open the file
    my ($result,@todo) = $dmarc->next; # initial result

    while (!defined $result && @todo) {
	my $todo = shift(@todo);
	if (!ref($todo)) {
	    # no reference - indicator that we need more mail data
	    if (read($fh, my $buf,8192)) {
		($result,@todo) = $dmarc->next($buf);
	    } else {
		# EOF
		($result,@todo) = $dmarc->next('');
	    }
	} else {
	    # Net::DNS Packet needed for lookups of
	    # SPF, DMARC and DKIM records
	    my $answer = $resolver->send($todo);
	    ($result,@todo) = $dmarc->next(
		$answer ||
		[ $todo, $resolver->errorstring ]
	    );
	}
    }

    print STDERR "%s from-domain=%s; reason=%s\n",
	$result || 'no-result',
	$dmarc->domain || 'unknown-domain',
	$todo[0] || 'unknown-reason';


=head1 DESCRIPTION

This module can be used to validate mails against DMARC policies like specified
in RFC 7208.
The main difference to L<Mail::DMARC> is that it does no blocking operations.
Instead it implements a state machine where user input is fed into and
instructions what the machine wants is returned.
The state machine only wants the data from the mail and the result of specific
DNS lookups. With each new data fed into the machine it will provide new
information what it needs next, until it finally has enough input and returns
the final result.
Because of this design the DMARC policy validation can be easily integrated into
event-driven programs or coupled with a specific DNS resolver.

L<Mail::DMARC::Iterator> uses the similarly designed modules
L<Mail::DKIM::Iterator> and L<Mail::SPF::Iterator> to provide the necessary
functionality of validating against DKIM and SPF records.

L<Mail::DMARC::Iterator> currently only validates a mail against the policy. It
does not provide any kind of feedback to the owner of the domain, i.e. feedback
based on the C<ruf> and C<rua> attributes of the DMARC policy is not
implemented. One can still access the necessary information using the C<record>
method.

The following methods are implemented

=over 4

=item $class->new(%args) -> $dmarc

This creates a new object. The following arguments can be given:

=over 8

=item mailfrom, ip, helo, myname

These arguments are given to the L<Mail::SPF::Iterator> object where they will
be used to compute the SPF policy.

=item spf_received => \@spf_result | undef

In this record the final result of the SPF policy calculation can be given as
described in L<Mail::SPF::Iterator>. If the argument is given and set to undef
it will try to find C<Received-SPF> records inside the mail extract the SPF
result from them. These records must have an C<envelope-from> parameter which
will be used for identity aligning as described in the DMARC specification.

=item dkim_result => DKIM_RESULT

If given this is the result of an externally done DKIM computation. It is
expected to be in the same format as the result returned by
L<Mail::DKIM::Iterator>.

=item dkim_sub => function

If given this is a function which computes the current DKIM result whenever it
is needed (i.e. within calls of C<next>). This is used of DKIM processing is
done in parallel to DMARC processing so that the result can change.
The function is expected to return the DKIM_RESULT in the same format as the
result returned by L<Mail::DKIM::Iterator>.

=item dnscache => \%hash

Optional cache for DNS lookups which can be shared between multiple instances
of L<Mail::DMARC::Iterator>. Before reporting DNS lookups as needed to the
user of the object it will first try to resolve the lookups using the cache.

=back

If neither C<dkim_sub> nor C<dkim_result> are given it will create an internal
L<Mail::DKIM::Iterator> object and feed the data into it as long as it is
needed, i.e. as long as now final DMARC result is known.

=item $self->domain -> $domain

Returns the domain of the From record if already known.

=item $self->record -> \%hash

Returns the DMARC policy record as hash, if already known.

=item $self->next( [ mailtext | dnspkt | [ dnspkt,error] ]* )
  -> (undef,@todo) | ($result,$reason,$action)

This is the central method to compute the result.
If the final result is known it will return the C<$result> including the
C<$reason> for this result and any C<$action> which must be taken based on the
policy. C<$result> will be pass, fail, ... as described below. In case of fail
C<$action> will return the policy action in case of C<fail>, i.e. reject,
quarantine or none.

If the final result is not known yet it will return a list of todo's, where each
of these is either the scalar C<'D'> or a DNS query in form of a
L<Net::DNS::Packet> object. In case of the scalar the state machine expects more
data from the mail and in case of the DNS query it expectes the answer to this
query.

The results of these todo's are given as arguments to C<next>, i.e. either data
from the mail as string or a L<Net::DNS::Packet> as the answer. In case the DNS
lookup failed it should add an array reference C<[ dnspkt, error ]> consisting
of the original DNS query packet and a string description of the error.

=item $self->authentication_results => @lines

Generates lines which can be used in the Authentiation-Results header.
With builtin DKIM and SPF handling this will include the results from these
too.

=back

The final results of the DMARC calculation are a dualvar which is both a string
and a number. The following values are defined:

=over 4

=item DMARC_PASS -> 1,'pass'

At least one of the identifier aligned DKIM or SPF reported pass.

=item DMARC_INVALID_FROM -> -1,'invalid-from'

The mail contains no usable From, i.e. none or multiple or with invalid syntax.

=item DMARC_NONE -> -2,'none'

No DMARC policy record was found.

=item DMARC_PERMERROR -> -3,'perm-error'

A DMARC policy record was found but it is invalid.

=item DMARC_TEMPERROR -> -4,'temp-error'

No SPF or DKIM pass and at least one temporary error (DNS lookup...) happened.

=item DMARC_FAIL -> 0,'fail'

Everything else. The policy of reject|quarantine|none has to be applied
in this case.

=back

=head1 SEE ALSO

L<Mail::DMARC>

L<Mail::SPF::Iterator>

L<Mail::DKIM::Iterator>

=head1 AUTHOR

Steffen Ullrich <sullr[at]cpan[dot]org>

=head1 COPYRIGHT

Steffen Ullrich, 2015..2019

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
