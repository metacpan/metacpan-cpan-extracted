=head1 NAME

Mail::SPF::Iterator - iterative SPF lookup

=head1 SYNOPSIS

    use Net::DNS;
    use Mail::SPF::Iterator;
    use Mail::SPF::Iterator Debug =>1; # enable debugging
    my $spf = Mail::SPF::Iterator->new(
	$ip,       # IP4|IP6 of client
	$mailfrom, # from MAIL FROM:
	$helo,     # from HELO|EHLO
	$myname,   # optional: my hostname
	{
	    default_spf => 'mx/24 ?all', # in case no record was found in DNS
	    pass_all => SPF_SoftFail,    # treat records like '+all' as error
	    # rfc4408 => 1,              # for compatibility only
	}
    );

    # could be other resolvers too
    my $resolver = Net::DNS::Resolver->new;

    ### with nonblocking, but still in loop
    ### (callbacks are preferred with non-blocking)
    my ($result,@ans) = $spf->next; # initial query
    while ( ! $result ) {
	my @query = @ans;
	die "no queries" if ! @query;
	for my $q (@query) {
	    # resolve query
	    my $socket = $resolver->bgsend( $q );
	    ... wait...
	    my $answer = $resolver->bgread($socket);
	    ($result,@ans) = $spf->next(
		$answer                             # valid answer
		|| [ $q, $resolver->errorstring ]   # or DNS problem
	    );
	    last if $result; # got final result
	    last if @ans;    # got more DNS queries
	}
    }

    ### OR with blocking:
    ### ($result,@ans) = $spf->lookup_blocking( undef,$resolver );

    ### print mailheader
    print "Received-SPF: ".$spf->mailheader;

    # $result = Fail|Pass|...
    # $ans[0] = comment for Received-SPF
    # $ans[1] = %hash with infos for Received-SPF
    # $ans[2] = explanation in case of Fail



=head1 DESCRIPTION

This module provides an iterative resolving of SPF records. Contrary to
Mail::SPF, which does blocking DNS lookups, this module just returns the DNS
queries and later expects the responses.

Lookup of the DNS records will be done outside of the module and can be done
in a event driven way. It is also possible to do many parallel SPF checks
in parallel without needing multiple threads or processes.

This module can also make use of SenderID records for checking the C<mfrom>
part, but it will prefer SPF. It will only use DNS TXT records for looking up
SPF policies unless compatibility with RFC 4408 is explicitly enabled.

See RFC 7208 (old RFC 4408) for SPF and RFC 4406 for SenderID.

=head1 METHODS

=over 4

=item new( IP, MAILFROM, HELO, [ MYNAME ], [ \%OPT ] )

Construct a new Mail::SPF::Iterator object, which maintains the state
between the steps of the iteration. For each new SPF check a new object has
to be created.

IP is the IP if the client as string (IP4 or IP6).

MAILFROM is the user@domain part from the MAIL FROM handshake, e.g. '<','>'
and any parameters removed. If only '<>' was given (like in bounces) the
value is empty.

HELO is the string send within the HELO|EHLO dialog which should be a domain
according to the RFC but often is not.

MYNAME is the name of the local host. It's only used if required by macros
inside the SPF record.

OPT is used for additional arguments. Currently B<default_spf> can be used
to set a default SPF record in case no SPF/TXT records are
returned from DNS (useful values are for example 'mx ?all' or 'mx/24 ?all').
B<rfc4408> can be set to true in case stricter compatibility is needed with RFC
4408 instead of RFC 7208, i.e. lookup of DNS SPF records, no limit on void DNS
lookups etc.
B<pass_all> can be set to the expected outcome in case a SPF policy gets found,
which would pass everything. Such policies are common used domains used by
spammers.

Returns the new object.

=item next([ ANSWER ])

C<next> will be initially called with no arguments to get initial DNS queries
and then will be called with the DNS answers.

ANSWER is either a DNS packet with the response to a former query or C<< [
QUERY, REASON ] >> on failures, where QUERY is the DNS packet containing the
failed query and REASON the reason, why the query failed (like TIMEOUT).

If a final result was achieved it will return
C<< ( RESULT, COMMENT, HASH, EXPLAIN ) >>. RESULT is the result, e.g. "Fail",
"Pass",.... COMMENT is the comment for the Received-SPF header. HASH contains
information about problem, mechanism for the Received-SPF header.
EXPLAIN will be set to the explain string if RESULT is Fail.

The following fields are in HASH

=over 8

=item client-ip

The clients IP address

=item helo

The helo string from the client

=item identity

How the identity of the sender was given, i.e. either C<mailfrom> or
C<helo>.

=item envelope-from

The sender, either based on the mail from in the SMTP dialog (with
C<identity> being C<mailfrom>) or the HELO/EHLO.

=back

If no final result was achieved yet it will either return
C<< (undef,@QUERIES) >> with a list of new queries to continue, C<< ('') >>
in case the ANSWER produced an error but got ignored, because there are
other queries open, or C<< () >> in case the ANSWER was ignored because it
did not match any open queries.

=item mailheader

Creates value for Received-SPF header based on the final answer from next().
Returns header as string (one line, no folding) or undef, if no final result
was found.
This creates only the value, not the 'Received-SPF' prefix.

=item result

Returns ( RESULT, COMMENT, HASH, EXPLAIN ) like the final C<next> does or () if
the final result wasn't found yet.

If the SPF record had an explain modifier, which needed DNS lookups to resolve
this method might return the result (although with incomplete explain) before
C<next> does it.

=item explain_default ( [ EXPLAIN ] )

Sets default explanation string if EXPLAIN is given.
If it's called as a class method the default explanation string for the class
will be set, otherwise the default explanation string for the object.

Returns the current default explanation string for the object or if non
given or if called as a class method the default explanation string for the
class.

=item lookup_blocking ( [ TIMEOUT, RESOLVER ] )

Quick way to get the SPF status.
This will simply call C<next> until it gets a final result.

TIMEOUT limits the lookup time and defaults to 20.
RESOLVER is a Net::DNS::Resolver object (or similar) and  defaults to
C<< Net::DNS::Resolver->new >>.
Returns ( RESULT, COMMENT, HASH ) like the final C<next> does.

This is not the preferred way to use this module, because it's blocking, so
no lookups can be done in parallel in a single process/thread.

=back

=head1 EXPORTED SYMBOLS

For convenience the constants SPF_TempError, SPF_PermError, SPF_Pass, SPF_Fail,
SPF_SoftFail, SPF_Neutral, SPF_None are by default exported, which have the values
C<"TempError">, C<"PermError"> ...

=head2 Arguments to C<use>/C<import>

The C<SPF_*> symbols are available for import and are exported if no arguments
are given to C<use> or C<import>. Same effect with adding C<:DEFAULT> as an
argument. Additionally the following arguments are supported:

=over 4

=item DebugFunc => \&coderef

Sets a custom debug function, which just takes on argument. If given it will be
called on all debug messages when debugging is active. This function takes as
the only argument the debug message.

=item Debug => 1|0

Switches debugging on/off.

=back

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


use strict;
use warnings;

package Mail::SPF::Iterator;

our $VERSION = '1.121';

use fields (
    # values given in or derived from params to new()
    'helo',            # helo given in new()
    'myname',          # myname given in new()
    'clientip4',       # packed ip from new() if IP4
    'clientip6',       # packed ip from new() if IP6
    'sender',          # mailfrom|helo given in new()
    'domain',          # extracted from mailfrom|helo
    'identity',        # 'mailfrom' if sender is mailfrom, else 'helo'
    'opt',             # additional options like default_spf
    # internal states and values
    'mech',            # list of unhandled mechanism for current SPF
    'include_stack',   # stack for handling includes
    'redirect',        # set to domain of redirect modifier of current SPF
    'explain',         # set to explain modifier of current SPF
    'cb',              # [$sub,@arg] for callback to DNS replies
    'cbq',             # list of queries from last mech incl state
    'validated',       # cache used in validation of hostnames for ptr and %{p}
    'limit_dns_mech',  # countdown for number of mechanism using DNS queries
    'limit_dns_void',  # countdown for number of void DNS queries
    'explain_default', # default explanation of object specific
    'result',          # contains final result
    'tmpresult',       # contains the best result we have so far
    'used_default_spf', # set to the default_spf from opt if used
);

use Net::DNS;
use Socket;
use URI::Escape 'uri_escape';
use Data::Dumper;
use base 'Exporter';

# need encode before accessing header->id since Net::DNS 1.46
our $NEED_ENCODE_BEFORE_ID = $Net::DNS::VERSION>=1.46;

### check if IPv6 support is in Socket, otherwise try Socket6
my $can_ip6;
BEGIN {
    $can_ip6 = eval {
	require Socket;
	Socket->import(qw(inet_pton inet_ntop));
	Socket->import('AF_INET6') if ! defined &AF_INET6;
	1;
    } || eval {
	require Socket6;
	Socket6->import(qw( inet_pton inet_ntop));
	Socket6->import('AF_INET6') if ! defined &AF_INET6;
	1;
    };
    if ( ! $can_ip6 ) {
	no strict 'refs';
	*{'AF_INET6'} = *{'inet_pton'} = *{'inet_ntop'}
	    = sub { die "no IPv6 support" };
    }
}

