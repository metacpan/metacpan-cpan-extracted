package FWS::V2::File;

use 5.006;
use strict;


=head1 NAME

FWS::V2::File - Framework Sites version 2 text and image file methods

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;

    my $fws = FWS::V2->new();

    #
    # retrieve a reference to an array of data we asked for
    #
    my $fileArrayRef = $fws->fileArray( directory   => "/home/directory" );



=head1 DESCRIPTION

Framework Sites version 2 file writing, reading and manipulation methods.

=head1 METHODS


=head2 backupFWS

Create a backup of the filesSecurePath, filesPath and the database and place it under the filesSecurePath backups directory.  The file names will be date keyed and be processed by the restoreFWS method by they keyed date string.  This will exclude any table that has the word 'session' in it, or anything that starts with 'admin_'.

Parameters:
    id: file name of files - the date string in numbers will be used if no id is passed
    excludeTables: Comma delimited list of tables you do not want to back up
    excludeFiles: Do not backup the FWS web accessable files
    minMode: Only backup anything that HAS to be there, no core, no js and css backup files.
    excludeSiteFiles: Backup site files related to plugins and the fws instance, but not the once related to the site
    excludeSecureFiles: Do not backup the secure files

Usage:
    $fws->backupFWS(%params);

Inside of the go.pl if you add certain site wide paramaters it will alter the behaviour of the backup"

    $fws->{FWSBackupExcludeTables} = 'notThisSiteTableThatsSpecial,orThisOne';

=cut

sub backupFWS {
    my ( $self, %paramHash ) = @_;

    #
    # set or use the default id
    #
    $paramHash{id} ||= $self->formatDate( format => 'number' );

    #
    # build inital directories where this will be stored
    #
    my $backupDir   = $self->{fileSecurePath} . '/backups';
    my $backupFile  = $backupDir . '/' . $paramHash{id};
    $self->makeDir( $backupDir );

    #
    # turn the exclude table into a ha to compare against
    #
    my %excludeTables;
    map { $excludeTables{$_} = 1 } split ( ',', $paramHash{excludeTables} );

    #
    # Dump the database
    #
    open ( my $SQLFILE, '>', $backupFile . '.sql' );
    my $tables = $self->runSQL( SQL => 'SHOW TABLES' );
    while ( @$tables ) {
        my $table = shift( @$tables );
        if ( $table !~ /session/ && $table !~ /^admin_/ && !$excludeTables{$table} ) {
            print $SQLFILE 'DROP TABLE IF EXISTS ' . $self->safeSQL( $table ) . ';' . "\n";
            print $SQLFILE $self->{'_DBH_' . $self->{DBName} . $self->{DBHost} }->selectall_arrayref( 'SHOW CREATE TABLE ' . $self->safeSQL( $table ) )->[0][1] . ';' . "\n";
            my $sth = $self->{'_DBH_' . $self->{DBName} . $self->{DBHost} }->prepare( 'SELECT * FROM ' . $table );
            $sth->execute();
            while ( my @data = $sth->fetchrow_array() ) {
                map ( $_ = "'" . $self->safeSQL( $_ ) . "'", @data );
                map ( $_ =~ s/\0/\\0/sg, @data );
                map ( $_ =~ s/\n/\\n/sg, @data );
                print $SQLFILE 'INSERT INTO ' . $table . ' VALUES (' . join( ',', @data ) . ');' . "\n";
            }
        }
    }
    close $SQLFILE;

    if ( !$paramHash{excludeFiles} ) {
        if ( !$paramHash{excludeSiteFiles} ) {
               $self->packDirectory( minMode => $paramHash{minMode}, fileName => $backupFile . '.files', directory => $self->{filePath} );
        }
        else {
               $self->packDirectory( minMode => $paramHash{minMode}, directoryList => '/fws,/plugins', fileName => $backupFile . '.files', directory => $self->{filePath} );
        }
    }

    if ( !$paramHash{excludeSecureFiles} && !$paramHash{minMode} ) {
        $self->packDirectory( minMode => $paramHash{minMode}, fileName => $backupFile . '.secureFiles', directory => $self->{fileSecurePath}, baseDirectory => $self->{fileSecurePath} );
    }

    return $paramHash{id};
}


=head2 restoreFWS

Restore a backup created by backupFWS.  This will overwrite the files in place that are the same, and will replace all database tables with the one from the restore that are restored.   All tables, and files not part of the restore will be left untouched.

    $fws->restoreFWS( id => 'someID' );

=cut

sub restoreFWS {
    my ( $self, %paramHash ) = @_;

    $self->FWSLog( 'Restore started: ' . $paramHash{id} );

    my $restoreFile = $self->{fileSecurePath} . '/backups/' . $paramHash{id};
    $self->unpackDirectory( fileName => $restoreFile . '.files',       directory => $self->{filePath} );
    $self->unpackDirectory( fileName => $restoreFile . '.secureFiles', directory => $self->{fileSecurePath} );

    my $sqlFile = $self->{fileSecurePath} . '/backups/' . $paramHash{id} . '.sql';
    open ( my $SQLFILE, '<', $sqlFile )  || $self->FWSLog( 'Could not read file: ' . $sqlFile );
    my $statement;
    my $endTest;
    while ( <$SQLFILE> ) {
        $statement  .= $_;
        $endTest    .= $_;

        #
        # git rid of all the escaped tics, and then eat the
        #
        $endTest =~ s/''//sg;
        $endTest =~ s/'(.*?)'//sg;

        #
        # if there is no tick, reset for next pass, and keep going
        #
        if ( $endTest !~ /'/ && $endTest =~ /;$/ ) {
            $self->runSQL( SQL=> $statement );
            $statement  = '';
            $endTest    = '';
        }
    }

    close $SQLFILE;
    return;
}

