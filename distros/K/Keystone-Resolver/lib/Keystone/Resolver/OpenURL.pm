# $Id: OpenURL.pm,v 1.28 2008-04-30 16:39:00 mike Exp $

package Keystone::Resolver::OpenURL;

use strict;
use warnings;
use Encode;
use URI::Escape qw(uri_escape_utf8);
use XML::LibXSLT;
use Scalar::Util;
use Keystone::Resolver::Result;


=head1 NAME

Keystone::Resolver::OpenURL - an OpenURL that can be resolved

=head1 SYNOPSIS

 %args = (genre => "article",
          issn => "0141-1926",
          volume => 29,
          issue => 4,
          spage => 471);
 $openURL = $resolver->openURL(\%args, "http://my.domain.com/resolve");
 @results = $openURL->resolve_to_results();
 $xml = $openURL->resolve_to_xml();
 $html = $openURL->resolve_to_html($stylesheetName);
 ($type, $content) = $openURL->resolve();

 print $openURL->resolve();

=head1 DESCRIPTION

This class represents an OpenURL, which may be resolved.

=head1 METHODS

=cut


=head2 new()

 $openURL = new Keystone::Resolver::OpenURL($resolver, \%args,
                                            "http://my.domain.com/resolve");
 # Or the more usual shorthand:
 $openURL = $resolver->openURL(\%args, "http://my.domain.com/resolve");

Creates a new OpenURL object, which can subsequently be resolved.  The
first argument is a reference to a hash of the arguments making up the
OpenURL data packet that specifies the ContextObject.  The second is
the base URL of the resolver, which is used for generating equivalent
URLs as required.  The third is the referer URL, which may be used for
some primitive authentication schemes.

=cut

sub new {
    my $class = shift();
    my($resolver, $argsref, $base, $referer) = @_;

    my $this = bless {
	resolver => $resolver,
	base => $base,
	referer => $referer,	# not yet used, but needed for authentication
	serial => undef,	# to be filled in by _serial() if required
	results => undef,	# to be filled in by resolve_to_results()
    }, $class;

    Scalar::Util::weaken($this->{resolver});

    ###	It may be a mistake that we have separate OpenURL and
    #	ContextObject classes, as there is always a one-to-one
    #	correspondance between them.
    $this->{co} = new Keystone::Resolver::ContextObject($resolver,
							$this, $argsref);

    $this->log(Keystone::Resolver::LogLevel::LIFECYCLE, "new OpenURL $this");
    return $this;
}


sub DESTROY {
    my $this = shift();
    Keystone::Resolver::static_log(Keystone::Resolver::LogLevel::LIFECYCLE,
				   "dead OpenURL $this");
}


=head2 newFromCGI()

 $openURL = newFromCGI Keystone::Resolver::OpenURL($resolver, $cgi,
	$ENV{HTTP_REFERER});
 $openURL = newFromCGI Keystone::Resolver::OpenURL($resolver, $cgi,
	$ENV{HTTP_REFERER}, { xml => 1, loglevel => 7 });

This convenience method creates an OpenURL object from a set of CGI
parameters, for the common case that the transport is HTTP-based.  it
behaves the same as the general constructor, C<new()>, except that
that a C<CGI> object is passed in place of the C<$argsref> and
C<$baseURL> arguments.

Additionally, a set of options may be passed in: unless overridden by
options in the CGI parameters, these are applied to the C<$resovler>.
Parameters in C<$cgi> whose keys are prefixed with C<opt_> are
interpreted as resolver options, like this:

	opt_loglevel=7&opt_logprefix=ERROR

All other keys in the CGI object are assumed to be part of the OpenURL
context object.

(### The option handling is arguably a mistake: the options should
apply to the OpenURL object, not the resolver that it uses -- but at
present, OpenURL objects do not have their own options at all.)

=cut