### create SPF_* constants and export them
our @EXPORT;
our @EXPORT_OK = '$DEBUG';
use constant SPF_Noop => '_NOOP';
my %ResultQ;
BEGIN {
    my $i = 0;
    $ResultQ{ &SPF_Noop } = $i++;
    for (qw(None PermError TempError Neutral SoftFail Fail Pass)) {
	no strict 'refs';
	*{"SPF_$_"} = eval "sub () { '$_' }";
	push @EXPORT, "SPF_$_";
	$ResultQ{$_} = $i++;
    }
}

my $DEBUGFUNC;
our $DEBUG=0;
sub import {
    goto &Exporter::import if @_ == 1; # implicit :DEFAULT
    my $i = 1;
    while ( $i<@_ ) {
	if ( $_[$i] eq 'DebugFunc' ) {
	    $DEBUGFUNC = $_[$i+1];
	    splice( @_,$i,2 );
	    next;
	} elsif ( $_[$i] eq 'Debug' ) {
	    $DEBUG = $_[$i+1];
	    splice( @_,$i,2 );
	    next;
	}
	++$i;
    }
    goto &Exporter::import if @_ >1; # not implicit :DEFAULT
}



### Debugging
sub DEBUG {
    $DEBUG or return; # check against debug level
    goto &$DEBUGFUNC if $DEBUGFUNC;
    my ($pkg,$file,$line) = caller;
    my $msg = shift;
    $msg = sprintf $msg,@_ if @_;
    print STDERR "DEBUG: $pkg#$line: $msg\n";
}

### pre-compute masks for IP4, IP6
my (@mask4,@mask6);
{
    my $m = '0' x 32;
    $mask4[0] = pack( "B32",$m);
    for (1..32) {
	substr( $m,$_-1,1) = '1';
	$mask4[$_] = pack( "B32",$m);
    }

    $m = '0' x 128;
    $mask6[0] = pack( "B32",$m);
    for (1..128) {
	substr( $m,$_-1,1) = '1';
	$mask6[$_] = pack( "B128",$m);
    }
}

### mapping char to result
my %qual2rv = (
    '+' => SPF_Pass,
    '-' => SPF_Fail,
    '~' => SPF_SoftFail,
    '?' => SPF_Neutral,
);

############################################################################
# NEW
# creates new SPF processing object
# Args: ($class,$ip,$mailfrom,$helo,?$myname,?\%opt)
#  $ip: IP4/IP6 as string
#  $mailfrom: user@domain of "mail from"
#  $helo: info from helo|ehlo - should be domain name
#  $myname: local name, used only for expanding macros (optional)
#  %opt: optional additional arguments
#    default_spf => ... : default SPF record if none from DNS
# Returns: $self
############################################################################
sub new {
    my ($class,$ip,$mailfrom,$helo,$myname,$opt) = @_;
    my Mail::SPF::Iterator $self = fields::new($class);

    my $domain =
	$mailfrom =~m{\@([\w\-.]+)$} ? $1 :
	$mailfrom =~m{\@\[([\da-f:\.]+)\]$}i ? $1 :
	$helo =~m{\@([\w\-.]+)$} ? $1 :
	$helo =~m{\@\[([\da-f:\.]+)\]$}i ? $1 :
	$helo;
    my ($sender,$identity) = $mailfrom ne ''
	? ( $mailfrom,'mailfrom' )
	: ( $helo,'helo' );

    my $ip4 = eval { inet_aton($ip) };
    my $ip6 = ! $ip4 && $can_ip6 && eval { inet_pton(AF_INET6,$ip) };
    die "no client IP4 or IP6 known (can_ip6=$can_ip6): $ip"
	if ! $ip4 and ! $ip6;

    if ( $ip6 ) {
	my $m = inet_pton( AF_INET6,'::ffff:0.0.0.0' );
	if ( ($ip6 & $m) eq $m ) {
	    # mapped IPv4
	    $ip4 = substr( $ip6,-4 );
	    $ip6 = undef;
	}
    }

    %$self = (
	clientip4 => $ip4,     # IP of client
	clientip6 => $ip6,     # IP of client
	domain => $domain,     # current domain
	sender => $sender,     # sender (mailfrom|helo)
	helo   => $helo,       # helo
	identity => $identity, # 'helo'|'mailfrom'
	myname => $myname,     # name of mail host itself
	include_stack => [],   # stack in case of include
	cb => undef,           # callback for next DNS reply
	cbq => [],             # the DNS queries for cb
	validated => {},       # validated IP/domain names for PTR and %{p}
	limit_dns_mech => 10,  # Limit on Number of DNS mechanism
	limit_dns_void => 2,   # Limit on Number of void DNS answers
	mech => undef,         # list of spf mechanism
	redirect => undef,     # redirect from SPF record
	explain => undef,      # explain from SPF record
	result => undef,       # final result [ SPF_*, info, \%hash ]
	opt => $opt,
    );
    return $self;
}

############################################################################
# return result
# Args: $self
# Returns: ($status,$info,$hash,$explain)
#  $status: SPF_Pass|SPF_Fail|...
#  $info:   comment for Received-SPF header
#  $hash:   param for Received-SPF header
#  $explain: explanation string on SPF_Fail
############################################################################
sub result {
    my Mail::SPF::Iterator $self = shift;
    my $r = $self->{result} or return;
    return @$r;
}

############################################################################
# get/set default explanation string
# Args: ($self,[$explain])
#  $explain: default explanation string (will be set)
# Returns: $explain
#  $explain: default explanation string
############################################################################
{
    my $default = 'SPF Check Failed';
    sub explain_default {
	if ( ref $_[0] ) {
	    my Mail::SPF::Iterator $self = shift;
	    $self->{explain_default} = shift if @_;
	    return defined $self->{explain_default}
		? $self->{explain_default}
		: $default;
	} else {
	    shift; # class
	    $default = shift if @_;
	    return $default;
	}
    }
}

############################################################################
# lookup blocking
# not the intended way to use the module, but sometimes one needs to quickly
# lookup something, even if it's blocking
# Args: ($self,[$timeout,$resolver])
#  $timeout: total timeout for lookups, default 20
#  $resolver: Resolver object compatible to Net::DNS::Resolver, if not
#      given a new Net::DNS::Resolver object will be created
# Returns: ($status,$info,$hash,$explain)
#  see result()
############################################################################
sub lookup_blocking {
    my Mail::SPF::Iterator $self = shift;
    my ($timeout,$resolver) = @_;

    my $expire = time() + ( $timeout || 20 ); # 20s: RFC4408, 10.1
    $resolver ||= Net::DNS::Resolver->new;

    my ($status,@ans) = $self->next; # get initial queries
    while ( ! $status ) {

	# expired ?
	$timeout = $expire - time();
	last if $timeout < 0;

	my @query = @ans;
	die "no more queries but no final status" if ! @query;
	for my $q (@query) {
	    #DEBUG( "next query: ".$q->string );
	    my $socket = $resolver->bgsend( $q );

	    my $rin = '';
	    vec( $rin,fileno($socket),1) = 1;
	    select( $rin,undef,undef,$timeout ) or last;

	    my $answer = $resolver->bgread( $socket );
	    ($status,@ans) = $self->next(
		$answer || [ $q, $resolver->errorstring ]
	    );
	    last if $status or @ans;
	}
    }
    my @rv = ! $status
	? ( SPF_TempError,'', { problem => 'DNS lookups timed out' } )
	: ($status,@ans);
    return wantarray ? @rv : $status;
}

