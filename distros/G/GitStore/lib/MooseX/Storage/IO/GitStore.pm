package MooseX::Storage::IO::GitStore;
BEGIN {
  $MooseX::Storage::IO::GitStore::AUTHORITY = 'cpan:YANICK';
}
#ABSTRACT:  Save Moose objects in your GitStore
$MooseX::Storage::IO::GitStore::VERSION = '0.17';
use Moose::Role;

requires 'thaw';
requires 'freeze';

has git_repo => (
    traits => [ 'DoNotSerialize' ],
    is => 'ro',
    isa => 'Str',
    required => 0,
);

has gitstore => (
    traits => [ 'DoNotSerialize' ],
    is => 'ro',
    isa => 'GitStore|Undef',
    lazy => 1,
    default => sub { $_[0]->git_repo && _basic_store($_[0]->git_repo); },
);

sub _basic_store {
    GitStore->new( repo => $_[0], autocommit => 1, 
        serializer => sub { $_[2] },
        deserializer => sub { $_[2] }, 
    );
}

sub load {
    my ( $class, $filename, %args ) = @_;

    if( ref $class ) {
        $args{git_repo} ||= $class->git_repo;
        $args{gitstore} ||= $class->gitstore;
    }

    $args{inject}{git_repo} ||= $args{git_repo};
    $args{gitstore} ||= _basic_store($args{git_repo});
    $class->thaw($args{gitstore}->get($filename),%args);
}

sub store {
    my ( $self, $filename, %args ) = @_;
    ($self->gitstore || _basic_store($args{git_repo}))->set( $filename => $self->freeze(%args) );
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::IO::GitStore - Save Moose objects in your GitStore

=head1 VERSION

version 0.17

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage( format => 'YAML', io => 'GitStore');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  ## methods to load/store a class
  ## on the file system

  $p->store('my_point', git_repo => './store');

  my $p2 = Point->load('my_point', git_repo => './store');

=head1 ATTRIBUTES

The role adds two attributes to the class, C<git_repo> and C<gitstore>.

=head2 git_repo

The optional path to the git repository where the object will be stored.

=head2 gitstore

The L<GitStore> object used by the storage system. If not specified, it will
be created using I<git_repo>, and will have I<autocommit> set to 1.

=head1 METHODS

=over 4

=item B<load ($filename, git_repo => $path)>

Load the object associated with I<$filename>. I<$path> can be omited if used 
from an object instead of as a class method.

=item B<store ($filename, git_repo => $path)>

Save the object as I<$filename>. I<$path> can be omited if used 
from an object instead of as a class method.

=back

=head1 SEE ALSO

L<MooseX::Storage>

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Fayland Lam <fayland@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
