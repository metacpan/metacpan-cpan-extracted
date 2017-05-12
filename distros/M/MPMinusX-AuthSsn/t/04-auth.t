#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 04-auth.t 2 2013-08-07 09:50:14Z minus $
#
#########################################################################
use Test::More tests => 10;
use lib qw(inc);
use Test::MPMinus;
use MPMinusX::AuthSsn;
my $m = new Test::MPMinus
my $usid = undef;
my $ssn = new MPMinusX::AuthSsn($m, $usid);
is($ssn->authen( \&authen ), 0, "Access denied authen(LOGIN_INCORRECT): ".$ssn->reason());
is($ssn->authen( \&authen, 'foo' ), 0, "Access denied authen(PASSWORD_INCORRECT): ".$ssn->reason());
is($ssn->authen( \&authen, 'foo', 'hack' ), 0, "Access denied authen(AUTH_REQUIRED): ".$ssn->reason());
is($ssn->authen( \&authen, 'foo', 'bar' ), 1, "Grant access authen(OK): ".$ssn->reason());
is($ssn->get('login'), 'foo', "Login is foo");
is($ssn->authz( \&authz ), 0, "Access denied authz(FORBIDDEN): ".$ssn->reason());
$ssn->set(role  => 1);
is($ssn->authz( \&authz ), 1, "Grant access authz(OK/NEW): ".$ssn->reason());
$usid = $ssn->sid;
ok($usid ? 1 : 0, "USID generated");
is($ssn->access( \&access ), 1, "Grant access access(OK): ".$ssn->reason());
is($ssn->access( \&access, 'anonymous' ), 0, "Access denied access(FORBIDDEN): ".$ssn->reason());

sub authen {
    my $self = shift;
    my $login = shift || '';
    my $password = shift || '';

    return $self->status(0, 'LOGIN_INCORRECT') unless $login;
    return $self->status(0, 'PASSWORD_INCORRECT') unless $password;
    return $self->status(0, 'AUTH_REQUIRED') unless ($login eq 'foo') && ($password eq 'bar');

    $self->set(login => $login);
    $self->set(role  => 0);
    return 1;

}
sub authz {
    my $self = shift;
    my $role = $self->get('role') || 0;
    return $self->status(0, 'FORBIDDEN') unless $role;

    return 1;
}
sub access {
    my $self = shift;
    my $login = shift || $self->get('login') || 'anonymous';
    return $self->status(0, 'FORBIDDEN') if $login eq 'anonymous';
    return 1;
}

1;
