package GDPR::IAB::TCFv2::Parser 0.530;

use v5.12;
use warnings;
use integer;
use bytes;

use Carp         qw<carp croak>;
use MIME::Base64 qw<decode_base64>;
use POSIX        qw<strftime>;

use GDPR::IAB::TCFv2::BitField;
use GDPR::IAB::TCFv2::BitUtils qw<is_set
  get_uint3
  get_uint6
  get_uint12
  get_uint16
  get_uint36
  get_char6_pair
>;
use GDPR::IAB::TCFv2::Publisher;
use GDPR::IAB::TCFv2::RangeSection;
use GDPR::IAB::TCFv2::Constants::RestrictionType qw<:all>;

use constant {
  CONSENT_STRING_TCF_V2   => {SEPARATOR => quotemeta q<.>, PREFIX => q<C>, MIN_BYTE_SIZE => 29,},
  EXPECTED_TCF_V2_VERSION => 2,
  MAX_SPECIAL_FEATURE_ID  => 12,
  MAX_PURPOSE_ID          => 24,
  DATE_FORMAT_ISO_8601    => '%Y-%m-%dT%H:%M:%SZ',
  TCF_V23_DEADLINE        => 1772236800,                                                          # 2026-02-28T00:00:00Z
  SEGMENT_TYPES           => {CORE => 0, DISCLOSED_VENDORS => 1, ALLOWED_VENDORS => 2, PUBLISHER_TC => 3,},
  OFFSETS                 => {
    SEGMENT_TYPE            => 0,
    VERSION                 => 0,
    CREATED                 => 6,
    LAST_UPDATED            => 42,
    CMP_ID                  => 78,
    CMP_VERSION             => 90,
    CONSENT_SCREEN          => 102,
    CONSENT_LANGUAGE        => 108,
    VENDOR_LIST_VERSION     => 120,
    POLICY_VERSION          => 132,
    SERVICE_SPECIFIC        => 138,
    USE_NON_STANDARD_STACKS => 139,
    SPECIAL_FEATURE_OPT_IN  => 140,
    PURPOSE_CONSENT_ALLOWED => 152,
    PURPOSE_LIT_ALLOWED     => 176,
    PURPOSE_ONE_TREATMENT   => 200,
    PUBLISHER_COUNTRY_CODE  => 201,
    VENDOR_CONSENT          => 213,
  },
};

use overload q<""> => \&tc_string;

# ABSTRACT: gdpr iab tcf v2.3 consent string parser

