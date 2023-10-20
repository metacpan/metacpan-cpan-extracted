package Dist::Zilla::Plugin::Typemap;
$Dist::Zilla::Plugin::Typemap::VERSION = '0.005';
use Moose;

with 'Dist::Zilla::Role::FileMunger', 'Dist::Zilla::Role::PrereqSource';

use Dist::Zilla::File::InMemory;
use List::Util qw/first max/;
use MooseX::Types::Moose qw/ArrayRef Bool Str/;
use MooseX::Types::Perl qw/StrictVersionStr/;
use ExtUtils::Typemaps;
use Module::Runtime 'require_module';
use Carp 'croak';

sub mvp_multivalue_args {
	return qw/modules files/;
}

sub mvp_aliases {
	return {
		module => 'modules',
		file   => 'files',
	};
}

has modules => (
	isa     => ArrayRef,
	traits  => ['Array'],
	default => sub { [] },
	handles => {
		modules => 'elements',
	},
);

has files => (
	isa     => ArrayRef,
	traits  => ['Array'],
	default => sub { [] },
	handles => {
		files => 'elements',
	},
);

has minimum_pxs => (
	is      => 'ro',
	isa     => Str,
	default => 'auto',
);

has filename => (
	is      => 'ro',
	isa     => Str,
	default => 'typemap',
);

sub munge_files {
	my ($self) = @_;

	for my $file (@{$self->zilla->files}) {
		next unless $file->name eq $self->filename;
		$self->munge_file($file);
	}
}

sub munge_file {
	my ($self, $file) = @_;

	my $typemap = ExtUtils::Typemaps->new(string => $file->content);

	for my $name ($self->modules) {
		my $module = $name =~ s/^\+/ExtUtils::Typemaps::/gr;
		require_module($module);
		$typemap->merge(typemap => $module->new);
	}

	for my $filename ($self->files) {
		my $file = first { $_->name eq $filename } @{$self->zilla->files} or croak "No such typemap file $filename";
		$typemap->add_string(string => $file->content);
	}

	$file->content($typemap->as_string);

	return;
}

sub register_prereqs {
	my ($self) = @_;

	my $version = $self->minimum_pxs;
	my @modules = map { s/^\+/ExtUtils::Typemaps::/gr } $self->modules;
	if ($version eq 'auto') {
		my @versions = 0;
		for my $module (@modules) {
			require_module($module);
			push @versions, $module->minimum_pxs if $module->can('minimum_pxs');
		}
		$version = max(@versions);
	}
	elsif ($version eq 'author') {
		require Module::Metadata;
		$version = Module::Metadata->new_from_module('ExtUtils::ParseXS')->version->stringify;
	}
	$self->zilla->register_prereqs({ phase => 'build' }, 'ExtUtils::ParseXS' => $version) if $version;

	for my $module (@modules) {
		$self->zilla->register_prereqs({ phase => 'develop' }, $module => 0);
	}

	return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

# ABSTRACT: Manipulate the typemap file for XS distributions using dzil

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Typemap - Manipulate the typemap file for XS distributions using dzil

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 [Typemap]
 module = ExtUtils::Typemaps::Blabla

=head1 DESCRIPTION

This module manipulates the typemap of an XS distribution. It uses the existing typemap as a base, and adds maps from both typemap modules and from separate files to it.

=head1 ATTRIBUTES

=head2 module

This adds typemap module to the type, e.g. C<ExtUtils::Typemaps::Magic> or C<ExtUtils::Typemaps::STL>. The prefix C<+> is replaced with C<ExtUtils::Typemaps::> for convenience. This may be given multiple times.

=head2 file

This adds a file in the dist to the typemap. This may be given multiple times.

=head2 filename

This is the name of the file that the typemap is written to. It defaults to F<typemap>.

=head2 minimum_pxs

This sets a build requirement on a specific version of L<ExtUtils::ParseXS|ExtUtils::ParseXS>. The special value C<author> is replaced with the version of C<ExtUtils::ParseXS> that the author has installed. The special value C<auto> (the default) will automatically determine the minimum version using the C<minimum_pxs> method on the typemap class if present.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
