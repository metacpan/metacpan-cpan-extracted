package Mail::DKIM::Signature;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: represents a DKIM-Signature header

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::DKIM::PublicKey;
use Mail::DKIM::Algorithm::rsa_sha1;
use Mail::DKIM::Algorithm::rsa_sha256;

use base 'Mail::DKIM::KeyValueList';
use Carp;


sub new {
    my $class = shift;
    my %prms  = @_;
    my $self  = {};
    bless $self, $class;

    $self->version('1');
    $self->algorithm( $prms{'Algorithm'} || 'rsa-sha1' );
    $self->signature( $prms{'Signature'} );
    $self->canonicalization( $prms{'Method'} ) if exists $prms{'Method'};
    $self->domain( $prms{'Domain'} );
    $self->headerlist( $prms{'Headers'} );
    $self->protocol( $prms{'Query'} ) if exists $prms{'Query'};
    $self->selector( $prms{'Selector'} );
    $self->identity( $prms{'Identity'} )     if exists $prms{'Identity'};
    $self->timestamp( $prms{'Timestamp'} )   if defined $prms{'Timestamp'};
    $self->expiration( $prms{'Expiration'} ) if defined $prms{'Expiration'};
    $self->key( $prms{'Key'} )               if defined $prms{'Key'};

    return $self;
}


sub parse {
    my $class = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($string) = @_;

    # remove line terminator, if present
    $string =~ s/\015\012\z//;

    # remove field name, if present
    my $prefix = $class->prefix();
    if ( $string =~ s/^($prefix)//i ) {

        # save the field name (capitalization), so that it can be
        # restored later
        $prefix = $1;
    }

    my $self = $class->SUPER::parse($string);
    $self->{prefix} = $prefix;

    return $self;
}


# deprecated
sub wantheader {
    my $self = shift;
    my $attr = shift;

    $self->headerlist
      or return 1;

    foreach my $key ( $self->headerlist ) {
        lc $attr eq lc $key
          and return 1;
    }

    return;
}


sub algorithm {
    my $self = shift;

    if (@_) {
        $self->set_tag( 'a', shift );
    }

    my $a = $self->get_tag('a');
    return defined $a ? lc $a : undef;
}


sub as_string {
    my $self = shift;

    return $self->prefix() . $self->SUPER::as_string;
}

# undocumented method
sub as_string_debug {
    my $self = shift;

    return $self->prefix()
      . join( ';', map { '>' . $_->{raw} . '<' } @{ $self->{tags} } );
}


sub as_string_without_data {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );

    my $alt = $self->clone;
    $alt->signature('');

    return $alt->as_string;
}


sub body_count {
    my $self = shift;

    # set new body count if provided
    (@_)
      and $self->set_tag( 'l', shift );

    return $self->get_tag('l');
}


sub body_hash {
    my $self = shift;

    # set new body hash if provided
    (@_)
      and $self->set_tag( 'bh', shift );

    my $result = $self->get_tag('bh');
    if ( defined $result ) {
        $result =~ s/\s+//gs;
    }
    return $result;
}


