package Dist::Zilla::Plugin::TemplateXS;
{
  $Dist::Zilla::Plugin::TemplateXS::VERSION = '0.002';
}

use Moose;
with qw(Dist::Zilla::Role::FileGatherer Dist::Zilla::Role::TextTemplate);

use Path::Tiny;

use namespace::autoclean;

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 { installer => Sub::Exporter::ForMethods::method_installer }, '-setup';
use Dist::Zilla::File::InMemory;
use Moose::Util::TypeConstraints;

has template => (
	is	=> 'ro',
	isa => 'Str',
	predicate => 'has_template',
);

has style => (
	is  => 'ro',
	isa => enum(['MakeMaker', 'ModuleBuild']),
	required => 1,
);

sub filename {
	my ($self, $name) = @_;
	my @module_parts = split /::/, $name;
	if ($self->style eq 'MakeMaker') {
		return $module_parts[-1] . '.xs';
	}
	elsif ($self->style eq 'ModuleBuild') {
		return path('lib', @module_parts) . '.xs';
	}
	else {
		confess 'Invalid style for XS file generation';
	}
}

sub content {
	my ($self, $name) = @_;
	my $template = $self->has_template ? path($self->template)->slurp_utf8 : ${ $self->section_data('Module.xs') };
	return $self->fill_in_string($template, { dist => \($self->zilla), name => $name, style => $self->style });
}

sub gather_files {
	my $self = shift;
	(my $name = $self->zilla->name) =~ s/-/::/g;
	$self->add_file(Dist::Zilla::File::InMemory->new({ name => $self->filename($name), content => $self->content($name) }));
	return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A simple xs-file-from-template plugin

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TemplateXS - A simple xs-file-from-template plugin

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 ; In your profile.ini
 [TemplateXS]
 style = MakeMaker

=head1 DESCRIPTION

This is a L<ModuleMaker|Dist::Zilla::Role::ModuleMaker> used for creating new XS files when minting a new dist with C<dzil new>. It uses L<Text::Template> (via L<Dist::Zilla::Role::TextTemplate>) to render a template into a XS file. The template is given three variables for use in rendering: C<$name>, the module name; C<$dist>, the Dist::Zilla object, and C<$style>, the C<style> attribute that determines the location of the new file.

=head1 ATTRIBUTES

=head2 style

This B<mandatory> argument affects the location of the new XS file. Possible values are:

=over 4

=item * MakeMaker

This will cause the XS file for Foo::Bar to be written to F<Bar.xs>.

=item * ModuleBuild

This will cause the XS file for Foo::Bar to be written to F<lib/Foo/Bar.xs>.

=back

=head2 template

This contains the path to the template that is to be used. If not set, a default template will be used that looks something like this:

 #define PERL_NO_GET_CONTEXT
 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
 
 MODULE = {{ $name }}				PACKAGE = {{ $name }}
 
 PROTOTYPES: DISABLED

=head1 METHODS

=head2 filename($module_name)

This returns the filename for C<$module_name>, given the specified C<style>.

=head2 content($module_name)

This returns the appropriate content for C<$module_name>.

=head2 gather_files()

This adds an XS file for the main module of the distribution.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ Module.xs ]__
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = {{ $name }}				PACKAGE = {{ $name }}

PROTOTYPES: DISABLED