sub Parse {
  my ($klass, $tc_string, %opts) = @_;

  croak 'missing gdpr consent string' unless defined $tc_string && length $tc_string;

  my $segments = _decode_tc_string_segments($tc_string);

  my $strict = !!$opts{strict};

  my %options = (json => $opts{json} // {}, strict => $strict, reference_time => $opts{reference_time},);

  $options{json}->{date_format}    ||= DATE_FORMAT_ISO_8601;
  $options{json}->{boolean_values} ||= [_json_false(), _json_true()];

  if (exists $opts{prefetch}) {
    my $prefetch = $opts{prefetch};

    $prefetch = [$prefetch] if ref($prefetch) ne ref([]);

    $options{prefetch} = $prefetch;
  }

  my $self = {
    core_data              => $segments->{core_data},
    disclosed_vendors_data => $segments->{disclosed_vendors},
    allowed_vendors_data   => $segments->{allowed_vendors},
    publisher_tc_data      => $segments->{publisher_tc},
    options                => \%options,
    tc_string              => $tc_string,

    vendor_consents             => undef,
    vendor_legitimate_interests => undef,
    publisher                   => undef,
    disclosed_vendors           => undef,
    allowed_vendors             => undef,
  };

  bless $self, $klass;

  croak "consent string is not tcf version @{[ EXPECTED_TCF_V2_VERSION ]}"
    if $strict && $self->version != EXPECTED_TCF_V2_VERSION;

  croak 'invalid vendor list version' if $self->vendor_list_version == 0;

  # TCF v2.3: Mandatory Disclosed Vendors segment check
  if ($strict && $self->is_v23) {
    croak "TCF v2.3: Disclosed Vendors segment is mandatory" unless $self->has_vendor_disclosure;
  }

  my $next_offset = $self->_parse_vendor_section();

  $self->_parse_publisher_section($next_offset);

  $self->_parse_disclosed_vendors();
  $self->_parse_allowed_vendors();

  return $self;
}

sub tc_string {
  my $self = shift;

  return $self->{tc_string};
}

sub version {
  my $self = shift;

  return scalar(get_uint6($self->{core_data}, OFFSETS->{VERSION}));
}

sub created {
  my $self = shift;

  my ($seconds, $nanoseconds) = $self->_get_epoch(OFFSETS->{CREATED});

  return wantarray ? ($seconds, $nanoseconds) : $seconds;
}

sub last_updated {
  my $self = shift;

  my ($seconds, $nanoseconds) = $self->_get_epoch(OFFSETS->{LAST_UPDATED});

  return wantarray ? ($seconds, $nanoseconds) : $seconds;
}

sub _get_epoch {
  my ($self, $offset) = @_;

  # Drop the file-level `use integer` for this scope. TCF v2 stores
  # Created and LastUpdated as a 36-bit deciseconds-since-epoch field,
  # which exceeds a 32-bit signed IV. On a Perl built without 64-bit
  # ints (e.g. the armv6l smokers), `get_uint36` returns the value as
  # an NV via Math::BigInt->numify; the C-integer `/` and `%` of
  # `use integer` would then coerce that NV back into an overflowing
  # 32-bit IV. NV float math keeps full precision (36 bits fits in
  # the 53-bit mantissa) and lands a correct integer result via int().
  no integer;

  my $deciseconds = scalar(get_uint36($self->{core_data}, $offset));

  my $seconds     = int($deciseconds / 10);
  my $nanoseconds = int(($deciseconds - $seconds * 10) * 100_000_000);

  return ($seconds, $nanoseconds);
}

sub cmp_id {
  my $self = shift;

  return scalar(get_uint12($self->{core_data}, OFFSETS->{CMP_ID}));
}

sub cmp_version {
  my $self = shift;

  return scalar(get_uint12($self->{core_data}, OFFSETS->{CMP_VERSION}));
}

sub consent_screen {
  my $self = shift;

  return scalar(get_uint6($self->{core_data}, OFFSETS->{CONSENT_SCREEN}));
}

sub consent_language {
  my $self = shift;

  return scalar(get_char6_pair($self->{core_data}, OFFSETS->{CONSENT_LANGUAGE}));
}

sub vendor_list_version {
  my $self = shift;

  return scalar(get_uint12($self->{core_data}, OFFSETS->{VENDOR_LIST_VERSION}));
}

sub policy_version {
  my $self = shift;

  return scalar(get_uint6($self->{core_data}, OFFSETS->{POLICY_VERSION}));
}

sub is_v22_plus {
  my $self = shift;
  return $self->policy_version >= 4 ? 1 : 0;
}

sub is_v23 {
  my $self     = shift;
  my $deadline = TCF_V23_DEADLINE;

  # If a reference_time was provided and it is BEFORE the deadline,
  # we skip all v2.3 checks to allow total historical simulation.
  if (defined $self->{options}->{reference_time} && $self->{options}->{reference_time} < $deadline) {
    return 0;
  }

  return 1 if $self->policy_version >= 5;

  # TCF v2.3 became mandatory on 2026-02-28. Strings created on or after
  # this date are subject to v2.3 rules (e.g. mandatory Disclosed Vendors).
  return 1 if $self->created >= $deadline;

  return 0;
}

sub is_service_specific {
  my $self = shift;

  return scalar(is_set($self->{core_data}, OFFSETS->{SERVICE_SPECIFIC}));
}

sub use_non_standard_stacks {
  my $self = shift;

  return scalar(is_set($self->{core_data}, OFFSETS->{USE_NON_STANDARD_STACKS}));
}

sub is_special_feature_opt_in {
  my ($self, $id) = @_;

  croak "invalid special feature id $id: must be between 1 and @{[ MAX_SPECIAL_FEATURE_ID ]}"
    if $id < 1 || $id > MAX_SPECIAL_FEATURE_ID;

  return $self->_safe_is_special_feature_opt_in($id);
}

sub _safe_is_special_feature_opt_in {
  my ($self, $id) = @_;

  return scalar(is_set($self->{core_data}, OFFSETS->{SPECIAL_FEATURE_OPT_IN} + $id - 1));
}

sub is_purpose_consent_allowed {
  my ($self, @ids) = @_;

  $self->_validate_purpose_ids('is_purpose_consent_allowed', @ids);

  foreach my $id (@ids) {
    return 0 unless $self->_safe_is_purpose_consent_allowed($id);
  }

  return 1;
}

sub _safe_is_purpose_consent_allowed {
  my ($self, $id) = @_;
  return scalar(is_set($self->{core_data}, OFFSETS->{PURPOSE_CONSENT_ALLOWED} + $id - 1));
}

sub is_purpose_legitimate_interest_allowed {
  my ($self, @ids) = @_;

  $self->_validate_purpose_ids('is_purpose_legitimate_interest_allowed', @ids);

  foreach my $id (@ids) {

    # SPEC: Purpose 1 never allows Legitimate Interest
    return 0 if $id == 1;

    # SPEC: TCF v2.2+ (Policy >= 4) prohibits LI for Purposes 3, 4, 5, and 6
    if ($self->is_v22_plus) {
      return 0 if $id >= 3 && $id <= 6;
    }

    return 0 unless $self->_safe_is_purpose_legitimate_interest_allowed($id);
  }

  return 1;
}

sub _validate_purpose_ids {
  my ($self, $method_name, @ids) = @_;

  croak "method $method_name requires at least one argument" unless @ids;

  foreach my $id (@ids) {
    croak "invalid purpose id $id: must be between 1 and @{[ MAX_PURPOSE_ID ]}" if $id < 1 || $id > MAX_PURPOSE_ID;
  }
}

sub _safe_is_purpose_legitimate_interest_allowed {
  my ($self, $id) = @_;

  return scalar(is_set($self->{core_data}, OFFSETS->{PURPOSE_LIT_ALLOWED} + $id - 1));
}

sub purpose_one_treatment {
  my $self = shift;

  return scalar(is_set($self->{core_data}, OFFSETS->{PURPOSE_ONE_TREATMENT}));
}

sub publisher_country_code {
  my $self = shift;

  return scalar(get_char6_pair($self->{core_data}, OFFSETS->{PUBLISHER_COUNTRY_CODE}));
}

sub max_vendor_id_consent {
  my $self = shift;

  return $self->{vendor_consents}->max_id;
}

sub max_vendor_id_legitimate_interest {
  my $self = shift;

  return $self->{vendor_legitimate_interests}->max_id;
}

sub vendor_consent {
  my ($self, $id) = @_;

  return $self->{vendor_consents}->contains($id);
}

sub vendor_legitimate_interest {
  my ($self, $id) = @_;

  return $self->{vendor_legitimate_interests}->contains($id);
}

sub disclosed_vendor {
  my ($self, $id) = @_;

  return 0 unless defined $self->{disclosed_vendors};

  return $self->{disclosed_vendors}->contains($id);
}

sub has_vendor_disclosure {
  my $self = shift;
  return defined $self->{disclosed_vendors} ? 1 : 0;
}

sub allowed_vendor {
  my ($self, $id) = @_;

  return 0 unless defined $self->{allowed_vendors};

  return $self->{allowed_vendors}->contains($id);
}

sub check_publisher_restriction {
  my $self = shift;

  my ($purpose_id, $restriction_type, $vendor_id);

  if (scalar(@_) == 6) {
    my (%opts) = @_;

    $purpose_id       = $opts{purpose_id};
    $restriction_type = $opts{restriction_type};
    $vendor_id        = $opts{vendor_id};
  }
  else {
    ($purpose_id, $restriction_type, $vendor_id) = @_;
  }

  return $self->{publisher}->check_restriction($purpose_id, $restriction_type, $vendor_id);
}

sub has_publisher_restrictions {
  my $self = shift;
  return $self->{publisher} ? $self->{publisher}->has_restrictions : 0;
}

sub publisher_restrictions {
  my ($self, $vendor_id) = @_;

  return $self->{publisher}->restrictions($vendor_id);
}

sub publisher_tc {
  my $self = shift;

  return $self->{publisher}->publisher_tc;
}

sub is_vendor_consent_allowed {
  my ($self, $vendor_id, @args) = @_;

  my ($purpose_ids, $opts) = $self->_parse_vendor_args(@args);

  foreach my $purpose_id (@$purpose_ids) {
    return 0 unless $self->_check_purpose_id($purpose_id, %$opts);
  }

  return 0 unless $self->vendor_consent($vendor_id);

  foreach my $purpose_id (@$purpose_ids) {
    return 0 if $self->check_publisher_restriction($purpose_id, NotAllowed,                $vendor_id);
    return 0 if $self->check_publisher_restriction($purpose_id, RequireLegitimateInterest, $vendor_id);

    return 0 unless $self->_safe_is_purpose_consent_allowed($purpose_id);
  }

  return 1;
}

sub is_vendor_legitimate_interest_allowed {
  my ($self, $vendor_id, @args) = @_;

  my ($purpose_ids, $opts) = $self->_parse_vendor_args(@args);

  foreach my $purpose_id (@$purpose_ids) {
    return 0 unless $self->_check_purpose_id($purpose_id, %$opts);
  }

  return 0 unless $self->vendor_legitimate_interest($vendor_id);

  foreach my $purpose_id (@$purpose_ids) {

    # SPEC: Purpose 1 never allows Legitimate Interest
    return 0 if $purpose_id == 1;

    # SPEC: TCF v2.2+ (Policy >= 4) prohibits LI for Purposes 3, 4, 5, and 6
    if ($self->is_v22_plus) {
      return 0 if $purpose_id >= 3 && $purpose_id <= 6;
    }

    return 0 if $self->check_publisher_restriction($purpose_id, NotAllowed,     $vendor_id);
    return 0 if $self->check_publisher_restriction($purpose_id, RequireConsent, $vendor_id);

    return 0 unless $self->_safe_is_purpose_legitimate_interest_allowed($purpose_id);
  }

  return 1;
}

sub _parse_vendor_args {
  my ($self, @args) = @_;

  if (@args && ref $args[-1] eq 'HASH') {
    my $opts = pop @args;
    return (\@args, $opts);
  }

  my @purposes;
  my %opts;
  while (@args) {
    if ($args[0] =~ /^\d+$/) {
      push @purposes, shift @args;
    }
    else {
      %opts = @args;
      last;
    }
  }

  return (\@purposes, \%opts);
}

sub is_vendor_allowed_for_any_basis {
  my ($self, $vendor_id, @args) = @_;

  return 1 if $self->is_vendor_consent_allowed($vendor_id, @args);
  return 1 if $self->is_vendor_legitimate_interest_allowed($vendor_id, @args);

  return 0;
}

sub is_vendor_allowed_for_flexible_purpose {
  my ($self, $vendor_id, $purpose_id, $default_is_li, %opts) = @_;

  return 0 unless $self->_check_purpose_id($purpose_id, %opts);

  # SPEC: TCF v2.2+ (Policy >= 4) prohibits LI for Purposes 3, 4, 5, and 6
  if ($self->is_v22_plus && $purpose_id >= 3 && $purpose_id <= 6) {
    $default_is_li = 0;
  }

  # SPEC: Purpose 1 never allows Legitimate Interest
  if ($purpose_id == 1) {
    $default_is_li = 0;
  }

  if ($self->check_publisher_restriction($purpose_id, RequireConsent, $vendor_id)) {
    return $self->is_vendor_consent_allowed($vendor_id, $purpose_id, %opts);
  }

  if ($self->check_publisher_restriction($purpose_id, RequireLegitimateInterest, $vendor_id)) {
    return $self->is_vendor_legitimate_interest_allowed($vendor_id, $purpose_id, %opts);
  }

  if ($self->check_publisher_restriction($purpose_id, NotAllowed, $vendor_id)) {
    return 0;
  }

  if ($default_is_li) {
    return $self->is_vendor_legitimate_interest_allowed($vendor_id, $purpose_id, %opts);
  }

  return $self->is_vendor_consent_allowed($vendor_id, $purpose_id, %opts);
}

sub _check_purpose_id {
  my ($self, $id, %opts) = @_;

  my $strict = exists $opts{strict} ? $opts{strict} : $self->{options}->{strict};

  if ($id < 1 || $id > MAX_PURPOSE_ID) {
    if ($strict) {
      croak "invalid purpose id $id: must be between 1 and @{[ MAX_PURPOSE_ID ]}";
    }
    else {
      carp "invalid purpose id $id: must be between 1 and @{[ MAX_PURPOSE_ID ]}";
      return 0;
    }
  }

  return 1;
}

sub _format_date {
  my ($self, $epoch, $nanoseconds) = @_;

  return $epoch if !!$self->{options}->{json}->{use_epoch};

  my $format = $self->{options}->{json}->{date_format};

  return $format->($epoch, $nanoseconds) if ref($format) eq ref(sub { });

  return strftime($format, gmtime($epoch));
}

sub _json_true { 1 == 1 }

sub _json_false { 1 == 0 }

sub _format_json_subsection {
  my ($self, @data) = @_;

  if (!!$self->{options}->{json}->{compact}) {
    return [map { $_->[0] } grep { $_->[1] } @data];
  }

  my $verbose = !!$self->{options}->{json}->{verbose};

  return {map { @{$_} } grep { $verbose || $_->[1] } @data};
}

sub TO_JSON {
  my $self = shift;

  my %args      = (@_ && ref $_[-1] eq 'HASH') ? %{pop @_} : @_;
  my $filter_id = $args{vendor_id} // $self->{options}->{json}->{vendor_id};

  my ($false, $true) = @{$self->{options}->{json}->{boolean_values}};

  my $created      = $self->_format_date($self->created);
  my $last_updated = $self->_format_date($self->last_updated);

  my $purpose_consents = $self->_format_json_subsection(
    map { [
      $_ => (
          $filter_id
        ? $self->is_vendor_allowed_for_any_basis($filter_id, $_)
        : $self->_safe_is_purpose_consent_allowed($_)
      ) ? $true : $false
    ] } 1 .. MAX_PURPOSE_ID,
  );

  my $purpose_li = $self->_format_json_subsection(
    map { [
      $_ => (
          $filter_id
        ? $self->is_vendor_legitimate_interest_allowed($filter_id, $_)
        : $self->_safe_is_purpose_legitimate_interest_allowed($_)
      ) ? $true : $false
    ] } 1 .. MAX_PURPOSE_ID,
  );

  return {
    tc_string               => $self->tc_string,
    version                 => $self->version,
    created                 => $created,
    last_updated            => $last_updated,
    cmp_id                  => $self->cmp_id,
    cmp_version             => $self->cmp_version,
    consent_screen          => $self->consent_screen,
    consent_language        => $self->consent_language,
    vendor_list_version     => $self->vendor_list_version,
    policy_version          => $self->policy_version,
    is_service_specific     => $self->is_service_specific     ? $true : $false,
    use_non_standard_stacks => $self->use_non_standard_stacks ? $true : $false,
    purpose_one_treatment   => $self->purpose_one_treatment   ? $true : $false,
    publisher_country_code  => $self->publisher_country_code,
    special_features_opt_in => $self->_format_json_subsection(
      map { [$_ => $self->_safe_is_special_feature_opt_in($_) ? $true : $false] } 1 .. MAX_SPECIAL_FEATURE_ID
    ),
    purpose => {consents => $purpose_consents, legitimate_interests => $purpose_li,},
    vendor  => {
      consents             => $self->{vendor_consents}->TO_JSON($filter_id),
      legitimate_interests => $self->{vendor_legitimate_interests}->TO_JSON($filter_id),
      ($self->{disclosed_vendors} ? (disclosed => $self->{disclosed_vendors}->TO_JSON($filter_id)) : ()),
      ($self->{allowed_vendors}   ? (allowed   => $self->{allowed_vendors}->TO_JSON($filter_id))   : ()),
    },
    publisher => $self->{publisher}->TO_JSON($filter_id),
  };
}

sub _decode_tc_string_segments {
  my $tc_string = shift;

  my ($core, @parts) = split CONSENT_STRING_TCF_V2->{SEPARATOR}, $tc_string;

  my $core_data      = _validate_and_decode_base64($core);
  my $core_data_size = length($core_data);

  croak
    "vendor consent strings are at least @{[ CONSENT_STRING_TCF_V2->{MIN_BYTE_SIZE} ]} bytes long (got ${core_data_size} bytes)"
    if $core_data_size < CONSENT_STRING_TCF_V2->{MIN_BYTE_SIZE};

  my %segments;

  foreach my $part (@parts) {
    my $decoded = _validate_and_decode_base64($part);

    my $segment_type = get_uint3($decoded, OFFSETS->{SEGMENT_TYPE});

    croak "duplicate segment type $segment_type" if exists $segments{$segment_type};

    $segments{$segment_type} = $decoded;
  }

  return {
    core_data         => $core_data,
    disclosed_vendors => $segments{SEGMENT_TYPES->{DISCLOSED_VENDORS}},
    allowed_vendors   => $segments{SEGMENT_TYPES->{ALLOWED_VENDORS}},
    publisher_tc      => $segments{SEGMENT_TYPES->{PUBLISHER_TC}},
  };
}

sub _validate_and_decode_base64 {
  my $s = shift;

  # see: https://www.perlmonks.org/?node_id=775820
  croak "invalid base64 format" unless $s =~ m{
        ^
        (?:[-A-Za-z0-9_]{4})*
        (?:
            [-A-Za-z0-9_]{2}[AEIMQUYcgkosw048]
        |
            [-A-Za-z0-9_][AQgw]
        )?
        \z
    }x;

  return _decode_base64url($s);
}

sub _decode_base64url {
  my $s = shift;
  $s =~ tr/-_/+\//;
  $s .= '=' while length($s) % 4;
  return decode_base64($s);
}

sub _parse_vendor_section {
  my $self = shift;

  # parse vendor consent

  my $legitimate_interest_offset = $self->_parse_vendor_consents(OFFSETS->{VENDOR_CONSENT});

  # parse vendor legitimate interest

  my $pub_restriction_offset = $self->_parse_vendor_legitimate_interests($legitimate_interest_offset);

  return $pub_restriction_offset;
}

sub _parse_vendor_consents {
  my ($self, $vendor_consent_offset) = @_;

  my ($vendor_consents, $legitimate_interest_offset) = $self->_parse_bitfield_or_range($vendor_consent_offset,);

  $self->{vendor_consents} = $vendor_consents;

  return $legitimate_interest_offset;
}

sub _parse_vendor_legitimate_interests {
  my ($self, $legitimate_interest_offset) = @_;

  my $data_size_bits = length($self->{core_data}) << 3;

  my ($vendor_legitimate_interests, $pub_restriction_offset) = $self->_parse_bitfield_or_range(
    $legitimate_interest_offset,
    sub {
      my $legitimate_interest_start = shift;

      croak "invalid consent data: no legitimate interest start position"
        if $legitimate_interest_start >= $data_size_bits;
    }
  );

  $self->{vendor_legitimate_interests} = $vendor_legitimate_interests;

  return $pub_restriction_offset;
}

sub _parse_publisher_section {
  my ($self, $pub_restriction_offset) = @_;

  # parse public restrictions

  my $publisher = GDPR::IAB::TCFv2::Publisher->Parse(
    core_data         => $self->{core_data},
    core_data_size    => length($self->{core_data}),
    offset            => $pub_restriction_offset,
    publisher_tc_data => $self->{publisher_tc_data},
    options           => $self->{options},
  );

  $self->{publisher} = $publisher;
}

sub _parse_disclosed_vendors {
  my $self = shift;

  return unless defined $self->{disclosed_vendors_data};

  $self->{disclosed_vendors}
    = $self->_parse_vendor_bitfield_or_range($self->{disclosed_vendors_data}, SEGMENT_TYPES->{DISCLOSED_VENDORS},);
}

sub _parse_allowed_vendors {
  my $self = shift;

  return unless defined $self->{allowed_vendors_data};

  $self->{allowed_vendors}
    = $self->_parse_vendor_bitfield_or_range($self->{allowed_vendors_data}, SEGMENT_TYPES->{ALLOWED_VENDORS},);
}

# Returns only $vendors_section -- unlike _parse_bitfield_or_range, which
# yields ($section, $next_offset) so the caller can keep parsing the core
# segment.  Disclosed/Allowed Vendors live in their own base64 segment
# with nothing trailing the bitfield/range, so there is no offset to chain.
sub _parse_vendor_bitfield_or_range {
  my ($self, $data, $expected_segment_type) = @_;

  # If data looks like a string of 0/1 (from legacy tests), pack it.
  if ($data =~ /^[01]+$/) {
    $data = pack("B*", $data);
  }

  my ($segment_type, $offset) = get_uint3($data, 0);

  croak "invalid segment type $segment_type: expected $expected_segment_type"
    if defined $expected_segment_type && $segment_type != $expected_segment_type;

  my ($max_id, $next_offset) = get_uint16($data, $offset);

  # Spec: MaxVendorId == 0 means "field unused".  Skip the IsRange flag
  # and any trailing payload entirely; return an empty BitField so that
  # has_vendor_disclosure() still reports the segment as present while
  # contains() always returns false for any vendor id.
  if ($max_id == 0) {
    my ($empty_section) = GDPR::IAB::TCFv2::BitField->Parse(
      data      => $data,
      data_size => length($data),
      max_id    => 0,
      offset    => $next_offset,
      options   => $self->{options},
    );
    return $empty_section;
  }

  my ($is_range, $bf_offset) = is_set($data, $next_offset);

  my $vendors_section;
  if ($is_range) {
    ($vendors_section,) = GDPR::IAB::TCFv2::RangeSection->Parse(
      data      => $data,
      data_size => length($data),
      offset    => $bf_offset,
      max_id    => $max_id,
      options   => $self->{options},
    );
  }
  else {
    ($vendors_section,) = GDPR::IAB::TCFv2::BitField->Parse(
      data      => $data,
      data_size => length($data),
      offset    => $bf_offset,
      max_id    => $max_id,
      options   => $self->{options},
    );
  }

  return $vendors_section;
}

sub _parse_bitfield_or_range {
  my ($self, $offset, $validate_next_offset) = @_;

  my $vendors_section;

  my ($max_id, $next_offset) = get_uint16($self->{core_data}, $offset);

  $validate_next_offset->($next_offset) if defined $validate_next_offset;

  my $is_range;

  ($is_range, $next_offset) = is_set($self->{core_data}, $next_offset,);

  if ($is_range) {
    ($vendors_section, $next_offset) = $self->_parse_range_section($max_id, $next_offset,);
  }
  else {
    ($vendors_section, $next_offset) = $self->_parse_bitfield($max_id, $next_offset,);
  }

  return wantarray ? ($vendors_section, $next_offset) : $vendors_section;
}

sub _parse_range_section {
  my ($self, $max_id, $range_section_start_offset) = @_;

  my ($range_section, $next_offset) = GDPR::IAB::TCFv2::RangeSection->Parse(
    data      => $self->{core_data},
    data_size => length($self->{core_data}),
    offset    => $range_section_start_offset,
    max_id    => $max_id,
    options   => $self->{options},
  );

  return wantarray ? ($range_section, $next_offset) : $range_section;
}

sub _parse_bitfield {
  my ($self, $max_id, $bitfield_start_offset) = @_;

  my ($bitfield, $next_offset) = GDPR::IAB::TCFv2::BitField->Parse(
    data      => $self->{core_data},
    data_size => length($self->{core_data}),
    offset    => $bitfield_start_offset,
    max_id    => $max_id,
    options   => $self->{options},
  );

  return wantarray ? ($bitfield, $next_offset) : $bitfield;
}

BEGIN {
  if (my $native_decode_base64url = MIME::Base64->can("decode_base64url")) {
    no warnings q<redefine>;

    *_decode_base64url = $native_decode_base64url;
  }

  eval {
    require JSON;

    if (my $native_json_true = JSON->can("true")) {
      no warnings q<redefine>;

      *_json_true = $native_json_true;
    }

    if (my $native_json_false = JSON->can("false")) {
      no warnings q<redefine>;

      *_json_false = $native_json_false;
    }
  };
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

GDPR::IAB::TCFv2::Parser - bit-stream parser for TCF v2.3 consent strings

=head1 SYNOPSIS

The purpose of this package is to parse Transparency & Consent String (TC String) as defined by IAB version 2.

    use warnings;

    use GDPR::IAB::TCFv2::Parser;
    use GDPR::IAB::TCFv2::Constants::Purpose qw<:all>;
    use GDPR::IAB::TCFv2::Constants::SpecialFeature qw<:all>;
    use GDPR::IAB::TCFv2::Constants::RestrictionType qw<:all>;

    my $consent = GDPR::IAB::TCFv2::Parser->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA'
    );

    use feature qw<say>;

    say $consent->version;             # 2
    say $consent->created;             # epoch 1228644257 or 07/12/2008
    say $consent->last_updated;        # epoch 1326215413 or 10/01/2012
    say $consent->cmp_id;              # 21 - Traffective GmbH
    say $consent->cmp_version;         # 7
    say $consent->consent_screen;      # 2
    say $consent->consent_language;    # "EN"
    say $consent->vendor_list_version; # 23

    say "find consent for purpose ids 1, 3, 9 and 10" if 4 == grep {
        $consent->is_purpose_consent_allowed($_)
    } ( # constants exported by GDPR::IAB::TCFv2::Constants::Purpose
        InfoStorageAccess,       #  1
        PersonalizationProfile,  #  3
        MarketResearch,          #  9
        DevelopImprove,          # 10
    );

    say "find consent for vendor id 284 (Weborama)" if $consent->vendor_consent(284);

    # Geolocation exported by GDPR::IAB::TCFv2::Constants::SpecialFeature
    say "user is opt in for special feature 'Geolocation (id 1)'"
        if $consent->is_special_feature_opt_in(Geolocation);

    # NotAllowed exported by GDPR::IAB::TCFv2::Constants::RestrictionType
    say "publisher restriction for purpose Info Storage Access (1), restriction type NotAllowed (0) for weborama (284)"
        if $consent->check_publisher_restriction(InfoStorageAccess, NotAllowed, 284);

For policy-driven checks against an entire vendor profile (required purposes,
legal basis, GVL flexibility, optional Disclosed Vendors enforcement),
use the L<GDPR::IAB::TCFv2::Validator> companion class instead of stringing
the predicates above together by hand:

    use GDPR::IAB::TCFv2::Validator;

    my $validator = GDPR::IAB::TCFv2::Validator->new(
        vendor_id                       => 284,
        consent_purpose_ids             => [ 1, 3 ],
        legitimate_interest_purpose_ids => [ 7 ],
    );

    my $tc_string = '...';
    my $result = $validator->validate($tc_string);   # fail-fast
    # ...or $validator->validate_all($tc_string) to accumulate every reason

    if ($result) {
        # vendor 284 has every required permission
    }
    else {
        warn "compliance failed: $result\n";   # stringifies to the reasons
        warn $_ for $result->reasons;
    }

=head1 DESCRIPTION

C<GDPR::IAB::TCFv2::Parser> is the single-pass bit-stream decoder for
TCF v2.3 (and v2.0/v2.2) consent strings, as specified by the IAB. It
is normally constructed via the L<GDPR::IAB::TCFv2> hub
(C<< GDPR::IAB::TCFv2->Parse(...) >>) but can be called directly when
you want to bypass the hub's facade.

The returned object exposes every accessor, predicate, and JSON
serializer documented below.

=head1 CONSTRUCTOR

=head2 Parse

The Parse method will decode and validate a base64 encoded version of the tcf v2 string.

Will return a C<GDPR::IAB::TCFv2::Parser> immutable object that allow easy access to different properties.

Will die if can't decode the string.

    use GDPR::IAB::TCFv2::Parser;

    my $consent = GDPR::IAB::TCFv2::Parser->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA'
    );

