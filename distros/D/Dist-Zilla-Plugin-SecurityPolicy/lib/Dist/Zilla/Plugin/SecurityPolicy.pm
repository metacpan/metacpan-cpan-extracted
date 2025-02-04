package Dist::Zilla::Plugin::SecurityPolicy;
$Dist::Zilla::Plugin::SecurityPolicy::VERSION = '0.001';
use strict;
use warnings;

use Moose;
with qw/Dist::Zilla::Role::FileGatherer Dist::Zilla::Role::PrereqSource Dist::Zilla::Role::FilePruner/;

use MooseX::Types::Moose qw/Str HashRef/;
use MooseX::Types::Perl qw/StrictVersionStr/;

use Carp 'croak';
use Module::Runtime 'require_module';

has policy_class => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has policy_args => (
	isa      => HashRef,
	traits   => ['Hash'],
	default  => sub { {} },
	handles  => {
		policy_args => 'elements',
	}
);

has policy_version => (
	is       => 'ro',
	isa      => StrictVersionStr,
	default  => '0',
);

has filename => (
	is       => 'ro',
	isa      => Str,
	default  => 'SECURITY.md',
);

around plugin_from_config => sub {
	my ($orig, $class, $name, $args, $section) = @_;

	my (%module_args, %policy_args);
	for my $key (keys %{ $args }) {
		if ($key =~ s/^-//) {
			$module_args{$key} = $args->{"-$key"};
		} else {
			$module_args{policy_args}{$key} = $args->{$key};
		}
	}

	if (!$module_args{policy_class}) {
		my $policy_name = $module_args{policy} or croak "No security policy was given";
		$module_args{policy_class} = "Software::Security::Policy::$policy_name";
	}

	return $class->$orig($name, \%module_args, $section);
};

sub gather_files {
	my ($self) = @_;

	my $zilla = $self->zilla;
	my %policy_args = (
		maintainer => join(', ', @{ $zilla->authors }),
		program    => $zilla->name,
		$self->policy_args,
	);

	require_module($self->policy_class);
	my $policy = $self->policy_class->new(\%policy_args);

	require Dist::Zilla::File::InMemory;
	$self->add_file(Dist::Zilla::File::InMemory->new(
		name     => $self->filename,
		content  => $policy->fulltext,
	));

	return;
}

sub register_prereqs {
	my $self = shift;
	$self->zilla->register_prereqs({ phase => 'develop' }, $self->policy_class => $self->policy_version);
	return;
}

sub prune_files {
	my $self = shift;

	my @files = @{ $self->zilla->files };
	my $filename = $self->filename;
	for my $file (@files) {
		$self->zilla->prune_file($file) if $file->name eq $filename and $file->added_by !~ __PACKAGE__;
	}
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

# ABSTRACT: Add a SECURITY.md to your dzil distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::SecurityPolicy - Add a SECURITY.md to your dzil distribution

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 [SecurityPolicy]
 -policy = Individual
 timeframe = 2 weeks

=head1 DESCRIPTION

This plugin adds a SECURITY.md file as generated using L<Software::Security::Policy|Software::Security::Policy>. Any options to this plugin that are prefixed by C<-> are kept for this module, any others will be passed to the constructor of the security policy.

=head1 ATTRIBUTES

=head2 policy_class

E.g. C<policy_class = Software::Security::Policy::Individual>

This sets the used policy class.

=head2 policy

E.g. C<policy = Individual>

This is a short hand for setting the policy, allowing you to skip prepending C<Software::Security::Policy::>

=head2 policy_version

The minimum version of the policy class, defaults to C<0>.

=head2 filename

This allows you to override the name of the security file. It default to C<SECURITY.md> and you should probably not change it.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
