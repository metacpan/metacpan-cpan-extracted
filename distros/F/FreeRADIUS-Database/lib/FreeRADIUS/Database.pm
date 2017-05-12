package FreeRADIUS::Database;

use strict;
use warnings;

use Carp;
$Carp::Verbose = 1;

use Config::Tiny;
use DBIx::Class;

our $VERSION = '0.06';

# initialization

sub new {

    my $class   = shift;
    my $params  = shift;

    my $conf_file = $params->{ config };

    my $self    = {};

    bless $self, $class;

    my $config_ok;

    if ( $conf_file ) {
        $config_ok = $self->_configure({ config => $conf_file });
    }
    else {
        $config_ok = $self->_configure();
    }

    return if ! $config_ok;

    return $self;
}
sub _configure {

    my $self    = shift;
    my $params  = shift;

    # configuration file bootstrap
    
    my @locations = qw( env param default );
    
    my $conf_file;
    
    if ( exists $ENV{'FREERADIUS_DATABASE_CONFIG'} ) {
        $conf_file = $ENV{'FREERADIUS_DATABASE_CONFIG'};
    }
    elsif ( exists $params->{ config } ) {
        $conf_file = $params->{ config };
    }
    else {
        $conf_file = '/usr/local/etc/freeradius_database.conf';
    }
    
    if ( ! $conf_file || ! -e $conf_file ) {
        return 0;
    }

    my $config  = Config::Tiny->read( $conf_file );
    
    for my $section ( keys %$config ) {
    
        # handle the RASs manually, and set up the 
        # MySQL regexes by hand

        if ( $section eq 'RAS' ) {

            next if defined &RAS;

            {
                my $ras_href;

                while ( my( $ras, $ips ) = ( each %{ $config->{ $section } } )) {

                    $ips    =~ s/\s+//g;
                    $ips    =~ s/,/|/g;

                    $ras_href->{ $ras } = $ips;
                }

                no strict 'refs';

                *RAS = sub {
                    return $ras_href;
                }
            }       
        }           

        # do the 'easy-to-automate' config members

        while ( my ( $member, $value ) = ( each %{ $config->{ $section }  } ) ) {

            $member = uc $member;
            
            $self->{ config }{ $member } = $value;

            no strict 'refs';

            *$member = sub {
                my $self    = shift;
                $self->{ config }{ $member } = shift if @_;
                return $self->{ config }{ $member };
                
            } if ! defined &$member;
        }
    }

    return $self;
}

# accounting