or

    use GDPR::IAB::TCFv2::Parser;

    my $consent = GDPR::IAB::TCFv2::Parser->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA',
        json => {
            verbose        => 0,
            compact        => 1,
            use_epoch      => 0,
            boolean_values => [ 0, 1 ],
            date_format    => '%Y%m%d',    # yyymmdd
        },
        strict => 1,
        prefetch => 284,
    );

Parse may receive an optional hash with the following parameters:

=over

=item *

On C<strict> mode we will validate if the version of the consent string is the version 2 (or die with an exception).

Additionally, for TCF v2.3 strings (Policy Version 5+), C<strict> mode will enforce that the B<Disclosed Vendors> segment is present.

The C<strict> mode is disabled by default.

=item *

The C<prefetch> option receives one (as scalar) or more (as arrayref) vendor ids.

This is useful when parsing a range based consent string, since we need to visit all ranges to find a particular id.

=item *

C<json> is hashref with the following properties used to customize the json format:

=over

=item *

C<verbose> changes the json encoding. By default we omit some false values such as C<vendor_consents> to create
a compact json representation. With C<verbose> we will present everything. See L</TO_JSON> for more details.

=item *

C<compact> changes the json encoding. All fields that are a mapping of something to a boolean will be changed to an array
of all elements keys where the value is true. This affects the following fields:  C<special_features_opt_in>,
C<purpose/consents>, C<purpose/legitimate_interests>, C<vendor/consents> and C<vendor/legitimate_interests>. See L</TO_JSON> for more details.

