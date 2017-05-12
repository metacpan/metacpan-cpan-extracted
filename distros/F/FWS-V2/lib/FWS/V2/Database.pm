package FWS::V2::Database;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Database - Framework Sites version 2 data management

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;

    #
    # Create FWS with MySQL connectivity
    #
    my $fws = FWS::V2->new(
                DBName      => 'theDBName',
                DBUser      => 'myUser',
                DBPassword  => 'myPass'
    );

    #
    # create FWS with SQLite connectivity
    #
    my $fws2 = FWS::V2->new(
                DBType      => 'SQLite',
                DBName      => '/home/user/your.db'
    );



=head1 DESCRIPTION

Framework Sites version 2 common methods that connect, read, write, reorder or alter the database itself.


=head1 METHODS

=head2 mergeExtra

In FWS database tables there is a field named extra_value.  This field holds a hash that is to be appended to the return hash of the record it belongs to.

    #
    # If we have an extra_value field and a real hash lets combine them together
    #
    %dataHash = $fws->mergeExtra( $extra_value, %dataHash );

Note: If anything but stored extra_value strings are passed, the method will throw an error

=cut

sub mergeExtra {
    my ( $self, $extraValue, %addHash ) = @_;

    #
    # lets use storable in comptabile nfreeze mode
    #
    use Storable qw(nfreeze thaw);

    #
    # pull the hash out
    #
    my %extraHash;

    #
    # only if its populated unthaw it
    #
    if ( $extraValue ) { %extraHash = %{thaw( $extraValue )} }

    #
    # return the two hashes combined together
    #
    return ( %addHash, %extraHash );
}

=head2 adminUserArray

Return an array of the admin users.   The hash array will contain name, userId, and guid.

    #
    # get a reference to the hash array
    #
    my $adminUserArray = $fws->adminUserArray( ref => 1 );

=cut

sub adminUserArray {
    my ( $self, %paramHash ) = @_;
    my @userHashArray;

    #
    # get the data from the database and push it into the hash array
    #
    my $adminUserArray = $self->runSQL( SQL => "select name, user_id, guid from admin_user" );
    while ( @$adminUserArray ) {
        #
        # assign the data to variables: Perl likes it done this way
        #
        my %userHash;
        $userHash{name}          = shift @{$adminUserArray};
        $userHash{userId}        = shift @{$adminUserArray};
        $userHash{guid}          = shift @{$adminUserArray};

        #
        # push it into the array
        #
        push @userHashArray, {%userHash};
    }
    if ( $paramHash{ref} ) { return \@userHashArray }
    return @userHashArray;
}


=head2 adminUserHash

Return an array of the admin users.   The hash array will contain name, userId, and guid.

    #
    # get a reference to the hash
    #
    my $dataHashRef = $fws->adminUserHash( guid => 'someGUIDOfAnAdminUser', ref => 1 );

=cut

sub adminUserHash {
    my ( $self, %paramHash ) = @_;
    my $extArray        = $self->runSQL( SQL => "select extra_value, 'email', email, 'userId', user_id, 'name', name from admin_user where guid='" . $self->safeSQL( $paramHash{guid} ) . "'");
    my $extraValue      = shift @{$extArray};
    my %adminUserHash   = @$extArray;
    %adminUserHash      = $self->mergeExtra( $extraValue, %adminUserHash );
    if ( $paramHash{ref} ) { return \%adminUserHash }
    return %adminUserHash;
}

=head2 alterTable

It is not recommended you would use the alterTable method outside of its intended core database creation and maintenance routines but is here for completeness.  Some of the internal table definitions alter data based on its context and will be unpredictable.  For work with table structures not directly tied to the FWS 2 core schema, use FWS::Lite in a non web rendered script.

    #
    # retrieve a reference to an array of data we asked for
    #
    # Note: It is not recommended to change the data structure of
    # FWS default tables
    #
    print $fws->alterTable(
        table   => 'table_name', # case sensitive table name
        field   => 'field_name', # case sensitive field name
        type    => 'char(255)',  # Any standard cross platform type
        key     => '',           # MUL, PRIMARY KEY, FULL TEXT
        default => '',           # '0000-00-00', 1, 'default value'...
    );

=cut

sub alterTable {
    my ( $self, %paramHash ) = @_;

    #
    # because this is only called interanally and all data is static and known,
    # we can be a little laxed on safety there is no need to wrapper everything
    # in safeSQL - even so in the context of some parts here we actually
    # might even been adding tics out of place on purpose.
    #

    #
    # set some vars we will flip depending on db type
    # alot is defaulted to mysql, because that
    # is the norm, we will groom things that need to be groomed
    #
    my $sqlReturn;
    my $autoIncrement       = 'AUTO_INCREMENT ';
    my $indexStatement      = 'alter table ' . $paramHash{table} . ' add INDEX ' . $paramHash{table} . '_' . $paramHash{field} . ' (' . $paramHash{field} . ')';

    #
    # if default is timestamp lets not put tic's around it
    #
    if ( $paramHash{default} ne 'CURRENT_TIMESTAMP' ) {
        $paramHash{default} = "'" . $paramHash{default} . "'";
    }

    #
    # the default value is not applicable to text types lets not set it!
    #
    my $default = " NOT NULL default " . $paramHash{default};
    if ( $paramHash{type} =~ /^text/i ) { $default = '' }

    #
    # build teh statements
    #
    my $addStatement        = "alter table " . $paramHash{table} . " add " . $paramHash{field} . " " . $paramHash{type} . $default;
    my $changeStatement     = "alter table " . $paramHash{table} . " change " . $paramHash{field} . " " . $paramHash{field} . " " . $paramHash{type} . $default;

    #
    # add primary key if the table is not an ext field
    #
    my $primaryKey          = "PRIMARY KEY";

    #
    # show tables statement
    #
    my $showTablesStatement = "show tables";

    #
    # do SQLLite changes
    #
    if ( $self->{DBType} =~ /^sqlite$/i ) {
        $autoIncrement          = "";
        $indexStatement         = "create index " . $paramHash{table} . "_" . $paramHash{field} . " on " . $paramHash{table} . " (" . $paramHash{field} . ")";
        $showTablesStatement    = "select name from sqlite_master where type='table'";
    }

    #
    # do mySQL changes
    #
    if ( $self->{DBType} =~ /^mysql$/i ) {
        if ( $paramHash{key} eq 'FULLTEXT' ) {
            $indexStatement = "create FULLTEXT index " . $paramHash{table} . "_" . $paramHash{field} . " on " . $paramHash{table} . " (" . $paramHash{field} . ")";
        }
    }

    #
    # FULTEXT is MUL if not mysql, and mysql returns them as MUL even if they are full text so we don't need to updated them if they are set to that
    # so lets change it to MUL to keep mysql and other DB's without FULLTEXT syntax happy
    #
    if ( $paramHash{key} eq 'FULLTEXT' ) { $paramHash{key} = 'MUL' }

    #
    # blank by default because we use guid - enxt if we are trans we need order ids for easy to read transactions
    # this is for legacy eCommerce, but I like it anyways so we'll keep it this way
    #
    my $idField;
    if ( $paramHash{table} eq 'trans' ) { $idField = ", id INTEGER " . $autoIncrement . $primaryKey }

    #
    # if its the sessions table make it like this
    #
    if ( $paramHash{table} eq 'fws_sessions' ) { $idField = ", id char(36) " . $primaryKey }

    #
    # compile the statement
    #
    my $createStatement = "create table " . $paramHash{table} . " (site_guid char(36) NOT NULL default ''" . $idField . ")";

    #
    # For full text searching, we will need to use MyISAM
    #
    if ( $self->{DBType} =~ /^mysql$/i ) { $createStatement .= " ENGINE=MyISAM" }

    #
    # get the table hash
    #
    my %tableHash;
    my @tableList = @{$self->runSQL( SQL => $showTablesStatement, noUpdate => 1 )};
    while (@tableList) {
        my $fieldInc            = shift @tableList;
        $tableHash{$fieldInc}   = 1;
    }

    #
    # create tht table if it does not exist
    #
    if ( !$tableHash{$paramHash{table}} ) {
        $self->runSQL( SQL => $createStatement, noUpdate => 1 );
        $sqlReturn .= $createStatement . '; ';
    }

    #
    # get the table definition hash
    #
    my %tableFieldHash = $self->tableFieldHash( $paramHash{table} );

    #
    # make the field if its not there
    #
    if ( !$tableFieldHash{$paramHash{field}}{type} ) {
        $self->runSQL( SQL => $addStatement, noUpdate=> 1 );
        $sqlReturn .= $addStatement . '; ';
    }

    #
    # change the datatype if we are talking about MySQL for now if your SQLite
    # we still have to add support for that
    #
    if ( $paramHash{type} ne $tableFieldHash{$paramHash{field}}{type} && $self->{DBType} =~ /^mysql$/i ) {
        $self->runSQL( SQL => $changeStatement, noUpdate => 1 );
        $sqlReturn .= $changeStatement . '; ';
    }

    #
    # set any keys if not the same;
    #
    if ( $tableFieldHash{$paramHash{table} . '_' . $paramHash{field}}{key} ne 'MUL' && $paramHash{key} ) {
        $self->runSQL( SQL => $indexStatement, noUpdate => 1 );
        $sqlReturn .=  $indexStatement . '; ';
    }

    return $sqlReturn;
}


=head2 autoArray

Return a hash array of make, model, and year from the default automotive tables if they are installed.

    #
    # get a list of autos make model and year based on year
    #
    my @autoArray = $fws->autoArray( year => '1994' );
    for my $i (0 .. $#autoArray) {
        print $autoArray[$i]{make} . "\t" . $autoArray[$i]{model} . "\n";
    }    
 

=cut

sub autoArray {
    my ( $self, %paramHash ) = @_;

    my $whereStatement = '1=1';

    #
    # add active critiria if appicable
    #
    if ( $paramHash{model} ) { $whereStatement .= " and model like '" . $self->safeSQL( $paramHash{model} ) . "'" }
    if ( $paramHash{year} ) { $whereStatement .= " and year like '" . $self->safeSQL( $paramHash{year} ) . "'" }
    if ( $paramHash{make} ) { $whereStatement .= " and make like '" . $self->safeSQL( $paramHash{make} ) . "'" }

    my @autoArray = @{$self->runSQL( SQL => "select make, model, year from auto where " . $whereStatement )};

    my @returnArray;
    while (@autoArray) {
        my %autoHash;
        $autoHash{make}    = shift @autoArray;
        $autoHash{model}   = shift @autoArray;
        $autoHash{year}    = shift @autoArray;
        push @returnArray, {%autoHash};
    }
    return @returnArray;
}


=head2 connectDBH

Do the initial database connection via MySQL or SQLite.  This method will return back the DBH it creates, but it is only here for completeness and would normally never be used.  For FWS database routines this is not required as it will be implied when executing those methods.

    $fws->connectDBH();

If you want to pass DBType, DBName, DBHost, DBUser, and DBPassword as a hash, the global FWS DBH will not be passed, and the DBH it creates will be returned from the method.

The first time this is ran, it will cache the DBH and not ask for another.   If you are running multipule data sources you will need to add noCache=>1.  This will not cache the DBH, nor use the the cached DBH used as the default return.

=cut

sub connectDBH {
    my ( $self, %paramHash ) = @_;

    #
    # hook up with some DBI
    #
    use DBI;

    #
    # Use defaults if they are not passed
    #
    $paramHash{DBType}         ||= $self->{DBType};
    $paramHash{DBName}         ||= $self->{DBName};
    $paramHash{DBHost}         ||= $self->{DBHost};
    $paramHash{DBUser}         ||= $self->{DBUser};
    $paramHash{DBPort}         ||= $self->{DBPort};
    $paramHash{DBPassword}     ||= $self->{DBPassword};
    $paramHash{noCache}        ||= 0;

    #
    # fill this up!
    #
    my $DBH;

    #
    # grab the DBI if we don't have it yet, or if noCache is passed do it again
    #
    if ( !$self->{'_DBH_'.$paramHash{DBName} . $paramHash{DBHost}} || $paramHash{noCache} eq '1') {

        #
        # DBType for mysql is always lower case
        #
        if ( $paramHash{DBType} =~ /mysql/i) { $paramHash{DBType} = lc( $paramHash{DBType} ) }

        #
        # default set to mysql
        #
        my $dsn = $paramHash{DBType} . ":" . $paramHash{DBName} . ":" . $paramHash{DBHost} . ":" . $paramHash{DBPort};

        #
        # SQLite
        #
        if ( $paramHash{DBType} =~ /SQLite/i ) { $dsn = "SQLite:" . $paramHash{DBName} }

        #
        # set the DBH for use throughout the script
        #
        $DBH = DBI->connect( 'DBI:' . $dsn, $paramHash{DBUser}, $paramHash{DBPassword} );

        #
        # send an error if we got one
        #
        if ( DBI->errstr() ) { $self->FWSLog( 'DB connection error: ' . DBI->errstr() ) }
    }

    #
    # if DBH cache isn't defined then lets define it
    #
    if ( !$self->{'_DBH_' . $paramHash{DBName} . $paramHash{DBHost}} && !$paramHash{noCache} )  { $self->{'_DBH_' . $paramHash{DBName} . $paramHash{DBHost}} = $DBH }

    #
    # in either case return the DBH in case someone wants it for convience
    #
    return $DBH;
}


=head2 copyData

Make a copy of data hash giving it a unique guid, and appending (Copy) text to name and title if you pass the extra key of addTail.

    #
    # duplicate a data record
    #
    my %newHash = $fws->copyData( %dataHash );

    #
    # do the same thing but add (Copy) to the end of the name and title
    #
    my %copyHash = $fws->copyData( addTail => 1, %dataHash );

=cut

sub copyData {
    my ( $self, %paramHash ) = @_;

    my %dataHash = $self->dataHash( guid => $paramHash{guid} );

    if ( $paramHash{addTail} ) {
        $dataHash{name}   .= ' (Copy)';
        $dataHash{title}  .= ' (Copy)';
    }

    delete $paramHash{addTail};
    $dataHash{guid}   = '';
    $dataHash{parent} = $paramHash{parent};

    return $self->saveData( %dataHash );
}


=head2 changeUserEmail

Change the email of a user throught the system.

    my $failMessage = $fws->changeUserEmail( 'from@email.com', 'to@eamil.com' );

Fail message will be blank if it worked.

=cut

