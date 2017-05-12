package Gantry::Control::Model::auth_users_cdbi;
use strict;

use base 'Gantry::Utils::AuthCDBI', 'Exporter';

our $AUTH_USERS = 'Gantry::Control::Model::auth_users_cdbi';
our @EXPORT_OK = ( '$AUTH_USERS' );

__PACKAGE__->table( 'auth_users' );
__PACKAGE__->sequence( 'auth_users_seq' );
__PACKAGE__->columns( Primary => 'user_id' );
__PACKAGE__->columns( All => 
        qw/user_id active user_name passwd crypt first_name 
        last_name email/ );
__PACKAGE__->columns( Essential => 
        qw/user_id active user_name passwd crypt first_name 
        last_name email/ );
__PACKAGE__->has_many( groups => 'Gantry::Control::Model::auth_group_members_cdbi' );

1;

__END__

=head1 NAME

Gantry::Control::Model::auth_users - Model Component for auth_users Control table

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 SEE ALSO

Class::DBI(3), Class::DBI::Sweet(3), Gantry(3), Gantry::Control::Model(3)

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
