package Dist::Zilla::Plugin::Codeberg::Meta 2.0000;

use Modern::Perl;
use JSON::MaybeXS;
use URL::Encode qw(url_encode_utf8);
use Moose;

extends 'Dist::Zilla::Plugin::Codeberg';
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

   $self->log('Getting Codeberg repository info');

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
      ? "https://Codeberg.org/$repo_name"
      : $repo->{web_url};

   $git_url
      = $offline
      ? "git://Codeberg.org/$repo_name.git"
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

Dist::Zilla::Plugin::Codeberg::Meta - Add a Codeberg repo's info to META.{yml,json}

=head1 VERSION

version 2.0000

=head1 SYNOPSIS

Configure git with your Codeberg login name:

    $ git config --global codeberg.user LoginName
    $ git config --global codeberg.token AccessToken

Set up an access token on Codeberg, in your profile under "Personal Access Tokens." You
must grant the token the C<api> scope!

then, in your F<dist.ini>:

    # default config
    [Codeberg::Meta]

    # to override the repo name
    [Codeberg::Meta]
    repo = SomeRepo

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin adds some information about the distribution's Codeberg
repository to the META.{yml,json} files, using the official L<CPAN::Meta>
specification.

Note that, to work properly, L<Codeberg::Meta> needs the network to connect to
Codeberg itself. If the network is not available, it will try to come up with
sensible data, but it may be inaccurate.

L<Codeberg::Meta> currently sets the following fields:

=over 4

=item C<homepage>

The official home of this project on the web.

=item C<repository>

=over 4

=item C<web>

URL pointing to the Codeberg page of the project.

=item C<url>

URL pointing to the Codeberg repository (C<git://...>).

=item C<type>

This is set to C<git> by default.

=back

=item C<bugtracker>

=over 4

=item C<web>

URL pointing to the Codeberg issues page of the project. If the C<bugs> option is
set to false (default is true) or the issues are disabled in the Codeberg
repository, this will be skipped.

When offline, this is not set.

=back

=back

=head1 ATTRIBUTES

=over

=item C<bugs>

The META bugtracker web field will be set to the issue's page of the repository
on Codeberg, if this option is set to true (default) and if the Codeberg Issues happen to
be activated (see the Codeberg repository's C<General> settings panel).

=item C<fork>

If the repository is a Codeberg fork of another repository this option will make
all the information be taken from the original repository instead of the forked
one, if it's set to true (default).

=item C<metacpan>

The Codeberg homepage field will be set to the metacpan.org distribution URL
(e.g. C<https://metacpan.org/release/Dist-Zilla-Plugin-Codeberg>) if this option is set to true
(default).

This takes precedence over the C<p3rl> options (if both are
true, metacpan will be used).

=item C<meta_home>

The Codeberg homepage field will be set to the value present in the dist meta
(e.g. the one set by other plugins) if this option is set to true (default is
false). If no value is present in the dist meta, this option is ignored.

This takes precedence over the C<metacpan> and C<p3rl> options (if all
three are true, meta_home will be used).

=item C<p3rl>

The Codeberg homepage field will be set to the p3rl.org shortened URL
(e.g. C<https://p3rl.org/Dist::Zilla::Plugin::Codeberg>) if this option is set to true (default is
false).

=item C<remote>

Specifies the git remote name to be used when guessing the repo name (default C<origin>). 

=item C<repo>

The name of the Codeberg repository. By default the name will be extracted from
the URL of the remote specified in the C<remote> option, and if that fails the
dist name (from dist.ini) is used. It can also be in the form C<user/repo>
when it belongs to another Codeberg user/organization.

=item C<wiki>

The META homepage field will be set to the URL of the wiki of the Codeberg
repository, if this option is set to true (default is false) and if the Codeberg
Wiki happens to be activated (see the Codeberg repository's C<Admin> panel).

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Add a Codeberg repo's info to META.{yml,json}

