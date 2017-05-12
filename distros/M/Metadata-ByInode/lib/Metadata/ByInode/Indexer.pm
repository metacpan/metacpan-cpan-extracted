package Metadata::ByInode::Indexer;
use warnings;
use strict;
use Carp;
use Cwd;
use File::Find::Rule;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)/g;
#use Smart::Comments '###';

my $DEBUG =1;
sub DEBUG : lvalue { $DEBUG }

my $TEST =0;
sub TEST : lvalue { $TEST }


=pod

=head1 NAME

Metadata::ByInode::Indexer - customizable file and directory indexer

=head1 DESCRIPTION 

part of Metadata::ByInode
not meant to be used alone!

=head1 index()

First argument is an absolute file path.

If this is a dir, will recurse - NON inclusive
that means the dir *itself* will NOT be indexed

if it is a file, will do just that one.

returns indexed files count

by default the indexer does not index hidden files
to index hidden files,

 $m = new Metadata::ByInode::Indexer({ 
   abs_dbfile => '/tmp/mbi_test.db', 
   index_hidden_files => 1 
 });
 
 $m->index('/path/to/what'); # dir or file
 
=cut


sub _teststop {
	my $self = shift;
	my $arg = shift;
	if (defined $arg and $arg=~/^\d+$/){
		$self->{_teststop} = $arg;
		print STDERR " teststop changed to $arg\n" if DEBUG;
	}
	$self->{_teststop}||= 1000;
	return $self->{_teststop};	
}



sub index {
	my $self = shift;
	my $arg = shift; $arg or croak('missing argument to index');
	my $abs_path = Cwd::abs_path($arg);

	# index hidden? follow symlinks?	
	my $files_indexed = 0;	
	# make sure if this is a dir, we use mindepth so we do NOT index itself
	my $ondisk = time;


	$self->_delete_treeslice($abs_path);


	unless ($self->{index_hidden_files}){
		print STDERR " setting rule for no hidden files.. " if DEBUG;	
		$self->finder->not_name( qr/^\./ ); # no hidden files	, but will this index a reg file ina  hidden dir?
		print STDERR "done.\n" if DEBUG;
	}
	
	my @files = $self->finder->in($abs_path);

	if (DEBUG){
		printf STDERR " we count %s files\n", scalar @files;
		printf STDERR " we will stop at %s (DEBUG is on)\n", $self->_teststop;
	}



	
	my $runonce_=0;
	for ( @files ){  #### Working===[%]     done
		
		#take out first if it's self and a dir, we do not index ourselves in this case! 
		unless($runonce_){
			$runonce_=1;
			if ($abs_path eq $_ and -d $_){
				print STDERR " index() took out self.. $_\n" if DEBUG;
				next;
			}		
		}
		
		if ( (DEBUG or TEST) and $self->_teststop == $files_indexed ){ 
			printf STDERR " reached teststop of %s files\n", $self->_teststop;
			last;
		}

		# make sure we do not index the original argument	
	
		my $abs_path = $_;
		$abs_path=~/^(.+)\/([^\/]+$)/ or die(__PACKAGE__.'115');
		my ($abs_loc,$filename)=($1,$2);

	#	unless( $self->{index_hidden_files} ){
	#		if ($abs_loc=~/\/\./ or $filename=~/^\./){ next; } # /. anywhere
	#	}
		

		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks)
           = lstat($abs_path);
		
		if ( -l _ or -p _ or -b _){
			next;
		}	
			
		$self->_reset;
			
		$self->_set('abs_loc',$abs_loc);
		$self->_set('filename',$filename);
		$self->_set('ondisk',$ondisk);

		if ($self->_save_stat_data){
		
			$self->_set('size',$size) if $size;
			$self->_set('ctime',$ctime) if $ctime;
			$self->_set('mtime',$mtime) if $mtime;

			if ( -f _ ){
				$self->_set( is_file => 1);
			}
			elsif( -d _ ){
				$self->_set( is_dir => 1 );
			}

			if ( -T _ ){
				$self->_set( is_text => 1 );
			}	
			elsif( -B _ ){
				$self->_set( is_binary => 1 );
			}
		}	
		
		$self->index_extra;	

		$self->set($ino,$self->_record); # set first arg can be inode or abs path, this should quicken with passing it inode
		$files_indexed++;

	}
			
	my $seconds_elapsed = int(time - $ondisk);
	### $seconds_elapsed
	### $files_indexed

	$self->dbh->commit;
	
	return $files_indexed;	
}