=item *

C<use_epoch> changes the json encode. By default we format the C<created> and C<last_updated> are converted to string using
L<ISO_8601|https://en.wikipedia.org/wiki/ISO_8601>. With C<use_epoch> we will return the unix epoch in seconds.
See L</TO_JSON> for more details.

=item *

C<boolean_values> if present, expects an arrayref if two elements: the C<false> and the C<true> values to be used in json encoding.
If omit, we will try to use C<JSON::false> and C<JSON::true> if the package L<JSON> is available, else we will fallback to C<0> and C<1>.

=item *

C<date_format> if present accepts two kinds of value: an C<string> (to be used on C<POSIX::strftime>) or a code reference to a subroutine that
will be called with two arguments: epoch in seconds and nanoseconds. If omitted the format L<ISO_8601|https://en.wikipedia.org/wiki/ISO_8601> will be used
except if the option C<use_epoch> is true.

=item *

C<vendor_id> if present, filters the JSON output to only include data for the specific vendor ID. This affects the C<vendor> and C<publisher/restrictions> sections, drastically reducing the size of the output.

=back

=back

=head1 METHODS

=head2 tc_string

Returns the original consent string.

The consent object L<GDPR::IAB::TCFv2::Parser> will call this method on string interpolations.

=head2 version

Version number of the encoding format. The value is 2 for this format.

