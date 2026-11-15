package Mail::DKIM2::Key;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.33';

use Scalar::Util ();
use MIME::Base64 qw(decode_base64);
use Crypt::PK::RSA;
use Crypt::PK::Ed25519;
use Crypt::Digest::SHA256 qw(sha256);
use Mail::DKIM2::TagValueList ();
use Mail::DKIM2::Util ();

use Exporter 'import';
our @EXPORT_OK = qw(
    signature_algorithm
    signature_algorithm_for_key
    load_private_key
    load_private_key_data
    parse_dkim_pubkey
    parse_dkim_key_record
    key_records
    domain_policy
    query_domain_policy
    policy_from_source
);

# The signing algorithms this library implements (-09 sections 3.2, 3.3),
# for the Signer and the Verifier alike: the key class each needs, how it
# signs and verifies the signing input of section 12.8, and the smallest key
# it accepts. Names are case-sensitive (section 2.14) and match exactly.
my %SIGNATURE_ALGORITHM = (
    'rsa-sha256' => {
        name      => 'rsa-sha256',
        key_class => 'Crypt::PK::RSA',
        min_bits  => 1024,    # section 3.2: Signers MUST use at least this
        sign      => sub { $_[0]->sign_message($_[1], 'SHA256', 'v1.5') },
        verify    => sub { $_[0]->verify_message($_[2], $_[1], 'SHA256', 'v1.5') },
    },
    'ed25519-sha256' => {
        name      => 'ed25519-sha256',
        key_class => 'Crypt::PK::Ed25519',
        # The SHA-256 of the input is what PureEdDSA signs (section 3.3).
        sign      => sub { $_[0]->sign_message(sha256($_[1])) },
        verify    => sub { $_[0]->verify_message($_[2], sha256($_[1])) },
    },
);

# signature_algorithm($name): the entry above for an s= item's algorithm
# name -- a hashref with name, key_class, sign->($key, $input) and
# verify->($key, $input, $signature), and min_bits for RSA -- or undef for a
# name this library does not implement.
sub signature_algorithm {
    my ($name) = @_;
    return defined $name ? $SIGNATURE_ALGORITHM{$name} : undef;
}

# signature_algorithm_for_key($key): the name of the algorithm a key object
# signs with, or undef for a key of no implemented type.
sub signature_algorithm_for_key {
    my ($key) = @_;
    return unless Scalar::Util::blessed($key);
    for my $name (sort keys %SIGNATURE_ALGORITHM) {
        return $name if $key->isa($SIGNATURE_ALGORITHM{$name}{key_class});
    }
    return;
}

# Load a private key from a PEM file.
# Returns a Crypt::PK::RSA or Crypt::PK::Ed25519 object depending on key type.
sub load_private_key {
    my ($file) = @_;
    # Try RSA first, then Ed25519
    my $key = eval { Crypt::PK::RSA->new($file) };
    die $@ if ref $@;
    return $key if $key;
    return Crypt::PK::Ed25519->new($file);
}

# Load a private key from key MATERIAL rather than a filename, for callers whose
# keys live in a database rather than on disk.
#
# Accepts PEM as stored, and also bare base64 with the armor stripped, which is
# how some key stores keep it. Returns a Crypt::PK::RSA or Crypt::PK::Ed25519
# object, or undef -- never dies, so a caller signing live mail can log and
# carry on rather than losing the message.
sub load_private_key_data {
    my ($data) = @_;
    return unless defined $data && length $data;

    if ($data =~ /-----BEGIN/) {
        my $key = eval { Crypt::PK::RSA->new(\$data) };
        die $@ if ref $@;
        return $key if $key;
        $key = eval { Crypt::PK::Ed25519->new(\$data) };
        die $@ if ref $@;
        return $key;
    }

    (my $b64 = $data) =~ s/\s+//g;
    return unless length $b64;
    my $der = eval { decode_base64($b64) };
    die $@ if ref $@;
    return unless defined $der && length $der;
    my $key = eval { Crypt::PK::RSA->new(\$der) };
    die $@ if ref $@;
    return $key if $key;
    $key = eval { Crypt::PK::Ed25519->new(\$der) };
    die $@ if ref $@;
    return $key;
}

# A key object from a valid record: the key, or nothing (a key type this
# library does not implement, or p= that is not a key of that type).
sub parse_dkim_pubkey {
    my ($key_txt) = @_;
    my ($key) = parse_dkim_key_record($key_txt);
    return $key;
}

