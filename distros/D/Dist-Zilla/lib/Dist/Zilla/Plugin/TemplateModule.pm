package Dist::Zilla::Plugin::TemplateModule 6.032;
# ABSTRACT: a simple module-from-template plugin

use Moose;
with 'Dist::Zilla::Role::ModuleMaker',
     'Dist::Zilla::Role::TextTemplate';

use Dist::Zilla::Pragmas;

use Dist::Zilla::Path;

use namespace::autoclean;

use autodie;

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 # encoding and bytes
  { installer => Sub::Exporter::ForMethods::method_installer },
  '-setup';
use Dist::Zilla::File::InMemory;

#pod =head1 MINTING CONFIGURATION
#pod
#pod This module is part of the standard configuration of the default L<Dist::Zilla>
#pod Minting Profile, and all profiles that don't set a custom ':DefaultModuleMaker'
#pod so you don't need to normally do anything to configure it.
#pod
#pod   dzil new Some::Module
#pod   # creates ./Some-Module/*
#pod   # creates ./Some-Module/lib/Some/Module.pm
#pod
#pod However, for those who wish to configure this ( or any subclasses ) this is
#pod presently required:
#pod
#pod   [TemplateModule / :DefaultModuleMaker]
#pod   ; template  = SomeFile.pm
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a L<ModuleMaker|Dist::Zilla::Role::ModuleMaker> used for creating new
#pod Perl modules files when minting a new dist with C<dzil new>.  It uses
#pod L<Text::Template> (via L<Dist::Zilla::Role::TextTemplate>) to render a template
#pod into a Perl module.  The template is given two variables for use in rendering:
#pod C<$name>, the module name; and C<$dist>, the Dist::Zilla object.  The module is
#pod always created as a file under F<./lib>.
#pod
#pod By default, the template looks something like this:
#pod
#pod   use strict;
#pod   use warnings;
#pod   package {{ $name }};
#pod
#pod   1;
#pod
#pod =attr template
#pod
#pod The C<template> parameter may be given to the plugin to provide a different
#pod filename, absolute or relative to the build/profile directory.
#pod
#pod If this parameter is not specified, this module will use the boilerplate module
#pod template included in this module.
#pod
#pod =cut

has template => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_template',
);

sub make_module {
  my ($self, $arg) = @_;

  my $template;

  if ($self->has_template) {
    $template = path( $self->template )->slurp_utf8;
  } else {
    $template = ${ $self->section_data('Module.pm') };
  }

  my $content = $self->fill_in_string(
    $template,
    {
      dist => \($self->zilla),
      name => $arg->{name},
    },
  );

  my $filename = $arg->{name} =~ s{::}{/}gr;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => "lib/$filename.pm",
    content => $content,
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TemplateModule - a simple module-from-template plugin

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This is a L<ModuleMaker|Dist::Zilla::Role::ModuleMaker> used for creating new
Perl modules files when minting a new dist with C<dzil new>.  It uses
L<Text::Template> (via L<Dist::Zilla::Role::TextTemplate>) to render a template
into a Perl module.  The template is given two variables for use in rendering:
C<$name>, the module name; and C<$dist>, the Dist::Zilla object.  The module is
always created as a file under F<./lib>.

By default, the template looks something like this:

  use strict;
  use warnings;
  package {{ $name }};

  1;

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

=head2 template

The C<template> parameter may be given to the plugin to provide a different
filename, absolute or relative to the build/profile directory.

If this parameter is not specified, this module will use the boilerplate module
template included in this module.

=head1 MINTING CONFIGURATION

This module is part of the standard configuration of the default L<Dist::Zilla>
Minting Profile, and all profiles that don't set a custom ':DefaultModuleMaker'
so you don't need to normally do anything to configure it.

  dzil new Some::Module
  # creates ./Some-Module/*
  # creates ./Some-Module/lib/Some/Module.pm

However, for those who wish to configure this ( or any subclasses ) this is
presently required:

  [TemplateModule / :DefaultModuleMaker]
  ; template  = SomeFile.pm

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ Module.pm ]__
use strict;
use warnings;
package {{ $name }};

1;
