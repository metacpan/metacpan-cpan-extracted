package Mail::Decency::Core::DatabaseCreate;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.4" );

=head1 NAME

Mail::Decency::Core::Meta::DatabaseCreate

=head1 DESCRIPTION

Prints SQL CREATE statements for module and server databases. Of course, only for DBD databases..

=head1 METHODS


=head2 print_sql

Print SQL "CREATE *" statements.

=cut

sub print_sql {
    my ( $self ) = @_;
    
    print "-- SQL START\n\n";
    
    foreach my $child( @{ $self->childs }, $self ) {
        next unless $child->can( 'schema_definition' );
        my $definition_ref = $child->schema_definition;
        print "-- For: $child\n";
        while( my ( $schema, $tables_ref ) = each %$definition_ref ) {
            while ( my ( $table, $columns_ref ) = each %$tables_ref ) {
                $child->database->setup( $schema => $table => $columns_ref, 0 );
                print "\n";
            }
        }
        print "\n";
    }
    
    print "\n-- SQL END\n";
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