############################################################################
# mailheader
# create value for Received-SPF header for final response
# Args: $self
# Returns: $hdrvalue
############################################################################
sub mailheader {
    my Mail::SPF::Iterator $self = shift;
    my ($result,$info,$hash) = @{ $self->{result} || return };
    $result .= " (using default SPF of \"$self->{used_default_spf}\")"
	if $self->{used_default_spf};
    return $result ." ". join( "; ", map {
	my $v = $hash->{$_};
	$v =~ s{([\"\\])}{\\$1}g;
	$v =~ s{[\r\n]+}{ }g;
	$v =~ s{^\s+}{};
	$v =~ s{\s+$}{};
	$v = qq("$v") if $v eq '' or $v =~ m{[^0-9a-zA-Z!#$%&'*+\-/=?^_`{|}~]};
	"$_=$v"
    } sort keys %$hash );
}


############################################################################
# next step in SPF lookup
# - verify that there are open queries for the DNS reply and that parameter
#   in query match question+answer in reply
# - process dnsresp by the current callback
# - process callbacks result using _next_process_cbrv which returns either
#   final result or more DNS questions
# Args: ($self,$dnsresp)
#   $dnsresp: DNS reply
# Returns: (undef,@dnsq) | ($status,$info,\%param,$explain) | ()
#   (undef,@dnsq): @dnsq are more DNS questions
#   ($status,$info,\%param,$explain): final response
#   (''): reply processed, but answer ignored (likely error)
#   (): reply ignored, does not matching outstanding request
############################################################################
sub next {
    my Mail::SPF::Iterator $self = shift;
    my $dnsresp = shift;

    if ( ! $dnsresp ) {
	# no DNS response - must be initial call to next
	die "no DNS reply but callback given" if $self->{cb};
	return $self->_next_process_cbrv( $self->_query_txt_spf );
    }

    # handle DNS reply
    my $callback = $self->{cb} or die "no callback but DNS reply";
    my $cb_queries = $self->{cbq};
    if ( ! @$cb_queries ) {
	# we've got a reply, but no outstanding queries - ignore
	$DEBUG && DEBUG( "got reply w/o queries, ignoring" );
	return;
    }

    # extract query from reply
    my ($question,$err,$qid);
    if ( ! UNIVERSAL::isa( $dnsresp, 'Net::DNS::Packet' )) {
	# probably [ $question, $errorstring ]
	(my $query,$err) = @$dnsresp;
	($question) = $query->question;
	$qid = $query->header->id;
	$err ||= 'unknown error';
	$dnsresp = $err;
	$DEBUG && DEBUG( "error '$err' to query ".$question->string );
    } else {
	($question) = $dnsresp->question;
	$qid = $dnsresp->header->id;
    }
    my $qtype = $question->qtype;

    # check if the reply matches one of the open queries
    my $found;
    for (@$cb_queries) {
	next if $qid != $_->{id}; # ID mismatch
	next if $qtype ne $_->{q}->qtype;  # type mismatch

	if ( lc($question->qname) eq lc($_->{q}->qname) ) {
	    $found = $_;
	    last;
	}

	# in case of special characters the names might have the
	# wire presentation \DDD or the raw presentation
	# actual behavior depends on the Net::DNS version, so normalize
	my $rname = lc($question->qname);
	my $qname = lc($_->{q}->qname);
	s{\\(?:(\d\d\d)|(.))}{ $2 || chr($1) }esg for($rname,$qname);
	if ( $rname eq $qname ) {
	    $found = $_;
	    last;
	}
    }

    if ( ! $found ) {
	# packet does not match our queries
	$DEBUG && DEBUG( "found no open query for ".$question->string );
	return; # ignore problem
    } elsif ( ! $found->{pkt} ) {
	# duplicate response - ignore
	$DEBUG && DEBUG( "duplicate response, ignoring" );
	return;
    }

    delete $found->{pkt}; # no longer needed

    # found matching query
    # check for error
    if ( $err ) {
	# if this temporary error is the best we have so far set it as tmpresult
	if (! $self->{tmpresult} or
	    $ResultQ{ $self->{tmpresult}[0] } < $ResultQ{ &SPF_TempError }) {
	    $self->{tmpresult} = [ SPF_TempError,
		"getting ".$found->{q}->qtype." for ".$found->{q}->qname,
		{ problem => "error getting DNS response: $err" }
	    ]
	}

	if ( grep { $_->{pkt} } @$cb_queries ) {
	    # we still have outstanding queries, so we might still get answers
	    # -> return ('') as a sign, that we got an error to an outstanding
	    # request, but otherwise ignore this error
	    $DEBUG && DEBUG( "ignore error '$err', we still have oustanding queries" );
	    return ('');

	} elsif ( my $r = $self->{result} ) {
	    # we have a final result already, so this error occured only while
	    # trying to expand %{p} for explain
	    # -> ignore error, set to default explain and return final result
	    $DEBUG && DEBUG( "error looking up data for explain: $err" );
	    return @$r;

	} else {
	    # we have no final result - pick the best error we have so far
	    $DEBUG && DEBUG( "TempError: $err" );
	    $self->{result} = $self->{tmpresult};
	    _update_result_info($self);
	    return @{$self->{result}};
	}
    }

    # call callback with no records on error
    my $rcode = $dnsresp->header->rcode;
    my @answer = $dnsresp->answer;
    if (!@answer or  $rcode ne 'NOERROR') {
	my ($sub,@arg) = @$callback;
	if ($sub != \&_got_TXT_exp
	    and ! $self->{opt}{rfc4408}
	    and --$self->{limit_dns_void} < 0) {
	    $self->{result} = [ SPF_PermError, "",
		{ problem => "Number of void DNS queries exceeded" }];
	    _update_result_info($self);
	    return @{$self->{result}};
	}

	return $self->_next_process_cbrv(
	    $sub->($self,$qtype,$rcode,[],[],@arg));
    }

    # extract answer and additional data
    # verify if names and types in answer records match query
    # handle CNAMEs
    my $qname = $question->qname;
    $qname =~s{\\(?:(\d\d\d)|(.))}{ $2 || chr($1) }esg; # presentation -> raw
    $qname = lc($qname);
    my (%cname,%ans);
    for my $rr (@answer) {
	my $rtype = $rr->type;
	# changed between Net::DNS 0.63 and 0.64
	# it reports now the presentation name instead of the raw name
	( my $name = $rr->name ) =~s{\\(?:(\d\d\d)|(.))}{ $2 || chr($1) }esg;
	$name = lc($name);
	if ( $rtype eq 'CNAME' ) {
	    # remember CNAME so that we can check that the answer record
	    # for $qtype matches name from query or CNAME which is an alias
	    # for name
	    if ( exists $cname{$name} ) {
		$DEBUG && DEBUG( "more than one CNAME for same name" );
		next; # XXX should we TempError instead of ignoring?
	    }
	    $cname{$name} = $rr->cname;
	} elsif ( $rtype eq $qtype ) {
	    push @{ $ans{$name}},$rr;
	} else {
	    # XXXX should we TempError instead of ignoring?
	    $DEBUG && DEBUG( "unexpected answer record for $qtype:$qname" );
	}
    }

    # find all valid names, usually there should be at most one CNAME
    # works by starting with name from query, finding CNAMEs for it,
    # adding these to set and finding next CNAMEs etc
    # if there are unconnected CNAMEs they will be left in %cname
    my @names = ($qname);
    while ( %cname ) {
	my @n = grep { defined $_ } delete @cname{@names} or last;
	push @names, map { lc($_) } @n;
    }
    if ( %cname ) {
	# Report but ignore - XXX should we TempError instead?
	$DEBUG && DEBUG( "unrelated CNAME records ".Dumper(\%cname));
    }

    # collect the RR for all valid names
    my @ans;
    for (@names) {
	my $rrs = delete $ans{$_} or next;
	push @ans,@$rrs;
    }
    if ( %ans ) {
	# answer records which don't match name from query or via CNAME
	# derived names
	# Report but ignore - XXX should we TempError instead?
	$DEBUG && DEBUG( "unrelated answer records for $qtype names=@names ".Dumper(\%ans));
    }

    if ( ! @ans and @names>1 ) {
	# according to RFC1034 all RR for the type should be put into
	# the answer section together with the CNAMEs
	# so if there are no RRs in this answer, we should assume, that
	# there will be no RRs at all
	$DEBUG && DEBUG( "no answer records for $qtype, but names @names" );
    }

    my ($sub,@arg) = @$callback;
    return $self->_next_process_cbrv(
	$sub->($self,$qtype,$rcode,\@ans,[ $dnsresp->additional ],@arg));
}

############################################################################
# return list of DNS queries which are still open
# Args: ($self)
# Returns: @dnsq
############################################################################
sub todo {
    return
	map { $_->{pkt} ? ($_->{pkt}):() }
	@{ shift->{cbq} }
}

############################################################################
# fill information in hash of final result
# Args: ($self)
############################################################################
sub _update_result_info {
    my Mail::SPF::Iterator $self = shift;
    my $h = $self->{result} or return;
    $h = $h->[2] or return;
    $h->{'client-ip'} = $self->{clientip4}
	? inet_ntoa($self->{clientip4})
	: inet_ntop(AF_INET6,$self->{clientip6});
    $h->{helo} = $self->{helo};
    $h->{identity} = $self->{identity};
    $h->{'envelope-from'} = "<$self->{sender}>" if $self->{sender};
}

############################################################################
# process results from callback to DNS reply, called from next
# Args: ($self,@rv)
#  @rv: result from callback, either
#       @query - List of new Net::DNS::Packet queries for next step
#       ()     - no result (go on with next step)
#       (status,...) - final response
# Returns: ... - see sub next
############################################################################
sub _next_process_cbrv {
    my Mail::SPF::Iterator $self = shift;
    my @rv = @_; # results from callback to _mech*

    # resolving of %{p} in exp= mod or explain TXT results in @rv = ()
    # see sub _validate_*
    if ( $self->{result} && ! @rv ) {
	# set to final result
	@rv = @{ $self->{result}};
    }

    # if the last mech (which was called with the DNS reply in sub next) got
    # no match and no further questions we need to find the match or questions
    # either by processing the next mech in the current SPF record, following
    # a redirect or going the include stack up
    @rv = $self->_next_mech if ! @rv;

    if ( UNIVERSAL::isa( $rv[0],'Net::DNS::Packet' )) {
	# @rv is list of DNS packets
	return $self->_next_rv_dnsq(@rv)
    }

    # @rv is (status,...)
    # status of SPF_Noop is special in that it returns nothing as a sign, that
    # it just waits for more input
    # Only used when we could get multiple responses, e.g when multiple DNS
    # requests were send like in the query for SPF+TXT
    if ( $rv[0] eq SPF_Noop ) {
	die "NOOP but no open queries"
	    if ! grep { $_->{pkt} } @{$self->{cbq}};
	return ('');
    }

    # inside include the response is only pre-final,
    # propagate it the include stack up:
    # see RFC4408, 5.2 for propagation of results
    while ( my $top = pop @{ $self->{include_stack} } ) {
	$DEBUG && DEBUG( "pre-final response $rv[0]" );

	if ( $rv[0] eq SPF_TempError || $rv[0] eq SPF_PermError ) {
	    # keep
	} elsif ( $rv[0] eq SPF_None ) {
	    $rv[0] = SPF_PermError; # change None to PermError
	} else {
	    # go stack up, restore saved data
	    my $qual = delete $top->{qual};
	    while ( my ($k,$v) = each %$top ) {
		$self->{$k} = $v;
	    }
	    if ( $rv[0] eq SPF_Pass ) {
		# Pass == match -> set status to $qual
		$rv[0] = $qual;
	    } else {
		# ! Pass == non-match
		# -> restart with @rv=() and go on with next mech
		@rv = $self->_next_mech;
		if ( UNIVERSAL::isa( $rv[0],'Net::DNS::Packet' )) {
		    # @rv is list of DNS packets
		    return $self->_next_rv_dnsq(@rv)
		}
	    }
	}
    }

    # no more include stack
    # -> @rv is the probably the final result, but check if we had a better
    # one already
    my $final;
    if ($self->{tmpresult} and
	$ResultQ{ $self->{tmpresult}[0] } > $ResultQ{ $rv[0] }) {
	$final = $self->{result} = $self->{tmpresult};
    } else {
	$final = $self->{result} = [ @rv ];
    }
    _update_result_info($self);

    # now the only things left is to handle explain in case of SPF_Fail
    return @$final if $final->[0] ne SPF_Fail; # finally done

    # set default explanation
    $final->[3] = $self->explain_default if ! defined $final->[3];

    # lookup TXT record for explain
    if ( my $exp = delete $self->{explain} ) {
	if (ref $exp) {
	    if ( my @dnsq = $self->_resolve_macro_p($exp)) {
		# we need to do more DNS lookups for resolving %{p} macros
		# inside the exp=... modifier, before we get the domain name
		# which contains the TXT for explain
		$DEBUG && DEBUG( "need to resolve %{p} in $exp->{macro}" );
		$self->{explain} = $exp; # put back until resolved
		return $self->_next_rv_dnsq(@dnsq)
	    }
	    $exp = $exp->{expanded};
	}
	if ( my @err = _check_domain( $exp, "explain:$exp" )) {
	    # bad domain: return unmodified final
	    return @$final;
	}
	$DEBUG && DEBUG( "lookup TXT for '$exp' for explain" );
	$self->{cb} = [ \&_got_TXT_exp ];
	return $self->_next_rv_dnsq( Net::DNS::Packet->new($exp,'TXT','IN'));
    }

    # resolve macros in TXT record for explain
    if ( my $exp = delete $final->[4] ) {
	# we had a %{p} to resolve in the TXT we got for explain,
	# see _got_TXT_exp -> should be expanded now
	$final->[3] = $exp->{expanded};

    }

    # This was the last action needed
    return @$final;
}

############################################################################
# try to match or give more questions by
# - trying the next mechanism in the current SPF record
# - if there is no next mech try to redirect to another SPF record
# - if there is no redirect try to go include stack up
# - if there is no include stack return SPF_Neutral
# Args: $self
# Returns: @query|@final
#   @query: new queries as list of Net::DNS::Packets
#   @final: final SPF result (see sub next)
############################################################################
sub _next_mech {
    my Mail::SPF::Iterator $self = shift;

    for my $dummy (1) {

	# if we have more mechanisms in the current SPF record take next
	if ( my $next = shift @{$self->{mech}} ) {
	    my ($sub,$id,@arg) = @$next;
	    my @rv = $sub->($self,@arg);
	    redo if ! @rv; # still no match and no queries
	    return @rv;
	}

	# if no mechanisms in current SPF record but we have a redirect
	# continue with the SPF record from the new location
	if ( my $domain = $self->{redirect} ) {
	    if ( ref $domain ) {
		# need to resolve %{p}
		if ( $domain->{macro} and
		    ( my @rv = $self->_resolve_macro_p($domain))) {
		    return @rv;
		}
		$self->{redirect} = $domain = $domain->{expanded};
	    }
	    if ( my @err = _check_domain($domain,"redirect:$domain" )) {
		 return @err;
	    }

	    return ( SPF_PermError, "",
		{ problem => "Number of DNS mechanism exceeded" })
		if --$self->{limit_dns_mech} < 0;

	    # reset state information
	    $self->{mech}     = [];
	    $self->{explain}  = undef;
	    $self->{redirect} = undef;

	    # set domain to domain from redirect
	    $self->{domain}   = $domain;

	    # restart with new SPF record
	    return $self->_query_txt_spf;
	}

	# if there are still no more mechanisms available and we are inside
	# an include go up the include stack
	my $st = $self->{include_stack};
	if (@$st) {
	    my $top = pop @$st;
	    delete $top->{qual};
	    while ( my ($k,$v) = each %$top ) {
		$self->{$k} = $v;
	    }
	    # continue with mech or redirect of upper SPF record
	    redo;
	}
    }

    # no mech, no redirect and no include stack
    # -> give up finally and return SPF_Neutral
    return ( SPF_Neutral,'no matches' );
}

############################################################################
# if @rv is list of DNS packets return them as (undef,@dnspkt)
# remember the queries so that the answers can later (sub next) verified
# against the queries
# Args: ($self,@dnsq)
#  @dnsq: list of Net::DNS::Packet's
# Returns: (undef,@dnsq)
############################################################################
sub _next_rv_dnsq {
    my Mail::SPF::Iterator $self = shift;
    my @dnsq = @_;
    # track queries for later verification
    $self->{cbq} = [ map {
	$_->header->rd(1); # make query recursive
	$_->encode if $NEED_ENCODE_BEFORE_ID;
	{ q => ($_->question)[0], id => $_->header->id, pkt => $_ }
    } @dnsq ];
    $DEBUG && DEBUG( "need to lookup ".join( " | ",
	map { "'".$_->{id}.'/'.$_->{q}->string."'" } @{$self->{cbq}}));
    return ( undef,@dnsq );
}

############################################################################
# check if the domain has the right format
# this checks the domain before the macros got expanded
############################################################################
sub _check_macro_domain {
    my ($domain,$why) = @_;
    # 'domain-spec': see RFC4408 Appendix A for ABNF
    my $rx = qr{
	# macro-string
	(?:
	    [^%\s]+ |
	    % (?: { [slodipvh] \d* r? [.\-+,/_=]* } | [%\-_] )
	)*
	# domain-end
	(?:(?:
	    # toplabel
	    \. [\da-z]*[a-z][\da-z]* |
	    \. [\da-z]+-[\-a-z\d]*[\da-z]
	) | (?:
	    # macro-expand
	    % (?: { [slodipvh] \d* r? [.\-+,/_=]* } | [%\-_] )
	))
    }xi;
    _check_domain( $domain,$why,$rx);
}

############################################################################
# check if the domain has the right format
# this checks the domain after the macros got expanded
############################################################################
sub _check_domain {
    my ($domain,$why,$rx) = @_;
    $why = '' if ! defined $why;

    # domain name according to RFC2181 can be anything binary!
    # this is not only for host names
    $rx ||= qr{.*?};

    my @rv;
    if ( $domain =~m{[^\d.]}
	&& $domain =~s{^($rx)\.?$}{$1} ) {
	# looks like valid domain name
	if ( grep { length == 0 || length>63 } split( m{\.},$domain,-1 )) {
	    @rv = ( SPF_PermError,"query $why", { problem =>
		"DNS labels limited to 63 chars and should not be empty." });
	} elsif ( length($domain)>253 ) {
	    @rv = ( SPF_PermError,"query $why",
		{ problem => "Domain names limited to 253 chars." });
	} else {
	    #DEBUG( "domain name ist OK" );
	    return
	}
    } else {
	@rv = ( SPF_PermError, "query $why",
	    { problem => "Invalid domain name" });
    }

    $DEBUG && DEBUG( "error with '$domain': ".$rv[2]{problem} );
    return @rv; # have error
}

############################################################################
# initial query
# returns queries for SPF and TXT record, next state is _got_txt_spf
############################################################################
sub _query_txt_spf {
    my Mail::SPF::Iterator $self = shift;
    $DEBUG && DEBUG( "want SPF/TXT for $self->{domain}" );
    # return query for SPF and TXT, we see what we get first
    if ( my @err = _check_domain( $self->{domain}, "SPF/TXT record" )) {
	if ( ! $self->{cb} ) {
	    # for initial query return SPF_None on errors
	    $err[0] = SPF_None;
	}
	return @err;
    }

    $self->{cb} = [ \&_got_txt_spf ];
    return (
	# use SPF DNS record only if rfc4408 compatibility is required
	$self->{opt}{rfc4408}
	    ? (scalar(Net::DNS::Packet->new( $self->{domain}, 'SPF','IN' ))):(),
	scalar(Net::DNS::Packet->new( $self->{domain}, 'TXT','IN' )),
    );
}

############################################################################
# processes response to SPF|TXT query
# parses response and starts processing
############################################################################
sub _got_txt_spf {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add) = @_;

    {
	last if ! @$ans;

	# RFC4408 says in 4.5:
	# 2. If any records of type SPF are in the set, then all records of
	#    type TXT are discarded.
	# But it says that if both SPF and TXT are given they should be the
	# same (3.1.1)
	# so I think we can ignore the requirement 4.5.2 and just use the
	# first record which is valid SPF, if the admin of the domain sets
	# TXT and SPF to different values it's his own problem

	my (@spfdata,@senderid);
	for my $rr (@$ans) {
	    my $txtdata = join( '', $rr->char_str_list );
	    $txtdata =~m{^
		(?:
		    (v=spf1)
		    | spf2\.\d/(?:[\w,]*\bmfrom\b[\w,]*)
		)
		(?:$|\040\s*)(.*)
	    }xi or next;
	    if ( $1 ) {
		push @spfdata,$2;
		$DEBUG && DEBUG( "got spf data for $qtype: $txtdata" );
	    } else {
		push @senderid,$2;
		$DEBUG && DEBUG( "got senderid data for $qtype: $txtdata" );
	    }
	}

	# if SenderID and SPF are given prefer SPF, else use any
	@spfdata = @senderid if ! @spfdata;

	@spfdata or last; # no usable SPF reply
	if (@spfdata>1) {
	    return ( SPF_PermError,
		"checking $qtype for $self->{domain}",
		{ problem => "multiple SPF records" }
	    );
	}
	unless ( eval { $self->_parse_spf( $spfdata[0] ) }) {
	    # this is an invalid SPF record
	    # make it a permanent error
	    # it does not matter if the other type of record is good
	    # because according to RFC if both provide SPF (v=spf1..)
	    # they should be the same, so the other one should be bad too
	    return ( SPF_PermError,
		"checking $qtype for $self->{domain}",
		{ problem => "invalid SPF record: $@" }
	    );
	}

	# looks good, return so that next() processes the next query
	return;
    }

    # If this is the first response, wait for the other
    $DEBUG && DEBUG( "no records for $qtype ($rcode)" );
    if ( grep { $_->{pkt} } @{ $self->{cbq}} ) {
	return (SPF_Noop);
    }

    # otherwise it means that we got no SPF or TXT records

    # if we have a default record and we are at the first level use this
    if (!$self->{mech} and my $default = $self->{opt}{default_spf}) {
	if (eval { $self->_parse_spf($default) }) {
	    # good
	    $self->{used_default_spf} = $default;
	    return;
	}
	return (SPF_PermError,
	    "checking default SPF for $self->{domain}",
	    { problem => "invalid default SPF record: $@" }
	);
    }

    # return SPF_None if this was the initial query ($self->{mech} is undef)
    # and SPF_PermError if as a result from redirect or include
    # ($self->{mech} is [])
    $DEBUG && DEBUG( "no usable SPF/TXT records" );
    return ( $self->{mech} ? SPF_PermError : SPF_None,
	'query SPF/TXT record',
	{ problem => 'no SPF records found' });
}


############################################################################
# parse SPF record, returns 1 if record looks valid,
# otherwise die()s with somewhat helpful error message
############################################################################
sub _parse_spf {
    my Mail::SPF::Iterator $self = shift;
    my $data = shift;

    my (@mech,$redirect,$explain);
    for ( split( ' ', $data )) {
	my ($qual,$mech,$mod,$arg) = m{^(?:
	    ([~\-+?]?) # Qualifier
	    (all|ip[46]|a|mx|ptr|exists|include)   # Mechanism
	    |(redirect|exp)   # Modifier
	    |[a-zA-Z][\w.\-]*=  # unknown modifier + '='
	)([ \t\x20-\x7e]*)  # Arguments
	$}x
	    or die "bad SPF part: $_\n";

	if ( $mech ) {
	    $qual = $qual2rv{ $qual || '+' };

	    if ( $mech eq 'all' ) {
		die "no arguments allowed with mechanism 'all': '$_'\n"
		    if $arg ne '';
		push @mech, [ \&_mech_all, $_, $qual ]

	    } elsif ( $mech eq 'ip4' ) {
		my ($ip,$plen) =
		    $arg =~m{^:(\d+\.\d+\.\d+\.\d+)(?:/([1-9]\d*|0))?$}
		    or die "bad argument for mechanism 'ip4' in '$_'\n";
		$plen = 32 if ! defined $plen;
		$plen>32 and die "invalid prefix len >32 in '$_'\n";
		eval { $ip = inet_aton( $ip ) }
		    or die "bad ip '$ip' in '$_'\n";
		next if ! $self->{clientip4}; # don't use for IP6
		push @mech, [ \&_mech_ip4, $_, $qual, $ip,$plen ];

	    } elsif ( $mech eq 'ip6' ) {
		my ($ip,$plen) =
		    $arg =~m{^:([\da-fA-F:\.]+)(?:/([1-9]\d*|0))?$}
		    or die "bad argument for mechanism 'ip6' in '$_'\n";
		$plen = 128 if ! defined $plen;
		$plen>128 and die "invalid prefix len >128 in '$_'\n";
		eval { $ip = inet_pton( AF_INET6,$ip ) }
		    or die "bad ip '$ip' in '$_'\n"
		    if $can_ip6;
		next if ! $self->{clientip6}; # don't use for IP4
		push @mech, [ \&_mech_ip6, $_, $qual, $ip,$plen ];

	    } elsif ( $mech eq 'a' or $mech eq 'mx' ) {
		$arg ||= '';
		my ($domain,$plen4,$plen6) =
		    $arg =~m{^
			(?: : (.+?))?                # [ ":" domain-spec ]
			(?: /  (?: ([1-9]\d*|0) ))?  # [ ip4-cidr-length ]
			(?: // (?: ([1-9]\d*|0) ))?  # [ "/" ip6-cidr-length ]
		    $}x or die "bad argument for mechanism '$mech' in '$_'\n";

		$plen4 = 32 if ! defined $plen4;
		$plen6 = 128 if ! defined $plen6;
		die "invalid prefix len >32 in '$_'\n" if $plen4>32;
		die "invalid prefix len >128 in '$_'\n" if $plen6>128;
		if ( ! $domain ) {
		    $domain = $self->{domain};
		} else {
		    if ( my @err = _check_macro_domain($domain)) {
			die(($err[2]->{problem}||"Invalid domain name")."\n");
		    }
		    $domain = $self->_macro_expand($domain);
		}
		my $sub = $mech eq 'a' ? \&_mech_a : \&_mech_mx;
		push @mech, [ \&_resolve_macro_p, $domain ] if ref($domain);
		push @mech, [ $sub, $_, $qual, $domain,
		    $self->{clientip4} ? $plen4:$plen6 ];

	    } elsif ( $mech eq 'ptr' ) {
		my ($domain) = ( $arg || '' )=~m{^(?::([^/]+))?$}
		    or die "bad argument for mechanism '$mech' in '$_'\n";
		$domain = $domain
		    ? $self->_macro_expand($domain)
		    : $self->{domain};
		push @mech, [ \&_resolve_macro_p, $_, $domain ] if ref($domain);
		push @mech, [ \&_mech_ptr, $_, $qual, $domain ];

	    } elsif ( $mech eq 'exists' ) {
		my ($domain) = ( $arg || '' )=~m{^:([^/]+)$}
		    or die "bad argument for mechanism '$mech' in '$_'\n";
		$domain = $self->_macro_expand($domain);
		push @mech, [ \&_resolve_macro_p, $_, $domain ] if ref($domain);
		push @mech, [ \&_mech_exists, $_, $qual, $domain ];

	    } elsif ( $mech eq 'include' ) {
		my ($domain) = ( $arg || '' )=~m{^:([^/]+)$}
		    or die "bad argument for mechanism '$mech' in '$_'\n";
		$domain = $self->_macro_expand($domain);
		push @mech, [ \&_resolve_macro_p, $_, $domain ] if ref($domain);
		push @mech, [ \&_mech_include, $_, $qual, $domain ];

	    } else {
		die "unhandled mechanism '$mech'\n"
	    }

	} elsif ( $mod ) {
	    # multiple redirect or explain will be considered an error
	    if ( $mod eq 'redirect' ) {
		die "redirect was specified more than once\n" if $redirect;
		my ($domain) = ( $arg || '' )=~m{^=([^/]+)$}
		    or die "bad argument for modifier '$mod' in '$_'\n";
		if ( my @err = _check_macro_domain($domain)) {
		    die(( $err[2]->{problem} || "Invalid domain name" )."\n" );
		}
		$redirect = $self->_macro_expand($domain);

	    } elsif ( $mod eq 'exp' ) {
		die "$explain was specified more than once\n" if $explain;
		my ($domain) = ( $arg || '' )=~m{^=([^/]+)$}
		    or die "bad argument for modifier '$mod' in '$_'\n";
		if ( my @err = _check_macro_domain($domain)) {
		    die(( $err[2]->{problem} || "Invalid domain name" )."\n" );
		}
		$explain = $self->_macro_expand($domain);

	    } elsif ( $mod ) {
		die "unhandled modifier '$mod'\n"
	    }
	} else {
	    # unknown modifier - check if arg is valid macro-string
	    # (will die() on error) but ignore modifier
	    $self->_macro_expand($arg || '');
	}
    }

    if ($self->{opt}{pass_all}) {
	my $r = 0;
	for (@mech) {
	    my $qual = $_->[2];
	    last if $_->[0] == \&_mech_include;
	    $r=-1,last if $qual eq SPF_Fail;
	    $r=+1,last if $qual eq SPF_Pass and $_->[0] == \&_mech_all;
	}
	if ($r == 1) {
	    # looks like a pass all rule
	    $self->{result} = [
		$self->{opt}{pass_all}, "",
		{ problem => "record designed to allow every sender" }
	    ];
	    _update_result_info($self);
	}
    }
    $self->{mech} = \@mech;
    $self->{explain} = $explain;
    $self->{redirect} = $redirect;
    return 1;
}

############################################################################
# handles mechanism 'all'
# matches all time
############################################################################
sub _mech_all {
    my Mail::SPF::Iterator $self = shift;
    my $qual = shift;
    $DEBUG && DEBUG( "match mech all with qual=$qual" );
    return ( $qual,'matches default', { mechanism => 'all' });
}

############################################################################
# handle mechanism 'ip4'
# matches if clients IP4 address is in ip/mask
############################################################################
sub _mech_ip4 {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$ip,$plen) = @_;
    defined $self->{clientip4} or return (); # ignore rule, no IP4 address
    if ( ($self->{clientip4} & $mask4[$plen]) eq ($ip & $mask4[$plen]) ) {
	# rules matches
	$DEBUG && DEBUG( "match mech ip4:".inet_ntoa($ip)."/$plen with qual=$qual" );
	return ($qual,"matches ip4:".inet_ntoa($ip)."/$plen",
	    { mechanism => 'ip4' } )
    }
    $DEBUG && DEBUG( "no match mech ip4:".inet_ntoa($ip)."/$plen" );
    return (); # ignore, no match
}

############################################################################
# handle mechanism 'ip6'
# matches if clients IP6 address is in ip/mask
############################################################################
sub _mech_ip6 {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$ip,$plen) = @_;
    defined $self->{clientip6} or return (); # ignore rule, no IP6 address
    if ( ($self->{clientip6} & $mask6[$plen]) eq ($ip & $mask6[$plen])) {
	# rules matches
	$DEBUG && DEBUG( "match mech ip6:".inet_ntop(AF_INET6,$ip)."/$plen with qual=$qual" );
	return ($qual,"matches ip6:".inet_ntop(AF_INET6,$ip)."/$plen",
	    { mechanism => 'ip6' } )
    }
    $DEBUG && DEBUG( "no match ip6:".inet_ntop(AF_INET6,$ip)."/$plen" );
    return (); # ignore, no match
}

############################################################################
# handle mechanism 'a'
# check if one of the A/AAAA records for $domain resolves to
# clientip/plen,
############################################################################
sub _mech_a {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$domain,$plen) = @_;
    $domain = $domain->{expanded} if ref $domain;
    $DEBUG && DEBUG( "check mech a:$domain/$plen with qual=$qual" );
    if ( my @err = _check_domain($domain, "a:$domain/$plen")) {
	# spec is not clear here:
	# variante1: no match on invalid domain name -> return
	# variante2: propagate err -> return @err
	# we use variante2 for now
	$DEBUG && DEBUG( "no match mech a:$domain/$plen - @err" );
	return @err;
    }

    return ( SPF_PermError, "",
	{ problem => "Number of DNS mechanism exceeded" })
	if --$self->{limit_dns_mech} < 0;

    my $typ = $self->{clientip4} ? 'A':'AAAA';
    $self->{cb} = [ \&_got_A, $qual,$plen,[ $domain ],'a' ];
    return scalar(Net::DNS::Packet->new( $domain, $typ,'IN' ));
}

############################################################################
# this is used in _mech_a and in _mech_mx if the address for an MX is not
# sent inside the additional data
# in the case of MX $names might contain more than one name to resolve, it
# will try to resolve names to addresses and to match them until @$names
# is empty
############################################################################
sub _got_A {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add,$qual,$plen,$names,$mech) = @_;
    my $domain = shift(@$names);

    $DEBUG && DEBUG( "got response to $qtype for $domain: $rcode" );
    if ( $rcode eq 'NXDOMAIN' ) {
	$DEBUG && DEBUG( "no match mech a:$domain/$plen - $rcode" );
	# no records found
    } elsif ( $rcode ne 'NOERROR' ) {
	$DEBUG && DEBUG( "temperror mech a:$domain/$plen - $rcode" );
	return ( SPF_TempError,
	    "getting $qtype for $domain",
	    { problem => "error resolving $domain" }
	);
    }

    my @addr = map { $_->address } @$ans;
    return _check_A_match($self,$qual,$domain,$plen,\@addr,$names,$mech);
}

sub _check_A_match {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$domain,$plen,$addr,$names,$mech) = @_;

    # process all found addresses
    if ( $self->{clientip4} ) {
	$plen = 32 if ! defined $plen;
	my $mask = $mask4[$plen];
	for my $addr (@$addr) {
	    $DEBUG && DEBUG( "check a:$domain($addr)/$plen for mech $mech" );
	    my $packed = $addr=~m{^[\d.]+$} && eval { inet_aton($addr) }
		or return ( SPF_TempError,
		    "getting A for $domain",
		    { problem => "bad address in A record" }
		);

	    if ( ($packed & $mask) eq  ($self->{clientip4} & $mask) ) {
		# match!
		$DEBUG && DEBUG( "match mech a:.../$plen for mech $mech with qual $qual" );
		return ($qual,"matches domain: $domain/$plen with IP4 $addr",
		    { mechanism => $mech })
	    }
	}
    } else { # AAAA
	$plen = 128 if ! defined $plen;
	my $mask = $mask6[$plen];
	for my $addr (@$addr) {
	    $DEBUG && DEBUG( "check a:$domain($addr)//$plen for mech $mech" );
	    my $packed = eval { inet_pton(AF_INET6,$addr) }
		or return ( SPF_TempError,
		    "getting AAAA for $domain",
		    { problem => "bad address in AAAA record" }
		);
	    if ( ($packed & $mask) eq ($self->{clientip6} & $mask) ) {
		# match!
		$DEBUG && DEBUG( "match mech a:...//$plen for mech $mech with qual $qual" );
		return ($qual,"matches domain: $domain//$plen with IP6 $addr",
		    { mechanism => $mech })
	    }
	}
    }

    # no match yet, can we resolve another name?
    if ( @$names ) {
	my $typ = $self->{clientip4} ? 'A':'AAAA';
	$DEBUG && DEBUG( "check mech a:$names->[0]/$plen for mech $mech with qual $qual" );
	$self->{cb} = [ \&_got_A, $qual,$plen,$names,$mech ];
	return scalar(Net::DNS::Packet->new( $names->[0], $typ,'IN' ));
    }

    # finally no match
    $DEBUG && DEBUG( "no match mech $mech:$domain/$plen" );
    return;
}