=head2 created

Epoch time format when TC String was created in numeric format. You can easily parse with L<DateTime> if needed.

On scalar context it returns epoch in seconds. On list context it returns epoch in seconds and nanoseconds.

    use GDPR::IAB::TCFv2::Parser;
    use Test::More tests => 3;

    my $consent = GDPR::IAB::TCFv2::Parser->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA'
    );

    is $consent->created, 1228644257,
      'should return the creation epoch 07/12/2008';

    my ( $seconds, $nanoseconds ) = $consent->created;
    is $seconds, 1228644257,
        'should return the creation epoch 07/12/2008 on list context';
    is $nanoseconds, 700000000,
        'should return the 700000000 nanoseconds of epoch on list context';

=head2 last_updated

Epoch time format when TC String was last updated in numeric format. You can easily parse with L<DateTime> if needed.

On scalar context it returns epoch in seconds. On list context it returns epoch in seconds and nanoseconds, like the C<created>

=head2 cmp_id

Consent Management Platform ID that last updated the TC String. Is a unique ID will be assigned to each Consent Management Platform.

=head2 cmp_version

Consent Management Platform version of the CMP that last updated this TC String.
Each change to a CMP should increment their internally assigned version number as a record of which version the user gave consent and transparency was established.

=head2 consent_screen

