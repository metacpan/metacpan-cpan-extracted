package Foorum::Model::Log;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Model';
use Foorum::Logger qw/error_log/;

sub log_action {
    my ( $self, $c, $info ) = @_;

    my $user_id = $c->user_exists ? $c->user->user_id : 0;

    $c->model('DBIC::LogAction')->create(
        {   user_id     => $user_id,
            action      => $info->{action} || 'kiss',
            object_type => $info->{object_type} || 'ass',
            object_id   => $info->{object_id} || 0,         # times
            time        => time(),
            text        => $info->{text} || '',
            forum_id    => $info->{forum_id} || 0,
        }
    );
}

sub check_c_error {
    my ( $self, $c ) = @_;

    my @error = @{ $c->error };
    return 0 unless ( scalar @error );

    my $error = join( "\n", @error );

    error_log( $c->model('DBIC'), 'fatal', $error );

    $c->stash->{simple_wrapper} = 1;
    $c->stash->{error}          = { msg => $error };
    $c->stash->{template}       = 'simple/error.html';
    $c->error(0);

    return 1;
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
