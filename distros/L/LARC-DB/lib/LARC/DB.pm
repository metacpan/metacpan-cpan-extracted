package LARC::DB;

use DBI;
use File::Path;
use warnings;
use strict;

=head1 NAME

LARC::DB - Provides a methode for storing SQLite DBs in a pleasantly organized manner.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use LARC::DB;

    my $ldb = LARC::DB->new();

=head1 FUNCTIONS

=head2 new

Initializes the module. No arguements are taken. No arguements are required.

    my $ldb = LARC::DB->new();

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	if (!defined($args{app})) {
		$args{app}='';
	}

	if (!defined($args{version})) {
		$args{version}='';
	}

	my $self={error=>undef, errorString=>''};
	bless $self;

	#makes the $ENV{HOME} is defined
	if (!defined($ENV{HOME})) {
		warn('LARC-DB new:2: The enviromental variable "HOME" is not defined');
		$self->{error}=2;
		$self->{errorString}='The enviromental variable "HOME" is not defined';
		return $self;
	}

	$self->{base}=$ENV{HOME}."/larc/DB/";

	#checks to see if it needs inited or not
	if (! -e $self->{base}) {
		$self->{init}=0;
	}else {
		#makes sure $self->{base} is a directory
		if (! -d $self->{base}) {
			warn('LARC-DB new:1: "'.$self->{base}.'" is not a directory');
			$self->{error}=1;
			$self->{errorString}='"'.$self->{base}.'" is not a directory';
		}else {
			#init is good if it is a directory
			$self->{init}=1;
		}
	}

	return $self;
}

=head2 connect

This generates to a SQLite DB connecting and returns a DBI object.

    my $dbh=$ldb->connect('some/DB');
    if($ldb->{error}){
        print "ERROR!";
    }

=cut

sub connect{
	my $self=$_[0];
	my $db=$_[1];

	$self->errorBlank;

	if (!$self->validname($db)) {
		warn('LARC-DB connect:12: "'.$db.'" is a invalid name');
		$self->{error}=12;
		$self->{errorString}='"'.$db.'" is a invalid name';
		return undef;
	}

	my $dbfile=$self->{base}.$db.'.sqlite';

	if (! -e $dbfile) {
		warn('LARC-DB connect:4: "'.$self->{base}.$db.'.sqlite" does not exist. '.
			 'Thus connecting to "'.$db.'" is not possible');
		$self->{error}=4;
		$self->{errorString}='"'.$self->{base}.$db.'.sqlite" does not exist. '.
		                     'Thus connecting to "'.$db.'" is not possible';
		return undef;
	}

	my $dbh = DBI->connect("dbi:SQLite:dbname=".$dbfile,"","");

	return $dbh;
}

=head2 DBexists

Checks if a database exists or not. One one option is accepted and
that is the DB name.

    my $returned=$ldb->DBexists('foo/bar');
    if($ldb->{error}){
        print 'Error:'.$ldb->{error}.':'.$error->{errorString};
    }
    if($returned){
        print 'It exists';
    }

=cut

sub DBexists{
	my $self=$_[0];
	my $db=$_[1];

	$self->errorBlank;

	if (!$self->validname($db)) {
		warn('LARC-DB connect:12: "'.$db.'" is a invalid name');
		$self->{error}=12;
		$self->{errorString}='"'.$db.'" is a invalid name';
		return undef;
	}

	my $dbfile=$self->{base}.$db.'.sqlite';

	#return if it does not exist
	if (! -e $dbfile) {
		return undef;
	}

	#it exists
	return 1;
}

=head2 init

This initiliazes the support stuff for it all. It currently just creates
'~/larc/DB/' if needed.

    $ldb->init();
    if($ldb->{error}){
        print "ERROR!";
    }

=cut