sub changeUserEmail {
    my ( $self, $emailFrom, $emailTo ) = @_;

    #
    # check to make sure its not already being used
    #
    my %userHash = $self->userHash( $emailTo );

    #
    # check to make sure the emails we are chaning it to are valid
    #
    if ( !$self->isValidEmail( $emailTo ) ) {
        return 'The email you are chaning to is invalid';
    }

    #
    # if its not used, lets do it!
    #
    if ( $userHash{guid} && $emailFrom ) {

        #
        # THIS NEEDS TO BE EXPORTD SOME HOW TO ECommerce
        #
        #my @transArray = $self->transactionArray(email=>$emailFrom);
        #for my $i (0 .. $#transArray) {
        #       $self->runSQL( SQL => "update trans set email='" . $self->safeSQL( $emailTo ) . "' where email like '" . $self->safeSQL( $emailFrom ) . "'" );
#
#               }

        #
        # update the profile we are changing
        #
        $self->runSQL( SQL => "update profile set email='" . $self->safeSQL( $emailTo ) . "' where email like '" . $self->safeSQL( $emailFrom ) . "'" );



    }
    else { return 'Email could not be changed, it is already being used.'; }
    return;
}


=head2 dataArray

Retrieve a hash array based on any combination of keywords, type, guid, or tags

    my @dataArray = $fws->dataArray( guid => $someParentGUID );
    for my $i ( 0 .. $#dataArray ) {
         $valueHash{html} .= $dataArray[$i]{name} . "<br/>";
    }

Any combination of the following parameters will restrict the results.  At least one is required.

=over 4

=item * guid: Retrieve any element whose parent element is the guid

=item * keywords: A space delimited list of keywords to search for

=item * tags: A comma delimited list of element tags to search for

=item * type: Match any element which this exact type

=item * containerId: Pull the data from the data container

=item * childGUID: Retrieve any element whose child element is the guid (This option can not be used with keywords attribute)

=item * showAll: Show active and inactive records. By default only active records will show

=back

Note: guid and containerId cannot be used at the same time, as they both specify the parent your pulling the array from

=cut

