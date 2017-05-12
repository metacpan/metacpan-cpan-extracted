package Dist::Zilla::Plugin::BuildSelf;
$Dist::Zilla::Plugin::BuildSelf::VERSION = '0.004';
use Moose;
with qw/Dist::Zilla::Role::BuildPL Dist::Zilla::Role::TextTemplate Dist::Zilla::Role::PrereqSource/;

use Dist::Zilla::File::InMemory;

has add_buildpl => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

has template => (
	is  => 'ro',
	isa => 'Str',
	default => "use {{ \$minimum_perl }};\nuse lib 'lib';\nuse {{ \$module }};\nBuild_PL(\\\@ARGV, \\\%ENV);\n",
);

has module => (
	is => 'ro',
	isa => 'Str',
	builder => '_module_builder',
	lazy => 1,
);

has auto_configure_requires => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

has minimum_perl => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->zilla->prereqs->requirements_for('runtime', 'requires')->requirements_for_module('perl') || '5.006'
	},
);


sub _module_builder {
	my $self = shift;
	(my $name = $self->zilla->name) =~ s/-/::/g;
	return $name;
}

sub register_prereqs {
	my ($self) = @_;

	if ($self->auto_configure_requires) {
		my $reqs = $self->zilla->prereqs->requirements_for('runtime', 'requires');
		$self->zilla->register_prereqs({ phase => 'configure' }, %{ $reqs->as_string_hash });
	}

	return;
}

sub setup_installer {
	my ($self, $arg) = @_;

	if ($self->add_buildpl) {
		my $content = $self->fill_in_string($self->template, { module => $self->module, minimum_perl => $self->minimum_perl });
		my $file = Dist::Zilla::File::InMemory->new({ name => 'Build.PL', content => $content });
		$self->add_file($file);
	}

	return;
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

version 0.004

=head1 DESCRIPTION

Unless you're writing a Build.PL compatible module builder, you should not be looking at this. The only purpose of this module is to bootstrap any such module on Dist::Zilla.

=head1 ATTRIBUTES

=head2 module

The module used to build the current module. Defaults to the main module of the current distribution.

=head2 minimum_perl

The minimal version of perl needed to run this Build.PL. It defaults to the current runtime requirements' value for C<perl>, or C<5.006> otherwise.

=head2 template

The template to use for the Build.PL script. This is a Text::Template string with the arguments as described above: C<$module> and C<$minimum_perl>. Default is typical for the author's Build.PL ideas, YMMV.

=for Pod::Coverage register_prereqs
setup_installer
=end

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
