package Gitalist::Git::CollectionOfRepositories::Gitolite::Impl;
{
  $Gitalist::Git::CollectionOfRepositories::Gitolite::Impl::VERSION = '0.002';
}
use MooseX::Declare;
use namespace::autoclean;
use Gitalist::Git::CollectionOfRepositories::Gitolite::Collection;

class Gitalist::Git::CollectionOfRepositories::Gitolite::Impl
{
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;    
    use MooseX::Types::Path::Class qw/Dir/;
    use Moose::Util::TypeConstraints;

    has remote_user => (
        is => 'ro',
        isa => NonEmptySimpleStr,
        required => 1,
    );

    method debug_string { 'chosen collection ' . ref($self->chosen_collection) . " " . $self->chosen_collection->debug_string }

    role_type 'Gitalist::Git::CollectionOfRepositories';
    has chosen_collection => (
        is => 'ro',
        does => 'Gitalist::Git::CollectionOfRepositories',
        handles => [qw/
            _get_repo_from_name
            _build_repositories
            /],
        default => sub {
            my $self = shift;
            Gitalist::Git::CollectionOfRepositories::Gitolite::Collection->new(%$self);
        },
        lazy => 1,
    );

}
