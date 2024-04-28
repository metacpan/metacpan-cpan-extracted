package Dist::Zilla::Plugin::DynamicPrereqs::Meta;
$Dist::Zilla::Plugin::DynamicPrereqs::Meta::VERSION = '0.002';
use 5.020;

use Moose;

with 'Dist::Zilla::Role::MetaProvider', 'Dist::Zilla::Role::PrereqSource';

use experimental 'signatures', 'postderef';

use Carp 'croak';
use Cpanel::JSON::XS;
use Dist::Zilla::File::InMemory;
use MooseX::Types::Moose qw/ArrayRef Str/;
use Text::ParseWords 'shellwords';

my $coder = Cpanel::JSON::XS->new->pretty;

sub mvp_multivalue_args {
	return qw/conditions prereqs/;
}

sub mvp_aliases {
	return {
		condition => 'conditions',
		prereq => 'input_prereq',
	};
}

has filename => (
	is      => 'ro',
	isa     => Str,
	default => 'dynamic-prereqs.json',
);

has joiner => (
	is      => 'ro',
	isa     => Str,
	default => 'and',
);

has input_conditions => (
	init_arg => 'conditions',
	required => 1,
	isa      => ArrayRef[Str],
	traits   => ['Array'],
	handles  => {
		input_conditions => 'elements',
	},
);

sub condition($self) {
	my @conditions = map { [ shellwords($_) ] } $self->input_conditions;
	return @conditions == 1 ? $conditions[0] : [ $self->joiner, @conditions ];
}

has input_prereqs => (
	init_arg => 'prereqs',
	traits   => ['Array'],
	isa      => ArrayRef,
	handles  => {
		input_prereqs => 'elements',
	},
);

sub prereqs($self) {
	my %result;
	for my $line ($self->input_prereqs) {
		my ($module, $version) = split ' ', $line, 2;
		$version //= 0;
		$result{$module} = $version;
	}
	return \%result;
}

has error => (
	is  => 'ro',
	isa => Str,
);

has phase => (
	is      => 'ro',
	isa     => Str,
	default => 'runtime',
);

has relationship => (
	is      => 'ro',
	isa     => Str,
	default => 'requires',
);

sub metadata {
	my ($self) = @_;
	my %entry = ( condition => $self->condition );
	$entry{phase} = $self->phase if $self->phase ne 'runtime';
	$entry{relationship} = $self->relationship if $self->relationship ne 'requires';
	if ($self->error) {
		$entry{error} = $self->error;
	} else {
		$entry{prereqs} = $self->prereqs;
	}

	return {
		x_dynamic_prereqs => {
			version     => 1,
			expressions => [
				\%entry
			],
		},
	};
}

sub register_prereqs($self) {
	$self->zilla->register_prereqs({ phase => 'configure' }, 'CPAN::Requirements::Dynamic' => 0);
	return;
}

1;

# ABSTRACT: Add dynamic prereqs to to the metadata in our Dist::Zilla build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DynamicPrereqs::Meta - Add dynamic prereqs to to the metadata in our Dist::Zilla build

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 [DynamicPrereqs::Meta]
 condition = is_os linux
 condition = not has_perl 5.036
 joiner = and
 prereq = Foo::Bar 1.2

=head1 DESCRIPTION

This module adds L<dynamic prerequisites|CPAN::Requires::Dynamic> to the metafile of a dist.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
