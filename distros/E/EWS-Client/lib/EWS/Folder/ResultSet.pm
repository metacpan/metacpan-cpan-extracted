package EWS::Folder::ResultSet;
BEGIN {
  $EWS::Folder::ResultSet::VERSION = '1.143070';
}

use Moose;
use MooseX::Iterator;

use EWS::Folder::Item;

has items => (
    is => 'ro',
    isa => 'ArrayRef[EWS::Folder::Item]',
    required => 1,
);

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # promote hashes returned from Exchange into Item objects
    my $items = [ map { EWS::Folder::Item->new($_) }
                             @{$params->{items}} ];

    # convert $items into a deletable HASH
    my %hshItems = map { $_->{FolderId}->{Id} => $_ } @{$items};

    $items = [];
    foreach my $item (values %hshItems) {
        if ( exists( $hshItems{$item->{ParentFolderId}->{Id}} )) {
            # add item to parent's SubFolders array
            push @{$hshItems{$item->{ParentFolderId}->{Id}}->{items}}, $item;
        }
        else {
            # item without parent in the hash means it must be kept
            push @{$items}, $item;
        }
    }
    $params->{items} = $items;
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
