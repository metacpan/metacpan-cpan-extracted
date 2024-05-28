package Dist::Zilla::File::FromCode 6.032;
# ABSTRACT: a file whose content is (re-)built on demand

use Moose;

use Dist::Zilla::Pragmas;

use Moose::Util::TypeConstraints;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This represents a file whose contents will be generated on demand from a
#pod callback or method name.
#pod
#pod It has one attribute, C<code>, which may be a method name (string) or a
#pod coderef.  When the file's C<content> method is called, the code is used to
#pod generate the content.  This content is I<not> cached.  It is recomputed every
#pod time the content is requested.
#pod
#pod =cut

with 'Dist::Zilla::Role::File';

has code => (
  is  => 'rw',
  isa => 'CodeRef|Str',
  required => 1,
);

#pod =attr code_return_type
#pod
#pod 'text' or 'bytes'
#pod
#pod =cut

has code_return_type => (
  is => 'ro',
  isa => enum([ qw(text bytes) ]),
  default => 'text',
);

#pod =attr encoding
#pod
#pod =cut

sub encoding;

has encoding => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => "_build_encoding",
);

sub _build_encoding {
  my ($self) = @_;
  return $self->code_return_type eq 'text' ? 'UTF-8' : 'bytes';
}

#pod =attr content
#pod
#pod =cut

sub content {
  my ($self) = @_;

  confess("cannot set content of a FromCode file") if @_ > 1;

  my $code = $self->code;
  my $result = $self->$code;

  if ( $self->code_return_type eq 'text' ) {
    return $result;
  }
  else {
    $self->_decode($result);
  }
}

#pod =attr encoded_content
#pod
#pod =cut

sub encoded_content {
  my ($self) = @_;

  confess( "cannot set encoded_content of a FromCode file" ) if @_ > 1;

  my $code = $self->code;
  my $result = $self->$code;

  if ( $self->code_return_type eq 'bytes' ) {
    return $result;
  }
  else {
    $self->_encode($result);
  }
}

sub _set_added_by {
  my ($self, $value) = @_;
  return $self->_push_added_by(sprintf("%s from coderef added by %s", $self->code_return_type, $value));
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::File::FromCode - a file whose content is (re-)built on demand

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This represents a file whose contents will be generated on demand from a
callback or method name.

It has one attribute, C<code>, which may be a method name (string) or a
coderef.  When the file's C<content> method is called, the code is used to
generate the content.  This content is I<not> cached.  It is recomputed every
time the content is requested.

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

=head2 code_return_type

'text' or 'bytes'

=head2 encoding

=head2 content

=head2 encoded_content

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
