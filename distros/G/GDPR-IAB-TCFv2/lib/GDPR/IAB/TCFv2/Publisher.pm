package GDPR::IAB::TCFv2::Publisher;
use strict;
use warnings;

use Carp qw<croak>;

use GDPR::IAB::TCFv2::PublisherRestrictions;
use GDPR::IAB::TCFv2::PublisherTC;


sub Parse {
    my ( $klass, %args ) = @_;

    croak "missing 'core_data'"      unless defined $args{core_data};
    croak "missing 'core_data_size'" unless defined $args{core_data_size};

    croak "missing 'options'"      unless defined $args{options};
    croak "missing 'options.json'" unless defined $args{options}->{json};

    my $core_data      = $args{core_data};
    my $core_data_size = $args{core_data_size};

    my $restrictions = GDPR::IAB::TCFv2::PublisherRestrictions->Parse(
        data      => $core_data,
        data_size => $core_data_size,
        options   => $args{options},
    );

    my $self = {
        restrictions => $restrictions,
        publisher_tc => undef,
    };

    if ( defined $args{publisher_tc_data} ) {
        my $publisher_tc_data = $args{publisher_tc_data};
        my $publisher_tc_data_size =
          $args{publisher_tc_data_size} || length($publisher_tc_data);

        my $publisher_tc = GDPR::IAB::TCFv2::PublisherTC->Parse(
            data      => $publisher_tc_data,
            data_size => $publisher_tc_data_size,
            options   => $args{options},
        );

        $self->{publisher_tc} = $publisher_tc;
    }

    bless $self, $klass;

    return $self;
}

sub check_restriction {
    my ( $self, $purpose_id, $restriction_type, $vendor_id ) = @_;

    return $self->{restrictions}
      ->check_restriction( $purpose_id, $restriction_type, $vendor_id );
}

sub restrictions {
    my ( $self, $vendor_id ) = @_;

    return $self->{restrictions}->restrictions($vendor_id);
}

sub publisher_tc {
    my ( $self, $callback ) = @_;

    return $self->{publisher_tc};
}

sub TO_JSON {
    my $self = shift;

    my %tags = (
        restrictions => $self->{restrictions}->TO_JSON,
    );

    if ( defined $self->{publisher_tc} ) {
        %tags = ( %tags, %{ $self->{publisher_tc}->TO_JSON } );
    }

    return \%tags;
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::Publisher - Transparency & Consent String version 2 publisher

Combines the creation of L<GDPR::IAB::TCFv2::PublisherRestrictions> and L<GDPR::IAB::TCFv2::PublisherTC> based on the data available.

=head1 SYNOPSIS

    my $publisher = GDPR::IAB::TCFv2::Publisher->Parse(
        core_data         => $core_data,
        core_data_size    => $core_data_size,
        publisher_tc_data => $publisher_tc_data, # optional
        options           => { json => ... },
    );

    say "there is publisher restriction on purpose id 1, type 0 on vendor_id 284"
        if $publisher->check_restriction(1, 0, 284);

=head1 CONSTRUCTOR

Constructor C<Parse> receives an hash of 4 parameters: 

=over

=item *

Key C<core_data> is the binary core data

=item *

Key C<core_data_size> is the original binary core data size

=item *

Key C<publisher_tc_data> is the binary publisher data. Optional.

=item *

Key C<options> is the L<GDPR::IAB::TCFv2> options (includes the C<json> field to modify the L</TO_JSON> method output.

=back

=head1 METHODS

=head2 check_restriction

Return true for a given combination of purpose id, restriction type and vendor_id 

    my $purpose_id = 1;
    my $restriction_type = 0;
    my $vendor_id = 284;
    $ok = $publisher->check_restriction($purpose_id, $restriction_type, $vendor_id);

=head2 restrictions

Return a hashref of purpose => { restriction type => bool } for a given vendor id.

Example, by parsing the consent C<COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA> we can generate this.

    my $restrictions = $publisher->restrictions(32);
    # returns { 7 => { 1 => 1 } }

=head2 publisher_tc

If the consent string has a C<Publisher TC> section, we will decode this section as an instance of L<GDPR::IAB::TCFv2::PublisherTC>.

Will return undefined if there is no C<Publisher TC> section.

=head2 TO_JSON

Returns a hashref with the following format:

    {
        consents => ...,
        legitimate_interests => ...,
        custom_purposes => {
            consents => ...,
            legitimate_interests => ...,
        },
        restrictions => {
            '[purpose id]' => {
                # 0 - Not Allowed
                # 1 - Require Consent
                # 2 - Require Legitimate Interest
                '[vendor_id id]' => 1,
            },
        }
    }

Example, by parsing the consent C<COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA.argAC0gAAAAAAAAAAAA> we can generate this compact hashref.

    {
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
      "custom_purpose" : {
         "consents" : [],
         "legitimate_interests" : []
      },
      "restrictions" : {
         "7" : {
            "32" : 1
         }
      }
    }

However by parsing the consent C<COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA> without the C<Publisher TC> 
section will omit all fields except C<restrictions>:

    {
      "restrictions" : {
         "7" : {
            "32" : 1
         }
      }
    }
