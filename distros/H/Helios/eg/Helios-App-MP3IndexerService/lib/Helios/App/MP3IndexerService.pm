package Helios::App::MP3IndexerService;

use 5.008;
use strict;
use warnings;
use base 'Helios::Service';
use Data::Dumper;

use Helios::Error;
use Helios::LogEntry::Levels ':all';
use MP3::Info ();

our $VERSION = '2.00';

=head1 NAME

Helios::App::MP3IndexerService - Helios service to index MP3s to a database table

=head1 SYNOPSIS

 # start the service daemon
 helios.pl Helios::App::MP3IndexerService
 
 # submit jobs using the included cmd line utility
 locate .mp3|mp3submit4index.pl

=head1 DESCRIPTION

This is a sample application to demonstrate some of the features of the 
Helios distributed job processing system and how to write services for it.

=head1 DATABASE SCHEMA

The sql/schema.sql file contains the SQL to create the MP3_INDEX_TB table that 
MP3IndexerService will write all of its data to.  Edit it appropriately for 
your system and issue a command like the following:

 mysql -D indexer_db -u indexer_user -p < schema.sql

=head1 CONFIG PARAMETERS

The config.sh file contains the commands necessary to configure 
Helios::App::MP3IndexerService in the Helios collective database.  Edit the 
--value parameters to provide the database info for the indexer database 
(created above) and then run config.sh to complete 
Helios::App::MP3IndexerService configuration.

=head1 SERVICE START

Once that is done, you should be able to start the service with helios.pl:

 helios.pl Helios::App::MP3IndexerService

and then submit jobs to the service using the included mp3submit4index.pl 
program:

 find / -name "*\.mp3" -print | mp3submit4index.pl

Happy MP3 indexing!

=head1 RUN() METHOD

As always in Helios applications, the run() method is the main subroutine in 
the application.  It receives a job to process in the form of a Helios::Job 
object, it calls the subroutines or methods necessary to do the job processing, 
then it marks the job as successful or failed and returns.

This particular run() method:

=over 4

=item *

checks to make sure it can read the file it was given (and throws a 
Helios::Error::InvalidArg exception if it can't)

=item *

calls a method to parse the ID3 tags and other info of the MP3 file

=item *

calls a method to update the index table in the database with the new MP3 info

=item *

marks the job as successful unless any kind of exception was thrown.  If any 
kind of exception was thrown (either by throwing a Helios::Error exception, 
calling die(), or some other method), run() will log the error in the Helios 
log and mark the job as failed.

=back

Though Helios applications can become very complex, every service class 
follows this same basic, simple pattern.  This makes it easy in most cases to 
write Helios applications. 

=cut

sub run 
{
	my $self = shift;
	my $job = shift;
	my $config = $self->getConfig();
	my $args = $self->getJobArgs($job);
	
	my $filename = $args->{filename};
	
	eval {
		$self->logMsg($job, LOG_INFO, "Filename: $filename");
		unless (-r $filename ) { Helios::Error::InvalidArg->throw("Cannot read file $filename"); }

		# parse the MP3 tags and info
		my $mp3i = $self->parseMP3Info($filename);
		$self->logMsg($job, LOG_INFO, 'Parsed artist: '.$mp3i->artist.' title: '.$mp3i->title.' album: '.$mp3i->album);		
		if ($self->debug) { print Dumper($mp3i),"\n"; }

		# update the database with the new MP3 info		
		$self->updateDb($filename, $mp3i);

		# mark the job as completed successfully		
		$self->completedJob($job);
		1;
	} or do {
		# uhoh, an error occurred
		# we'll log an error message, and mark the job as failed
		my $E = $@;
		$self->logMsg($job, LOG_ERR, "$E");
		$self->failedJob($job,"$E");
	};
	
}

=head1 OTHER METHODS

=head2 parseMP3Info($filename)

Given a filename, parseMP3info() returns an MP3::Info object with information 
on the given MP3 file.

=cut

sub parseMP3Info 
{
	my $self = shift;
	my $filename = shift;
	
	return MP3::Info->new($filename);	
	
}


=head2 updateDb($filename, $mp3info_object)

Given the MP3 file and the MP3::Info object with that file's info, updateDb() 
adds the information on that MP3 to the database table, either through 
an UPDATE (if the filename is already in the table) or an INSERT (if the 
filename isn't already there).

Note that this method uses the Helios::Service->dbConnect() method to connect 
to the database, and uses database connection information set in the Helios 
configuration subsystem.  All the method need do is call the getConfig() 
method, and it has a hash with all of the configuration parameters for the 
current application running on the current host.

=cut 

sub updateDb 
{
	my $self = shift;
	my $filename = shift;
	my $mp3i = shift;
	my $config = $self->getConfig();

	my $sql;
	my $sth;

	# connect to the database	
	my $dbh = $self->dbConnect($config->{mp3db_dsn}, $config->{mp3db_user}, $config->{mp3db_pass});
	# is the file already in the table?
	my $fc = $dbh->selectrow_arrayref("SELECT COUNT(*) FROM mp3_index_tb WHERE pathname = ?", undef, ($filename));
	
	if ($fc->[0]) 
	{
		# this file is already in the table so we'll UPDATE it
		$sql = <<ENDUPDATESQL;
UPDATE mp3_index_tb 
SET
	artist = ?,
	title = ?,
	album = ?,
	tracknum = ?,
	genre = ?,
	year = ?,
	tracktime = ?,
	tracksize = ?,
	bitrate = ?,
	tagversion = ?,
	comment = ?
WHERE
	pathname = ?		
ENDUPDATESQL
		$sth = $dbh->prepare_cached($sql);
		$sth->execute(
			$mp3i->artist,
			$mp3i->title,
			$mp3i->album,
			$mp3i->tracknum,
			$mp3i->genre,
			$mp3i->year,
			$mp3i->time,
			$mp3i->size,
			$mp3i->bitrate,
			$mp3i->version,
			$mp3i->comment,
			$filename
		);
		$sth->finish();
		$self->logMsg($self->getJob(), LOG_INFO,"Updated $filename in database");
	}
	else
	{
		# it's not yet in the table, so we'll INSERT it
		$sql = <<ENDSQL;
INSERT INTO mp3_index_tb
	(pathname, artist, title, album, tracknum, genre, year, tracktime, tracksize, bitrate, tagversion, comment)
VALUES
	(?,?,?,?,?,?,?,?,?,?,?,?)
ENDSQL
		$sth = $dbh->prepare_cached($sql);
		$sth->execute(
			$filename,
			$mp3i->artist,
			$mp3i->title,
			$mp3i->album,
			$mp3i->tracknum,
			$mp3i->genre,
			$mp3i->year,
			$mp3i->time,
			$mp3i->size,
			$mp3i->bitrate,
			$mp3i->version,
			$mp3i->comment
		);
		$sth->finish();
		$self->logMsg($self->getJob(), LOG_INFO,"Inserted $filename in database");
	}
	
}



1;
__END__


=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Johnson.

Portions of this software are Copyright (C) 2014 by Logical Helion, LLC
where noted.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
