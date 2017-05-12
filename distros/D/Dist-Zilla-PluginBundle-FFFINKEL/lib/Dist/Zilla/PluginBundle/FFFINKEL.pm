package Dist::Zilla::PluginBundle::FFFINKEL;
BEGIN {
  $Dist::Zilla::PluginBundle::FFFINKEL::AUTHORITY = 'cpan:FFFINKEL';
}
{
  $Dist::Zilla::PluginBundle::FFFINKEL::VERSION = '0.008';
}

# ABSTRACT: My Dist::Zilla plugin bundle

use Moose;
use namespace::autoclean;
with qw/ Dist::Zilla::Role::PluginBundle::Easy /;


sub configure {
	my ($self) = @_;

	$self->add_bundle(
		'@Filter',
		{
			'-bundle' => '@Basic',
			'-remove' => [ 'ShareDir' ],
		}
	);

	$self->add_plugins( [ 'Git::NextVersion', { first_version => 0.001 } ] );
	$self->add_plugins('PkgVersion');
	$self->add_plugins( [ 'Authority', { authority => 'cpan:FFFINKEL', } ] );
	$self->add_plugins('ChangelogFromGit');

	$self->add_plugins(
		qw/
			PodWeaver
			AutoPrereqs
			Clean
			/
	);

	$self->add_plugins(
		qw/
		  EOLTests
		  PodSyntaxTests
		  Git::Check
		  /
		  #PodCoverageTests
	);

	$self->add_bundle(
		'@Git',
		{
			push_to => 'origin',
			push_to => 'github',
		}
	);

	$self->add_plugins('Twitter');

}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::FFFINKEL - My Dist::Zilla plugin bundle

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  [@FFFINKEL]

=head1 DESCRIPTION

  [@Filter]
  -bundle = @Basic
  -remove = ShareDir

  [Git::NextVersion]
  first_version = 0.001
  [PkgVersion]
  [Authority]
  authority = cpan:FFFINKEL
  [ChangelogFromGit]

  [PodWeaver]
  [AutoPrereqs]
  [Clean]

  [EOLTests]
  [PodSyntaxTests]
  [PodCoverageTests]
  [Git::Check]

  [@Git]
  push_to = origin
  push_to = github

  [Twitter]

=head1 NAME

Dist::Zilla::PluginBundle::FFFINKEL - My Dist::Zilla plugin bundle

=head1 METHODS

=head2 configure

Bundle configuration method, see
L<Dist::Zilla::PluginBundle::Easy/"DESCRIPTION">

=head1 AUTHOR

Matt Finkel <fffinkel@cpan.org>

=head1 SEE ALSO

L<Dist::Zilla::Role::PluginBundle::Easy> L<Dist::Zilla::PluginBundle::RJBS>
L<Dist::Zilla::PluginBundle::INGY>

=head1 AUTHOR

Matt Finkel <fffinkel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Matt Finkel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