sub dataArray {
    my ( $self, %paramHash ) = @_;

    #
    # set site GUID if it wasn't passed to us
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # transform the containerId to the parent id
    #
    if ( $paramHash{containerId} ) {

        #
        # if we don't get one, we will fail on the next check because we won't have a guid
        #
        ( $paramHash{guid} ) = @{$self->runSQL( SQL => "select guid from data where name='" . $self->safeSQL( $paramHash{containerId} ) . "' and element_type='data' and site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "' LIMIT 1" )};

    }

    #
    # if we don't have any data to search for get out so we don't get "EVERYTHING"
    #
    if ( $paramHash{childGUID} eq '' && $paramHash{guid} eq '' && !$paramHash{type} && $paramHash{keywords} eq '' && $paramHash{tags} eq '' ) {
          return ();
    }

    #
    # get the where and join builders ready for content
    #
    my $addToExtWhere;
    my $addToDataWhere;
    my $addToExtJoin;
    my $addToDataXRefJoin;

    #
    # bind by element Type could be a comma delemented List
    #
    if ( $paramHash{type} ) {
        my @typeArray   = split( /,/, $paramHash{type} );
        $addToDataWhere .= 'and (';
        $addToExtWhere  .= 'and (';
        while (@typeArray) {
            my $type = shift @typeArray;
            $addToDataWhere .= "data.element_type like '" . $type . "' or ";
        }
        $addToExtWhere  =~ s/\s*or\s*$//g;
        $addToExtWhere  .= ')';
        $addToDataWhere =~ s/\s*or\s*$//g;
        $addToDataWhere .= ')';
    }

    #
    # data left join connector
    #
    my $dataConnector = 'guid_xref.child=data.guid';

    #
    # bind critera by child guid, so we are only seeing stuff who's child = #
    #
    if ( $paramHash{childGUID} ) {
        $addToExtWhere  .= "and guid_xref.child = '" .
            $self->safeSQL( $paramHash{childGUID} ) . "' ";
        $addToDataWhere .= "and guid_xref.child = '" .
            $self->safeSQL( $paramHash{childGUID} ) . "' ";
        $dataConnector  = 'guid_xref.parent=data.guid';
    }

    #
    # bind critera by array guid, so we are only seeing stuff who's parent = #
    #
    if ( $paramHash{guid} ) {
        $addToExtWhere  .= "and guid_xref.parent = '" .
            $self->safeSQL( $paramHash{guid} ) . "' ";
        $addToDataWhere .= "and guid_xref.parent = '" .
            $self->safeSQL( $paramHash{guid} ) . "' ";
    }


    #
    # find data by tags
    #
    if ( $paramHash{tags} ) {
        my @tagsArray = split( /,/, $paramHash{tags} );
        my $tagGUIDs;
        while (@tagsArray) {
            my $checkTag = shift @tagsArray;

            #
            # bind by tags Type could be a comma delemented List
            #
            my %elementHash = $self->_fullElementHash();

            for my $elementType ( keys %elementHash ) {
            my $incTags = $elementHash{$elementType}{tags};
            if ( ( $incTags =~/^$checkTag$/
                        || $incTags =~/^$checkTag,/
                        || $incTags =~/,$checkTag$/
                        || $incTags =~/,$checkTag,$/
                        )
                        && $incTags && $checkTag ) {
                    $tagGUIDs .= ',\'' . $elementType . '\'';
                    }
                }
            }

        $addToDataWhere .= 'and (data.element_type in (\'\'' . $tagGUIDs . '))';
        $addToExtWhere  .= 'and (data.element_type in (\'\'' . $tagGUIDs . '))';
        }


    #
    # add the keywordScore field response
    #
    my $keywordScoreSQL     = '1';
    my $dataCacheSQL        = '1';
    my $dataCacheJoin       = '';

    #
    # if any keywords are added,  and create an array of ID's and join them into comma delmited use
    #
    if ( $paramHash{keywords} ) {

        #
        # build the field list we will search against
        #
        my @fieldList = ( 'data_cache.title', 'data_cache.name' );
        for my $key ( keys %{$self->{dataCacheFields}} ) { push @fieldList, 'data_cache.' . $key }

        #
        # set the cache and join statement starters
        #
        $dataCacheSQL   = 'data_cache.pageIdOfElement';
        $dataCacheJoin  = 'left join data_cache on (data_cache.guid=child)';

        #
        # do some last minute checking for keywords stablity
        #
        $paramHash{keywords} =~ s/[^a-zA-Z0-9 \.\-]//sg;

        #
        # build the actual keyword chains
        #
        $addToDataWhere .= " and data.active='1' and (";
        $addToDataWhere .= $self->_getKeywordSQL( $paramHash{keywords}, @fieldList );
        $addToDataWhere .= ")";

        #
        # if we are on mysql lets do some fuzzy matching
        #
        if ( $self->{DBType} =~ /^mysql$/i ) {
            $keywordScoreSQL = "(";
            while (@fieldList) {
                $keywordScoreSQL .= "(MATCH (" . $self->safeSQL( shift @fieldList ) . ") AGAINST ('" . $self->safeSQL( $paramHash{keywords} ) . "'))+"
                }
            $keywordScoreSQL =~ s/\+$//sg;
            $keywordScoreSQL =  $keywordScoreSQL . ")+1 as keywordScore";
            }
        }

    my @hashArray;
    my $arrayRef = $self->runSQL( SQL => "select distinct " . $keywordScoreSQL . ", " . $dataCacheSQL . ", data.extra_value, data.guid, data.created_date, data.show_mobile, data.lang, guid_xref.site_guid, data.site_guid, data.site_guid, data.active, data.friendly_url, data.page_friendly_url, data.title, data.disable_title, data.default_element, data.disable_edit_mode, data.element_type, data.nav_name, data.name, guid_xref.parent, data.page_guid, guid_xref.layout from guid_xref " . $dataCacheJoin . "  left join data on (guid_xref.site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "') and " . $dataConnector . " " . $addToDataXRefJoin . " " . $addToExtJoin . " where guid_xref.parent != '' and guid_xref.site_guid is not null " . $addToDataWhere . " order by guid_xref.ord" );

    #
    # for speed we will add this to here so we don't have to ask it EVERY single time we loop though the while statemnent
    #
    my $showMePlease = 0;
    if (( $paramHash{showAll} || $self->formValue('editMode') eq '1' || $self->formValue('p') =~ /^fws_/) ) { $showMePlease =1 }

    #
    # move though the data records creating the individual hashes
    #
    while (@{$arrayRef}) {
        my %dataHash;

        my $keywordScore                  = shift @{$arrayRef};
        my $pageIdOfElement               = shift @{$arrayRef};
        my $extraValue                    = shift @{$arrayRef};
        $dataHash{guid}                   = shift @{$arrayRef};
        $dataHash{createdDate}            = shift @{$arrayRef};
        $dataHash{showMobile}             = shift @{$arrayRef};
        $dataHash{lang}                   = shift @{$arrayRef};
        $dataHash{guid_xref_site_guid}    = shift @{$arrayRef};
        $dataHash{siteGUID}               = shift @{$arrayRef};
        $dataHash{site_guid}              = shift @{$arrayRef};
        $dataHash{active}                 = shift @{$arrayRef};
        $dataHash{friendlyURL}            = shift @{$arrayRef};
        $dataHash{pageFriendlyURL}        = shift @{$arrayRef};
        $dataHash{title}                  = shift @{$arrayRef};
        $dataHash{disableTitle}           = shift @{$arrayRef};
        $dataHash{defaultElement}         = shift @{$arrayRef};
        $dataHash{disableEditMode}        = shift @{$arrayRef};
        $dataHash{type}                   = shift @{$arrayRef};
        $dataHash{navigationName}         = shift @{$arrayRef};
        $dataHash{name}                   = shift @{$arrayRef};
        $dataHash{parent}                 = shift @{$arrayRef};
        $dataHash{pageGUID}               = shift @{$arrayRef};
        $dataHash{layout}                 = shift @{$arrayRef};



        if ( $dataHash{active} || ( $showMePlease && $dataHash{siteGUID} eq $paramHash{siteGUID}) || ( $paramHash{siteGUID} ne $dataHash{siteGUID} && $dataHash{active} ) ) {

            #
            # twist our legacy statements around.  titleOrig isn't legacy - but I don't
            # know why its here either.  We will attempt to deprecate it on the next version
            #
            $dataHash{element_type}       = $dataHash{type};
            $dataHash{titleOrig}          = $dataHash{title};

            #
            # if the title is blank lets dump the name into it
            #
            $dataHash{title} ||= $dataHash{name};

            #
            # add the extended fields and create the hash
            #
            %dataHash = $self->mergeExtra( $extraValue, %dataHash );

            #
            # overwriting these, just in case someone tried to save them in the extended hash
            #
            $dataHash{keywordScore}       = $keywordScore;
            $dataHash{pageIdOfElement}    = $pageIdOfElement;
            $dataHash{pageIdOfElement}    = $pageIdOfElement;

            #
            # push the hash into the array
            #
            push @hashArray, {%dataHash};
        }
    }

    #
    # return the reference or the array
    #
    if ( $paramHash{ref} ) { return \@hashArray }
    return @hashArray;
}

=head2 dataHash

Retrieve a hash or hash reference for a data matching the passed guid.  This can only be used after setSiteValues() because it required $fws->{siteGUID} to be defined.

    #
    # get the hash itself
    #
    my %dataHash     = $fws->dataHash( guid => 'someguidsomeguidsomeguid' );

    #
    # get a reference to the hash
    #
    my $dataHashRef = $fws->dataHash( guid => 'someguidsomeguidsomeguid', ref => 1 );

=cut

sub dataHash {
    my ( $self, %paramHash ) = @_;

    #
    # set site GUID if it wasn't passed to us
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    my $arrayRef =  $self->runSQL( SQL => "select data.extra_value, data.element_type, 'pageGUID', data.page_guid, 'lang', lang, 'guid', data.guid, 'pageFriendlyURL', page_friendly_url, 'friendlyURL', friendly_url, 'defaultElement', data.default_element, 'guid_xref_site_guid', data.site_guid, 'showLogin', data.show_login, 'showMobile', data.show_mobile, 'showResubscribe', data.show_resubscribe, 'groupId', data.groups_guid, 'disableEditMode',data.disable_edit_mode, 'siteGUID', data.site_guid, 'site_guid', data.site_guid, 'title', data.title, 'disableTitle', data.disable_title, 'active', data.active, 'navigationName', nav_name, 'name', data.name from data left join site on site.guid=data.site_guid where data.guid='" . $self->safeSQL( $paramHash{guid} ) . "' and (data.site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "' or site.sid='fws')" );

    #
    # pull off the first two fields because we need to manipulate them
    #
    my $extraValue      = shift @{$arrayRef};
    my $dataType        = shift @{$arrayRef};

    #
    # convert it to a hash
    #
    my %dataHash            = @$arrayRef;

    #
    # do some legacy data type switching around.  some call it type (wich it should be, and some call it element_type
    #
    $dataHash{type}         = $dataType;
    $dataHash{element_type} = $dataType;

    
    #
    # combine the hash
    #
    %dataHash               = $self->mergeExtra( $extraValue, %dataHash );

    #
    # Overwrite the title with the name if it is blank
    #
    $dataHash{title} ||=  $dataHash{name};

    #
    # return the hash or hash reference
    #
    if ( $paramHash{ref} ) { return \%dataHash }
    return %dataHash;
}

=head2 deleteData

Delete something from the data table.   %dataHash must contain guid and either containerId or parent. By passing noOrphanDelete with a value of 1, any data orphaned from the act of this delete will also be deleted.

    my %dataHash;
    $dataHash{noOrphanDelete} = '0';
    $dataHash{guid}           = 'someguid123123123';
    $dataHash{parent}         = 'someparentguid';
    my %dataHash $fws->deleteData( %dataHash );

=cut

sub deleteData {
    my ( $self, %paramHash ) = @_;
    %paramHash = $self->runScript( 'preDeleteData', %paramHash );

    #
    # get the sid if one wasn't passed
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # transform the containerId to the parent id
    #
    if ( $paramHash{containerId} ) {
        ( $paramHash{parent} ) = @{$self->runSQL( SQL => "select guid from data where name='" . $self->safeSQL( $paramHash{containerId} ) . "' and element_type='data' and site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "' LIMIT 1" )};
    }

    #
    # Kill the xref
    #
    $self->_deleteXRef( $paramHash{guid}, $paramHash{parent}, $paramHash{siteGUID} );

    #
    # Kill any data recrods now orphaned from this process
    #
    $self->_deleteOrphanedData("guid_xref","child","data","guid");

    #
    # if we are cleaning orphans continue
    #
    if ( !$paramHash{noOrphanDelete} ) {
        #
        # loop though till we don't see anything dissapear
        #
        my $keepGoing = 1;

        while ( $keepGoing ) {
            #
            # set up the tests
            #
            my ( $firstTest )         = @{$self->runSQL( SQL => "select count(1) from guid_xref" )};
            my ( $firstTestData )     = @{$self->runSQL( SQL => "select count(1) from data" )};

            #
            # get rid of any parent that no longer has a perent
            #
            $self->_deleteOrphanedData( 'guid_xref', 'parent', 'data', 'guid', ' and guid_xref.parent <> \'\'' );

            #
            # get rid of any data records that are now orphaned from the above process's
            #
            $self->_deleteOrphanedData( "data", "guid", "guid_xref", "child");

            #
            # if we are not deleting orphans do the checks
            #
            if ( !$paramHash{noOrphanDelete} ) {

                #
                # grab a second test to match against
                #
                my ( $secondTest )        = @{$self->runSQL( SQL => "select count(1) from guid_xref" )};
                my ( $secondTestData )    = @{$self->runSQL( SQL => "select count(1) from data" )};

                #
                # now that we have a first and second pass.  if they have changed keep going, but if nothing happened
                # lets ditch out of here
                #
                if ( $secondTest eq $firstTest && $secondTestData eq $firstTestData ) { $keepGoing = 0 } else { $keepGoing = 1 }
            }
        }
        #
        # Kill any data recrods now orphaned from the cleansing
        #
        $self->_deleteOrphanedData("guid_xref","child","data","guid");
    }

    #
    # run any post scripts and return what we were passed
    #
    %paramHash = $self->runScript('postDeleteData',%paramHash);
    return %paramHash;
}

=head2 deleteHash

Remove a hash based on its guid from FWS hash object.

=cut

sub deleteHash {
    my ( $self, %paramHash ) = @_;

    #
    # get the current array
    #
    my @hashArray = $self->hashArray(%paramHash);
    my @newArray;

    #
    # go though each one of the shippingLocation items, figure out what one is being updated and update it!
    #
    for my $i (0 .. $#hashArray) {

        #
        # update the loc with the same guid with the new hash
        #
        if ( $paramHash{guid} ne $hashArray[$i]{guid} ) { push @newArray, {%{$hashArray[$i]}} }
    }
    return (nfreeze(\@newArray));
}


=head2 deleteUser

Delete a user by passing the guid in as a hash key

=cut

sub deleteUser {
    my ( $self, %paramHash ) = @_;
    %paramHash = $self->runScript( 'preDeleteUser', %paramHash );
    $self->runSQL( SQL => "delete from profile where guid='" . $self->safeSQL( $paramHash{guid} ) . "'" );
    %paramHash = $self->runScript( 'preDeleteUser', %paramHash );
    return %paramHash;
}


=head2 deleteQueue

Delete from the message and process queue

    my %queueHash;
    $queueHash{guid} = 'someQueueGUID';
    my %queueHash $fws->deleteQueue( %queueHash );

=cut

sub deleteQueue {
    my ( $self, %paramHash ) = @_;
    %paramHash = $self->runScript( 'preDeleteQueue', %paramHash );
    $self->runSQL( SQL => "delete from queue where guid = '" . $self->safeSQL( $paramHash{guid} ) . "'" );
    %paramHash = $self->runScript( 'postDeleteQueue', %paramHash );
    return %paramHash;
}


=head2 elementArray

Return the elements from the database. This will not pull elements from plugins!

=cut

sub elementArray {
    my ( $self, %paramHash ) = @_;

    #
    # array holder for the return
    #
    my @elementArrayReturn;

    #
    # the where satement we will be appending to
    #
    my $addToWhere;

    #
    # if we are passed a parent guid we have to match
    #
    if ( $paramHash{parent} ) { $addToWhere = " and parent='" . $self->safeSQL( $paramHash{parent} ) . "'" }

    #
    # TODO does this really need be done anymore? 1.3 used 0 numbers
    #
    if ( $paramHash{parent} eq '0' ) { $addToWhere = " and parent=''" }

    #
    # match only with matching siteGUID
    #
    if ( $paramHash{siteGUID} ) { $addToWhere .= " and site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "'" }

    #
    # match only with matching plugin, all other search cretira is overwritten! 
    # And these plugins are only alowed to be shows if they are the root of a site
    #
    if ( $paramHash{plugin} ) {
        # TODO update to not use s%, have it actually xref the site table for parents in case later we descide they won't all start with s
        $addToWhere = " and plugin='" . $self->safeSQL( $paramHash{plugin} ) . "' and parent like 's%'"
    }

    if ( $paramHash{tags} ) {
        my @tagsArray = split( /,/, $paramHash{tags} );
        while (@tagsArray) {
            my $checkTag = shift @tagsArray;
            #
            # add extra ,'s where any spaces are,  that will fill in gaps for the like
            #
            $checkTag =~ s/ //sg;

            #
            # add the where with all chanches of like
            #
            if ( $checkTag ) {
                $addToWhere .= " and (tags like '" . $checkTag . "' or tags like '" . $checkTag . ",%' or tags like '%," . $checkTag . "' or  tags like '%," . $checkTag . ",%')";
            }
        }
    }

    if ( $paramHash{keywords} ) {
        my $keywordSQL = $self->_getKeywordSQL( $paramHash{keywords}, "css_devel", "js_devel", "schema_devel", "script_devel", "title", "type", "guid", "admin_group" );
        if ( $keywordSQL ) { $addToWhere .= ' and ( ' . $keywordSQL . ' ) ' }
    }

    #
    # grab the array from the DB
    #
    my ( @elementArray ) = @{$self->runSQL( SQL => "select ord, plugin, admin_group, root_element, site_guid, guid, type, parent, title, schema_devel, script_devel, checkedout from element where 1=1" . $addToWhere . " order by title" )};
    
    #
    # look at element included in plugins
    #
    for my $guid ( sort { $self->{elementHash}{$a}{alphaOrd} <=> $self->{elementHash}{$b}{alphaOrd} } keys %{$self->{elementHash}}) {

        my $addElement = 0;
        if ( $paramHash{tags} ) {
            my @tagsArray = split( /,/, $paramHash{tags} );

            while (@tagsArray) {
                my $checkTag = shift @tagsArray;
                #
                # add extra ,'s where any spaces are,  that will fill in gaps for the like
                #
                $checkTag =~ s/ //sg;
                if ( $checkTag && $self->{elementHash}{$guid}{tags} =~ /^$checkTag$/ ) { $addElement = 1 }
            }

        if ( $addElement ) { push @elementArrayReturn, {%{$self->{elementHash}{$guid}}} }
        }
    }

    #
    # loop though the whole thing and push it into the array for return
    #
    my $alphaOrd = 0;
    while (@elementArray) {
        my %elementHash;
        $alphaOrd++;
        $elementHash{ord}         = shift @elementArray;
        $elementHash{plugin}      = shift @elementArray;
        $elementHash{adminGroup}  = shift @elementArray;
        $elementHash{rootElement} = shift @elementArray;
        $elementHash{siteGUID}    = shift @elementArray;
        $elementHash{guid}        = shift @elementArray;
        $elementHash{type}        = shift @elementArray;
        $elementHash{parent}      = shift @elementArray;
        $elementHash{title}       = shift @elementArray;
        $elementHash{schemaDevel} = shift @elementArray;
        $elementHash{scriptDevel} = shift @elementArray;
        $elementHash{checkedout}  = shift @elementArray;
        $elementHash{alphaOrd}    = $alphaOrd;
        $elementHash{label}       = $elementHash{type} . ' - ' . $elementHash{title};
        if ( !$elementHash{type} ) { $elementHash{label} = 'element' . $elementHash{label} }

        push @elementArrayReturn, {%elementHash};
    }

    return @elementArrayReturn;
}


=head2 elementHash

Return the hash for an element from cache, plugin for element database

=cut

sub elementHash {
    my ( $self, %paramHash ) = @_;

    if ( !$self->{elementHash}->{$paramHash{guid}}{guid} ) {

        #
        # add to element guid or type
        #
        my $addToWhere = "guid='" . $self->safeSQL( $paramHash{guid} ) . "'";
        if ( $paramHash{guid} ) { $addToWhere .= " or type='" . $self->safeSQL( $paramHash{guid} ) . "'" }

        #
        # get tha hash from the DB
        #
        my (@scriptArray) = @{$self->runSQL( SQL => "select 'plugin', plugin, 'jsDevel', js_devel, 'cssDevel', css_devel, 'adminGroup', admin_group, 'classPrefix', class_prefix, 'siteGUID', site_guid, 'guid', guid, 'ord', ord, 'tags', tags, 'public', public, 'rootElement', root_element, 'type', type, 'parent', parent, 'title', title, 'schemaDevel', schema_devel, 'scriptDevel', script_devel, 'checkedout', checkedout from element where " . $addToWhere . " order by ord limit 1" )};

        #
        # create the hash and return it
        #
        %{$self->{elementHash}->{$paramHash{guid}}} = @scriptArray;
    }

    return %{$self->{elementHash}->{$paramHash{guid}}};
}

=head2 exportCSV

Return a hash array in a csv format.

    my $csv = $fws->exportCSV( dataArray => [@someArray] );

=cut

sub exportCSV {
    my ( $self, %paramHash ) = @_;

    #
    # pull the array out of the hash and find out the keys
    #
    my @dataArray = @{$paramHash{dataArray}};
    my %theKeys;
    for my $i (0 .. $#dataArray) {
        for my $key ( keys %{$dataArray[$i]}) {
            if ( $key !~ /^(guid|killSession)$/ ) { $theKeys{$key} =1 }
        }
    }

    #
    # create the header
    #
    my $returnString = 'guid,';
    for my $key ( sort keys %theKeys) { $returnString .= $key . ',' }
    $returnString .= "\n";

    #
    # create the list for everything else
    #
    for my $i (0 .. $#dataArray) {
        $returnString .= $dataArray[$i]{guid} . ',';

        #
        # kill anything that is a blank date and aggressivly clean up anything
        # could break a csv
        #
        for my $key ( sort keys %theKeys) {
            $dataArray[$i]{$key} =~ s/(,|;)/ /sg;
            $dataArray[$i]{$key} =~ s/(\n|\r)//sg;
            $dataArray[$i]{$key} =~ s/^(0000.00.00.*|'|")//sg;
            $returnString .= $dataArray[$i]{$key} . ',';
        }
        $returnString .= "\n";
    }

    #
    # kill the trailing comma and return the string
    #
    $returnString =~ s/,$//sg;
    return $returnString . "\n";
}


=head2 flushSearchCache

Delete all cached data and rebuild it from scratch.  Will return the number of records it optimized.  If no siteGUID was passed then the one from the current site being rendered is used

    print $fws->flushSearchCache( $fws->{siteGUID} );

This also will set the parent id of the data record if it is not already set

=cut

sub flushSearchCache {
    my ( $self, $siteGUID ) = @_;

    #
    # set the site guid if it wasn't passed
    #
    $siteGUID ||= $self->{siteGUID};

    #
    # before we do anything lets get the cache fields reset
    #
    $self->setCacheIndex();

    #
    # drop the current data
    #
    $self->runSQL( SQL => "delete from data_cache where site_guid='" . $self->safeSQL( $siteGUID ) . "'" );

    #
    # lets make the stuff we might need
    #
    my %dataCacheFields = %{$self->{dataCacheFields}};
    foreach my $key ( keys %dataCacheFields ) {
        $self->alterTable( table => "data_cache", field => $key, type => "text", key => "FULLTEXT", default => "" );
    }

    #
    # have a counter so we can see how much work we did
    #
    my $dataUnits = 0;

    #
    # get a list of the current data, and update the cache for each one
    #
    my $dataArray = $self->runSQL( SQL => "select guid from data where site_guid='" . $self->safeSQL( $siteGUID ) . "'");
    while (@$dataArray) {
        my $guid = shift @{$dataArray};
        my %dataHash = $self->dataHash( guid => $guid );
        $self->updateDataCache( %dataHash );
        $dataUnits++;
    }
    return $dataUnits;
}


=head2 getSiteGUID

Get the site GUID for a site by passing the SID of that site.  If the SID does not exist it will return an empty string.

    print $fws->getSiteGUID( 'somesite' );

NOTE: This should not be used and will eventually be pulled in as a FWS internal method only, but is available for legacy reasons.

=cut

sub getSiteGUID {
    my ( $self, $sid ) = @_;
    #
    # get the ID to the sid for site ids these always match the corrisponding sid
    #
    my ( $guid ) = @{$self->runSQL( SQL => "select guid from site where sid='" . $self->safeSQL( $sid ) . "'" )};
    return $guid;
}


=head2 hashArray

Return a FWS Hash in its array format.

=cut

sub hashArray {
    my ( $self, %paramHash ) = @_;

    use Storable qw(nfreeze thaw);

    if ( $paramHash{hashArray} ) {
        #
        # get the current array, and clear the loc string
        #
        return @{thaw( $paramHash{hashArray} )};
    }

    return;
}


=head2 createFWSDatabase

Do a new database check and then create the base records for a new install of FWS if the database doesn't have an admin record.  The return is the HTML that would render for a browser to let them know what just happened.

This will auto trigger a flag to only it allow it to execute once so it doesn't recurse itself.

=cut

sub createFWSDatabase {
    my ( $self ) = @_;

    #
    # make sure I didn't do this yet
    #
    if ( !$self->{createFWSDatabaseRan} ) { 
    
        #
        # Set this flag so we know if we changed anything
        # if we did the return will be the message of what happened
        #
        my $somethingNew = 0;

        #
        # make the admin record if not there
        #
        my ( $adminGUID ) = @{$self->runSQL( SQL => "select guid from site where sid='admin'", noUpdate => 1 )};
        if ( !$adminGUID ) {
        
            #
            # because we don't have an admin we probably don't have a DB at all, lets make it
            #
            $self->updateDatabase();

            #
            # now that the db is there, lets do this!
            #
            $adminGUID = $self->createGUID( 's' );
            $self->runSQL( SQL => "insert into site (guid, sid, site_guid) values ('" . $adminGUID . "', 'admin', '" . $adminGUID . "')" );
            $somethingNew++;
        }
        
        #
        # make the FWS record if not there
        #
        my ( $fwsGUID ) = @{$self->runSQL( SQL => "select guid from site where sid='fws'", noUpdate => 1 )};
        if ( !$fwsGUID ) {
            $fwsGUID = $self->createGUID( 'f' );
            $self->runSQL( SQL => "insert into site (guid, sid, site_guid) values ('" . $fwsGUID . "', 'fws', '" . $adminGUID . "')" );
            $somethingNew++;
        }
    
        #
        # make the default site record if not there
        #
        my ( $siteGUID ) = @{$self->runSQL( SQL => "select guid from site where sid='site'", noUpdate => 1 )};
        if ( !$siteGUID ) {
            $siteGUID = $self->createGUID( 's' );
            $self->runSQL( SQL => "insert into site (guid, sid, default_site, site_guid) values ('" . $siteGUID . "', 'site', '1', '" . $adminGUID . "')" );
            
            #
            # create new home page GUID
            #
            $self->homeGUID( $siteGUID );
            $somethingNew++;
        }
   
        #
        # because there was something new, redirect to the script again now that
        # things should be present
        # 
        if ( $somethingNew ) {
            print "Status: 302 Found\n";
            print "Location: " . $self->{scriptName} . "\n\n";
        }
    }

    #
    # in case of DB Recursion we don't want to run this again, flag it up
    # 
    $self->{createFWSDatabaseRan} = 1;
    return; 
}

=head2 queueArray

Return a hash array of the current items in the processing queue.

=cut

sub queueArray {
    my ( $self, %paramHash ) = @_;

    #
    # set PH's for sql statement
    #
    my $whereStatement = "1 = 1 ";
    my $keywordSQL;

    #
    # Add keywords if they exist to select statement
    #
    if ( $paramHash{keywords} ) {
        $keywordSQL = $self->_getKeywordSQL( $paramHash{keywords}, "queue_from", "queue_to", "from_name", "subject" );
        if ( $keywordSQL ) { $keywordSQL = " and ( " . $keywordSQL . " ) " }
    }

    #
    # queuery by directory or user if needed
    # add other criteria if applicable
    #
    if ( $paramHash{directoryGUID} )  { $whereStatement .= " and directory_guid = '" . $self->safeSQL( $paramHash{directoryGUID} ) . "'" }
    if ( $paramHash{userGUID} )       { $whereStatement .= " and profile_guid = '" . $self->safeSQL( $paramHash{userGUID} ) . "'" }
    if ( $paramHash{from} )           { $whereStatement .= " and queue_from = '" . $self->safeSQL( $paramHash{from} ) . "'" }
    if ( $paramHash{to} )             { $whereStatement .= " and queue_to = '" . $self->safeSQL( $paramHash{to} ) . "'" }
    if ( $paramHash{fromName} )       { $whereStatement .= " and from_name = '" . $self->safeSQL( $paramHash{fromName} ) . "'" }
    if ( $paramHash{subject} )        { $whereStatement .= " and subject = '" . $self->safeSQL( $paramHash{subject} ) . "'" }
    if ( $paramHash{type} )           { $whereStatement .= " and type = '" . $self->safeSQL( $paramHash{type} ) . "'" }

    #
    # add date critiria if appicable
    #
    $paramHash{dateFrom}    ||= "0000-00-00 00:00:00";
    $paramHash{dateTo}      ||= $self->formatDate( format => 'SQL' );
    $whereStatement .= " and scheduled_date <= '" . $self->safeSQL( $paramHash{dateTo} ) . "'";
    $whereStatement .= " and scheduled_date >= '" . $self->safeSQL( $paramHash{dateFrom} ) . "'";

    my $arrayRef = $self->runSQL( SQL => "select profile_guid,directory_guid,guid,type,hash,draft,from_name,queue_from,queue_to,body,subject,digital_assets,transfer_encoding,mime_type,scheduled_date from queue where " . $whereStatement . $keywordSQL . " ORDER BY scheduled_date DESC" );
    my @queueArray;
    while ( @{$arrayRef} ) {
        my %sendHash;
        $sendHash{userGUID}         = shift @{$arrayRef};
        $sendHash{directoryGUID}    = shift @{$arrayRef};
        $sendHash{guid}             = shift @{$arrayRef};
        $sendHash{type}             = shift @{$arrayRef};
        $sendHash{hash}             = shift @{$arrayRef};
        $sendHash{draft}            = shift @{$arrayRef};
        $sendHash{fromName}         = shift @{$arrayRef};
        $sendHash{from}             = shift @{$arrayRef};
        $sendHash{to}               = shift @{$arrayRef};
        $sendHash{body}             = shift @{$arrayRef};
        $sendHash{subject}          = shift @{$arrayRef};
        $sendHash{digitalAssets}    = shift @{$arrayRef};
        $sendHash{transferEncoding} = shift @{$arrayRef};
        $sendHash{mimeType}         = shift @{$arrayRef};
        $sendHash{scheduledDate}    = shift @{$arrayRef};
        push @queueArray, {%sendHash};
    }
    if ( $paramHash{ref} ) { return \@queueArray }
    return @queueArray;
}

=head2 queueHash

Return a hash or reference to the a queue hash.

=cut

sub queueHash {
    my ( $self, %paramHash ) = @_;

    #
    # get an array of the all stuff we need,  in a name\value pair format
    #
    my $arrayRef = $self->runSQL( SQL => "select 'directoryGUID',directory_guid,'userGUID',profile_guid,'hash',hash,'guid',guid,'draft',draft,'fromName',from_name,'from',queue_from,'to',queue_to,'body',body,'subject',subject,'digitalAssets',digital_assets,'transferEncoding',transfer_encoding,'mimeType',mime_type,'scheduledDate',scheduled_date from queue where guid='" . $self->safeSQL( $paramHash{guid} ) . "'" );

    #
    # convert the array to a hash
    #
    my %itemHash = @$arrayRef;

    if ( $paramHash{ref} ) { return \%itemHash }
    return %itemHash;
}


=head2 queueHistoryArray

Return a hash array of the history items from the processing queue.

Parmeters to constrain data:

=over 4

=item * limit

Maximum number of records to return.

=item * email

Only items that were sent to or from an email account specified.

=item * synced

Only items that match the sync flaged that is passed.  [0|1]

=item * userGUID

Only items created from this user.

=item * directoryGUID

Only items referencing this directory record.

=back

=cut

sub queueHistoryArray {
    my ( $self, %paramHash ) = @_;

    #
    # set SQL PH's
    #
    my $whereStatement = '1=1';
    my $limitSQL;
 
    #
    # create sql where and limits
    #
    if ( $paramHash{limit} )          { $limitSQL = ' LIMIT ' . $self->safeSQL( $paramHash{limit} ) }
    if ( $paramHash{email} )          { $whereStatement .= " and (queue_from like '" . $self->safeSQL( $paramHash{email} ) . "' or queue_to like '" . $self->safeSQL( $paramHash{email} ) . "')" }
    if ( $paramHash{userGUID} )       { $whereStatement .= " and profile_guid='" . $self->safeSQL( $paramHash{userGUID} ) . "'" }
    if ( $paramHash{directoryGUID} )  { $whereStatement .= " and directory_guid='" . $self->safeSQL( $paramHash{directoryGUID} ) . "'" }
    if ( $paramHash{synced} )         { $whereStatement .= " and synced='" . $self->safeSQL( $paramHash{synced} ) . "'" }

    my @queueHistoryArray;
    my $arrayRef = $self->runSQL( SQL => "select queue_guid, profile_guid, queue_guid, directory_guid, guid, hash, queue_from, queue_to, type, subject, success, synced, failure_code, response, sent_date, scheduled_date from queue_history where " . $whereStatement . " order by sent_date desc" . $limitSQL );

    while ( @{$arrayRef} ) {
        my %sendHash;
        $sendHash{guidGUID}       = shift @{$arrayRef};
        $sendHash{userGUID}       = shift @{$arrayRef};
        $sendHash{queueGUID}      = shift @{$arrayRef};
        $sendHash{directoryGUID}  = shift @{$arrayRef};
        $sendHash{guid}           = shift @{$arrayRef};
        $sendHash{hash}           = shift @{$arrayRef};
        $sendHash{from}           = shift @{$arrayRef};
        $sendHash{to}             = shift @{$arrayRef};
        $sendHash{type}           = shift @{$arrayRef};
        $sendHash{subject}        = shift @{$arrayRef};
        $sendHash{success}        = shift @{$arrayRef};
        $sendHash{synced}         = shift @{$arrayRef};
        $sendHash{failureCode}    = shift @{$arrayRef};
        $sendHash{response}       = shift @{$arrayRef};
        $sendHash{sentDate}       = shift @{$arrayRef};
        $sendHash{scheduledDate}  = shift @{$arrayRef};
        push @queueHistoryArray, {%sendHash};
    }
    if ( $paramHash{ref} ) { return \@queueHistoryArray }
    return @queueHistoryArray;
}

=head2 queueHistoryHash

Return a hash or reference to the a queue history hash.   History hashes will be referenced by passing a guid key or if present a queueGUID key from the derived queue record it was created from.

=cut;

sub queueHistoryHash {
    my ( $self, %paramHash ) = @_;

    #
    # get the historyHash based on the queueGUID it was dirived from if that what is being used for
    # if not just treat it like any ole hash lookup
    #
    my $whereStatement = "guid='" . $self->safeSQL( $paramHash{guid} ) . "'";
    if ( $paramHash{queueGUID} ) { $whereStatement = "queue_guid='" . $self->safeSQL( $paramHash{queueGUID} ) . "'" }

    #
    # get an array of the all stuff we need,  in a name\value pair format
    #
    my $arrayRef = $self->runSQL( SQL => "select 'hash',hash,'guid',guid,'scheduledDate',scheduled_date,'queueGUID',queue_guid,'from',queue_from,'to',queue_to,'failureCode',failure_code,'body',body,'synced',synced,'success',success,'response',response,'subject',subject,'sentDate',sent_date from queue_history where " . $whereStatement );

    #
    # convert the array
    #
    my %itemHash = @$arrayRef;

    if ( $paramHash{ref} ) { return \%itemHash } 
    return %itemHash;
}


=head2 processQueue

Process the internal sending queue

    #
    # process the internal queue
    #
    $fws->processQueue();

=cut

sub processQueue {
    my ( $self ) = @_;
    #
    # get the queue
    #
    my @queueArray = $self->queueArray();

    #
    # make sure its not a draft, or if the type is 
    # blank and sendmail, then ship it off!
    #
    for my $i (0 .. $#queueArray) {
        if ( !$queueArray[$i]{draft} && ( !$queueArray[$i]{type} || $queueArray[$i]{type} eq 'sendmail')) {
            $queueArray[$i]{fromQueue} = 1;
            $self->send( %{$queueArray[$i]} );
            $self->deleteQueue( %{$queueArray[$i]} );
        }
    }
    return;
}


=head2 runSQL

Return an reference to an array that contains the results of the SQL ran.  In addition if you pass noUpdate => 1 the method will not run updateDatabase on errors.  This is important if you doing something that could create a recursion problem.

    #
    # retrieve a reference to an array of data we asked for
    #
    my $dataArray = $fws->runSQL( SQL => "select id,type from id_and_type_table" );     # Any SQL statement or query

    #
    # loop though the array
    #
    while ( @$dataArray ) {

        #
        # collect the data each row at a time
        #
        my $id      = shift @{$dataArray};
        my $type    = shift @{$dataArray};

        #
        # display or do something with the data
        #
        print "ID: " . $id . " - " . $type . "\n";
    }


=cut

sub runSQL {
    my ( $self, %paramHash ) = @_;

    #
    # Make sure we are connected to the default DBH
    #
    $self->connectDBH();

    #
    # if we pass a DBH lets use it
    #
    $paramHash{DBH} ||= $self->{'_DBH_' . $self->{DBName} . $self->{DBHost}};

    #
    # Get this data array ready to slurp
    # and set the failFlag for future use to autocreate a dB schema
    # based on a default setting
    #
    my @data;

    #
    # send this off to the log
    #
    $self->SQLLog( $paramHash{SQL} );

    #
    # prepare the SQL and loop though the arrays
    #
    my $sth = $paramHash{DBH}->prepare( $paramHash{SQL} );
    if ( $sth ) {

        #
        # ensure errors are turned off and execute
        #
        $sth->{PrintError} = 0;
        $sth->execute();

        #
        # only continue if there is no errors
        # and we are doing something warrents fetching
        #
        if ( !$sth->errstr && $paramHash{SQL} =~ /^[\n\r\s]*(select|desc|show) /is ) {

            #
            # SQL lite gathing and normilization
            #
            if ( $self->{DBType} =~ /^SQLite$/i ) {
                while ( my @row = $sth->fetchrow ) {
                    my @cleanRow;
                    while ( @row ) {
                        my $clean = shift @row;
                        $clean = '' if !defined $clean;
                        $clean =~ s/\\\\/\\/sg;
                        push @cleanRow, $clean;
                    }
                    push @data, @cleanRow;
                }
            }
    
            #
            # Fault to MySQL if we didn't find another type
            #
            else {
                while ( my @row = $sth->fetchrow ) {
                    my @cleanRow;
                    while ( @row ) {
                        my $clean = shift @row;
                        $clean = '' if !defined $clean;
                        push @cleanRow, $clean;
                    }
                    push @data, @cleanRow;
                }
            }
        }
    }

    #
    # if errstr is populated, lets EXPLODE!
    # but not if its fetch without windows 7 will give this genericly when
    # returns without records are passed
    #
    if ( $sth->errstr ){
        $self->FWSLog( 'DB SQL error: ' . $paramHash{SQL} . ': ' . $sth->errstr );

        #
        # run update DB on an error to fix anything that was broke :(
        # if noUpdate is passed lets not do this, so we do recurse!
        #
        if ( !$paramHash{noUpdate} ) { $self->FWSLog( 'DB update ran: ' . $self->updateDatabase() ) }
    }

    #
    # return this back as a normal array
    #
    return \@data;
}

=head2 saveData

Update or create a new data record.  If guid is not provided then a new record will be created.   If you pass "newGUID" as a parameter for a new record, the new guid will not be auto generated, newGUID will be used.

    %dataHash = $fws->saveData( %dataHash );

Required hash keys if the data is new:

=over 4

=item * parent: This is the reference to where the data belongs

=item * name: This is the reference id for the record

=item * type: A valid element type

=back

Not required hash keys:

=over 4

=item * $active: 0 or 1. Default is 0 if not specified

=item * newGUID: If this is a new record, use this guid (Note: There is no internal checking to make sure this is unique)

=item * lang: Two letter language definition. (Not needed for most multi-lingual sites, only if the code has a requirement that it is splitting language based on other criteria in the control)

=item * ... Any other extended data fields you want to save with the data element

=back


Example of adding a data record

    my %paramHash;
    $paramHash{parent}         = $fws->formValue( 'guid' );
    $paramHash{active}         = 1;
    $paramHash{name}           = $fws->formValue( 'name' );
    $paramHash{title}          = $fws->formValue( 'title' );
    $paramHash{type}           = 'site_myElement';
    $paramHash{color}          = 'red';

    %paramHash = $fws->saveData(%paramHash);

Example of adding the same data record to a "data container"

    my %paramHash;
    $paramHash{containerId}    = 'thisReference';
    $paramHash{active}         = 1;
    $paramHash{name}           = $fws->formValue( 'name' );
    $paramHash{type}           = 'site_thisType';
    $paramHash{title}          = $fws->formValue( 'title' );
    $paramHash{color}          = 'red';

    %paramHash = $fws->saveData(%paramHash);

Note: If the containerId does not match or exist, then one will be created in the root of your site, and the data will be added to the new one.

Example of updating a data record:

    $guid = 'someGUIDaaaaabbbbccccc';
 
    #
    # get the original hash
    #
    my %dataHash = $fws->dataHash(guid=>$guid);
 
    #
    # make some changes
    #
    $dataHash{name}     = "New Reference Name";
    $dataHash{color}    = "blue";
 
    #
    # Give the altered hash to the update procedure
    # 
    $fws->saveData( %dataHash );

=cut

sub saveData {
    my ( $self, %paramHash ) = @_;

    #
    # run any pre scripts and return what we were passed
    #
    %paramHash = $self->runScript('preSaveData',%paramHash);

    #
    # if siteGUID is blank, lets set it to the site we are looking at
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # transform the containerId to the parent id
    #
    if ( $paramHash{containerId} ) {
        #
        # if we don't have a container for it already, lets make one!
        #
        ( $paramHash{parent} ) = @{$self->runSQL( SQL => "select guid from data where name='" . $self->safeSQL( $paramHash{containerId} ) . "' and element_type='data' LIMIT 1" )};
        if ( !$paramHash{parent} ) {

            #
            # recursive!!!! but because containerId isn't passed we are good :)
            #
            my %parentHash = $self->saveData( name => $paramHash{containerId}, type => 'data', parent => $self->siteValue( 'homeGUID' ), layout => '0' );

            #
            # set the parent to the new guid
            #
            $paramHash{parent} = $parentHash{guid};
        }

        #
        # get rid of the containerId, and lets continue with a normal update
        #
        delete( $paramHash{containerId} );
    }

    #
    # check to see if its already used;
    #
    my %usedHash = $self->dataHash( guid => $paramHash{guid} );

    #
    # Lets check the "new guid" if there is one, if it matches, this is an update also
    #
    if ( !$usedHash{guid} && !$paramHash{newGUID} ) {
        %usedHash = $self->dataHash( guid => $paramHash{newGUID} );
        if ( $usedHash{guid} ) { $paramHash{guid} = $paramHash{newGUID} }
    }

    #
    # if there is no ID this is an add, else, its really just an updateData
    #
    if ( !$usedHash{guid} ) {
        #
        # set the active to false if its not specified
        #
        if ( !$paramHash{active} ) { $paramHash{active} = '0' }

        #
        # get the intial ID and insert the record
        #
        if ( $paramHash{newGUID} ) { $paramHash{guid} = $paramHash{newGUID} }
        elsif ( !$paramHash{guid} ) { $paramHash{guid} = $self->createGUID( 'd' ) }

        #
        # if title is blank make it the name;
        #
        if ( !$paramHash{title} ) { $paramHash{title} = $paramHash{name} }


        #
        # insert the record
        #
        $self->runSQL( SQL => "insert into data (guid,site_guid,created_date) values ('" . $self->safeSQL( $paramHash{guid} ) . "','" . $self->safeSQL( $paramHash{siteGUID} ) . "','" . $self->formatDate( format => 'SQL' ) . "')");
    }

    #
    # get the next in the org, so it will be at the end of the list
    #
    if ( !$paramHash{ord} ) { 
        ( $paramHash{ord} ) = @{$self->runSQL( SQL => "select max( ord ) + 1 from guid_xref where site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "' and parent='" . $self->safeSQL( $paramHash{parent} ) . "'")};
    }
    
    #
    # if layout is ever blank, set it to main as a default
    #
    $paramHash{layout} ||= 'main';

    #
    # if we are talking a type of page or home, set layout to 0 because it should not be used
    #
    if ( $paramHash{type} eq 'page' || $paramHash{type} eq 'home' ) { 
        $paramHash{layout} = '0';
    }

    #
    # add the xref record if it needs to... BUT!  only pages are aloud to have blank parents, everything else needs a parent
    #
    if ( $paramHash{type} eq 'home' || $paramHash{parent} ) {
        $self->_saveXRef( $paramHash{guid}, $paramHash{layout}, $paramHash{ord}, $paramHash{parent}, $paramHash{siteGUID} );
    }

    #
    # if we are talking about a home page, then we actually need to set this as "page"
    #
    if ( $paramHash{type} eq 'home' ) { $paramHash{type} ='page' }
    
    #
    # now before we added something new we might need a new index, lets reset it for good measure
    #
    $self->setCacheIndex();
	
	#
	# set default to ensure we don't explode with SQL errors from default defs
	#
	$paramHash{showMobile} 		||= 0;
	$paramHash{showLogin} 		||= 0;
	$paramHash{default_element} ||= 0;
	$paramHash{disableTitle} 	||= 0;
	$paramHash{disableEditMode} ||= 0;

    #
    # Save the data minus the extra fields
    #
    $self->runSQL( SQL => "update data set " .
                                "extra_value = ''" .
                                ", show_mobile = '" .       $self->safeSQL( $paramHash{showMobile} ) . "'" .
                                ", show_login = '" .        $self->safeSQL( $paramHash{showLogin} ) . "'" .
                                ", default_element = '" .   $self->safeSQL( $paramHash{default_element} ) . "'" .
                                ", disable_title = '" .     $self->safeSQL( $paramHash{disableTitle} ) . "'" .
                                ", disable_edit_mode = '" . $self->safeSQL( $paramHash{disableEditMode} ) . "'" .
                                ", disable_title = '" .     $self->safeSQL( $paramHash{disableTitle} ) . "'" .
                                ", lang = '" .              $self->safeSQL( $paramHash{lang} ) . "'" .
                                ", friendly_url = '" .      $self->safeSQL( $paramHash{friendlyURL} ) . "'" .
                                ", page_friendly_url = '" . $self->safeSQL( $paramHash{pageFriendlyURL} ) . "'" .
                                ", active = '" .            $self->safeSQL( $paramHash{active} ) . "'" .
                                ", nav_name = '" .          $self->safeSQL( $paramHash{navigationName} ) . "'" .
                                ", name = '" .              $self->safeSQL( $paramHash{name} ) . "'" .
                                ", title = '" .             $self->safeSQL( $paramHash{title} ) . "'" .
                                ", element_type = '" .      $self->safeSQL( $paramHash{type} ) . "' " .
                                "where guid = '" . $self->safeSQL( $paramHash{guid} ) . "' and site_guid = '" . $self->safeSQL( $paramHash{siteGUID}) . "'"
    );

    #
    # loop though and update every one that is diffrent
    #
    for my $key ( keys %paramHash ) {
        if ( $key !~ /^ord|pageIdOfElement|keywordScore|navigationName|showResubscribe|default_element|guid_xref_site_guid|groupId|lang|friendlyURL|pageFriendlyURL|type|guid|siteGUID|newGUID|showMobile|name|element_type|active|title|disableTitle|disableEditMode|defaultElement|showLogin|parent|layout|site_guid$/ ) {
            $self->saveExtra( table => 'data', siteGUID => $paramHash{siteGUID}, guid => $paramHash{guid}, field => $key, value => $paramHash{$key} );
        }
    }

    #
    # update the modified stamp
    #
    $self->updateModifiedDate(%paramHash);

    #
    # update the cache data directly
    #
    $self->updateDataCache(%paramHash);

    #
    # run any post scripts 
    #
    %paramHash = $self->runScript('postSaveData',%paramHash);

    #
    # return anything created in the paramHash that was changed and already present
    #
    return %paramHash;
}


=head2 saveExtra

Save data that is part of the extra hash for a FWS table.

    $self->saveExtra(   
        table       => 'table_name',
        siteGUID    => 'site_guid_not_required',
        guid        => 'some_guid',
        field       => 'table_field',
        value       => 'the value we are setting it to'
    );

=cut

sub saveExtra {
    my ( $self, %paramHash ) = @_;

    #
    # set site GUID if it wasn't passed to us
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # set up the site_sid restriction... but a lot of table types don't use
    #
    my $addToWhere = " and site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "'";
    if ( $self->{dataSchema}{$paramHash{table}}{site_guid}{noSite} ) { $addToWhere = '' }

    #
    # get the hash from the id we are pulling from
    #
    my ( $extraValue ) = @{$self->runSQL( SQL => "select extra_value from " . $self->safeSQL( $paramHash{table} ) . " where guid='" . $self->safeSQL( $paramHash{guid} ) . "'" . $addToWhere )};

    #
    # if crypt password is set, then crypt it up!
    #
    if ( $self->{dataSchema}{$paramHash{table}}{extra_value}{encrypt} ) { $extraValue = $self->FWSDecrypt( $extraValue ) }

    #
    # pull the hash out
    #
    use Storable qw(nfreeze thaw);
    my %extraHash;
    if ( $extraValue ) { %extraHash = %{thaw( $extraValue )} }

    #
    # add the new one
    #
    $extraHash{$paramHash{field}} = $paramHash{value};

    #
    # convert back to a hash string
    #
    my $hash = nfreeze(\%extraHash);

    #
    # encrypt if we are the trans table
    #
    if ( $self->{dataSchema}{$paramHash{table}}{extra_value}{encrypt} ) { $hash = $self->FWSEncrypt( $hash ) }

    #
    # update the hash in the db
    #
    $self->runSQL( SQL => "update " . $self->safeSQL( $paramHash{table} ) . " set extra_value='" . $self->safeSQL( $hash ) . "' where guid='" . $self->safeSQL( $paramHash{guid} ) . "'" . $addToWhere );

    #
    # update the cache table if we are on the data table
    #
    if ( $paramHash{table} eq 'data' ) {

        #
        # pull the data has, update it, then send it to the cache
        #
        $self->updateDataCache( $self->dataHash( guid => $paramHash{guid} ) );
    }
    return;
}


=head2 saveHash

Save a generic hash to a hash object in the same fasion as other FWS save objects.  If the object exists already it will udpate it, or add a new one if it did not exist

    #
    # add a new object
    #
    $someHash{someArray} = $fws->saveHash( hashArray  => $someHash{someArray},
                                           date       => $fws->dateTime( format => 'SQL' ),

    #
    # update a object that contains its perspective guid
    #
    $someHash{someArray} = $fws->saveHash( hashArray  => $someHash{someArray}, %existingDataThatIsUpdated );

=cut

sub saveHash {
    my ( $self, %paramHash ) = @_;

    #
    # get the current array, and clear the loc string
    #
    my @hashArray = $self->hashArray(%paramHash);
    my @newArray;
    my $hashUpdated = 0;

    #
    # lets not keep the refrence to the hashArray itself, that would be nasty if we saved it!
    #
    delete $paramHash{hashArray};

    #
    # go though each one of the shippingLocation items, figure out what one is being updated and update it!
    #
    for my $i (0 .. $#hashArray) {

        #
        # update the loc with the same guid with the new hash
        #
        if ( $paramHash{guid} eq $hashArray[$i]{guid} ) {

            #
            # update the flag, to know we are NOT talking about adding a new one and append to the line
            #
            push @newArray, {%paramHash};
            $hashUpdated = 1;
            }
        #
        # update the loc with the same thing but repackaged (no change was made)
        #
        else { push @newArray, {%{$hashArray[$i]}} }
    }

    #
    # if we dindn't update then this is an add
    #
    if (!$hashUpdated) {
        $paramHash{guid} = $self->createGUID( 'h' );
        push @newArray, {%paramHash};
    }
    return ( nfreeze(\@newArray) );
}


=head2 saveQueue

Save a hash to the process and message queue.

    %queueHash = $fws->saveQueue( %queueHash );

=cut

sub saveQueue {
    my ( $self, %paramHash ) = @_;

    %paramHash = $self->runScript( 'preSaveQueue', %paramHash );

    %paramHash = $self->_recordInit( 
        '_guidLeader'   => 'q',
        '_table'        => 'queue',
        %paramHash,
    );

    %paramHash = $self->_recordSave(
        '_fields'       => 'directory_guid|profile_guid|queue_from|hash|queue_to|from_name|draft|type|subject|digital_assets|transfer_encoding|mime_type|body|scheduled_date',
        '_keys'         => 'directoryGUID|userGUID|from|hash|to|fromName|draft|type|subject|digitalAssets|transferEncoding|mimeType|body|scheduledDate',
        '_table'        => 'queue',
        '_noExtra'      => '1',
        %paramHash,
    );


    %paramHash = $self->runScript('postSaveQueue',%paramHash);

    return %paramHash;
}

=head2 saveQueueHistory

Save a hash to the process and message queue history.

    %queueHash = $fws->saveQueueHistory( %queueHash );

=cut

sub saveQueueHistory {
    my ( $self, %paramHash ) = @_;

    %paramHash = $self->runScript('preSaveQueueHistory',%paramHash);

    #
    # if sent date isn't set,  lets set it to NOW
    #
    if ( !$paramHash{sentDate} || $paramHash{sentDate}  =~ /^0000.00.00/ ) { $paramHash{sentDate} = $self->safeSQL( $self->formatDate( format => "SQL" ) ) }

    %paramHash = $self->_recordInit(
                '_guidLeader'   => 'q',
                '_table'        => 'queue_history',
                %paramHash);

    %paramHash = $self->_recordSave(
                '_fields'       => 'synced|queue_guid|directory_guid|profile_guid|hash|scheduled_date|queue_from|from_name|queue_to|body|type|subject|success|failure_code|response|sent_date',
                '_keys'         => 'synced|queueGUID|directoryGUID|profileGUID|hash|scheduledDate|from|fromName|to|body|type|subject|success|failureCode|response|sentDate',
                '_table'        => 'queue_history',
                '_noExtra'      => '1',
                %paramHash);

    %paramHash = $self->runScript('postSaveQueueHistory',%paramHash);

    return %paramHash;
}


=head2 saveUser

Save a user and return its hash.

    %userHash = $fws->saveUser( %userHash );

=cut

sub saveUser {
    my ( $self, %paramHash ) = @_;
    %paramHash = $self->runScript('preSaveUser',%paramHash);

    if ( !$paramHash{guid} ) {
        #
        # if we are not going to make a duplicate lets rock
        #
        if ( !@{$self->runSQL( SQL => "select 1 from profile where email like '" . $self->safeSQL( $paramHash{email} ) . "' LIMIT 1" )} && $paramHash{email} && $paramHash{password} ) {
            #
            # make sure name will be something
            #
            if ( !$paramHash{name} ) { $paramHash{name} = $paramHash{billingName} }
            if ( !$paramHash{name} ) { $paramHash{name} = $paramHash{shippingName} }

            #
            # if the active is blank or undef lets make it 1
            #
            if ( !defined $paramHash{active} ) {    $paramHash{active} = 1 }
            if ( $paramHash{active} eq '' ) {       $paramHash{active} = 1 }

            #
            # lets match these so the update procedure will treat it like a new update
            #
            $paramHash{passwordConfirm} = $paramHash{password};

            #
            # do the inital insert
            #
            $paramHash{guid} = $self->createGUID('u');
            $self->runSQL( SQL => "insert into profile (guid,email,name,active) values ('" . $paramHash{guid} . "','" .  $self->safeSQL( $paramHash{email} ) . "','" .  $self->safeSQL( $paramHash{name} ) . "','" .  $self->safeSQL( $paramHash{active} ) . "')" );

            #
            # if the profile is new lets send the admin an email
            #
            if ( $self->siteValue('profileCreationEmail') ) {
                $self->send( to => $self->siteValue('profileCreationEmail'), fromName => $self->{email},from => $self->{email}, subject => "New User Created", mimeType => "text/plain", body => 'Name: ' . $paramHash{name} . "\nEmail: " . $paramHash{email} . "\n" );
            }
        }
    }

    #
    # see if the password needs to be updated and one last check to see if its strong enough
    #
    my $insertSQL;
    if ( $paramHash{password} && $paramHash{passwordConfirm} eq $paramHash{password} ) {

        #
        # crypt the password
        #
        $paramHash{password} = $self->cryptPassword( $paramHash{password} );

        #
        # add to the insert statement
        #
        $insertSQL .= ",profile_password='" . $self->safeSQL( $paramHash{password} ) . "'";
    }

    #
    # set the dirived stuff so nobody gets sneeky and tries to pass it to the procedure
    #
    $paramHash{pin} ||= $self->createPin();

    #
    # update the core of the record
    #
    $self->runSQL( SQL => "update profile set fb_id='" . $self->safeSQL( $paramHash{FBId} ) . "',fb_access_token='" . $self->safeSQL( $paramHash{FBAccessToken} ) . "', pin='" . $self->safeSQL( $paramHash{pin} ) . "',active='" . $self->safeSQL( $paramHash{active} ) . "',name='" . $self->safeSQL( $paramHash{name} ) . "' " . $insertSQL . " where guid='" . $paramHash{guid} . "'" );

    #
    # loop though and update every one that is diffrent, but you can't touch for security reasons
    #
    for my $key ( keys %paramHash ) {
        if ( $key !~ /^(FBId|FBAccessToken|googleId|password|passwordConfirm|group|name|guid|active|pin|active|email|profile_password|passwordConfirm|password|site_guid)$/ ) {
            $self->saveExtra( table => 'profile', guid => $paramHash{guid}, field => $key, value => $paramHash{$key} );
        }
    }

    #
    # do a hard reset of the profile so it will load again the next time a proc asks for it
    #
    for ( keys %{$self->{profileHash}} ) { delete $self->{profileHash}->{$_} }

    #
    # Not sure if this is needed, but for consistance, the Update doesn't actually Update the hash so it will return its self unaltered
    #
    %paramHash = $self->runScript( 'postSaveUser', %paramHash );
    return %paramHash;
}


=head2 schemaHash

Return the schema hash for an element.  You can pass either the guid or the element type.

    my %schemaHash = $fws->schemaHash( 'someGUIDorType' );

=cut

sub schemaHash {
    my ( $self, $guid ) = @_;

    #
    # Get it from the element hash, (with caching enabled)
    #
    my %elementHash = $self->elementHash( guid => $guid );

    #
    # make sure schemaHash is defined before we run the code
    #
    my %dataSchema;

    #
    # run the eval and populate the hash (Including the title)
    #
    ## no critic (RequireCheckingReturnValueOfEval ProhibitStringyEval)
    eval $elementHash{schemaDevel};
    ## use critic
    my $errorCode = $@;
    if ( $errorCode ) { $self->FWSLog( 'DB schema error: ' . $guid . ' - ' . $errorCode ) }

    return %dataSchema;
}


=head2 setCacheIndex

Set a sites cache index for its site.  you can bas a siteGUID as a hash parameter if you wish to update the index for a site not currently being rendered.

    $fws->setCacheIndex();

=cut

sub setCacheIndex {
    my ( $self, %paramHash ) = @_;

    #
    # set site GUID if it wasn't passed to us
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    my @indexArray;
    my %elementHash = $self->_fullElementHash();
      for my $elementGUID ( keys %elementHash ) {
        my %schemaHash = $self->schemaHash( $elementGUID );

        #
        #  loop though each one and if the index is set to one, add it to the index list
        #
        for my $key ( keys %schemaHash) {
            if ( $schemaHash{$key}{index} ) { push @indexArray, $key }
        }
    }

    #
    # create a comma delemited list that is the inexed fields
    #
    my $cacheValue = join( ',', @indexArray );

    #
    # update the extra table of what the cacheIndex is
    #
    if ( $self->siteValue( 'dataCacheIndex' ) ne $cacheValue ) {
        $self->FWSLog( "Adding data cache index: ".$cacheValue );
        $self->saveExtra( table => 'site', guid => $paramHash{siteGUID}, field => 'dataCacheIndex', value => $cacheValue );
    }
    return;
}


=head2 sortArray

Return a sorted array reference by passing the array reference, what key to sort by, and numrical or alpha sort.

    #
    # type: alpha|number
    # key: the key you are sorting by
    # array: an array reference
    #
    my $arrayRef = $fws->sortArray( key => 'id', type => 'alpha', array => \@someArray );

=cut

sub sortArray {
    my ( $self, %paramHash ) = @_;
    my @returnArray = @{$paramHash{array}};

    if ( $paramHash{type} eq 'number' ) {
        @returnArray = ( map{$_->[1]} sort {$a->[0] <=> $b->[0]} map{[$_->{$paramHash{key}},$_]} @returnArray )
    }
    else {
        @returnArray = ( map{$_->[1]} sort {$a->[0] cmp $b->[0]} map{[$_->{$paramHash{key}},$_]} @returnArray )
    }
    return \@returnArray;
}

=head2 tableFieldHash

Return a multi-dimensional hash of all the fields in a table with its properties.  This usually isn't used by anything but internal table alteration methods, but it could be useful if you are making conditionals to determine the data structure before adding or changing data.  The method is CPU intensive so it should only be used when performance is not a requirement.

    $tableFieldHashRef = $fws->tableFieldHash( 'the_table' );

The return dump will have the following structure:

    $tableFieldHashRef->{field}{type}
    $tableFieldHashRef->{field}{ord}
    $tableFieldHashRef->{field}{null}
    $tableFieldHashRef->{field}{default}
    $tableFieldHashRef->{field}{extra}

If the field is indexed it will return a unique table field combination key equal to MUL or FULLTEXT:

    $tableFieldHashRef->{thetable_field}{key}

=cut

sub tableFieldHash {
    my ( $self, $table ) = @_;

    #
    # set an order counter so we can sort by this if needed
    #
    my $fieldOrd = 0;

    #
    # if we have a cached version lets make one
    #
    if (!keys %{$self->{'_' . $table . 'FieldCache'}}) {

        #
        # grab the table def hash for mysql
        #
        if ( $self->{DBType} =~ /^mysql$/i ) {
            my $tableData = $self->runSQL( SQL => "desc " . $self->safeSQL( $table ) );
            while ( @$tableData ) {
                $fieldOrd++;
                my $fieldInc                                                            = shift @{$tableData};
                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{type}                 = shift @{$tableData};
                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{ord}                  = $fieldOrd;
                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{null}                 = shift @{$tableData};
                $self->{'_' . $table . 'FieldCache'}->{$table . "_" . $fieldInc}{key}   = shift @{$tableData};
                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{default}              = shift @{$tableData};
                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{extra}                = shift @{$tableData};
            }
        }

        #
        # grab the table def hash for sqlite
        #
        if ( $self->{DBType} =~ /^sqlite$/i ) {
            my $tableData = $self->runSQL( SQL => "PRAGMA table_info(" . $self->safeSQL( $table ) . ")");
            while (@$tableData) {
                $fieldOrd++;
                                   shift @{$tableData};
                my $fieldInc =     shift @{$tableData};
                                   shift @{$tableData};
                                   shift @{$tableData};
                                   shift @{$tableData};

                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{type} =  shift @{$tableData};
                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{ord}  = $fieldOrd;
            }

            $tableData = $self->runSQL( SQL => "PRAGMA index_list(" . $self->safeSQL( $table ) . ")" );
            while (@$tableData) {
                                   shift @{$tableData};
                my $fieldInc =     shift @{$tableData};
                                   shift @{$tableData};

                $self->{'_' . $table . 'FieldCache'}->{$fieldInc}{key} = 'MUL';
            }
        }
    }
    return %{$self->{'_' . $table . 'FieldCache'}};

}

=head2 templateArray

Return a hash array of all the templates available.

=cut

sub templateArray {
    my ( $self ) = @_;
    #
    # Get the Template array
    #
    my $templateArray = $self->runSQL( SQL => "select guid,title,site_guid,template_devel,css_devel,js_devel,default_template from templates where site_guid='" . $self->safeSQL( $self->{siteGUID} ) . "'" );

    my @templateHashArray;
    while (@$templateArray) {
        #
        # create the hash and return it
        #
        my %templateHash;
        $templateHash{guid}       = shift @{$templateArray};
        $templateHash{title}      = shift @{$templateArray};
        $templateHash{siteGUID}   = shift @{$templateArray};
        $templateHash{template}   = shift @{$templateArray};
        $templateHash{css}        = shift @{$templateArray};
        $templateHash{js}         = shift @{$templateArray};
        $templateHash{default}    = shift @{$templateArray};

        push @templateHashArray, {%templateHash};
    }
    return @templateHashArray;
}


=head2 templateHash

Return a hash of all the information about a template.

=cut

sub templateHash {

    my ( $self, %paramHash ) = @_;

    my $pageId          = $paramHash{pageGIUD};

    my $template;
    my $css;
    my $js;
    my $title;

    #
    # get the default template Id
    #
    my ( $defaultGUID ) = @{$self->runSQL( SQL => "select guid from templates where default_template = '1' and site_guid='" . $self->safeSQL( $self->{siteGUID} ) . "'" )};

    #
    # get the home page template ID
    #
    my ( $homePageTemplateId ) = @{$self->runSQL( SQL => "select layout from guid_xref where child='" . $self->safeSQL( $self->homeGUID() ) . "'" )};

    #
    # if this is the home page then set the page id to the actual home page templates ID
    #
    if ( $pageId eq $self->homeGUID() && !$paramHash{templateGUID} ) { $paramHash{templateGUID} = $homePageTemplateId }

    #
    # set some sql defaults
    #
    my $returnFields = 'title, template_devel, css_devel, js_devel, templates.guid';

    #
    # we have a page id, lets see if we can get the template from it. but if the
    # page id was 0 we know that its the home page template id we want not the "0" template id
    #
    if ( $pageId ) {
        ( $title,  $template, $css, $js, $paramHash{templateGUID} ) = @{$self->runSQL( SQL => "select " . $returnFields . " from templates left join guid_xref on layout=templates.guid where guid_xref.child='" . $self->safeSQL( $pageId ) . "' and guid_xref.site_guid='" . $self->safeSQL( $self->{siteGUID} ) . "'" )};
    }

    #
    # we wern't given a page lets grab it from the templateGUID
    #
    elsif ( !$paramHash{templateGUID} ) {
        ( $title, $template, $css, $js, $paramHash{templateGUID} ) = @{$self->runSQL( SQL => "select " . $returnFields . " from templates where guid='" . $self->safeSQL( $paramHash{templateGUID} ) . "'" )};
    }

    #
    # man, this sucks, we didn't find one yet lets get the default one
    #
    if ( !$paramHash{templateGUID} ) {
        ( $title, $template, $css, $js, $paramHash{templateGUID} ) = @{$self->runSQL( SQL => "select " . $returnFields . "  from templates where guid='" . $self->safeSQL( $defaultGUID ) . "'" )};
    }

    #
    # wtf, still didn't get one yet????  lets build out a basic one so the page will render
    #
    if ( !$paramHash{templateGUID} ) {
        $title      = "FWS template";
        $template   = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n".
            "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">\n" .
            "<head>\n" .
            "#FWSHead#" .
            "</head>\n" .
            "<body>\n" .
            "#FWSMenu#" .
            "<div id=\"loc_wrapper\">" .
            "<div id=\"loc\">" .
            "<div id=\"loc_1_wrapper\">" .
            "<div id=\"loc_1\">" .
            "<div id=\"loc_1_1_wrapper\">" .
            "<div id=\"loc_1_1\">#FWSShow-header#</div>" .
            "</div>" .
            "</div>" .
            "</div>" .
            "<div id=\"loc_2_wrapper\">" .
            "<div id=\"loc_2\">" .
            "<div id=\"loc_2_1_wrapper\">" .
            "<div id=\"loc_2_1\">#FWSShow-main#</div>" .
            "</div>" .
            "</div>" .
            "</div>" .
            "<div id=\"loc_3_wrapper\">" .
            "<div id=\"loc_3\">" .
            "<div id=\"loc_3_1_wrapper\">" .
            "<div id=\"loc_3_1\">#FWSShow-footer#</div>" .
            "</div>" .
            "</div>" .
            "</div>" .
            "</div>" .
            "</div>" .
            "<div style=\"clear:both;\"></div>\n" .
            "#FWSJavaLoad#"  . 
            "</body>\n"  . 
            "</html>";
    }


    #
    # create the hash and return it
    #
    my %templateHash;
    $templateHash{guid}           = $paramHash{templateGUID};
    $templateHash{homeGUID}       = $homePageTemplateId;
    $templateHash{title}          = '';
    $templateHash{siteGUID}       = $self->{siteGUID};
    $templateHash{template}       = $template;
    $templateHash{css}            = $css;
    $templateHash{js}             = $js;
    $templateHash{defaultGUID}    = $defaultGUID;

    return %templateHash;
}



=head2 updateDataCache

Update the cache version of the data record.  This is called automatically when saveData is called.

    $fws->updateDataCache(%theDataHash);

=cut

sub updateDataCache {
    my ( $self, %dataHash ) = @_;

    #
    # get the field hash so we don't have to try to add fields that might not be there EVERY time
    #
    my %tableFieldHash = $self->tableFieldHash( 'data_cache' );

    #
    # set the page id of the guid for easy access on search pages
    #
    $dataHash{pageIdOfElement} = $self->_setPageGUID( guid => $dataHash{guid} );
    
    #
    # get the page hash of the page, and update the page description to the data for easy access on search pages
    #
    my %pageHash = $self->dataHash( guid => $dataHash{pageIdOfElement} );
    $dataHash{pageDescription} = $pageHash{pageDescription};

    #
    # get what fields we are aloud to use
    #
    my %dataCacheFields = %{$self->{dataCacheFields}};

    #
    # we will be building these up while we loop
    #
    my $fields;
    my $values;

    #
    # make any fields that "might" be needed
    #
    foreach my $key ( keys %dataHash ) {
        if ( $dataCacheFields{$key} || $key =~ /^(site_guid|guid|name|title|pageIdOfElement|pageDescription)$/ ) {

            #
            # if the type is blank, then this is new
            #
            if ( !$tableFieldHash{$key}{type} ) {
                #
                # alter tha table
                #
                $self->alterTable( table => 'data_cache', field => $key, type => 'text', key => 'FULLTEXT', default => '' );
            }



            #
            # append the new data to the strings we are using to create the insert statement
            #
            $fields .= $self->safeSQL( $key ) . ',';
            $values .= "'" . $self->safeSQL( $dataHash{$key} ) . "',";
        }
    }

    #
    # clean up the commas at the end of values and fields
    #
    $fields =~ s/,$//sg;
    $values =~ s/,$//sg;

    #
    # remove the one that "might" be there
    #
    $self->runSQL( SQL => "delete from data_cache where guid='" . $self->safeSQL( $dataHash{guid} )."'" );

    #
    # add the the new one
    #
    $self->runSQL( SQL => "insert into data_cache (" . $fields . ") values (" . $values . ")" );

    return;
}

=head2 userArray

Return an array or reference to an array of the users on an installation.    You can pass the keywords parameter and it will look though name and email address.

=cut

sub userArray {
    my ( $self, %paramHash ) = @_;
    my @userHashArray;

    #
    # add keyword Search
    #
    my $whereStatement;
    my $keywordsSQL = $self->_getKeywordSQL( $paramHash{keywords}, "name", "email", "extra_value" );
    if ( $keywordsSQL ) { $whereStatement = 'where ' . $keywordsSQL };

    #
    # get the data from the database and push it into the hash array
    #
    my $userArray = $self->runSQL( SQL => "select fb_id,fb_access_token,name,email,guid,active,extra_value from profile " . $whereStatement );
    while ( @$userArray ) {
        #
        # fill in the hash
        #
        my %userHash;
        $userHash{FBId}           = shift @{$userArray};
        $userHash{FBAccessToken}  = shift @{$userArray};
        $userHash{name}           = $self->removeHTML( shift @{$userArray} );
        $userHash{email}          = shift @{$userArray};
        $userHash{guid}           = shift @{$userArray};
        $userHash{active}         = shift @{$userArray};

        #
        # add the extra stuff to the hash
        #
        my $extra_value = shift @{$userArray};
        %userHash       = $self->mergeExtra( $extra_value, %userHash );

        #
        # push it into the array
        #
        push @userHashArray, {%userHash};
    }
    if ( $paramHash{ref} ) { return \@userHashArray }
    return @userHashArray;
}


=head2 userHash

Return the hash for a user.

    %userHash = $fws->userHash( guid => 'guid' );

=cut

sub userHash {
    my ( $self, %paramHash ) = @_;

    #
    # store the guid in this, till we figure out what one we are looking up
    #
    my $lookupGUID;
    my $lookupSQL;

    #
    # if user isn't logged in and we are not passing anything just return - nothing to see here
    #
    if ( !keys %paramHash && !$self->isUserLoggedIn() ) { return }
    #
    # if we have a pin lets do the lookup that way and skip the rest of this crap that is amix of old and new
    # but make sure we set the lookupGUID to something so we don't do any caching and treat it as disposable
    #
    elsif ( $paramHash{pin} ) { $lookupGUID = '_'; $lookupSQL = "pin like '" . $self->safeSQL( $paramHash{pin} ) . "'" }
    else {

        #
        #
        # do some fanageling for old code to see if it is being called the old way, or the new way
        #
        if ( $paramHash{guid} ) { $lookupGUID = $paramHash{guid} }

        #
        # if guid isn't defined, then set it to the email address, or the only thing passed
        #
        elsif ( !$paramHash{email} ) { $lookupGUID = each %paramHash } else { $lookupGUID = $paramHash{email} }

        #
        # if its still blank after that, then we are talking about looking up the guy who is logged in currently
        #
        if ( !$lookupGUID ) { $lookupSQL = "email like '" . $self->safeSQL( $self->{userLoginId} ) . "'" }

        #
        # if the lookupGUID has an @ in it, then look up the guid - least efficient but old stuff still looks for stuff this way
        #
        elsif ( $lookupGUID =~ /@/ ) { $lookupSQL = "email like '" . $self->safeSQL( $lookupGUID ) . "'" }

        #
        # if it doesn't have a @ in it, then we must have a guid to work with, lets find that
        #
        else { $lookupSQL = "guid='" . $self->safeSQL( $lookupGUID ) . "'" }

    }

    #
    # create a new variable but leave it blank unless we are using a persistant one
    #
    my %userHash;

    #
    # if your not logged in.. lets skip this  But, if we are looking for one thing - then lets do it
    #
    if ( $self->isUserLoggedIn() || $lookupGUID ) {

        #
        # the profile hash is not disposable see if we already have it if we do, just populate it from the cached
        # version because this is the current guy logged in
        #
        if ( !$lookupGUID ) { %userHash = %{$self->{profileHash}} }

        #
        # see if it is populated,  if it is, skip this and return it.
        #
        if ( !keys %userHash ) {

            #
            # get the goods from the profile table and grab the ID from the front,
            # so we can use it to get the profile;
            #
            my @profileExtArray     = @{$self->runSQL( SQL => "select profile.extra_value, profile.guid, 'pin', profile.pin, 'guid', profile.guid, 'googleId', profile.google_id, 'name', profile.name, 'FBId', fb_id, 'FBAccessToken', fb_access_token, 'email', profile.email, 'active', profile.active from profile where " . $lookupSQL )};
            my $extraValue          = shift @profileExtArray;
            my $guid                = shift @profileExtArray;

            #
            # convert it into the hash
            #
            %userHash = @profileExtArray;

            #
            # add extra Hash
            #
            %userHash = $self->mergeExtra( $extraValue, %userHash );

            #
            # add all the groups I have access too
            #
            my @groups = @{$self->runSQL( SQL => "select profile_groups_xref.groups_guid from profile left join profile_groups_xref on profile_groups_xref.profile_guid = profile.guid where profile.guid = '" . $self->safeSQL( $guid ) . "'" )};
            while (@groups) {
                $userHash{group}{ shift @groups } = 1;
            }

            #
            # if not logged or we are not looking for a particular guid that is disposable
            # set the id to 0 and active to 0 and destroy what we have
            #
            if ( !$self->isUserLoggedIn() && !$lookupGUID ) {
                for ( keys %{$self->{profileHash}} ) { delete $self->{profileHash}->{$_} }
                $userHash{guid}    = '';
                $userHash{active}  = '0';
            }

            #
            # set the default for radio buttons
            #
            $userHash{active} ||= 0;

            #
            # if are a disposable record, don't save it as the profile hash, just return it
            #
            if ( !$lookupGUID ) { %{$self->{profileHash}} = %userHash }
        }
    }

    #
    # make sure nobody is putting anything dangrous in the user name
    #
    $userHash{name} = $self->removeHTML( $userHash{name} );

    return %userHash;
}


=head2 userGroupHash

Return the hash for a user group by passing the groups guid.

    %userGroupHash = $fws->userGroupHash('somegroupguid');

=cut

sub userGroupHash {
    my ( $self, $guid ) = @_;
    my ( $name, $description ) = @{$self->runSQL( SQL => "select name,description from groups where guid='" . $self->safeSQL( $guid ) . "'" )};
    my %userGroupHash;
    $userGroupHash{name}          = $name;
    $userGroupHash{description}   = $description;
    $userGroupHash{guid}          = $guid;

    #
    # get a list of users and add that to the hash
    #
    my @userList = @{$self->runSQL( SQL => "select profile_guid from profile_groups_xref where groups_guid='" . $self->safeSQL( $guid ) . "'" )};
    while (@userList) {
        my $userId = shift @userList;
        $userGroupHash{user}{$userId} = '1';
    }

    return %userGroupHash;
}


=head2 userGroupArray

Return the hash array for all of the user groups;

    my @userGroupArray = $fws->userGroupArray();

=cut

sub userGroupArray {
    my ( $self ) = @_;
    my @userGroupHashArray;

    #
    # get the data from the database and push it into the hash array
    #
    my @userGroupArray = @{$self->runSQL( SQL => "select name,description,guid from groups" )};
    while (@userGroupArray) {

        #
        # fill in the hash
        #
        my %userGroupHash;
        $userGroupHash{name}          = shift @userGroupArray;
        $userGroupHash{description}   = shift @userGroupArray;
        $userGroupHash{guid}          = shift @userGroupArray;

        #
        # push it into the array
        #
        push @userGroupHashArray, {%userGroupHash};
    }
    return @userGroupHashArray;
}


=head2 updateDatabase

Alter the database to match the schema for FWS 2.   The return will print the SQL statements used to adjust the tables.

    print $fws->updateDatabase()."\n";

This method is automatically called when on the web optimized version of FWS when rendering the 'System' screen.  This will also auto trigger a flag to only it allow it to execute once so it doesn't recurse itself.

=cut

sub updateDatabase {
    my ( $self ) = @_;

    #
    # our passback for what we did
    #
    my $dbResponse;
    
    #
    # make sure I didn't do this yet
    #
    if ( !$self->{upadateDatabaseRan} ) { 
        
        #
        # loop though the records and make or update the tables
        #
        for my $table ( keys %{$self->{dataSchema}} ) {

            for my $field ( keys %{$self->{dataSchema}{$table}} ) {
    
                my $type        = $self->{dataSchema}{$table}{$field}{type};
                my $key         = $self->{dataSchema}{$table}{$field}{key};
                my $default     = $self->{dataSchema}{$table}{$field}{default};
    
                #
                # make sure this isn't a bad record.   It at least needs a table name
                #
                if ( $table ) { $dbResponse .= $self->alterTable( table => $table, field => $field, type => $type, key => $key, default => $default ) }
            }
        }
    }
        
    $self->{upadateDatabaseRan} = 1; 
    return $dbResponse;
}


=head2 updateModifiedDate

Update the modified date of the page a dataHash element resides on.

    $fws->updateModifiedDate(%dataHash);

Note: By updating anything that is persistant against multiple pages all pages will have thier date updated as it is considered a site wide change.

=cut

sub updateModifiedDate {
    my ( $self, %paramHash ) = @_;

    #
    # it is default or not
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # set the type to page if the id itself is a page
    #
    my ( $type ) = @{$self->runSQL( SQL => "select element_type from data where guid='" . $self->safeSQL( $paramHash{guid} ) . "' and site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "'" )};

    #
    # if its not page loop though till it finds what page its on
    #
    my $isDefault   = 0;
    my $recurCap    = 0;
    while ( $paramHash{guid} && ( $type ne 'page' || $type ne 'home' ) && $recurCap < 100 ) {
        my ( $defaultElement ) = @{$self->runSQL( SQL => "select default_element from data where guid='" . $self->safeSQL( $paramHash{guid} ) . "' and site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "'" )};
        ( $paramHash{guid}, $type ) = @{$self->runSQL( SQL => "select parent,data.element_type from guid_xref left join data on data.guid=parent where child='" . $self->safeSQL( $paramHash{guid} ) . "' and guid_xref.site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "'")};
        if ( !$isDefault && $defaultElement ) { $isDefault = 1 }
        $recurCap++;
    }

    #
    # if id is blank that means we are updating a home page element
    #
    if ( !$type || $isDefault > 0 || $isDefault < 0) {
        $self->saveExtra( table => 'data', siteGUID => $paramHash{siteGUID}, field => 'dateUpdated', value => time );
    }

    #
    # if is default then update ALL pages
    #
    if ( $isDefault ) {
        $self->saveExtra( table => 'data', siteGUID => $paramHash{siteGUID}, field => 'dateUpdated', value => time );
        my @pageList = @{$self->runSQL( SQL => "select guid from data where data.site_guid='" . $self->safeSQL( $paramHash{siteGUID} ) . "' and (data.element_type='page' or data.element_type='home')" )};
        while ( @pageList ) {
            my $pageId = shift @pageList;
            $self->saveExtra( table => 'data', siteGUID => $paramHash{siteGUID}, guid => $pageId, field => 'dateUpdated', value => time );
        }
    }

    #
    # if the type is page, then just update that page
    #
    if ( $type eq 'page' || $type eq 'home' ) {
        $self->saveExtra( table => 'data', siteGUID => $paramHash{siteGUID}, guid => $paramHash{guid}, field => 'dateUpdated', value => time );
    }
    return;
}


=head2 homeGUID

Return the guid for the home page.  Without any paramanters it will return the home page guid for the current site.

=cut

sub homeGUID {
    my ( $self, $site_guid ) = @_;

    #
    # blindly get the homeGUID of site that isn't our own potently
    #
    if ( $site_guid ) {
        my ( $homeGUID ) = @{$self->runSQL( SQL => "select home_guid from site where guid='" . $self->safeSQL( $site_guid ) . "'" )};
        return $homeGUID;
    }

    #
    # if is not set, set it and create the page
    #
    return $self->siteValue('homeGUID');
}


=head2 randomizeArray

need doc

=cut

sub randomizeArray {
    my ( $self, $dataRef ) = @_;
    my $i = @$dataRef;
    while ( $i-- ) {
        my $j = int rand ( $i + 1 );
        @$dataRef[$i,$j] = @$dataRef[$j,$i];
    }
    return $dataRef;
}


=head2 sortDataByAlpha

need doc

=cut

sub sortDataByAlpha {
    my ( $self, $sortId, @data ) = @_;
    return ( map{$_->[1]} sort {$a->[0] cmp $b->[0]} map{[$_->{$sortId},$_]} @data )
}


=head2 sortDataByNumber

need doc

=cut

sub sortDataByNumber {
    my ( $self, $sortId, @data ) = @_;
    return (map{$_->[1]} sort {$a->[0] <=> $b->[0]} map{[$_->{$sortId},$_]} @data)
}



#
# Set the data records current parent.  If more than one
# parent, one will be chosen at random
#
sub _setPageGUID {
    my ( $self, %paramHash ) =@_;

    my $guid    = $paramHash{guid};
    my $depth   = $paramHash{depth};

    #
    # hang on to this so we can do a DB update to this
    #
    my $updateGUID = $guid;

    #
    # set the depth to how far you will look before giving up
    #
    $depth ||= 10;

    #
    # set the cap counter
    #
    my $recurCap = 0;

    #
    # get the inital type
    #
    my $pageGUID = 0;
    my ( $type ) = @{$self->runSQL(  SQL => "select element_type from data where guid='" . $self->safeSQL( $guid ) . "'" )};

    #
    # recursivly head down till you get "page" or "" as refrence.
    #
    while ( $type ne 'page' && $type ne 'home' && $guid ) {
        my @idsAndTypes = @{$self->runSQL( SQL => "select parent,element_type from guid_xref left join data on data.guid=parent where child='" . $self->safeSQL( $guid ) . "'" )};
        while (@idsAndTypes) {
            $guid           = shift @idsAndTypes;
            my $listType    = shift @idsAndTypes;
            if ( $listType eq 'page' ) {
                $pageGUID = $guid;
                $type = 'page';
            }
        }

        #
        # give up after 5 
        #
        if ( $recurCap > 5 ) { $type = 'page'; $pageGUID = 0 }
        $recurCap++;
    }

    #
    # set the data record
    #
    $self->runSQL( SQL => "update data set page_guid='". $self->safeSQL( $pageGUID ) . "' where guid='" . $self->safeSQL( $updateGUID ) . "'" );

    return $pageGUID;
}


#
# remove all the data orphaned by a delete
#
sub _deleteOrphanedData {
    my ( $self, $table, $field, $refTable, $refField, $extraWhere, $DBH ) = @_;

    #
    # get the vars set for pre-processing
    #
    my $keepDeleting = 1;

    #
    # keep looping till either we are endless or
    #
    while ( $keepDeleting ) {

        #
        # create the SQL that will be used for the delete and the reflective query
        #
        my $fromSQL = "from " . $table . " where " . $table . " . " . $field . " in (select " . $field . " from (select distinct " . $table . "." . $field . " from " . $table . " left join " . $refTable . " on " . $refTable . "." . $refField . " = " . $table . "." . $field . " where " . $refTable . "." . $refField . " is null ".$extraWhere.") as delete_list)";

        #
        # do the actual delete
        #
        $self->runSQL( DBH => $DBH, SQL => "delete " . $fromSQL );

        #
        # if we are talking about the data field, lets do the same thing to the data cache table
        #
        if ( $table eq 'data' ) {
            $self->runSQL( DBH => $DBH, SQL => "delete from " . $table . "_cache where " . $table . "_cache . " . $field . " in (select " . $field . " from (select distinct " . $table . "_cache." . $field . " from " . $table . "_cache left join " . $refTable . " on " . $refTable . "." . $refField . " = " . $table . "_cache." . $field . " where " . $refTable . "." . $refField . " is null " . $extraWhere . ") as delete_list)" );
        }

        #
        # run the same fromSQL and see if anything is left
        #
        ( $keepDeleting ) = @{$self->runSQL( DBH => $DBH, SQL => "select 1 " . $fromSQL )};
    }

    return;
}


#
# Delete a guid XRef
#
sub _deleteXRef {
    my ( $self, $child, $parent, $siteGUID ) = @_;
    return $self->runSQL( SQL => "delete from guid_xref where child='" . $self->safeSQL( $child ) . "' and parent='" . $self->safeSQL( $parent ) . "' and site_guid='" . $self->safeSQL( $siteGUID ) . "'");
}


#
# Lookup all the elements and return the hash
# This does NOT pull back schema and scripts.  This is for lean element lookups
#
sub _fullElementHash {
    my ( $self, %paramHash ) = @_;

    if ( !keys %{$self->{_fullElementHashCache}} ) {

        #
        # if your in an admin page, you will need this so you can see the stuff in scope for the tree views
        # it doesn't matter if it caches it, because these are ajax calls limited only to themselves
        #

        #
        # get the elementArray
        #
        my $elementArray = $self->runSQL( SQL => "select guid, plugin, type, class_prefix, css_devel, js_devel, title, tags, parent, ord, site_guid, root_element, public, checkedout from element" );

        #
        # Push the elementHash into the Cache
        #
        %{$self->{_fullElementHashCache}} = %{$self->{elementHash}};


        while ( @{$elementArray} ) {
            my $guid                                                = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{guid}           = $guid;
            $self->{_fullElementHashCache}->{$guid}{plugin}         = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{type}           = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{classPrefix}    = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{cssDevel}       = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{jsDevel}        = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{title}          = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{tags}           = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{parent}         = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{ord}            = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{siteGUID}       = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{rootElement}    = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{public}         = shift @{$elementArray};
            $self->{_fullElementHashCache}->{$guid}{checkedout}     = shift @{$elementArray};
        }

        #
        # Do alpha sorting and add parent refernces if needed
        #
        my $alphaOrd = 0;
        for my $guid ( sort { $self->{_fullElementHashCache}->{$a}{title} cmp $self->{_fullElementHashCache}->{$b}{title} } keys %{$self->{_fullElementHashCache}}) {
            $alphaOrd++;
            $self->{_fullElementHashCache}->{$guid}{alphaOrd} = $alphaOrd;
            my $type = $self->{_fullElementHashCache}->{$guid}{type};

            if ( $type ) {
                $self->{_fullElementHashCache}->{$type}{guid}       = $guid;
                $self->{_fullElementHashCache}->{$type}{parent}     = $self->{_fullElementHashCache}->{$guid}{parent};
            }
        }
    }
    return %{$self->{_fullElementHashCache}};
}


#
# creation of a record if needed, and also set pins and guids
#
sub _recordInit {
    my ( $self, %paramHash ) = @_;

    #
    # lets make sure we are not updateing the same record or adding a new one we shouldn't
    #
    if ( !$paramHash{guid} ) {

        #
        # set the dirived stuff so nobody gets sneeky and tries to pass it to the procedure
        #
        $paramHash{siteGUID}    ||= $self->{siteGUID};
        $paramHash{_guidLeader} ||= 'r';
        $paramHash{siteGUID}    = $self->safeSQL( $paramHash{siteGUID} );
        $paramHash{guid}        = $self->createGUID( $paramHash{_guidLeader} );

        #
        # if newGUID is set, lets use that as the guid
        #
        if ( $paramHash{newGUID} ) {
            $paramHash{guid} = $paramHash{newGUID};
        }

        $self->runSQL( DBH => $paramHash{DBH}, SQL => "insert into " . $self->safeSQL( $paramHash{_table} ) . " (guid,site_guid,created_date) values ('" . $self->safeSQL( $paramHash{guid} ) . "','" . $self->safeSQL( $paramHash{siteGUID} ) . "','" . $self->formatDate( format => 'SQL' ) . "')" );


        #
        # Global pin support, if you have a pin field, but its not populated, populate it.
        #
        if ( !$paramHash{pin} && $self->{dataSchema}{$paramHash{_table}}{pin}{type} ) {
    
            #
            # set the dirived stuff so nobody gets sneeky and tries to pass it to the procedure
            #
            $paramHash{pin} = $self->createPin();
            $self->runSQL( DBH => $paramHash{DBH}, SQL => "update " . $self->safeSQL( $paramHash{_table} ) . " set pin='" . $self->safeSQL( $paramHash{pin} ) . "' where guid='" . $self->safeSQL( $paramHash{guid} ) . "'" );
        }
    }
    return %paramHash;
}


#
# return a generic record hash
# Pass: table, where
#
sub _recordHash {
    my ( $self, %paramHash ) = @_;

    #
    # eat 's in table for safety
    #
    $paramHash{table} =~ s/'//sg;

    #
    # define the SQL starter statement
    #
    my $SQL = "select ";

    #
    # if fields was not passed, we assume we have matching field and keys based on the schema
    #
    for my $field ( keys %{$self->{dataSchema}{$paramHash{table}}} ) {
        if ( $self->{dataSchema}{$paramHash{table}}{$field}{name} ) {
            # for safety lets eat any tic in the field name
            $field =~ s/'//sg;
            $SQL .= "'" . $self->safeSQL( $self->{dataSchema}{$paramHash{table}}{$field}{name} ) . "'," . $field . ",";
        }
    }
    $SQL =~ s/,$//sg;

    #
    # do extra value if this table has one
    #
    if ( $self->{dataSchema}{$paramHash{_table}}{extra_value}{type} ) { $SQL .= ',extra_value' }

    #
    # get the hash
    #
    my @returnArray = @{$self->runSQL( DBH => $paramHash{DBH}, SQL => $SQL . " from " . $paramHash{table} . " where " . $paramHash{where} )};

    #
    # pop off the ext values
    #
    if ( $self->{dataSchema}{$paramHash{_table}}{extra_value}{type} ) {
        my $extraValue = pop( @returnArray );
        return $self->mergeExtra( $extraValue, @returnArray );
    }

    #
    # if no ext value, then return the whole thing
    #
    return @returnArray;
}


#
# save a record with generic record structure
#
sub _recordSave {
    my ( $self, %paramHash ) = @_;

    #
    # for completeness lets hold on to this so we can return it
    #
    my %paramHolder = %paramHash;

    #
    # define the SQL starter statement
    #
    my $SQL = "update ".$self->safeSQL( $paramHash{_table} )." set ";

    #
    # if fields was not passed, we assume we have matching field and keys based on the schema
    #
    if ( !$paramHash{_keys} || !$paramHash{_fields} ) {
        for my $field ( keys %{$self->{dataSchema}{$paramHash{_table}}} ) {
            if ( $self->{dataSchema}{$paramHash{_table}}{$field}{save} ) {
                $paramHash{_keys}     .= $self->{dataSchema}{$paramHash{_table}}{$field}{name} . '|';
                $paramHash{_fields}   .= $field . '|';
            }
        }
        $paramHash{_keys} =~ s/\|$//sg;
        $paramHash{_fields} =~ s/\|$//sg;
    }

    #
    # make arrays usable
    #
    my @fields     = split( /\|/, $paramHash{_fields} );
    my @fieldKeys  = split( /\|/, $paramHash{_keys} );

    #
    # add each field thats a core field
    #
    for my $i ( 0 .. $#fields ) {
        $SQL .= $fields[$i] . "='" . $self->safeSQL( $paramHash{$fieldKeys[$i]} ) . "'," ;
        #
        # for the next step delete the keys that should not be updated
        #
        delete $paramHash{$fieldKeys[$i]};
    }

    #
    # trim off last ,
    #
    $SQL =~ s/,$//sg;

    #
    # default key is guid
    #
    $paramHash{keyField}    ||= 'guid';
    $paramHash{keyValueKey} ||= 'guid';

    #
    # add scope to the statement
    #
    $SQL .= " where " . $self->safeSQL( $paramHash{keyField} ) . "='" . $self->safeSQL( $paramHash{$paramHash{keyValueKey}} ) . "'";

    $self->runSQL( DBH => $paramHash{DBH}, SQL => $SQL );

    #
    # save the keys in the ext field;
    #
    my $keyReg = $paramHash{_keys};
    for my $key ( keys %paramHash ) {
        if ( $key !~ /^_/ && $key !~ /^(guid|site_guid|created_date|createdDate|siteGUID|pin)$/ ) {
            if ( $self->{dataSchema}{$paramHash{_table}}{extra_value}{type} ) {
                $self->saveExtra( DBH => $paramHash{DBH}, table => $paramHash{_table}, guid => $paramHash{guid}, field => $key, value => $paramHash{$key} );
            }
        }
    }
    return %paramHolder;
}


#
# Pass keywords and field list, and create a wellformed where statement for keyword
# searches
#
sub _getKeywordSQL {
    my ( $self, $keywords, @likeFields ) = @_;
    #
    # Grab everything that is in quotes
    #
    my @exactMatches;
    while ( $keywords =~ /"/ ) {
        $keywords =~ /(".*?")/g;
        my $currentMatch = $1;
        $keywords =~ s/$currentMatch//g;
        $currentMatch =~ s/"//g;
        push @exactMatches, $currentMatch;
    }

    #
    # split them up and add the exact matches
    #
    my @keywordsSplit = split( ' ', $keywords );
    push @keywordsSplit, @exactMatches;

    #
    # build the SQL
    #
    my $keywordSQL;
    foreach my $keyword ( @keywordsSplit ) {
        if ( $keyword ) {
            my $fieldSQL;
            foreach my $likeField ( @likeFields ) {
                $fieldSQL .=    $self->safeSQL( $likeField ) . " LIKE '%".
                                $self->safeSQL( $keyword ) . "%' or ";
            }
            $fieldSQL =~ s/ or $//sg;
            if ( $fieldSQL ) { $keywordSQL .= "( " . $fieldSQL . " ) and " }
        }
    }

    #
    # kILL THE last and and then wrap it in parans so it will fit will in sql statements
    #
    $keywordSQL =~ s/\s*and\s*$//sg;
    return $keywordSQL;
}


#
# Save a guid XRef
#
sub _saveXRef {
    my ( $self, $child, $layout, $ord, $parent, $siteGUID ) = @_;

	#
	# set defaults to ensure the insert dosen't fail
	#
	$ord ||= 0;
	
    #
    # delete the old one if its there
    #
    $self->_deleteXRef( $child, $parent, $siteGUID );
	
    #
    # add the new one
    #
    return $self->runSQL( SQL => "insert into guid_xref (child,layout,ord,parent,site_guid) values ('" . $self->safeSQL( $child ) . "','" . $self->safeSQL( $layout ) . "','" . $self->safeSQL( $ord ) . "','".$self->safeSQL( $parent ) . "','" . $self->safeSQL( $siteGUID ) . "')" );
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Database


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Database
