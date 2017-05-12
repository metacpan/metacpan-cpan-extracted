package Mail::DMARC::opendmarc;

use 5.010000;
use strict;
use warnings;
use Carp;
use File::ShareDir;
#use Switch;

our $DEBUG = 0;

require Exporter;
use XSLoader;


my $_symbols_present = 0;
my $_tld_file;

BEGIN {
	
	our $VERSION = '0.11';
	
    eval {
		require Mail::DMARC::opendmarc::Constants::C::Symbols;
	};
    $_symbols_present = 1 unless $@;

    eval {
		require Mail::DMARC::opendmarc::Constants::C::ForwardDecls;
	};
	
	# Need to load XS here to call library_init function
	XSLoader::load ('Mail::DMARC::opendmarc', $VERSION);


	#print "TLD file is " . File::ShareDir::module_dir('Mail::DMARC::opendmarc') . '/effective_tld_names.dat';
	$_tld_file = File::ShareDir::dist_dir('Mail-DMARC-opendmarc') . '/effective_tld_names.dat';
	
	#print "$INC{'Mail/DMARC/opendmarc'}/effective_tld_names\.dat\n";
	my $ret = opendmarc_policy_library_init_tld($_tld_file);
	# TODO somehow let this see the defined constants
	croak "Failed to initialize libopendmarc: $ret\n" unless ($ret == 0);
	
}

END {
	opendmarc_policy_library_shutdown_tld($_tld_file);
}



# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::DMARC::opendmarc ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT_OK = (
	
                $_symbols_present ? @Mail::DMARC::opendmarc::Constants::C::Symbols::ALL
                                  : (),
);

use AutoLoader;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Mail::DMARC::opendmarc::constant not defined" if $constname eq 'constant'
;
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
		no warnings;
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}




# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::DMARC::opendmarc - Perl extension wrapping OpenDMARC's libopendmarc library

=head1 SYNOPSIS

  use Mail::DMARC::opendmarc;

  my $dmarc = Mail::DMARC::opendmarc->new();

  # Get spf and dkim auth results from Authentication-Results (RFC5451) header
  # Store them into the dmarc object together with from domain and let object
  # query DNS too
  $dmarc->query_and_store_auth_results(
        'mlu.contactlab.it',  # From: domain
        'example.com',  # envelope-from domain
        Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_NONE, # SPF check result
        'neutral', # human-readable SPF check result
        'mlu.contactlab.it', # DKIM domain
        Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS, # DKIM check result
        'ok' # human-readable DKIM check result
		);
		
  my $result = $dmarc->verify();
  
  # result is a hashref with the following attributes:
  #		'spf_alignment' 
  #		'dkim_alignment'
  #		'policy'
  #		'human_policy' 
  #		'utilized_domain'

  print "DMARC check result: " . $result->{human_policy} . "\n";
  print "DMARC domain used for policy evaluation: " . $result->{utilized_domain} . "\n";
  (warning: utilized_domain is only reliable if you have libopendmarc 1.1.3+)
  
  # Diagnostic output of internal libopendmarc structure via this handy function:
  print $dmarc->dump_policy() if ($debug);
  # Use it often. Side-effects on the library's internal structure might
  # interfere if you're trying to optimize call sequences.
  
  if ($result->{policy} == Mail::DMARC::opendmarc::DMARC_POLICY_PASS)
		...

=head1 DESCRIPTION

A very thin layer wrapping Trusted Domain Project's libopendmarc.
Please refer to http://www.trusteddomain.org/opendmarc.html for more information on opendmarc

Look into the test suite for more usage examples.

=head2 METHODS

=head3 Basic housekeeping

=item new

	# $dmarc will hold a reference to a Mail::DMARC::opendmarc instance
	my $dmarc = Mail::DMARC::opendmarc->new();
	
Initializes a new object to interact with libopendmarc


=cut

sub new {
	my $class = shift;
	my $ip_addr = shift || 'localhost';

	my $self = {};
	bless $self, $class;

	# TODO add IPv6 support
	
	$self->{policy_t} = Mail::DMARC::opendmarc::opendmarc_policy_connect_init($ip_addr,4);
	$self->{policy_loaded} = undef;

	die "Unable to initialize policy object" unless defined($self->{policy_t});
	
	return $self;
}

=item DESTROY

Performs libopendmarc cleanup when objects goes out of scope. Automatically invoked by Perl as needed.

=cut

sub DESTROY {
	my $self = shift;

	Mail::DMARC::opendmarc::opendmarc_policy_connect_shutdown($self->{policy_t}) if defined($self->{policy});
	warn "Destructor called for $self" if $DEBUG;
}

