# $Id: ContextObject.pm,v 1.10 2008-04-10 00:27:02 mike Exp $

package Keystone::Resolver::ContextObject;

use strict;
use warnings;
use LWP;
use URI::Escape;
use Encode;
use Scalar::Util;
use Keystone::Resolver::Descriptor;

=head1 NAME

Keystone::Resolver::ContextObject - an OpenURL Framework (Z39.88) ContextObject

=head1 SYNOPSIS

 $co = new Keystone::Resolver::ContextObject(\%args);

=head1 DESCRIPTION

Read the OpenURL v1.0 standard (Z39.88) to understand the details, but
a ContextObject is a group of six Descriptors, each of which describes
an Entity, plus a small amount of additional administrative
information.  The six types of Entity include Referent (the thing
we're trying to resolve), Referer (the service that generated the
OpenURL), etc.  The administrative information includes details such
as the character encoding used by the constituent entities (which is
UTF-8 by default, unless otherwise specified by a C<ctx_enc> argument,
in which case the data is all canonicalised into UTF-8 anyway.)

=head1 METHODS

=cut


=head2 new()

 $co = new Keystone::Resolver::ContextObject(\%args);

Constructs a new ContextObject from the specified set of arguments.
Although the class model of the code is based on v1.0 of the OpenURL
standard, v0.1 OpenURLs are also transparently handled, so that
equivalent v0.1 and v1.0 OpenURL parameter sets are built into
identical ContextObjects.

=cut

# Distilled summary of Z39.88 Part 2, section 7 (ContextObject Format)
# --------------------------------------------------------------------
#
# [Table 3, Table 5] Special keys describing the ContextObject as a
# whole:
#	ctx_ver		Version of the standard (always "Z39.88-2004")
#	ctx_enc		Character Encoding (expressed as an info URI)
#			Default is info:ofi/enc:UTF-8
#	ctx_id		Identifier of ContextObject
#	ctx_tim		ISO8601 date-time of ContextObject creation
# These are all optional and non-repeatable.
#
# According to the standard (Part 2, section 7.1.1, p10), each
# ContextObject must contain exactly one Referent and Referrer, and
# zero or one of each of the other entities.
#
# [Table 1] Each of the six entities is built based on control
# elements of the form <prefix>_<type>=<value> where prefix is one of:
#	rft		Referent
#	rfe		ReferringEntity	### Table 1 says to use "ref"
#	req		Requester
#	svc		ServiceType
#	res		Resolver
#	rfr		Referrer
# and <type> is one of:
#	id		Entity is uniquely identified by <value>
#	val_*		By-value metadata
#	ref*		By-reference metadata
#	dat		Private data
# Any number of "id"s may be specified for a given entity (e.g. both a
# DOI and a Pubmed ID), but no more than one metadata set (whether by
# value or by reference) or private data cookie.
#
# [Table 2] Meanings of specific control elements:
#	*_val_fmt	Metadata is in the format specified by <value>
#			(and is in <prefix>.<field> elements of this CO)
#	*_ref		Metadata is found at the location <value>
#	*_ref_fmt	Metadata is in the format specified by <value>
#
# Actual metadata for a given entity is represented by keys of the
# form <prefix>.<field>, where prefix indicates one of the six
# entities using the three-letter codes above.  This is only supplied
# for by-value metadata -- NOT for by-reference metadata (or IDs or
# private data).
#
# Since there must be a referent in a context object, and a referent
# must contain exactly one of rft_id, rft_val_fmt (with rft.*
# metadata), rft_ref_fmt (with rft_ref pointing to metadata) or
# rft_dat, the existence of one of these is the test for a valid
# ContextObject
#
# (Section 7.2 of the standard describes the XML ContextObject format.
# We do not plan to implement this in initial versions of Keystone.)
#
# Section 8 lists identifiers for five KEV-based metadata schemas
# (book, dissertation, journal, patent, sch_svc) and eight XML-based
# ones (the same five plus MARC21, oai_dc and pro); but only the
# journal metadata formats are actually described.  The others are
# supposed to be in the registry at openurl.info, but since that site
# is perpetually down, it's hard to tell whether that's true.  Anyway,
# we will only concern ourselves, for now, with journals.
#
# Section 8.1 (Key/Encoded-Value Metadata Format to Describe Journals)
# lists 29 fields, of which maybe half a dozen will actually get used:
#	aulast, aufirst, auinit, auinit1, auinitm, ausuffix, au,
#	aucorp, atitle, title, jtitle, stitle, date, chron, ssn,
#	quarter, volume, part, issue, spage, epage, pages, artnum,
#	isbn, issn, eissn, coden, sici, genre
#
# ContextObjects are delivered using one of three transports described
# in section 9 (by-reference, by-value and inline).  Each of which
# comes in two flavours (http and https) which are of no interest to
# us.  We can tell which of the transports is in use by checking for
# elements url_ctx_ref (the ContextObject is provided by reference)
# and url_ctx_val (it is provided as the value of that element); if
# both are missing, the ContextObject is inline.
#
# The standard says (sections 9.1.1, 9.2.1, 9.3.1) that elements not
# specified for the three transports may be supplied by clients and
# may be ignored by servers, so they are suitable for passing private
# information such as opt_loglevel=7 to the resolver.  (Identifying
# such elements is handled by the driver program rather than by the
# Resolver library: by the time the library sees them, they've already
# been turned into options.)

