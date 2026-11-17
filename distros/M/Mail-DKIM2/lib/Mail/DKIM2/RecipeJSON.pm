package Mail::DKIM2::RecipeJSON;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.35';

use B ();
use Encode ();
use JSON;
use MIME::Base64 qw(encode_base64 decode_base64);

use Exporter 'import';
our @EXPORT_OK = qw(
    encode_tag_json
    decode_tag_json
    is_utf8_octets
);

# Encode data as base64 JSON for a tag value
sub encode_tag_json {
    my ($data) = @_;
    return encode_base64(JSON->new->canonical(1)->encode($data), '');
}

# Decode a base64 JSON tag value. The JSON text must be UTF-8 (RFC 8259
# section 8.1; -09 section 5): anything else dies. Every string in the
# result, object keys included, is UTF-8 octets, as the message's own
# header values and body lines are, so a literal compares and hashes
# byte for byte; a string holding a lone surrogate (a "\ud800" escape) is
# not UTF-8 and dies too.
sub decode_tag_json {
    my ($b64) = @_;
    my $octets = decode_base64($b64);
    my $text = eval { Encode::decode('UTF-8', $octets, Encode::FB_CROAK() | Encode::LEAVE_SRC()) };
    die $@ if ref $@;
    die "JSON text is not UTF-8\n" unless defined $text;
    my $data = JSON->new->decode($text);
    # A key given twice in one object is invalid here: JSON parsers disagree
    # on which value wins (first or last), so {"b":[...],"b":null} would be a
    # null body Recipe to some verifiers and signers and a real one to others.
    # A key that is not lowercase is invalid too (-09 §5).
    if (defined(my $error = _json_lexical_error($text))) {
        die $error;
    }
    return _json_octets($data);
}

# A decoded JSON value with every string -- object keys included --
# turned into UTF-8 octets. Numbers and booleans are returned untouched:
# MessageInstance tells a JSON integer from a JSON string by its flags.
sub _json_octets {
    my ($v) = @_;
    return { map { _json_octet_string($_) => _json_octets($v->{$_}) } keys %$v }
        if ref $v eq 'HASH';
    return [ map { _json_octets($_) } @$v ] if ref $v eq 'ARRAY';
    return $v if !defined $v || ref $v;
    return $v unless B::svref_2object(\$v)->FLAGS & B::SVf_POK;
    return _json_octet_string($v);
}

sub _json_octet_string {
    my ($s) = @_;
    die "JSON string is not UTF-8\n" if $s =~ /[\x{D800}-\x{DFFF}]/;
    utf8::encode($s);
    return $s;
}

# True if $octets is valid UTF-8 (ASCII included): strict, so no surrogate,
# nothing above U+10FFFF, no overlong form.
sub is_utf8_octets {
    my ($octets) = @_;
    return 1 unless $octets =~ /[^\x00-\x7F]/;
    my $ok = eval { Encode::decode('UTF-8', $octets, Encode::FB_CROAK() | Encode::LEAVE_SRC()); 1 };
    die $@ if ref $@;
    return $ok ? 1 : 0;
}

# The first problem the decoded value cannot show in $text (already known to
# be valid JSON), or undef: a key that is not lowercase (has an ASCII
# capital), a key that appears twice in one object, compared after
# unescaping, or a number with a fraction or
# an exponent. Every number in a Recipe is an integer (-09 section 5), and
# whether 1e0 decodes as an integer depends on the JSON backend -- JSON::XS
# gives an NV, JSON::PP an IV -- so it is refused here, from the text.
sub _json_lexical_error {
    my ($text) = @_;
    my $json = JSON->new->allow_nonref;
    my @stack;   # one entry per open container: undef for an array, a hash of keys for an object
    my $want_key = 0;
    pos($text) = 0;
    while (pos($text) < length $text) {
        if ($text =~ /\G\s+/gc) { next }
        if ($text =~ /\G\{/gc) { push @stack, {}; $want_key = 1; next }
        if ($text =~ /\G\[/gc) { push @stack, undef; $want_key = 0; next }
        if ($text =~ /\G[\}\]]/gc) { pop @stack; $want_key = 0; next }
        if ($text =~ /\G,/gc) { $want_key = ref $stack[-1] ? 1 : 0; next }
        if ($text =~ /\G:/gc) { next }
        if ($text =~ /\G("(?:[^"\\]|\\.)*")/gcs) {
            if ($want_key && ref $stack[-1]) {
                my $k = $json->decode($1);
                # -09 §5: keys MUST be lowercase (the -08 contract, D10).
                return "JSON object key is not lowercase\n" if $k =~ /[A-Z]/;
                return "duplicate JSON object key\n" if $stack[-1]{$k}++;
                $want_key = 0;
            }
            next;
        }
        $text =~ /\G([^\s,:\[\]\{\}"]+)/gc or last;   # number, true, false, null
        return "JSON number is not an integer\n" if $1 =~ /^-?[0-9].*[.eE]/;
    }
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::RecipeJSON - The base64 JSON of a Message-Instance r= tag

=head1 SYNOPSIS

    use Mail::DKIM2::RecipeJSON qw(encode_tag_json decode_tag_json);

    my $r    = encode_tag_json({ b => [ { c => [1, 4] } ] });
    my $data = decode_tag_json($r);

=head1 DESCRIPTION

Encoding and strict decoding of the JSON object a Message-Instance carries
in its C<r=> tag (-09 section 5). L<Mail::DKIM2::MessageInstance> checks
the Recipes themselves; this is the document they arrive in. Nothing is
exported by default; L<Mail::DKIM2::Common> exports these too, as it did
before they moved here in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 FUNCTIONS

=head2 encode_tag_json($data), decode_tag_json($base64)

Canonical JSON in base64, the encoding of the C<r=> Recipe tag. C<decode_tag_json> dies on invalid JSON, including JSON text that is not
UTF-8 and an object that gives the same key twice, compared without regard
to case (parsers disagree on which value wins). Every string it returns,
object keys included, is UTF-8 octets.

=head2 is_utf8_octets($octets)

True if C<$octets> is valid UTF-8 (ASCII included), strictly: no
surrogate, nothing above U+10FFFF, no overlong form. A Recipe literal that
is goes in a C<d> step; one that is not, in a C<u> step (-09 section 5).

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
