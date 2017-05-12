package Dist::Zilla::Plugin::UploadToStratopan;

our $VERSION = 0.012;

use Moose;
use Mojo::UserAgent;
use Mojo::DOM;

with 'Dist::Zilla::Role::Releaser';

# ABSTRACT: Automate Stratopan releases with Dist::Zilla

has agent         => ( is           => 'ro',
                       isa          => 'Str',
                       default      => 'stratopan-uploader/' . $VERSION );

has repo          => ( is           => 'ro',
                       isa          => 'Str',
                       required     => 1 );

has stack         => ( is           => 'ro',
                       isa          => 'Str',
                       default      => 'master',
                       required     => 1 );

has _strato_base  => ( is           => 'ro',
                       isa          => 'Str',
                       default      => 'https://stratopan.com' );

has _ua           => ( is           => 'ro',
                       isa          => 'Mojo::UserAgent',
                       lazy_build   => 1 );

has _username     => ( is           => 'ro',
                       isa          => 'Str',
                       lazy_build   => 1 );

has _password     => ( is           => 'ro',
                       isa          => 'Str',
                       lazy_build   => 1 );


sub _build__username {
    my $self = shift;

    return $self->zilla->chrome->prompt_str( "Stratopan username: " );
}

sub _build__password {
    my $self = shift;
    return $self->zilla->chrome->prompt_str(
               "Stratopan password: ", { noecho => 1 }
           );
}

sub _build__ua {
    my $self = shift;

    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name( $self->agent );
    return $ua;
}

sub release {
    my ( $self, $tarball ) = @_;

    $tarball = "$tarball";    # stringify object

    my $ua = $self->_ua;
    my $tx = $ua->post( $self->_strato_base . '/signin',
                        form => {
                          login    => $self->_username,
                          password => $self->_password
                       } );

    if ( my $error = $tx->res->dom->find( 'div#page-alert p' ) ) {
        $self->log_fatal( $error->all_text );
    }

    my $submit_url = sprintf '%s/%s/%s/%s/stack/add',
        $self->_strato_base, $self->_username, $self->repo, $self->stack;

    $self->log( [ "uploading %s to %s", $tarball, $submit_url ] );

    $tx = $ua->post( $submit_url,
        form => {
            recurse    => 1,
            archive    => { file => $tarball }
        }
    );

    if ( $tx->res->code == 302 ) {
        return $self->log( "success." );
    }

    $self->log_fatal( $tx->res->dom->find( 'div#page-alert p' )->all_text );
}


1;


__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::UploadToStratopan - Automate Stratopan releases with Dist::Zilla

=head1 SYNOPSIS

In your C<dist.ini>:

    [UploadToStratopan]
    repo  = myrepo
    stack = master

=head1 DESCRIPTION

This is a Dist::Zilla releaser plugin which will automatically upload your
completed build tarball to Stratopan.

The module will prompt you for your Stratopan username (NOT email) and password.

Currently, it works by posting the file to Stratopan's "Add" form; when the
Stratopan REST API becomes available, this module will be updated to use it
instead.

=head1 ATTRIBUTES

=head2 agent

The HTTP user agent string to use when talking to Stratopan. The default
is C<stratopan-uploader/$VERSION>.

=head2 repo

The name of the Stratopan repository. Required.

=head2 stack

The name of the stack within your repository to which you want to upload. The
default is C<master>.

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mike Friedman

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
