package Dist::Zilla::File::OnDisk 6.011;
# ABSTRACT: a file that comes from your filesystem

use Moose;

use Dist::Zilla::Path;

use namespace::autoclean;

with 'Dist::Zilla::Role::MutableFile', 'Dist::Zilla::Role::StubBuild';

#pod =head1 DESCRIPTION
#pod
#pod This represents a file stored on disk.  Its C<content> attribute is read from
#pod the originally given file name when first read, but is then kept in memory and
#pod may be altered by plugins.
#pod
#pod =cut

has _original_name => (
  is  => 'ro',
  writer => '_set_original_name',
  isa => 'Str',
  init_arg => undef,
);

after 'BUILD' => sub {
  my ($self) = @_;
  $self->_set_original_name( $self->name );
};

sub _build_encoded_content {
  my ($self) = @_;
  return path($self->_original_name)->slurp_raw;
}

sub _build_content_source { return "encoded_content" }

# should never be called, as content will always be generated from
# encoded content
sub _build_content { die "shouldn't reach here" }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::File::OnDisk - a file that comes from your filesystem

=head1 VERSION

version 6.011

=head1 DESCRIPTION

This represents a file stored on disk.  Its C<content> attribute is read from
the originally given file name when first read, but is then kept in memory and
may be altered by plugins.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
