package Dist::Zilla::Plugin::GitLab::Create 1.0002;

use Modern::Perl;
use JSON::MaybeXS;
use Moose;
use Try::Tiny;
use Git::Wrapper;
use File::Basename;

extends 'Dist::Zilla::Plugin::GitLab';
with 'Dist::Zilla::Role::AfterMint';
with 'Dist::Zilla::Role::TextTemplate';

has issues => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has merge_requests => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has namespace => (
   is  => 'ro',
   isa => 'Maybe[Str]',
);

has packages => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has prompt => (
   is      => 'ro',
   isa     => 'Bool',
   default => 0,
);

has public => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has remote => (
   is      => 'ro',
   isa     => 'Str',
   default => 'origin',
);

has repo => (
   is  => 'ro',
   isa => 'Maybe[Str]',
);

has snippets => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

has wiki => (
   is      => 'ro',
   isa     => 'Bool',
   default => 1,
);

sub after_mint {
   my $self = shift;
   my ($opts) = @_;

   return if $self->prompt and not $self->_confirm;

   my $root      = $opts->{mint_root};
   my $repo_name = $self->zilla->name;
   if ( $opts->{repo} ) {
      $repo_name = $opts->{repo};
   }
   elsif ( $self->repo ) {
      $repo_name
         = $self->fill_in_string( $self->repo, { dist => \( $self->zilla ) },
         );
   }

   $self->log( [ 'Creating new GitLab repository \'%s\'', $repo_name ] );
   my $http = HTTP::Tiny->new;
   my ( $params, $headers, $content );

   $headers = $self->_auth_headers;
   if ( $self->namespace ) {
      my $namespaces_url = $self->api . '/namespaces';
      my $namespaces
         = $http->request( 'GET', $namespaces_url, { headers => $headers } );
      my $spaces = $self->_check_response($namespaces);
      foreach my $space (@$spaces) {
         next if $self->namespace ne $space->path;
         $params->{namespace_id} = $space->id;
      }
   }

   $params->{name}       = $repo_name;
   $params->{visibility} = $self->public ? 'public' : 'private';
   $params->{description}
      = $opts->{description}
      ? $opts->{description}
      : undef;
   $params->{issues_enabled} = $self->issues;
   $self->log(
      [ 'Issues are %s', $params->{issues_enabled} ? 'enabled' : 'disabled' ]
   );
   $params->{wiki_enabled} = $self->wiki;
   $self->log(
      [ 'Wiki is %s', $params->{wiki_enabled} ? 'enabled' : 'disabled' ] );
   $params->{packages_enabled} = $self->packages;
   $self->log(
      [
         'Packages are %s',
         $params->{packages_enabled} ? 'enabled' : 'disabled'
      ]
   );
   $params->{snippets_enabled} = $self->snippets;
   $self->log(
      [
         'Snippets are %s',
         $params->{snippets_enabled} ? 'enabled' : 'disabled'
      ]
   );
   $params->{merge_requests_enabled} = $self->merge_requests;
   $self->log(
      [
         'Merge requests are %s',
         $params->{merge_requests_enabled} ? 'enabled' : 'disabled'
      ]
   );

   my $url = $self->api . '/projects';
   $content = encode_json($params);
   $headers->{'content-type'} = 'application/json';
   $self->log_debug("Sending POST $url");

   my $response = $http->request(
      'POST', $url,
      {
         content => $content,
         headers => $headers,
      }
   );

   my $repo = $self->_check_response($response);

   return if not $repo;

   my $git_dir = "$root/.git";
   my $rem_ref = $git_dir . '/refs/remotes/' . $self->remote;

   if ( ( -d $git_dir ) && ( not -d $rem_ref ) ) {
      my $git = Git::Wrapper->new($root);

      $self->log( [ 'Setting GitLab remote \'%s\'', $self->remote ] );
      $git->remote( 'add', $self->remote, $repo->{ssh_url_to_repo} );

      my ($branch) = try {
         $git->rev_parse( { abbrev_ref => 1, symbolic_full_name => 1 },
            'HEAD' )
      };

      if ($branch) {
         try {
            $git->config("branch.$branch.merge");
            $git->config("branch.$branch.remote");
         }
         catch {
            $self->log(
               [ 'Setting up remote tracking for branch \'%s\'', $branch ] );

            $git->config( "branch.$branch.merge",  "refs/heads/$branch" );
            $git->config( "branch.$branch.remote", $self->remote );
         };
      }
   }
}

sub _confirm {
   my ($self) = @_;

   my $dist   = $self->zilla->name;
   my $prompt = "Shall I create a GitLab repository for $dist?";

   return $self->zilla->chrome->prompt_yn( $prompt, { default => 1 } );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitLab::Create - Create a new GitLab repo on dzil new

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

then, in your F<profile.ini>:

    # default config
    [GitLab::Create]

    # to override publicness
    [GitLab::Create]
    public = 0

    # use a template for the repository name
    [GitLab::Create]
    repo = {{ lc $dist->name }}

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin creates a new git repository on GitLab.com when
a new distribution is created with C<dzil new>.

It will also add a new git remote pointing to the newly created GitLab
repository's private URL. See L</"ADDING REMOTE"> for more info.

=head1 ATTRIBUTES

=over

=item C<issues>

Enable issues for the new repository if this option is set to true (default).

=item C<merge_requests>

Enable merge requests for the new repository if this option is set to true (default).

=item C<namespace>

Specifies the project namespace path in which to create the repository
(by default the repository is created in the user's account).

=item C<packages>

Enable packages for the new repository if this option is set to true (default).

=item C<prompt>

Prompt for confirmation before creating a GitLab repository if this option is
set to true (default is false).

=item C<public>

Create a public repository if this option is set to true (default), otherwise
create a private repository.

=item C<remote>

Specifies the git remote name to be added (default 'origin'). This will point to
the newly created GitLab repository's private URL. See L</"ADDING REMOTE"> for
more info.

=item C<repo>

Specifies the name of the GitLab repository to be created (by default the name
of the dist is used). This can be a template, so something like the following
will work:

    repo = {{ lc $dist->name }}

=item C<snippets>

Enable snippets for the new repository if this option is set to true (default).

=item C<wiki>

Enable the wiki for the new repository if this option is set to true (default).

=back

=head1 ADDING REMOTE

By default C<GitLab::Create> adds a new git remote pointing to the newly created
GitLab repository's private URL B<if, and only if,> a git repository has already
been initialized, and if the remote doesn't already exist in that repository.

To take full advantage of this feature you should use, along with C<GitLab::Create>,
the L<Dist::Zilla::Plugin::Git::Init> plugin, leaving blank its C<remote> option,
as follows:

    [Git::Init]
    ; here goes your Git::Init config, remember
    ; to not set the 'remote' option
    [GitLab::Create]

You may set your preferred remote name, by setting the C<remote> option of the
C<GitLab::Create> plugin, as follows:

    [Git::Init]
    [GitLab::Create]
    remote = myremote

Remember to put C<[Git::Init]> B<before> C<[GitLab::Create]>.

After the new remote is added, the current branch will track it, unless remote
tracking for the branch was already set. This may allow one to use the
L<Dist::Zilla::Plugin::Git::Push> plugin without the need to do a C<git push>
between the C<dzil new> and C<dzil release>. Note though that this will work
only when the C<push.default> Git configuration option is set to either
C<upstream> or C<simple> (which will be the default in Git 2.0). If you are
using an older Git or don't want to change your config, you may want to have a
look at L<Dist::Zilla::Plugin::Git::PushInitial>.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Create a new GitLab repo on dzil new

