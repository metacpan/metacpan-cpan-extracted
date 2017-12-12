package Git::Database::Backend::Git::Raw::Repository;
$Git::Database::Backend::Git::Raw::Repository::VERSION = '0.010';
use Git::Raw;
use Sub::Quote;
use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::RefWriter',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Raw::Repository object'
          if !eval { $_[0]->isa('Git::Raw::Repository') }
    } ),
);

my %type = (
    blob   => Git::Raw::Object->BLOB,
    tree   => Git::Raw::Object->TREE,
    commit => Git::Raw::Object->COMMIT,
    tag    => Git::Raw::Object->TAG,
);
my @kind;
$kind[ $type{$_} ] = $_ for keys %type;

# Git::Database::Role::Backend
sub hash_object {
    my ( $self, $object ) = @_;
    return $self->store->odb->hash( $object->content, $type{ $object->kind } );
}

# Git::Database::Role::ObjectReader
sub get_object_attributes {
    my ( $self, $digest ) = @_;

    # get the Git::Raw::Odb::Object
    my $object = eval { $self->store->odb->read($digest) }
      or $@ and do { ( my $at = $@ ) =~ s/ at .* line .*$//; warn "$at\n" };
    return undef if !defined $object;

    return {
        kind    => $kind[ $object->type ],
        size    => $object->size,
        content => $object->data,
        digest  => $object->id,
    };
}

sub all_digests {
    my ( $self, $kind ) = @_;
    my $odb = $self->store->odb;
    my $type = $kind ? $type{$kind} : '';

    my @digests;
    $odb->foreach(
        $kind
        ? sub {
            my $o = $odb->read( shift );
            push @digests, $o->id if $o->type == $type;
            return 0;
          }
        : sub { push @digests, shift; return 0; }
    );
    return sort @digests;
}

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    return $self->store->odb->write( $object->content, $type{ $object->kind } );
}

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    return {
        map +( $_->name => $self->_deref($_->target)->id ),
        # we include HEAD explicitly to mimic `show-ref --head`
        Git::Raw::Reference->lookup('HEAD', $self->store), $self->store->refs
    };
}

sub _deref {
    my ($self, $maybe_ref) = @_;
    return $maybe_ref->isa('Git::Raw::Reference')
      ? $self->_deref($maybe_ref->target)
      : $maybe_ref;
}

# Git::Database::Role::RefWriter
sub put_ref {
    my ($self, $refname, $digest) = @_;
    Git::Raw::Reference->create(
      $refname, $self->store, $self->store->lookup($digest));
}

sub delete_ref {
    my ($self, $refname) = @_;
    Git::Raw::Reference->lookup($refname, $self->store)->delete;
}

1;

__END__

=pod

=for Pod::Coverage
  hash_object
  get_object_attributes
  all_digests
  put_object
  refs
  put_ref
  delete_ref
  _deref

=head1 NAME

Git::Database::Backend::Git::Raw::Repository - A Git::Database backend based on Git::Raw

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Raw::Repository->open('path/to/some/git/repository');

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads data from a Git repository using the L<Git::Raw>
bindings to the L<libgit2|http://libgit2.github.com> library.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>,
L<Git::Database::Role::RefWriter>.

=head1 CAVEAT

This backend requires L<Git::Raw> version 0.74 or greater.

=head1 AUTHORS

Sergey Romanov <sromanov@cpan.org> provided the initial version of
the module, with support for the L<Git::Database::Role::RefReader>
and L<Git::Database::Role::RefWriter> roles.

Philippe Bruhat (BooK) <book@cpan.org> implemented
the L<Git::Database::Role::ObjectReader> and
L<Git::Database::Role::ObjectWriter> roles.

Jacques Germishuys <jacquesg@cpan.org> added the features needed for
the above roles to L<Git::Raw>.

=head1 COPYRIGHT

Copyright 2017 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