=head2 createSizedImages

Create all of the derived images from a file upload based on its schema definition

    my %dataHashToUpdate = $fws->dataHash(guid=>'someGUIDThatHasImagesToUpdate');
    $fws->createSizedImages(%dataHashToUpdate);

If the data hash might not be correct because it is actually stored in a different table you can pass the field name you wish to update

    $fws->createSizedImages(guid=>'someGUID',image_1=>'/someImage/image.jpg');

=cut

sub createSizedImages {
    my ( $self, %paramHash ) = @_;

    #
    # going to need the current hash plus its derived schema to figure out what we should be making
    #
    my %dataHash    = ( %paramHash,$self->dataHash( guid => $paramHash{guid} ) );
    my %schemaHash  = $self->schemaHash( $dataHash{type} );

    #
    # if siteGUID is blank, lets get the one of the site we are on
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # bust though all the fields and see if we need to do anything with them
    #
    for my $field ( keys %dataHash ) {

        #
        # for non secure files lets prune the 640,custom, and thumb fields
        #
        my $dataType = $schemaHash{$field}{fieldType};
        if ( $dataType eq 'file' || $dataType eq 'secureFile' ) {

            #
            # get just the file name... we will use this a few times
            #
            my $fileName = $self->justFileName( $dataHash{$field} );

            #
            # set the file path based on secure or not
            #
            my $dirPath = $self->{filePath};
            if ( $dataType eq 'secureFile' ) { $dirPath = $self->{fileSecurePath} }

            #
            # check for thumb creation... if so lets do it!
            #
            for my $fieldName ( keys %schemaHash ) {
                if ( $schemaHash{$fieldName}{fieldParent} eq $field && $schemaHash{$fieldName}{fieldParent} ) {

                    #
                    # A directive to create a new image exists!  lets figure out where and how, and do it
                    #
                    my $directory       = $self->safeDir( $dirPath . '/' . $paramHash{siteGUID} . '/' . $paramHash{guid} );
                    my $newDirectory    = $self->safeDir( $dirPath . '/' . $paramHash{siteGUID} . '/' . $paramHash{guid} . '/' . $fieldName );
                    my $newFile         = $newDirectory . '/' . $fileName;
                    my $webFile         = $self->{fileWebPath} . '/' . $paramHash{siteGUID} . '/' . $paramHash{guid} . '/' . $fieldName . '/' . $fileName;


                    #
                    # make the image width 100, if its not specified
                    #
                    if ( $schemaHash{$fieldName}{imageWidth} < 1 ) { $schemaHash{$fieldName}{imageWidth} = 100 }

                    #
                    # Make the subdir if its not already there
                    #
                    $self->makeDir( $newDirectory );

                    #
                    # create the new image
                    #
                    $self->saveImage( sourceFile => $directory . '/' . $fileName, fileName => $newFile, width => $schemaHash{$fieldName}{imageWidth} );

                    #
                    # if its a secure file, we only save it from site guid on...
                    #
                    if ( $dataType eq 'secureFile' ) { $webFile = '/' . $paramHash{siteGUID} . '/' . $paramHash{guid} . '/' . $fileName }

                    #
                    # if the new image is not there, then lets blank out the file
                    #
                    if ( !-e $newFile ) { $webFile = '' }

                    if ( $paramHash{guid} ) {
                        #
                        # save a blank one, or save a good one
                        #
                        $self->saveExtra( table => 'data', siteGUID => $paramHash{siteGUID}, guid => $paramHash{guid}, field => $fieldName, value => $webFile );
                    }
                }
            }
        }
    }

    return;
}

=head2 fileArray

Return a directory listing into a FWS hash array reference.

    #
    # retrieve a reference to an array of data we asked for
    #
    my $fileArray = $fws->fileArray( directory   =>'/home/directory' );

    #
    # loop though the array printing the files we found
    #
    for my $i (0 .. $#$fileArray) {
        print $fileArray->[$i]{file}. "\n";
    }

=cut

sub fileArray {
    my ( $self, %paramHash ) =@_;

    #
    # ensure nothing scary is in the directory
    #
    $paramHash{directory} = $self->safeDir( $paramHash{directory} );

    #
    # pull the directory into an array
    #
    opendir ( my $DIR, $paramHash{directory} );
    my @getDir = grep( !/^\.\.?$/, readdir( $DIR ));
    closedir $DIR;

    my @fileHashArray;
    foreach my $dirFile ( @getDir ) {
        if ( -f $paramHash{directory} . '/' . $dirFile ) {

            my %fileHash;
            $fileHash{file}       = $dirFile;
            $fileHash{fullFile}   = $paramHash{directory} . '/' . $dirFile;
            $fileHash{size}       = ( stat $fileHash{fullFile} )[7];
            $fileHash{date}       = ( stat $fileHash{fullFile} )[9];

            #
            # push it to the array
            #
            push ( @fileHashArray, {%fileHash} );
        }
    }
    return \@fileHashArray;
}


