package Role::Identifiable::HasTags;
{
  $Role::Identifiable::HasTags::VERSION = '0.007';
}
use Moose::Role;
# ABSTRACT: a thing with a list of tags


use Moose::Util::TypeConstraints;

sub has_tag {
  my ($self, $tag) = @_;

  $_ eq $tag && return 1 for $self->tags;

  return;
}

sub tags {
  my ($self) = @_;

  # Poor man's uniq:
  my %tags = map {; $_ => 1 }
             (@{ $self->_default_tags }, @{ $self->_instance_tags });

  return wantarray ? keys %tags : (keys %tags)[0];
}

subtype 'Role::Identifiable::_Tag', as 'Str', where { length };

has instance_tags => (
  is     => 'ro',
  isa    => 'ArrayRef[Role::Identifiable::_Tag]',
  reader => '_instance_tags',
  init_arg => 'tags',
  default  => sub { [] },
);

has _default_tags => (
  is      => 'ro',
  builder => '_build_default_tags',
);

sub _build_default_tags {
  # This code stolen happily from Moose::Object::BUILDALL -- rjbs, 2010-10-18

  # NOTE: we ask Perl if we even need to do this first, to avoid extra meta
  # level calls
  return [] unless $_[0]->can('x_tags');

  my @tags;

  my ($self, $params) = @_;
  foreach my $method (
    reverse Class::MOP::class_of($self)->find_all_methods_by_name('x_tags')
  ) {
    push @tags, $method->{code}->execute($self, $params);
  }

  return \@tags;
}

no Moose::Util::TypeConstraints;
no Moose::Role;
1;

__END__

=pod

=head1 NAME

Role::Identifiable::HasTags - a thing with a list of tags

=head1 VERSION

version 0.007

=head1 OVERVIEW

This role adds the ability for your class and its composed parts (roles,
superclasses) as well as instances of it to contribute to a pool of tags
describing each instance.

The behavior of this role is not yet very stable.  Do not rely on it yet.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
