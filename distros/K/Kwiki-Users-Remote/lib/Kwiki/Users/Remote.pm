package Kwiki::Users::Remote;
use strict;
use warnings;

use Kwiki::Users -Base;

our $VERSION = "0.04";

const class_title => 'Kwiki users from HTTP authentication';
const user_class  => 'Kwiki::User::Remote';

package Kwiki::User::Remote;
use base 'Kwiki::User';

sub name {
    exists $ENV{REMOTE_USER}
        ? $ENV{REMOTE_USER}
        : $self->hub->config->user_default_name;
}

sub id {
    exists $ENV{REMOTE_USER}
        ? $ENV{REMOTE_USER}
        : $self->hub->config->user_default_name;
}

__DATA__

=head1 NAME 

Kwiki::Users::Remote - automatically set Kwiki user name from HTTP authentication

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ echo "users_class: Kwiki::Users::Remote" >> config.yaml

In your Apache configuration:

    <Location /kwiki>
        AuthName     "my kwiki"
        AuthType     Basic
        AuthUserFile /path/to/htpasswd
        Require      valid-user
    </Location>

Optionally, to display the user name:

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::UserName::Remote

=head1 DESCRIPTION

When using HTTP authentication for your Kwiki, use this module to automatically
set the user's name from the username they logged in with. This name will
appear in any Recent Changes listing.

You might also want to use L<Kwiki::UserName::Remote>.

=head1 ACKNOWLEDGEMENTS

Gerald Richter submitted a patch so that username changes would be recognized
under mod_perl

=head1 AUTHORS

Ian Langworth <langworth.com> 

=head1 SEE ALSO

L<Kwiki>, L<Kwiki::UserName::Remote>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, 2005 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