sub init{
	my $self=$_[0];

	$self->errorBlank;

	#create the larc directory
	if (!mkdir($ENV{HOME}.'/larc/')) {
		warn('LARC-DB init:3: Failed to create "~/larc/"');
		$self->{error}=3;
		$self->{errorString}='Failed to create "~/larc/"';
		return undef;
	}

	#create the SQLite storage directory
	if (!mkdir($ENV{HOME}.'/larc/DB')) {
		warn('LARC-DB init:3: Failed to create "~/larc/DB"');
		$self->{error}=3;
		$self->{errorString}='Failed to create "~/larc/DB"';
		return undef;
	}

	return 1;
}

=head2 list

List DBs under a specific path. The returned value is an array.

Any thing ending in '/' is a directory. If something is both a
directory and DB, both an entry for the DB and directory is listed.

Any thing beginning with an '.' is not returned.

    my @DBs=$ldb->list('some/');
    if($ldb->{error}){
        print "ERROR!";
    }

=cut

sub list{
	my $self=$_[0];
	my $db=$_[1];

	#makes sure it is a valid name
	if (!$self->validname($db)) {
		warn('LARC-DB list:12: "'.$db.'" is a invalid name');
		$self->{error}=12;
		$self->{errorString}='"'.$db.'" is a invalid name';
		return undef;
	}

	$self->errorBlank;

	my $dbpath=$self->{base}.$db;

	#errors if it is just a DB or does not exist
	if (! -d) {
		warn('LARC-DB list:11: The specified, "'.$dbpath
			 .'", is either just a DB or does not exist');
		$self->{error}=11;
		$self->{errorString}='The specified, "'.$dbpath
			                 .'", is either just a DB or does not exist.';
		return undef;		
	}

	#opens the dir for latter use by readdir
	if (opendir(DBDIR, $dbpath)){
		warn('LARC-DB list:13: opendir failed for "'.$dbpath.'"');
		$self->{error}=13;
		$self->{errorString}='opendir failed for "'.$dbpath.'"';
		return undef;
	}

	#reads it and removes any thing starting with a period
	my @dir=grep(!/^\./, readdir(DBDIR));

	#process @dir
	my $dirInt=0;
	my @return;
	while (defined($dir[$dirInt])) {
		#only adds it if it is not a dot file
		if (! $dir[$dirInt] =~ /^\./ ) {
			#if it is a directory add it to the return array with / appended
			#if not, just add it
			if(-d $dbpath.'/'.$dir[$dirInt]){
				push(@return, $dir[$dirInt].'/');
			}else {
				push(@return, $dir[$dirInt]);
			}
		}
		$dirInt++;
	}

	return @return;
}

=head2 newdb

Creates a new DB.

    $ldb->newdb('some/DB');
    if($ldb->{error}){
        print "ERROR!";
    }

=cut

sub newdb{
	my $self=$_[0];
	my $db=$_[1];

	#makes sure it is a valid name
	if (!$self->validname($db)) {
		warn('LARC-DB newdb:12: "'.$db.'" is a invalid name');
		$self->{error}=12;
		$self->{errorString}='"'.$db.'" is a invalid name';
		return undef;
	}

	$self->errorBlank;

	my $dbpath=$self->{base}.$db;
	my $dbfile=$dbpath.'.sqlite';

	if ($dbpath =~ /\/$/) {
		#make sure the directory does not already exist
		if ( -e $dbpath) {
			warn('LARC-DB newdb:4: "'.$dbpath.'" already exists');
			$self->{error}=6;
			$self->{errorString}='"'.$dbpath.'" already exists.';
			return undef;
		}
		
		#error if creating it fails
		if (!mkpath($dbpath)) {
			warn('LARC-DB newdb:10: Make path failed for "'.$dbpath.'"');
			$self->{error}=10;
			$self->{errorString}='Mkpath failed for "'.$dbpath.'".';
			return undef;			
		}

		return 1;
	}

	#makes sure it does not already exist
	if ( -e $dbfile) {
		warn('LARC-DB newdb:4: "'.$dbfile.'" already exists');
		$self->{error}=6;
		$self->{errorString}='"'.$dbfile.'" already exists.';
		return undef;
	}

	#this will create the new one
	if (!DBI->connect("dbi:SQLite:dbname=".$dbfile,"","")){
		warn('LARC-DB newdb:5: Fa')
	}

	return 1;
}

