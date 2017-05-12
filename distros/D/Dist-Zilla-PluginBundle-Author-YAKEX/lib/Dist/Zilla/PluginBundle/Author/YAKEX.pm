package Dist::Zilla::PluginBundle::Author::YAKEX;

use strict;
use warnings;

# ABSTRACT: Dist::Zilla configuration the way YAKEX does it
our $VERSION = 'v0.1.5'; # VERSION

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::PluginRemover';

sub configure
{
	my $self = shift;
	$self->add_bundle('Basic');
	$self->add_plugins(
		[ NextRelease => { filename => 'Changes' } ],
	);
	$self->add_bundle(Git => {
		commit_msg => 'Released as %v%n%n%c',
		tag_format => '%v',
		tag_message => 'Released as %v',
		allow_dirty => [ 'Changes', 'README.md', 'dist.ini' ],
	});
	$self->add_plugins(
		[ ReadmeAnyFromPod => {
			type => 'markdown',
			filename => 'README.md',
			location => 'root',
		} ],
		qw[
			GithubMeta MetaJSON PodWeaver OurPkgVersion CheckVersionIncrement MinimumPerl
			PodSyntaxTests PodCoverageTests Test::Perl::Critic Test::Compile
		],
		[ 'Test::Kwalitee::Extra' => { arg => ['!has_example'] } ],
		[ Twitter => { url_shortener => 'none', hash_tags => '#perl' } ],
	);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::YAKEX - Dist::Zilla configuration the way YAKEX does it

=head1 VERSION

version v0.1.5

=head1 SYNOPSIS

  # in dist.ini
  [@Author::YAKEX]

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle used by YAKEX's distribution. It is equivalent to the following dist.ini

  [@Basic]
  
  [NextRelease]
  filename = Changes
  
  [@Git]
  commit_msg = Released as %v%n%n%c
  tag_format = %v
  tag_message = Released as %v
  allow_dirty = Changes
  allow_dirty = README.md
  allow_dirty = dist.ini
  
  [ReadmeAnyFromPod]
  type = markdown
  filename = README.md
  location = root
  
  [GithubMeta]
  [MetaJSON]
  [PodWeaver]
  [OurPkgVersion]
  [CheckVersionIncrement]
  [PodSyntaxTests]
  [PodCoverageTests]
  [Test::Perl::Critic]
  [Test::Compile]
  [Test::Kwalitee::Extra]
  arg = !has_example
  arg = !build_prereq_matches_use
  
  [Twitter]
  url_shortener = none
  hash_tags = #perl
  
  [MinimumPerl]

This PluginBundle also supports PluginRemover, so dropping a plugin is as easy as this:

   [@YAKEX]
   -remove = PluginDontUse

=head1 METHODS

=head2 C<configure>

See L<Dist::Zilla::Role::PluginBundle::Easy>

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
