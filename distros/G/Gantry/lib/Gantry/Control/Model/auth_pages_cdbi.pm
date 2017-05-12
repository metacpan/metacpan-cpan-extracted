package Gantry::Control::Model::auth_pages_cdbi;
use strict;

use base 'Gantry::Utils::AuthCDBI', 'Exporter';

our $AUTH_PAGES = 'Gantry::Control::Model::auth_pages_cdbi';
our @EXPORT_OK = ( '$AUTH_PAGES' );

__PACKAGE__->table('auth_pages');
__PACKAGE__->sequence('auth_pages_seq');
__PACKAGE__->columns( Primary => 'id' );
__PACKAGE__->columns( All => qw/id user_perm group_perm world_perm 
                                owner_id group_id uri title/ );
__PACKAGE__->columns( Essential => qw/id user_perm group_perm world_perm 
                                owner_id group_id uri title/ );
__PACKAGE__->has_a( group_id => 'Gantry::Control::Model::auth_groups_cdbi' );
__PACKAGE__->has_a( owner_id => 'Gantry::Control::Model::auth_users_cdbi' );

1;

__END__

=head1 NAME

Gantry::Control::Model::auth_pages - Model Component for the auth_pages table

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
