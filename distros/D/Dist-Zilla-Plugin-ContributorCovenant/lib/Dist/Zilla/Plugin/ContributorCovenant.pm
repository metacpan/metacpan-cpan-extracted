package Dist::Zilla::Plugin::ContributorCovenant;
$Dist::Zilla::Plugin::ContributorCovenant::VERSION = '1.004001';
=head1 NAME

Dist::Zilla::Plugin::ContributorCovenant - Add Contributor Covenant as Code of Conduct

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::ContributorCovenant> adds the Contributor
Covenant to your CPAN build as C<CODE_OF_CONDUCT.md>. It pulls
email address of first author from C<dist.ini>. If none found,
it will type "GitHub / RT" instead.

=head1 SYNOPSIS

Add this one line to your dist.ini.

  [ContributorCovenant]

If you want to leave a copy of Code Of Conduct in code repository,
You can add following lines to your dist.ini as well.

  [CopyFilesFromBuild]
  copy = CODE_OF_CONDUCT.md

Note that this plugin will prune other CODE_OF_CONDUCT.md files, to
avoid multiple CODE_OF_CONDUCT.md preventing the build.

The version of this module will match the version of the Contributor
Covenant used.  For instance, version 1.004001 will use Contributor
Covenant version 1.4.1.

=cut

use warnings;
use strict;

use Moose;
use Dist::Zilla::File::InMemory;

with qw/
  Dist::Zilla::Role::Plugin
  Dist::Zilla::Role::FileGatherer
  Dist::Zilla::Role::FilePruner
  Dist::Zilla::Role::TextTemplate
  Dist::Zilla::Role::MetaProvider
/;

sub metadata {
  return { 'x_contributor_covenant' => { 'version' => 0.02 } };
}

has '+zilla' => (
  handles => { authors => 'authors' },
);

has contributor_covenant => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self    = shift;
    my ($author, $email);

    $author  = $self->authors->[0];
    ($email) = $author =~ /<(.*)>/ if $author;
    my $contact = $email || 'GitHub / RT';

    $self->fill_in_string(contributor_covenant_template(),{
      contact => $contact,
    });
  },
);

sub gather_files {
  my $self    = shift;
  $self->add_file(
    Dist::Zilla::File::InMemory->new({
      content => $self->contributor_covenant,
      name  => 'CODE_OF_CONDUCT.md',
    })
  );
}

sub prune_files {
  my $self = shift;

  my @coc_files = grep {$_->name eq 'CODE_OF_CONDUCT.md'} @{$self->zilla->files};
  return unless scalar @coc_files > 1;

  # We will keep COC file produced by this plugin
  foreach my $file (@coc_files){
    my $keep = 0;
    foreach my $source ($file->added_by){
      $keep = 1 if $source =~ 'Dist::Zilla::Plugin::ContributorCovenant';
    }
    $self->zilla->prune_file($file) unless $keep;
  }

}

sub contributor_covenant_template {
  return <<'END_TEMPLATE';
# Contributor Covenant Code of Conduct

## Our Pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, sex characteristics, gender identity and expression,
level of experience, education, socio-economic status, nationality, personal
appearance, race, religion, or sexual identity and orientation.

## Our Standards

Examples of behavior that contributes to creating a positive environment
include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or
  advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic
  address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

## Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem inappropriate,
threatening, offensive, or harmful.

## Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an appointed
representative at an online or offline event. Representation of a project may be
further defined and clarified by project maintainers.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported by contacting the project team at {{ $contact }}. All
complaints will be reviewed and investigated and will result in a response that
is deemed necessary and appropriate to the circumstances. The project team is
obligated to maintain confidentiality with regard to the reporter of an incident.
Further details of specific enforcement policies may be posted separately.

Project maintainers who do not follow or enforce the Code of Conduct in good
faith may face temporary or permanent repercussions as determined by other
members of the project's leadership.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 1.4,
available at https://www.contributor-covenant.org/version/1/4/code-of-conduct.html

[homepage]: https://www.contributor-covenant.org

END_TEMPLATE
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Kivanc Yazan C<< <kyzn at cpan.org> >>

=head1 CONTRIBUTORS

Joelle Maslak C<< <jmaslak at antelope.net> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Kivanc Yazan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 ATTRIBUTION

- This module is based heavily on L<Dist::Zilla::Plugin::Covenant>.

- Covenant text is taken from L<https://www.contributor-covenant.org/version/1/4/code-of-conduct.md>.

=head1 SEE ALSO

- Contributor Covenant, L<https://www.contributor-covenant.org/>

- VM Brasseur's "The Importance of Ecosystem" Keynote, L<https://archive.org/details/yatpc2018-ecosystem>

=cut
