package FreeRADIUS::Database::Storage::Result::DailyAgg;
use base qw/ DBIx::Class /;

__PACKAGE__->load_components( qw/Core/ );

__PACKAGE__->table( 'aggregate_daily' );

__PACKAGE__->add_columns( qw(
                        TotAcctId
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

__PACKAGE__->set_primary_key( qw/ TotAcctId / );
