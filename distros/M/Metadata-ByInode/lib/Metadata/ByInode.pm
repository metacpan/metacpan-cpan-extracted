package Metadata::ByInode;
use strict;
use warnings;
use Carp;
use DBI;
use Cwd;
use base 'Metadata::ByInode::Search';
use base 'Metadata::ByInode::Indexer';


#our @ISA = qw(Metadata::ByInode::Search Metadata::ByInode::Indexer);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.17 $ =~ /(\d+)/g;
my $DEBUG = 0;
sub DEBUG : lvalue { $DEBUG }


sub new {
	my ($class,$self)= (shift,shift);
	$self||={};

	$self->{abs_dbfile} or $self->{dbh} or croak('no (abs_dbfile )arg or open (dbh) arg passed to constructor');
	
	bless $self, $class;

	return $self;
}

=pod

=head1 NAME

Metadata::ByInode - Extend metadata in relation to file's inode using a database.


=head1 SYNOPSIS

	use Metadata::ByInode;
	
	my $mbi = new Metadata::ByInode({ abs_dbfile => '/home/myself/mbi.db' });
	
	# index files for quick lookup
	$mbi->index('/home/myself/photos/family');

	# lookup a file by filename and location
	my $results = 
		$mbi->search({ 
			abs_loc => '/home/myself/photos/family', 
			filename => 'ralph' 
		});

=head1 DESCRIPTION

This is primarily meant to be support for an indexer.
Ideally, this will look at a slice of the filesystem, make some deductions with
the indexer, and save that info.
You can use this module bare bones to set and get data on any files in the system.

The indexer is a module that inherits this one.

=head1 SEE ALSO

L<Metadata::ByInode::Indexer>

=head1 METHODS 

=head2 new()

Arguments are:

=over 4

=item dbh

(optional) existing database handle, otherwise DBD::Sqlite is used

=item abs_dbfile

