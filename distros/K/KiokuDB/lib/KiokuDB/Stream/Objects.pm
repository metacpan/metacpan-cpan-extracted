package KiokuDB::Stream::Objects;
BEGIN {
  $KiokuDB::Stream::Objects::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Stream::Objects::VERSION = '0.57';
use Moose;
# ABSTRACT: Data::Stream::Bulk with live object management.

use namespace::clean -except => 'meta';

has directory => (
    isa => "KiokuDB",
    is  => "ro",
    required => 1,
);

has entry_stream => (
    does => "Data::Stream::Bulk",
    is   => "ro",
    required => 1,
    handles  => [qw(is_done loaded)],
);

has linker => (
    isa => "KiokuDB::Linker",
    is  => "ro",
    lazy_build => 1,
);

sub _build_linker {
    my $self = shift;

    $self->directory->linker;
}

has live_objects => (
    isa => "KiokuDB::LiveObjects",
    is  => "ro",
    lazy_build => 1,
);

sub _build_live_objects {
    my $self = shift;

    $self->directory->live_objects;
}

has _scope => (
    isa => "KiokuDB::LiveObjects::Scope",
    writer  => "_scope",
    clearer => "_clear_scope",
);

has _no_scope => (
    isa => "Bool",
    is  => "rw",
);

with qw(Data::Stream::Bulk) => { -version => 0.08, -excludes => 'loaded' };

sub next {
    my $self = shift;

    $self->_clear_scope;

    my $entries = $self->entry_stream->next || return;;

    if ( @$entries ) {
        $self->_scope( $self->directory->new_scope )
            unless $self->_no_scope;

        for my $entry (@$entries) {
            $self->live_objects->register_entry(
                $entry->id => $entry,
                in_storage => 1
            ) unless $self->live_objects->id_to_entry($entry->id);
        }

        return [ $self->linker->expand_objects(@$entries) ];
    } else {
        return [];
    }
}

before all => sub { shift->_no_scope(1) };

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Stream::Objects - Data::Stream::Bulk with live object management.

=head1 VERSION

version 0.57

=head1 DESCRIPTION

This class is for object streams coming out of L<KiokuDB>.

C<new_scope> is called once for each block, and then cleared.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