# Parse and validate a key record (draft-ietf-dkim-dkim2-dns §3.2, §3.4.1;
# -09 §14.5 says a Verifier MUST NOT use a malformed one). Returns the
# key object, or (undef, $why) where $why completes "public key <selector>
# ...": "has a syntax error", "has been revoked" or "has an unsupported key
# type". The whole record is checked, not searched: a repeated tag (an empty
# p= before a good one, say) makes it invalid, and v=, if present, must be
# the first tag and exactly DKIM1. Tag names are case sensitive here, as in
# DKIM1. Unknown and retired tags (h=, n=, s=, t=) are ignored, once their
# values have passed the tag-list grammar.
sub parse_dkim_key_record {
    my ($txt) = @_;
    my $syntax = 'has a syntax error';
    my ($tag, $order) = _parse_dns_tag_list($txt) or return (undef, $syntax);
    my %tag = %$tag;
    if (exists $tag{v}) {
        return (undef, $syntax) unless $order->[0] eq 'v' && $tag{v} eq 'DKIM1';
    }
    return (undef, $syntax) unless exists $tag{p};
    (my $p = $tag{p}) =~ s/[ \t\r\n]//g;
    return (undef, 'has been revoked') unless length $p;
    return (undef, $syntax) unless Mail::DKIM2::Util::is_base64string($p);
    my $k = $tag{k} // 'rsa';
    my $key = _key_from_p($k, $p);
    return $key if $key;
    # -09 section 14.6 (contract E5): an RSA key this verifier regards as
    # too short.
    return (undef, 'too short') if $k eq 'rsa' && _rsa_bits($p);
    # -09 §14.5 (contract D7): base64 that is not a usable key of its type.
    return (undef, $k eq 'rsa' || $k eq 'ed25519' ? 'is malformed' : 'has an unsupported key type');
}

# A TXT record as a DNS tag=value list (DKIMKEYS -03 section 2.6: the
# Tag=Value rules of the spec's section 8): (\%tags, \@names_in_order), or
# the empty list for a syntax error -- a repeated tag, a spec that is not
# name=value, a value outside the tag-list grammar, or no tag at all. Tag
# names are case sensitive.
sub _parse_dns_tag_list {
    my ($txt) = @_;
    return unless defined $txt;
    my (%tag, @order);
    for my $spec (split /;/, $txt, -1) {
        next if $spec =~ /\A[ \t\r\n]*\z/;    # empty spec, e.g. after a trailing ";"
        my ($name, $value) = $spec =~ /\A[ \t\r\n]*([A-Za-z][A-Za-z0-9_]*)[ \t\r\n]*=(.*)\z/s
            or return;
        return if exists $tag{$name};
        $value = _trim_wsp($value);
        # Every value, unknown tags' included, must fit the tag-list grammar
        # (RFC 6376 §3.2 VALCHAR): ignoring a tag comes after parsing it
        # (follow-up review F5).
        return unless $value =~ /\A$Mail::DKIM2::TagValueList::TAG_VALUE\z/;
        $tag{$name} = $value;
        push @order, $name;
    }
    return unless @order;
    return (\%tag, \@order);
}

sub _key_from_p {
    my ($k, $p) = @_;
    if ($k eq 'ed25519') {
        # -09 §14.5: an Ed25519 key is exactly 32 octets (RFC 8032), the
        # raw key; anything else -- a DER SubjectPublicKeyInfo included --
        # is malformed. Never die on one: return undef so the verifier
        # reports a clean permerror instead of aborting the whole operation
        # (the RSA branch below is likewise eval-wrapped).
        my $raw = decode_base64($p);
        return unless length($raw) == 32;
        my $key = eval {
            my $pk = Crypt::PK::Ed25519->new();
            $pk->import_key_raw($raw, 'public');
            $pk;
        };
        die $@ if ref $@;
        return $key;
    }
    # Any other key type is unrecognised, and ignored: never read as RSA.
    return unless $k eq 'rsa';
    # RSA: p= is base64-encoded SubjectPublicKeyInfo DER. A key under
    # 1024 bits is too short: -09 section 3.2 leaves it to the Verifier, and
    # we refuse it (contract E5).
    my $der = decode_base64($p);
    my $rsa = eval { Crypt::PK::RSA->new(\$der) };
    die $@ if ref $@;
    return unless $rsa && $rsa->size * 8 >= 1024;
    return $rsa;
}

# True when $p (base64) loads as an RSA key, of whatever size: tells a key
# that is too short from one that is malformed.
sub _rsa_bits {
    my ($p) = @_;
    my $der = decode_base64($p);
    my $rsa = eval { Crypt::PK::RSA->new(\$der) };
    die $@ if ref $@;
    return $rsa ? $rsa->size * 8 : 0;
}

