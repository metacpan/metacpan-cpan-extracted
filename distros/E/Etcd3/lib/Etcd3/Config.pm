use utf8;
package Etcd3::Config;

use strict;
use warnings;

use Moo;
use namespace::clean;

=head1 NAME

Etcd3::Config

=cut

our $VERSION = '0.005';

=head2 etcd

=cut

has etcd => ( is => 'lazy' );

sub _build_etcd {
    my $self  = shift;
    my $found = `which etcd`;
    if ( $? == 0 ) {
        chomp($found);
        return $found;
    }
    return;
}

=head2 configuration

=cut

sub configuration {
    return Etcd3::Config->new;
}

=head2 configure

=cut

sub configure {
    my $class = shift;
    my $code  = shift;
    local $_ = $class->configuration;
    $code->($_);
    return;
}

1;
