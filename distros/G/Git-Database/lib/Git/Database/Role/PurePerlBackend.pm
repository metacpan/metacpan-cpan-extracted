package Git::Database::Role::PurePerlBackend;
$Git::Database::Role::PurePerlBackend::VERSION = '0.011';
use Sub::Quote;
use Path::Class qw( file );    # used by Git::PurePerl/Cogit

use Git::Database::Object::Raw;
#use namespace::clean;

use Moo::Role;

requires
  '_store_packs',
  ;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  ;

sub _expand_abbrev {
    my ( $self, $abbrev ) = @_;

    # some shortcuts
    return ''         if !defined $abbrev;
    return lc $abbrev if $abbrev =~ /^[0-9a-fA-F]{40}$/;
    return ''         if length $abbrev < 4;

    # basic implementation
    my @matches = grep /^$abbrev/, $self->all_digests;
    warn "error: short SHA1 $abbrev is ambiguous.\n" if @matches > 1;
    return @matches == 1 ? shift @matches : '';
}

# Git::Database::Role::ObjectReader
sub get_object_attributes {
    my ( $self, $digest ) = @_;

    # expand abbreviated digests
    $digest = $self->_expand_abbrev($digest)
      or return undef
      if $digest !~ /^[0-9a-f]{40}$/;

    # search packs
    for my $pack ( @{ $self->_store_packs } ) {
        my ( $kind, $size, $content ) = $pack->get_object($digest);
        if ( defined($kind) && defined($size) && defined($content) ) {
            return {
                kind    => $kind,
                digest  => $digest,
                content => $content,
                size    => $size,
            };
        }
    }

    # search loose objects
    my ( $kind, $size, $content ) = $self->store->loose->get_object($digest);
    if ( defined($kind) && defined($size) && defined($content) ) {
        return {
            kind    => $kind,
            digest  => $digest,
            content => $content,
            size    => $size,
        };
    }

    return undef;
}

sub all_digests {
    my ( $self, $kind ) = @_;
    return $self->store->all_sha1s->all if !$kind;
    return map $_->sha1, grep $_->kind eq $kind, $self->store->all_objects->all;
}

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    $self->store->loose->put_object( Git::Database::Object::Raw->new($object) );
    return $object->digest;
}

# Git::Database::Role::RefReader
sub refs {
    my $store = $_[0]->store;
    my %refs = ( HEAD => $store->ref_sha1('HEAD') );
    @refs{ $store->ref_names } = $store->refs_sha1;

    # get back to packed-refs to pick the primary target of the refs,
    # since Git::PurePerl's ref_sha1 peels everything to reach the commit
    if ( -f ( my $packed_refs = file( $store->gitdir, 'packed-refs' ) ) ) {
        for my $line ( $packed_refs->slurp( chomp => 1 ) ) {
            next if $line =~ /^[#^]/;
            my ( $sha1, $name ) = split ' ', $line;
            $refs{$name} = $sha1;
        }
    }

    return \%refs;
}

1;

__END__

=pod

=for Pod::Coverage
  get_object_attributes
  all_digests
  put_object
  refs

=head1 NAME

Git::Database::Role::PurePerlBackend - Code shared by the Cogit and Git::PurePerl backends

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    package MyPurePerlBackend;

    use Moo;
    use namespace::clean;

    with 'Git::Database::Role::PurePerlBackend';

    # implement the required methods
    sub _store_packs { ... }

    1;

=head1 DESCRIPTION

This role contains the code shared by the
L<Git::PurePerl> and L<Cogit> backends.

Both backends share the same API, except for one tiny difference:
one returns its packs as a list, and the other as an array reference.

This role hides the difference behind a simple interface.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
