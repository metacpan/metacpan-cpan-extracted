#
# This file is part of Jedi-Plugin-Auth
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Auth::DB::Result::User;

# ABSTRACT: ResultSet for User table

use strict;
use warnings;
our $VERSION = '0.01';    # VERSION

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('jedi_auth_users');
__PACKAGE__->add_column( id => { data_type => 'integer' } );
__PACKAGE__->add_columns(qw/user password uuid info/);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( uniq_user => [qw/user/], );

__PACKAGE__->add_unique_constraint( uuid => [qw/uuid/], );

__PACKAGE__->has_many(
    user_roles => 'Jedi::Plugin::Auth::DB::Result::UsersRoles',
    'user_id'
);
__PACKAGE__->many_to_many( roles => 'user_roles' => 'role' );

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Auth::DB::Result::User - ResultSet for User table

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
