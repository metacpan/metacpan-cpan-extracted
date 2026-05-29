package GDPR::IAB::TCFv2::PublisherRestrictions 0.530;
use v5.12;
use warnings;

use Carp qw<croak>;

use GDPR::IAB::TCFv2::BitUtils qw<
  get_uint2
  get_uint6
  get_uint12
>;

use constant ASSUMED_MAX_VENDOR_ID => 0x7FFF;    # 32767 or (1 << 15) -1


sub Parse {
  my ($klass, %args) = @_;

  croak "missing 'data'"      unless defined $args{data};
  croak "missing 'data_size'" unless defined $args{data_size};
  croak "missing 'offset'"    unless defined $args{offset};

  croak "missing 'options'"      unless defined $args{options};
  croak "missing 'options.json'" unless defined $args{options}->{json};

  my $data      = $args{data};
  my $data_size = $args{data_size};
  my $offset    = $args{offset};
  my $max_id    = ASSUMED_MAX_VENDOR_ID;
  my $options   = $args{options};

  return if $offset + 12 > $data_size;

  my ($num_restrictions, $next_offset) = get_uint12($data, $offset);

  my %restrictions;

  for (1 .. $num_restrictions) {
    my ($purpose_id, $restriction_type, $vendor_restrictions);

    ($purpose_id, $next_offset) = get_uint6($data, $next_offset);

    ($restriction_type, $next_offset) = get_uint2($data, $next_offset);

    ($vendor_restrictions, $next_offset) = GDPR::IAB::TCFv2::RangeSection->Parse(
      data      => $data,
      data_size => $data_size,
      offset    => $next_offset,
      max_id    => ASSUMED_MAX_VENDOR_ID,
      options   => $options,
    );

    $restrictions{$purpose_id} ||= {};

    $restrictions{$purpose_id}->{$restriction_type} = $vendor_restrictions;
  }

  my $self = {restrictions => \%restrictions,};

  bless $self, $klass;

  return $self;
}

sub has_restrictions {
  my $self = shift;
  return scalar keys %{$self->{restrictions}} ? 1 : 0;
}

sub restrictions {
  my ($self, $vendor_id) = @_;

  my %restrictions;

  foreach my $purpose_id (keys %{$self->{restrictions}}) {
    foreach my $restriction_type (keys %{$self->{restrictions}->{$purpose_id}}) {
      if ($self->{restrictions}->{$purpose_id}->{$restriction_type}->contains($vendor_id)) {
        $restrictions{$purpose_id} ||= {};
        $restrictions{$purpose_id}->{$restriction_type} = 1;
      }
    }
  }

  return \%restrictions;
}

sub check_restriction {
  my $self = shift;

  my $nargs = scalar(@_);

  croak "missing arguments: purpose id, restriction type and vendor id" if $nargs == 0;
  croak "missing arguments: restriction type and vendor id"             if $nargs == 1;
  croak "missing argument: vendor id"                                   if $nargs == 2;

  my ($purpose_id, $restriction_type, $vendor_id) = @_;

  return 0 unless exists $self->{restrictions}->{$purpose_id}->{$restriction_type};

  return $self->{restrictions}->{$purpose_id}->{$restriction_type}->contains($vendor_id);
}

sub TO_JSON {
  my ($self, $filter_id) = @_;

  my %publisher_restrictions;

  foreach my $purpose_id (sort { $a <=> $b } keys %{$self->{restrictions}}) {
    my $restriction_map = $self->{restrictions}->{$purpose_id};

    my %purpose_restrictions;

    foreach my $restriction_type (keys %{$restriction_map}) {
      if (defined $filter_id) {
        if ($restriction_map->{$restriction_type}->contains($filter_id)) {
          $purpose_restrictions{$filter_id} = int($restriction_type);
        }
      }
      else {
        my $vendors = $restriction_map->{$restriction_type}->all;

        foreach my $vendor (@{$vendors}) {
          $purpose_restrictions{$vendor} = int($restriction_type);
        }
      }
    }

    # If not filtering, or if we found the filtered vendor, add the purpose
    if (!defined $filter_id || scalar keys %purpose_restrictions) {
      $publisher_restrictions{$purpose_id} = \%purpose_restrictions;
    }
  }

  return \%publisher_restrictions;
}


1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::PublisherRestrictions - TCF v2.3 publisher restrictions parser

=head1 SYNOPSIS

    use GDPR::IAB::TCFv2::PublisherRestrictions;
    my $data = '...'; # raw binary data

    my $publisher_restrictions = GDPR::IAB::TCFv2::PublisherRestrictions->Parse(
        data      => $data,
        data_size => length($data),
        offset    => 213,
        options   => { json => {} },
    );

    if ($publisher_restrictions->check_restriction(1, 0, 284)) {
        # ...
    }

=head1 CONSTRUCTOR

Constructor C<Parse> receives a hash of 4 parameters: 

=over

=item *

Key C<data> is the binary core data

=item *

Key C<data_size> is the core data size in bits

=item *

Key C<offset> is the bit offset

=item *

Key C<options> is the L<GDPR::IAB::TCFv2> options (includes the C<json> field to modify the L</TO_JSON> method output.

=back


=head1 METHODS

=head2 check_restriction

Return true for a given combination of purpose id, restriction type and vendor 

    my $purpose_id = 1;
    my $restriction_type = 0;
    my $vendor_id = 284;
    my $ok = $object->check_restriction($purpose_id, $restriction_type, $vendor_id);

=head2 restrictions

Return a hashref of purpose => { restriction type => bool } for a given vendor id.

Example, by parsing the consent C<COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA> we can generate this.

    my $restrictions = $object->restrictions(32);
    # returns { 7 => { 1 => 1 } }

=head2 TO_JSON

Returns a hashref keyed by purpose id; each inner hashref maps vendor id
to the integer C<restriction_type> that vendor was given for that purpose:

    {
        '[purpose id]' => {
            # value is the restriction type:
            #   0 - Not Allowed
            #   1 - Require Consent
            #   2 - Require Legitimate Interest
            '[vendor id]' => '[restriction type]',
        },
    }

Example, by parsing the consent C<COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA> we can generate this hashref (vendor 32 has restriction type 1 -- Require Consent -- for purpose 7):

    {
        "7" => {
            "32" => 1
        }
    }
