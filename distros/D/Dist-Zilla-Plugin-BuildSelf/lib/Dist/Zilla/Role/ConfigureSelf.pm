package Dist::Zilla::Role::ConfigureSelf;
$Dist::Zilla::Role::ConfigureSelf::VERSION = '0.007';
use Moose::Role;

with qw/Dist::Zilla::Role::PrereqSource/;

use experimental 'signatures', 'postderef';

use MooseX::Types::Perl qw/StrictVersionStr/;
use MooseX::Types::Moose qw/Bool/;

has auto_configure_requires => (
	is => 'ro',
	isa => Bool,
	default => 1,
);

has sanatize_for => (
	is => 'ro',
	isa => StrictVersionStr,
);

sub register_prereqs($self) {
	if ($self->auto_configure_requires) {
		my $prereqs = $self->zilla->prereqs->cpan_meta_prereqs;
		if (my $for = $self->sanatize_for) {
			require CPAN::Meta::Prereqs::Filter;
			$prereqs = CPAN::Meta::Prereqs::Filter::filter_prereqs($prereqs, omit_core => $for);
		}
		my $reqs = $prereqs->requirements_for('runtime', 'requires');
		$self->zilla->register_prereqs({ phase => 'configure' }, $reqs->as_string_hash->%*);
	}
}

1;

# ABSTRACT: A helper role ConfigureSelf plugins

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ConfigureSelf - A helper role ConfigureSelf plugins

=head1 VERSION

version 0.007

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
