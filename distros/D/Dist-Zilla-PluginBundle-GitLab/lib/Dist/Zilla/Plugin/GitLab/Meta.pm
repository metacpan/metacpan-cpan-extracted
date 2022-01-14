package Dist::Zilla::Plugin::GitLab::Meta 1.0002;

use Modern::Perl;
use JSON::MaybeXS;
use URL::Encode qw(url_encode_utf8);
use Moose;

extends 'Dist::Zilla::Plugin::GitLab';
with 'Dist::Zilla::Role::MetaProvider';

has bugs => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has fork => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has wiki => (
   is      => 'ro',
   isa     => 'Bool',
   default => 0,
);

has p3rl => (
   is      => 'ro',
   isa     => 'Bool',
   default => 0,
);

has metacpan => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has meta_home => (
   is      => 'ro',
   isa     => 'Bool',
   default => 0,
);

around dump_config => sub {
   my ( $orig, $self ) = @_;
   my $config = $self->$orig;

   my $option = first { $self->$_ } qw(meta_home metacpan p3rl);
   $config->{ +__PACKAGE__ } = { $option => ( $self->$option ? 1 : 0 ), };
   return $config;
};

sub metadata {
   my $self    = shift;
   my $offline = 0;

   my $repo_name = $self->_get_repo_name;
   return {} if ( !$repo_name );
   my $encoded_repo = url_encode_utf8($repo_name);

   my $http = HTTP::Tiny->new;

   $self->log('Getting GitLab repository info');

   my $url = $self->api . "/projects/$encoded_repo";
   $self->log_debug("Sending GET $url");
   my $response
      = $http->request( 'GET', $url, { headers => $self->_auth_headers } );

   my $repo = $self->_check_response($response);
   $offline = 1 if not $repo;

   $self->log('Using offline repository information') if $offline;

   if ( !$offline && $self->fork && defined $repo->{forked_from_project} ) {
      my $parent = $repo->{forked_from_project}{path_with_namespace};
      $url      = $self->api . '/projects/' . url_encode_utf8($parent);
      $response = $http->request( 'GET', $url );

      $repo = $self->_check_response($response);
      return if not $repo;
   }

   my ( $html_url, $git_url, $bugtracker );

   $html_url
      = $offline
      ? "https://GitLab.com/$repo_name"
      : $repo->{web_url};

   $git_url
      = $offline
      ? "git://GitLab.com/$repo_name.git"
      : $repo->{http_url_to_repo};

   if ( !$offline && $repo->{issues_enabled} == JSON->true() ) {
      $bugtracker = "$html_url/-/issues";
   }

   my $meta;
   $meta->{resources} = {
      repository => {
         web  => $html_url,
         url  => $git_url,
         type => 'git'
      }
   };

   my $dist_name = $self->zilla->name;
   if ( $self->meta_home
      && ( my $meta_home = $self->zilla->distmeta->{resources}{homepage} ) ) {
      $meta->{resources}{homepage} = $meta_home;
   }
   elsif ( $self->metacpan ) {
      $meta->{resources}{homepage}
         = "https://metacpan.org/release/$dist_name/";
   }
   elsif ( $self->p3rl ) {
      my $guess_name = $dist_name;
      $guess_name =~ s/\-/\:\:/g;
      $meta->{resources}{homepage} = "https://p3rl.org/$guess_name";
   }

   if ( $self->bugs && $self->bugs == 1 && $bugtracker ) {
      $meta->{resources}{bugtracker} = { web => $bugtracker };
   }

   return $meta;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitLab::Meta - Add a GitLab repo's info to META.{yml,json}

=head1 VERSION

version 1.0002

=head1 SYNOPSIS

Configure git with your GitLab login name:

    $ git config --global gitlab.user LoginName
    $ git config --global gitlab.token AccessToken

Set up an access token on GitLab, in your profile under "Personal Access Tokens." You
must grant the token the C<api> scope!

then, in your F<dist.ini>:

    # default config
    [GitLab::Meta]

    # to override the repo name
    [GitLab::Meta]
    repo = SomeRepo

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin adds some information about the distribution's GitLab
repository to the META.{yml,json} files, using the official L<CPAN::Meta>
specification.

Note that, to work properly, L<GitLab::Meta> needs the network to connect to
GitLab itself. If the network is not available, it will try to come up with
sensible data, but it may be inaccurate.

L<GitLab::Meta> currently sets the following fields:

=over 4

=item C<homepage>

The official home of this project on the web.

=item C<repository>

=over 4

=item C<web>

URL pointing to the GitLab page of the project.

=item C<url>

URL pointing to the GitLab repository (C<git://...>).

=item C<type>

This is set to C<git> by default.

=back

=item C<bugtracker>

=over 4

=item C<web>

URL pointing to the GitLab issues page of the project. If the C<bugs> option is
set to false (default is true) or the issues are disabled in the GitLab
repository, this will be skipped.

When offline, this is not set.

=back

=back

=head1 ATTRIBUTES

=over

=item C<bugs>

The META bugtracker web field will be set to the issue's page of the repository
on GitLab, if this option is set to true (default) and if the GitLab Issues happen to
be activated (see the GitLab repository's C<General> settings panel).

=item C<fork>

If the repository is a GitLab fork of another repository this option will make
all the information be taken from the original repository instead of the forked
one, if it's set to true (default).

=item C<metacpan>

The GitLab homepage field will be set to the metacpan.org distribution URL
(e.g. C<https://metacpan.org/release/Dist-Zilla-Plugin-GitLab>) if this option is set to true
(default).

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
(e.g. C<https://p3rl.org/Dist::Zilla::Plugin::GitLab>) if this option is set to true (default is
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

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Add a GitLab repo's info to META.{yml,json}