sub aggregate_daily {

    my $self    = shift;
    my $params  = shift if @_;

    my $classify_ras = $self->RAS_CLASSIFICATION();

    # check to see if the operator wants to override the 
    # config variable

    $classify_ras = $params->{ classify } if exists $params->{ classify };

    if ( exists $params->{ day } && $params->{ day } !~ m{ \A \d{4}-\d{2}-\d{2} \z }xms ) {
        croak "The 'day' param must be in the form YYYY-MM-DD: $!";
    }

    my $day = $params->{ day };

    if ( ! $day ) {
        my $datetime = $self->date();
        $datetime->subtract( days   => 1 );
        $day = $datetime->ymd();
    }

    my $schema = $self->_schema();

    # UPDATE

    if ( $classify_ras ) {
    
        $self->update_ras_name( {
                        day => $day,
                    } );    
    }

    # DELETE if this is an overlay run  

    $schema->resultset( 'DailyAgg' )->search({ acctdate => $day })->delete();

    # FETCH

    my $daily_fetch_rs = $schema->resultset( 'Radacct' )->search(
    
            { 
                'acctstoptime' => { like => "$day%" },      
            },{
        
            select => [
                'username',
                { count => 'radacctid' },
                { sum   => 'acctsessiontime' },
                { max   => 'acctsessiontime' },
                { min   => 'acctsessiontime' },
                { sum   => 'acctinputoctets' },
                { sum   => 'acctoutputoctets' },
                'nasipaddress',
            ],

            group_by => [ qw/ username nasipaddress / ],

            as       => [ qw/   
                                UserName
                                ConnNum
                                ConnTotDuration
                                ConnMaxDuration
                                ConnMinDuration
                                InputOctets 
                                OutputOctets
                                NASIPAddress
                            /,
                        ],
        });

    $daily_fetch_rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    
    my $agg_table = $schema->resultset( 'DailyAgg' );

    while ( my $daily_entry = $daily_fetch_rs->next() ) {
        
        $daily_entry->{ AcctDate } = $day;
        $agg_table->create( $daily_entry );
    }

    return 0;
}
sub aggregate_monthly {

    my $self    = shift;
    my $params  = shift;

    my $month;

    if ( $params->{ month } ) {
        $month = $params->{ month };
        if ( $month !~ m{ \A \d{4}-\d{2} \z }xms ){
            croak "The 'month' param must be in the form YYYY-MM: $!";
        }
    }
    else {
        my $datetime = $self->date();
        $datetime->subtract( days => 1 );
        $month = $self->date( { get => 'month', datetime => $datetime } );
    }

    my $schema = $self->_schema();

    # DELETE if overlay run

    $schema->resultset( 'MonthlyAgg' )->search({ 
                                            acctdate => { like => "$month%" }, 
                                        })->delete();

    my $month_rs = $schema->resultset( 'DailyAgg' )->search(
                    
                    {
                        'AcctDate' => { like => "$month%" },
                    },
                    {
                        select => [
                                    'UserName',
                                    { sum   => 'ConnNum' },
                                    { sum   => 'ConnTotDuration' },
                                    { max   => 'ConnMaxDuration' },
                                    { min   => 'ConnMinDuration' },
                                    { sum   => 'InputOctets' },
                                    { sum   => 'OutputOctets' },
                                    'NASIPAddress',
                        ],

                        group_by => [ qw/ UserName NASIPAddress / ],

                        as       => [ qw/
                                        UserName
                                        ConnNum
                                        ConnTotDuration
                                        ConnMaxDuration
                                        ConnMinDuration
                                        InputOctets
                                        OutputOctets
                                        NASIPAddress
                                        /,
                                    ],
                    }
            );

    $month_rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

    my $agg_table = $schema->resultset( 'MonthlyAgg' );

    while ( my $month_entry = $month_rs->next() ) {

        $month_entry->{ AcctDate } = $month . "-00";
        $agg_table->create( $month_entry );
    }

    return 0;
}

# archiving & management

