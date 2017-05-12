use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Ref::Tag;

our $VERSION = '0.004011';

# ABSTRACT: A single tag object

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moo qw( extends );
extends 'Git::Wrapper::Plus::Ref';

























## no critic(NamingConventions::ProhibitMixedCaseSubs)
sub new_from_Ref {
  my ( $class, $source_object ) = @_;
  if ( not $source_object->can('name') ) {
    require Carp;
    return Carp::croak("Object $source_object does not respond to ->name, cannot Ref -> Tag");
  }
  my $name = $source_object->name;
  ## no critic ( Compatibility::PerlMinimumVersionAndWhy )
  if ( $name =~ qr{\Arefs/tags/(.+\z)}msx ) {
    return $class->new(
      git  => $source_object->git,
      name => $1,
    );
  }
  require Carp;
  Carp::croak("Path $name is not in refs/tags/*, cannot convert to Tag object");
}











sub refname {
  my ($self) = @_;
  return 'refs/tags/' . $self->name;
}





sub verify {
  my ( $self, ) = @_;
  return $self->git->tag( '-v', $self->name );
}





## no critic (ProhibitBuiltinHomonyms)

sub delete {
  my ( $self, ) = @_;
  return $self->git->tag( '-d', $self->name );
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Ref::Tag - A single tag object

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

    use Git::Wrapper::Plus::Ref::Tag;
    my $t = Git::Wrapper::Plus::Ref::Tag->new(
        git => $git,
        name => '1.2',
    );
    $t->name # '1.2'
    $t->refname # 'refs/tags/1.2'
    $t->verify # git tag -v 1.2
    $t->delete # git tag -d 1.2

=head1 METHODS

=head2 C<new_from_Ref>

Convert a Plus::Ref to a Plus::Ref::Tag

    my $tag = $class->new_from_Ref( $ref );

=head2 C<refname>

Returns C<name>, in the form C<< refs/tags/B<< <name> >> >>

=head2 C<verify>

=head2 C<delete>

=head1 ATTRIBUTES

=head2 C<name>

=head2 C<git>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Git::Wrapper::Plus::Ref::Tag",
    "interface":"class",
    "inherits":"Git::Wrapper::Plus::Ref"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