# Accessors

sub policy_loaded {
	my $self = shift;
	my $val = shift;
	return ($self->{policy_loaded} = $val) if (defined($val));
	return $self->{policy_loaded};
}

sub valid {
	my $self = shift;
	my $val = shift;
	return ($self->{valid} = $val) if (defined($val));
	return $self->{valid};
}

sub policy_t {
	my $self = shift;
	return $self->{policy_t};
}

=head3 Utility methods


=item policy_status_to_str

Wraps: opendmarc_policy_status_to_str.
Returns a human-readable string for libopendmarc status codes (OPENDMARC_STATUS_T)

	# Will print "Success. No errors"
	print $dmarc->policy_status_to_str(0);

=cut

sub policy_status_to_str {
	my $self = shift;
	my $status = shift;

	return Mail::DMARC::opendmarc::opendmarc_policy_status_to_str($status);
}

=item dump_policy

Wraps opendmarc_policy_to_buf.
Dumps the values of libopendmarc's DMARC_POLICY_T opaque struct, the per-message library context.
Useful for debugging and learning DMARC.

=cut


sub dump_policy {
	my $self = shift;
	return Mail::DMARC::opendmarc::opendmarc_policy_to_buf($self->policy_t);
}

=head3 DMARC policy retrieval / parsing

=item query

Performs a DNS lookup for $domain's DMARC policy.
Initializes the object's internal structure for later handling.
Returns a status code (0 is success - see policy_status_to_str)

	my $rcode = $dmarc->query('example.com');

=cut

sub query {
	my $self = shift;
	my $domain = shift;

	$self->policy_loaded(undef);
	$self->{policy_t} = Mail::DMARC::opendmarc::opendmarc_policy_connect_rset($self->{policy_t});
	return Mail::DMARC::opendmarc::DMARC_PARSE_ERROR_NULL_CTX unless defined($self->{policy_t});

	my $ret = Mail::DMARC::opendmarc::opendmarc_policy_query_dmarc($self->{policy_t}, $domain);
	$self->policy_loaded(1) if ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY);
	return $ret;
}

=item store

Wraps: opendmarc_policy_store_dmarc
Stores a DMARC policy and initializes the object's internal structure for later handling.
Doesn't perform DNS queries to retrieve the DMARC policy - you pass the domain, policy record
and organization domain to store (and parse).
Returns a status code (0 is success - see policy_status_to_str)

	my $rcode = $dmarc->store($dmarc_policy_record, $domain, $organizational_domain);
	my $rcode = $dmarc->store('v=DMARC1;p=none','mail.example.com','example.com');

=cut


sub store {
	my $self = shift;
	my $record = shift;
	my $domain = shift;
	my $organizational_domain = shift;

	$self->policy_loaded(undef);
	$self->{policy_t} = Mail::DMARC::opendmarc::opendmarc_policy_connect_rset($self->{policy_t});
	return Mail::DMARC::opendmarc::DMARC_PARSE_ERROR_NULL_CTX unless defined($self->{policy_t});

	my $ret = Mail::DMARC::opendmarc::opendmarc_policy_store_dmarc($self->{policy_t}, $record, $domain, $organizational_domain);
	$self->policy_loaded(1) if ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY);
	return $ret;
}

=item parse

Wraps: opendmarc_policy_parse_dmarc
Parses a DMARC policy and initializes the object's internal structure for later handling.
Doesn't perform DNS queries to retrieve the DMARC policy - you pass the policy to parse.
You should use store() instead of parse().
Returns a status code (0 is success - see policy_status_to_str)

	my $rcode = $dmarc->parse($domain, $dmarc_policy_record);
	my $rcode = $dmarc->parse('example.com', 'v=DMARC1;p=none");

=cut

sub parse {
	my $self = shift;
	my $domain = shift;
	my $record = shift;

	$self->policy_loaded(undef);
	$self->{policy_t} = Mail::DMARC::opendmarc::opendmarc_policy_connect_rset($self->{policy_t});
	return Mail::DMARC::opendmarc::DMARC_PARSE_ERROR_NULL_CTX unless defined($self->{policy_t});

	my $ret = Mail::DMARC::opendmarc::opendmarc_policy_parse_dmarc($self->{policy_t}, $domain, $record);
	$self->policy_loaded(1) if ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY);
	return $ret;
}

=head3 Information storage methods


=item store_from_domain

Wraps: opendmarc_policy_store_from_domain
Tell the policy evaluator the From domain of the message to be evaluated

	my $rcode = $dmarc->store_from_domain($domain);
	my $rcode = $dmarc->store_from_domain('example.com');