# key_records(@txt): the TXT records at a selector that are candidate key
# records (-09 section 3.7, DKIMKEYS -03 section 3): each one but those that
# begin with a "v=" tag whose value is not DKIM1. More than one left is the
# caller's "has multiple records".
sub key_records {
    return grep { my $v = _leading_v($_); !defined $v || $v eq 'DKIM1' } @_;
}

# The value of a TXT record's first tag when that tag is "v", else undef:
# read without parsing the rest, since -09 section 3.7 sorts records on it
# before any is used.
sub _leading_v {
    my ($txt) = @_;
    return unless defined $txt;
    $txt =~ /\A[ \t\r\n]*v[ \t\r\n]*=[ \t\r\n]*([^;]*?)[ \t\r\n]*(?:;|\z)/ or return;
    return $1;
}

# $s without leading or trailing WSP, in linear time: a TXT record is
# whatever the signer's DNS serves (up to 64 KB), and a trailing-WSP match
# tried at every position of a long inner run of spaces is quadratic. The
# lookbehind starts it only at the beginning of a run.
sub _trim_wsp {
    my ($s) = @_;
    $s =~ s/\A[ \t\r\n]+//;
    $s =~ s/(?<![ \t\r\n])[ \t\r\n]+\z//;
    return $s;
}

