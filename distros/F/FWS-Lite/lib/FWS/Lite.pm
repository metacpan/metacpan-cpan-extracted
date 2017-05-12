package FWS::Lite;

use 5.006;
use strict;

=head1 NAME

FWS::Lite - Version independent access to Framework Sites installations and common methods

=head1 VERSION

Version 0.004

=cut

our $VERSION = '0.004';

=head1 SYNOPSIS

	use FWS::Lite;

	#
	# Create FWS with MySQL connectivity
	#	
	my $fws = FWS::Lite->new(	DBName		=> "theDBName",
					DBUser		=> "myUser",
					DBPassword	=> "myPass");

	#
	# create FWS with SQLite connectivity
	#
	my $fws2 = FWS::Lite->new(	DBType		=> "SQLite",
					DBName		=> "/home/user/your.db");



=head1 DESCRIPTION

This module provides basic input and output to a FrameWork Sites installation or can be used independently using the methodologies of FrameWork Sites data structures and file handling in a small package.

=head1 CONSTRUCTOR

Most uses of FWS::Lite are accessing data from live FWS installations and do not require anything but the database credentials.   All non-required settings can be set for completeness or for the ability to run native FWS Code via FWS::Lite for testing that needs these set to determine location and site context.   

=head2 new

	my $fws = $fws->new(
		DBName 		=> "DBNameOrSQLitePathAndFile", # MySQL required
		DBUser 		=> "myDBUser",			# MySQL required
		DBPassword 	=> "myDBPassword",		# MySQL required
		DBHost 		=> "somePlace.somewhere.com", 	# default: localhost
		DBType 		=> "MySQL")			# default: MySQL

Depending on if you are connecting to a MySQL or SQLite a combination of the following are required. 

=over 4

=item * DBName (MySQL and SQLite Required)

For MySQL this is the DB Name.  For SQLite this is the DB file path and file name.
MySQL example:  user_fws
SQLite example: /home/user/secureFiles/user_fws.db

=item * DBUser (MySQL Required)

Required for MySQL and is the database user that has full grant access to the database.

=item * DBPassword (MySQL Required)

The DBUser's password.

=item * DBHost (MySQL Required if your database is not on localhost)

The DBHost will default to 'localhost' if not specified, but can be what ever is configured for the database environment.


=item * DBType (SQLite Required)

The DBType will default to 'MySQL' if not specified, but needs to be added if you are connecting to SQLite.

=back

Non-required parameters for FWS installations can be added, but depending on the scope of your task they usually are not needed unless your testing code, or interacting with web elements that display rendered content from a stand alone script.

=over 4

=item * domain

Full domain name with http prefix.  Example: http://www.example.com

=item * filePath

Full path name of common files. Example: /home/user/www/files

=item * fileSecurePath 

Full path name of non web accessible files. Example: /home/user/secureFiles

=item * fileWebPath

Web path for the same place filePath points to.  Example: /files

=item * secureDomain

Secure domain name with https prefix. For non-secure sites that do not have an SSL cert you can use the http:// prefix to disable SSL.  Example: https://www.example.com 

=back

=cut


####################
####### HIDE ####### FWS 2.0 Web import block 
####################

sub new {
        my $class = shift;
	my $self = {@_};
        bless $self, $class;
	return $self;
}

####################
##### END HIDE ##### FWS 2.0 Web import block 
####################


=head1 DATA METHODS

FWS methods that connect, read, write, reorder or alter the database itself.

=head2 connectDBH

Do the initial database connection via MySQL or SQLite.  This method will return back the DBH it creates, but it is only here for completeness and would normally never be used.  For FWS database routines this is not required as it will be implied when executing those methods..

	$fws->connectDBH();

=cut

sub connectDBH {
        my ($self) = @_;
	
	#
	# grab the DBI if we don't have it yet
	#
	if (!defined $self->{'_DBH'}) {

		#
		# hook up with some DBI
		#	
	        use DBI;
	
	        #
	        # default set to mysql
	        #
	        my $connectString = $self->{'DBType'}.":".$self->{'DBName'}.":".$self->{'DBHost'}.":3306";
	
	        #
	        # SQLite
	        #
	        if ($self->{'DBType'} =~ /SQLite/i) { $connectString = "SQLite:".$self->{'DBName'} }
	
	        #
	        # set the DBH for use throughout the script
	        #
	        $self->{'_DBH'} = DBI->connect("DBI:".$connectString,$self->{'DBUser'}, $self->{'DBPassword'});
	
		#
		# in case the user is going to do thier own thing, we will pass back the DBH
		#
		return $self->{'_DBH'};
	}
}