sub archive_radacct {

    my $self    = shift;
    my $params  = shift;

    my $month;

    if ( $params->{ month } ) {
        $month = $params->{ month };
    }
    else {
        my $datetime = $self->date();
        $datetime->subtract( months => $self->MONTHS_AFTER_ARCHIVE() );
        $month = $self->date( { get => 'month', datetime => $datetime } );
    }

    my $dbh = $self->_db_handle();

    my $archive_table_name = "radacct_${ month }";
    $archive_table_name =~ s/-//;

    my $table_ok = $self->_create_archive_table( { 
                                    tablename => $archive_table_name 
                                } );
    
    if ( $table_ok ) {

        my $archive_query = $dbh->prepare("
            INSERT INTO $archive_table_name
            SELECT * FROM radacct
            WHERE AcctStopTime LIKE '$month%'
        ") or die $DBI::errstr;

        $archive_query->execute();
    }
    else {
        die "Could not create the archive DB table!: $!";
    }

    # delete, if necessary

    if ( $self->DELETE_AFTER_ARCHIVE() ) {

        my $delete_query = $dbh->prepare("
            DELETE FROM radacct
            WHERE AcctStopTime LIKE '$month%'
        ") or die $DBI::errstr;
    }

    return 0;
}

# statistics

sub daily_login_totals {

    use DateTime::Format::Strptime;

    my $self        = shift;
    my $params      = shift;

    my $username    = $params->{ username };
    my $nas         = $params->{ nas };
    my $day         = $params->{ day };
    my $raw         = $params->{ raw };

    my $schema = $self->_schema();

    my $day_total_rs = $schema->resultset( 'DailyAgg' )->search(
                                    {
                                        'username'      => $username,
                                        'acctdate'      => $day,
                                        'nasipaddress'  => $nas,
                                    },
                                    {
                                        select  => [ qw /
                                                        ConnTotDuration
                                                        InputOctets
                                                        OutputOctets
                                                        AcctDate
                                                        /,
                                                    ],
                                        
                                        as      => [ qw /
                                                        duration
                                                        upload
                                                        download
                                                        date
                                                        /,
                                                    ],  
    
                                    });

    # return undef if no rows found

    return if ! $day_total_rs->count();

    # extract only the hash of data

    $day_total_rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

    my $total = $day_total_rs->first();

    if ( ! $raw ) {
        
        $total->{ upload }      
            = $self->bytes_to_megabytes( $total->{ upload } );
        
        $total->{ download }    
            = $self->bytes_to_megabytes( $total->{ download } );
        
        $total->{ duration }    
            = $self->seconds_to_hours( $total->{ duration } );
    }

    return $total;
}
sub monthly_login_totals {

    use DateTime::Format::Strptime;

    my $self        = shift;
    my $params      = shift;

    my $username    = $params->{ username };
    my $nas         = $params->{ nas };         # ip, name or class
    my $month       = $params->{ month };       # YYYY-MM
    my $raw         = $params->{ raw };

    my $num_months  = ( $params->{ num_months } )
        ? $params->{ num_months }
        : 11;

    # return undef if num_months is bad

    if ( ! ( $num_months < 36 ) ) {
        return;
    }

    $month = ( $month )
        ? $month
        : '';

    my $schema = $self->_schema();

    my $month_total_rs = $schema->resultset( 'MonthlyAgg' )->search(
                                    {
                                        UserName    => $username,
                                        AcctDate    => { like => "$month%" },
                                        NASIPAddress => $nas,
                                    },
                                    {

                                    select  => [ qw/
                                                ConnTotDuration
                                                AcctDate
                                                InputOctets
                                                OutputOctets
                                                /,
                                            ],
                                    
                                    { order_by => 'AcctDate' },
                                    
                                    { limit     => $num_months },

                                    as  => [ qw/
                                                duration
                                                date
                                                upload
                                                download
                                            /,
                                        ],

                            });

    # return undef if nothing was found

    return if ! $month_total_rs->count();

    $month_total_rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

    my $month_totals_aref;

    while ( my $month_history = $month_total_rs->next() ) {

        if ( ! $raw ) {
        
        $month_history->{ upload } = ( $month_history->{ upload } > 1000000000 )
            ? $self->bytes_to_gigabytes( $month_history->{ upload } )   
            : $self->bytes_to_megabytes( $month_history->{ upload } );

        $month_history->{ download } = ( $month_history->{ download } > 1000000000 ) 
            ? $self->bytes_to_gigabytes( $month_history->{ download } ) 
            : $self->bytes_to_megabytes( $month_history->{ download } );

        $month_history->{ duration } 
            = $self->seconds_to_hours( $month_history->{ duration } )   
    
        }
            
        # convert to humanized date

        my $date_format = DateTime::Format::Strptime->new(
                                                    pattern => '%y-%m-00',
                                                );
        my $datetime    
            = $date_format->parse_datetime( $month_history->{ date } );
        
        my $human_date  
            = $datetime->month_abbr() . " " . $datetime->year();

        push ( @{ $month_totals_aref },  $month_history );
    }

    return $month_totals_aref;
}
sub month_hours_used {

    my $self    = shift;
    my $params  = shift;

    my $username = $params->{ username };

    my $nas = ( $params->{ nas } )
        ? $params->{ nas }
        : 'dialup';

    my $month;

    if ( exists $params->{ month } ) {
        $month = $params->{ month };
        $month .= '-00';
    }
    else {
        my $datetime = $self->date();
        $month = $self->date({ get => 'month', datetime => $datetime });
        $month .= '-00';
    }

    my $schema  = $self->_schema();

    my $rs = $schema->resultset( 'MonthlyAgg' )->find({
                    username        => $username,
                    nasipaddress    => $nas,
                    acctdate        => $month ,
                });

    return if ! $rs;

    my $hours_used = $rs->ConnTotDuration();

    if ( $hours_used ) {
        $hours_used = ( $hours_used / 60 / 60 );
        $hours_used = sprintf ( '%.2f', $hours_used );
    }

    return $hours_used;
}

# common methods

sub date {

    use DateTime;

    my $self    = shift;
    my $params  = shift if @_;

    if ( exists $params->{ get } && $params->{ get } !~ m{ \A (day|month|year) \z }xms ) {
    
        croak "\n\nThe get parameter must be one of 'day', 'month' or 'year': $!";
    }

    my $get_what = ( $params->{ get } )
        ? $params->{ get }
        : '';

    my $datetime;

    if ( $params->{ datetime } ) {
        $datetime = $params->{ datetime };
    }
    else {
        $datetime = DateTime->now( time_zone => $self->TIMEZONE() );
    }

    if ( $get_what eq 'day' ) {
        return $datetime->ymd();
    }
    
    if ( $get_what eq 'month' ) {

        my $month = $datetime->month();
        
        if ( length( $month ) == 1 ) {
            $month = 0 . $month;
        }

        my $date =  $datetime->year() . "-" . $month;  

        return $date;
    }

    if ( $get_what eq 'year' ) {
        my $date =  $datetime->year();

        return $date;
    }

    return ( DateTime->now( time_zone => $self->TIMEZONE()) );
}
sub password {

    my $self    = shift;
    my $params  = shift;

    my $username    = $params->{ username };
    my $new_pw      = $params->{ password };

    my $schema  = $self->_schema();

    my $rs      = $schema->resultset( 'Radcheck' )->find({ UserName => $username });

    return if ! $rs;

    my $orig_pw = $rs->Value();

    return $orig_pw if ! $new_pw;

    if ( $new_pw ) {

        $rs->Value( $new_pw );
        $rs->update();

    }
    
    return $self->password({ username => $username });
}

# NAS 

sub update_ras_name {

    my $self    = shift;
    my $params  = shift;

    my $day     = $params->{ day };
    
    my $ras_href = $self->RAS();

    my @classified_ras;

    my $schema = $self->_schema();

    while ( my( $ras_class, $ras_regex ) = ( each %$ras_href ) ) {
   
        my @ras_ips;

        if ( $ras_regex =~ /|/ ) {
            @ras_ips = split ( /\|/, $ras_regex );
        }
        else {
            push @ras_ips, $ras_regex;
        }
    
        for my $ras_to_classify ( @ras_ips ) {
    
            my $rs = $schema->resultset( 'Radacct' )->search({  
                                
                                'AcctStopTime' => { like => "$day%" },
                                'NASIPAddress' => { like => "$ras_to_classify%" },
                            
                            });

            $rs->update({ NASIPAddress => $ras_class });
        }
    }

    return 0;
}

# mathematical functions

sub seconds_to_hours {

    my $self    = shift;
    my $seconds = shift;

    my $hours   = sprintf ( '%.2f', ( ($seconds / 60) / 60 ) );
    return $hours;
}
sub bytes_to_megabytes {

    my $self    = shift;
    my $bytes   = shift;

    my $mb      = sprintf ( '%.2f', ( ($bytes / 1024) / 1024 ) );
    return $mb;
}
sub bytes_to_gigabytes {

    my $self    = shift;
    my $bytes   = shift;

    my $gb      = sprintf ( '%.2f', ( ($bytes / 1024) / 1024 /1024 ) );
    return $gb;
}

# internal methods

sub _create_archive_table {

    my $self    = shift;
    my $params  = shift;

    my $archive_table = $params->{ tablename };
    
    my $dbh = $self->_db_handle();

    $dbh->do ("

    CREATE TABLE if not exists `$archive_table` (
    `RadAcctId` bigint(21) NOT NULL auto_increment,
    `AcctSessionId` varchar(32) NOT NULL default '',
    `AcctUniqueId` varchar(32) NOT NULL default '',
    `UserName` varchar(64) NOT NULL default '',
    `Realm` varchar(64) default '',
    `NASIPAddress` varchar(15) NOT NULL default '',
    `NASPortId` int(12) default NULL,
    `NASPortType` varchar(32) default NULL,
    `AcctStartTime` datetime NOT NULL default '0000-00-00 00:00:00',
    `AcctStopTime` datetime NOT NULL default '0000-00-00 00:00:00',
    `AcctSessionTime` int(12) default NULL,
    `AcctAuthentic` varchar(32) default NULL,
    `ConnectInfo_start` varchar(32) default NULL,
    `ConnectInfo_stop` varchar(32) default NULL,
    `AcctInputOctets` bigint(20) unsigned default NULL,
    `AcctOutputOctets` bigint(20) unsigned default NULL,
    `CalledStationId` varchar(50) NOT NULL default '',
    `CallingStationId` varchar(50) NOT NULL default '',
    `AcctTerminateCause` varchar(32) NOT NULL default '',
    `ServiceType` varchar(32) default NULL,
    `FramedProtocol` varchar(32) default NULL,
    `FramedIPAddress` varchar(15) NOT NULL default '',
    `AcctStartDelay` int(12) default NULL,
    `AcctStopDelay` int(12) default NULL,
    PRIMARY KEY  (`RadAcctId`),
    KEY `UserName` (`UserName`),
    KEY `FramedIPAddress` (`FramedIPAddress`),
    KEY `AcctSessionId` (`AcctSessionId`),
    KEY `AcctUniqueId` (`AcctUniqueId`),
    KEY `AcctStartTime` (`AcctStartTime`),
    KEY `AcctStopTime` (`AcctStopTime`),
    KEY `NASIPAddress` (`NASIPAddress`)

    )TYPE=MyISAM;");

    return 1;
}
sub _schema {

    use FreeRADIUS::Database::Storage;
    use FreeRADIUS::Database::Storage::Replicated;

    my $self    = shift;
    my $params  = shift;

    my $database_servers = $self->_database_config();

    my $master  = shift @{ $database_servers };

    if ( ! $self->IN_TEST_MODE() && $self->ENABLE_REPLICATION() ) {

        my $schema = FreeRADIUS::Database::Storage::Replicated->connect( @{ $master } );

        $schema->storage->connect_replicants( @{ $database_servers } );

        return $schema;
    }

    my $schema
        = FreeRADIUS::Database::Storage->connect( @{ $master } );

    return $schema;
}
sub _database_config {

    my $self    = shift;
    my $params  = shift;

    my $database_servers; # aref

    # configure the test server if required

    if ( $self->IN_TEST_MODE() ){

        push( @$database_servers, [
                                $self->TEST_MODE_SOURCE(),
                            ]);

        return $database_servers;
    }

    # configure the master

    push( @$database_servers, [
                                $self->MASTER_SOURCE(),
                                $self->MASTER_USER(),
                                $self->MASTER_PASS(),
                            ]);

    # ...and add any slaves

    if ( $self->ENABLE_REPLICATION() && $self->SLAVE_SERVERS() ){
        
        for my $slave_number ( 1 .. $self->SLAVE_SERVERS() ){
            
            my $slave_info = "SLAVE_${ slave_number }_";

            my $slave; # aref

            for my $item ( qw/ SOURCE USER PASS / ){
                    
                my $function = $slave_info . $item;
                
                push @$slave, $self->$function();
            }       
                
            push @$database_servers, $slave;
        }
    }

    # if the master is locked for maintenance, shift it off
    # the stack

    if ( $self->MASTER_LOCKED() ) {
        
        shift @$database_servers;
    }

    return $database_servers;
}
sub _nothing {0;} # POD


1;

__END__

=head1 NAME

FreeRADIUS::Database - RADIUS user, client and database manager. 

=head1 SYNOPSIS

  use FreeRADIUS::Database;

  # create a new object, using the default configuration file

  my $radius = FreeRADIUS::Database->new();

  # create a new object, with an alternate config file

  my $radius = FreeRADIUS::Database->new({ config => '/path/to/config.file' });
 
  # aggregate yesterday's radacct data

  $radius->aggregate_daily();

  # aggregate a specific day of radacct data

  $radius->aggregate_daily({ day => '2009-06-12' });

  # aggregate radacct table by month (operates on month that was yesterday)

  $radius->aggregate_monthly();

  # aggregate monthly for a specific month

  $radius->aggregate_monthly({ month => '2009-06' });

  # rewrite the NAS IP Addresses in the radacct table into their named class
  # without doing aggregation

  $radius->update_ras_name({ day => '2009-06-01' });

  # get a users daily aggregated totals

  my $href = $radius->daily_login_totals({ 
                                username => 'un',
                                nas      => 'nasipaddress',
                                day      => 'YYYY-MM-DD',
                            });
    
  # get a users monthly aggregated bandwidth/time totals

  my $aoh = $radius->monthly_login_totals({
                                username    => 'un',
                                nas         => 'nasipaddress',
                                month       => 'YY-MM',
                                num_months  => 12, # default 11, max 36
                            });

  # get a user's hours used (month)

  my $float = $radius->month_hours_used({
                                username    => 'un',
                                nas         => 'nasipaddress',  # defaults to 'dialup'
                                month       => 'YYYY-MM',       # defaults to today's month
                            });


=head1 DESCRIPTION

This module contains methods to manage numerous aspects of a RADIUS database. 

It aids in user and password management, producing statistics, and provides
maintenance and mangement control of the backend MySQL database.

=head1 METHODS




=head2 new({ config => FILE })

Instantiates a new FreeRADIUS::Database object. 

The default configuration file can be overridden in two ways. The first is sending
in a 'config' parameter with the alternate configuration file name. This
parameter must be supplied within a hash reference.

You can also override the default configuration file location by setting 
the FREERADIUS_DATABASE_CONFIG environment variable prior to making the call to new().

If a configuration file can not be found or read, or the object can not be created,
the return will be undef.




=head2 aggregate_daily ( { day => DAY } )

This method is for the daily RADIUS database maintenance.

It's standard order of operation is as follows:

- update the names of the NASs in the radacct table in the RADIUS database,
  if ras_classification is set in the configuration file**
- clears out any existing data in the aggregate_daily table for the day
  being worked on (in the event multiple runs in a single day are performed)
- aggregates the daily RADIUS accounting from radacct table, and writes
  it into the aggregate_daily table

** this variable can be overridden if the named parameter 'classify' is passed in.

If the optional parameter day is specified, the method will run for that day. The
day parameter is a DateTime object, after being called as such: $datetime->ymd().

If the day parameter is not passed in, the working day will be set to yesterday.

Returns 0 upon completion/success.




=head2 aggregate_monthly ( { month => $month } )

This method aggregates the daily totals into monthly aggregates into the
'aggregate_monthly' database table.

If supplied, the 'month' parameter will be used as the month to operate on.
The month must be specified as such: YYYY-MM-DD.

Returns 0 upon success.




=head2 archive_radacct( { month => $month } )

Copies the data for the month specified in the 'month' parameter from
the 'radacct' table into a newly created archive table 'radacct_YYYY-MM'.
Note that the 'month' parameter must be supplied as YYYY-MM.

If the 'month' parameter is not specified, the method will work three months
previous to the current one by default. Change the configuration file directive
'months_after_archive' to override this default.

Returns 0 upon completion.



=head2 daily_login_totals ({ NAME => VALUE })

Retrieves the login totals for a user on a particular NAS or NAS class on a
particular day. It is particularly handy if you are classifying NASs.

The parameters are passed in within a hash reference:

    username    => STRING
    nas         => STRING
    date        => 'YYYY-MM-DD'
    raw         => BOOL # optional

The first three are mandatory. The 'raw' parameter is optional. If
present and set to true, upload and download will be multiplied into
MB/GB, and duration will be multiplied into hours, instead of bytes, bytes
and seconds respectively.

If no data is found, the return is undef. Otherwise, returns a hash
reference with 'date', 'upload', 'download', and 'duration' as it's
keys.




=head2 monthly_login_totals ( { NAME => VALUE } )

This method retrieves the monthly aggregate login times/bandwidth used for
a particular user. It is designed in such a way that 'update_ras_name()' must
be being used.

The parameters are passed in as a hash reference:

    username    => STRING
    nas         => STRING
    month       => YYYY-MM  # optional
    num_months  => INTEGER  # optional

The username parameter is mandatory. The 'nas' is a string that consists of
one of the 'RAS classifications' specified in the configuration file, a NAS
IP address, or a NAS name.

The 'num_months' parameter is optional, and must be an integer between 1 and 36. if
this parameter is absent, the default will be 11. This parameter is negated by the 
'month' parameter. If 'num_months' is out of range, 'undef' will be returned.

If 'month' is passed in, it must be in the form YYYY-MM. This will do a lookup for
that single month only.

Returns an array reference of hash references, in order to integrate with numerous
templating system's TMPL_LOOP structure. Each hash reference is in the following format:

    month    => 'Jan 2009',
    upload   => MB or GB decimal
    download => MB or GB decimal
    duration => hours decimal

Returns undef if no rows are found in the database table.




=head2 month_hours_used ( { NAME => VALUE } )

Returns the number of hours used for an individual user's plan for any given month.

Parameters must be passed in as a hash reference as such:

    username    => $username,   # mandatory
    nas         => $class,      # NAS class or IP
    month       => YYYY-MM,     # optional

If month is not passed in, we will default to the current month. If 'class'
is not passed in, we will default to 'dialup'.

Returns the number of hours used, in a two point decimal format. If no
entries could be found in the database, returns undef.

=head2 _create_archive_table ( { tablename => $tablename } )

Creates an archive table in the RADIUS MySQL database. The 'tablename' parameter
is mandatory. It makes sense to use 'radacct_YYYY-MM' as the name of the table.

Returns 1 upon success.




=head2 date ( { get => VALUE, datetime => $datetime } )

Returns a date string or object.

The 'get' hashref parameter can take either day, month or year as valid values.

If year is specified, returns the string 'YYYY'. If 'month' is specified,
the return is 'YYYY-MM'. For day, returns 'YYYY-MM-DD'.

The method will generate a 'now' DateTime object to work with, unless a pre-created
DateTime object is passed in with the optional 'datetime' parameter.

Returns a DateTime object of the present date/time if no parameters are passed in.

The program terminates via croak() if the 'get' parameter is passed in with an 
invalid value.



=head2 password( { NAME => VALUE })

This method acts as both a getter and a setter for a user's RADIUS password.

The parameters are passed in as a hash reference in the following form:

    username    => 'username',
    password    => 'password'

The username parameter is mandatory. If it is not passed in, or is not found the
return is undef, otherwise the current user password is returned.

If the password parameter is passed in along with the username, the current
user's password will be overwritten with the new value, and the new value
will be returned.



=head2 update_ras_name( { day => $day } )

This method rewrites the NASIPAddress in the RADIUS database's radacct table.
Generally, it is used to classify groups of RAS IP addresses and assign them
a name. For example, you can group all of your ADSL RASs IP addresses into
logical groups for UBB.

The day parameter is mandatory, and must be a DateTime object, after being
called with $datetime->ymd(). This method will operate on the date 
specified in the DateTime object.

This method is handy for calling in a loop context to iterate over past data.

See the accompanying update_nas_ip_address script in the distributions src/utilities
directory.

Returns 0 upon completion/success.

=head1 SEE ALSO

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2012 by Steve Bertrand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