CMP Screen number at which consent was given for a user with the CMP that last updated this TC String.
The number is a CMP internal designation and is CmpVersion specific. The number is used for identifying on which screen a user gave consent as a record.

=head2 consent_language

Two-letter L<ISO 639-1|https://en.wikipedia.org/wiki/ISO_639-1> language code in which the CMP UI was presented.

=head2 vendor_list_version

Number corresponds to L<GVL|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#the-global-vendor-list> vendorListVersion.
Version of the GVL used to create this TC String.

=head2 policy_version

Version of policy used within L<GVL|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#the-global-vendor-list>.

From the corresponding field in the GVL that was used for obtaining consent.

=head2 is_v22_plus

Returns true if the TC string uses Policy Version 4 or higher (TCF v2.2+).

=head2 is_v23

Returns true if the TC string uses Policy Version 5 or higher (TCF v2.3).

=head2 is_service_specific

This field must always have the value of 1. When a Vendor encounters a TC String with C<is_service_specific=0> then it is considered invalid.

=head2 use_non_standard_stacks

If true, CMP used non-IAB standard texts during consent gathering.

Setting this to 1 signals to Vendors that a private CMP has modified standard Stack descriptions and/or their translations and/or that a CMP has modified or supplemented standard Illustrations and/or their translations as allowed by the policy..

