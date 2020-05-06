package Dist::Zilla::Plugin::ContributorCovenant;
$Dist::Zilla::Plugin::ContributorCovenant::VERSION = '2.000000';
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

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming,
diverse, inclusive, and healthy community.

## Our Standards

Examples of behavior that contributes to a positive environment for our
community include:

* Demonstrating empathy and kindness toward other people
* Being respectful of differing opinions, viewpoints, and experiences
* Giving and gracefully accepting constructive feedback
* Accepting responsibility and apologizing to those affected by our mistakes,
  and learning from the experience
* Focusing on what is best not just for us as individuals, but for the
  overall community

Examples of unacceptable behavior include:

* The use of sexualized language or imagery, and sexual attention or
  advances of any kind
* Trolling, insulting or derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or email
  address, without their explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

## Enforcement Responsibilities

Community leaders are responsible for clarifying and enforcing our standards of
acceptable behavior and will take appropriate and fair corrective action in
response to any behavior that they deem inappropriate, threatening, offensive,
or harmful.

Community leaders have the right and responsibility to remove, edit, or reject
comments, commits, code, wiki edits, issues, and other contributions that are
not aligned to this Code of Conduct, and will communicate reasons for moderation
decisions when appropriate.

## Scope

This Code of Conduct applies within all community spaces, and also applies when
an individual is officially representing the community in public spaces.
Examples of representing our community include using an official e-mail address,
posting via an official social media account, or acting as an appointed
representative at an online or offline event.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to the community leaders responsible for enforcement at
{{ $contact }}.
All complaints will be reviewed and investigated promptly and fairly.

All community leaders are obligated to respect the privacy and security of the
reporter of any incident.

## Enforcement Guidelines

Community leaders will follow these Community Impact Guidelines in determining
the consequences for any action they deem in violation of this Code of Conduct:

### 1. Correction

**Community Impact**: Use of inappropriate language or other behavior deemed
unprofessional or unwelcome in the community.

**Consequence**: A private, written warning from community leaders, providing
clarity around the nature of the violation and an explanation of why the
behavior was inappropriate. A public apology may be requested.

### 2. Warning

**Community Impact**: A violation through a single incident or series
of actions.

**Consequence**: A warning with consequences for continued behavior. No
interaction with the people involved, including unsolicited interaction with
those enforcing the Code of Conduct, for a specified period of time. This
includes avoiding interactions in community spaces as well as external channels
like social media. Violating these terms may lead to a temporary or
permanent ban.

### 3. Temporary Ban

**Community Impact**: A serious violation of community standards, including
sustained inappropriate behavior.

**Consequence**: A temporary ban from any sort of interaction or public
communication with the community for a specified period of time. No public or
private interaction with the people involved, including unsolicited interaction
with those enforcing the Code of Conduct, is allowed during this period.
Violating these terms may lead to a permanent ban.

### 4. Permanent Ban

**Community Impact**: Demonstrating a pattern of violation of community
standards, including sustained inappropriate behavior,  harassment of an
individual, or aggression toward or disparagement of classes of individuals.

**Consequence**: A permanent ban from any sort of public interaction within
the community.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage],
version 2.0, available at
https://www.contributor-covenant.org/version/2/0/code_of_conduct.html.

Community Impact Guidelines were inspired by [Mozilla's code of conduct
enforcement ladder](https://github.com/mozilla/diversity).

[homepage]: https://www.contributor-covenant.org

For answers to common questions about this code of conduct, see the FAQ at
https://www.contributor-covenant.org/faq. Translations are available at
https://www.contributor-covenant.org/translations.
END_TEMPLATE
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Kivanc Yazan C<< <kyzn at cpan.org> >>

=head1 CONTRIBUTORS

Joelle Maslak C<< <jmaslak at antelope.net> >>
D Ruth Holloway C<< <ruth at hiruthie.me> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Kivanc Yazan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 ATTRIBUTION

- This module is based heavily on L<Dist::Zilla::Plugin::Covenant>.

- Covenant text is taken from L<https://www.contributor-covenant.org/version/2/0/code_of_conduct/code_of_conduct.md>.

=head1 SEE ALSO

- Contributor Covenant, L<https://www.contributor-covenant.org/>

- VM Brasseur's "The Importance of Ecosystem" Keynote, L<https://archive.org/details/yatpc2018-ecosystem>

=cut
