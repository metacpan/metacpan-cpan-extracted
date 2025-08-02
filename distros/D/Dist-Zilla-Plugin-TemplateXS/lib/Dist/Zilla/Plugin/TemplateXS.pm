package Dist::Zilla::Plugin::TemplateXS;
$Dist::Zilla::Plugin::TemplateXS::VERSION = '0.005';
use Moose;
with qw(Dist::Zilla::Role::FileGatherer Dist::Zilla::Role::TextTemplate);

use experimental 'signatures';

use Path::Tiny;

use namespace::autoclean;

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 { installer => Sub::Exporter::ForMethods::method_installer }, '-setup';
use Dist::Zilla::File::InMemory;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw/Str Bool ArrayRef/;

sub mvp_multivalue_args($class) {
	return 'includes';
}

sub mvp_aliases($class) {
	return { include => 'includes' };
}

has template => (
	is	=> 'ro',
	isa => Str,
	predicate => 'has_template',
);

has style => (
	is  => 'ro',
	isa => enum(['MakeMaker', 'ModuleBuild']),
	required => 1,
);

has includes => (
	isa     => ArrayRef[Str],
	traits  => ['Array'],
	default => sub { [] },
	handles => {
		includes => 'elements',
	},
);

has prototypes_line => (
	is      => 'ro',
	isa     => Bool,
	lazy    => 1,
	builder => '_build_prototypes_line',
);

sub _build_prototypes_line($self) {
	return $self->style eq 'MakeMaker';
}

sub filename($self, $name) {
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

sub gather_files($self) {
	my $module = $self->zilla->name =~ s/-/::/gr;
	my $filename = $self->filename($module);
	my $includes = join "\n", map { qq{#include "$_"}} $self->includes;

	my $template = $self->has_template ? path($self->template)->slurp_utf8 : ${ $self->section_data('Module.xs') };
	my $content  = $self->fill_in_string($template, {
		module          => $module,
		includes        => $includes,
		prototypes_line => $self->prototypes_line,
	});

	$self->add_file(Dist::Zilla::File::InMemory->new({ name => $filename, content => $content }));
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

version 0.005

=head1 SYNOPSIS

 ; In your profile.ini
 [TemplateXS]
 style = MakeMaker
 include = ppport.h

=head1 DESCRIPTION

This is a L<FileGatherer|Dist::Zilla::Role::FileGatherer> used for creating new XS files when minting a new dist with C<dzil new>. It uses L<Text::Template> (via L<Dist::Zilla::Role::TextTemplate>) to render a template into a XS file. The template is given three variables for use in rendering: C<$name>, the module name; C<$dist>, the Dist::Zilla object, and C<$style>, the C<style> attribute that determines the location of the new file.

=head1 ATTRIBUTES

=head2 style

This B<mandatory> argument affects the location of the new XS file. Possible values are:

=over 4

=item * MakeMaker

This will cause the XS file for Foo::Bar to be written to F<Bar.xs>.

=item * ModuleBuild

This will cause the XS file for Foo::Bar to be written to F<lib/Foo/Bar.xs>.

=back

=head2 prototypes_line

If enabled, a prototypes lines will be emitted. This is necessary when using L<ExtUtils::MakeMaker>, but when using L<Module::Build> or L<Module::Build::Tiny>, so it's enabled by default only when C<style> is C<MakeMaker>.

=head2 template

This contains the B<path> to the template that is to be used. If not set, a default template will be used that looks something like this:

 #define PERL_NO_GET_CONTEXT
 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
 
 {{ $includes }}

 MODULE = {{ $module }}				PACKAGE = {{ $module }}

{{ $prototypes_line ? 'PROTOTYPES: DISABLE\n' : '' }}

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

{{ $includes }}

MODULE = {{ $module }}				PACKAGE = {{ $module }}

{{ $prototypes_line ? 'PROTOTYPES: DISABLE\n' : '' }}