=head2 is_special_feature_opt_in

If true means Opt in.

The TCF L<Policies|https://iabeurope.eu/iab-europe-transparency-consent-framework-policies/> designates certain Features as "special" which means a CMP must afford the user a means to opt in to their use. These "Special Features" are published and numerically identified in the L<Global Vendor List separately|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#the-global-vendor-list> from normal Features.

See also: L<GDPR::IAB::TCFv2::Constants::SpecialFeature>.

=head2 is_purpose_consent_allowed

If true means Consent.

The user's consent value for each Purpose established on the legal basis of consent.
Accepts one or more Purpose IDs. Returns true if all Purposes have consent.

    my $ok = $instance->is_purpose_consent_allowed(1);
    my $all_ok = $instance->is_purpose_consent_allowed(1, 2, 3);

Throws an exception if no arguments are provided or if an ID is invalid.

See also: L<GDPR::IAB::TCFv2::Constants::Purpose>.

=head2 is_purpose_legitimate_interest_allowed

The user's consent value for each Purpose established on the legal basis of legitimate interest.
Accepts one or more Purpose IDs. Returns true if all Purposes have legitimate interest.

    my $ok = $instance->is_purpose_legitimate_interest_allowed(1);
    my $all_ok = $instance->is_purpose_legitimate_interest_allowed(1, 2, 3);

Throws an exception if no arguments are provided or if an ID is invalid.

See also: L<GDPR::IAB::TCFv2::Constants::Purpose>.

=head2 purpose_one_treatment

CMPs can use the C<publisher_country_code> field to indicate the legal jurisdiction the publisher is under to help vendors determine whether the vendor needs consent for Purpose 1.

Returns true if Purpose 1 was NOT disclosed at all.

Returns false if Purpose 1 was disclosed commonly as consent as expected by the L<Policies|https://iabeurope.eu/iab-europe-transparency-consent-framework-policies/>.

=head2 publisher_country_code

Two-letter L<ISO 639-1|https://en.wikipedia.org/wiki/ISO_639-1> language code of the country that determines legislation of reference.
Commonly, this corresponds to the country in which the publisher's business entity is established.

=head2 max_vendor_id_consent

The maximum Vendor ID that is represented in the following bit field or range encoding.

Because this section can be a variable length, this indicates the last ID of the section so that a decoder will know when it has reached the end.

=head2 vendor_consent

If true, vendor has consent.

The consent value for each Vendor ID.

    my $ok = $instance->vendor_consent(284); # if true, consent ok for Weborama (vendor id 284).

=head2 max_vendor_id_legitimate_interest

The maximum Vendor ID that is represented in the following bit field or range encoding.

Because this section can be a variable length, this indicates the last ID of the section so that a decoder will know when it has reached the end.

=head2 vendor_legitimate_interest

If true, legitimate interest established.

The legitimate interest value for each Vendor ID

    my $ok = $instance->vendor_legitimate_interest(284); # if true, legitimate interest established for Weborama (vendor id 284).

=head2 disclosed_vendor

If true, the vendor was disclosed to the user (Segment 1 or 5).

    say "Vendor 284 was disclosed" if $consent->disclosed_vendor(284);

=head2 has_vendor_disclosure

Returns true (1) if the TC string contains a "Disclosed Vendors" segment (ID 1 or 5), and false (0) otherwise.

=head2 allowed_vendor

If true, the vendor is in the "Allowed Vendors" segment (Segment 2). This is typically used for service-specific TC strings.

    say "Vendor 284 is allowed" if $consent->allowed_vendor(284);

=head2 is_vendor_consent_allowed

Check if a vendor has consent for a list of purposes, respecting publisher restrictions.

    if ($consent->is_vendor_consent_allowed(284, 1, 2, 3)) {
        # ...
    }

=head2 is_vendor_legitimate_interest_allowed

Check if a vendor has legitimate interest for a list of purposes, respecting publisher restrictions.

    if ($consent->is_vendor_legitimate_interest_allowed(284, 2, 4)) {
        # ...
    }

=head2 is_vendor_allowed_for_any_basis

