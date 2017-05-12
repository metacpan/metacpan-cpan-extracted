package EWS::DistributionList::ResultSet;
BEGIN {
  $EWS::DistributionList::ResultSet::VERSION = '1.143070';
}
use Moose;
use MooseX::Iterator;

use EWS::DistributionList::Mailbox;

has mailboxes => (
    is       => 'ro',
    isa      => 'ArrayRef[EWS::DistributionList::Mailbox]',
    required => 1,
);

sub BUILDARGS {
    my ( $class, @rest ) = @_;
    my $params = ( scalar @rest == 1 ? $rest[0] : {@rest} );

    # promote hashes returned from Exchange into Item objects
    $params->{mailboxes} = [ map { EWS::DistributionList::Mailbox->new($_) } @{ $params->{mailboxes} } ];
    return $params;
}

sub count {
    my $self = shift;
    return scalar @{ $self->mailboxes };
}

has iterator => (
    is      => 'ro',
    isa     => 'MooseX::Iterator::Array',
    handles => [
        qw/
            next
            has_next
            peek
            reset
            /
    ],
    lazy_build => 1,
);

sub _build_iterator {
    my $self = shift;
    return MooseX::Iterator::Array->new( collection => $self->mailboxes );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