sub new {
    my $class = shift();
    my($resolver, $openurl, $argsref) = @_;

    my %args = %$argsref;	# local copy

    if (!defined $args{url_ver}) {
	# It's not a Z39.88 OpenURL: if it's a v0.1 OpenURL we can
	# translate it and we'll be happy.
	if (!_translate_0point1($openurl, \%args)) {
	    $openurl->die("can't translate v0.1 OpenURL to v1.0");
	}
    } elsif (($openurl->arg1(\%args, "url_ver")) ne "Z39.88-2004") {
	$openurl->die("not a v1.0 (Z39.88-2004) OpenURL");
    }

    my $this = $class->_create($resolver, $openurl, \%args);
    my $err;
    $err = $this->_validate(\%args)
	and $this->die("validate: $err");
    $err = $this->_dereference_contextObject(\%args)
	and $this->die("dereference: $err");
    $err = $this->_canonicalise_charenc(\%args)
	and $this->die("canonicalise_charenc: $err");
    $err = $this->_make_entities(\%args)
	and $this->die("make_entities: $err");

    foreach my $key (sort keys %args) {
	$this->warn("remaining key $key=", join(", ", @{ $args{$key} }));
    }

    $err = $this->_dereference_entities()
	and $this->die("dereference_entities: $err");

    # Earlier versions used to try to resolve IDs here, but in fact
    # that's premature, since they usually resolve not to metadata
    # that we can go on to use, but directly to the URL of the
    # resource.  Accordingly, IDs are now handled in
    # Keystone::Resolver::OpenURL::resolve_to_results().  However, if
    # we later run into different ID schemes that do resolve to
    # metadata rather than content URLs, we'll need to resurrect the
    # code that used to be here for that purpose.

    # This under-the-bonnet pre-test is only for efficiency
    if ($this->option("loglevel") &
	Keystone::Resolver::LogLevel::DUMPDESCRIPTORS) {
	$this->log(Keystone::Resolver::LogLevel::DUMPDESCRIPTORS,
		   $this->_dump());
    }

    return $this;
}


# All the following tables are PRIVATE to _translate_0point1()

### Why are isbn/sici (identifiers) considered v1.0 metadata?
my @_v01v10same = qw(artnum atitle aufirst auinit auinit1 auinitm aulast
		     coden date eissn epage isbn issn issue pages part
		     quarter sici spage ssn stitle title volume);
my %_v01v10map = ( map { ($_ => "rft.$_") } @_v01v10same);