=head2 formMapToHashArray

Return a reference to a hash array from its human readable formMap.    The format is new line delmited per array item then subsectioned by |, then name valued paired with ~ per each subsection.  The first item of each | and ~ delemited section is translaged into the name hash key while the rest of the ~ delemented are convered into a name value pair.

Example:

    title 1~type~type 1|sub title 1a|sub title 1b
    title 2~something~extra|sub title 2a~extaKey~extra value|sub title 2b

Will return:

    [
      {
        'name' => 'title 1',
        'type' => 'type 1',
        'optionArray' => [
                   { 'name' => 'sub title 1a' },
                   { 'name' => 'sub title 1b' }
                 ]
      },
      {
        'name' => 'title 2',
        'something' => 'extra',
        'optionArray' => [
                   { 'name' => 'sub title 2a', 'extaKey' => 'extra value' },
                   { 'name' => 'sub title 2b' }
                 ]
      }
    ];

=cut

sub formMapToHashArray {
    my ( $self, $obj ) = @_;

    my @formArray;
    for my $line ( split ( /\n/, $obj ) ) {

        my @optionArray;
        my @items = split ( /\|/, $line );

        my %item;
        my %itemExt;
        ( $item{name}, %itemExt ) = split( /~/, shift( @items ) );
        %item = ( %itemExt, %item );

        while ( @items ) {
            my %option;
            my %optionExt;
            ( $option{name}, %optionExt) = split( /~/, shift( @items ) );
            %option = ( %optionExt, %option );
            push( @optionArray, {%option} );
        }

        $item{optionArray} = \@optionArray;
        push( @formArray, {%item} );
    }

    return \@formArray;
}


=head2 getEncodedBinary

Retrive a file and convert it into a base 64 encoded binary.

    #
    # Get the file
    #
    my $base64String = $fws->getEncodedBinary( $someFileWeWantToConvert );

=cut

sub getEncodedBinary {
    my ( $self, $fileName ) = @_;

    #
    #convert file to base64
    #
    use MIME::Base64;
    my $rawFile;

    open ( my $FILE, '<', $fileName ) || $self->FWSLog( 'Could not read file: ' . $fileName );
    binmode $FILE;
    while ( read ( $FILE, my $buffer, 1 ) ) { $rawFile .= $buffer }
    close $FILE;

    my $rawfile = encode_base64( $rawFile );
    return $rawfile;
}


=head2 unpackDirectory

The counterpart to packDirectory.   This will put the files under the directory you choose from a file created by packDirectory.

    #
    # Put the files somewhere
    #
    $fws->unpackDirectory( directory => $someDirectory, fileName => '/something' );

=cut

sub unpackDirectory {
    my ( $self, %paramHash ) = @_;

    $self->FWSLog( 'Unpacking files: ' . $paramHash{fileName} . ' -> ' . $paramHash{directory} );

    #
    # for good mesure, make the directory in case this is super fresh
    #
    $self->makeDir( $paramHash{directory} );

    #
    # PH's for file slurping
    #
    my $fileReading;
    my $fileName;

    #
    # open file
    #
    open ( my $UNPACKFILE, '<', $paramHash{fileName} );
    while ( <$UNPACKFILE> ) {
        my $line = $_;

        #
        # eat the return
        #
        chomp $line;

        if ( $line =~ /^FILE_END\|/ ) {
            #
            # save the file to that directory
            #
            $self->saveEncodedBinary( $paramHash{directory} . '/' . $fileName, $fileReading );

            #
            # reset so when we come around again we will no we are done.
            #
            $fileName       = '';
            $fileReading    = '';
        }

        #
        # if we have a file name,  we are currenlty looking for a
        # file.  eat those lines up and stick them in a diffrent var
        #
        elsif ( $fileName ne '' ) { $fileReading .= $line . "\n" }

        #
        # if this is a start of a file, lets get it set up and
        # define the file name, the next time we go around we
        # will be looking at the base 64
        #
        if ( $line =~ /^FILE\|/ ) {
            ( $fileName = $line ) =~ s/.*?\|\/*(.*)\n*/$1/sg;
            ( my $directory = $paramHash{directory} . '/' . $fileName ) =~ s/^(.*)\/.*/$1/sg;
            $self->makeDir( $directory );
        }


    }
    close $UNPACKFILE;

    return;
}



