package Foorum::Action::PathLogger;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'Catalyst::Action';
use Time::HiRes qw( gettimeofday tv_interval );
use Data::Dumper;

use MRO::Compat;

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    $self->next::method(@_);

    my $loadtime = tv_interval( $c->stash->{start_t0}, [gettimeofday] );
    $self->log_path( $c, $loadtime );
}

sub log_path {
    my ( $self, $c, $loadtime ) = @_;

    # sometimes we won't logger path because it expandes the table too quickly
    return unless ( $c->config->{logger}->{path} );
    return if ( $c->stash->{donot_log_path} );

# but sometimes we want to know which url is causing more than $PATH_LOAD_TIME_MORE_THAN
    return
        if ( $loadtime < $c->config->{logger}->{path_load_time_more_than} );

    my $path = $c->req->path;
    $path = ($path) ? substr( $path, 0, 255 ) : 'forum';    # varchar(255)
    my $get = $c->req->uri->query;
    $get = substr( $get, 0, 255 ) if ($get);                # varchar(255)
    my $post = $c->req->body_parameters;
    $post
        = ( keys %$post )
        ? substr( Dumper($post), 0, 255 )
        : '';                                               # varchar(255)
    ($loadtime) = ( $loadtime =~ /^(\d{1,5}\.?\d{0,2})/ );  # float(5,2)
    my $session_id = $c->sessionid;
    my $user_id = ( $c->user_exists ) ? $c->user->user_id : 0;

    $c->model('DBIC::LogPath')->create(
        {   session_id => $session_id,
            user_id    => $user_id,
            path       => $path,
            get        => $get,
            post       => $post,
            time       => time(),
            loadtime   => $loadtime,
        }
    );
}

1;
__END__

=pod

=head1 NAME

Foorum::Action::PathLogger - Log every request into log_path table

=head1 SYNOPSIS

  sub end : ActionClass('+Foorum::Action::PathLogger') {

=head1 DESCRIPTION

log request.

=head1 SEE ALSO

L<Catalyst::Action>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
