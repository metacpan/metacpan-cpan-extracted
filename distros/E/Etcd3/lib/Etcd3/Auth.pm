use utf8;
package Etcd3::Auth;

use strict;
use warnings;

=encoding utf8

=cut

use Etcd3::Auth::Authenticate;
use Etcd3::Auth::Enable;
use Etcd3::Auth::Role;

=head1 NAME

Etcd3::Auth

=cut

our $VERSION = '0.006';

=head1 DESCRIPTION

Authentication

=cut

=head1 SYNOPSIS

    # enable auth
    $etcd->user_add

    # add user
    $etcd->user_add( { name => 'samba', password =>'P@$$' });

    # add role
    $etcd->role( { name => 'myrole' })->add;

    # grant role
    $etcd->user_role( { user => 'samba', role => 'myrole' })->grant;

=cut

1;
