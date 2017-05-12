package Foorum::Controller::Admin::BanIP;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Net::CIDR::Lite;

sub auto : Private {
    my ( $self, $c ) = @_;

    # only administrator is allowed. site moderator is not allowed here
    unless ( $c->model('Policy')->is_admin( $c, 'site' ) ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'admin/ban_ip/default.html';
    my @cidr_ips = $c->model('DBIC')->resultset('BannedIp')->search()->all;
    foreach (@cidr_ips) {
        my $cidr = Net::CIDR::Lite->new;
        $cidr->add( $_->cidr_ip );
        my @ip_ranges = $cidr->list_range;
        $_->{range} = join( ' | ', @ip_ranges );
    }
    $c->stash->{cidr_ips} = \@cidr_ips;

}

sub remove : Local {
    my ( $self, $c ) = @_;

    my $ip_id = $c->req->param('ip_id');
    return $c->res->redirect('/admin/banip?st=301') unless ($ip_id);

    my $st = $c->model('DBIC')->resultset('BannedIp')
        ->search( { ip_id => $ip_id, } )->delete;

    my $cache_key = 'global|banned_ip';
    $c->cache->reomove($cache_key);

    $c->res->redirect('/admin/banip?st=1');
}

sub add : Local {
    my ( $self, $c ) = @_;

    my $from_ip = $c->req->param('from_ip');
    my $end_ip  = $c->req->param('end_ip');
    return $c->res->redirect('/admin/banip?st=301')
        unless ( $from_ip and $end_ip );

    my $cidr = Net::CIDR::Lite->new;
    $cidr->add_range("$from_ip - $end_ip");
    my @cidr_list = $cidr->list;
    foreach my $cidr (@cidr_list) {
        $c->model('DBIC')->resultset('BannedIp')->create(
            {   cidr_ip => $cidr,
                time    => time(),
            }
        );
    }

    my $cache_key = 'global|banned_ip';
    $c->cache->remove($cache_key);

    return $c->res->redirect('/admin/banip?st=1');
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