=head2 rmdb

Removes a DB.

    $ldb->rmdb('some/DB');
    if($ldb->{error}){
        print "ERROR!";
    }

=cut

sub rmdb{
	my $self=$_[0];
	my $db=$_[1];

	#makes sure it is a valid name
	if (!$self->validname($db)) {
		warn('LARC-DB list:12: "'.$db.'" is a invalid name');
		$self->{error}=12;
		$self->{errorString}='"'.$db.'" is a invalid name';
		return undef;
	}

	$self->errorBlank;

	my $dbpath=$self->{base}.$db;
	my $dbfile=$dbpath.'.sqlite';

	#removes it if a dir is specified
	if ($db =~ /\/$/) {
		#makes sure it exists
		if (! -d $dbpath) {
			warn('LARC-DB rmdb:4: "'.$dbpath.'" does not exist');
			$self->{error}=4;
			$self->{errorString}='"'.$dbpath.'" does not exist.';
		return undef;			
		}

		#makes is removed
		if (!rmdir($dbpath)) {
			warn('LARC-DB rmdb:9: Failed to unlink "'.$dbfile.'".');
			$self->{error}=9;
			$self->{errorString}='Failed to unlink "'.$dbfile.'".';
			return undef;
		}

		return 1;
	}

	#makes sure it does not already exist
	if (! -e $dbfile) {
		warn('LARC-DB rmdb:4: "'.$dbfile.'" does not exist');
		$self->{error}=4;
		$self->{errorString}='"'.$dbfile.'" already exist.';
		return undef;
	}

	#try to remove it
	if (!unlink($dbfile)) {
		warn('LARC-DB rmdb:8: Failed to unlink "'.$dbfile.'".');
		$self->{error}=8;
		$self->{errorString}='Failed to unlink "'.$dbfile.'".';
		return undef;
	}

	return 1;
}

=head2 validname

This checks if a DB name is valid or not.

    if($returned=$ldb->validname('some/DB')){
        print 'Invalid name'.
    }

=cut

sub validname{
	my $self=$_[0];
	my $name=$_[1];

	#return if it is undef
	if (!defined($name)) {
		return undef;
	}

	#return if it begins it matches /\/./
	if ($name =~ /\/./) {
		return undef;
	}

	#returns if it matches /^./
	if ($name =~ /^./) {
		return undef;
	}

	#it is valid
	return 1;
}

=head2 errorBlank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorBlank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 STORAGE

The base dir used is '$ENV{HOME}/larc/DB/'. The specified DB is then tacked onto
that as a path with '.sqlite' appended to the end. So the DB 'foo/bar' then becomes
'$ENV{HOME}/larc/DB/foo/bar.sqlite'. This allows a DB to have sub DBs in regards
to how the path looks.

A DB may not begin with '.' or have that any were after an '/'. Thus the following are
all invalid.

    ./someDB
    some/.DB
    some/.something/DB

=head1 ERROR CODES

=head2 1

The base directory, '~/larc/DB/', does exists, but is not a directory.

=head2 2

The enviromental variable 'HOME' is not defined.

=head2 3

Failed to create the directory '~/larc' or '~/larc/DB';

=head2 4

The database does not exist.

=head2 5

Failed to create the new SQLite file.

=head2 6

The DB already exists.

=head2 7

Reservered for future use.

=head2 8

Failed to unlink a DB file.

=head2 9

Failed to remove the specified directory.

=head2 10

Mkpath failed.

=head2 11

The specified DB is not also a directory.

=head2 12

Invalid DB name.

=head2 13

Opendir error.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-larc-db at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LARC-DB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LARC::DB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LARC-DB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LARC-DB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LARC-DB>

=item * Search CPAN

L<http://search.cpan.org/dist/LARC-DB>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of LARC::DB
