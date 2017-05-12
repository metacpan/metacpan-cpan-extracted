package Git::PurePerl::DirectoryEntry;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

has 'mode'     => ( is => 'ro', isa => 'Str',           required => 1 );
has 'filename' => ( is => 'ro', isa => 'Str',           required => 1 );
has 'sha1'     => ( is => 'ro', isa => 'Str',           required => 1 );
has 'git'      => ( is => 'ro', isa => 'Git::PurePerl', required => 1, weak_ref => 1 );

sub object {
    my $self = shift;
    return $self->git->get_object( $self->sha1 );
}

__PACKAGE__->meta->make_immutable;

