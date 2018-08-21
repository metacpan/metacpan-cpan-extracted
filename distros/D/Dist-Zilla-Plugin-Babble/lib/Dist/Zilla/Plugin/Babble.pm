package Dist::Zilla::Plugin::Babble;
$Dist::Zilla::Plugin::Babble::VERSION = '0.001';
use Moose;
use MooseX::Types::Moose qw/ArrayRef Str/;
use MooseX::Types::Perl qw/StrictVersionStr/;
use List::Util 'any';

with 'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [ ':InstallModules', ':ExecFiles' ],
	};

sub mvp_multivalue_args {
	return qw/files plugins/;
}

sub mvp_aliases {
	return {
		file   => 'files',
		plugin => 'plugins',
	};
}

has files => (
	isa     => ArrayRef[Str],
	traits  => ['Array'],
	lazy    => 1,
	default => sub { [] },
	handles => {
		files => 'elements',
	},
);

has plugins => (
	isa     => ArrayRef[Str],
	traits  => ['Array'],
	lazy    => 1,
	builder => '_build_plugins',
	handles => {
		plugins => 'elements',
	},
);

my %supported_since = (
	'::CoreSignatures' => '5.028',
	'::State'          => '5.010',
	'::DefinedOr'      => '5.010',
	'::PostfixDeref'   => '5.020',
	'::PostfixDeref'   => '5.014',
);

sub _build_plugins {
	my $self = shift;
	my @plugins = grep { $supported_since{$_} > $self->for_version } keys %supported_since;
	return \@plugins;
}

has for_version => (
	is => 'ro',
	isa => StrictVersionStr,
	default => '5.008',
);

has transformer => (
	is       => 'ro',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build_transformer',
);

sub _build_transformer {
	my $self = shift;
	require Babble::PluginChain;
	my $pc = Babble::PluginChain->new;
	$pc->add_plugin($_) for $self->plugins;
	return $pc;
}

sub munge_files {
	my $self = shift;

	if (my %filename = map { $_ => 1 } $self->files) {
		foreach my $file (@{ $self->zilla->files }) {
			$self->munge_file($file) if $filename{$file->name};
		}
	}
	else {
		$self->munge_file($_) for @{ $self->found_files };
	}

	return;
}

sub munge_file {
	my ($self, $file) = @_;
	my $content = $file->content;
	my $pc = $self->transformer;
	eval {
		$file->content($pc->transform_document($content));
		1;
	} or die "Could not munge " . $file->name . ": " . $@;
	return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

'For Science®';

# ABSTRACT: EXPERIMENTAL Automatic Babble substitution in Dist::Zilla


# vim: ts=4 sts=4 sw=4 noet :

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Babble - EXPERIMENTAL Automatic Babble substitution in Dist::Zilla

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 [Babble]
 
 #or
 
 [Babble]
 for_version = 5.010 # don't translate defined-or or state
 
 #or
 
 [Babble]
 plugin = ::CoreSignatures # only signature transformation

=head1 DESCRIPTION

Are you in need of Damian's Mad Science™? Are you lacking Matt's Voodoo? Do you want to mix all of the complexities of dzil's transformations with that stack? Then you're in the right place.

This module translates various modern Perl langauge features into their older equivalents using L<Babble|Babble>. It is highly experimental, and comes with no warranties whatsoever.

By default it transforms code to be able to compile on perl C<5.008>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