=head2 runSQL

Return an reference to an array that contains the results of the SQL ran.



	#
	# retrieve a reference to an array of data we asked for
	#
	my $dataArray = $fws->runSQL(SQL=>"select id,type from id_and_type_table");	# Any SQL statement or query
	
	#
	# loop though the array
	#
	while (@$dataArray) {
		
		#
		# collect the data each row at a time
		#
	        my $id          = shift(@$dataArray);
	        my $type        = shift(@$dataArray);

		#
		# display or do something with the data
		#
	        print "ID: ".$id." - ".$type."\n";
        }
	

=cut

sub runSQL {
        my ($self,%paramHash) = @_;
	
	$self->connectDBH();

	# 
	# Get this data array ready to slurp
	# and set the failFlag for future use to autocreate a dB schema
	# based on a default setting
	#
        my @data;
	my $errorResponse;

        #
        # use the dbh we were handed... if not use the default one.
        #
        if (!exists $paramHash{'DBH'}) {$paramHash{'DBH'} = $self->{'_DBH'}}
        
	#
	# once loging is turned on we can enable this
	#
	#$self->SQLLog($paramHash{'SQL'});

	#
	# prepare the SQL and loop though the arrays
	#

        my $sth = $paramHash{'DBH'}->prepare($paramHash{'SQL'});
        if ($sth ne '') {
		$sth->{PrintError} = 0; 
		$sth->execute(); 

		#
		# clean way to get error response
		#
		if (defined $DBI::errstr) { $errorResponse .= $DBI::errstr }		

		#
		# set the row variable ready to be populated
		#
		my @row;
		my @cleanRow;
		my $clean;

		#
		# SQL lite gathing and normilization
		#
                if ($self->{'DBType'} =~ /^SQLite$/i) {
                        while (@row = $sth->fetchrow) {
                                while (@row) {
                                        $clean = shift(@row);
                                        $clean = '' if !defined $clean;
                                        $clean =~ s/\\\\/\\/sg;
                                        push (@cleanRow,$clean);
                                }
                                push (@data,@cleanRow);
                        }
                }
		
		#
		# Fault to MySQL if we didn't find another type
		#
                else {
                        while (@row = $sth->fetchrow) {
                                while (@row) {
                                        $clean = shift(@row);
                                        $clean = '' if !defined $clean;
                                        push (@cleanRow,$clean);
                                }
                                push (@data,@cleanRow);
                        }
                }
        }

	#
	# check if myDBH has been blanked - if so we have an error
	# or I didn't have one to begin with
	#
	if ($errorResponse) {
		#
		# once FWSLog is enabled I can enable this
		#
		warn 'SQL ERROR: '.$paramHash{'SQL'}. ' - '.$errorResponse;
		#$self->FWSLog('SQL ERROR: '.$paramHash{'SQL'});
	}

	#
	# return this back as a normal array
	#
	return \@data;
}



=head2 alterTable

Alter a table to conform to the given definition without restriction.  The key will describe its index type and lesser definitions of field type will be applied without error or fault.  The return will give back any statement that was used to alter the table definition or table creation statement.  Use with caution on existing fields as its primary use is for new table creation or programmatic adding of new fields to a table that might not have a field that is needed.

        #
        # retrieve a reference to an array of data we asked for
	#
	# Note: It is not recommended to change the data structure of 
	# FWS default tables
        #
        print $fws->alterTable(	table	=>"table_name",		# case sensitive table name
				field	=>"field_name",		# case sensitive field name
				type	=>"char(255)",		# Any standard cross platform type
				key	=>"", 			# MUL, PRIMARY KEY, FULL TEXT
				default	=>"");			# '0000-00-00', 1, 'this default value'...

=cut

