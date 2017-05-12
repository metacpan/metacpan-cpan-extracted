package TestModule;

use strict;
use FindBin qw/ $Bin /;

sub setup_database {
    my ( $module ) = @_;
    my $definition_ref = $module->schema_definition;
    while( my ( $schema, $tables_ref ) = each %$definition_ref ) {
        while ( my ( $table, $columns_ref ) = each %$tables_ref ) {
            $module->database->setup( $schema => $table => $columns_ref, 1 );
        }
    }
}

1;
