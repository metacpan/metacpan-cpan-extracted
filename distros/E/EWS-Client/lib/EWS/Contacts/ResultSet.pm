package EWS::Contacts::ResultSet;
BEGIN {
  $EWS::Contacts::ResultSet::VERSION = '1.143070';
}
use Moose;
use MooseX::Iterator;

use EWS::Contacts::Item;

has items => (
    is => 'ro',
    isa => 'ArrayRef[EWS::Contacts::Item]',
    required => 1,
);

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # promote hashes returned from Exchange into Item objects
    $params->{items} = [ map { EWS::Contacts::Item->new($_) }
                             @{$params->{items}} ];
    return $params;
}

sub count {
    my $self = shift;
    return scalar @{$self->items};
}

has iterator => (
    is => 'ro',
    isa => 'MooseX::Iterator::Array',
    handles => [qw/
        next
        has_next
        peek
        reset
    /],
    lazy_build => 1,
);

sub _build_iterator {
    my $self = shift;
    return MooseX::Iterator::Array->new( collection => $self->items );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