####################
####### HIDE ####### FWS 2.0 Web import block 
####################

sub alterTable {
        my ($self, %paramHash) =@_;

        #
        # set some vars we will flip depending on db type alot is defaulted to mysql, because that
        # is the norm, we will groom things that need to be groomed
        #
        my $sqlReturn;
        my $autoIncrement       = "AUTO_INCREMENT ";
        my $indexStatement      = "alter table ".$paramHash{'table'}." add INDEX ".$paramHash{'table'}."_".$paramHash{'field'}." (".$paramHash{'field'}.")";

        #
        # if default is timestamp lets not put tic's around it
        #
        if ($paramHash{'default'} ne 'CURRENT_TIMESTAMP') { $paramHash{'default'} = "'".$paramHash{'default'}."'" }

	#
	# the add statement we will use to alter tha table
	#
        my $addStatement        = "alter table ".$paramHash{'table'}." add ".$paramHash{'field'}." ".$paramHash{'type'}." NOT NULL default ".$paramHash{'default'};

        #
        # add primary key if the table is not an ext field
        #
        my $primaryKey = "PRIMARY KEY";

        #
        # show tables statement
        #
        my $showTablesStatement = "show tables";

        #
        # do SQLite changes
        #
        if ($self->{'DBType'} =~ /^sqlite$/i) {
                $autoIncrement = "";
                $indexStatement = "create index ".$paramHash{'table'}."_".$paramHash{'field'}." on ".$paramHash{'table'}." (".$paramHash{'field'}.")";
                $showTablesStatement = "select name from sqlite_master where type='table'";
        }

        #
        # do mySQL changes
        #
        if ($self->{'DBType'} =~ /^mysql$/i) {
                if ($paramHash{'key'} eq 'FULLTEXT') {
                        $indexStatement = "create FULLTEXT index ".$paramHash{'table'}."_".$paramHash{'field'}." on ".$paramHash{'table'}." (".$paramHash{'field'}.")";
                }
        }
        #
        # FULTEXT is MUL if not mysql, and mysql returns them as MUL even if they are full text so we don't need to updated them if they are set to that
        # so lets change it to MUL to keep mysql and other DB's without FULLTEXT syntax happy
        #
        if ($paramHash{'key'} eq 'FULLTEXT') { $paramHash{'key'} = 'MUL' }

        #
        # compile the statement
        #
        my $createStatement = "create table ".$paramHash{'table'}." (guid char(36) NOT NULL default '')";

        #
        # get the table hash
        #
        my %tableHash;
        my $tableList = $self->runSQL(SQL=>$showTablesStatement);
        while (@$tableList) {
                my $fieldInc                       = shift(@$tableList);
       		$tableHash{$fieldInc} = 1;
        }

	#
        # create the table if it does not exist
        #
        if (!exists $tableHash{$paramHash{'table'}}) {
                $self->runSQL(SQL=>$createStatement);
                $sqlReturn .= $createStatement.";\n";
        }

        #
        # get the table def hash
        #
        my $tableFieldHash = $self->tableFieldHash($paramHash{'table'});

        #
        # make the field if its not there
        #
        if (!exists $tableFieldHash->{$paramHash{'field'}}{"type"}) {
                $self->runSQL(SQL=>$addStatement);
                $sqlReturn .= $addStatement.";\n";
        }

        #
        # change the datatype if we are talking about MySQL 
        #
	my $changeStatement     = "alter table ".$paramHash{'table'}." change ".$paramHash{'field'}." ".$paramHash{'field'}." ".$paramHash{'type'}." NOT NULL default ".$paramHash{'default'};
        if ($paramHash{'type'} ne $tableFieldHash->{$paramHash{'field'}}{"type"} && $self->DBType() =~ /^mysql$/i) {
                $self->runSQL(SQL=>$changeStatement);
                $sqlReturn .= $changeStatement."; ";
                }

	#
	# need to add change syntax for SQLlite TODO
	#

       	#
	# Set a default for the index
	# 
	if (!exists $tableFieldHash->{$paramHash{'table'}."_".$paramHash{'field'}}{"key"}) { $tableFieldHash->{$paramHash{'table'}."_".$paramHash{'field'}}{"key"} = '' }
        
	#
        # set any keys if not the same
	#
        if ($tableFieldHash->{$paramHash{'table'}."_".$paramHash{'field'}}{"key"} ne "MUL" && $paramHash{'key'} ne "") {
                $self->runSQL(SQL=>$indexStatement);
                $sqlReturn .=  $indexStatement.";\n";
        }

        return $sqlReturn;
}

