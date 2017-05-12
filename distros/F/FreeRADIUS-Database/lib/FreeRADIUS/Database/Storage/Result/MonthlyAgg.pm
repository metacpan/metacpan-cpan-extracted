package FreeRADIUS::Database::Storage::Result::MonthlyAgg;
use base qw/ DBIx::Class /;

__PACKAGE__->load_components( qw/Core/ );

__PACKAGE__->table( 'aggregate_monthly' );

__PACKAGE__->add_columns( qw(
                        MTotAcctId
                        UserName
                        AcctDate
                        ConnNum
                        ConnTotDuration
                        ConnMaxDuration
                        ConnMinDuration
                        InputOctets
                        OutputOctets
                        NASIPAddress                
                    ));

__PACKAGE__->set_primary_key( qw/ MTotAcctId / );
