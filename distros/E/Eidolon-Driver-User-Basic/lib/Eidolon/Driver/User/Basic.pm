package Eidolon::Driver::User::Basic;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/User/Basic.pm - basic user driver
#
# ==============================================================================

use base qw/Eidolon::Driver::User/;
use warnings;
use strict;

our $VERSION  = "0.02"; # 2009-04-06 02:04:33

# ------------------------------------------------------------------------------
# authorize($login)
# authorize user
# ------------------------------------------------------------------------------
sub authorize
{
    my ($self, $login, $r);

    ($self, $login) = @_;
    $r = Eidolon::Core::Registry->get_instance;

    $r->cgi->start_session;
    $r->cgi->set_session("login", $login);
    $r->cgi->set_session("ip",    $self->ip);

    __PACKAGE__->mk_accessors("login");
    $self->login( $login );
}

# ------------------------------------------------------------------------------
# unauthorize()
# unauthorize user
# ------------------------------------------------------------------------------
sub unauthorize
{
    my ($self, $r);

    $self = shift;
    $r    = Eidolon::Core::Reigstry->get_instance;

    $r->cgi->destroy_session;
    $self->login( undef );
}

# ------------------------------------------------------------------------------
# $ authorized()
# check if user is authorized
# ------------------------------------------------------------------------------
sub authorized
{
    my ($self, $r);

    $self = shift;
    $r    = Eidolon::Core::Registry->get_instance;

    return $r->cgi->get_session("login") && ($r->cgi->get_session("ip") eq $self->ip);
}

1;

__END__

=head1 NAME

Eidolon::Driver::User::Basic - Eidolon basic user driver.

=head1 SYNOPSIS

Login handler:

    my ($r, $user, $login, $pass);

    $r     = Eidolon::Core::Registry->get_instance;
    $user  = $r->loader->get_object("Eidolon::Driver::User::Basic");
    
    if (!$user->authorized)
    {
        $login = $r->cgi->post("login");
        $pass  = $r->cgi->post("password");

        # login & password validation
        # ...

        $user->authorize($login) if ($login_and_password_are_valid);
    }

Logout handler:

    my ($r, $user);

    $r    = Eidolon::Core::Registry->get_instance;
    $user = $r->loader->get_object("Eidolon::Driver::User::Basic");

    $user->unauthorize;

=head1 DESCRIPTION

The I<Eidolon::Driver::User::Basic> is a user driver for I<Eidolon>, that
provides simple session-based authorization.

=head1 METHODS

=head2 new()

Inherited from L<Eidolon::Driver::User/new()>.

=head2 authorize($login)

Implementation of abstract method from L<Eidolon::Driver::User/authorize($login)>.

=head2 unauthorize()

Implementation of abstract method from L<Eidolon::Driver::User/unauthorize()>.

=head2 authorized()

Implementation of abstract method from L<Eidolon::Driver::User/authorized()>.

=head1 ATTRIBUTES

The I<Eidolon::Driver::User::Basic> package adds one useful class 
attribute that is filled in during user authorization. See
L<Eidolon::Driver::User/ATTRIBUTES> for more information about using user driver 
class attributes.

=head2 agent

Inherited from L<Eidolon::Driver::User/agent>.

=head2 ip

Inherited from L<Eidolon::Driver::User/ip>.

=head2 language

Inherited from L<Eidolon::Driver::User/language>.

=head2 referer

Inherited from L<Eidolon::Driver::User/referer>.

=head2 login

User login. Contains information only if user was authorized before, I<undef>
otherwise.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::User>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
