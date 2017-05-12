package Dist::Zilla::Plugin::UpdateGitHub;
BEGIN {
  $Dist::Zilla::Plugin::UpdateGitHub::VERSION = '0.0019';
}
# ABSTRACT: Update your github repository description from abstract on release


use Moose;
with qw/ Dist::Zilla::Role::Releaser /;

use Config::Identity::GitHub;
use LWP::UserAgent;
my $agent = LWP::UserAgent->new;

sub update {
    my $self = shift;
    my %given = @_;
    my ( $login, $token, $repository, $description );

    ( $repository, $description ) = @given{qw/ repository description /};
    defined $_ && length $_ or die "Missing repository" for $repository;
    defined $_ && length $_ or die "Missing description" for $description;

    ( $login, $token ) = @given{qw/ login token /};
    unless( defined $token && length $token ) {
        my %identity = Config::Identity::GitHub->load;
        ( $login, $token ) = @identity{qw/ login token /};
    }
    for ( $login, $token ) {
        unless ( defined $_ and length $_ ) {
            $self->log( 'Missing GitHub login and/or token' );
            return;
        }
    }

    my $uri = "https://github.com/api/v2/json/repos/show/$login/$repository";
    my $response = $agent->post( $uri,
        [ login => $login, token => $token, 'values[description]' => $description ] );

    unless ( $response->is_success ) {
        die $response->status_line, "\n",
            $response->decoded_content;
    }

    return $response;
}

sub release {
    my ( $self ) = @_;
    
    my $repository = $self->zilla->name;
    my $description = $self->zilla->abstract;

    eval {
        if ( my $response = $self->update( repository => $repository, description => $description ) ) {
            $self->log( "Updated github description:", $response->decoded_content );
        }
    };
    $self->log( "Unable to update github description: $@" ) if $@;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::UpdateGitHub - Update your github repository description from abstract on release

=head1 VERSION

version 0.0019

=head1 SYNOPSIS

In your L<Dist::Zilla> C<dist.ini>:

    [UpdateGitHub]

=head1 DESCRIPTION

Dist::Zilla::Plugin::UpdateGitHub will automatically update your github repository
description to be the same as your abstract on release

It will infer the repository name from the distribution name, and get your login/token from C<$HOME/.github> or C<$HOME/.github-identity>

=head1 FUTURE

More complicated repository inferring

Update homepage as well

=head1 SEE ALSO

L<App::GitHub::update>

L<Config::Identity>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