=cut

sub store_from_domain {
	my $self = shift;
	my $from_domain = shift;

	return Mail::DMARC::opendmarc::opendmarc_policy_store_from_domain($self->{policy_t}, $from_domain);
}

=item store_dkim

Wraps: opendmarc_policy_store_dkim
Tell the policy evaluator the domain DKIM-signing the message and
the result of the DKIM signature verification.
	my $rcode = $dmarc->store_dkim($domain, $result, $human_result);
	my $rcode = $dmarc->store_dkim('example.com', Mail::DMARC::opendmarc::DMARC_POLIY_DKIM_OUTCOME_PASS, 'DKIM pass');
	
The following symbols are available for result mapping:
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_FAIL
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_TMPFAIL
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE



=cut

sub store_dkim {
	my $self = shift;
	my $domain = shift;
	my $result = shift;
	my $human_result = shift;

	return Mail::DMARC::opendmarc::opendmarc_policy_store_dkim($self->{policy_t}, $domain, $result, $human_result);
}

=item store_spf

Wraps: opendmarc_policy_store_spf
Tell the policy evaluator the domain DKIM-signing the message and
the result of the DKIM signature verification.

	my $rcode = $dmarc->store_spf($domain, $result, $origin, $human_result);
	my $rcode = $dmarc->store_spf('example.com', 
		Mail::DMARC::opendmarc::DMARC_POLIY_SPF_OUTCOME_PASS, 
		Mail::DMARC::opendmarc::DMARC_POLIY_SPF_ORIGIN_MAILFROM,
		'SPF passed');

The following symbols are available for result mapping:
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_FAIL
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_PASS
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_TMPFAIL
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_NONE
The following symbols are available for SPF origin mapping:
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ORIGIN_MAILFROM
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ORIGIN_HELO
=cut


sub store_spf {
	my $self = shift;
	my $domain = shift;
	my $result = shift;
	my $origin = shift;
	my $human_result = shift;

	return Mail::DMARC::opendmarc::opendmarc_policy_store_spf($self->{policy_t}, $domain, $result, $origin, $human_result);
}

# TODO
# Parse a Authentication-Results header and invoke store_from_domain, store_dkim and store_spf appropriately
sub store_auth_results_from_header {
	my $self = shift;
	my $rfc5451_header = shift;
	# Implement parsing of RFC5451 Authentication-Results header and feed them to store_auth_results
	return undef;
}

# TODO
sub validate {
	my $self = shift;
	my $from_address = shift;
	my $rfc5451_header = shift;
	# all-in-one
	return undef;
}

=head3 Do-it-all-at-once convenience methods

=item query_and_store_auth_results

Perform DMARC policy retrieval *and* store authentication results for the current message
at the same time. Implies SPF authentication is performed against "mail from" and not "helo".
Returns a status code.

	my $rcode = $dmarc->query_and_store_auth_results(
		$from_domain,
		$spf_domain,
		$spf_result,
		$spf_human_result,
		$dkim_domain,
		$dkim_result,
		$dkim_human_result);


=cut

sub query_and_store_auth_results {
	my $self = shift;
	my $from_domain = shift;
	my $spf_domain = shift;
	my $spf_result = shift;
	my $spf_human_result = shift;
	my $dkim_domain = shift;
	my $dkim_result = shift;
	my $dkim_human_result = shift;
	
	$self->valid(undef);

	my $ret = $self->query($from_domain);
	return $ret unless ($ret == DMARC_PARSE_OKAY || $ret == DMARC_POLICY_ABSENT || $ret == DMARC_DNS_ERROR_NO_RECORD);
	
	return $self->store_auth_results (
		$from_domain,
		$spf_domain,
		$spf_result,
		$spf_human_result,
		$dkim_domain,
		$dkim_result,
		$dkim_human_result
	);
}


=item store_auth_results

Like query_and_store_results but does not perform a DMARC policy retrieval - use "store" to initialize the DMARC 
policy instead.
Implies SPF authentication is performed against "mail from" and not "helo".
Returns a status code.

	my $rcode = $dmarc->store_auth_results(
		$from_domain,
		$spf_domain,
		$spf_result,
		$spf_human_result,
		$dkim_domain,
		$dkim_result,
		$dkim_human_result);


=cut