=head2 uploadFile {

Run generic upload file routine.

    $fws->uploadFile( '/directory', $FILEHANDLE, 'newfilename.ext' );

=cut

sub uploadFile {
    my ( $self, $directory, $fileHandle, $fileName ) = @_;

    $directory    = $self->safeDir( $directory );
    $fileName     = $self->safeFile( $fileName );

    #
    # make the directory if its not already there
    #
    $self->makeDir( $directory );

    #
    # get the file from the browser
    #
    my $byteReader;
    my $buffer;
    my $fileHolder;
    while ( $byteReader = read( $fileHandle, $buffer, 1024 ) ) { $fileHolder .= $buffer }

    #
    # if we meet the restrictions write the file to the filesystem and create thumbnails and icons.
    #
    open( my $SFILE, '>', $directory . '/' . $fileName ) || $self->FWSLog( "Could not write to file: " . $directory . "/" . $fileName );
    print $SFILE $fileHolder;
    close $SFILE;

    return $directory . "/" . $fileName;
}


=head2 packDirectory

MIME encode a directory ready for a FWS export.  This will exclude anything that starts with /backup, /cache, /import_ or ends with .log or .pm.someDateNumber.

    #
    # Get the file
    #
    my $packedFileString = $fws->packDirectory( directory => $someDirectory );


You can also pass the key directoryList, and it will only add directories on this comma delimtied list unless the file begins with FWS.

    #
    # Only grab fws and plugins dirs
    #
    my $packedFileString = $fws->packDirectory( directory => $someDirectory, directoryList => '/fws,/plugins' );


=cut

sub packDirectory {
    my ( $self, %paramHash ) = @_;

    #
    # set the default base dir for parsing
    #
    $paramHash{baseDirectory} ||= $self->{filePath};
    my $dirPath = $paramHash{baseDirectory};

    #
    # this will need some MIME and file find action
    #
    use File::Find;
    use MIME::Base64;

    my $FILEFILE;
    if ( $paramHash{fileName} ) { open ( $FILEFILE, ">", $paramHash{fileName} ) }

    #
    # PH for the return
    #
    my $packFile;

    finddepth( sub {
        #
        # clean up the name so it will always be consistant
        #
        my $fullFileName = $File::Find::name;
        ( my $file = $fullFileName ) =~ s/^$dirPath//sg;

        #
        # if we have a list of dirs, lets make sure we are ok to process this one
        #
        my $dirOK = 0;
        if ( $paramHash{directoryList} ne '' ) {
            map { if ( $file =~ /^$_/ ) { $dirOK = 1 } } split( /,/, $paramHash{directoryList} );
        }

        #
        # if we didn't pass a directoryList then we are all good for every file
        #
        else { $dirOK = 1 }

        #
        # move though the files
        #
        if (-f $fullFileName 
            && $file !~ /^\/(import_|backup|cache|fws\/cache)/i 
            && $file !~ /(.log|\.pm\.\d+)$/i 
            && ( ( $file !~ /^\/fws\//i && $file !~ /^\/plugin\// && $file !~ /FWSElement-/ ) || !$paramHash{minMode} )
            && ( $file !~ /FWSElement-/ || !$paramHash{noFWSBackups} )
            && ( $dirOK || $file =~ /^FWS/ ) ) {

            #
            # get the file
            #
            my $rawFile;
            open ( my $FILE, '<', $fullFileName ) || $self->FWSLog( 'Can not read file: ' .  $! );
            binmode $FILE;
            while ( read( $FILE, my $buffer, 1 ) ) { $rawFile .= $buffer }
            close $FILE;

            #
            # print the header - encode it - footer around the file
            #
            my $fileLine = 'FILE|' . $file . "\n" . encode_base64( $rawFile ) . 'FILE_END|' . $file . "\n";
            if ( $paramHash{fileName} ne '' ) { print $FILEFILE $fileLine }
            else { $packFile .= $fileLine }

            }
        }, $paramHash{directory} );

    if ( $paramHash{fileName} ) { close $FILEFILE }

    return $packFile;
    }


=head2 saveEncodedBinary

Decode a base 64 encoded string and save it as its file.

    #
    # Save the file
    #
    $fws->saveEncodedBinary( $someFileWeWantToSave, $theBase64EcodedString );

=cut

sub saveEncodedBinary {
    my ( $self, $fileName, $rawFile ) = @_;
    use MIME::Base64;
    #
    # take a base64 text string, and save it to filesystem
    #
    open ( my $FILE, ">", $fileName );
    binmode $FILE;
    $rawFile = decode_base64( $rawFile );
    print $FILE $rawFile;
    close $FILE;
    return;
}


=head2 pluginInfo

Extract the version and description from a FWS plugin.  If no version is labeled or exists it will return 0.0000 and the description will be blank.

    #
    # get the info from the plugin
    #
    my %pluginInfo = $fws->pluginInfo( $somePluginFile );
    print "Description: " . $pluginInfo{description} . "\n";
    print "Version: " . $pluginInfo{version} . "\n";
    print "Author: " . $pluginInfo{author} . "\n";
    print "Author Email: " . $pluginInfo{authorEmail} . "\n";

=cut

sub pluginInfo {
    my ( $self, $pluginFile ) = @_;

    #
    # the return we will build
    #
    my %returnHash;

    #
    # pull the file into a string so we can parse it
    #
    my $scriptContent;
    if ( -e $pluginFile ) {
        open ( my $SCRIPTFILE, "<", $pluginFile );
        while ( <$SCRIPTFILE> ) { $scriptContent .= $_ }
        close $SCRIPTFILE;
    }
    
    #
    # strip the version and header data out and create the commit button
    #
    $scriptContent             =~ s/our\s\$VERSION\s*=\s*\'([\d\.]+).*?\n//s;
    $returnHash{version}       = $1;
   
    #
    # make the version cool if its not in there
    # 
    $returnHash{version}        =~ s/[^\d\.]//g;
    $returnHash{version}       ||= '0.0000';

    #   
    # get description
    #
    $scriptContent              =~  s/.head1\sNAME\n\n[a-zA-Z0-9]+\s-\s(.*?)\n//sg;
    $returnHash{description}    = $1;
    
    #
    # Pull out the author
    #
    $scriptContent              =~ s/.head1 AUTHOR[\n]*(.*?),\sC\<\<\s\<\s*(.*?)\s*\>\s\>\>.*//sg;
    $returnHash{authorName}     = $1;
    ( $returnHash{authorEmail}  = $2 ) =~ s/ at /\@/g;
    
    return %returnHash; 
}


=head2 makeDir

Make a new directory with built in safety mechanics.   If the directory is not under the filePath or fileSecurePath then nothing will be created.

    $fws->makeDir( directory => $self->{filePath} . '/thisNewDir' );

This by default is ran in safe mode, making sure directorys are only created in the filePath or fileSecurePath.  This can be turned off by passing nonFWS => 1.

=cut

sub makeDir {
    my ( $self, @paramArray ) = @_;
    
    #
    # set paramHash if its a hash or, its in single value
    # mode using the directory
    #
    my %paramHash;
    if ( $#paramArray ) { %paramHash = @paramArray }
    else { $paramHash{directory} = $paramArray[0] }
       
    #
    # kill double ..'s so noobdy tries to leave our tight environment of security
    #
    $paramHash{directory} = $self->safeDir( $paramHash{directory} );
    
    #
    # gently bail if we didn't get a directory
    #
    return if $paramHash{directory} eq '';

    #
    # to make sure nothing fishiy is going on, you should only be making dirs under this area
    #
    my $filePath        = $self->safeDir( $self->{filePath} );
    my $fileSecurePath  = $self->safeDir( $self->{fileSecurePath} );
    
    if ( $paramHash{directory} =~ /^\Q$filePath\E/ || $paramHash{directory} =~ /^\Q$fileSecurePath\E/ || $paramHash{nonFWS} ) {

        #
        # create an array we can loop though to rebuild it making them on the fly
        #
        my @directories = split( /\//, $paramHash{directory} );

        #
        # delete the $paramHash{directory} because we will rebuild it
        #
        $paramHash{directory} = '';

        #
        # loop though each one making them if they need to
        #
        foreach my $thisDir ( @directories ) {
            #
            # make the dir and send a debug message
            #
            $paramHash{directory} .= $thisDir . '/';
            mkdir( $paramHash{directory}, 0755 );
        }
    }

    else {
        $self->FWSLog( 'makeDir() in unauthorized directory: ' . $paramHash{directory} );
        return;
    }
    return $paramHash{directory}; 
}


=head2 runInit

Run init scripts for a site.  This can only be used after setSiteValues() or setSiteFiendly() is called.

    $fws->runInit();

=cut

sub runInit {
    my ( $self ) = @_;
    return $self->runScript( 'init' );
}

=head2 runScript

Run a FWS element script.  This should not be used outside of the FWS core.  There is no recursion or security checking and should not be used inside of elements to perfent possible recursion.   Only use this if you are absolutly sure of the script content and its safety.

    %valueHash = $fws->runScript( 'scriptName', %valueHash );

=cut

sub runScript {
    my ( $self, $guid, %valueHash ) = @_;

    #
    # because of the nature of the element caching it is possible for one to be ran twice,  to make sure lets create a testing hash
    #
    my %scriptRan;


    #
    # if this is blank, lets just not do it
    #
    if ( $guid ) {
        #
        # copy the self object to fws
        #
        my $fws = $self;

        #
        # get the short hand hash to see whats up
        #
        my %fullElementHash = $self->_fullElementHash();

        for my $fullGUID ( sort { $fullElementHash{$a}{alphaOrd} <=> $fullElementHash{$b}{alphaOrd} } keys %fullElementHash) {

            #
            # lets see if we have a match
            #
            my $liveGUID;
            if ( $fullGUID eq $guid ) { $liveGUID = $fullElementHash{$fullGUID}{guid} }
            if ( $fullElementHash{$fullGUID}{type} eq $guid ) { $liveGUID = $fullElementHash{$fullGUID}{guid} }


            #
            # we snagged one!  lets do it!
            #
            if ( $liveGUID && !$scriptRan{$liveGUID} ) {
                #
                # se the flag so we don't do this one twice
                #
                $scriptRan{$liveGUID} = '1';

                my %elementHash = $fws->elementHash(guid=>$liveGUID);

                if ( $elementHash{scriptDevel} ) {
                    ## no critic
                    eval $elementHash{scriptDevel};
                    ## use critic
                    my $errorCode = $@;
                    if ( $errorCode ) { $self->FWSLog( $guid, $errorCode ) }
                }
            }
        }

        #
        # now put it back
        #
        $self = $fws;

    }
    #
    # return the valueHash back in case the script altered it
    #
    return %valueHash;
}


=head2 saveImage

Save an image with a unique width or height.  The file will be converted to extensions graphic type of the fileName passed.   Source, fileName and either width or height is required.

    #
    # convert this png, to a jpg that is 110x110
    #
    $fws->saveImage(    
        sourceFile  => '/somefile.png',
        fileName    => '/theNewFile.jpg',
        width       => '110',
        height      => '110'
    );

    #
    # convert this png, to a jpg that is 110x110 but chop off the bottom of the height if it resizes to larget then 110 instead of shrinking or stretching
    #
    $fws->saveImage(    
        sourceFile  =>'/somefile.png',
        fileName    =>'/theNewFile.jpg',
        width       =>'110',
        cropHeight  =>'110'
    );

=cut

sub saveImage {
    my ( $self, %paramHash ) = @_;

    #
    # use GD in trueColor mode
    #
    use GD();
    GD::Image->trueColor(1);

    #
    # create new image
    #
    my $image;
    if ( !( $image = GD::Image->new( $paramHash{sourceFile} ) ) )  {
        $self->FWSLog( 'Image cannot be opened by GD for resizing, it might be currupt: ' . $paramHash{sourceFile} );
        return 0;
    }

    #
    # if we truely have an image lets continue if not, lets pretend this didn't even happen
    #
    else {

        #
        # get current widht/height for mat to resize
        #
        my ( $width, $height ) = $image->getBounds();

        #
        # if you are binding a width and a height, then do some magic to truncate extra sizing
        #
        if ( $paramHash{height} && $paramHash{width} ) {
            if ( ( $width / $paramHash{width} ) > ( $height / $paramHash{height} ) ) {
                $paramHash{cropWidth}   = $paramHash{width};
                $paramHash{width}       = '';
            }
            else {
                $paramHash{cropHeight}  = $paramHash{height};
                $paramHash{height}      = '';
            }
        }

        #
        # do math to get new width/height
        #
        $paramHash{height}  ||= int( $paramHash{width} / $width * $height );
        $paramHash{width}   ||= int( $paramHash{height} / $height * $width );

        #
        # make sure size is at least 1
        #
        if ( $paramHash{width} < 1 ) {  $paramHash{width} = 1 }
        if ( $paramHash{height} < 1 ) { $paramHash{height} = 1 }

        #
        # Resize image and save to a file using proper mime type
        #
        my $sizedImage = GD::Image->new( $paramHash{width}, $paramHash{height} );
        $sizedImage->copyResampled( $image, 0, 0, 0, 0, $paramHash{width}, $paramHash{height}, $width, $height );

        #
        # trim it up or this is pointless if the perpsective is already correct, but what the hay!
        #
        $paramHash{cropWidth}   ||= $paramHash{width};
        $paramHash{cropHeight}  ||= $paramHash{height};

        #
        # do the deed
        #
        my $newImage = GD::Image->new( $paramHash{cropWidth}, $paramHash{cropHeight} );
        $newImage->copyResized( $sizedImage, 0, 0, 0, 0, $paramHash{width}, $paramHash{height}, $paramHash{width}, $paramHash{height} );

        #
        # safe the the physical file
        # save as what ever extnesion was passed for the name
        #
        open ( my $IMG, '>', $paramHash{fileName} ) || $self->FWSLog( 'Could not write to file: ' . $! );
        binmode $IMG;
        if ( $paramHash{fileName} =~ /\.(jpg|jpeg|jpe)$/i ) {   print $IMG $newImage->jpeg() }
        if ( $paramHash{fileName} =~ /\.png$/i ) {              print $IMG $newImage->png() }
        if ( $paramHash{fileName} =~ /\.gif$/i ) {              print $IMG $newImage->gif() }
        close $IMG;
    }
    return 1;
}

=head2 FWSDecrypt

Decrypt data if a site has the proper configuration

    my $decryptedData = $fws->FWSDecrypt( 'alsdkjfalkj230948lkjxldkfj' );

=cut

sub FWSDecrypt {
    my ( $self, $encData )= @_;

    if ( $self->{encryptionType} =~ /blowfish/i ) {
        require Crypt::Blowfish;
        Crypt::Blowfish->import();
        my $cipher1 = Crypt::Blowfish->new( substr( $self->{encryptionKey}, 0, 56 ) );
        my $cipher2 = Crypt::Blowfish->new( substr( $self->{encryptionKey}, 57, 56 ) );
        my $cipher3 = Crypt::Blowfish->new( substr( $self->{encryptionKey}, 111, 56 ) );
        my $data = pack( "H*", $encData );
        my $dec;
        while ( length( $data ) > 0 )  {
            my $len = length( $data );
            $dec .= $cipher3->decrypt( substr( $data, 0, 8 ) );
            if ( $len > 8 ) { $data = substr( $data, 8 ) } else { $data = '' }
        }
        $data = $dec;
        $dec = '';
        while ( length( $data ) > 0 )  {
            my $len = length( $data );
            $dec .= $cipher2->decrypt( reverse( substr( $data, 0, 8 ) ) );
            if ( $len > 8 ) { $data = substr( $data, 8 ) } else { $data = '' }
        }
        $data = $dec;
        $dec = '';
        my $size = substr( $data, 0, 8 );
        $data = substr( $data, 8 );
        while ( length( $data ) > 0 )  {
            my $len = length( $data );
            $dec .= $cipher1->decrypt( substr( $data, 0, 8 ) );
            if ( $len > 8 ) { $data = substr( $data, 8 ) } else { $data = '' }
        }
        $encData = substr( $dec, 0, $size );
    }
    return $encData;
}



=head2 FWSEncrypt

Encrypt data if a site has the proper configuration

    my $encryptedData = $fws->FWSEncrypt( 'encrypt this stuff' );

=cut

sub FWSEncrypt {
    my ( $self, $data )= @_;
    my $enc;

    if ( $self->{encryptionType} =~ /blowfish/i ) {
        require Crypt::Blowfish;
        Crypt::Blowfish->import();
        my $cipher1 = Crypt::Blowfish->new( substr( $self->{encryptionKey}, 0, 56 ) );
        my $cipher2 = Crypt::Blowfish->new( substr( $self->{encryptionKey}, 57, 56 ) );
        my $cipher3 = Crypt::Blowfish->new( substr( $self->{encryptionKey}, 111, 56 ) );
        my $fullLength = length( $data );
        while ( length( $data ) > 0 )  {
            my $len = length( $data );
            if ( $len < 8 ) { $data .= "\000"x(8-$len) }
            $enc .= $cipher1->encrypt( substr( $data, 0, 8 ) );
            if ( $len > 8 ) { $data = substr( $data, 8 ) } else { $data = '' }
        }
        $fullLength = sprintf("%8d", $fullLength);
        $fullLength=~ tr/ /0/;
        $data = $fullLength.$enc;
        $enc = '';
        while ( length( $data ) > 0 ) {
            my $len = length( $data );
            $enc .= $cipher2->encrypt( reverse( substr( $data, 0, 8 ) ) );
            if ( $len > 8 ) { $data = substr( $data, 8 ) } else { $data = '' }
        }
        $data = $enc;
        $enc = '';
        while ( length( $data ) > 0 ) {
            my $len = length( $data );
            $enc .= $cipher3->encrypt( substr( $data, 0, 8 ) );
            if ( $len > 8 ) {$data = substr( $data, 8 ) } else { $data = '' }
        }
        $data = unpack( "H*", $enc );
    }
    return $data;
}


=head2 tailFile

Read x number of lines from the end of a file.  If lines are not specified it will default to 10.

    #
    # Print last 10 lines of the FWS.log file
    #
    print $fws->tailFile( lines => 50, fileName => $fws->{fileSecurePath} . "/FWS.log" );

=cut

sub tailFile {
    my ( $self, %paramHash ) = @_;

    #
    # set the default ot 10 lines
    #
    $paramHash{lines} ||= 10;

    #
    # open the file
    #
    open ( my $TAILFILE, "<", $paramHash{fileName} );


    #
    # set our cursor to to know where we are at
    #
    my $lineCursor;
    my $tailReturn;

    while ( <$TAILFILE> ) {

        #
        # advance the cursor and add the next line to the end
        #
        $tailReturn .= $_;
        $lineCursor++;

        #
        # eat the first line if we have what we needed
        #
        if ( $lineCursor > $paramHash{lines} ) { $tailReturn =~ s/^(.*?)\n// }
    }

    close $TAILFILE;

    return $tailReturn;
}


=head2 FWSLog

Append something to the FWS.log file if FWSLogLevel is set to 1 which is default.

    #
    # Soemthing is happening
    #
    $fws->FWSLog("this is happening\nthis is a new log line");

If a multi line string is passed it will break it up in to more than one log entries.

=cut

sub FWSLog{
    my ( $self, $module, $errorText ) = @_;
    if ( $self->{FWSLogLevel} > 0 ) {
        open ( my $FILE, ">>", $self->{fileSecurePath} . "/FWS.log" ) || return 0;

        #
        # if you only pass it one thing, lets set it up so it will display
        #
        if ( !$errorText ) {
            $errorText = $module;
            $module = 'FWS';
        }

        #
        # split up the lines so we can pass a whole bunch and have them format each on one line
        #
        my @resultLines = split /\n/, $errorText;
        foreach my $resultLine ( @resultLines ) {
            if ( $resultLine ) {
                print $FILE $ENV{REMOTE_ADDR} . " - [".$self->formatDate( format => "apache" ) . "] " . $module . ": " . $resultLine . " [" . $ENV{SERVER_NAME} . $ENV{REQUEST_URI} . "]\n";
            }
        }
        close $FILE;
    }

    return $module;
}


=head2 SQLLog

Append something to the SQL.log file if SQLLogLevel is set to 1 or 2.   Level 1 will log anything that updates a database record, and level 2 will log everything.  In good practice this should not be used, as all SQL statements are ran via the runSQL method which applies SQLLog.

    #
    # Soemthing is happening
    #
    $fws->SQLLog( $theSQLStatement );

=cut


sub SQLLog{
    my ( $self, $SQL ) = @_;
    if ( $self->{SQLLogLevel} > 0 ) {
        open ( my $FILE, ">>", $self->{fileSecurePath}."/SQL.log" ) || return 0;
        if ( ( $self->{SQLLogLevel} eq '1' && ( $SQL =~/^insert/i || $SQL=~/^delete/i || $SQL=~/^update/i || $SQL=~/^alter/i ) ) || $self->{SQLLogLevel} eq '2' ) {
            print $FILE $ENV{REMOTE_ADDR} . " - [" . $self->formatDate( format => "apache" ) . "] " . $SQL . " [" . $ENV{SERVER_NAME} . $ENV{REQUEST_URI} . "]\n";
        }
        close $FILE;
    }
    return 1;
}


sub _saveElementFile {
    my ( $self, $guid, $siteGUID, $table, $ext, $content ) = @_;

    #
    # for security reasons lets make sure ext is safe
    #
    if ( ( $ext eq 'css' || $ext eq 'js' ) && ( $table eq 'element' || $table eq 'templates' || $table eq 'site' || $table eq 'page' ) ) {

        #
        # if siteGUID is blank, lets get the one of the site we are on
        #
        $siteGUID ||= $self->{siteGUID};

        #
        # set the directory and make it if it might not exist
        #
        my $directory = $self->{filePath}."/".$siteGUID."/".$guid;
        $self->makeDir( $directory );

        #
        # set the timestamp so we will add this to the file name for the cachable named ones
        #
        my $timeStamp = time();

        #
        # for security lets get rid of anything dangerous
        #
        my $name        = $self->safeDir( $directory . "/FWSElement." . $ext );
        my $backupName  = $self->safeDir( $directory . "/FWSElement-" . $timeStamp . "." . $ext );

        #
        # save the file to the FS
        #
        open ( my $FILE, ">", $name ) || $self->FWSLog( "Could not write to file: " . $name );
        print $FILE $content;
        close $FILE;

        #
        # update Key field is guid, unless we are talking about the "site" table, then it is "siteGUID"
        #
        if ( $table eq 'site' ) { $guid = $siteGUID }

        #
        # if it is blank, then we are actually here to delete it
        #
        if ( !$content ) {
            unlink $name;
            if ( $table eq 'page' ) { $self->saveExtra( table => 'data', siteGUID => $siteGUID, guid => $guid, field => $ext . 'Devel', value => '0' ) }
            else { $self->runSQL( SQL => "update " . $self->safeSQL( $table ) . " set " . $self->safeSQL( $ext ) . "_devel=0 where guid='" . $self->safeSQL( $guid ) . "'" ) }
        }
        else {
            if ( $table eq 'page' ) { $self->saveExtra( table => 'data', siteGUID => $siteGUID, guid => $guid, field => $ext . 'Devel', value => $timeStamp ) }
            else { $self->runSQL( SQL => "update " . $self->safeSQL( $table ) . " set " . $self->safeSQL( $ext ) . "_devel=" . $self->safeSQL( $timeStamp ) . " where guid='" . $self->safeSQL( $guid ) . "'" ) }

            #
            # save the backupName one
            #
            open ( my $FILE, ">", $backupName ) || $self->FWSLog( "Could not write to file: " . $backupName );
            print $FILE $content;
            close $FILE;
        }

        #
        # Remove JS and CSS Cache
        #
        $self->flushWebCache();
    }
    return;
}


sub _versionData {
    my ( $self, $location, $url, $saveVersion ) = @_;
    my @metaData;

    #
    # vesrion tags all end it .txt and start with current_
    #
    $url = "current_" . $url . ".txt";
    if ( $location =~ /live/i ) {

        #
        # get the major ver
        #
        my $liveDistServer = $self->{FWSServer}."/fws_".$self->{FWSVersion};

        require LWP::UserAgent;
        my $browser = LWP::UserAgent->new();
        my $response = $browser->get( $liveDistServer."/".$url );
        if (!$response->is_success ) { return "Unavailable" }
        @metaData = split(/\n/,$response->content);
    }
    else {
        open (my $FILE, "<", $self->fileSecurePath . "/" . $url ) || return "";
        @metaData = <$FILE>;
        close $FILE;
    }

    #
    # get the major ver of the version name we recived
    #
    my $majorVer    = shift( @metaData );
    my $build       = shift( @metaData );
    if ( $saveVersion ) {
        open ( my $FILE, '>', $self->{fileSecurePath} . "/" . $url );
        print $FILE $majorVer."\n" . $build."\n";
        close $FILE;
    }

    my $returnString = $majorVer;
    if ( $build ) { $returnString .= ' Build '.$build }
    $returnString =~ s/\n//sg;

    my @verSplit = split( /\./, $majorVer );
    $majorVer = $verSplit[0] . '.' . $verSplit[1];

    return ( $returnString, $majorVer, $build );
}

sub _getElementEditText {
    my ( $self, $siteGUID, $guid, $ext )= @_;

    #
    # get a file that is to edited in ACE from the elements. only works on js and css files
    #
    my $fileText;
    if ( $ext eq 'js' || $ext eq 'css' ) {
        $self->FWSLog( "Opening Element File: " . $self->{filePath} . '/' . $siteGUID . '/' . $guid . '/FWSElement.' . $ext );
        my $file = $self->safeDir( $self->{filePath} . '/' . $siteGUID . '/' . $guid . '/FWSElement.' . $ext);
        if ( -e $file ) {
            open ( my $FILE, "<", $file );
            while ( <$FILE> ) { $fileText .= $_ }
            close $FILE;
        }
    }
    return $fileText;
}



=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::File


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


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::File
