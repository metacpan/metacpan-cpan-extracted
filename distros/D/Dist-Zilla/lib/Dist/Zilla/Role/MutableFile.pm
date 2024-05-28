package Dist::Zilla::Role::MutableFile 6.032;
# ABSTRACT: something that can act like a file with changeable contents

use Moose::Role;

use Dist::Zilla::Pragmas;

use Moose::Util::TypeConstraints;
use MooseX::SetOnce;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This role describes a file whose contents may be modified
#pod
#pod =attr encoding
#pod
#pod Default is 'UTF-8'. Can only be set once.
#pod
#pod =cut

with 'Dist::Zilla::Role::File';

sub encoding;

has encoding => (
  is          => 'rw',
  isa         => 'Str',
  lazy        => 1,
  default     => 'UTF-8',
  traits      => [ qw(SetOnce) ],
);

#pod =attr content
#pod
#pod =cut

has _content => (
  is          => 'rw',
  isa         => 'Str',
  lazy        => 1,
  builder     => '_build_content',
  clearer     => 'clear_content',
  predicate   => 'has_content',
);

sub content {
  my $self = shift;
  if ( ! @_ ) {
    # if we have it or we're tasked to provide it, return it (possibly lazily
    # generated from a builder); otherwise, get it from the encoded_content
    if ( $self->has_content || $self->_content_source eq 'content' ) {
      return $self->_content;
    }
    else {
      return $self->_content($self->_decode($self->encoded_content));
    }
  }
  else {
    my ($pkg, $line) = $self->_caller_of('content');
    $self->_content_source('content');
    $self->_push_added_by(sprintf("content set by %s (%s line %s)", $self->_caller_plugin_name, $pkg, $line));
    $self->clear_encoded_content;
    return $self->_content(@_);
  }
}

#pod =attr encoded_content
#pod
#pod =cut

has _encoded_content => (
  is          => 'rw',
  isa         => 'Str',
  lazy        => 1,
  builder     => '_build_encoded_content',
  clearer     => 'clear_encoded_content',
  predicate   => 'has_encoded_content',
);

sub encoded_content {
  my $self = shift;
  if ( ! @_ ) {
    # if we have it or we're tasked to provide it, return it (possibly lazily
    # generated from a builder); otherwise, get it from the content
    if ($self->has_encoded_content || $self->_content_source eq 'encoded_content') {
      return $self->_encoded_content;
    }
    else {
      return $self->_encoded_content($self->_encode($self->content));
    }
  }
  my ($pkg, $line) = $self->_caller_of('encoded_content');
  $self->_content_source('encoded_content');
  $self->_push_added_by(sprintf("encoded_content set by %s (%s line %s)", $self->_caller_plugin_name, $pkg, $line));
  $self->clear_content;
  $self->_encoded_content(@_);
}

has _content_source => (
    is => 'rw',
    isa => enum([qw/content encoded_content/]),
    lazy => 1,
    builder => '_build_content_source',
);

sub _set_added_by {
  my ($self, $value) = @_;
  return $self->_push_added_by(sprintf("%s added by %s", $self->_content_source, $value));
};

# we really only need one of these and only if _content or _encoded_content
# isn't provided, but roles can't do that, so we'll insist on both just in case
# and let classes provide stubs if they provide _content or _encoded_content
# another way

requires '_build_content';
requires '_build_encoded_content';

# we need to know the content source so we know where we might need to rely on
# lazy loading to give us content. It should be set by the class if there is a
# class-wide default or just stubbed if a BUILD modifier sets it per-object.

requires '_build_content_source';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::MutableFile - something that can act like a file with changeable contents

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This role describes a file whose contents may be modified

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 encoding

Default is 'UTF-8'. Can only be set once.

=head2 content

=head2 encoded_content

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
