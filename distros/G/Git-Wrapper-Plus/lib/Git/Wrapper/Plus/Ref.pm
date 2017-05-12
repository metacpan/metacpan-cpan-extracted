use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Ref;

our $VERSION = '0.004011';

# ABSTRACT: An Abstract REF node

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

























use Moo qw( has );











has 'name' => ( is => ro =>, required => 1 );
has 'git'  => ( is => ro =>, required => 1 );













sub refname {
  my ($self) = @_;
  return $self->name;
}







sub sha1 {
  my ($self)    = @_;
  my ($refname) = $self->refname;
  my (@sha1s)   = $self->git->rev_parse($refname);
  if ( scalar @sha1s > 1 ) {
    require Carp;
    return Carp::confess( q[Fatal: rev-parse ] . $refname . q[ returned multiple values] );
  }
  return shift @sha1s;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Ref - An Abstract REF node

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

    use Git::Wrapper::Plus::Ref;

    my $instance = Git::Wrapper::Plus::Ref->new(
        git => $git_wrapper,
        name => "refs/heads/foo"
    );
    $instance->refname # refs/heads/foo
    $instance->name    # refs/heads/foo
    $instance->sha1    # deadbeefbadf00da55c0ffee

=head1 METHODS

=head2 C<refname>

Return the fully qualified ref name for this object.

This exists so that L<< C<name>|/name >> can be made specialized in a subclass, for instance, a C<branch>
may have C<name> as C<master>, and C<refname> will be overloaded to return C<refs/heads/master>.

This is then used by the L<< C<sha1>|/sha1 >> method to resolve the C<ref> name to a C<sha1>

=head2 C<sha1>

Return the C<SHA1> resolving for C<refname>

=head1 ATTRIBUTES

=head2 C<name>

B<REQUIRED>: The user friendly name for this C<ref>

=head2 C<git>

B<REQUIRED>: A C<Git::Wrapper> compatible object for resolving C<sha1> internals.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Git::Wrapper::Plus::Ref",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
