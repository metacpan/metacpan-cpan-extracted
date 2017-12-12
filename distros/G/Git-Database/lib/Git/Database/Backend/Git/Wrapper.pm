package Git::Database::Backend::Git::Wrapper;
$Git::Database::Backend::Git::Wrapper::VERSION = '0.010';
use Cwd qw( cwd );
use Git::Wrapper;
use Git::Version::Compare qw( ge_git );
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
        die 'store is not a Git::Wrapper object'
          if !eval { $_[0]->isa('Git::Wrapper') }
    } ),
    default => sub { Git::Wrapper->new( cwd() ) },
);

# Git::Database::Role::Backend
sub hash_object {
    my ( $self, $object ) = @_;
    my @out = $self->store->hash_object( { -STDIN => $object->content },
        '--stdin', '-t', $object->kind );
    return shift @out;
}

# Git::Database::Role::ObjectReader
sub get_object_meta {
    my ( $self, $digest ) = @_;
    my ($meta) =
      $self->store->cat_file( { -STDIN => "$digest\n" }, '--batch-check' );
    warn join $/, @{ $self->store->ERR }, '' if @{ $self->store->ERR };

    # protect against weird cases like if $digest contains a space
    my @parts = split / /, $meta;
    return ( $digest, 'missing', undef ) if $parts[-1] eq 'missing';

    my ( $kind, $size ) = splice @parts, -2;
    return join( ' ', @parts ), $kind, $size;
}

sub get_object_attributes {
    my ( $self, $digest ) = @_;

    my @out = $self->store->cat_file( { -STDIN => "$digest\n" }, '--batch' );
    my $meta = shift @out;
    warn join $/, @{ $self->store->ERR }, '' if @{ $self->store->ERR };

    # protect against weird cases like if $digest contains a space
    my ( $sha1, $kind, $size ) = my @parts = split / /, $meta;

    # git versions >= 2.11.0.rc0 throw more verbose errors
    return undef if $parts[0] =~ /^(?:symlink|dangling|loop|notdir)$/;

    # object does not exist in the git object database
    return undef if $parts[-1] eq 'missing';

    return {
        kind    => $kind,
        size    => $size,
        content => join( $/, @out ),    # I expect this to break on binary data
        digest  => $sha1
    };
}

sub all_digests {
    my ( $self, $kind ) = @_;
    my $store = $self->store;
    my $re = $kind ? qr/ \Q$kind\E / : qr/ /;

    # the --batch-all-objects option appeared in v2.6.0-rc0
    if ( ge_git( $store->version, '2.6.0.rc0' ) ) {
        return map +( split / / )[0],
          grep /$re/,
          $store->cat_file(qw( --batch-check --batch-all-objects ));
    }
    else {    # this won't return unreachable objects
        my $revs = join "\n", map +( split / / )[0],
          sort $store->rev_list(qw( --all --objects ));
        return if !length $revs;
        return map +( split / / )[0], grep /$re/,
          $store->cat_file( qw( --batch-check ), { -STDIN => "$revs\n" } );
    }
}

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    my ($hash) = $self->store->hash_object( '-t', $object->kind, '-w',
        { stdin => 1, -STDIN => $object->content } );
    return $hash;
}

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    return {
        reverse map +( split / / ),
        $self->store->show_ref( { head => 1 } )
    };
}

# Git::Database::Role::RefWriter
sub put_ref {
    my ($self, $refname, $digest ) = @_;
    $self->store->update_ref( $refname, $digest );
}

sub delete_ref {
    my ($self, $refname ) = @_;
    $self->store->update_ref( '-d', $refname );
}

1;

__END__

=pod

=for Pod::Coverage
  hash_object
  get_object_attributes
  get_object_meta
  all_digests
  put_object
  refs
  put_ref
  delete_ref

=head1 NAME

Git::Database::Backend::Git::Wrapper - A Git::Database backend based on Git::Wrapper

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Wrapper->new('/var/foo');

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads and writes data from a Git repository using the
L<Git::Wrapper> module.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>,
L<Git::Database::Role::RefWriter>.

=head1 AUTHORS

Philippe Bruhat (BooK) <book@cpan.org>

Sergey Romanov provided the code to support the
L<Git::Database::Role::ObjectWriter>, L<Git::Database::Role::RefReader>,
and L<Git::Database::Role::RefWriter> roles.

=head1 COPYRIGHT

Copyright 2016-2017 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