sub newFromCGI {
    my $class = shift();
#   my($cgi, $referer, $optsref, $resolver) = @_;
    my($resolver, $cgi, $referer, $optsref) = @_;
    die "no resolver defined in newFromCGI()"
	if !defined $resolver;

    my %args;
    my %opts = defined $optsref ? %$optsref : ();

    # Default options set from the environment: the KR_OPTIONS
    # environment variable is of the form: loglevel=32,xml=1
    my $optstr = $ENV{KR_OPTIONS};
    if (defined $optstr) {
	foreach my $pair (split /,/, $optstr) {
	    my($key, $val) = ($pair =~ /(.*)=(.*)/);
	    $opts{$key} = $val;
	}
    }

    foreach my $key ($cgi->param()) {
	if ($key =~ /^opt_/) {
	    my @val = $cgi->param($key);
	    $key =~ s/^opt_//;
	    die "Oops.  Multiple values for option '$key'" if @val > 1;
	    $opts{$key} = $val[0];
	    #print STDERR "set option($key) -> ", $val[0], "\n";
	} else {
	    push @{ $args{$key} }, ($cgi->param($key));
	    #print STDERR "$key = ", join(", ",@{$args{$key}}), "\n";
	}
    }

    foreach my $key (keys %opts) {
	$resolver->option($key, $opts{$key});
    }

    my $baseURL = $opts{baseURL} || $cgi->url();
    return $class->new($resolver, \%args, $baseURL, $referer);
}


sub resolver { return shift()->{resolver} }
sub base { return shift()->{base} }
sub co { return shift()->{co} }

# Delegations -- not so simple now that the resolver reference is weak!
sub option {
    my $this = shift();
    my($key, $value) = @_;
    my $resolver = $this->{resolver};
    if (defined $resolver) {
	return $resolver->option(@_);
    } else {
	warn("OpenURL::option('$key', " .
	     (defined $value ? "'$value'" : "undef") .
	     ") on weakened {resolver}, returning undef");
	return undef;
    }
}

sub log {
    my $this = shift();
    my $resolver = $this->{resolver};
    if (defined $resolver) {
	return $resolver->log(@_);
    } else {
	warn "weakened {resolver} reference has become undefined: logging @_";
    }
}
sub descriptor { my $this = shift(); return $this->co()->descriptor(@_) }
sub rft { my $this = shift(); return $this->descriptor("rft")->metadata1(@_) }

# Special delegation: knows database name from OpenURL argument
sub db {
    my $this = shift();
    use Carp; confess "resolver link is undefined" if !defined $this->{resolver};
    return $this->resolver()->db(@_ ? @_ : $this->option("db"));
}


=head2 die(), warn()

 $openURL->die("no service available: ", $errmsg, "(", $details, ")");
 $openURL->warn("multiple genres with same ID");

C<die()> reports failure to resolve this OpenURL.  A nicely formatted
message may be displayed for the user, a message may be generated in a
log file, an email may be sent to the administrator or some
combination of these actions may be taken.  In any case, the arguments
are concatenated to form a string used in these messages.

C<warn()> is the same, except that it indicates a non-fatal condition.

=cut

sub die {
    my $this = shift();

    ###	We could choose what to have die() and warn() do based on
    #	configuration options.  For now, they just fall back to Perl's
    #	built-in die() and warn(), but we could, for example, format a
    #	nice message for the user.

    # I can't persuade Carp to do what I want here - Carp::CarpLevel=1
    # skips right over the stack-frame I want - so I am crudely
    # locating the relevant caller frame by hand.  The approach is
    # that the immediate caller will usually be a trivial delegate if
    # it's from outside this package, so in that case we want the next
    # one down.
    my($package, $filename, $line) = caller(0);
    ($package, $filename, $line) = caller(1)
	if $package ne "Keystone::Resolver::OpenURL";

    CORE::die "*** fatal: " . join("", @_) . " at $filename line $line.\n";
}

sub warn {
    my $this = shift();

    return if $this->option("nowarn");

    # See comments in die() above
    my($package, $filename, $line) = caller(0);
    ($package, $filename, $line) = caller(1)
	if $package ne "Keystone::Resolver::OpenURL";

    $this->log(Keystone::Resolver::LogLevel::WARNING, 
	       join("", @_) . " at $filename line $line");
}


=head2 arg1()

 $scalar = $openurl->arg1($hashref, $key, $delete, $allowUndef);

This simple utility method extracts the first element (i.e. element 0)
from the specified element of the specified hash and returns it,
throwing an error if that element doesn't exist, isn't an array
reference or has no elements, and warning if it has more than one.

 $openurl->arg1($hashref, "name")

is precisely equivalent to

 $hashref->{name}->[0]