sub store_auth_results {
	my $self = shift;
	my $from_domain = shift;
	my $spf_domain = shift;
	my $spf_result = shift;
	my $spf_human_result = shift;
	my $dkim_domain = shift;
	my $dkim_result = shift;
	my $dkim_human_result = shift;

	$self->valid(undef);

	$self->{from_domain} = $from_domain;
	my $ret;
	$ret = $self->store_from_domain($from_domain);
	return $ret unless $ret == DMARC_PARSE_OKAY;

	$self->{spf} = {
		'domain' => $spf_domain,
		'result' => $spf_result,
		'human' => $spf_human_result
	};
	$self->{dkim} = {
		'domain' => $dkim_domain,
		'result' => $dkim_result,
		'human' => $dkim_human_result
	};

	$ret = $self->store_spf($spf_domain, $spf_result, DMARC_POLICY_SPF_ORIGIN_MAILFROM, $spf_human_result);
	return $ret unless $ret == DMARC_PARSE_OKAY;
	$ret = $self->store_dkim($dkim_domain, $dkim_result, $dkim_human_result);
	$self->valid(1) if $ret == DMARC_PARSE_OKAY;
	return $ret;

}

our %POLICY_VALUES = (
		Mail::DMARC::opendmarc::DMARC_POLICY_ABSENT => 'DMARC_POLICY_ABSENT',
		Mail::DMARC::opendmarc::DMARC_POLICY_NONE => 'DMARC_POLICY_NONE',
		Mail::DMARC::opendmarc::DMARC_POLICY_PASS => 'DMARC_POLICY_PASS',
		Mail::DMARC::opendmarc::DMARC_POLICY_QUARANTINE => 'DMARC_POLICY_QUARANTINE',
		Mail::DMARC::opendmarc::DMARC_POLICY_REJECT => 'DMARC_POLICY_REJECT'
);

our %SPF_ALIGNMENT_VALUES = (
		0 => 'N/A',
		Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_PASS => 'DMARC_POLICY_SPF_ALIGNMENT_PASS',
		Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_FAIL => 'DMARC_POLICY_SPF_ALIGNMENT_FAIL'
);

our %DKIM_ALIGNMENT_VALUES = (
		0 => 'N/A',
		Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_ALIGNMENT_PASS => 'DMARC_POLICY_DKIM_ALIGNMENT_PASS',	
		Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_ALIGNMENT_FAIL => 'DMARC_POLICY_DKIM_ALIGNMENT_FAIL'	
);
	
	
# Main function

=head3 DMARC evaluation result methods

=item verify

