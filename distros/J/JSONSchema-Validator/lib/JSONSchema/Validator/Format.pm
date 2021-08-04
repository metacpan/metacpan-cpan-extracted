package JSONSchema::Validator::Format;

# ABSTRACT: Formats of JSON Schema specification

use strict;
use warnings;
use Time::Piece;

use Scalar::Util 'looks_like_number';

our @ISA = 'Exporter';
our @EXPORT_OK = qw(
    validate_date_time validate_date validate_time
    validate_email validate_hostname
    validate_idn_email
    validate_uuid
    validate_ipv4 validate_ipv6
    validate_byte
    validate_int32 validate_int64
    validate_float validate_double
    validate_regex
    validate_json_pointer validate_relative_json_pointer
    validate_uri validate_uri_reference
    validate_iri validate_iri_reference
    validate_uri_template
);

my $DATE_PATTERN = qr/(\d{4})-(\d\d)-(\d\d)/;
my $TIME_PATTERN = qr/(\d\d):(\d\d):(\d\d)(?:\.\d+)?/;
my $ZONE_PATTERN = qr/[zZ]|([+-])(\d\d):(\d\d)/;
my $DATETIME_PATTERN = qr/^${DATE_PATTERN}[tT ]${TIME_PATTERN}(?:${ZONE_PATTERN})?$/;
my $DATE_PATTERN_FULL = qr/\A${DATE_PATTERN}\z/;
my $TIME_PATTERN_FULL = qr/\A${TIME_PATTERN}(?:${ZONE_PATTERN})?\z/;
my $HEX_PATTERN = qr/[0-9A-Fa-f]/;
my $UUID_PATTERN = qr/\A${HEX_PATTERN}{8}-${HEX_PATTERN}{4}-${HEX_PATTERN}{4}-[089abAB]${HEX_PATTERN}{3}-${HEX_PATTERN}{12}\z/;
my $IPV4_OCTET_PATTERN = qr/\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]/;
my $IPV4_PATTERN = qr/${IPV4_OCTET_PATTERN}(?:\.${IPV4_OCTET_PATTERN}){3}/;
my $IPV4_FINAL_PATTERN = qr/\A${IPV4_PATTERN}\z/;
my $IPV6_SINGLE_PATTERN = qr/\A(?:${HEX_PATTERN}{1,4}:){7}${HEX_PATTERN}{1,4}\z/;
my $IPV6_GROUP_PATTERN = qr/(?:${HEX_PATTERN}{1,4}:)*${HEX_PATTERN}{1,4}/;
my $IPV6_MULTI_GROUP_PATTERN = qr/\A(?:${IPV6_GROUP_PATTERN}|)::(?:${IPV6_GROUP_PATTERN}|)\z/;
my $IPV6_SINGLE_IPV4_PATTERN = qr/\A((?:${HEX_PATTERN}{1,4}:){6})((?:\d{1,3}\.){3}\d{1,3})\z/;
my $IPV6_MULTI_GROUP_IPV4_PATTERN = qr/\A((?:${IPV6_GROUP_PATTERN}|)::(?:${IPV6_GROUP_PATTERN}:|))((?:\d{1,3}\.){3}\d{1,3})\z/;
my $BASE64_PATTERN = qr/\A(?:|[A-Za-z0-9\+\/]+=?=?)\z/;
my $INTEGER_PATTERN = qr/\A[\+\-]?\d+\z/;
my $UCSCHAR_PATTERN = qr/
    [\x{A0}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}] |
    [\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}] |
    [\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}] |
    [\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}] |
    [\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}] |
    [\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}]
/x;
my $IPRIVATE_PATTERN = qr/[\x{E000}-\x{F8FF}\x{F0000}-\x{FFFFD}\x{100000}-\x{10FFFD}]/;
my $IPV6_PATTERN = do {
    my $HEXDIG = qr/[A-Fa-f0-9]/;
    my $h16 = qr/${HEXDIG}{1,4}/;
    my $ls32 = qr/(?:${h16}:${h16})|${IPV4_PATTERN}/;
    qr/
                                        (?:${h16}:){6} ${ls32} |
                                        :: (?:${h16}:){5} ${ls32} |
        (?:                 ${h16})? :: (?:${h16}:){4} ${ls32} |
        (?:(?:${h16}:){0,1} ${h16})? :: (?:${h16}:){3} ${ls32} |
        (?:(?:${h16}:){0,2} ${h16})? :: (?:${h16}:){2} ${ls32} |
        (?:(?:${h16}:){0,3} ${h16})? :: (?:${h16}:){1} ${ls32} |
        (?:(?:${h16}:){0,4} ${h16})? ::                ${ls32} |
        (?:(?:${h16}:){0,5} ${h16})? ::                ${h16} |
        (?:(?:${h16}:){0,6} ${h16})? ::
    /x;
};
my $IPV6_FINAL_PATTERN = qr/\A${IPV6_PATTERN}\z/;