except for the extra checking.

If the optional third argument, C<$delete> is provided and non-zero,
then C<$hashref->[$key]> is deleted as a side-effect.

If the optional fourth argument, C<$allowUndef> is provided and
non-zero, then no error is raised if C<$hashref->[$key]> is undefined:
instead, an undefined value is returned.

=cut

sub arg1 {
    my $this = shift();
    my($hashref, $key, $delete, $allowUndef) = @_;

    my $arrayref = $hashref->{$key};
    return undef
	if !defined $arrayref && $allowUndef;
    $this->die("element '$key' does not exist")
	if !defined $arrayref;
    delete $hashref->{$key}
	if defined $delete;
    $this->die("element '$key' ($arrayref) is not an array reference")
	if ref($arrayref) ne "ARRAY";
    $this->die("element '$key' has no elements")
	if @$arrayref == 0;
    if (@$arrayref > 1) {
	# When Openly's "OpenURL Referer" Firefox add-on, version
	# 2.3.5, sees a COinS object in OCLC's WorldCat, the OpenURL
	# that it generates has two "url_ver=Z39.88-2004" elements.
	# Since this is an important source of OpenURLs for testing,
	# we want to allow this without a warning, even though it's
	# naughty.
	my @values = @$arrayref;
	my $val0 = shift @values;
	$this->warn("element '$key' has multiple conflicting values: ",
		    join(", ", map { "'$_'" } @$arrayref))
	    if grep { $_ ne $val0 } @values;
    }

    return $arrayref->[0];
}


=head2 resolve_to_results(), resolve_to_xml(), resolve_to_html(), resolve()

 @results = $openURL->resolve_to_results();
 $xml = $openURL->resolve_to_xml();
 $html1 = $openURL->resolve_to_html();
 $html2 = $openURL->resolve_to_html($stylesheetName);

The various C<resolve_to_*()> methods all resolve a
C<Keystone::Resolver::OpenURL> object into a list of candidate objects
that satisfy the link.  They differ only in the form in which they
return the information.

=over 4

=item resolve_to_results()

Returns an array of zero or more C<Keystone::Resolver::Result>
objects, from which the type and text of results can readily be
extracted.

=cut

sub resolve_to_results {
    my $this = shift();

    if (defined $this->{results}) {
	# Avoid repeated work if two resolve_*() methods are called
	return @{ $this->{results} };
    }

    my($type, $tag) = $this->_single_service();
    if (defined $type) {
	# We only want this single service, not all available ones
	my $service = $this->db()->service_by_type_and_tag($type, $tag);
	$this->die("no $type service with tag '$tag'") if !defined $service;
	$this->_add_result($service, 1);
	goto DONE;
    }

    my $rft = $this->descriptor("rft");
    # This under-the-bonnet pre-test is only for efficiency
    if ($this->option("loglevel") &
	Keystone::Resolver::LogLevel::DUMPREFERENT) {
	use Data::Dumper;
	$this->log(Keystone::Resolver::LogLevel::DUMPREFERENT, Dumper($rft));
    }

    my $errmsg = $this->_resolve_ids($rft);
    $this->die("resolve_ids: $errmsg")
	if defined $errmsg;
    ### What about resolving IDs for the other descriptors?

    ### Resolve private data indicated by "dat" attribute in each
    #	descriptor, probably in the same way as well-known IDs.

    my $mformat = $rft->superdata1("val_fmt");
    if (defined $mformat) {
	$errmsg = $this->_resolve_metadata($mformat);
	$this->die("resolve_metadata: $errmsg")
	    if defined $errmsg;
    } elsif (@{ $this->{results} } == 0) {
	# This is only a problem if there are no resolved IDs either
	$this->die("no metadata format specified for referent");
    }

DONE:
    return @{ $this->{results} };
}