# In v0.1 but not in v1.0:
#	genre: (journal, book, conference, etc.)
#	bici: "A BICI for a section of a book, to which an ISBN has
#		been assigned. Compliant with http://www.niso.org/bici.html"

# "au", "aucorp", "ausuffix" and "chron" are in v1.0 but not in v0.1,
# so we have no way of generating them.  "jtitle" is a synonym with
# "title", and is handled separately in the constructor since v1.0
# requires it to be handled for all six entities.

# See Z39.88 part 2, section 8.1 for a rationale of the
# journal-related elements of this hash, and the on-line registry for
# the book-related parts.  (There are no books in Z39.88 itself).
# Two of the v0.1 genres (conference, proceeding) are supported by
# both the journal and book metadata formats in v1.0.  We arbitrarily
# choose the journal versions, in the absence of any other guidance.
my %_v01v10genre = (
	journal    => [ "info:ofi/fmt:kev:mtx:journal", "journal" ],
	book       => [ "info:ofi/fmt:kev:mtx:book",    "book" ],
	conference => [ "info:ofi/fmt:kev:mtx:journal", "conference" ],
	article    => [ "info:ofi/fmt:kev:mtx:journal", "article" ],
	preprint   => [ "info:ofi/fmt:kev:mtx:journal", "preprint" ],
	proceeding => [ "info:ofi/fmt:kev:mtx:journal", "proceeding" ],
	bookitem   => [ "info:ofi/fmt:kev:mtx:book",    "bookitem" ],
);

