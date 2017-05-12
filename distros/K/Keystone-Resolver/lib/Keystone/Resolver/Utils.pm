# $Id: Utils.pm,v 1.6 2008-02-15 09:49:17 mike Exp $

package Keystone::Resolver::Utils;

use strict;
use warnings;
use URI::Escape qw(uri_unescape uri_escape_utf8);
use Encode;

use Exporter 'import';
our @EXPORT_OK = qw(encode_hash decode_hash utf8param
		    apache_request mod_perl_version
		    apache_non_moronic_logging);

=head1 NAME

Keystone::Resolver::Utils - Simple utility functions for Keystone Resolver

=head1 SYNOPSIS

 use Keystone::Resolver::Utils qw(encode_hash decode_hash);
 $string = encode_hash(%foo);
 %bar = decode_hash($string);

=head1 DESCRIPTION

This module consists of standalone functions -- yes, that's right,
functions: not classes, not methods, functions.  These are provided
for the use of Keystone Resolver.

=head1 FUNCTIONS

=head2 encode_hash(), decode_hash()

 $string = encode_hash(%foo);
 %bar = decode_hash($string);

C<encode_hash()> encodes a hash into a single scalar string, which may
then be stored in a database, specified as a URL parameters, etc.
C<decode_hash()> decodes a string created by C<encode_hash()> back
into a hash identical to the original.

These two functions constitute a tiny subset of the functionality of
the C<Storable> module, but have the pleasant property that the
encoded form is human-readable and therefore useful in logging.  In
theory, the encoding is secret, but I may as well admit that the hash
is encoded as a URL query.

=cut

sub encode_hash {
    my(%hash) = @_;

    return join("&", map {
	uri_escape_utf8($_) . "=" . uri_escape_utf8($hash{$_})
    } sort keys %hash);
}

sub decode_hash {
    my($string) = @_;

    return (map { decode_utf8(uri_unescape($_)) }
	    map { (split /=/, $_, -1) } split(/&/, $string, -1));
}


=head2 utf8param()

 $unicodeString = utf8param($r, $key);
 @unicodeKeys = utf8param($r);

Returns the value associated with the parameter named C<$key> in the
Apache Request (or similar object) C<$r>, on the assumption that the
encoded value was a sequence of UTF-8 octets.  These octets are
decoded into Unicode characters, and it is a string of these that is
returned.

If called with no C<$key> parameter, returns a list of the names of
all parameters available in C<$r>, each such key returned as a string
of Unicode characters.

=cut

# Under Apache 2/mod_perl 2, the ubiquitous $r is no longer and
# Apache::Request object, nor even an Apache2::Request, but an
# Apache2::RequestReq ... which, astonishingly, doesn't have the
# param() method.  So if we're given one of these things, we need to
# make an Apache::Request out of, which at least isn't too hard.
# However *sigh* this may not be a cheap operation, so we keep a cache
# of already-made Request objects.
#
my %_apache2request;
my %_paramsbyrequest;		# Used for Apache2 only
sub utf8param {
    my($r, $key, $value) = @_;

    if ($r->isa('Apache2::RequestRec')) {
	# Running under Apache2
	if (defined $_apache2request{$r}) {
	    #warn "using existing Apache2::RequestReq for '$r'";
	    $r = $_apache2request{$r};
	} else {
	    require Apache2::Request;
	    #warn "making new Apache2::RequestReq for '$r'";
	    $r = $_apache2request{$r} = new Apache2::Request($r);
	}
    }

    if (!defined $key) {
	return map { decode_utf8($_) } $r->param();
    }

    my $raw = undef;
    $raw = $_paramsbyrequest{$r}->{$key} if $r->isa('Apache2::Request');
    $raw = $r->param($key) if !defined $raw;

    if (defined $value) {
	# Argh!  Simply writing through to the underlying method
	# param() won't work in Apache2, where param() is readonly.
	# So we have to keep a hash of additional values, which we
	# consult (above) before the actual parameters.  Ouch ouch.
	if ($r->isa('Apache2::Request')) {
	    $_paramsbyrequest{$r}->{$key} = encode_utf8($value);
	} else {
	    $r->param($key, encode_utf8($value));
	}
    }

    return undef if !defined $raw;
    my $cooked = decode_utf8($raw);
    warn "converted '$raw' to '", $cooked, "'\n" if $cooked ne $raw;
    return $cooked;
}