# The job of this function is just to see whether the ContextObject
# specifies that the resolver is to deliver a single service (e.g. a
# citation) rather than the usual array of options.  If so, we return
# that service's type and tag; otherwise an undefined value.
#
# Unfortunately, there's no standard way to express requesting a
# particular service.  Clearly this is a property of service-type, so
# it belongs in the "svc" descriptor, but the metadata format for
# scholarly services defined at
#	http://www.openurl.info/registry/docs/info:ofi/fmt:kev:mtx:sch_svc
# only lets us say yes or no to whether we want services of each of
# the obvious types (abstract, citation, fulltext, holdings, ill) and
# not to say anything more detailed.  An alternative would be to use
# svc_id, but the registry at
#	http://openurl.info/registry/
# doesn't seen to define any info-URIs describing service-types.  So
# it seems we are reduced to using a private identifier, "svc_dat".
# At least there is precedent for this in the KEV Guidelines document,
# Example 10.6.4 (ServiceType) on page 31:
#	&svc_dat=addToCart
#
# What value should we use of svc_dat?  To minimise the likelihood of
# name-clashes with independent OpenURL 1.0 implementations, we prefix
# all our private-data values with "indexdata".  Then we use the type
# (e.g. "citation"), followed by the tag of the specific service we
# want (e.g. a citation style), with all components colon-separated,
# like this:
#	indexdata:citation:endnote
#
sub _single_service {
    my $this = shift();

    my $svc = $this->descriptor("svc");
    return undef if !defined $svc; # nothing about service-type in CO
    my $svc_dat = $svc->superdata1("dat");
    return undef if !defined $svc_dat; # no service-type private data
    my($prefix, $type, $tag) = ($svc_dat =~ /(.*?):(.*?):(.*)/);
    return undef if !defined $tag; # unrecognised format;
    return undef if $prefix ne "indexdata"; # someone else's private data
    return ($type, $tag);
}


sub _resolve_ids {
    my $this = shift();
    my($d) = @_;

    my $idrefs = $d->superdata("id");
    return undef
	if !defined $idrefs;

    foreach my $id (@$idrefs) {
	my $errmsg = $this->_resolve_one_id($d, $id);
	return $errmsg
	    if defined $errmsg;
    }

    return undef;
}


sub _resolve_one_id {
    my $this = shift();
    my($d, $id) = @_;

    if ($id eq "") {
	$this->warn("ignoring empty ", $d->name(), " ID");
	return undef;
    }

    # ID should be a URI, for example:
    #	mailto:jane.doe@caltech.edu
    #	info:doi/10.1006/mthe.2000.0239
    #	info:sid/elsevier.com:ScienceDirect
    my($scheme, $address) = ($id =~ /(.*?):(.*)/);
    if (!defined $scheme) {
	$this->warn("ID doesn't seem to be a URI: '$id'");
	return undef;
    }

    eval {
	require "Keystone/Resolver/plugins/ID/$scheme.pm";
    }; if ($@) {
	$this->warn("can't load ID plugin '$scheme': $@");
	return "ID URI-scheme '$scheme' not supported";
    }

    my($uri, $tag, $data, $errmsg, $nonfatal) =
	"Keystone::Resolver::plugins::ID::$scheme"->data($this, $address);
    $this->_log_resolve_id($id, $scheme, $uri, $tag, $data, $errmsg, $nonfatal)
	if $this->option("loglevel") & Keystone::Resolver::LogLevel::RESOLVEID;

    if (!defined $uri && !defined $data) {
	return $errmsg if !$nonfatal;
	$this->_add_error($errmsg) if defined $errmsg;
	return undef;
    }

    if (defined $uri) {
	# The identifier resolved completely into the URI of the result
	my $res = new Keystone::Resolver::Result("id", $tag,
						 undef, undef, $uri);
	$this->log(Keystone::Resolver::LogLevel::MKRESULT, $res->render());
	push @{ $this->{results} }, $res;
    }

    if (defined $data) {
	# The identifier yielded additional metadata to be used further
	foreach my $key (keys %$data) {
	    $d->push_metadata($key, $data->{$key});
	}
    }

    return undef;
}


sub _log_resolve_id {
    my $this = shift();
    my($id, $scheme, $uri, $tag, $data, $errmsg, $nonfatal) = @_;

    my $str = "$id";
    if (defined $uri) {
	$str .= ": [$tag] $uri";
    }
    if (defined $data) {
	$str .= ": { " . join(", ", map { "$_ -> \"" . $data->{$_} . "\"" }
			      sort keys %$data) . "}";
    }
    if (!defined $uri && !defined $data) {
	my $non = defined $nonfatal ? "non" : "";
	$str .= " failed ($non" . "fatal)";
	if (defined $errmsg) {
	    $str .= ": $errmsg";
	} else {
	    $str .= " with no error-message";
	}
    }

    $this->log(Keystone::Resolver::LogLevel::RESOLVEID, $str);
}