# domain_policy(@txt): the Domain Policy Record held by the TXT records at
# _domainkey.<domain> (-09 section 3.8, DKIMKEYS -03 section 6): 'strict'
# when subdomains are not authorized to make that domain's From Authentic,
# 'open' when they are (no record, no f=, or no "strict" flag), or
# 'multiple' for more than one record. Only records beginning with the tag
# v=DKIM1 count. A record that does so but does not parse is 'strict': the
# spec gives it no outcome, so it fails closed (contract E3.2).
sub domain_policy {
    my @dpr = grep { (_leading_v($_) // '') eq 'DKIM1' } @_;
    return 'open' unless @dpr;
    return 'multiple' if @dpr > 1;
    my ($tag) = _parse_dns_tag_list($dpr[0]) or return 'strict';
    my $f = $tag->{f};
    return 'open' unless defined $f && length $f;
    my @flags = map { _trim_wsp($_) } split /:/, $f, -1;
    return 'strict' if grep { !/\A[A-Za-z](?:[A-Za-z0-9-]*[A-Za-z0-9])?\z/ } @flags;
    return (grep { $_ eq 'strict' } @flags) ? 'strict' : 'open';
}

# query_domain_policy($resolver, $domain): the TXT records at
# _domainkey.$domain (each RR's strings joined) through $resolver's query(),
# as an arrayref; [] for NXDOMAIN or no TXT. Dies "TEMPERROR: ..." for any
# other failure.
sub query_domain_policy {
    my ($resolver, $dom) = @_;
    my $fqdn = "_domainkey.$dom";
    my $reply = $resolver->query($fqdn, 'TXT');
    unless ($reply) {
        my $err = $resolver->errorstring // '';
        return [] if $err =~ /^(?:NXDOMAIN|NOERROR|NODATA)\s*$/i;
        die "TEMPERROR: DNS lookup for $fqdn failed: $err\n";
    }
    return [ map { join '', $_->txtdata } grep { $_->type eq 'TXT' } $reply->answer ];
}

# policy_from_source($dom, $callback, $resolver_sub, @cb_args): the Domain
# Policy Record of $dom ('open', 'strict', 'multiple' or 'temperror') from
# $callback->($dom, @cb_args) when given, else query_domain_policy through
# $resolver_sub->(); a die (a TEMPERROR) is 'temperror', with the reason
# returned second.
sub policy_from_source {
    my ($dom, $callback, $resolver_sub, @cb_args) = @_;
    my $txt = eval {
        $callback ? $callback->($dom, @cb_args) : query_domain_policy($resolver_sub->(), $dom);
    };
    if (my $err = $@) {
        die $err if ref $err;
        (my $why = $err) =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
        return ('temperror', $why =~ s/\s+\z//r);
    }
    return domain_policy(@{ $txt || [] });
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Key - Keys, key records, Domain Policy Records and signing algorithms for DKIM2

=head1 SYNOPSIS

    use Mail::DKIM2::Key qw(load_private_key parse_dkim_pubkey signature_algorithm);

    my $key = load_private_key('/etc/dkim2/sel1.pem');
    my $pub = parse_dkim_pubkey('v=DKIM1; k=rsa; p=MIIB...');

=head1 DESCRIPTION

Private keys as a Signer takes them, the public key records and Domain
Policy Records a Verifier reads from the DNS (-09 sections 3.7, 3.8 and
14.5), and the table of signing algorithms both use (sections 3.2, 3.3).
Nothing is exported by default; L<Mail::DKIM2::Common> exports these too,
as it did before they moved here in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 FUNCTIONS

=head2 load_private_key($pem_file)

A L<Crypt::PK::RSA> or L<Crypt::PK::Ed25519> from a PEM file, whichever
it holds. Dies if the file is neither.

=head2 load_private_key_data($data)

The same from key material in memory: PEM, or bare base64 DER as some key
stores keep it. Returns undef rather than dying, so a signer of live mail
can log and carry on.

=head2 parse_dkim_key_record($txt_record)

Validates a whole key record (draft-ietf-dkim-dkim2-dns sections 3.2 and
3.4.1) and returns the public key object: a C<Crypt::PK::RSA> for C<k=rsa>
(the default) or a C<Crypt::PK::Ed25519> for C<k=ed25519>, the raw 32
octets of RFC 8463 (-09 section 14.5). Otherwise returns C<(undef, $why)>,
where C<$why> completes "public key E<lt>selectorE<gt> ...":

=over

=item C<has a syntax error>

Not a tag-list; a tag given twice; C<v=> present but not the first tag or
not exactly C<DKIM1>; no C<p=>; C<p=> not base64.

=item C<is malformed>

C<p=> is base64 but not a usable key of its type (-09 section 14.5): an
Ed25519 key that is not exactly 32 octets (DER included), or one that does
not load.

=item C<too short>

An RSA key of fewer than 1024 bits: -09 sections 3.2 and 14.6 leave it to
the Verifier, and this one refuses it (new in 0.29; it was C<is malformed>).

=item C<has been revoked>

An empty C<p=>.

=item C<has an unsupported key type>

A C<k=> other than C<rsa> or C<ed25519>.

=back

Unknown tags and the retired C<h=>, C<n=>, C<s=> and C<t=> are ignored.
Tag names are case sensitive, as in DKIM1.

=head2 query_domain_policy($resolver, $domain)

The TXT records at C<< _domainkey.<domain> >> through C<< $resolver->query >>,
each RR's strings joined, as an arrayref: empty for NXDOMAIN, NOERROR or
NODATA; dies with C<TEMPERROR:> otherwise. New in 0.29.

=head2 policy_from_source($domain, $callback, $resolver_sub, @callback_args)

The Domain Policy Record state of C<$domain> (C<open>, C<strict>,
C<multiple> or C<temperror>, with the reason second for C<temperror>), from
C<< $callback->($domain, @callback_args) >> when given, else
L</query_domain_policy> through C<< $resolver_sub->() >>. New in 0.29.

=head2 key_records(@txt)

The TXT records at a selector that are candidate key records (-09 section
3.7, draft-ietf-dkim-dkim2-dns-03 section 3): all but those that begin with
a C<v=> tag whose value is not C<DKIM1>. More than one left is the caller's
C<has multiple records>. New in 0.29.

=head2 domain_policy(@txt)

The Domain Policy Record held by the TXT records at
C<< _domainkey.<domain> >> (-09 section 3.8, draft-ietf-dkim-dkim2-dns-03
section 6): C<strict> when subdomains are not authorized to make that
domain's From Authentic, C<open> when they are (no record, no C<f=>, or no
C<strict> flag; unknown flags are ignored), C<multiple> for more than one
record. Only records whose first tag is C<v=DKIM1> count; one that does but
does not parse is C<strict> (it fails closed). New in 0.29.

=head2 parse_dkim_pubkey($txt_record)

The key object from C<parse_dkim_key_record>, or undef for a record that
gives no usable key.

=head2 signature_algorithm($name)

The signing algorithm named C<$name> in an C<s=> item (-09 sections 3.2,
3.3), as a hashref, or undef for one this library does not implement:
C<name>; C<key_class>, the class a key for it must be; C<sign>, called as
C<< ->($key, $signing_input) >> and returning the raw signature; C<verify>,
called as C<< ->($key, $signing_input, $signature) >>; and for
C<rsa-sha256>, C<min_bits> (1024). The L<Mail::DKIM2::Signer> and the
L<Mail::DKIM2::Verifier> both sign and verify through it. Names are
case-sensitive. New in 0.31.

=head2 signature_algorithm_for_key($key)

The name of the algorithm a key object signs with (C<rsa-sha256> for a
L<Crypt::PK::RSA>, C<ed25519-sha256> for a L<Crypt::PK::Ed25519>), or undef.
New in 0.31.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
