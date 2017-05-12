package Dist::Dzpl::Plugin::Hook::FilePruner;

use Moose;
with qw/ Dist::Zilla::Role::FilePruner /;

has callback => qw/ is ro required 1 isa CodeRef /;

sub prune_files {
    my $self = shift;
    return $self->callback->( $self->zilla, $self );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