############################################################################
# handle mechanism 'mx'
# similar to mech 'a', we expect the A/AAAA records for the MX in the
# additional section of the DNS response
############################################################################
sub _mech_mx {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$domain,$plen) = @_;
    $domain = $domain->{expanded} if ref $domain;
    if ( my @err = _check_domain($domain,
	"mx:$domain".( defined $plen ? "/$plen":"" ))) {
	$DEBUG && DEBUG( "no mech mx:$domain/$plen - @err" );
	return @err
    }

    return ( SPF_PermError, "",
	{ problem => "Number of DNS mechanism exceeded" })
	if --$self->{limit_dns_mech} < 0;

    $self->{cb} = [ \&_got_MX,$qual,$domain,$plen ];
    return scalar(Net::DNS::Packet->new( $domain, 'MX','IN' ));
}

sub _got_MX {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add,$qual,$domain,$plen) = @_;

    if ( $rcode eq 'NXDOMAIN' ) {
	$DEBUG && DEBUG( "no match mech mx:$domain/$plen - $rcode" );
	# no records found
    } elsif ( $rcode ne 'NOERROR' ) {
	$DEBUG && DEBUG( "no match mech mx:$domain/$plen - $rcode" );
	return ( SPF_TempError,
	    "getting MX form $domain",
	    { problem => "error resolving $domain" }
	);
    } elsif ( ! @$ans ) {
	$DEBUG && DEBUG( "no match mech mx:$domain/$plen - no MX records" );
	return; # domain has no MX -> no match
    }

    # all MX, with best (lowest) preference first
    my @mx = map { $_->[0] }
	sort { $a->[1] <=> $b->[1] }
	map { [ $_->exchange, $_->preference ] }
	@$ans;
    my %mx = map { $_ => [] } @mx;

    if (!$self->{opt}{rfc4408}) {
	# RFC 4408 limited the number of MX to query to 10
	# RFC 7208 instead said that ALL returned MX should count
	# against the limit and the test suite suggest that this limit
	# should be enforced before even asking the MX
	return ( SPF_PermError, "",
	    { problem => "Number of DNS mechanism exceeded" })
	    if $self->{limit_dns_mech}-@mx < 0;
    }

    # try to find A|AAAA records in additional data
    my $atyp = $self->{clientip4} ? 'A':'AAAA';
    for my $rr (@$add) {
	if ( $rr->type eq $atyp && exists $mx{$rr->name} ) {
	    push @{$mx{$rr->name}},$rr->address;
	}
    }
    $DEBUG && DEBUG( "found mx for $domain: ".join( " ",
	map { $mx{$_} ? "$_(".join(",",@{$mx{$_}}).")" : $_ } @mx ));

    # remove from @mx where I've found addresses
    @mx = grep { ! @{$mx{$_}} } @mx;
    # limit the Rest to 10 records (rfc4408,10.1)
    splice(@mx,10) if @mx>10;

    my @addr = map { @$_ } values %mx;
    return _check_A_match( $self,$qual,"(mx)".$domain,$plen,\@addr,\@mx,'mx');
}

