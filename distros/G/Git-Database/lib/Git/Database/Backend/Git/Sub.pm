package Git::Database::Backend::Git::Sub;
$Git::Database::Backend::Git::Sub::VERSION = '0.009';
use Git::Sub qw(
   cat_file
   hash_object
   rev_list
   show_ref
   update_ref
   version
);
use Git::Version::Compare qw( ge_git );
use File::pushd qw( pushd );

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::RefWriter',
  ;

# the store attribute is a directory name
# or an object representing a directory
# (e.g. Path::Class, Path::Tiny, File::Fu)

# Git::Database::Role::Backend
sub hash_object {
    my ( $self, $object ) = @_;
    my $keeper = pushd $self->store;
    my $hash = git::hash_object
      '-t'      => $object->kind,
      '--stdin' => \$object->content;
    return $hash;
}

# Git::Database::Role::ObjectReader
sub get_object_meta {
    my ( $self, $digest ) = @_;
    my $keeper = pushd $self->store;
    my $meta = git::cat_file
      '--batch-check' => \"$digest\n";

    # protect against weird cases like if $digest contains a space
    my @parts = split / /, $meta;
    return ( $digest, 'missing', undef ) if $parts[-1] eq 'missing';

    my ( $kind, $size ) = splice @parts, -2;
    return join( ' ', @parts ), $kind, $size;
}

sub get_object_attributes {
    my ( $self, $digest ) = @_;

    my $out = do {
        my $keeper = pushd $self->store;
        local $/;
        git::cat_file '--batch' => \"$digest\n";
    };

    my ( $meta, $content ) = split "\n", $out, 2;

    # protect against weird cases like if $digest contains a space
    my ( $sha1, $kind, $size ) = my @parts = split / /, $meta;

    # git versions >= 2.11.0.rc0 throw more verbose errors
    return undef if $parts[0] =~ /^(?:symlink|dangling|loop|notdir)$/;

    # object does not exist in the git object database
    return undef if $parts[-1] eq 'missing';

    return {
        kind       => $kind,
        size       => $size,
        content    => substr( $content, 0, $size ),
        digest     => $sha1
    };
}

sub all_digests {
    my ( $self, $kind ) = @_;

    my $re = $kind ? qr/ \Q$kind\E / : qr/ /;
    my @digests;

    my $keeper = pushd $self->store;

    # the --batch-all-objects option appeared in v2.6.0-rc0
    if ( ge_git git::version, '2.6.0.rc0' ) {
        @digests = map +( split / / )[0],
          grep /$re/,
          git::cat_file '--batch-check', '--batch-all-objects';
    }
    else {    # this won't return unreachable objects
        @digests =
          map +( split / / )[0], grep /$re/,
          git::cat_file '--batch-check', \join '', map +( split / / )[0] . "\n",
          sort +git::rev_list '--all', '--objects';
    }

    return @digests;
}

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    my $keeper = pushd $self->store;

    my $hash = git::hash_object
      '-w',
      '-t'      => $object->kind,
      '--stdin' => \$object->content;
    return $hash;
}

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    my $keeper = pushd $self->store;
    my %digest = reverse map +( split / / ),
      git::show_ref '--head';
    return \%digest;
}

# Git::Database::Role::RefWriter
sub put_ref {
    my ( $self, $refname, $digest ) = @_;
    my $keeper = pushd $self->store;
    git::update_ref( $refname, $digest );
    return
}

sub delete_ref {
    my ( $self, $refname ) = @_;
    my $keeper = pushd $self->store;
    git::update_ref( '-d', $refname );
    return
}

1;

__END__

=pod

=for Pod::Coverage
  has_object_checker
  has_object_factory
  DEMOLISH
  hash_object
  get_object_attributes
  get_object_meta
  all_digests
  put_object
  refs
  put_ref
  delete_ref

=head1 NAME

Git::Database::Backend::Git::Sub - A Git::Database backend based on Git::Sub

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    # Git::Sub does not offer an OO interface
    $dir = 'path/to/some/git/repository/';

    # let Git::Database figure it out by itself
    my $db = Git::Database->new( store => $dir );

=head1 DESCRIPTION

This backend reads and write data from a Git repository using the
L<Git::Sub> Git wrapper.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>,
L<Git::Database::Role::RefWriter>.

=head1 CAVEAT

This backend may have issues with Perl 5.8.9, they are fixed in L<Git::Sub> 0.163320.

There is also a minimum requirement on L<System::Sub> 0.162800.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016-2017 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
