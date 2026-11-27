package HTTP::Message::Signature;

# ABSTRACT: Verify HTTP Message Signatures (RFC 9421)

use v5.24;
use Moo;

use Carp qw( carp croak );
use Crypt::PK::Ed25519;
use Crypt::PK::RSA;
use Hash::MultiValue;
use Hash::Ordered;
use HTTP::Message;
use HTTP::StructuredField v0.0.3;
use HTTP::Tiny;
use JSON          qw( decode_json );
use List::Util    1.29 qw( first pairmap );
use MIME::Base64  qw( decode_base64 );
use PerlX::Maybe  qw( maybe );
use Ref::Util     qw( is_plain_hashref );
use String::Util  qw( trim unquote );
use Syntax::Keyword::Match;
use Types::Common qw( Bool HashRef InstanceOf NonEmptyStr  );
use Types::URI    qw( Uri );
use URI;

use experimental qw( lexical_subs signatures );

use namespace::autoclean;

our $VERSION = 'v0.0.3';



has message => (
    is       => 'ro',
    isa      => InstanceOf [qw/ HTTP::Message Plack::Request /],
    required => 1,
    handles  => [qw/ as_string headers /],
);


has is_request => (
    is      => 'lazy',
    isa     => Bool,
    builder => sub($self) {
        my $message = $self->message;
        return $message->isa("HTTP::Request") || $message->isa("Plack::Request");
    },
    init_arg => undef,
);


has is_response => (
    is      => 'lazy',
    isa     => Bool,
    builder => sub($self) { $self->message->isa("HTTP::Response") },
    init_arg => undef,
);


has user_agent => (
    is      => 'lazy',
    isa     => InstanceOf ['HTTP::Tiny'],
    builder => sub($self) {
        return HTTP::Tiny->new;
    },
);


has signature_agent => (
    is      => 'lazy',
    isa     => NonEmptyStr,
    builder => sub($self) {
        my $agent = join(",", $self->headers->header("signature-agent") );
        if ( $agent =~ /\A [a-z\*][a-z0-1_\-\.\*]* = /ax ) {
            my ($key) = $self->headers->header("signature-agent-key") || $self->signature_labels;
            my $agents = HTTP::StructuredField->parse_dictionary(  $agent );
            $agent = $agents->get( unquote($key) )->value;
        }
        return $agent;
    }
);


has signature_agent_uri => (
    is      => 'lazy',
    isa     => Uri,
    coerce  => 1,
    builder => sub($self) {
        my $uri = URI->new( unquote( $self->signature_agent ) );
        carp "signature-agent header contains a full URL" if $uri->path && $uri->path ne "/";
        $uri->path("/.well-known/http-message-signatures-directory");
        return $uri;
    },
);


has signature_input => (
    is      => 'lazy',
    isa     => InstanceOf ['Hash::Ordered'],
    builder => sub($self) {
        my @input = $self->headers->header("signature-input");
        return HTTP::StructuredField->parse_dictionary( join( ',', @input ) );
    },
    handles => {
        signature_labels => 'keys',
    },
);


has signature_header => (
    is      => 'lazy',
    isa     => InstanceOf ['Hash::Ordered'],
    builder => sub($self) {
        my @input = $self->headers->header("signature");
        return HTTP::StructuredField->parse_dictionary( join( ',', @input ) );
    },
);


has public_keys_json => (
    is      => 'lazy',
    isa     => NonEmptyStr,
    builder => sub($self) {

        # TODO: add support for caching keys by URL

        state $types = { map { $_ => 1 } qw[ application/http-message-signatures-directory+json application/json ] };

        my $uri = $self->signature_agent_uri;
        croak "agent_uri should be an https URL" unless $uri->scheme eq "https";
        my $res =
          $self->user_agent->get( "$uri", { headers => { 'Accept' => join( ",", keys $types->%* ) } } );
        if ( $res->{success} && $types->{ $res->{headers}{'content-type'} } ) {
            return $res->{content};
        }

        croak "error retrieving ${uri}";
    }
);


has public_keys => (
    is      => 'lazy',
    isa     => HashRef,       # TODO make strict validation optional
    builder => sub($self) {
        return decode_json( $self->public_keys_json );
    },
);


has require_tag => (
    is        => 'ro',
    isa       => NonEmptyStr,
    predicate => 1,
);


sub is_expired($self) {
    my $expires = $self->signature_input->get("expires") or return undef;
    return time > $expires->value;
}