Check if a vendor has either consent or legitimate interest for a list of purposes, respecting publisher restrictions.

    if ($consent->is_vendor_allowed_for_any_basis(284, 1, 2)) {
        # ...
    }

=head2 has_publisher_restrictions

Returns true (1) if the TC string contains a "Publisher Restrictions" section, and false (0) otherwise.

=head2 check_publisher_restriction

It true, there is a publisher restriction of certain type, for a given purpose id, for a given vendor id:

    # return true if there is publisher restriction to vendor 284 regarding purpose id 1
    # with restriction type 0 'Purpose Flatly Not Allowed by Publisher'
    my $ok = $instance->check_publisher_restriction(1, 0, 284);

or

    my $ok = $instance->check_publisher_restriction(
        purpose_id       => 1,
        restriction_type => 0,
        vendor_id        => 284);

Version 2.0 of the Framework introduced the ability for publishers to signal restrictions on how vendors may process personal data. Restrictions can be of two types:

=over

=item *

Purposes. Restrict the purposes for which personal data is processed by a vendor.

=item *

Legal basis. Specify the legal basis upon which a publisher requires a vendor to operate where a vendor has signaled flexibility on legal basis in the GVL.

=back

Publisher restrictions are custom requirements specified by a publisher. In order for vendors to determine if processing is permissible at all for a specific purpose or which legal basis is applicable (in case they signaled flexibility in the GVL) restrictions must be respected.

=over

=item 1

Vendors must always respect a restriction signal that disallows them the processing for a specific purpose regardless of whether or not they have declared that purpose to be "flexible".

=item 2

Vendors that declared a purpose with a default legal basis (consent or legitimate interest respectively) but also declared this purpose as flexible must respect a legal basis restriction if present. That means for example in case they declared a purpose as legitimate interest but also declared that purpose as flexible and there is a legal basis restriction to require consent, they must then check for the consent signal and must not apply the legitimate interest signal.

=back

For the avoidance of doubt:

In case a vendor has declared flexibility for a purpose and there is no legal basis restriction signal it must always apply the default legal basis under which the purpose was registered aside from being registered as flexible. That means if a vendor declared a purpose as legitimate interest and also declared that purpose as flexible it may not apply a "consent" signal without a legal basis restriction signal to require consent.

=head2 is_vendor_allowed_for_flexible_purpose

Check if a vendor is allowed for a flexible purpose, given a default legal basis (true if Legitimate Interest, false if Consent).

    if ($consent->is_vendor_allowed_for_flexible_purpose(284, 2, 1)) {
        # vendor 284, purpose 2, default is LI
    }

=head2 publisher_restrictions

Similar to L</check_publisher_restriction> but return an hashref of purpose => { restriction type => bool } for a given vendor.

=head2 publisher_tc

If the consent string has a C<Publisher TC> section, we will decode this section as an instance of L<GDPR::IAB::TCFv2::PublisherTC>.

Will return undefined if there is no C<Publisher TC> section.

=head2 TO_JSON

Will serialize the consent object into a hash reference. The objective is to be used by L<JSON> package.

With option C<convert_blessed>, the encoder will call this method.

    use warnings;
    use feature qw<say>;

    use JSON;
    use DateTime;
    use DateTimeX::TO_JSON formatter => 'DateTime::Format::RFC3339';
    use GDPR::IAB::TCFv2::Parser;

    my $consent = GDPR::IAB::TCFv2::Parser->Parse(
        'COyiILmOyiILmADACHENAPCAAAAAAAAAAAAAE5QBgALgAqgD8AQACSwEygJyAAAAAA.argAC0gAAAAAAAAAAAA',
        json => {
            compact     => 1,
            date_format => sub { # can be omitted, with DateTimeX::TO_JSON
                my ( $epoch, $ns ) = @_;

                return DateTime->from_epoch( epoch => $epoch )
                ->set_nanosecond($ns);
            },
        },
    );

    my $json    = JSON->new->convert_blessed;
    my $encoded = $json->pretty->encode($consent);

    say $encoded;

Outputs:

    {
        "tc_string" : "COyiILmOyiILmADACHENAPCAAAAAAAAAAAAAE5QBgALgAqgD8AQACSwEygJyAAAAAA",
        "consent_language" : "EN",
        "purpose" : {
            "consents" : [],
            "legitimate_interests" : []
        },
        "cmp_id" : 3,
        "purpose_one_treatment" : false,
        "publisher" : {
            "consents" : [
                2,
                4,
                6,
                8,
                9,
                10
            ],
            "legitimate_interests" : [
                2,
                4,
                5,
                7,
                10
            ],
            "custom_purposes" : {
                "consents" : [],
                "legitimate_interests" : []
            },
            "restrictions" : {}
        },
        "special_features_opt_in" : [],
        "last_updated" : "2020-04-27T20:27:54.200000000Z",
        "use_non_standard_stacks" : false,
        "policy_version" : 2,
        "version" : 2,
        "is_service_specific" : false,
        "created" : "2020-04-27T20:27:54.200000000Z",
        "consent_screen" : 7,
        "vendor_list_version" : 15,
        "cmp_version" : 2,
        "publisher_country_code" : "AA",
        "vendor" : {
            "consents" : [
                23,
                42,
                126,
                127,
                128,
                587,
                613,
                626
            ],
            "legitimate_interests" : []
        }
    }


If L<JSON> is installed, the L</TO_JSON> method will use C<JSON::true> and C<JSON::false> as boolean value.

By default it returns a compacted format where we omit the C<false> on fields like C<vendor_consents> and we convert the dates
using L<ISO_8601|https://en.wikipedia.org/wiki/ISO_8601>. This behaviour can be changed by extra option in the L<Parse> constructor.

=head1 SEE ALSO

L<GDPR::IAB::TCFv2> for the documentation hub and project overview.

L<GDPR::IAB::TCFv2::Validator> for declarative compliance checks.

L<GDPR::IAB::TCFv2::CMPValidator> for CMP-list validation.

L<iabtcfv2> for one-liner / shell-use shortcuts.

The original IAB documentation of L<TCF v2|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md>.

=cut
