use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Refs::Ref;
BEGIN {
  $Dist::Zilla::Util::Git::Refs::Ref::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Util::Git::Refs::Ref::VERSION = '0.002000';
}

# ABSTRACT: An Abstract REF node

use Moose;


has name => ( isa => 'Str',    required => 1, is => ro => );
has git  => ( isa => 'Object', required => 1, is => ro => );


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

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Refs::Ref - An Abstract REF node

=head1 VERSION

version 0.002000

=head1 METHODS

=head2 C<refname>

Return the fully qualified ref name for this object.

=head2 C<sha1>

Return the C<SHA1> resolving for C<refname>

=head1 ATTRIBUTES

=head2 C<name>

=head2 C<git>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