Process the incoming message context information against the DMARC policy.
Returns a hash with the following keys:

	'utilized_domain': the domain the policy comes from; either the from_domain or the organizational domain
	'spf_alignment': result of the DMARC SPF alignment check. Possible values:
		Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_PASS 
		Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_FAIL
	'dkim_alignment': result of the DMARC DKIM alignment check: Possible values:
		Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_ALIGNMENT_PASS 
		Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_ALIGNMENT_FAIL
	'policy': the recommended policy to apply to the current message
		Mail::DMARC::opendmarc::DMARC_POLICY_ABSENT 
		Mail::DMARC::opendmarc::DMARC_POLICY_NONE 
		Mail::DMARC::opendmarc::DMARC_POLICY_PASS 
		Mail::DMARC::opendmarc::DMARC_POLICY_QUARANTINE 
		Mail::DMARC::opendmarc::DMARC_POLICY_REJECT
	'human_policy': human-readable description of the policy
	
	$dmarc->query_and_store_auth_results(...);
	my $result = $dmarc->verify();
	print "What should we do with this message: " . $result->{human_policy} . "\n";
	if ($result->{policy} == Mail::DMARC::opendmarc::DMARC_POLICY_REJECT) {
		# processing for messages who failed the DMARC check...


=cut

sub verify {
	my $self = shift;

	return undef unless $self->{valid};	
	my $result = {
		'utilized_domain' => undef,
		'spf_alignment' => undef,
		'dkim_alignment' => undef,
		'policy' => undef,
		'human_policy' => undef
	};

	my $ret = Mail::DMARC::opendmarc::opendmarc_get_policy_to_enforce($self->{policy_t});
	return undef unless (exists $POLICY_VALUES{$ret});
	$result->{human_policy} = $self->human_policy($ret);
	$result->{policy} = $ret;
	my $sa = 0;
	my $da = 0;
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_alignment($self->{policy_t}, $da, $sa);
	return undef unless $ret == DMARC_PARSE_OKAY;
	$result->{spf_alignment} = $sa;
	$result->{dkim_alignment} = $da;
	$result->{utilized_domain} = Mail::DMARC::opendmarc::opendmarc_policy_fetch_utilized_domain_string($self->{policy_t});

	return $result;
	
}

sub human_policy {
	my $self = shift;
	my $val = shift;
	return $POLICY_VALUES{$val} if (exists $POLICY_VALUES{$val});
	return 'Invalid';
}

sub human_spf_alignment {
	my $self = shift;
	my $val = shift;
	return $SPF_ALIGNMENT_VALUES{$val} if (exists $SPF_ALIGNMENT_VALUES{$val});
	return 'Invalid';
}

sub human_dkim_alignment {
	my $self = shift;
	my $val = shift;
	return $DKIM_ALIGNMENT_VALUES{$val} if (exists $DKIM_ALIGNMENT_VALUES{$val});
	return 'Invalid';
}

=item get_policy_to_enforce

Get the result of the policy evaluation.
Returns one of:
		Mail::DMARC::opendmarc::DMARC_POLICY_ABSENT 
		Mail::DMARC::opendmarc::DMARC_POLICY_NONE 
		Mail::DMARC::opendmarc::DMARC_POLICY_PASS 
		Mail::DMARC::opendmarc::DMARC_POLICY_QUARANTINE 
		Mail::DMARC::opendmarc::DMARC_POLICY_REJECT

=cut

sub get_policy_to_enforce {
	my $self = shift;

	return Mail::DMARC::opendmarc::opendmarc_get_policy_to_enforce($self->{policy_t});
}

our %FO_VALUES = (
		Mail::DMARC::opendmarc::DMARC_RECORD_FO_UNSPECIFIED => 'N/A',
		Mail::DMARC::opendmarc::DMARC_RECORD_FO_0 => '0',
		Mail::DMARC::opendmarc::DMARC_RECORD_FO_1 => '1',
		Mail::DMARC::opendmarc::DMARC_RECORD_FO_D => 'd',
		Mail::DMARC::opendmarc::DMARC_RECORD_FO_S => 's'
);

our %RF_VALUES = (
		Mail::DMARC::opendmarc::DMARC_RECORD_RF_UNSPECIFIED => 'N/A',
		Mail::DMARC::opendmarc::DMARC_RECORD_RF_AFRF => 'afrf',
		Mail::DMARC::opendmarc::DMARC_RECORD_RF_IODEF => 'iodef'
);


=item get_policy

Returns a hash containing individual elements of the policy after parsing.

	'policy': same as get_policy_to_enforce (for a given message)
	'p'
	'sp'
	'pct'
	'adkim'
	'aspf'
	'spf_aligment'
	'dkim_aligment'
	'fo'
	'rf'
	'ruf' NOT IMPLENTED YET
	'rua' NOT IMPLEMENTED YET
	
Please refer to DMARC specs for an explanation of the hash elements and their meaning.

=cut


sub get_policy {
	my $self = shift;

	my $result = {};

	$result->{policy} = $self->get_policy_to_enforce();
	my $i = 0;
	my $ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_p($self->{policy_t}, $i);
	$result->{p} = ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY && $i > 0 ? chr($i) : undef);
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_sp($self->{policy_t}, $i);
	$result->{sp} = ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY && $i > 0 ? chr($i) : undef);
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_pct($self->{policy_t}, $i);
	$result->{pct} = $i;
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_adkim($self->{policy_t}, $i);
	$result->{adkim} = ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY && $i > 0 ? chr($i) : undef);
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_aspf($self->{policy_t}, $i);
	$result->{aspf} = ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY && $i > 0 ? chr($i) : undef);
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_fo($self->{policy_t}, $i);
	$result->{fo} = ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY && $i > 0 ? chr($i) : undef);
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_rf($self->{policy_t}, $i);
	$result->{rf} = ($ret == Mail::DMARC::opendmarc::DMARC_PARSE_OKAY && $i > 0 ? chr($i) : undef);
	my $k = 0;
	$ret = Mail::DMARC::opendmarc::opendmarc_policy_fetch_alignment($self->{policy_t}, $i, $k);
	$result->{spf_alignment} = $i;
	$result->{dkim_alignment} = $k;

	return $result;
}

1;
__END__

=head1 SEE ALSO

About DMARC: http://www.opendmarc.org

Abount opendmarc and libopendmarc: http://www.trusteddomain.org/opendmarc.html

=head1 AUTHOR

Davide Migliavacca, E<lt>shari@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2013 by Davide Migliavacca and ContactLab

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

This license is not covering the required libopendmarc package from
http://www.trusteddomain.org/opendmarc.html. Please refer to appropriate
license details for the package.

THis license is not covering the bundled "effective TLD list file"
from http://mxr.mozilla.org, which is licensed under the 
Mozilla Public License 2.0

Please try to have the appropriate amount of fun.

=cut

