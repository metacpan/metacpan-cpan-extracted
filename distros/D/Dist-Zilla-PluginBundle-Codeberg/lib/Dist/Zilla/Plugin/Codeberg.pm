package Dist::Zilla::Plugin::Codeberg 2.0000;

use Modern::Perl;
use JSON::MaybeXS;
use Moose;
use Try::Tiny;
use HTTP::Tiny;
use Git::Wrapper;
use Class::Load qw(try_load_class);

our $AUTHORITY = 'cpan:GEEKRUTH';    # AUTHORITY
has api => (
   is      => 'ro',
   isa     => 'Str',
   default => 'https://codeberg.org/api/v1',
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

   %identity = Config::Identity::Codeberg->load
      if try_load_class('Config::Identity::Codeberg');

   if (%identity) {
      $login = $identity{login};
   }
   else {
      $login = qx{git config codeberg.user};
      chomp $login;
   }

   if ( !$login ) {
      my $error
         = %identity
         ? 'Err: missing value \'user\' in ~/.codeberg'
         : 'Err: Missing value \'codeberg.user\' in git config';

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
   %identity = Config::Identity::Codeberg->load
      if try_load_class('Config::Identity::Codeberg');

   if (%identity) {
      $token = $identity{token};
   }
   else {
      $token = qx{git config codeberg.token};
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
      ($repo) = $url =~ /codeberg\.org.*?[:\/](.*)\.git$/;
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
            Data::Dumper->new( [$response] )
               ->Indent(2)
               ->Terse(1)
               ->Sortkeys(1)
               ->Dump
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

      $self->log("Error communicating with Codeberg: $_");

      return;
   };
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Codeberg - Plugins to integrate Dist::Zilla with Codeberg

=head1 VERSION

version 2.0000

=head1 DESCRIPTION

B<Dist-Zilla-Plugin-Codeberg> is a set of plugins for L<Dist::Zilla> intended
to more easily integrate L<Codeberg|https://codeberg.org> in the C<dzil> workflow.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::Codeberg::Create> Create Codeberg repo on C<dzil new>

=item * L<Dist::Zilla::Plugin::Codeberg::Update> Update Codeberg repo info on release

=item * L<Dist::Zilla::Plugin::Codeberg::Meta> Add Codeberg repo info to F<META.{yml,json}>

=back

This distribution also provides a plugin bundle, L<Dist::Zilla::PluginBundle::Codeberg>,
which provides L<Codeberg::Meta|Dist::Zilla::Plugin::Codeberg::Meta> and
L<Codeberg::Update|Dist::Zilla::Plugin::Codeberg::Update> together in one convenient bundle.

This distribution also provides an additional C<dzil> command (L<dzil
codeberg|Dist::Zilla::App::Command::codeberg>).

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Plugins to integrate Dist::Zilla with Codeberg