####################
##### END HIDE ##### FWS 2.0 Web import block 
####################

=head2 tableFieldHash

Return a multi-dimensional hash of all the fields in a table with its properties.  This usually isn't used by anything but internal table alteration methods, but it could be useful for someone making conditionals to determine the data structure before adding or changing data.

        $tableFieldHashRef = $fws->tableFieldHash('the_table');

	#
	# the return dump will have the following structure
	#
	$hash->{field}{type}
	$hash->{field}{key}
	$hash->{field}{ord}
	$hash->{field}{null}
	$hash->{field}{default}
	$hash->{field}{extra}
	
	$hash->{field_2}{type}
	$hash->{field_2}{key}
	$hash->{field_2}{ord}
	$hash->{field_2}{null}
	$hash->{field_2}{default}
	$hash->{field_2}{extra}
	
	...


=cut

sub tableFieldHash {
        my ($self,$table) = @_;

	#
	# set an order counter so we can sort by this if needed
	#
        my $fieldOrd = 0;

	#
	# TODO CACHE
	#
	my $tableFieldHash = {};

	#
	#  if we have a cached version, just return it
	#	
        if (!keys %$tableFieldHash) {
		#
		# we are not pulling this from cache, lets start from scratch
		#
		my %tableFieldHash;


                #
                # grab the table def hash for mysql
                #
                if ($self->{'DBType'} =~ /^mysql$/i) {
                        my $tableData = $self->runSQL(SQL=>"desc ".$table);
                        while (@$tableData) {
                                $fieldOrd++;
                                my $fieldInc                       		= shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'type'}      	= shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'ord'}       	= $fieldOrd;
                                $tableFieldHash{$fieldInc}{'null'}      	= shift(@$tableData);
                                $tableFieldHash{$table."_".$fieldInc}{'key'}    = shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'default'}   	= shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'extra'}     	= shift(@$tableData);
                        }
                }

                #
                # grab the table def hash for sqlite
                #
                if ($self->{'DBType'} =~ /^sqlite$/i) {
                        my $tableData = $self->runSQL(SQL=>"PRAGMA table_info(".$table.")");
                        while (@$tableData) {
                                					shift(@$tableData);
                                my $fieldInc = 				shift(@$tableData);
                                					shift(@$tableData);
                                					shift(@$tableData);
                                					shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'type'} =    shift(@$tableData);

                                $fieldOrd++;
                                $tableFieldHash{$fieldInc}{'ord'}       = $fieldOrd;
                        }

                        $tableData = $self->runSQL(SQL=>"PRAGMA index_list(".$table.")");
                        while (@$tableData) {
                                			shift(@$tableData);
                                my $fieldInc = 		shift(@$tableData);
                                			shift(@$tableData);

                                $tableFieldHash{$fieldInc}{"key"} = "MUL";
                        }
               	} 
       		return \%tableFieldHash;
	}	
	else {	
		#
              	# TODO SAVE CACHE
               	#
        }
}




=head1 FORMAT METHODS

FWS methods that use or manipulate text either for rendering or default population.

=head2 createGUID

Return a non repeatable Globally Unique Identifier to be used to populate the guid field that is default on all FWS tables.

        #
        # retrieve a guid to use with a new record
        #
        my $guid = $fws->createGUID();

=cut

####################
####### HIDE ####### FWS 2.0 Web import block 
####################

sub createGUID {
        my ($self) =@_;
	my $guid;
	use Digest::SHA1 qw(sha1);
	$guid = join('-', unpack('H8 H4 H4 H4 H12', sha1( shift().shift().time().rand().$<.$$)));
	return $guid;
}

####################
##### END HIDE ##### FWS 2.0 Web import block 
####################

=head2 createPassword

