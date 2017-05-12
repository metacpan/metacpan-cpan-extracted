package Foorum::Model::UserAuth;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Model';

sub auth {
    my ( $self, $c, $userinfo ) = @_;

    my $where;
    if ( exists $userinfo->{user_id} ) {
        $where = { user_id => $userinfo->{user_id} };
    } elsif ( exists $userinfo->{username} ) {
        $where = { username => $userinfo->{username} };
    } elsif ( exists $userinfo->{email} ) {
        $where = { email => $userinfo->{email} };
    } else {
        return;
    }

    my $user = $c->model('DBIC::User')->get($where);
    return $user;
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
