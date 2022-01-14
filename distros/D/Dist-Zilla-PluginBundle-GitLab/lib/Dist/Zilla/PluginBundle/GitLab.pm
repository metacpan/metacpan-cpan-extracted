package Dist::Zilla::PluginBundle::GitLab 1.0002;

use Modern::Perl;
use Carp;
use Moose;
extends 'Dist::Zilla::Plugin::GitLab';
with 'Dist::Zilla::Role::PluginBundle::Easy';

has '+repo' => (
   lazy    => 1,
   default => sub { $_[0]->payload->{repo} },
);

# GitLab::Meta

has bugs => (
   is      => 'ro',
   isa     => 'Bool',
   lazy    => 1,
   default => sub {
      defined $_[0]->payload->{bugs} ? $_[0]->payload->{bugs} : 1;
   },
);

has fork => (
   is      => 'ro',
   isa     => 'Bool',
   lazy    => 1,
   default => sub {
      defined $_[0]->payload->{fork} ? $_[0]->payload->{fork} : 1;
   },
);

has p3rl => (
   is      => 'ro',
   isa     => 'Bool',
   lazy    => 1,
   default => sub {
      defined $_[0]->payload->{p3rl} ? $_[0]->payload->{p3rl} : 0;
   },
);

has metacpan => (
   is      => 'ro',
   isa     => 'Bool',
   lazy    => 1,
   default => sub {
      defined $_[0]->payload->{metacpan} ? $_[0]->payload->{metacpan} : 0;
   },
);

has meta_home => (
   is      => 'ro',
   isa     => 'Bool',
   lazy    => 1,
   default => sub {
      defined $_[0]->payload->{meta_home} ? $_[0]->payload->{meta_home} : 0;
   },
);

has remote => (
   is      => 'ro',
   isa     => 'Maybe[Str]',
   lazy    => 1,
   default => sub {
      defined $_[0]->payload->{remote} ? $_[0]->payload->{remote} : 'origin';
   },
);

has wiki => (
   is      => 'ro',
   isa     => 'Bool',
   lazy    => 1,
   default => sub {
      defined $_[0]->payload->{wiki} ? $_[0]->payload->{wiki} : 0;
   },
);

sub configure {
   my $self = shift;

   $self->add_plugins(
      [
         'GitLab::Meta' => {
            bugs      => $self->bugs,
            fork      => $self->fork,
            metacpan  => $self->metacpan,
            meta_home => $self->meta_home,
            p3rl      => $self->p3rl,
            remote    => $self->remote,
            repo      => $self->repo,
            wiki      => $self->wiki,
         }
      ],

      [
         'GitLab::Update' => {
            repo => $self->repo,
         }
      ]
   );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::GitLab - Access GitLab functionality to maintain distros from Dist::Zilla

=head1 VERSION

version 1.0002

=head1 SYNOPSIS

Configure git with your GitLab credentials:

    $ git config --global gitlab.user LoginName
    $ git config --global gitlab.token AccessToken

Alternatively you can install L<Config::Identity> and write your credentials
in the (optionally GPG-encrypted) C<~/.gitlab> file as follows:

    login LoginName
    token AccessToken

Set up an access token on GitLab, in your profile under "Personal Access Tokens." You
must grant the token the C<api> scope!

then, in your F<dist.ini>:

    [@GitLab]
    repo = SomeRepo

=head1 DESCRIPTION

This bundle automatically adds the plugins
L<GitLab::Meta|Dist::Zilla::Plugin::GitLab::Meta>
and L<GitLab::Update|Dist::Zilla::Plugin::GitLab::Update>.

=head1 ATTRIBUTES

=over

=item C<bugs>

The META bugtracker web field will be set to the issue's page of the repository
on GitLab, if this options is set to true (default) and if the GitLab Issues happen to
be activated (see the GitLab repository's C<Admin> panel).

=item C<fork>

If the repository is a GitLab fork of another repository this option will make
all the information be taken from the original repository instead of the forked
one, if it's set to true (default).

=item C<metacpan>

The GitLab homepage field will be set to the metacpan.org distribution URL
(e.g. C<https://metacpan.org/release/Dist-Zilla-Plugin-GitLab>) if this option is set to true
(default is false).

This takes precedence over the C<p3rl> options (if both are
true, metacpan will be used).

=item C<meta_home>

The GitLab homepage field will be set to the value present in the dist meta
(e.g. the one set by other plugins) if this option is set to true (default is
false). If no value is present in the dist meta, this option is ignored.

This takes precedence over the C<metacpan> and C<p3rl> options (if all
three are true, meta_home will be used).

=item C<p3rl>

The GitLab homepage field will be set to the p3rl.org shortened URL
(e.g. C<https://p3rl.org/Dist::Zilla::PluginBundle::GitLab>) if this option is set to true (default is
false).

=item C<remote>

Specifies the git remote name to be used when guessing the repo name (default C<origin>). 

=item C<repo>

The name of the GitLab repository. By default the name will be extracted from
the URL of the remote specified in the C<remote> option, and if that fails the
dist name (from dist.ini) is used. It can also be in the form C<user/repo>
when it belongs to another GitLab user/organization.

=item C<wiki>

The META homepage field will be set to the URL of the wiki of the GitLab
repository, if this option is set to true (default is false) and if the GitLab
Wiki happens to be activated (see the GitLab repository's C<Admin> panel).

=back

=head1 SEE ALSO

L<Dist::Zilla::Plugin::GitLab::Meta>, L<Dist::Zilla::Plugin::GitLab::Update>

=head1 ACKNOWLEDGEMENTS

Alessandro Ghedini <alexbio@cpan.org> made L<Dist::Zilla::PluginBundle::GitLab> from
which this module is created. Much of the underlying code is from that module.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Access GitLab functionality to maintain distros from Dist::Zilla


