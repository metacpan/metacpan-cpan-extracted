package FreeRADIUS::Database::Storage::Result::Radcheck;
use base qw/ DBIx::Class /;

__PACKAGE__->load_components( qw/Core/ );

__PACKAGE__->table( 'radcheck' );

__PACKAGE__->add_columns( qw(
                        id
                        UserName
                        Attribute
                        op
                        Value
                ));

__PACKAGE__->set_primary_key( qw/ id / );