############################################################################
# handle mechanis 'exists'
# just check, if I get any A record for the domain (lookup for A even if
# I use IP6 - this is RBL style)
############################################################################
sub _mech_exists {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$domain) = @_;
    $domain = $domain->{expanded} if ref $domain;
    if ( my @err = _check_domain($domain, "exists:$domain" )) {
	$DEBUG && DEBUG( "no match mech exists:$domain - @err" );
	return @err
    }

    return ( SPF_PermError, "",
	{ problem => "Number of DNS mechanism exceeded" })
	if --$self->{limit_dns_mech} < 0;

    $self->{cb} = [ \&_got_A_exists,$qual,$domain ];
    return scalar(Net::DNS::Packet->new( $domain, 'A','IN' ));
}

sub _got_A_exists {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add,$qual,$domain) = @_;

    if ( $rcode ne 'NOERROR' ) {
	$DEBUG && DEBUG( "no match mech exists:$domain - $rcode" );
	return;
    } elsif ( ! @$ans ) {
	$DEBUG && DEBUG( "no match mech exists:$domain - no A records" );
	return;
    }
    $DEBUG && DEBUG( "match mech exists:$domain with qual $qual" );
    return ($qual,"domain $domain exists", { mechanism => 'exists' } )
}



############################################################################
# PTR
# this is the most complex and most expensive mechanism:
# - first get domains from PTR records for IP (clientip4|clientip6)
# - filter for domains which match $domain (because only these are interesting
#   for matching)
# - then verify the domains, if they point back to the IP by doing A|AAAA
#   lookups until one domain can be validated
############################################################################
sub _mech_ptr {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$domain) = @_;
    $domain = $domain->{expanded} if ref $domain;
    if ( my @err = _check_domain($domain, "ptr:$domain" )) {
	$DEBUG && DEBUG( "no match mech ptr:$domain - @err" );
	return @err
    }

    return ( SPF_PermError, "",
	{ problem => "Number of DNS mechanism exceeded" })
	if --$self->{limit_dns_mech} < 0;

    my $ip = $self->{clientip4} || $self->{clientip6};
    if ( exists $self->{validated}{$ip}{$domain} ) {
	# already checked
	if ( ! $self->{validated}{$ip}{$domain} ) {
	    # could not be validated
	    $DEBUG && DEBUG( "no match mech ptr:$domain - cannot validate $ip/$domain" );
	    return; # ignore
	} else {
	    $DEBUG && DEBUG( "match mech ptr:$domain with qual $qual" );
	    return ($qual,"$domain validated" );
	}
    }

    my $query;
    if ( $self->{clientip4} ) {
	$query = join( '.', reverse split( m/\./,
	    inet_ntoa($self->{clientip4}) ))
	    .'.in-addr.arpa'
    } else {
	$query = join( '.', split( //,
	    reverse unpack("H*",$self->{clientip6}) ))
	    .'.ip6.arpa';
    }

    $self->{cb} = [ \&_got_PTR,$qual,$query,$domain ];
    return scalar(Net::DNS::Packet->new( $query, 'PTR','IN' ));
}