sub verify( $self, $label = undef ) {

    ($label) = $self->signature_labels unless defined $label;
    my $input = $self->signature_input->get($label) or croak "signature-input label ${label} was not found";

    if ( $self->has_require_tag ) {
        my $check = $input->params->get("tag");
        my $tag = $self->require_tag;
        croak "tag is not '${tag}'" unless $check && $check->value eq $tag;
    }

    my $keyid = $input->params->get("keyid") or croak "no keyid was found in the signature-input";
    my $kid   = unquote( $keyid->value );

    state $algs = {
        "ed25519"        => { class => "Crypt::PK::Ed25519", key => { kty => "OKP", crv => "Ed25519" } },
        "rsa-pss-sha512" => { class => "Crypt::PK::RSA", key => { kty => "RSA", alg => "PS512" }, hash => [qw/ SHA512 pss 64 /] },
    };

    my $alg  = eval { $input->params->get("alg")->value } or croak "missing alg parameter";
    my $meta = $algs->{ $alg } or croak "unsupported algorithm";

    my $key = first { $_->{kid} eq $kid } $self->public_keys->{keys}->@*
      or croak "keyid '${kid}' was not found in the public keys";

    # TODO: add support for looking up keys from a cache based on agent URL and key id, and alg

    for my $field ( keys $meta->{key}->%* ) {
        $key->{$field} eq $meta->{key}{$field} or croak "keyid ${kid} is incompatible with ${alg}";
    }

    my $class = $meta->{class};

    my @params = $meta->{hash} ? $meta->{hash}->@* : ();

    my $pk = $class->new($key);

    my $sig = $self->signature_header->get($label)->value;

    my $base = $self->_generate_signature_base($label);

    return $pk->verify_message( $sig, $base, @params );
}