Return a random password or text key that can be used for temp password or unique configurable small strings.

        #
        # retrieve a password that is 6-8 characters long and does not contain commonly mistaken letters
        #
        my $tempPassword = $fws->createPassword(	
					composition	=> "qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM23456789"
					lowLength	=> 6,
					highLength	=> 8);

=cut


##################################################################
sub createPassword {
	my ($self, %paramHash) = @_;
	my $returnString;
	my @pass = split //,$paramHash{'composition'};
	my $length = int(rand($paramHash{'highLengthy'} - $paramHash{'lowLength'} + 1)) + $paramHash{'lowLength'};
	for(1..$length) { $returnString .= $pass[int(rand($#pass))] }
	return $returnString;
}



=head1 FILE METHODS

FWS methods that access the file system for its results.

=head2 fileArray

Return a directory listing into a FWS hash array reference.
        
	#
        # retrieve a reference to an array of data we asked for
        #
        my $fileArray = $fws->fileArray( directory   =>"/home/directory" );

        #
        # loop though the array printing the files we found
        #
	for my $i (0 .. $#$fileArray) {
	        print $fileArray->[$i]{"file"}. "\n";
	}

=cut

sub fileArray {
        my ($self,%paramHash) =@_;

        #
        # ensure nothing scary is in the directory
        #
        $paramHash{'directory'} = $self->safeDir($paramHash{'directory'});

        #
        # pull the directory into an array
        #
        opendir(DIR, $paramHash{'directory'});
        my @getDir = grep(!/^\.\.?$/,readdir(DIR));
        closedir(DIR);

        my @fileHashArray;
        foreach my $dirFile (@getDir) {
                if (-f $paramHash{'directory'}.'/'.$dirFile) {

                        my %fileHash;
                        $fileHash{'file'}           = $dirFile;
                        $fileHash{'fullFile'}       = $paramHash{'directory'}.'/'.$dirFile;
                        $fileHash{'size'}           = (stat $fileHash{'fullFile'})[7];
                        $fileHash{'date'}           = (stat $fileHash{'fullFile'})[9];

                        #
                        # push it to the array
                        #
                        push (@fileHashArray,{%fileHash});
                }
        }
        return \@fileHashArray;
}


=head1 SAFETY METHODS

FWS Safety methods are used for security when using unknown parameters that could be malicious.   When ever data is passed to another method it should be wrapped in its appropriate safety method under the guidance of each method.

=head2 safeDir

All directories should be wrapped in this method before being applied.  It will remove any context that could change its scope to higher than its given location.  When using directories ALWAYS prepend them with $fws->{"fileDir"} or $fws->{"secureFileDir"} to ensure they root path is always in a known location to further prevent any tampering.  NEVER use a directory that is not prepended with a known depth!

	#
	# will return //this/could/be/dangerous
	#
	print $fws->safeDir("../../this/could/be/dangrous");
	
        #
        # will return this/is/fine
        #
	print $fws->safeDir("this/is/fine");

=cut

sub safeDir {
        my ($self, $incommingText) = @_;
        $incommingText =~ s/(\.\.|\||;)//sg;
        return $incommingText;
}


=head2 safeFile

All files should be wrapped in this method before being applied.  It will remove any context that could change its scope to a different directory.

        #
        # will return ....i-am-trying-to-change-dir.ext
        #
        print $fws->safeDir("../../i-am-trying-to-change-dir.ext");

=cut


sub safeFile {
        my ($self, $incommingText) = @_;
        $incommingText =~ s/(\/|\\|;|\|)//sg;
        return $incommingText;
}


=head2 safeSQL

All fields and dynamic content in SQL statements should be wrapped in this method before being applied.  It will add double tics and escape any escapes so you can not break out of a statement and inject anything not intended.

        #
        # will return this '' or 1=1 or '' is super bad
        #
        print $fws->safeSQL("this ' or 1=1 or ' is super bad");

=cut

sub safeSQL {
        my ($self, $incommingText) = @_;
        $incommingText =~ s/\'/\'\'/sg;
        $incommingText =~ s/\\/\\\\/sg;
        return $incommingText;
}


##########################################################################################
=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-lite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-Lite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::Lite


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-Lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-Lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-Lite>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-Lite/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::Lite