(optional, required if you don't pass an open dbh) absoute path to sqlite file, will be created if not found.

=back

Example usage:
	
	my $mbi = new Metadata::ByInode;
	
	my $mbi = new Metadata::ByInode({
		abs_dbfile => '/home/myself/mystuff.db'		
	});


=head1 NOTE ON dbh

If you do not pass a dbh, the dbh is opened using DBI::SQLite at abs_path argument.
It will take care of commit and disconnect for you.

If you *do* pass it a dbh, we do not automatically commit and disconnect on DESTROY.
It is up to you what to do with it, if you set autocommit or need to commit later.

_finish_open_handles()

Will search the prepared handles we opened and finish them and commit.
It returns the number of prepared handles closed.


=cut	
	




sub _reset_db {
	my $self = shift;
	print STDERR __PACKAGE__."::_reset_db() called\n" if DEBUG;	
	
	unless( $self->dbh->do('DROP TABLE metadata') ) {			
		my $err =$DBI::errstr;
		die("cannot setup db, is DBD::SQLite installed? $! - ".$DBI::esstr);
	}


	$self->_setup_db or return 0;

	print STDERR __PACKAGE__."::_reset_db() done\n" if DEBUG;	
	
	return 1;
}

sub _setup_db {
	my $self = shift;
	
	print STDERR __PACKAGE__."::_setup_db() called\n" if DEBUG;	
	
	my $b = qq|CREATE TABLE IF NOT EXISTS metadata(
inode INTEGER(10) NOT NULL,
mkey VARCHAR(50) NOT NULL,
mvalue TEXT,
PRIMARY KEY (inode,mkey)
)|;

	unless( $self->dbh->do($b) ) {			
		my $err =$DBI::errstr;
		die("cannot setup db, is DBD::SQLite installed? $! - ".$DBI::esstr);
	}

	# must commit here to prevent error that when you search before you index, it fucks up

	$self->dbh->commit;

	print STDERR __PACKAGE__."::_setup_db() done\n" if DEBUG;	

	return 1;
}
=pod

=head1 _setup_db()

automatically called if using sqlite on a non existent file, and we just created it.
The table is :

	CREATE TABLE IF NOT EXISTS metadata (
		inode INTEGER(10) NOT NULL,
		mkey VARCHAR(50) NOT NULL,
		mvalue TEXT,
		PRIMARY KEY (inode,mkey)
	);

in previous version, mkey was 'key', but this caused problems in mysql


=head1 _reset_db()

will reset the table, drop and recreate metadata table.

=cut







sub dbh {
	my $self = shift;	

	
	unless( defined $self->{dbh} ){
		print STDERR __PACKAGE__."::dbh() was not defined.. will set up for sqlite..\n" if DEBUG;		
		
		$self->{abs_dbfile} or croak(
			"need open database handle (dbh) or absolute path to sqlite databse file (abs_dbfile) "
			."as construcctor argument to Metadata::ByInode");

		my $isnew=0;
		unless(-f $self->{abs_dbfile}){
			$isnew=1;		
		}
		
		# attempt to open sqlite db file
		if( $self->{dbh}= DBI->connect(
			"dbi:SQLite:".$self->{abs_dbfile},'','',{RaiseError=>0, AutoCommit=>0}) 
		){ 	
			$self->{_not_passed_as_argument} = 1;
		} 

		else {
				croak("ERR: [$!], could not connect db[".$self->{abs_dbfile}."] -[$DBI::errstr]-"); 
		}
				
		# if it didn't exist before, set up the metadata table.
		if ($isnew) {
			$self->_setup_db;
		}		
	}	
	return $self->{dbh};
}

=pod

=head1 dbh()

Returns open db handle. If you did not pass an open database handle to the constructor, it expects that you did pass an absolute path to where
you want an sqlite database file read. If it does not exist, it will be made and setup.

=head1 GET AND SET METHODS

There is distinguising difference between the get() and the set() methods.
The get() methods simply query the database. You can get metadata for a file that is
no longer on disk. 

The set() methods however, do NOT let you set metadata for a file that is not on disk.
This is on purpose. So if you use this for some kind of logging, you can get history.

Again:

You can get() metadata for files no longer on disk.
You can NOT set() metadata for files not on disk.

If you are using the default indexer in this distribution, files no longer on disk 
are automatically take out of the metadata database if they are not there any more.

=cut

sub set {
	### set called
	my $self = shift;
	my $arg = shift; $arg or confess('missing abs path or inode argument to set()');	
	my $hash = shift;
	
	my $inode = _get_inode($arg);
	
	# init replace query
	unless( defined $self->{_open_handle}->{replace} ){
	
		$self->{_open_handle}->{replace} = 
			$self->dbh->prepare('REPLACE INTO metadata (inode,mkey,mvalue) VALUES(?,?,?)');
			#$self->dbh->prepare('INSERT INTO metadata (inode,mkey,mvalue) VALUES(?,?,?)');
			
	}
	
	for (keys %{$hash}){
		$self->{_open_handle}->{replace}->execute($inode,$_,$hash->{$_}) or confess($DBI::errstr);
	}	
	

	return 1;
}
=pod

=head2 set()

Sets meta for a file. First argument is abs_path or inode. Second argument is hash ref.
	
	$idx->set('/path/to/what',{ client => 'joe' });
	$idx->set(1235,{ client => 'hey', size => 'medium' });
	
=cut



sub get {
	my $self = shift;
	my $arg = shift; $arg or croak('must provide inode or abs path arg');
	my $key = shift; $key or croak('get() missing key argument');

	### get called
	### $arg
	### $key
	
	my $inode = $self->_search_inode($arg); # should be a search to the db only
	### $inode
	$inode or return;

	
	unless( defined $self->{_open_handle}->{select_by_key} ){
		$self->{_open_handle}->{select_by_key} = 
			$self->dbh->prepare('SELECT mvalue FROM metadata WHERE inode=? AND mkey=?');		
	}	
	
	$self->{_open_handle}->{select_by_key}->execute($inode, $key);
	my $value = ( $self->{_open_handle}->{select_by_key}->fetch )->[0];
	
	### $value
	defined $value or return; # could be 0

	return $value;	

}
=pod

=head2 get()

First argument is inode number, or absolute path to file.

If no metadata *is* found, returns undef.

	$mbi->get('/path/to/file','description');
	$mbi->get(1235,'description');

If value is 0, returns 0

=cut

sub get_all {
	my $self = shift;
	my $inode = shift; $inode or croak('missing inode argument to get_all()');
	$inode = $self->_search_inode($inode) or return;

	# init select query
	unless( defined $self->{_open_handle}->{select_all} ){
		$self->{_open_handle}->{select_all} = 
			$self->dbh->prepare('SELECT mkey,mvalue FROM metadata WHERE inode = ?');
	}
	

	$self->{_open_handle}->{select_all}->execute($inode); 

	
	my $meta = {};	
	while( my $row = $self->{_open_handle}->{select_all}->fetch ){		
		$meta->{ $row->[0] } = $row->[1];	
	}
	
	scalar ( keys %{$meta} ) or return; 

	# create pseudo abs_path?
	$meta->{abs_path} = $meta->{abs_loc}.'/'.$meta->{filename};
	
	return $meta;
}
=pod

=head2 get_all()

Returns hash with all metadata for one file.
First argument is abs_path or inode.

	my $meta = $idx->get_all('/path/to/this');

	my $meta = $idx->get_all(1245);

Please note: get() methods do NOT check for file existence, they just query the database for
information.

=cut
# TODO: REFINE THIS
=head2 NOTE ABOUT get() AND set()

get() methods do NOT test for file existence on disk!
They just try to fetch the data from the database.

however, if you use a set() method and you file definition is not inode, that is,
if you try to set() metadata and you specify an absolute path, then we DO test for
file existence.

You cannot set() metadata for files that are not on disk

You *can* query for metadata for files that are NOT on disk.

=head1 INTERNAL METHODS

=cut

sub _search_inode {
	####  _search_inode called
	my $self = shift;
	
	my $arg = shift; 
	#### $arg
	$arg or croak('_search_inode() missing argument');
	
	if ($arg=~/^\d+$/){ 
		#### digits, assumed to be inode, will return it without lookup
		return $arg;	
	}	

	my $abs_path = Cwd::abs_path($arg);

	$abs_path=~/^(\/.+)\/([^\/]+)$/ or croak("arg is not filepath");
	my ($abs_loc,$filename)=($1,$2);

	#### $abs_loc
	#### $filename

	unless( defined $self->{_open_handle}->{f} ){
		$self->{_open_handle}->{f} = 
			$self->dbh->prepare(q{
SELECT inode FROM metadata WHERE mkey='abs_loc' AND mvalue=? and inode=
 (SELECT inode FROM metadata WHERE mkey='filename' AND mvalue=?);
});

	}

	$self->{_open_handle}->{f}->execute($abs_loc,$filename);

	my $row = $self->{_open_handle}->{f}->fetch;
	#### $row
	my $inode = $row->[0];	
	#### $inode
	return $inode;	
}
=pod

=head1 _search_inode()

To get the inode from database.

argument is absolute path.
will look up in the database to see if we can resolve to an inode.

If the path provided does not match up with our entries, returns undef.
This would mean no metadata matches this path.

If argument provided is all digits, assumes this *is* an inode and returns it.

Croaks if its not ann inode or we cant split argument into an absolute path and filename.
=cut

sub _get_inode {
	my $arg = shift; $arg or croak('_get_inode() missing argument');
	
	if ($arg!~/^\d+$/){ 
		my $abs_path = Cwd::abs_path($arg);
		my @s = 	stat $abs_path or warn("$! - File not on disk? cant stat normalized:[$abs_path]") and return; 
		# TODO: if no stat, then we should change the time metadata that this file does no longer exist
		# furthermore, should we look up the inode in the database first?
		$arg = $s[1];
	}
	
	return $arg;
}
=pod

=head1 _get_inode()

To get the inode from disk.

Takes argument and tries to return inode. Argument can be absolute file path.
If argument is an inode, returns same value.
If argument is word chars, tries to stat for inode.
Returns undef if absolute path not on disk.

=head1 DESTROY() METHODS

The destructor will close open db handles, and commit changes.
If the dbh was passed to the constructor, this will not happen
and it is up to you to deal with your database settings (autocommit
etc).

=cut


sub _finish_open_handles {
	my $self = shift;

	$self->{_commit} ||= 0;

	for ( keys %{$self->{_open_handle}} ){
		my $handle = $_;
		### $handle 
		if (defined $self->{_open_handle}->{$handle}){
			$self->{_open_handle}->{$handle}->finish;
			$self->{_commit}++;
		}	
	 }
	return $self->{_commit};
}

sub DESTROY {
	my $self = shift;

	# we only do these when the db was opened from this object. Otherwise it's their business.
	
	if ( defined $self->{dbh} and defined $self->{_not_passed_as_argument} ){
		# TODO : what if they still want the handle!!!!!?????
		# if the dbhandle was created here, then close it. otherwise, nothing.
		# seems like a compromise.
		if ( $self->_finish_open_handles ){	
			$self->dbh->commit;
				
		}
		
		 # get rid of annoying warning
		open (STDERR,">>/dev/null");

		$self->dbh->disconnect; # TODO : warns that 'closing dbh with active statement handles at lib/Metadata/ByInode.pm'
		# WHY does it warn???
		close STDERR;		
	}


}

1;

=pod

=head1 CAVEATS

All paths are resolved for symlinks, NOTE!

=head1 PROS AND CONS

=head2 PROS

Inode is very stable in a unix filesystem. 

If the file is moved within the filesystem(within the same partition), the inode does not change.
If you overrite the file with a copy command, the target file's inode does not change.
If you rename the file, the inode does not change.

If you are indexing large ammounts of data, you can backup, and if you restore via copy, the inode does not change. 

=head2 CONS

If you move the file to another filesystem (to another disk, to another partition) the inode of the file changes.

=head1 BUGS

Please contact AUTHOR.

=head1 AUTHOR

Leo Charre <leo@leocharre.com>

=cut