sub _translate_0point1 {
    my($openurl, $args) = @_;

    my %new = (
	       url_ver => [ "Z39.88-2004" ],
	       url_ctx_fmt => [ "info:ofi/fmt:kev:mtx:ctx" ],
	       );

    foreach my $key (sort keys %new) {
	$openurl->log(Keystone::Resolver::LogLevel::CONVERT01,
		      "added $key=", list($new{$key}));
    }

    foreach my $key (keys %$args) {
	my $mapped = $_v01v10map{$key};
	if (defined $mapped) {
	    $new{$mapped} = delete $args->{$key};
	    $openurl->log(Keystone::Resolver::LogLevel::CONVERT01,
			  "converted $key=", list($new{$mapped}),
			  " to $mapped");
	}
    }

    my $id = delete $args->{id};
    if (defined $id) {
	$new{rft_id} = [ map { s/:/\//; "info:$_"; } @$id ];
	$openurl->log(Keystone::Resolver::LogLevel::CONVERT01,
		      "converted id=", list($new{rft_id}), " to rft_id");
    }

    my $sid = delete $args->{sid};
    if (defined $sid) {
	$new{rfr_id} = [ map { "info:sid/$_"; } @$sid ];
	$openurl->log(Keystone::Resolver::LogLevel::CONVERT01,
		      "converted sid=", list($new{rfr_id}), " to rfr_id");
    }

    # The OpenURL 0.1 standard says nothing about the mandatory or
    # optional nature of the "genre" tag, but by inspection some
    # OpenURLs, including one of page 5 of the standard itself, omit
    # this, so we need to choose a sensible default.
    my $genre = $openurl->arg1($args, "genre", 1, 1);
    $genre = "article" if !defined $genre;

    if (defined $genre) {
	my $ref = $_v01v10genre{$genre};
	my($format, $v1point0genre) = @$ref;
	$new{rft_val_fmt} = [ $format ];
	$new{"rft.genre"} = [ $v1point0genre ];
	$openurl->log(Keystone::Resolver::LogLevel::CONVERT01,
		      "converted genre=$genre to ",
		      "rft_val_fmt=$format, rft.genre=$v1point0genre");
    }

    # Check for left-over, untranslated, elements in $args
    foreach my $key (keys %$args) {
	$openurl->warn("can't translate OpenURL 0.1 key $key=",
		       join(", ", @{ $args->{$key} }));
	$new{"rft.$key"} = delete $args->{$key};
    }    

    # Move the new set of elements across into %$args
    foreach my $key (keys %new) {    
	$args->{$key} = $new{$key};
    }

    return 1;
}


# Returns a rendering of an array-reference
sub list {
    my($aref) = @_;

    CORE::die "not an array reference" if CORE::ref($aref) ne "ARRAY";
    return "[]" if @$aref == 0;
    return $aref->[0] if @$aref == 1;
    return "[" . join(", ", @$aref), "]";
}


sub _create {
    my $class = shift();
    my($resolver, $openurl, $args) = @_;

    my $this = bless {
	openurl     => $openurl,
	### The next five parameters arguably belong in the OpenURL object.
	url_ver     => $openurl->arg1($args, "url_ver", 1, 1), # unused
	url_tim     => $openurl->arg1($args, "url_tim", 1, 1), # unused
	format      => $openurl->arg1($args, "url_ctx_fmt", 1, 1),
	ref         => $openurl->arg1($args, "url_ctx_ref", 1, 1),
	val         => $openurl->arg1($args, "url_ctx_val", 1, 1),
        ### What are these parameters (apart from encoding) actually _for_?
	version     => $openurl->arg1($args, "ctx_ver", 1, 1), # unused
	encoding    => $openurl->arg1($args, "ctx_enc", 1, 1),
        id          => $openurl->arg1($args, "ctx_id", 1, 1), # unused
	timestamp   => $openurl->arg1($args, "ctx_tim", 1, 1), # unused
	descriptors => {},
    }, $class;

    Scalar::Util::weaken($this->{openurl});
    return $this;
}


sub resolver { return shift()->openurl()->resolver() }
sub openurl { return shift()->{openurl} }
sub format { return shift()->{format} }
sub ref { return shift()->{ref} }
sub val { return shift()->{val} }
sub encoding { return shift()->{encoding} }

sub descriptors {
    my $this = shift();

    return sort { $a->name() lt $b->name() }
	values %{ $this->{descriptors} };
}

sub descriptor {
    my $this = shift();
    my($name) = @_;

    return $this->{descriptors}->{$name};
}

# Delegations
sub option { my $this = shift(); return $this->resolver()->option(@_) }
sub log { my $this = shift(); return $this->resolver()->log(@_) }
sub fail { my $this = shift(); return $this->openurl()->fail(@_) }
sub die { my $this = shift(); return $this->openurl()->die(@_) }
sub warn { my $this = shift(); return $this->openurl()->warn(@_) }


sub _validate {
    my $this = shift();
    my($args) = @_;

    my $isByRef = defined $this->ref();
    my $isByVal = defined $this->val();
    my $isInline = (defined $args->{rft_id} ||
		    defined $args->{rft_ref_fmt} ||
		    defined $args->{rft_val_fmt});

    if ($isByRef && $isByVal && $isInline) {
	return "OpenURL is By-Reference, By-Value and Inline";
    } elsif ($isByRef && $isByVal) {
	return "both By-Reference and By-Value";
    } elsif ($isByRef && $isInline) {
	return "both By-Reference and Inline";
    } elsif ($isByVal && $isInline) {
	return "both By-Value and Inline";
    } elsif (!$isByRef && !$isByVal && !$isInline) {
	return "OpenURL is not By-Reference, By-Value or Inline";
    }

    ### Apart from doing the following check, we actually ignore the
    #   ContextObject format if it's there.  Should recognise:
    #		info:ofi/fmt:kev:mtx:ctx -- key/value pairs
    #		info:ofi/fmt:xml:xsd:ctx -- XML

    if (!$isInline && !defined $this->format()) {
	return "no ContextObject format specified " .
	    "for By-Reference or By-Value v1.0 OpenURL";
    }

    if ($isInline) {
	my $correct = "info:ofi/fmt:kev:mtx:ctx";
	my $format = $this->format();
	if (!defined $format) {
	    # format may be omitted for Inline v1.0 OpenURLs
	    $this->{format} = $correct;
	} elsif ($format ne $correct) {
	    return "incorrect format '$format' for Inline v1.0 OpenURL";
	}
    }

    # If we got this far, it has the correct signature, a defined
    # ContextObject format and parameters for exactly one of the three
    # standard transports.
    return undef;
}


sub _dereference_contextObject {
    my $this = shift();
    my($args) = @_;

    my $ref = $this->ref();
    if (defined $ref) {
	#return "no network for _dereference_contextObject()";####
	my ($val, $errmsg) = $this->fetch($ref, "ContextObject");
	if (!defined $val) {
	    return !defined $errmsg ? undef :
		"_dereference_contextObject: $errmsg";
	}
	$this->{val} = $val;
    }

    my $val = $this->val();
    if (defined $val) {
	# Resolve a value to a set of elements
	foreach my $nv (split /&/, $val) {
	    next if !$nv;
	    my($name, $value) = split /=/, $nv;
	    push @{ $args->{$name} }, uri_unescape($value);
	}
	$this->log(Keystone::Resolver::LogLevel::DISSECT,
		   "ContextObject value $val");
    }

    return undef;
}


# Fetch a reference to a value and canonicalise it.  Returns two
# elements, being the dereferenced value or undef, and an error
# message.  If the optional third argument is provided and true, then
# we do not follow redirections, and instead just return the URL to
# which we get redirected.
#
#   ###	Note that this method has security implementations.  See
#	KEV_Guidelines-20040211.pdf (annex to Z39.88), Appendix D.
#	For example, we should notice and refuse to follow links that
#	look like OpenURLs, to avoid recursion.
#
sub fetch {
    my $this = shift();
    my($ref, $label, $returnRedirect) = @_;

    my($scheme, $host, $tail) = $ref =~ m[^([^:]*)://([^/]*)/(.*)];
    my $domain = $this->openurl()->db()->domain_by_name($host);
    my $status = defined $domain ? $domain->status() : 0;

    if ($status == 1) {
	# Never even try to fetch data from this domain
	$this->log(Keystone::Resolver::LogLevel::DEREFERENCE,
		   "skipping bad domain ($host) for $label $ref");
	return (undef, undef);
    }

    my $ua = $this->resolver()->ua();
    my $oldRedirectable;
    if ($returnRedirect) {
	# How clumsy that this must be done modally
	$oldRedirectable = $ua->requests_redirectable();
	$ua->requests_redirectable([]);
    }

    my $res = $ua->get($ref);
    if ($returnRedirect) {
	$ua->requests_redirectable($oldRedirectable);
    }

    if (($returnRedirect && !$res->is_redirect()) ||
	(!$returnRedirect && !$res->is_success())) {
	return (undef, "ref($ref): " . $res->status_line())
	    if $status == 0;

	$this->die("impossible status '$status' for domain $host")
	    if $status != 2;

	# This domain is "greylisted": failure to fetch from here is ignored
	$this->log(Keystone::Resolver::LogLevel::DEREFERENCE,
		   "ignoring fetch failure ($host) for $label $ref");
	return (undef, undef);
    }

    $this->log(Keystone::Resolver::LogLevel::DEREFERENCE, "$label URI $ref");
    return $res->header("Location")
	if $returnRedirect;

    my $val = $res->content();
    # The next line discards all whitespace and is contentious.  See
    # http://isi.1cate.com/t/test/niso-suite-10.html
    $val =~ s/\s+//g;

    return $val;
}


# On entry to this function, each data value is a string of UTF-8
# octets in the range 0 to 255; on exit, it has become a string of
# (generally fewer) Unicode characters in the range 0 to 2^32-1
#
sub _canonicalise_charenc {
    my $this = shift();
    my($args) = @_;

    my $enc = $this->encoding();
    # Z39.88-2004, part 2, section 7.1.5 says this is optional and
    # that in its absence we can assume UTF-8.
    $enc = "info:ofi/enc:UTF-8" if !defined $enc;

    if ($enc !~ s/^info:ofi\/enc://) {
	return "character encoding '$enc' is not an info:ofi/enc URI";
    }

    foreach my $key (keys %$args) {
	my @translated;
	foreach my $datum (@{ $args->{$key} }) {
	    my $old = $datum;	# Needed since $datum seems to get cleared
	    my $new = decode($enc, $datum, Encode::FB_CROAK);
	    push @translated, $new;
	    #CORE::warn "translated ", _render($old), " to ", _render($new) if $new ne $old;
	}
	$args->{$key} = \@translated;
    }

    return undef;
}


# Play out a string by individual characters
sub _render {
    my($s) = @_;

    my $res = "'$s' (";
    $res .= join(" ", map { ord($_) } split //, $s);
    return $res . ")";
}

# Break into six descriptors (rft, rfe, etc.) each with relevant data
sub _make_entities {
    my $this = shift();
    my($args) = @_;

    foreach my $key (sort keys %$args) {
	my $found_sep = ($key =~ /(.*?)([_.])(.*)/);
	next if !$found_sep;
	my($name, $sep, $field) = ($1, $2, $3);
	next if $name eq 'url';
	next if $name eq 'ctx';

	my $d = $this->{descriptors}->{$name};
	if (!defined $d) {
	    $d = $this->{descriptors}->{$name} =
		new Keystone::Resolver::Descriptor($name);
	    $this->warn("created non-standard entity '$name'")
		if !grep { $name eq $_ } qw(rft rfe req svc res rfr);
	}

	if ($sep eq "_") {
	    $d->superdata($field, delete $args->{$key});
	} else {
	    my $val = delete $args->{$key};
	    $d->metadata($field, $val);
	    # OpenURL 1.0 supports "title" as an obsolete "jtitle" synonym
	    $d->metadata("jtitle", $val)
		if $field eq "title" && !defined $args->{"$name.jtitle"};
	}
    }

    return undef;
}


sub _dereference_entities {
    my $this = shift();

    # Resolve parameters indicated by "ref" attribute in each descriptor
    foreach my $d ($this->descriptors()) {
	my $name = $d->name();
	next if $name eq "req";	# No need to dereference requestor
				# ### and probably others
	my $errmsg = $this->_dereference_entity($d);
	return "_dereference_entity($name): $errmsg"
	    if defined $errmsg;
    }

    return undef;
}


sub _dereference_entity {
    my $this = shift();
    my($d) = @_;

    my $name = $d->name();
    my $ref = $d->superdata1("ref");
    my $fmt = $d->superdata1("ref_fmt");

    return undef
	if !defined $ref && !defined $fmt;
    return "reference provided but no reference-format"
	if !defined $fmt;
    return "reference-format provided but no reference"
	if !defined $ref;
    #return "no network for _dereference_entity()";####

    my($val, $errmsg) = $this->fetch($ref, "entity($name)");
    return $errmsg if !defined $val;

    $d->superdata("val_fmt", $d->delete_superdata("ref_fmt"));
    $d->delete_superdata("ref");

    foreach my $nv (split /&/, $val) {
	next if !$nv;
	my($name, $value) = split /=/, $nv;
	$d->push_metadata($name => uri_unescape($value));
    }
    
    $this->log(Keystone::Resolver::LogLevel::DISSECT,
	       "entity($name) value $val");
	return undef;
}


# Used only for generating logging output
sub _dump {
    my($this) = shift();

    my $s = "\n";
    foreach my $des ($this->descriptors()) {
	$s .= "\t" . $des->name() . " = {\n";
	foreach my $key ($des->superdata_keys()) {
	    $s .= "\t\t*$key -> " .
		join(", ", @{ $des->superdata($key) }) . "\n";
	}
	foreach my $key ($des->metadata_keys()) {
	    $s .= "\t\t $key -> " .
		join(", ", @{ $des->metadata($key) }) . "\n";
	}
	$s .= "\t}\n";
    }

    return $s;
}


1;