my $HOSTNAME_PATTERN = do {
    my $ldh_str = qr/(?:[A-Za-z0-9\-])+/;
    my $label = qr/[A-Za-z](?:(?:${ldh_str})?[A-Za-z0-9])?/;
    qr/\A${label}(?:\.${label})*\z/;
};

my $EMAIL_PATTERN = do {
    use re 'eval';
    my $obs_NO_WS_CTL = qr/[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]/;
    my $obs_qp = qr/\\(?:\x00|${obs_NO_WS_CTL}|\n|\r)/;
    my $quoted_pair = qr/\\(?:[\x21-\x7e]|[ \t])|${obs_qp}/;
    my $obs_FWS = qr/[ \t]+(?:\r\n[ \t]+)*/;
    my $FWS = qr/(?:[ \t]*\r\n)?[ \t]+|${obs_FWS}/;
    my $ctext = qr/[\x21-\x27\x2a-\x5b\x5d-\x7e]|${obs_NO_WS_CTL}/;
    my $comment;
    $comment = qr/\((?:(?:${FWS})?(?:${ctext}|${quoted_pair}|(??{$comment})))*(?:${FWS})?\)/;
    my $CFWS = qr/(?:(?:${FWS})?${comment})+(?:${FWS})?|${FWS}/;
    my $atext = qr/[A-Za-z0-9!#\$\%&'*+\/=?\^_`{|}~\-]/;
    my $dot_atom_text = qr/(?:${atext})+(?:\.(?:${atext})+)*/;
    my $dot_atom = qr/(?:${CFWS})?${dot_atom_text}(?:${CFWS})?/;
    my $obs_dtext = qr/${obs_NO_WS_CTL}|${quoted_pair}/;
    my $dtext = qr/[\x21-\x5a\x5e-\x7e]|${obs_dtext}/;
    my $domain_literal = qr/(?:${CFWS})?\[(?:(?:${FWS})?${dtext})*(?:${FWS})?\](?:${CFWS})?/;
    my $obs_qtext = $obs_NO_WS_CTL;
    my $qtext = qr/[\x21\x23-\x5b\x5d-\x7e]|${obs_qtext}/;
    my $qcontent = qr/${qtext}|${quoted_pair}/;
    my $quoted_string = qr/(?:${CFWS})?\x22(?:(?:${FWS})?${qcontent})*(?:${FWS})?\x22(?:${CFWS})?/;
    my $atom = qr/(?:${CFWS})?(?:${atext})+(?:${CFWS})?/;
    my $word = qr/${atom}|${quoted_string}/;
    my $obs_local_part = qr/${word}(?:\.${word})*/;
    my $local_part = qr/${dot_atom}|${quoted_string}|${obs_local_part}/;
    my $obs_domain = qr/${atom}(?:\.${atom})*/;
    my $domain = qr/${dot_atom}|${domain_literal}|${obs_domain}/;
    qr/\A${local_part}\@${domain}\z/;
};

my $IDN_EIMAIL_PATTERN = do {
    # from rfc3629 UTF-{1,4} given in octet sequence of utf8
    # transform it to unicode number
    my $UTF8_non_ascii = qr/
        [\x80-\x{D7FF}] | [\x{E000}-\x{FDCF}] | [\x{FDF0}-\x{FFFD}] |
        [\x{10000}-\x{1FFFD}] | [\x{20000}-\x{2FFFD}] | [\x{30000}-\x{3FFFD}] |
        [\x{40000}-\x{4fffd}] | [\x{50000}-\x{5fffd}] | [\x{60000}-\x{6fffd}] |
        [\x{70000}-\x{7fffd}] | [\x{80000}-\x{8fffd}] | [\x{90000}-\x{9fffd}] |
        [\x{a0000}-\x{afffd}] | [\x{b0000}-\x{bfffd}] | [\x{c0000}-\x{cfffd}] |
        [\x{d0000}-\x{dfffd}] | [\x{e0000}-\x{efffd}] | [\x{f0000}-\x{ffffd}] |
        [\x{100000}-\x{10fffd}]
    /x;
    my $atext = qr/[A-Za-z0-9!#\$\%&'*+\/=?\^_`{|}~\-]|${UTF8_non_ascii}/;
    my $quoted_pairSMTP = qr/\x5c[\x20-\x7e]/;
    my $qtextSMTP = qr/[\x20\x21\x23-\x5b\x5d-\x7e]|${UTF8_non_ascii}/;
    my $QcontentSMTP = qr/${qtextSMTP}|${quoted_pairSMTP}/;
    my $quoted_string = qr/\x22(?:${QcontentSMTP})*\x22/;
    my $atom = qr/(?:${atext})+/;
    my $dot_string = qr/${atom}(?:\.${atom})*/;
    my $local_part = qr/${dot_string}|${quoted_string}/;
    my $let_dig = qr/[A-Za-z0-9]/;
    my $ldh_str = qr/(?:[A-Za-z0-9\-])*${let_dig}/;
    my $Standardized_tag = qr/${ldh_str}/;
    my $dcontent = qr/[\x21-\x5a\x5e-\x7e]/;
    my $General_address_literal = qr/${Standardized_tag}:(?:${dcontent})+/;
    my $IPv6_address_literal = qr/IPv6:${IPV6_PATTERN}/;
    my $address_literal = qr/\[(?:${IPV4_PATTERN}|${IPv6_address_literal}|${General_address_literal})\]/;
    my $sub_domain = qr/${let_dig}(?:${ldh_str})?|(?:${UCSCHAR_PATTERN})*/; # couldn't find ABNF for U-label from rfc5890 use ucschar instead
    my $domain = qr/${sub_domain}(?:\.${sub_domain})*/;
    qr/\A${local_part}\@(?:${domain}|${address_literal})\z/;
};

sub URI_IRI_REGEXP_BUILDER {
    my $is_iri = shift;

    my $alpha = qr/[A-Za-z]/;
    my $HEXDIG = qr/[A-Fa-f0-9]/;
    my $h16 = qr/${HEXDIG}{1,4}/;
    my $sub_delims = qr/[!\$&'\(\)\*\+,;=]/;
    my $gen_delims = qr/[:\/\?#\[\]\@]/;
    my $reserved = qr/${gen_delims}|${sub_delims}/;
    my $unreserved = qr/${alpha}|\d|\-|\.|_|~/;
    my $iunreserved = $unreserved;
    if ($is_iri) {
        $iunreserved = qr/${alpha}|\d|\-|\.|_|~|${UCSCHAR_PATTERN}/;
    }
    my $pct_encoded = qr/\%${HEXDIG}${HEXDIG}/;
    my $pchar = qr/${iunreserved}|${pct_encoded}|${sub_delims}|:|\@/;
    my $fragment = qr/(?:${pchar}|\/|\?)*/;
    my $query = qr/(?:${pchar}|\/|\?)*/;
    if ($is_iri) {
        $query = qr/(?:${pchar}|${IPRIVATE_PATTERN}|\/|\?)*/;
    }
    my $segment_nz_nc = qr/(?:${iunreserved}|${pct_encoded}|${sub_delims}|\@)+/;
    my $segment_nz = qr/(?:${pchar})+/;
    my $segment = qr/(?:${pchar})*/;
    my $path_rootless = qr/${segment_nz}(?:\/${segment})*/;
    my $path_noscheme = qr/${segment_nz_nc}(?:\/${segment})*/;
    my $path_absolute = qr/\/(?:${segment_nz}(?:\/${segment})*)?/;
    my $path_abempty = qr/(?:\/${segment})*/;
    my $reg_name = qr/(?:${iunreserved}|${pct_encoded}|${sub_delims})*/;
    my $IPvFuture = qr/v${HEXDIG}+\.(?:${unreserved}|${sub_delims}|:)+/; # must be unreserved, not iunreserved
    my $IP_literal = qr/\[(?:${IPV6_PATTERN}|${IPvFuture})\]/;
    my $port = qr/\d*/;
    my $host = qr/${IP_literal}|${IPV4_PATTERN}|${reg_name}/;
    my $userinfo = qr/(?:${iunreserved}|${pct_encoded}|${sub_delims}|:)*/;
    my $authority = qr/(?:${userinfo}\@)?${host}(?::${port})?/;
    my $scheme = qr/${alpha}(?:${alpha}|\d|\+|\-|\.)*/;
    my $hier_part = qr!//${authority}${path_abempty}|${path_absolute}|${path_rootless}|!;
    my $uri = qr/\A${scheme}:${hier_part}(?:\?${query})?(?:#${fragment})?\z/;
    my $relative_part = qr!//${authority}${path_abempty}|${path_absolute}|${path_noscheme}|!;
    my $relative_ref = qr/\A${relative_part}(?:\?${query})?(?:#${fragment})?\z/;
    my $uri_reference = qr/${uri}|${relative_ref}/;
    ($uri, $uri_reference);
}

my ($URI_PATTERN, $URI_REFERENCE_PATTERN) = URI_IRI_REGEXP_BUILDER(0);
my ($IRI_PATTERN, $IRI_REFERENCE_PATTERN) = URI_IRI_REGEXP_BUILDER(1);

my $URI_TEMPLATE_PATTERN = do {
    my $alpha = qr/[A-Za-z]/;
    my $HEXDIG = qr/[A-Fa-f0-9]/;
    my $pct_encoded = qr/\%${HEXDIG}${HEXDIG}/;
    my $unreserved = qr/${alpha}|\d|\-|\.|_|~/;
    my $sub_delims = qr/[!\$&'\(\)\*\+,;=]/;
    my $gen_delims = qr/[:\/\?#\[\]\@]/;
    my $reserved = qr/${gen_delims}|${sub_delims}/;
    my $explode = qr/\*/;
    my $max_length = qr/[1-9]\d{0,3}/;
    my $prefix = qr/:${max_length}/;
    my $modifier_level4 = qr/${prefix}|${explode}/;
    my $varchar = qr/${alpha}|\d|_|${pct_encoded}/;
    my $varname = qr/${varchar}(?:\.?${varchar})*/;
    my $varspec = qr/${varname}(?:${modifier_level4})?/;
    my $variable_list = qr/${varspec}(?:,${varspec})*/;
    my $op_reserve = qr/[=,!\@\|]/;
    my $op_level3 = qr/[\.\/;\?&]/;
    my $op_level2 = qr/[\+#]/;
    my $operator = qr/${op_level2}|${op_level3}|${op_reserve}/;
    my $expression = qr/\{(?:${operator})?${variable_list}\}/;
    my $literals = qr/
        [\x21\x23\x24\x26\x28-\x3B\x3D\x3F-\x5B] |
        [\x5D\x5F\x61-\x7A\x7E] |
        ${UCSCHAR_PATTERN} |
        ${IPRIVATE_PATTERN} |
        ${pct_encoded}
    /x;
    qr/\A(?:${literals}|${expression})*\z/;
};

sub validate_date_time {
    my @dt = $_[0] =~ $DATETIME_PATTERN;

    my ($Y, $m, $d, $H, $M, $S, $sign, $HH, $MM) = @dt;

    my $r = _validate_date($Y, $m, $d);
    return 0 unless $r;

    $r = _validate_time($H, $M, $S, $sign, $HH, $MM);
    return 0 unless $r;

    return 1;
}

sub validate_date {
    my @dt = $_[0] =~ $DATE_PATTERN_FULL;
    return _validate_date(@dt);
}

sub _validate_date {
    my ($Y, $m, $d) = @_;

    for ($Y, $m, $d) {
        return 0 unless defined $_;
    }

    my $date2;
    eval { $date2 = Time::Piece->strptime("$Y-$m-$d", '%Y-%m-%d'); };
    return 0 if $@;

    # need to recheck values (test 2019-02-30)
    return 0 unless $date2->year == $Y;
    return 0 unless $date2->mon == $m;
    return 0 unless $date2->mday == $d;

    return 1;
}

sub validate_time {
    my @dt = $_[0] =~ $TIME_PATTERN_FULL;
    return _validate_time(@dt);
}

sub _validate_time {
    my ($H, $M, $S, $sign, $HH, $MM) = @_;

    for ($H, $M, $S) {
        return 0 unless defined $_;
    }

    return 0 if $H > 23;
    return 0 if $M > 59;
    return 0 if $S > 60;

    if ($HH && $MM) {
        return 0 if $HH > 23;
        return 0 if $MM > 59;
    }

    return 1;
}

sub validate_uuid {
    # from rfc4122
    # Today, there are versions 1-5. Version 6-F for future use.
    # [089abAB] - variants
    return $_[0] =~ $UUID_PATTERN ? 1 : 0;
}

sub validate_ipv4 {
    # from rfc2673
    return $_[0] =~ $IPV4_FINAL_PATTERN ? 1 : 0;
}

sub validate_ipv6 {
    # from rfc2373
    return $_[0] =~ $IPV6_FINAL_PATTERN ? 1 : 0;
}

sub validate_hostname {
    # from rfc1034
    my $hostname = shift;
    return 0 if length $hostname > 255;

    # remove root empty label
    $hostname =~ s/\.\z//;

    return 0 unless $hostname =~ $HOSTNAME_PATTERN;

    my @labels = split /\./, $hostname, -1;
    my @filtered = grep { length() <= 63 } @labels;
    return 0 unless scalar(@labels) == scalar(@filtered);
    return 1;
}

sub validate_email {
    # from rfc5322 section 3.4.1 addr-spec
    # not compatible with rfc5321 section 4.1.2 Mailbox
    return $_[0] =~ $EMAIL_PATTERN ? 1 : 0;
}

sub validate_idn_email {
    # from rfc6531 section 3.3 which extend rfc5321 section 4.1.2
    # not compatible with rfc5322 section 3.4.1 add-spec
    return $_[0] =~ $IDN_EIMAIL_PATTERN ? 1 : 0;
}

sub validate_byte {
    return 0 if length($_[0]) % 4 != 0;
    return 1 if $_[0] =~ $BASE64_PATTERN;
    return 0;
}

sub validate_int32 {
    return _validate_int_32_64($_[0], '214748364');
}

sub validate_int64 {
    return _validate_int_32_64($_[0], '922337203685477580');
}

sub _validate_int_32_64 {
    my ($num, $abs) = @_;
    return 0 unless $num =~ $INTEGER_PATTERN;

    my $sign = index($num, '-') == -1 ? 1 : -1;
    $num =~ s/\A[\+\-]?0*//;

    my $length_num = length $num;
    my $length_abs = 1 + length $abs;

    return 0 if $length_num > $length_abs;
    return 1 if $length_num < $length_abs;

    return 1 if $sign > 0 && (($abs . '7') cmp $num) >= 0;
    return 1 if $sign < 0 && (($abs . '8') cmp $num) >= 0;
    return 0;
}

sub validate_json_pointer {
    # from rfc6901:
    # CORE::state $pointer_regexp = do {
    #     my $escaped = qr/~[01]/;
    #     my $unescaped = qr/\x00-\x2e\x30-\x7d\x7f-\x10FFFF/;
    #     my $reference_token = qr/(?:${unescaped}|${escaped})*/;
    #     qr/(?:\/${reference_token})*/;
    # };

    # more simple solution:
    return 1 if $_[0] eq '';
    return 0 unless index($_[0], '/') == 0;
    return 0 if $_[0] =~ m/~(?:[^01]|\z)/;
    return 1;
}

sub validate_relative_json_pointer {
    # from draft-handrews-relative-json-pointer-01:
    # CORE::state $pointer_regexp = do {
    #     my $non_negative_integer = qr/0|[1-9][0-9]*/;
    #     my $relative_json_pointer = qr/${non_negative_integer}(?:#|${json_pointer})/;
    # };

    # more simple solution:
    my ($integer, $pointer) = $_[0] =~ m/\A(0|[1-9][0-9]*)(.*)\z/s;
    return 0 unless defined $integer;
    return 1 if $pointer eq '#';
    return validate_json_pointer($pointer);
}

sub validate_uri {
    # from rfc3986 Appendix A.
    return $_[0] =~ $URI_PATTERN ? 1 : 0;
}

sub validate_uri_reference {
    # from rfc3986 Appendix A.
    return $_[0] =~ $URI_REFERENCE_PATTERN ? 1 : 0;
}

sub validate_iri {
    # from rfc3987 section 2.2
    return $_[0] =~ $IRI_PATTERN ? 1 : 0;
}

sub validate_iri_reference {
    # from rfc3987 section 2.2
    return $_[0] =~ $IRI_REFERENCE_PATTERN ? 1 : 0;
}

sub validate_uri_template {
    # from rfc6570
    return $_[0] =~ $URI_TEMPLATE_PATTERN ? 1 : 0;
}

# validators below need to be improved

# no difference between double and float
sub validate_float {
    return 0 if $_[0] =~ m/\A\s+|\s+\z/;
    return 0 unless looks_like_number $_[0];
    return 1;
}

sub validate_double {
    return validate_float($_[0]);
}

# match perl regex but need ecma-262 regex
sub validate_regex {
    return eval { qr/$_[0]/; } ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Format - Formats of JSON Schema specification

=head1 VERSION

version 0.005

=head1 AUTHORS

=over 4

=item *

Alexey Stavrov <logioniz@ya.ru>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

Anton Fedotov <tosha.fedotov.2000@gmail.com>

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Andrey Khozov <andrey@rydlab.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
