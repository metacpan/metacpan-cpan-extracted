package FreeRADIUS::Database::Storage::Result::Radacct;
use base qw/ DBIx::Class /;

__PACKAGE__->load_components( qw/Core/ );

__PACKAGE__->table( 'radacct' );

__PACKAGE__->add_columns( qw(
                    RadAcctId
                    AcctSessionId
                    AcctUniqueId
                    UserName
                    Realm
                    NASIPAddress
                    NASPortId
                    NASPortType
                    AcctStartTime
                    AcctStopTime
                    AcctSessionTime
                    AcctAuthentic
                    ConnectInfo_start
                    ConnectInfo_stop
                    AcctInputOctets
                    AcctOutputOctets
                    CalledStationId
                    CallingStationId
                    AcctTerminateCause
                    ServiceType
                    FramedProtocol
                    FramedIPAddress
                    AcctStartDelay
                    AcctStopDelay                    
                ));

__PACKAGE__->set_primary_key( qw/ RadAcctId / );
