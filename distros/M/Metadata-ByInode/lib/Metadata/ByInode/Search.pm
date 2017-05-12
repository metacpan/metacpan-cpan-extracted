package Metadata::ByInode::Search;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)/g;


#returns boolean, did a search complete?
sub _sran {
	my $self= shift;
	$self->{_search} or return 0;	
	return 1;
}



sub results_count {
	my $self = shift;
	$self->_sran or return; 
	
	return $self->{_search}->{count};
}

sub search_results {
	my $self = shift;
	$self->_sran or return;	
	
	$self->results_count or return []; # return empty if none found
	
	unless ( defined  $self->{_search}->{results_array})  {
	
		for (keys  %{$self->{_search}->{data}} ){
			my $inode = $_;
			my $hash = $self->{_search}->{data}->{$inode};
			$hash->{inode} = $inode;
			push @{$self->{_search}->{results_array}},$hash;		
		}
	
	}
	
	return $self->{_search}->{results_array};	
}

sub search { # multiple key lookup and ranked
	my $self = shift;	
	my $arg = shift; ref $arg eq 'HASH' or croak('missing arg to search'); 		

	# keys in search args?

	keys %{$arg} or croak('no arguments, must be hash ref with args and vals');
	
	$self->_search_reset;
	

	my $argcount = keys %{$arg};
	### $argcount

	my $select= {
	 'like'  => $self->dbh->prepare("SELECT * FROM metadata WHERE mkey=? and mvalue LIKE ?"),
	 'exact' => $self->dbh->prepare("SELECT * FROM metadata WHERE mkey=? and mvalue=?"),
	};	
	my $sk = 'like'; #default

	my $RESULT = {};

	for ( keys %{$arg} ){
		my ($key,$value)= ($_,undef); 
		
		if ($key=~s/:exact$//){ # EXACT, so they can override the like
			$value = $arg->{$_};
			$sk= 'exact';
		}
		else { # LIKE		
			$key=~s/:like$//; # just in case
			$value = "%".$arg->{$_}."%";
			$sk ='like'			
		}
		
		$select->{$sk}->execute($key,$value) or warn("cannot search? $DBI::errstr");

		while ( my $row = $select->{$sk}->fetch ){
			$RESULT->{$row->[0]}->{_hit}++;
		}		
		
	}

	# just leave the result whose count matches num of args?
	# instead should order them to the back.. ?
	my $count = 0;
	for (keys %{$RESULT}){
		
		if( $RESULT->{$_}->{_hit} < $argcount ){
			delete $RESULT->{$_};
			next;			
		}
		$RESULT->{$_} = $self->get_all($_);
		$count++;		
	}
	
	$self->{_search}->{count} = $count;
	$self->{_search}->{data}  = $RESULT;
	return $RESULT;
}






sub _search_reset {
	my $self = shift;	
	$self->{_search} = undef;	
	return 1;
}

1;
__END__

=pod

=head1 NAME

Metadata::ByInode::Search

=head1 DESCRIPTION

this is not meant to be used directly. this is part of Metadata::ByInode

=head1 search()

Parameter is a hash ref with metadata keys and values you want to look up by.
Imagine you want to search for all metadata for a file whose absolute path you know.


	my $RESULT = $mbi->search ({
		filename => 'pm',
		abs_loc => '/home/leo/devel/Metadata-ByInode/lib'
	},);
	
	
Returns hash of hashes. Key is inode.

search() is NOT an exact match. it is a LIKE function by default.
If you want some keys to be exact then you must defined the key as:

	my $RESULT = $mbi->search ({
		filename => 'pm',
		'abs_loc:exact' => '/home/leo/devel/Metadata-ByInode/lib'
	},);

This would make the abs_loc be exactly '/home/leo/devel/Metadata-ByInode/lib', 
and the filename would match '*pm*'.

Notice that this is the same thing:

	my $RESULT = $mbi->search ({
		'filename:like' => 'pm',
		'abs_loc:exact' => '/home/leo/devel/Metadata-ByInode/lib'
	},);

	


example output:

	 $RESULT: {
	            '7496560' => {
	                           abs_loc => '/home/leo/devel/Metadata-ByInode/lib/Metadata',
	                           filename => 'ByInode.pm',
	                           ondisk => '1164911227'
	                         },
	            '7725851' => {
	                           abs_loc => '/home/leo/devel/Metadata-ByInode/lib/Metadata/ByInode',
	                           filename => 'Search.pm',
	                           ondisk => '1164911227'
	                         },
	            '7725852' => {
	                           abs_loc => '/home/leo/devel/Metadata-ByInode/lib/Metadata/ByInode',
	                           filename => 'Index.pm',
	                           ondisk => '1164911227'
	                         }
	          }



=head1 search_results()

Return the search results in an array ref, each array ref has an anon hash with file details as:

	$search_results = [
		{ abs_loc => '/tmp',		   filename => 'file1', ondisk => 1231231231, inode => 234, abs_path => '...'  },
		{ abs_loc => '/tmp/dir',   filename => 'file2', ondisk => 1231231231, inode => 143, abs_path => '...'  },	
	];

If no search results are present beacuse nothing was found, returns [] anon array ref, empty.

If no search was run, returns undef.


=head1 results_count()

If a search was run, how many results are there, returns number. 
if nothing was found, returns 0

Returns undef if no search was run.


=head1 SEE ALSO

L<Metadata::ByInode> and L<Metadata::ByInode::Indexer>


=head1 AUTHOR

Leo Charre <leo@leocharre.com>

=cut




