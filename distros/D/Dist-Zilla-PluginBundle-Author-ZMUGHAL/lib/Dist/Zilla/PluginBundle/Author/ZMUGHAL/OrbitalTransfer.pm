package Dist::Zilla::PluginBundle::Author::ZMUGHAL::OrbitalTransfer;
# ABSTRACT: A plugin bundle for Orbital Transfer
$Dist::Zilla::PluginBundle::Author::ZMUGHAL::OrbitalTransfer::VERSION = '0.006';
use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

use Dist::Zilla::Plugin::Babble ();
use Babble 0.090009 ();
use Dist::Zilla::Plugin::RunExtraTests ();
use Dist::Zilla::Plugin::Test::MinimumVersion ();
use Dist::Zilla::Plugin::Test::Perl::Critic ();
use Dist::Zilla::Plugin::Test::PodSpelling ();
use Dist::Zilla::Plugin::PodCoverageTests ();

sub configure {
	my $self = shift;

	$self->add_bundle('Filter', {
		'-bundle' => '@Author::ZMUGHAL::Basic',
	});

	$self->add_plugins(
		['Babble' => {
			plugin => [ qw(
				Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters
				::DefinedOr
				::SubstituteAndReturn
				::State
				::Ellipsis
			) ],
		}],
	);

	# ; run the xt/ tests
	$self->add_plugins( qw( RunExtraTests) );

	# ; code must target at least 5.8.0
	$self->add_plugins(
		['Test::MinimumVersion' => {
			max_target_perl => '5.8.0'
		}],
	);

	$self->add_plugins(qw(
		Test::Perl::Critic
		Test::PodSpelling
		PodCoverageTests
	));
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::ZMUGHAL::OrbitalTransfer - A plugin bundle for Orbital Transfer

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