sub _got_PTR {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add,$qual,$query,$domain) = @_;

    # ignore mech if it can not be validated
    $rcode eq 'NOERROR' or do {
	$DEBUG && DEBUG( "no match mech ptr:$domain - $rcode" );
	return;
    };
    my @names = map { $_->ptrdname } @$ans or do {
	$DEBUG && DEBUG( "no match mech ptr:$domain - no names in PTR lookup" );
	return;
    };

    # strip records, which do not end in $domain
    @names = grep { $_ eq $domain || m{\.\Q$domain\E$} } @names;
    if ( ! @names ) {
	$DEBUG && DEBUG( "no match mech ptr:$domain - no names in PTR lookup match $domain" );
	# return if no matches inside $domain
	return;
    }

    # limit to no more then 10 names (see RFC4408, 10.1)
    splice(@names,10) if @names>10;

    # validate the rest by looking up the IP and verifying it
    # with the original IP (clientip)
    my $typ = $self->{clientip4} ? 'A':'AAAA';

    $self->{cb} = [ \&_got_A_ptr, $qual,\@names ];
    return scalar(Net::DNS::Packet->new( $names[0], $typ,'IN' ));
}

sub _got_A_ptr {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add,$qual,$names) = @_;

    for my $dummy ( $rcode eq 'NOERROR' ? (1):() ) {
	@$ans or last; # no addr for domain? - try next
	my @addr = map { $_->address } @$ans;

	# check if @addr contains clientip
	my ($match,$ip);
	if ( $ip = $self->{clientip4} ) {
	    for(@addr) {
		m{^[\d\.]+$} or next;
		eval { inet_aton($_) } eq $ip or next;
		$match = 1;
		last;
	    }
	} else {
	    $ip = $self->{clientip6};
	    for(@addr) {
		eval { inet_pton(AF_INET6,$_) } eq $ip or next;
		$match = 1;
		last;
	    }
	}

	# cache verification status
	$self->{validated}{$ip}{$names->[0]} = $match;

	# return $qual if we have verified the ptr
	if ($match) {
	    $DEBUG && DEBUG( "match mech ptr:... with qual $qual" );
	    return ( $qual,"verified clientip with ptr", { mechanism => 'ptr' })
	}
    }

    # try next
    shift @$names;
    @$names or do {
	# no next
	$DEBUG && DEBUG( "no match mech ptr:... - no more names for clientip" );
	return;
    };

    # cb stays the same
    return scalar(Net::DNS::Packet->new( $names->[0], $qtype,'IN' ));
}