sub _generate_signature_base( $self, $label ) {

    my @buffer;

    my $seen = Hash::Ordered->new;

    my sub _process_header_field( $field, $value ) {

        # TODO serialize line as per "component-identifier ABNF rule"
        # TODO canonicalize the field value
        my $line = sprintf( '%s: %s', lc($field), $value // "" );
        croak "component has already been added to the sginature base" if $seen->exists( lc $field );
        $seen->set( lc $field => 1 );
        push @buffer, $line;
    }

    my $input = $self->signature_input->get($label) or croak "signature-input label ${label} was not found";
    croak "label ${label} is not a list" unless $input->is_inner_list;

    for my $field ( $input->value->@* ) {

        my $name = unquote($field->value, braces => 1 );
        if ( substr($name, 0, 1) eq '@' ) {
            _process_header_field( $self->_get_derived_field($field) );
        }
        else {

            my $header = $self->headers->header($name);
            if ($field->has_params) {

                my ($key) = $field->params->get("key")->value;
                my $dict = HTTP::StructuredField->parse_dictionary($header);
                my $param = $dict->get($key);

                # TODO: improve quoting
                _process_header_field( "\"${name}\";key=\"${key}\"" => sprintf('"%s"', $param->value ) );

            }
            else {
                _process_header_field( "\"${name}\"" => $header );
            }
        }

    }

    my $header = $self->headers->header("signature-input");
    croak "unexpected signature-input" unless substr( $header, 0, length($label) + 1 ) eq "${label}=";
    my $params = substr( $header, length($label) + 1 );
    _process_header_field( '"@signature-params"' => $params );

    return join( "\n", @buffer );
}

sub _get_derived_field( $self, $field ) {

    my $name = $field->value;

    # Note: HTTP::Message has uri_canonical but Plack::Request does not.

    state $handlers = {
        '@status'     => sub( $message, $ ) { $message->code },
        '@method'     => sub( $message, $ ) { $message->method },
        '@target-uri' => sub( $message, $ ) { $message->uri },
        '@authority'  => sub( $message, $ ) { $message->uri->authority },
        '@scheme'     => sub( $message, $ ) { $message->uri->scheme },
        '@path'       => sub( $message, $ ) { $message->uri->path },
        '@query'      => sub( $message, $ ) {
            my $query = $message->uri_canonical->query;
            if ( defined $query ) {
                return '?' . $query;
            }
            return undef;
        },
        '@query-param' => sub( $message, $param ) {
            if ( my ($name) = $param =~ /\A name = " ((?:\w+-)*\w+) " \z/ax ) {

                # Note: RFC 9421 Sec 2.2.8 says named parameters with multiple values must not be included
                my @values = $message->uri->query_param($name);
                croak "multipe query-param values for '${name}'" if @values > 1;
                return $values[0];
            }
        },
    };

    croak "unsupported field ${name}" unless exists $handlers->{$name};

    my $quoted = "\"${name}\"";

    my ($param, @extra) = $field->params->keys;
    if ( defined $param ) {
        croak "extra parameters in field ${name}" if @extra;
        $quoted .= ";" . unquote($param);
    }

    return ( maybe $quoted => $handlers->{$name}->( $self->message, $param ) );
}


sub BUILDARGS( $, @args ) {

    my %args = @args == 1 && is_plain_hashref( $args[0] ) ? $args[0]->%* : @args;

    my $message = $args{message};
    if ( is_plain_hashref($message) ) {
        require Plack::Request;
        $args{message} = Plack::Request->new($message);

    }

    return \%args;
}


1;

__END__

=pod

=encoding UTF-8

=for stopwords Auth JWK pss rsa sha512

=head1 NAME

HTTP::Message::Signature - Verify HTTP Message Signatures (RFC 9421)

=head1 VERSION

version v0.0.3

=head1 SYNOPSIS

    use HTTP::Message::Signature;

    try {

        my $sig = HTTP::Message::Signature->new(
            message     => $request,         # HTTP::Request, Plack::Request or PSGI env hash
            require_tag => 'web-bot-auth',
        );

        $sig->is_expired and die "expired signature";

        $sig->verify or die "bad signature";

    }
    catch ($e) {

        ...

    }

=head1 STATUS

This module is an experimental prototype.

The user interface is subject to change.

See also L</KNOWN ISSUES> and L</SECURITY CONSIDERATIONS>.

=head1 DESCRIPTION

This module supports verifying HTTP Message Signatures (RFC 9421), notably those used for Web Bot Authentication.

=head1 ATTRIBUTES

=head2 message

This is an L<HTTP::Message> or a L<Plack::Request>.

Note that you can pass a L<PSGI> environment hash reference to the constructor.

This is required.

=head2 is_request

True if L</message> is a request.

=head2 is_response

True if L</message> is a response.

=head2 user_agent

The user agent used for requesting keys.

This is a L<HTTP::Tiny> object.

=head2 signature_agent

This is the signature agent from the C<Signature-Agent> header.

This should be a base URL but the actual value may be quoted.
Some agents may send a full URL.

=head2 signature_agent_uri

This is the URI for the L</signature_agent> JSON Web Key (JWK).

=head2 signature_input

This is the C<Signature-Input> header, parsed into a L<Hash::MultiValue> object.

=head2 signature_labels

This is an array of the labels from the L</signature_input>.

=head2 signature_header

This is the C<Signature> header, parsed into a L<Hash::MultiValue> object, where the keys are labels.

=head2 public_keys_json

This is the raw JSON of the L</public_keys>.

The keys will be fetched from L</signature_agent_uri>.

Cached keys should be saved here instead of L</public_keys>.

=head2 public_keys

This is the parsed L</public_keys_json>.

=head2 require_tag

When set, the L</verify> method requires the tag in the L</signature_input> header to be that value.

Set this to C<web-bot-auth> to verify bots.

=head2 has_require_tag

A predicate for L</require_tag>.

=head1 METHODS

=head2 is_expired

Returns true if the signature is expired.

This can be checked before verification to avoid the work of checking a signature.

=head2 verify

  $sig->verify( $label ) or die "Signature ${label} is not verified";

Returns true if the signature was verified.

The C<$label> defaults to the first L</signature_labels> if omitted.

=for Pod::Coverage BUILDARGS

=head1 KNOWN ISSUES

=head2 Signature Algorithms

The current version only supports the "ed25519" and "rsa-pss-sha512" algorithms.

=head2 Missing Signature-Agent headers

The current version does not support caching keys.

=head2 Multiple Signatures

The current version of this module does not support multiple signatures.

=head2 Content Digests

The L</verify> method only checks the signature.
If the signature includes a C<Content-Digest> header, then the digest of the message body will need to be validated separately.

=head1 SECURITY CONSIDERATIONS

=head2 Trusted Agents

Your application should use an allowed list of trusted agents, rather than attempt to verify arbitrary requests.

=head1 SEE ALSO

L<Web Bot Auth|https://datatracker.ietf.org/wg/webbotauth/about/>

L<HTTP Message Signatures for automated traffic|https://github.com/webbotauth/draft-ietf-webbotauth-httpsig-protocol/>

L<RFC 7517: JSON Web Key (JWK)|https://www.rfc-editor.org/info/rfc7517>

L<RFC 9421: HTTP Message Signatures|https://www.rfc-editor.org/info/rfc9421>

L<RFC 9651: Structured Field Values for HTTP|https://www.rfc-editor.org/info/rfc9651>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-HTTP-Message-Signature>
and may be cloned from L<https://github.com/robrwo/perl-HTTP-Message-Signature.git>

=head1 SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.24 or later.
Future releases may only support Perl versions released in the last ten (10) years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-HTTP-Message-Signature/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
