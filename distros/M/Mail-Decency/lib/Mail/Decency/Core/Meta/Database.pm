package Mail::Decency::Core::Meta::Database;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.4" );

=head1 NAME

Mail::Decency::Core::Meta::Tables

=head1 DESCRIPTION

Abstract base class for all modules requiring databases


=head1 CLASS ATTRIBUTES


=head1 METHODS


=head2 check_database

Checks database by pinging (connection check) and setting up tables (schema definition)

=cut

sub check_database {
    my ( $self, $definition_ref ) = @_;
    
    # check all tables in all schemas ..
    while( my ( $schema, $tables_ref ) = each %$definition_ref ) {
        while ( my ( $table, $columns_ref ) = each %$tables_ref ) {
            
            # ping database ..
            unless ( $self->database->ping( $schema => $table ) ) {
                
                # don't create, die with create syntax error
                return 0 unless $self->database->setup( $schema => $table => $columns_ref );
            }
        }
    }
    
    return 1;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