sub _resolve_metadata {
    my $this = shift();
    my($mformat) = @_;

    # What does the metadata format actually tell us?  We can use
    # it to guess the genre, but its primary role is to act as a
    # "namespace identifier" for the metadata elements (aulast,
    # jtitle, etc.)  In theory, we should treat "aulast" in the
    # "journal" metadata format as a separate and distinct element
    # from the name-named element in the "book" metadata format.  In
    # practice, that would introduce a lot of extra complexity for
    # little or no gain.

    # Gather service types that can resolve items of the required genre
    my $db = $this->db();
    my $genre;
    my $genreTag = $this->rft("genre");
    if (defined $genreTag) {
	$genre = $db->genre_by_tag($genreTag);
	return "unsupported genre '$genreTag' specified"
	    if !defined $genre;
    } else {
	$genre = $db->genre_by_mformat($mformat);
	return "no genre specified, and none defined as default " .
	    "for metadata format '$mformat'"
	    if !defined $genre;
    }

    $this->log(Keystone::Resolver::LogLevel::SHOWGENRE,
	       "genre=", $genre->render());

    # Now we need to determine which service-types to use.  Begin by
    # populating the set with "include" rules that match our data.  If
    # no such rules fired, default to including all service-types
    # applicable to this genre; finally remove from the set any
    # service types ruled out by "exclude" rules.
    my @st;
    my $strules = $this->_gather_rules("ServiceTypeRule");
    $this->_process_rules($strules, \@st, 0, "ServiceType");
    @st = $db->servicetypes_by_genre($genre->id()) if @st == 0;
    $this->_process_rules($strules, \@st, 1, "ServiceType");
    return "no service-types for genre '" . $genre->tag() . "'"
	if @st == 0;

    my $srules = $this->_gather_rules("ServiceRule");
    foreach my $st (@st) {
	my $errmsg = $this->_add_results_for_servicetype($st, $srules);
	return undef if defined $errmsg && $errmsg eq 0;
	return $errmsg if defined $errmsg;
    }

    return undef;
}


# Returns a reference to a hash of all rules of the specified class,
# indexed by the bipartite string <field>=<value>
#
sub _gather_rules {
    my $this = shift();
    my($class) = @_;

    my @list = $this->db()->find($class);
    my %hash;
    foreach my $rule (@list) {
	my $fieldname = $rule->fieldname();
	my $value = $rule->value();
	$hash{"$fieldname=$value"} = $rule;
    }

    return \%hash;
}


sub _process_rules {
    my $this = shift();
    my($ruleset, $stref, $exclude, $class) = @_;

    CORE::die "_process_rules(class=$class) unknown"
	if !grep { $class eq $_ } qw(ServiceType Service);

    my $db = $this->db();
    foreach my $rule (values %$ruleset) {
	my $value = $this->_singleDatum($rule->fieldname());
	if ($rule->deny() == $exclude &&
	    defined $value && $value eq $rule->value()) {
	    my @tags = split /\s+/, $rule->tags();
	    if ($exclude) {
		my @newst = ();
		foreach my $st (@$stref) {
		    push @newst, $st if !grep { defined $st->tag() &&
						    $st->tag() eq $_ } @tags;
		}
		@$stref = @newst;
	    } elsif ($class eq "ServiceType") {
		push @$stref, $db->servicetypes_by_tags(@tags);
	    } else {
		push @$stref, $db->services_by_tags(@tags);
	    }
	}
    }
}


# Performs checks (e.g. authorisation) that are common to all service
# types.  Returns an error message if something goes wrong, 0 if all
# is OK and no more service-types need to be consulted because of an
# "include" rule firing, and undef if all is OK and processing should
# continue.
#
sub _add_results_for_servicetype {
    my $this = shift();
    my($serviceType, $rules) = @_;

    my @services;
    my $gotIncludedServices = 0;
    $this->_process_rules($rules, \@services, 0, "Service");
    $gotIncludedServices = 1 if @services > 0;
    @services = $this->db()->services_by_type($serviceType->id())
	if @services == 0;
    $this->_process_rules($rules, \@services, 1, "Service");

    foreach my $service (@services) {
	if ($service->disabled()) {
	    $this->log(Keystone::Resolver::LogLevel::CHITCHAT,
		       "skipping disabled service ", $service->render());
	    next;
	}

	if ($service->need_auth()) {
	    ### Should determine the user's identity and omit the
	    #	services the user has no credentials for.
	}

	my $errmsg = $this->_add_result($service);
	return $errmsg if defined $errmsg;
    }

    return $gotIncludedServices ? 0 : undef;
}


