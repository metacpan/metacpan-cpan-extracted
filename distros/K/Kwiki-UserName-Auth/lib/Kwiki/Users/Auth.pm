package Kwiki::Users::Auth;
use Kwiki::Users -Base;
our $VERSION = "0.02";

const class_id => 'users';
const class_title => 'Kwiki users registered online';
const user_class => 'Kwiki::User::Auth';

package Kwiki::User::Auth;
use base 'Kwiki::User';

field 'name';
field 'email';

sub set_user_name {
    return unless $self->is_in_cgi;
    my $users = $self->hub->session->load->param("users_auth");
    $users && $users->{name} or return;
    $self->name($self->utf8_decode($users->{name}));
    $self->email($self->utf8_decode($users->{email}));
}

package Kwiki::Users::Auth;

=head1 NAME

Kwiki::Users::Auth - Properl 'users_class' that works with Kwiki::UserName::Auth

=head1 DESCRIPTION

Please read the documentation in L<Kwiki::UserName::Auth>.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

