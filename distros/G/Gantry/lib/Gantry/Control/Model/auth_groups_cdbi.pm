package Gantry::Control::Model::auth_groups_cdbi;
use strict;

use base 'Gantry::Utils::AuthCDBI', 'Exporter';

our $AUTH_GROUPS = 'Gantry::Control::Model::auth_groups_cdbi';
our @EXPORT_OK = ( '$AUTH_GROUPS' );

__PACKAGE__->table('auth_groups');
__PACKAGE__->sequence('auth_groups_seq');
__PACKAGE__->columns( Primary => 'id' );
__PACKAGE__->columns( All => qw/id ident name description/ );
__PACKAGE__->columns( Essential => qw/id ident name description/ );

1;

__END__

=head1 NAME

Gantry::Control::Model::auth_groups- Model Component for the auth_groups table

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 SEE ALSO

Class::DBI(3), Class::DBI::Sweet(3), Gantry(3), Gantry::Control::Model(3)

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
