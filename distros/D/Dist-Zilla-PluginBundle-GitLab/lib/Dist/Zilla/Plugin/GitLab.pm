package Dist::Zilla::Plugin::GitLab 1.0002;

use Modern::Perl;
use JSON::MaybeXS;
use Moose;
use Try::Tiny;
use HTTP::Tiny;
use Git::Wrapper;
use Class::Load qw(try_load_class);

has api => (
   is      => 'ro',
   isa     => 'Str',
   default => 'https://gitlab.com/api/v4',
);

has remote => (
   is      => 'ro',
   isa     => 'Maybe[Str]',
   default => 'origin',
);

has repo => (
   is  => 'ro',
   isa => 'Maybe[Str]',
);

has _credentials => (
   is      => 'ro',
   isa     => 'HashRef',
   lazy    => 1,
   builder => '_build_credentials',
);

has _login => (
   is      => 'ro',
   isa     => 'Maybe[Str]',
   lazy    => 1,
   builder => '_build_login',
);

sub _build_login {
   my $self = shift;

   my ( $login, %identity );

   %identity = Config::Identity::GitLab->load
      if try_load_class('Config::Identity::GitLab');

   if (%identity) {
      $login = $identity{login};
   }
   else {
      $login = qx{git config gitlab.user};
      chomp $login;
   }

   if ( !$login ) {
      my $error
         = %identity
         ? 'Err: missing value \'user\' in ~/.gitlab'
         : 'Err: Missing value \'gitlab.user\' in git config';

      $self->log($error);
      return undef;
   }

   return $login;
}

sub _build_credentials {
   my $self = shift;

   my ( $login, $token );

   $login = $self->_login;

   if ( !$login ) {
      return {};
   }
   my %identity;
   %identity = Config::Identity::GitLab->load
      if try_load_class('Config::Identity::GitLab');

   if (%identity) {
      $token = $identity{token};
   }
   else {
      $token = qx{git config gitlab.token};
      chomp $token;
   }

   return { login => $login, token => $token };
}

sub _has_credentials {
   my $self = shift;
   return keys %{ $self->_credentials };
}

sub _auth_headers {
   my $self = shift;

   my $credentials = $self->_credentials;

   my %headers = ();
   if ( $credentials->{token} ) {
      $headers{'PRIVATE-TOKEN'} = $credentials->{token};
   }

   return \%headers;
}

sub _get_repo_name {
   my ( $self, $login ) = @_;

   my $repo;
   my $git = Git::Wrapper->new('./');

   $repo = $self->repo if $self->repo;

   my $url;
   {
      local $ENV{LANG} = 'C';
      ($url) = map /Fetch URL: (.*)/,
         $git->remote( 'show', '-n', $self->remote );
   }
   if ( !$repo ) {
      ($repo) = $url =~ /gitlab\.com.*?[:\/](.*)\.git$/;
   }

   $repo = $self->zilla->name unless $repo;

   if ( $repo !~ /.*\/.*/ ) {
      $login = $self->_login;
      if ( defined $login ) {
         $repo = "$login/$repo";
      }
   }

   return $repo;
}

sub _check_response {
   my ( $self, $response ) = @_;

   try {
      my $json_text = decode_json( $response->{content} );

      if ( !$response->{success} ) {

         require Data::Dumper;
         $self->log(
            'Err: ',
            Data::Dumper->new( [$response] )->Indent(2)->Terse(1)
               ->Sortkeys(1)->Dump
         );
         return;
      }

      return $json_text;
   }
   catch {
      $self->log("Error: $_");
      if (  $response
         && !$response->{success}
         && $response->{status} eq '599' ) {

         #possibly HTTP::Tiny error
         $self->log( 'Err: ', $response->{content} );
         return;
      }

      $self->log("Error communicating with GitLab: $_");

      return;
   };
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitLab - Plugins to integrate Dist::Zilla with GitLab

=head1 VERSION

version 1.0002

=head1 DESCRIPTION

B<Dist-Zilla-Plugin-GitLab> is a set of plugins for L<Dist::Zilla> intended
to more easily integrate L<GitLab|https://gitlab.com> in the C<dzil> workflow.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::GitLab::Create> Create GitLab repo on C<dzil new>

=item * L<Dist::Zilla::Plugin::GitLab::Update> Update GitLab repo info on release

=item * L<Dist::Zilla::Plugin::GitLab::Meta> Add GitLab repo info to F<META.{yml,json}>

=back

This distribution also provides a plugin bundle, L<Dist::Zilla::PluginBundle::GitLab>,
which provides L<GitLab::Meta|Dist::Zilla::Plugin::GitLab::Meta> and
L<GitLab::Update|Dist::Zilla::Plugin::GitLab::Update> together in one convenient bundle.

This distribution also provides an additional C<dzil> command (L<dzil
gh|Dist::Zilla::App::Command::gh>).

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Plugins to integrate Dist::Zilla with GitLab