sub _save_stat_data {
	my $self = shift;
	$self->{save_stat_data} ||= 0;
	return $self->{save_stat_data};
}

=for old
# through system find
# causes problems on some systems!!!!
sub find_abs_paths_systemfind {
	my $abs_path= shift;
	$abs_path or die();	
	my $mindepth = (-d $abs_path) ? '-mindepth 1' : '';
	my @abs_paths = split(/\n/,`find "$abs_path" $mindepth`);
	return \@abs_paths;
}
=cut

sub finder {
	my $self = shift;
	unless( defined $self->{file_file_rule} ){
		$self->{file_find_rule} = new File::Find::Rule();
		defined $self->{file_find_rule} or die("cant get File::Find::Rule object");		
	}	
	return $self->{file_find_rule};
}





sub _reset {
	my $self = shift;	
	$self->{_current_record} = undef;
	return 1;
}

sub _set {
	my $self = shift;	
	no warnings;
	my ($key,$val)=(shift,shift); (defined $key and defined $val) 
		or confess("_set() missing [key:$key] or [val:$val]");
	$self->{_current_record}->{$key} = $val;
	return 1;
}

sub _record {
	my $self = shift;
	defined $self->{_current_record} or die($!);
	return $self->{_current_record};
}



sub index_extra {
	my $self = shift;	
	return 1;
}

=pod



=head1 USING THE INDEXER

by deafault we just record abs_loc, filename, ontime(timestamp we recorded it on)
you can use the method rule() which returns a L<File::Find::Rule> object, to do neat things..

	my $i = new Metadata::ByInode({ abs_dbfile => '/tmp/dbfile.db' });

	$i->finder->name( qr/\.mp3$|\.avi$/ );

	$i->index('/home/myself'); 

This would only index mp3 and avi files in your home dir.

=head2 finder()

returns File::Find::Rule object,
you can feed it rules before calling index()


=head1 CREATING YOUR OWN INDEXER

=head2 index_extra()

If you want to invent your own indexer, then this is the method to override.
For every file found, this method is run, it just inserts data into the record
for that file.
By default, all files will have 'filename', 'abs_loc', and 'ondisk', which is a
timestamp of when the file was seen (now).

for example, if you want the indexer to record mime types, you should override
the index_extra method as..

	package Indexer::WithMime;
	use File::MMagic;		
	use base 'Metadata::ByInode::Indexer';

	
	sub index_extra {
	
		my $self = shift;	
      
		# get hash with current record data
      my $record = $self->_record;      

		# by default, record holds 'abs_loc', 'filename', and 'ondisk'
      
	   # ext will be the distiction between dirs here
		if ($record->{filename}=~/\.\w{1,4}$/ ){ 
				
				my $m = new File::MMagic;
				my $mime = $m->checktype_filename( 
               $record->{abs_loc} .'/'. $record->{filename} 
            );
				
				if ($mime){ 
				   # and now we append to the record another key and value pair
					$self->_set('mime_type',$mime); 					
				}		
		}
	
		return 1;	
	}

Then in your script

	use Indexer::WithMime;

	my $i = new Indexer::WithMime({ abs_dbfile => '/home/myself/dbfistartedle.db' });

	$i->index('/home/myself');

	# now you can search files by mime type residing somewhere in that dir

   $i->search({ mime_type => 'mp3' });

   #or 
   $i->search({ 
      mime_type => 'mp3',
      filename => 'u2',
   });

=head2 _teststop()

returns how many files to index before stop
only happens if DEBUG is on.
default val is 1000, to change it, provide new argument before indexing.

	$self->_teststop(10000); # now set to 10k

You may also pass this ammount to the constructor

	my $i = new Metadata::ByInode( { _teststop => 500, abs_dbfile => '/tmp/index.db' });

=head2 _find_abs_paths()

argument is abs path to what base dir to scan to index, returns abs paths to all within
no hidden files are returned

Returns array ref with abs paths:

	$self->_find_abs_paths('/var/wwww');

=head2 _save_stat_data()

By default we do not save stat data, if you want to, then pass as argument to constructor:

	my $i = new Metadata::ByInode({ save_stat_data => 1 });

This will create for each entry indexed;

	ctime mtime is_dir is_file is_text is_binary size

If you are indexing 1k files, this makes little difference. But if you are indexing 1million,
It makes a lot of difference in time.

