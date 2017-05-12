#
# This file is part of Jedi-Plugin-Auth
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Auth::DB::Result::UsersRoles;

# ABSTRACT: ResultSet for UsersRoles table

use strict;
use warnings;
our $VERSION = '0.01';    # VERSION

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('jedi_auth_users_roles');
__PACKAGE__->add_column( user_id => { data_type => 'integer' } );
__PACKAGE__->add_column( role_id => { data_type => 'integer' } );
__PACKAGE__->set_primary_key( __PACKAGE__->columns );

__PACKAGE__->belongs_to(
    role => 'Jedi::Plugin::Auth::DB::Result::Role',
    'role_id'
);
__PACKAGE__->belongs_to(
    user => 'Jedi::Plugin::Auth::DB::Result::User',
    'user_id'
);
1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Auth::DB::Result::UsersRoles - ResultSet for UsersRoles table

=head1 VERSION

version 0.01

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-auth/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
