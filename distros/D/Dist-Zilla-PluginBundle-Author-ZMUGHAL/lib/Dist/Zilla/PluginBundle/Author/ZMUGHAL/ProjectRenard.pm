package Dist::Zilla::PluginBundle::Author::ZMUGHAL::ProjectRenard;
# ABSTRACT: A plugin bundle for Project Renard
$Dist::Zilla::PluginBundle::Author::ZMUGHAL::ProjectRenard::VERSION = '0.004';
use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

# Dependencies
use Test::Perl::Critic ();
use Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign ();
use App::scan_prereqs_cpanfile ();
use Test::Pod::Coverage ();
use Pod::Coverage ();
use Pod::Coverage::TrustPod ();
use Pod::Weaver::Section::Extends ();
use Pod::Weaver::Section::Consumes ();
use Pod::Elemental::Transformer::List ();

use Dist::Zilla::Plugin::RunExtraTests ();
use Dist::Zilla::Plugin::PodWeaver ();

use Dist::Zilla::Plugin::Test::Perl::Critic ();
use Dist::Zilla::Plugin::Test::PodSpelling ();
use Dist::Zilla::Plugin::PodCoverageTests ();

sub configure {
	my $self = shift;

	$self->add_bundle('Filter', {
		'-bundle' => '@Author::ZMUGHAL::Basic',
		'-remove' => [ 'PodWeaver' ],
	});

	# ; run the xt/ tests
	$self->add_plugins( qw( RunExtraTests) );

	$self->add_plugins([
		'PodWeaver' => [
			config_plugin => '@Author::ZMUGHAL::ProjectRenard',
		],
	]);

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

Dist::Zilla::PluginBundle::Author::ZMUGHAL::ProjectRenard - A plugin bundle for Project Renard

=head1 VERSION

version 0.004

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