=head1 CHANGES

The previous version used the system find to get a list of what to index, now
we use File::Find::Rule

=head1 SEE ALSO

L<Metadata::ByInode> and L<Metadata::ByInode::Search>

=cut






# delete a slice of the indexed tree
sub _delete_treeslice {
	my $self = shift;
	my $arg = shift; $arg or croak('missing abs path arg to _delete_treeslice');
	my $ondisk = shift; #optional

	print STDERR "_delete_treeslice started\n" if DEBUG;
	
	my $abs_path = Cwd::abs_path($arg);
	## recursive delete
	## $abs_path
	## $ondisk

	#delete by location AND by time
	if ($ondisk) { # if this was a dir
		print STDERR " ondisk $ondisk, " if DEBUG;
	# YEAH! IT WORKS !! :)
		### was dir, will get rid of sub not updt
		unless (defined $self->{_open_handle}->{recursive_delete_o}){	
			$self->{_open_handle}->{recursive_delete_o} = $self->dbh->prepare( 
			q{DELETE FROM metadata WHERE inode IN }
		 .q{(SELECT inode FROM metadata WHERE mkey='abs_loc' AND mvalue LIKE ? AND inode IN }
		  .q{(SELECT inode FROM metadata WHERE mkey='ondisk' AND mvalue < ?));"}) 
			or croak( "_delete_treeslice() ".$self->dbh->errstr );
		}  
		
		$self->{_open_handle}->{recursive_delete_o}->execute("$abs_path%",$ondisk);
		my $rows_deleted_o = $self->{_open_handle}->{recursive_delete_o}->rows;
		### $rows_deleted_o
		$self->dbh->commit;
		print STDERR "done\n" if DEBUG;
		
			
	}

	# delete not by time
	else {
		print STDERR " regular, " if DEBUG;
	
	
=for did not work with mysql, only with sqlite
		unless (defined $self->{_open_handle}->{recursive_delete}){	
			$self->{_open_handle}->{recursive_delete} = $self->dbh->prepare( 
				q{DELETE FROM metadata WHERE inode IN ( SELECT inode FROM (select * from metadata) as x WHERE mkey='abs_loc' AND mvalue LIKE ? )} 
			) or croak( "_delete_treeslice() ". $self->dbh->errstr );# normal sub select bug in mysql, made up for here by selct * from .... as x
		}  
		
		$self->{_open_handle}->{recursive_delete}->execute("$abs_path%");
		my $rows_deleted = $self->{_open_handle}->{recursive_delete}->rows;
		### $rows_deleted	
		$self->dbh->commit;
		
=cut


		print STDERR " preparing.. " if DEBUG;

		# my which??
		print STDERR " preparing select 1.. " if DEBUG;
		my $inodes = $self->dbh->selectcol_arrayref("SELECT inode FROM metadata WHERE mkey='abs_loc' and mvalue LIKE '$abs_path%'");
		print STDERR "done.\n" if DEBUG;
		
		#print STDERR "executing select 1.. " if DEBUG;
		#$inodes->execute("$abs_path\%");
		#print STDERR "done.\n" if DEBUG;
		
		my $del = $self->dbh->prepare('DELETE FROM metadata WHERE inode=?');
		
		print STDERR "executing.. " if DEBUG;			
		for (@$inodes){
			$del->execute($_);
		}
		print STDERR "done.\n" if DEBUG;

		$self->dbh->commit;	
		
		

		
=for newway

	DOING A SUBSELECT LIKE THIS TAKES FOREEEEEVVVVVEEERRRRRRRRRRRR
		
		my $delete = $self->dbh->prepare( 
				q{DELETE FROM metadata WHERE inode IN( 
					SELECT inode FROM (select * from metadata) as temptable WHERE temptable.mkey='abs_loc' AND temptable.mvalue LIKE ?)}
		) or croak( "_delete_treeslice() ". $self->dbh->errstr );
		  
		print STDERR "done.\n" if DEBUG;
		
		print STDERR "executing.. " if DEBUG;
		$delete->execute("$abs_path\%");
		print STDERR "done.\n" if DEBUG;
		
		my $rows_deleted = $delete->rows;
		## $rows_deleted	
		$self->dbh->commit;	
=cut
		


		print STDERR "_delete_treeslice regular done\n" if DEBUG;
		
	}


	print STDERR "_delete_treeslice done\n" if DEBUG;

	return 1;
}

=pod

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut

1;