# Checks that are specific some individual service-types (e.g.
# coverage of full-text services) are done here and below.
# Returns undef if all is OK, an error message otherwise.  If optional
# third parameter is present and true, this result is the only one
# that was asked for, due to a service-type specifier in the Context
# Object.
#
sub _add_result {
    my $this = shift();
    my($service, $single) = @_;

    my($text, $errmsg, $nonfatal, $mimeType) =
	$this->_make_result($service);
    if (defined $text) {
	my $res = new Keystone::Resolver::Result($service->service_type_tag(),
						 $service->tag(),
						 $service->name(),
						 $service->priority(),
						 $text,
						 $mimeType,
						 $single);
	$this->log(Keystone::Resolver::LogLevel::MKRESULT, $res->render());
	push @{ $this->{results} }, $res;
	return undef;
    } elsif (!defined $errmsg) {
	# No-op, e.g. repeated failure on the same missing journal record
	return undef;
    } elsif ($nonfatal) {
	$this->_add_error($errmsg);
	return undef;
    }

    # Otherwise it's a hard error
    return $errmsg;
}


sub _make_result {
    my $this = shift();
    my($service) = @_;

    my $stype = ($service->service_type_plugin() ||
		 $service->service_type_tag());
    eval {
	require "Keystone/Resolver/plugins/ServiceType/$stype.pm";
    }; if ($@) {
	$this->warn("can't load service-type plugin '$stype' ",
		    "for service ", $service->name(), ": $@");
	return (undef, "service-type '$stype' is not supported");
    }

    my($text, $errmsg, $nonfatal, $mimeType) =
	"Keystone::Resolver::plugins::ServiceType::$stype"->handle($this,
								   $service);

    $this->log(Keystone::Resolver::LogLevel::HANDLE, $service->render(), ": ",
	       (defined $text ?
		($text . (defined $mimeType ? " ($mimeType)" : "")) :
		(!defined $errmsg ? "no-op" :
		 ((defined $nonfatal ? "non-fatal " : "") .
		  "error: ", $errmsg))));

    return ($text, $errmsg, $nonfatal, $mimeType);
}


sub _add_error {
    my $this = shift();

    push(@{ $this->{results} },
	 new Keystone::Resolver::Result("error", undef, undef, undef,
					join("", @_)));
}


# This method is provided for the use of service-type plugins such as
# plugins/ServiceType/fulltext.pm.  It caches the serial object
# required to satisfy an OpenURL, and returns it.  It caches the
# absence of a suitable serial, to avoid repeated failures.  Return
# values:
#	undef	Lookup tried, and failed; in this case, an error
#		message is also returned for display to the user.
#	0	Previous lookup failed so didn't try again
#	<ref>	Lookup suceeded *or* cached value used from prior success
#
sub _serial {
    my $this = shift();

    my $obj = $this->{serial};
    return $obj
	if defined $obj;

    my $issn = $this->rft("issn");
    my $jtitle = $this->rft("jtitle");
    if (!defined $issn && !defined $jtitle) {
	$this->{serial} = 0;
	return (undef, "no journal information provided");
    }

    $obj = $this->db()->serial($issn, $jtitle);
    if (!defined $obj) {
	my $errmsg = ("the resource database doesn't cover " .
		      (defined $issn ? "ISSN $issn" : "") .
		      (defined $issn && defined $jtitle ? ", " : "").
		      (defined $jtitle ? "journal title $jtitle" : ""));
	$this->warn($errmsg);
	$this->{serial} = 0;
	return (undef, $errmsg);
    }

    $this->{serial} = $obj;
    return $obj;
}