############################################################################
# mechanism include
# include SPF from other domain, propagate errors and consider Pass
# from this inner SPF as match for the include mechanism
############################################################################
sub _mech_include {
    my Mail::SPF::Iterator $self = shift;
    my ($qual,$domain) = @_;
    $domain = $domain->{expanded} if ref $domain;
    if ( my @err = _check_domain($domain, "include:$domain" )) {
	$DEBUG && DEBUG( "failed mech include:$domain - @err" );
	return @err
    }

    $DEBUG && DEBUG( "mech include:$domain with qual=$qual" );

    return ( SPF_PermError, "",
	{ problem => "Number of DNS mechanism exceeded" })
	if --$self->{limit_dns_mech} < 0;

    # push and reset current domain and SPF record
    push @{$self->{include_stack}}, {
	domain   => $self->{domain},
	mech     => $self->{mech},
	explain  => $self->{explain},
	redirect => $self->{redirect},
	qual     => $qual,
    };
    $self->{domain}   = $domain;
    $self->{mech}     = [];
    $self->{explain}  = undef;
    $self->{redirect} = undef;

    # start with new SPF record
    return $self->_query_txt_spf;
}


############################################################################
# create explain message from TXT record
############################################################################
sub _got_TXT_exp {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add) = @_;
    my $final = $self->{result};

    if ( $rcode ne 'NOERROR' ) {
	$DEBUG && DEBUG( "DNS error for exp TXT lookup" );
	# just return the final rv
	return @$final;
    }

    my ($txtdata,$t2) = grep { length } map { $_->txtdata } @$ans;;
    if ( $t2 ) {
	# only one record should be returned
	$DEBUG && DEBUG( "got more than one TXT -> error" );
	return @$final;
    } elsif ( ! $txtdata ) {
	$DEBUG && DEBUG( "no text in TXT for explain" );
	return @$final;
    }

    $DEBUG && DEBUG( "got TXT $txtdata" );

    # valid TXT record found -> expand macros
    my $exp = eval { $self->_macro_expand( $txtdata,'exp' ) };
    if ($@) {
	$DEBUG && DEBUG( "macro expansion of '$txtdata' failed: $@" );
	return @$final;
    }

    # explain
    if (ref $exp) {
	if ( my @xrv = $self->_resolve_macro_p($exp)) {
	    # we need to do more DNS lookups for resolving %{p} macros
	    $DEBUG && DEBUG( "need to resolve %{p} in $exp->{macro}" );
	    $final->[4] = $exp;
	    return @xrv;
	}
	$exp = $exp->{expanded};
    }

    # result should be limited to US-ASCII!
    # further limit to printable chars
    $final->[3] = $exp if $exp !~m{[\x00-\x1f\x7e-\xff]};

    return @$final;
}