=head2 apache_request()

 my $r = apache_request($cgi);

Because the Apache/Perl project people saw fit to totally change the
API between C<mod_perl> versions 1 and 2, and because the environment
variables that might tell you what version is in use are undocumented
and obscure, it is pretty painful getting hold of the Apache request
object in a portable way -- which you need for things like setting the
content-type.  C<apache_request()> does this, returning the Apache 1
or 2 request object if running under Apache, and otherwise returning
the fallback object which is passed in, if any.

=cut

sub apache_request {
    my($fallback) = @_;

    my $ver = mod_perl_version();
    #warn "ver=", (defined $ver ? "'$ver'" : "UNDEFINED"), "\n";
    if (!defined $ver) {
	#warn "Fallback: r='$fallback'\n";
	return $fallback;
    }

    if ($ver == 2) {
	require Apache2::RequestUtil;
	my $r = Apache2::RequestUtil->request();
	#warn "Apache2: r='$r'\n";
	return $r;
    }

    if ($ver == 1) {
	require Apache;
	my $r = Apache->request();
	#warn "Apache: r='$r'\n";
	return $r;
    }

    die "unknown mod_perl version '$ver'";
}


=head2 mod_perl_version()

 $ver = mod_perl_version();

Returns the major API version number of the version C<mod_perl> in
effect, or an undefined value if not running under mod_perl (e.g. as
an external CGI script or from the command-line).

=cut

# By inspection, it seems that mod_perl version 2 sets the
# MOD_PERL_API_VERSION environment variable, but mod_perl version 1
# does not; but that both set MOD_PERL.
#
sub mod_perl_version {
    my $api = $ENV{MOD_PERL_API_VERSION};
    return $api if defined $api;
    my $mp = $ENV{MOD_PERL};
    return undef if !defined $mp;
    # $mp is of the form "mod_perl/1.29"
    $mp =~ s/mod_perl\/([0-9]+)\..*/$1/;
    return $mp;
}


=head2

 apache_non_moronic_logging()

I hate the world.

For reasons which no rational being could ever fathom, one of the
differences between Apache 1.x/mod_perl and Apache 2.x/mod_perl2 is
that in the latter, calls to C<warn()> result in the output going to
the I<global> error-log of the server rather than the the error-log of
the virtual site.  I know, I know, it is truly astonishing.  I will
not meditate on this further.  See the section entitled C<Virtual
Hosts> in the C<Apache2::Log> manual for details, or see the online
version at
http://perl.apache.org/docs/2.0/api/Apache2/Log.html#Virtual_Hosts

Anyway, call C<apache_non_moronic_logging()> to globally fix this by
aliasing C<CORE::warn()> to the non-braindead Apache2 logging function
of the same name.  Calling under mod_perl 1, or not under mod_perl at
all, will no-op.

I<### except -- it turns out -- this doesn't actually work, even
though it is the very code from the Apache2::Log manual.  Or rather,
it works intermittently.  So I think you will just have to read the
global log as well as the resolver log.  Nice.>

=cut

sub apache_non_moronic_logging {
    my $ver = mod_perl_version();
    if (defined $ver && $ver == 2) {
	require "Apache2/Log.pm";
	*CORE::GLOBAL::warn = \&Apache2::ServerRec::warn;
	#warn "calling CORE::warn() as warn()";
	#CORE::warn "calling CORE::warn() as CORE::warn()";
	#Apache2::ServerRec::warn "calling Apache2::ServerRec::warn()";
    }
}


1;
