package Dist::Zilla::Plugin::DynamicPrereqs::ModuleBuildTiny;
$Dist::Zilla::Plugin::DynamicPrereqs::ModuleBuildTiny::VERSION = '0.006';
use 5.020;
use Moose;
use experimental qw/signatures/;
use namespace::autoclean;

with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::DynamicPrereqs::Meta';

sub register_prereqs($self) {
	$self->zilla->register_prereqs({ phase => 'configure' }, 'Module::Build::Tiny' => '0.048');
	$self->zilla->register_prereqs({ phase => 'configure' }, 'CPAN::Requirements::Dynamic' => '0.002');
	return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Add dynamic prereqs to the metadata for Module::Build::Tiny

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DynamicPrereqs::ModuleBuildTiny - Add dynamic prereqs to the metadata for Module::Build::Tiny

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 [ModuleBuildTiny]
 [DynamicPrereqs::ModuleBuildTiny]
 condition = is_os linux
 condition = not has_perl 5.036
 joiner = and
 prereq = Foo::Bar 1.2

=head1 DESCRIPTION

This module adds L<dynamic prerequisites|CPAN::Requirements::Dynamic> to the metafile of a L<Module::Build::Tiny> using dist.

=head1 ATTRIBUTES

=head2 conditions

One or more conditions, as defined by L<CPAN::Requirements::Dynamic>.

=head2 joiner

The operator that is used when more than one condition is given. This must be either C<and> or C<or>.

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