############################################################################
# expand Macros
############################################################################
sub _macro_expand {
    my Mail::SPF::Iterator $self = shift;
    my ($domain,$explain) = @_;
    my $new_domain = '';
    my $mchars = $explain ? qr{[slodipvhcrt]}i : qr{[slodipvh]}i;
    my $need_validated;
    #DEBUG( Carp::longmess("no domain" )) if ! $domain;
    #DEBUG( "domain=$domain" );
    while ( $domain =~ m{\G (?:
	([^%]+) |                                   # text
	%(?:
	    ([%_\-]) |                              # char: %_, %-, %%
	    {
		# macro: l1r+- ->  (l)(1)(r)(+-)
		($mchars) (\d*)(r?) ([.\-+,/_=]*)
	    } |
	    (.|$)                                   # bad char
	))}xg ) {
	my ($text,$char,$macro,$macro_n,$macro_r,$macro_delim,$bad)
	    = ($1,$2,$3,$4,$5,$6,$7);

	if ( defined $text ) {
	    $new_domain .= $text;

	} elsif ( defined $char ) {
	    $new_domain .=
		$char eq '%' ? '%' :
		$char eq '_' ? ' ' :
		'%20'

	} elsif ( $macro ) {
	    $macro_delim ||= '.';
	    my $imacro = lc($macro);
	    my $expand =
		$imacro eq 's' ? $self->{sender} :
		$imacro eq 'l' ?  $self->{sender} =~m{^([^@]+)\@}
		    ? $1 : 'postmaster' :
		$imacro eq 'o' ? $self->{sender} =~m{\@(.*)}
		    ? $1 : $self->{sender} :
		$imacro eq 'd' ? $self->{domain} :
		$imacro eq 'i' ? $self->{clientip4} ?
		    inet_ntoa($self->{clientip4}) :
		    join('.',map { uc } split(//,
			unpack( "H*",$self->{clientip6}))) :
		$imacro eq 'v' ? $self->{clientip4} ? 'in-addr' : 'ip6':
		$imacro eq 'h' ? $self->{helo} :
		$imacro eq 'c' ? $self->{clientip4} ?
		    inet_ntoa($self->{clientip4}) :
		    inet_ntop(AF_INET6,$self->{clientip6}) :
		$imacro eq 'r' ? $self->{myname} || 'unknown' :
		$imacro eq 't' ? time() :
		$imacro eq 'p' ? do {
		    my $ip = $self->{clientip4} || $self->{clientip6};
		    my $v = $self->{validated}{$ip};
		    my $d = $self->{domain};
		    if ( ! $v ) {
			# nothing validated pointing to IP
			$need_validated = { ip => $ip, domain => $d };
			'unknown'
		    } elsif ( $v->{$d} ) {
			# <domain> itself is validated
			$d;
		    } elsif ( my @xd = grep { $v->{$_} } keys %$v ) {
			if ( my @sd = grep { m{\.\Q$d\E$} } @xd ) {
			    # subdomain if <domain> is validated
			    $sd[0]
			} else {
			    # any other domain pointing to IP
			    $xd[0]
			}
		    } else {
			'unknown'
		    }
		} :
		die "unknown macro $macro\n";

	    my $rx = eval "qr{[$macro_delim]}";
	    my @parts = split( $rx, $expand );
	    @parts = reverse @parts if $macro_r;
	    if ( length $macro_n ) {
		die "bad macro definition '$domain'\n"
		    if ! $macro_n; # must be != 0
		@parts = splice( @parts,-$macro_n ) if @parts>$macro_n;
	    }
	    if ( $imacro ne $macro ) {
		# upper case - URI escape
		@parts = map { uri_escape($_) } @parts;
	    }
	    $new_domain .= join('.',@parts);

	} else {
	    die "bad macro definition '$domain'\n";
	}
    }

    if ( ! $explain ) {
	# should be less than 253 bytes
	while ( length($new_domain)>253 ) {
	    $new_domain =~s{^[^.]*\.}{} or last;
	}
	$new_domain = '' if length($new_domain)>253;
    }

    if ( $need_validated ) {
	return { expanded => $new_domain, %$need_validated, macro => $domain }
    } else {
	return $new_domain;
    }
}

############################################################################
# resolve macro %{p}, e.g. find validated domain name for IP and replace
# %{p} with it. This has many thing similar with the ptr: method
############################################################################
sub _resolve_macro_p {
    my Mail::SPF::Iterator $self = shift;
    my $rec = shift;
    my $ip = ref($rec) && $rec->{ip} or return; # nothing to resolve

    # could it already be resolved w/o further lookups?
    my $d = eval { $self->_macro_expand( $rec->{macro} ) };
    if ( ! ref $d ) {
	%$rec = ( expanded => $d ) if ! $@;
	return;
    }

    my $query;
    if ( length($ip) == 4 ) {
	$query = join( '.', reverse split( m/\./,
	    inet_ntoa($ip) )) .'.in-addr.arpa'
    } else {
	$query = join( '.', split( //,
	    reverse unpack("H*",$ip) )) .'.ip6.arpa';
    }

    $self->{cb} = [ \&_validate_got_PTR, $rec ];
    return scalar(Net::DNS::Packet->new( $query, 'PTR','IN' ));
}

sub _validate_got_PTR {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add,$rec ) = @_;

    # no validation possible if no records
    return if $rcode ne 'NOERROR' or ! @$ans;

    my @names = map { lc($_->ptrdname) } @$ans;

    # prefer records, which are $domain or end in $domain
    if ( my $domain = $rec->{domain} ) {
	unshift @names, grep { $_ eq $domain } @names;
	unshift @names, grep { m{\.\Q$domain\E$} } @names;
	{ my %n; @names = grep { !$n{$_}++ } @names } # uniq
    }

    # limit to no more then 10 names (RFC4408, 10.1)
    splice(@names,10) if @names>10;

    # validate the rest by looking up the IP and verifying it
    # with the original IP (clientip)
    my $typ = length($rec->{ip}) == 4 ? 'A':'AAAA';

    $self->{cb} = [ \&_validate_got_A_ptr, $rec,\@names ];
    return scalar(Net::DNS::Packet->new( $names[0], $typ,'IN' ));
}

sub _validate_got_A_ptr {
    my Mail::SPF::Iterator $self = shift;
    my ($qtype,$rcode,$ans,$add,$rec,$names) = @_;

    if ( $rcode eq 'NOERROR' ) {
	my @addr = map { $_->address } @$ans or do {
	    # no addr for domain? -> ignore - maybe
	    # the domain only provides the other kind of records?
	    return;
	};

	# check if @addr contains clientip
	my $match;
	my $ip = $rec->{ip};
	if ( length($ip) == 4 ) {
	    for(@addr) {
		m{^[\d\.]+$} or next;
		eval { inet_aton($_) } eq $ip or next;
		$match = 1;
		last;
	    }
	} else {
	    for(@addr) {
		eval { inet_pton(AF_INET6,$_) } eq $ip or next;
		$match = 1;
		last;
	    }
	}

	# cache verification status
	$self->{validated}{$ip}{$names->[0]} = $match;

	# expand macro if we have verified the ptr
	if ( $match ) {
	    if ( my $t = eval { $self->_macro_expand( $rec->{macro} ) }) {
		%$rec = ( expanded => $t );
	    }
	    return;
	}
    }

    # try next
    shift @$names;
    @$names or return; # no next

    # cb stays the same
    return scalar(Net::DNS::Packet->new( $names->[0], $qtype,'IN' ));
}


1;
