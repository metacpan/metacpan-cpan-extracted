package Dist::Zilla::Plugin::DynamicPrereqs::ModuleBuild;
$Dist::Zilla::Plugin::DynamicPrereqs::ModuleBuild::VERSION = '0.007';
use 5.020;
use Moose;

use List::Util 'first';

use namespace::autoclean;

use experimental qw/signatures/;

with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::FileMunger', 'Dist::Zilla::Role::DynamicPrereqs::Meta';

sub register_prereqs($self) {
	$self->zilla->register_prereqs({ phase => 'configure' }, 'Module::Build' => '0.4004');
	$self->zilla->register_prereqs({ phase => 'configure' }, 'CPAN::Meta' => '2.142060');
	$self->zilla->register_prereqs({ phase => 'configure' }, 'CPAN::Requirements::Dynamic' => '0.002');

	return;
}

my $content = <<'EOF';
package
	ModuleBuildDynamicPrereqs;

use strict;
use warnings;

use base 'Module::Build';

sub create_mymeta {
	my ($self) = @_;

	my ($meta_obj, $mymeta);
	my @mymetafiles = ( $self->mymetafile2, $self->mymetafile );

	# cleanup old MYMETA
	for my $f ( @mymetafiles ) {
		if ( $self->delete_filetree($f) ) {
			$self->log_verbose("Removed previous '$f'\n");
		}
	}

	require CPAN::Meta;
	CPAN::Meta->VERSION('2.142060');
	$meta_obj = CPAN::Meta->load_file($self->metafile2, { lazy_validation => 0 });

	# if we have metadata, just update it
	my $prereqs = $self->_normalize_prereqs;
	if (my $dynamic = $meta_obj->custom('x_dynamic_prereqs')) {
		my %meta = (%{ $meta_obj->as_struct }, dynamic_config => 0);
		require CPAN::Requirements::Dynamic;
		my $dynamic_parser = CPAN::Requirements::Dynamic->new(
			config        => $self->config,
			pureperl_only => $self->pureperl_only,
		);
		my $extra = $dynamic_parser->evaluate($dynamic);

		my $old_obj = CPAN::Meta::Prereqs->new($prereqs);
		$prereqs = $old_obj->with_merged_prereqs($extra)->as_string_hash;
	}

	my %updated = (
		%{ $meta_obj->as_struct({ version => 2.0 }) },
		prereqs => $prereqs,
		dynamic_config => 0,
		generated_by => "Module::Build version $Module::Build::VERSION",
	);
	my $mymeta_obj = CPAN::Meta->new( \%updated, { lazy_validation => 0 } );

	my @created = $self->_write_meta_files( $mymeta_obj, 'MYMETA' );

	$self->log_warn("Could not create MYMETA files\n")
		unless @created;

	return 1;
}

1;
EOF

sub gather_files($self) {
	require Dist::Zilla::File::InMemory;
	my $file = Dist::Zilla::File::InMemory->new({
		name    => 'inc/ModuleBuildDynamicPrereqs.pm',
		content => $content,
	});

	$self->add_file($file);

	return;
}

sub munge_files($self) {
	my $file = first { $_->name eq 'Build.PL' } @{$self->zilla->files};
	$self->log_fatal('No Build.PL found! Is [ModuleBuild] at least version 5.022?') if not $file;

	my $content = $file->content;

	$content =~ s/use Module::Build .*?;/use lib 'inc';\nuse ModuleBuildDynamicPrereqs;/;
	$content =~ s/(my \$build =).*?->new/$1 ModuleBuildDynamicPrereqs->new/;

	$file->content($content);
	return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Add dynamic prereqs to the metadata for Dist::Build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DynamicPrereqs::ModuleBuild - Add dynamic prereqs to the metadata for Dist::Build

=head1 VERSION

version 0.007

=head1 SYNOPSIS

 [ModuleBuild]
 [DynamicPrereqs::ModuleBuild]
 condition = is_os linux
 condition = not has_perl 5.036
 joiner = and
 prereq = Foo::Bar 1.2

=head1 DESCRIPTION

This module adds L<dynamic prerequisites|CPAN::Requirements::Dynamic> to the metafile of a L<Dist::Build> using dist.

=head1 ATTRIBUTES

=head2 conditions

One or more conditions, as defined by L<CPAN::Requirements::Dynamic>.

=head2 joiner

The operator that is used when more than one condition is given. This must be either C<and> (the default) or C<or>.

=head2 prereqs

One or more prerequisites that will be added to the requirements if the condition passes.

=head2 phase

The phase of the prerequisites, this defaults to C<'runtime'>.

=head2 relation

The relationship of the prerequisites, this defaults to C<'requires'>.

=head2 error

Instead of prerequisites being added, an error will be outputted if the condition matches.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
