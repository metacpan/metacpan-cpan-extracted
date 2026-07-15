package Dist::Zilla::Plugin::Codeberg::Update 2.0102;

use Modern::Perl;
use Carp;
use JSON::MaybeXS;
use Moose;
use List::Util  qw(first);
use URL::Encode qw(url_encode_utf8);

our $AUTHORITY = 'cpan:GEEKRUTH';    # AUTHORITY
extends 'Dist::Zilla::Plugin::Codeberg';
with 'Dist::Zilla::Role::AfterRelease';

sub after_release {
   my $self = shift;

   return if ( !$self->_has_credentials );

   my $repo_name = $self->_get_repo_name( $self->_credentials->{login} );
   if ( not $repo_name ) {
      $self->log('cannot update Codeberg repository info');
      return;
   }

   my $params = {
      name        => ( $repo_name =~ /\/(.*)$/ )[0],
      description => $self->zilla->abstract,
   };

   $self->log('Updating Codeberg repository info');

   my $url
      = $self->api . '/repos/' . $repo_name;    # url_encode_utf8($repo_name);

   my $current = $self->_current_params($url);
   if (  $current
      && ( $current->{name}        || q{} ) eq $params->{name}
      && ( $current->{description} || q{} ) eq $params->{description} ) {

      $self->log('Codeberg repo info is up to date');
      return;
   }
   my $headers = $self->_auth_headers;
   $headers->{'content-type'} = 'application/json';

   $self->log_debug("Sending PATCH $url");
   my $response = HTTP::Tiny->new->request(
      'PATCH', $url,
      {
         content => encode_json($params),
         headers => $headers,
      }
   );

   my $repo = $self->_check_response($response);

   return if not $repo;
}

sub _current_params {
   my $self = shift;
   my ($url) = @_;

   my $http = HTTP::Tiny->new;

   $self->log_debug("Sending GET $url");
   my $response = $http->request( 'GET', $url );

   return $self->_check_response($response);
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Codeberg::Update - Update a Codeberg repo's info on release

=head1 VERSION

version 2.0102

=head1 SYNOPSIS

Configure git with your Codeberg login name:

    $ git config --global codeberg.user LoginName
    $ git config --global codeberg.token AccessToken

Set up an access token on Codeberg, in your profile under "Personal Access Tokens." You
must grant the token the C<api> scope!

then, in your F<dist.ini>:

    # default config
    [Codeberg::Update]

    # to override the repo name
    [Codeberg::Update]
    repo = SomeRepo

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin updates the information of the Codeberg repository
when C<dzil release> is run.

=head1 ATTRIBUTES

=over

=item C<remote>

Specifies the git remote name to be used when guessing the repo name (default C<origin>). 

=item C<repo>

The name of the Codeberg repository. By default the name will be extracted from
the URL of the remote specified in the C<remote> option, and if that fails the
dist name (from dist.ini) is used. It can also be in the form C<user/repo>
when it belongs to another Codeberg user/organization.

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Update a Codeberg repo's info on release