sub canonicalization {
    my $self = shift;

    if (@_) {
        $self->set_tag( 'c', join( '/', @_ ) );
    }

    my $c = $self->get_tag('c');
    $c = lc $c if defined $c;
    if ( not $c ) {
        $c = 'simple/simple';
    }
    my ( $c1, $c2 ) = split( /\//, $c, 2 );
    if ( not defined $c2 ) {

        # default body canonicalization is "simple"
        $c2 = 'simple';
    }

    if (wantarray) {
        return ( $c1, $c2 );
    }
    else {
        return "$c1/$c2";
    }
}

use MIME::Base64;

# checks whether this signature specifies a legal canonicalization method
# returns true if the canonicalization is acceptable, false otherwise
#
sub check_canonicalization {
    my $self = shift;

    my ( $c1, $c2 ) = $self->canonicalization;

    my @known = ( 'nowsp', 'simple', 'relaxed', 'seal' );
    return undef unless ( grep { $_ eq $c1 } @known );
    return undef unless ( grep { $_ eq $c2 } @known );
    return 1;
}

# checks whether the expiration time on this signature is acceptable
# returns a true value if acceptable, false otherwise
#
sub check_expiration {
    my $self = shift;
    my $x    = $self->expiration;
    return 1 if not defined $x;

    $self->{_verify_time} ||= time();
    return ( $self->{_verify_time} <= $x );
}

# Returns a filtered list of protocols that can be used to fetch the
# public key corresponding to this signature. An empty list means that
# all designated protocols are unrecognized.
# Note: at this time, the only recognized protocol is "dns/txt".
#
sub check_protocol {
    my $self = shift;

    my $v = $self->version;

    foreach my $prot ( split /:/, $self->protocol ) {
        my ( $type, $options ) = split( /\//, $prot, 2 );
        if ( $type eq 'dns' ) {
            return ('dns/txt') if $options && $options eq 'txt';

            # prior to DKIM version 1, the '/txt' part was optional
            if ( !$v ) {
                return ('dns/txt') if !defined($options);
            }
        }
    }

    # unrecognized
    return;
}

# checks whether the version tag has an acceptable value
# returns true if so, otherwise false
#
sub check_version {
    my $self = shift;

    # check version
    if ( my $version = $self->version ) {
        my @ALLOWED_VERSIONS = ( '0.5', '1' );
        return ( grep { $_ eq $version } @ALLOWED_VERSIONS );
    }

    # we still consider a missing v= tag acceptable,
    # for backwards-compatibility
    return 1;
}


sub data {
    my $self = shift;

    if (@_) {
        $self->set_tag( 'b', shift );
    }

    my $b = $self->get_tag('b');
    $b =~ tr/\015\012 \t//d if defined $b;
    return $b;
}

*signature = \*data;

#undocumented, private function
#derived from MIME::Base64::Perl (allowed, thanks to the Perl license)
#
sub decode_qp {
    my $res = shift;

    #TODO- should I worry about non-ASCII systems here?
    $res =~ s/=([\da-fA-F]{2})/pack('C', hex($1))/ge
      if defined $res;
    return $res;
}

#undocumented, private function
#derived from MIME::Base64::Perl (allowed, thanks to the Perl license)
#
sub encode_qp {
    my $res = shift;

    # note- unlike MIME quoted-printable, we don't allow whitespace chars
    my $DISALLOWED = qr/[^!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~]/;

    #TODO- should I worry about non-ASCII systems here?
    $res =~ s/($DISALLOWED)/sprintf('=%02X', ord($1))/eg
      if defined $res;
    return $res;
}

sub DEFAULT_PREFIX {
    return 'DKIM-Signature:';
}

sub prefix {
    my $class = shift;
    if ( ref($class) ) {
        $class->{prefix} = shift if @_;
        return $class->{prefix} if $class->{prefix};
    }
    return $class->DEFAULT_PREFIX();
}


sub domain {
    my $self = shift;

    if (@_) {
        $self->set_tag( 'd', shift );
    }

    my $d = $self->get_tag('d');
    return defined $d ? lc $d : undef;
}


sub expiration {
    my $self = shift;

    (@_)
      and $self->set_tag( 'x', shift );

    return $self->get_tag('x');
}

# allows the type of signature to determine what "algorithm" gets used
sub get_algorithm_class {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($algorithm) = @_;

    my $class =
        $algorithm eq 'rsa-sha1'   ? 'Mail::DKIM::Algorithm::rsa_sha1'
      : $algorithm eq 'rsa-sha256' ? 'Mail::DKIM::Algorithm::rsa_sha256'
      :                              undef;
    return $class;
}

# [private method]
# fetch_public_key() - initiate a DNS query for fetching the key
#
# This method does NOT return the public key.
# Use get_public_key() for that.
#
sub fetch_public_key {
    my $self = shift;
    return if exists $self->{public_key_query};

    my $on_success = sub {
        if ( $_[0] ) {
            $self->{public} = $_[0];
        }
        else {
            $self->{public_error} = "not available\n";
        }
    };

    my @methods = $self->check_protocol;
    $self->{public_key_query} = Mail::DKIM::PublicKey->fetch_async(
        Protocol  => $methods[0],
        Selector  => $self->selector,
        Domain    => $self->domain,
        Callbacks => {
            Success => $on_success,
            Error   => sub { $self->{public_error} = shift },
        },
    );
    return;
}

#EXPERIMENTAL
sub _refetch_public_key {
    my $self = shift;
    if ( $self->{public_key_query} ) {

        # clear the existing query by waiting for it to complete
        $self->{public_key_query}->();
    }
    delete $self->{public_key_query};
    delete $self->{public};
    delete $self->{public_error};
    $self->fetch_public_key;
}


sub get_public_key {
    my $self = shift;

    # this ensures we only try fetching once, even if an error occurs
    if ( not exists $self->{public_key_query} ) {
        $self->fetch_public_key;
    }

    if ( $self->{public_key_query} ) {

        # wait for public key query to finish
        $self->{public_key_query}->();
        $self->{public_key_query} = 0;
    }

    if ( exists $self->{public} ) {
        return $self->{public};
    }
    else {
        die $self->{public_error};
    }
}


sub hash_algorithm {
    my $self      = shift;
    my $algorithm = $self->algorithm;

    return
        $algorithm eq 'rsa-sha1'   ? 'sha1'
      : $algorithm eq 'rsa-sha256' ? 'sha256'
      :                              undef;
}


sub headerlist {
    my $self = shift;

    (@_)
      and $self->set_tag( 'h', shift );

    my $h = $self->get_tag('h') || '';

    # remove whitespace next to colons
    $h =~ s/\s+:/:/g;
    $h =~ s/:\s+/:/g;
    $h = lc $h;

    if ( wantarray and $h ) {
        my @list = split /:/, $h;
        @list = map { s/^\s+|\s+$//g; $_ } @list;
        return @list;
    }
    elsif (wantarray) {
        return ();
    }

    return $h;
}


sub identity {
    my $self = shift;

    # set new identity if provided
    (@_)
      and $self->set_tag( 'i', encode_qp(shift) );

    my $i = $self->get_tag('i');
    if ( defined $i ) {
        return decode_qp($i);
    }
    else {
        return '@' . ( $self->domain || '' );
    }
}

sub identity_matches {
    my $self = shift;
    my ($addr) = @_;

    my $id = $self->identity;
    if ( $id =~ /^\@/ ) {

        # the identity is a domain-name only, so it only needs to match
        # the domain part of the sender address
        return ( lc( substr( $addr, -length($id) ) ) eq lc($id) );

        # TODO - compare the parent domains?
    }
    return lc($addr) eq lc($id);
}


sub key {
    my $self = shift;
    if (@_) {
        $self->{Key}     = shift;
        $self->{KeyFile} = undef;
    }
    return $self->{Key};
}


sub method {
    my $self = shift;

    if (@_) {
        $self->set_tag( 'c', shift );
    }

    return ( lc $self->get_tag('c') ) || 'simple';
}


sub protocol {
    my $self = shift;

    (@_)
      and $self->set_tag( 'q', shift );

    my $q = $self->get_tag('q');
    if ( defined $q ) {
        return $q;
    }
    else {
        return 'dns/txt';
    }
}


sub result {
    my $self = shift;
    @_ and $self->{verify_result}  = shift;
    @_ and $self->{verify_details} = shift;
    return $self->{verify_result};
}


sub result_detail {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );

    if ( $self->{verify_result} && $self->{verify_details} ) {
        return $self->{verify_result} . ' (' . $self->{verify_details} . ')';
    }
    return $self->{verify_result};
}


sub selector {
    my $self = shift;

    (@_)
      and $self->set_tag( 's', shift );

    return $self->get_tag('s');
}


sub prettify {
    my $self = shift;
    $self->wrap(
        Start => length( $self->prefix() ),
        Tags  => {
            b  => 'b64',
            bh => 'b64',
            h  => 'list',
        },
    );
}


sub prettify_safe {
    my $self = shift;
    $self->wrap(
        Start => length( $self->prefix() ),
        Tags  => {
            b => 'b64',
        },
        PreserveNames => 1,
        Default       => 'preserve',    #preserves unknown tags
    );
}


sub timestamp {
    my $self = shift;

    (@_)
      and $self->set_tag( 't', shift );

    return $self->get_tag('t');
}


sub version {
    my $self = shift;

    (@_)
      and $self->set_tag( 'v', shift );

    return $self->get_tag('v');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Signature - represents a DKIM-Signature header

=head1 VERSION

version 1.20220520

=head1 CONSTRUCTORS

=head2 new() - create a new signature from parameters

  my $signature = Mail::DKIM::Signature->new(
                      [ Algorithm => 'rsa-sha1', ]
                      [ Signature => $base64, ]
                      [ Method => 'relaxed', ]
                      [ Domain => 'example.org', ]
                      [ Identity => 'user@example.org', ]
                      [ Headers => 'from:subject:date:message-id', ]
                      [ Query => 'dns', ]
                      [ Selector => 'alpha', ]
                      [ Timestamp => time(), ]
                      [ Expiration => time() + 86400, ]
                  );

=head2 parse() - create a new signature from a DKIM-Signature header

  my $sig = Mail::DKIM::Signature->parse(
                  'DKIM-Signature: a=rsa-sha1; b=yluiJ7+0=; c=relaxed'
            );

Constructs a signature by parsing the provided DKIM-Signature header
content. You do not have to include the header name (i.e. "DKIM-Signature:")
but it is recommended, so the header name can be preserved and returned
the same way in as_string().

Note: The input to this constructor is in the same format as the output
of the as_string method.

=head1 METHODS

=head2 algorithm() - get or set the algorithm (a=) field

The algorithm used to generate the signature. Should be either "rsa-sha1",
an RSA-signed SHA-1 digest, or "rsa-sha256", an RSA-signed SHA-256 digest.

See also hash_algorithm().

=head2 as_string() - the signature header as a string

  print $signature->as_string . "\n";

outputs

  DKIM-Signature: a=rsa-sha1; b=yluiJ7+0=; c=relaxed

As shown in the example, the as_string method can be used to generate
the DKIM-Signature that gets prepended to a signed message.

=head2 as_string_without_data() - signature without the signature data

  print $signature->as_string_without_data . "\n";

outputs

  DKIM-Signature: a=rsa-sha1; b=; c=relaxed

This is similar to the as_string() method, but it always excludes the "data"
part. This is used by the DKIM canonicalization methods, which require
incorporating this part of the signature into the signed message.

=head2 body_count() - get or set the body count (l=) field

  my $i = $signature->body_count;

Informs the verifier of the number of bytes in the body of the email
included in the cryptographic hash, starting from 0 immediately
following the CRLF preceding the body. Also known as the l= tag.

When creating a signature, this tag may be either omitted, or set after
the selected canonicalization system has received the entire message
body (but before it canonicalizes the DKIM-Signature).

=head2 body_hash() - get or set the body hash (bh=) field

  my $bh = $signature->body_hash;

The hash of the body part of the message. Whitespace is ignored in this
value. This tag is required.

When accessing this value, whitespace is stripped from the tag for you.

=head2 canonicalization() - get or set the canonicalization (c=) field

  $signature->canonicalization('relaxed', 'simple');

  ($header, $body) = $signature->canonicalization;

Message canonicalization (default is "simple/simple"). This informs the
verifier of the type of canonicalization used to prepare the message for
signing.

In scalar context, this returns header/body canonicalization as a single
string separated by /. In list context, it returns a two element array,
containing first the header canonicalization, then the body.

=head2 data() - get or set the signature data (b=) field

  my $base64 = $signature->data;
  $signature->data($base64);

The signature data. Whitespace is automatically stripped from the
returned value. The data is Base64-encoded.

=head2 domain() - get or set the domain (d=) field

  my $d = $signature->domain;          # gets the domain value
  $signature->domain('example.org');   # sets the domain value

The domain of the signing entity, as specified in the signature.
This is the domain that will be queried for the public key.

If using an "internationalized domain name", the domain name must be
converted to ASCII (following section 4.1 of RFC 3490) before passing
it to this method.

=head2 expiration() - get or set the signature expiration (x=) field

Signature expiration (default is undef, meaning no expiration).
The signature expiration, if defined, is an unsigned integer identifying
the standard Unix seconds-since-1970 time when the signature will
expire.

=head2 get_public_key() - fetches the public key referenced by this signature

  my $pubkey = $signature->get_public_key;

Public key to fetch is determined by the protocol, selector, and domain
fields.

This method caches the result of the fetch, so subsequent calls will not
require additional DNS queries.

This method will C<die> if an error occurs.

=head2 get_tag() - access the raw value of a tag in this signature

  my $raw_identity = $signature->get_tag('i');

Use this method to access a tag not already supported by Mail::DKIM,
or if you want to bypass decoding of the value by Mail::DKIM.

For example, the raw i= (identity) tag is encoded in quoted-printable
form. If you use the identity() method, Mail::DKIM will decode from
quoted-printable before returning the value. But if you use
get_tag('i'), you can access the encoded quoted-printable form of
the value.

=head2 hash_algorithm() - access the hash algorithm specified in this signature

  my $hash = $signature->hash_algorithm;

Determines what hashing algorithm is used as part of the signature's
specified algorithm.

For algorithm "rsa-sha1", the hash algorithm is "sha1". Likewise, for
algorithm "rsa-sha256", the hash algorithm is "sha256". If the algorithm
is not recognized, undef is returned.

=head2 headerlist() - get or set the signed header fields (h=) field

  $signature->headerlist('a:b:c');

  my $headerlist = $signature->headerlist;

  my @headers = $signature->headerlist;

Signed header fields. A colon-separated list of header field names
that identify the header fields presented to the signing algorithm.

In scalar context, the list of header field names will be returned
as a single string, with the names joined together with colons.
In list context, the header field names will be returned as a list.

=head2 identity() - get or set the signing identity (i=) field

  my $i = $signature->identity;

Identity of the user or agent on behalf of which this message is signed.
The identity has an optional local part, followed by "@", then a domain
name. The domain name should be the same as or a subdomain of the
domain returned by the C<domain> method.

Ideally, the identity should match the identity listed in the From:
header, or the Sender: header, but this is not required to have a
valid signature. Whether the identity used is "authorized" to sign
for the given message is not determined here.

If using an "internationalized domain name", the domain name must be
converted to ASCII (following section 4.1 of RFC 3490) before passing
it to this method.

Identity values are encoded in the signature in quoted-printable format.
Using this method will translate to/from quoted-printable as necessary.
If you want the raw quoted-printable version of the identity, use
$signature->get_tag('i').

=head2 key() - get or set the private key object

  my $key = $signature->key;

  $signature->key(Mail::DKIM::PrivateKey->load(File => 'private.key'));

The private key is used for signing messages.
It is not used for verifying messages.

The key object can be any object that implements the
L<sign_digest()|Mail::DKIM::PrivateKey/"sign_digest()"> method.
(Providing your own object can be useful if your actual keys
are stored out-of-process.)

=head2 method() - get or set the canonicalization (c=) field

Message canonicalization (default is "simple"). This informs the verifier
of the type of canonicalization used to prepare the message for signing.

=head2 protocol() - get or set the query methods (q=) field

A colon-separated list of query methods used to retrieve the public
key (default is "dns"). Each query method is of the form "type[/options]",
where the syntax and semantics of the options depends on the type.

=head2 result() - get or set the verification result

  my $result = $signature->result;

  $signature->result('pass');

  # to set the result with details
  $signature->result('invalid', 'no public key');

=head2 result_detail() - access the result, plus details if available

  my $detail = $signature->result_detail;

An explanation of possible detail messages can be found in the
documentation for L<Mail::DKIM::Verifier/result_detail()>.

=head2 selector() - get or set the selector (s=) field

The selector subdivides the namespace for the "d=" (domain) tag.

=head2 prettify() - alters the signature to look "nicer" as an email header

  $signature->prettify;

This method may alter the signature in a way that breaks signatures, so
it should be done ONLY when the signature is being generated, BEFORE being
fed to the canonicalization algorithm.

See also prettify_safe(), which will not break signatures.

=head2 prettify_safe() - same as prettify() but only touches the b= part

  $signature->prettify_safe;

This method will not break the signature, but it only affects the b= part
of the signature.

=head2 timestamp() - get or set the signature timestamp (t=) field

Signature timestamp (default is undef, meaning unknown creation time).
This is the time that the signature was created. The value is an unsigned
integer identifying the number of standard Unix seconds-since-1970.

=head2 version() - get or set the DKIM specification version (v=) field

This is the version of the DKIM specification that applies to this
signature record.

=head1 SEE ALSO

L<Mail::DKIM::DkSignature> for DomainKey-Signature headers

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
