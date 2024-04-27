package Dist::Zilla::Plugin::BuildSelf;
$Dist::Zilla::Plugin::BuildSelf::VERSION = '0.007';
use Moose;
with qw/Dist::Zilla::Role::BuildPL Dist::Zilla::Role::TextTemplate Dist::Zilla::Role::ConfigureSelf/;

use MooseX::Types::Perl qw/StrictVersionStr/;
use MooseX::Types::Moose qw/Str Bool/;

use experimental 'signatures', 'postderef';

use Dist::Zilla::File::InMemory;

has add_buildpl => (
	is => 'ro',
	isa => Bool,
	lazy => 1,
	default => sub($self) {
		return not grep { $_->name eq 'Build.PL' } $self->zilla->files->@*;
	},
);

has template => (
	is  => 'ro',
	isa => Str,
	default => "use {{ \$minimum_perl }};\nuse lib 'lib';\nuse {{ \$module }};\nBuild_PL(\\\@ARGV, \\\%ENV);\n",
);

has module => (
	is => 'ro',
	isa => Str,
	builder => '_module_builder',
	lazy => 1,
);

has minimum_perl => (
	is      => 'ro',
	isa     => StrictVersionStr,
	lazy    => 1,
	default => sub($self) {
		return $self->zilla->prereqs->requirements_for('runtime', 'requires')->requirements_for_module('perl') || '5.006'
	},
);

sub _module_builder($self) {
	return $self->zilla->name =~ s/-/::/gr;
}

sub setup_installer($self) {
	if ($self->add_buildpl) {
		my $content = $self->fill_in_string($self->template, { module => $self->module, minimum_perl => $self->minimum_perl });
		my $file = Dist::Zilla::File::InMemory->new({ name => 'Build.PL', content => $content });
		$self->add_file($file);
	}
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Build a Build.PL that uses the current module to build itself

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::BuildSelf - Build a Build.PL that uses the current module to build itself

=head1 VERSION

version 0.007

=head1 DESCRIPTION

Unless you're writing a Build.PL compatible module builder, you should not be looking at this. The only purpose of this module is to bootstrap any such module on Dist::Zilla.

=head1 ATTRIBUTES

=head2 add_buildpl

If enabled it will generate a F<Build.PL> file for you. Defaults to true if no Build.PL file is given.

=head2 auto_configure_requires

If enabled it will automatically add the runtime requirements of the dist to the configure requirements.

=head2 sanatize_for

If non-zero it will filter modules provided by the given perl version from the configure dependencies.

=head2 module

The module used to build the current module. Defaults to the main module of the current distribution.

=head2 minimum_perl

The minimal version of perl needed to run this Build.PL. It defaults to the current runtime requirements' value for C<perl>, or C<5.006> otherwise.

=head2 template

The template to use for the Build.PL script. This is a Text::Template string with the arguments as described above: C<$module> and C<$minimum_perl>. Default is typical for the author's Build.PL ideas, YMMV.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
