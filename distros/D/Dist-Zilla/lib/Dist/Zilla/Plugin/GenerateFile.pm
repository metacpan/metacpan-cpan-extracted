package Dist::Zilla::Plugin::GenerateFile 6.032;
# ABSTRACT: build a custom file from only the plugin configuration

use Moose;
with (
  'Dist::Zilla::Role::FileGatherer',
  'Dist::Zilla::Role::TextTemplate',
);

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use Dist::Zilla::File::InMemory;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [GenerateFile]
#pod   filename    = todo/{{ $dist->name }}-master-plan.txt
#pod   name_is_template = 1
#pod   content_is_template = 1
#pod   content = # Outlines the plan for world domination by {{$dist->name}}
#pod   content =
#pod   content = Item 1: Think of an idea!
#pod   content = Item 2: ?
#pod   content = Item 3: Profit!
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin adds a file to the distribution.
#pod
#pod You can specify the content, as a sequence of lines, in your configuration.
#pod The specified filename and content might be literals or might be L<Text::Template>
#pod templates.
#pod
#pod =head2 Templating of the content
#pod
#pod If you provide C<content_is_template> (or C<is_template>) parameter of C<"1">, the
#pod content will be run through L<Text::Template>.  The variables C<$plugin> and
#pod C<$dist> will be provided, set to the [GenerateFile] plugin and the L<Dist::Zilla>
#pod object respectively.
#pod
#pod If you provide a C<name_is_template> parameter of "1", the filename will be run
#pod through L<Text::Template>.  The variables C<$plugin> and C<$dist> will be
#pod provided, set to the [GenerateFile] plugin and the L<Dist::Zilla> object
#pod respectively.
#pod
#pod =cut

sub mvp_aliases { +{ is_template => 'content_is_template' } }

sub mvp_multivalue_args { qw(content) }

#pod =attr filename
#pod
#pod This attribute names the file you want to generate.  It is required.
#pod
#pod =cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

#pod =attr content
#pod
#pod The C<content> attribute is an arrayref of lines that will be joined together
#pod with newlines to form the file content.
#pod
#pod =cut

has content => (
  is  => 'ro',
  isa => 'ArrayRef',
);

#pod =attr content_is_template, is_template
#pod
#pod This attribute is a bool indicating whether or not the content should be
#pod treated as a Text::Template template.  By default, it is false.
#pod
#pod =cut

has content_is_template => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

#pod =cut
#pod
#pod =attr name_is_template
#pod
#pod This attribute is a bool indicating whether or not the filename should be
#pod treated as a Text::Template template.  By default, it is false.
#pod
#pod =cut

has name_is_template => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub gather_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => $self->_filename,
    content => $self->_content,
  });

  $self->add_file($file);
  return;
}

sub _content {
  my $self = shift;

  my $content = join "\n", @{ $self->content };
  $content .= qq{\n};

  if ($self->content_is_template) {
    $content = $self->fill_in_string(
      $content,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    );
  }

  return $content;
}

sub _filename {
  my $self = shift;

  my $filename = $self->filename;

  if ($self->name_is_template) {
    $filename = $self->fill_in_string(
      $filename,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    );
  }

  return $filename;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GenerateFile - build a custom file from only the plugin configuration

=head1 VERSION

version 6.032

=head1 SYNOPSIS

In your F<dist.ini>:

  [GenerateFile]
  filename    = todo/{{ $dist->name }}-master-plan.txt
  name_is_template = 1
  content_is_template = 1
  content = # Outlines the plan for world domination by {{$dist->name}}
  content =
  content = Item 1: Think of an idea!
  content = Item 2: ?
  content = Item 3: Profit!

=head1 DESCRIPTION

This plugin adds a file to the distribution.

You can specify the content, as a sequence of lines, in your configuration.
The specified filename and content might be literals or might be L<Text::Template>
templates.

=head2 Templating of the content

If you provide C<content_is_template> (or C<is_template>) parameter of C<"1">, the
content will be run through L<Text::Template>.  The variables C<$plugin> and
C<$dist> will be provided, set to the [GenerateFile] plugin and the L<Dist::Zilla>
object respectively.

If you provide a C<name_is_template> parameter of "1", the filename will be run
through L<Text::Template>.  The variables C<$plugin> and C<$dist> will be
provided, set to the [GenerateFile] plugin and the L<Dist::Zilla> object
respectively.

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

=head2 filename

This attribute names the file you want to generate.  It is required.

=head2 content

The C<content> attribute is an arrayref of lines that will be joined together
with newlines to form the file content.

=head2 content_is_template, is_template

This attribute is a bool indicating whether or not the content should be
treated as a Text::Template template.  By default, it is false.

=head2 name_is_template

This attribute is a bool indicating whether or not the filename should be
treated as a Text::Template template.  By default, it is false.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
