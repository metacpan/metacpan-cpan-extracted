package EWS::Contacts::Item;
BEGIN {
  $EWS::Contacts::Item::VERSION = '1.143070';
}
use Moose;

use Encode;

has DisplayName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has JobTitle => (
    is => 'ro',
    isa => 'Str',
);

has CompanyName => (
    is => 'ro',
    isa => 'Str',
);

has BusinessHomePage => (
    is => 'ro',
    isa => 'Str',
);

has PhoneNumbers => (
    is => 'ro',
    isa => 'HashRef[ArrayRef]',
    default => sub { {} },
);

has EmailAddresses => (
    is => 'ro',
    isa => 'HashRef[ArrayRef]',
    default => sub { {} },
);

has PhysicalAddresses => (
    is => 'ro',
    isa => 'HashRef[ArrayRef]',
    default => sub { {} },
);

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    $params->{'PhoneNumbers'} = _build_Contact_Hashes($params->{'PhoneNumbers'});
    $params->{'EmailAddresses'} = _build_Contact_Hashes($params->{'EmailAddresses'});
    $params->{'PhysicalAddresses'} = _build_Biz_Hashes($params->{'PhysicalAddresses'});

    foreach my $key (keys %$params) {
        if (not ref $params->{$key}) {
            $params->{$key} = Encode::encode('utf8', $params->{$key});
        }
    }

    return $params;
}

sub _build_Contact_Hashes {
    my $values = shift;
    my $entries = {};

    return {} if !exists $values->{'Entry'}
                 or ref $values->{'Entry'} ne 'ARRAY'
                 or scalar @{ $values->{'Entry'} } == 0;

    foreach my $entry (@{ $values->{'Entry'} }) {
        next if !defined $entry->{'Key'};
                #or $entry->{'Key'} =~ m/(?:Fax|Callback|Isdn|Pager|Telex|TtyTdd)/i;

        my $type = $entry->{'Key'};
        $type =~ s/(\w)([A-Z0-9])/$1 $2/g; # BusinessPhone -> Business Phone

        # get numbers and set mapping to this name, but skip blanks
        next unless $entry->{'_'};
        push @{ $entries->{$type} }, $entry->{'_'};
    }

    return $entries;
}

sub _build_Biz_Hashes {
    my $values = shift;
    my $entries = {};

    return {} if !exists $values->{'Entry'}
                            or ref $values->{'Entry'} ne 'ARRAY'
                            or scalar @{ $values->{'Entry'} } == 0;

    foreach my $entry (@{ $values->{'Entry'} }) {
        next if !defined $entry->{'Key'};
        my $type = $entry->{'Key'};

        while( my ($fieldname, $fieldvalue) = each %$entry ) {
            $fieldname =~ s/(\w)([A-Z0-9])/$1 $2/g;
            next unless $fieldvalue and $fieldname ne 'Key';
            push @{ $entries->{"$type $fieldname"} }, $fieldvalue;
        }
    }

    return $entries;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