# PRIVATE to _makeURI()
my %_char2field = (v => "volume",
		   i => "issue",
		   p => "spage",
		   t => "atitle",
		   I => "issn",
		   a => "aulast",
		   A => "auinit",
		   j => "isbn",
		   );

# The format of recipes is described in ../../../doc/recipes
sub _makeURI {
    my $this = shift();
    my($recipe) = @_;
    my $saved = $recipe;

    my $uri = "";
    while ($recipe =~ s/(.*?)%([*_]*)(0?)([0-9]*)(([a-zA-Z%])|({[a-zA-Z_\\.\/]+}))//) {
	my($head, $strip, $zero, $width, $item) = ($1, $2, $3, $4, $5);
	$uri .= $head;
	if ($item eq "%") {
	    $uri .= "%";
	    next;
	}

	my $key;
	if ($item =~ s/^{(.*)}$/$1/) {
	    $key = $item;
	} else {
	    $key = $_char2field{$item};
	} 

	my $val;
	if (!defined $key) {
	    $this->warn("recipe '$saved' used unknown item '$item'");
	    $val = "{UNKNOWN-$item}";
	} else {
	    foreach my $onekey (split /\//, $key) {
		$val = $this->_singleDatum($onekey);
		last if defined $val && $val ne "";
	    }
	    return undef if !defined $val;
	    $val =~ s/-//g if $strip =~ /\*/;
	    $val =~ s/ //g if $strip =~ /_/;
	}

	my $len = length($val);
	if ($width ne "" &&  $len < $width) {
	    $val = (($zero eq "0" ? "0" : " ") x ($width-$len)) . $val;
	}

	$uri .= $val;
    }

    return $uri . $recipe;
}


sub _singleDatum {
    my $this = shift();
    my($key) = @_;

    if ($key eq "THIS") {
	return $this->v10url("svc_dat");
    } elsif ($key =~ /(.*?)([_\.])(.*)/) {
	# Explicit descriptor specified
	my($dname, $sep, $vname) = ($1, $2, $3);
	my $descriptor = $this->descriptor($dname);
	if ($sep eq "_") {
	    return defined $descriptor ?
		$descriptor->superdata1($vname) : undef;
	} else {
	    return defined $descriptor ?
		$descriptor->metadata1($vname) : undef;
	}
    } else {
	# No descriptor specified, use the defult: referent
	return $this->rft($key);
    }
}


=head3 resolve_to_xml()

Returns the text of an ultra-simple XML document that contains all the
results.  There is a DTD for this XML format in
C<etc/constraint/results-1.0.dtd>, but informally:

=over 4

=item *

The document consists of a top-level C<<results>> element containing
zero or more C<<result>> elements.

=item *

Each result has mandatory C<type>, C<tag> and C<service> attributes
and optional C<mimetype> and C<priority> attributes

=item *

Each C<<result>> element contains text which is typically but not
always a URI.

=back 4

=cut

### We should really use an XML-writer module rather than doing this
#   by hand.  In particular, it's misleading that the _xmlencode()
#   routine is responsible for the UTF-8 encoding of values.
sub resolve_to_xml {
    my $this = shift();

    my $xml = <<__EOT__;
<?xml version="1.0" encoding="UTF-8" ?>
<results>
__EOT__
    foreach my $d ($this->co()->descriptors()) {
	my $gotOne = 0;
	foreach my $key ($d->metadata_keys()) {
	    $xml .= "  <data entity=\"" . _xmlencode($d->name()) . "\">\n"
		if !$gotOne++;
	    next if $key eq "title"; # we've copied this into "jtitle"
	    my $valref = $d->metadata($key);
	    foreach my $val (@$valref) {
		$xml .= ("    <metadata key=\"" . _xmlencode($key) . "\">" .
			 _xmlencode($val) . "</metadata>\n");
	    }
	}
	$xml .= "  </data>\n"
	    if $gotOne;
    }

    foreach my $res ($this->resolve_to_results()) {
	my $service = $res->service();
	my $mimetype = $res->mimeType();
	$xml .= "  <result";
	$xml .= " type=\"" . _xmlencode($res->type()) .  "\"";
	$xml .= " priority=\"" . _xmlencode($res->priority()) . "\""
	    if defined $res->priority();
	# In rational databases such as MySQL, NULL values are NULL,
	# and are distinct from empty strings.  Therefore, NULL fields
	# can be omitted here.  In Oracle, though, that distinction is
	# steamrollered, and all empty fields become NULL.  So in
	# order to maintain the same output irrespective of which
	# RDBMS we're using (so that the same regression-tests work
	# for both), we need to emit an empty string even when the tag
	# is actually NULL.  *sigh*
	my $tag = $res->tag();
	$tag = "" if !defined $tag;
	$xml .= " tag=\"" . _xmlencode($tag) . "\"";
	$xml .= "\n\t" if defined $service || defined $mimetype;
	$xml .= "service=\"" . _xmlencode($service) .  "\""
	    if defined $service;
	$xml .= " " if defined $service && defined $mimetype;
	$xml .= "mimetype=\"" . _xmlencode($mimetype) .  "\""
	    if defined $mimetype;
	$xml .= "\n\t>" . _xmlencode($res->text()) . "</result>\n";
    }
    $xml .= "</results>\n";
    return $xml;
}


# PRIVATE to resolve_to_xml()
sub _xmlencode {
    my($x) = @_;

    $x = encode_utf8($x);
    $x =~ s/&/&amp;/g;
    $x =~ s/</&lt;/g;
    $x =~ s/>/&gt;/g;
    $x =~ s/\"/&quot;/g;

    return $x;
}


=item resolve_to_html()

Returns the text of an HTML document made by processing the XML
described above by a stylesheet.  If an argument is given, then this
is taken as the basename of the stylesheet to use, to be found in the
the XSLT directory of the resolver (as specified by its C<xsltdir>
option).  If this is omitted, the stylesheet named by the
C<xslt> option, from this directory, is used.

=cut

sub resolve_to_html {
    my $this = shift();
    my($ssname) = @_;

    $ssname = $this->option("xslt")
	if !defined $ssname;

    my $parser = $this->resolver()->parser();
    my $source = $parser->parse_string($this->resolve_to_xml());

    my $stylesheet = $this->resolver()->stylesheet($ssname);
    my $result = $stylesheet->transform($source);
    return $stylesheet->output_string($result);
}


=item resolve()

Returns an array of two elements from which an entire HTTP response
can be built: the C<Content-type> and the actual content.  The
response is XML, as returned from C<resolve_to_xml()>, if the C<xml>
option is set and non-zero; or HTML otherwise, as returned from
C<resolve_to_html()>, otherwise.

=back

=cut

sub resolve {
    my $this = shift();

    my @res = $this->resolve_to_results();
    if (@res == 1 && $res[0]->single()) {
	# The OpenURL requested only a single result, so we return it
	# as its own object rather than embedded into a larger XML or
	# HTML document.
	my $mimeType = $res[0]->mimeType();
	$mimeType = "text/plain" if !defined $mimeType;
	return ($mimeType, $res[0]->text());
    }

    if ($this->option("xml")) {
	return ("text/xml", $this->resolve_to_xml());
    } else {
	return ("text/html; charset=UTF-8", $this->resolve_to_html());
    }
}


=head2 v10url()

 $url = $openurl->v10url("svc_dat", "rft_id");

Returns a string containing a version 1.0 OpenURL representing the
Context Object described by C<$openurl>.  If arguments are provided,
they are the names of keys to be omitted from the returned OpenURL.

=cut

sub v10url {
    my $this = shift();
    my(@skip) = @_;

    my $url = $this->base();
    my $gotOne = 0;
    foreach my $d ($this->co()->descriptors()) {
	my $name = $d->name();
	foreach my $key ($d->superdata_keys()) {
	    my $valref = $d->superdata($key);
	    foreach my $val (@$valref) {
		my $fullkey = "${name}_$key";
		next if grep { $_ eq $fullkey } @skip;
		$url .= $gotOne++ ? "&" : "?";
		$url .= "$fullkey=" . uri_escape_utf8($val);
	    }
	}
	foreach my $key ($d->metadata_keys()) {
	    my $valref = $d->metadata($key);
	    foreach my $val (@$valref) {
		my $fullkey = "${name}.$key";
		next if grep { $_ eq $fullkey } @skip;
		$url .= $gotOne++ ? "&" : "?";
		$url .= "$fullkey=" . uri_escape_utf8($val);
	    }
	}
    }

    return $url;
}


1;
