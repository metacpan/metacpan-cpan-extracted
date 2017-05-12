package DirDB;

require 5.005_62;
use strict;
use warnings;
use Carp;

our $VERSION = '0.12';

my $DefaultArrayImpl = ['Tie::File' =>DATAPATH => recsep => "\0"]; # may change
my %ArrayImpl;
sub TIEHASH {
	my $self = shift;
	my $rootpath = shift or croak "we need a rootpath";
	$rootpath =~ s#/+$##; # lose trailing slash(es)
	-d $rootpath or
	   mkdir $rootpath, 0777 or
	     croak "could not create dir $rootpath: $!";
	my $me = bless \"$rootpath/", $self;

	my %moreargs = @_;
	$ArrayImpl{$me} = $moreargs{ARRAY} || $DefaultArrayImpl;
	$me;
};

sub TIEARRAY {
	confess "DirDB does not support arrays yet, although as of version 0.11 you may store and retrieve array references";
};

sub TIESCALAR {
	confess "DirDB does not support scalars yet -- try Tie::Slurp";
};


sub EXISTS {
	my $rootpath = ${+shift};
	my $key = shift;
	$key =~ s/^ /  /; #escape leading space into two spaces
	# defined (my $key = shift) or return undef;
	$key eq '' and $key = ' EMPTY';
	-e "$rootpath$key" or -e "$rootpath LOCK$key";
};

sub recursive_delete($);
sub recursive_delete($){
# unlink a file or rm -rf a directory tree
	my $path = shift;
	unless ( -d $path and ! -l $path ){
		unlink $path;
		-e $path and die "Could not unlink [$path]: $!\n";
		return;
	};
	opendir FSDBFH, $path or croak "opendir $path: $!";
	my @DirEnts = (readdir FSDBFH);
	#warn "direrctoy $path contains [@DirEnts]";
	closedir FSDBFH;
	while(defined(my $entity = shift @DirEnts )){
		$entity =~ /^\.\.?\Z/ and next;
		 recursive_delete "$path/$entity";
	};
#1 && do{
#	opendir FSDBFH, $path or croak "opendir $path: $!";
#	my @DirEnts = (readdir FSDBFH);
#	warn "after deleting, direrctoy $path contains [@DirEnts]";
#	closedir FSDBFH;
#      };
	rmdir $path or die "could not rmdir [$path]: $!\n";

};

sub FETCH {
	my $ref = shift;
	defined (my $rootpath = $$ref) or croak "undefined rootpath";
	my $key = shift;
#	warn "fetching $key from $rootpath";
	$key =~ s/^ /  /; #escape leading space into two spaces
	# defined (my $key = shift) or return undef;
	$key eq '' and $key = ' EMPTY';
	sleep 1 while -e "$rootpath LOCK$key";
	-e "$rootpath$key" or return undef;
	if(-d "$rootpath$key"){
	
		tie my %newhash, ref($ref),"$rootpath$key";
		-f "$rootpath$key/ ARRAY" and do {
			my @TieArgs= split /\n/,tied(%newhash)->FETCHMETA('ARRAY');
			my $classname = shift @TieArgs;
			my @newarr;
		   eval{
			tie @newarr, $classname,
			map {
				$_ eq 'DATAPATH' ?
				"$rootpath$key/DATA" : $_
			} @TieArgs or die <<EOF;
Tie <<$classname, @TieArgs>> Failed with error <<$!>>
EOF
		   }; $@ and croak "string tie problem: $@";
			return 
				-f "$rootpath$key/ BLESS"
				?
				bless \@newarr, tied(%newhash)->FETCHMETA('BLESS')
				:
				 \@newarr;

		};
		$ArrayImpl{tied %newhash} = $ArrayImpl{$ref};
 		return 
			-f "$rootpath$key/ BLESS"
			?
			bless \%newhash, tied(%newhash)->FETCHMETA('BLESS')
			:
			 \%newhash;
	};

	local *FSDBFH;
	open FSDBFH, "<$rootpath$key"
	   or croak "cannot open $rootpath$key: $!";

	local $/ = undef;
	<FSDBFH>;
};

{
my %CircleTracker;
sub STORE {
	my ($ref , $key, $value,$Xbless) = @_;
	my $rootpath = $$ref;
	my ($bless, $underly);
	# print "Storing $value to $key in $$ref\n";
	my $rnd = join 'X',$$,time,rand(10000);
	
	$key =~ s/^ /  /; #escape leading space into two spaces
	$key eq '' and $key = ' EMPTY';
	my $refvalue = ref $value;
	if ($refvalue){

		if ($refvalue eq 'ARRAY'){
			my %newhash;
			tie %newhash, DirDB=>"$rootpath A$rnd";
			tied(%newhash)->STOREMETA('ARRAY', join "\n", @{$ArrayImpl{$ref}});
			my @TieArgs = map {
				$_ eq 'DATAPATH' ? "$rootpath$key/DATA" : $_
			} @{$ArrayImpl{$ref}};
			$Xbless and
				tied(%newhash)->STOREMETA('BLESS', $Xbless);
		 	sleep 1 while !mkdir "$rootpath LOCK$key",0777;
		 	{
			  no warnings;
			  rename "$rootpath$key", "$rootpath GARBAGE$rnd"; 
			};
			rename "$rootpath A$rnd","$rootpath$key";
			my @NewArr = @$value;
			my $CN = shift @TieArgs;
		    eval{
			tie @$value,
				# $TieArgs[0],@TieArgs[1..$#TieArgs]
				$CN,@TieArgs
			or die "array tie to <<$CN, @TieArgs>> failed <<$!>>\n";
			@$value = @NewArr;
		    }; my $ERR = $@;
			rmdir "$rootpath LOCK$key";
		    $ERR and croak "DirDB arrayref store problem: $ERR";
			eval {recursive_delete "$rootpath GARBAGE$rnd"};
		 	if($@){
				croak "GC problem: $@";
		 	};
		 	return;
		};

		if ( $CircleTracker{$value}++ ){
	          croak "$ref version $VERSION cannot store circular structures\n";
		};


		unless ($refvalue eq 'HASH'){ 
		  ($bless,$underly) = ( "$value" =~ /^(.+)=([A-Z]+)\(/ );
		  {
			 no warnings; #suppress uninitalized value warning
			$underly eq 'HASH' and goto gottahash;
			$underly eq 'ARRAY' and do{
				STORE($ref, $key, [@$value],$bless);
				return;
			};
	          croak 
		   "$ref version $VERSION only stores references to HASH, not $underly blessed to $refvalue\n";	
		  }
			
		};
		gottahash:	
		if (tied (%$value)){
			# recursive copy
		 tie my %tmp, ref($ref), "$rootpath TMP$rnd" or
		   croak "tie failed: $!";
		 eval{
		 	# %tmp = %$value

			my ($k,$v);
			while(($k,$v) = each %$value){
				$tmp{$k}=$v;
			};
		 };
		 # print "$rootpath TMP$rnd should now contain @{[%$value]}\n";
		 if($@){
		    my $message = $@;
		    eval {recursive_delete "$rootpath TMP$rnd"};
		    croak "trouble writing [$value] to [$rootpath$key]: $message";

		};
	
		# print "lock (tied)";
		 sleep 1 while !mkdir "$rootpath LOCK$key",0777;
		 {
		  no warnings;
		  rename "$rootpath$key", "$rootpath GARBAGE$rnd"; 
		 };
		 rename "$rootpath TMP$rnd", "$rootpath$key";

		}else{ # not tied
		
			# cache, bless, restore
			my @cache = %$value;
			%$value = ();
		# print "lock (untied)";
			while( !mkdir "$rootpath LOCK$key",0777){
				# print "lock conflivt: $!";
				sleep 1;
			};
			{
			 no warnings;
		         rename "$rootpath$key", "$rootpath GARBAGE$rnd";
		        };
		        tie %$value, ref($ref), "$rootpath$key" or
		          warn "tie to [$rootpath$key] failed: $!";
		# print "assignment";
		};

		if(defined($bless)){
			tied(%$value)->STOREMETA('BLESS',$bless);
			# bless $value, $bless; not needed; this is why we are here!
		};

		GC:

		rmdir "$rootpath LOCK$key";

		delete $CircleTracker{$value};
		# print "GC";
		 eval {recursive_delete "$rootpath GARBAGE$rnd"};
		 if($@){
			croak "GC problem: $@";
		 };
		
		 return;

	}; # if refvalue

	# store a scalar using write-to-temp-and-rename
	local *FSDBFH;
	open FSDBFH,">$rootpath TMP$rnd" or croak $!;
	# defined $value and print FSDBFH $value;
	# this will work under -l without spurious newlines 
	defined $value and syswrite FSDBFH, $value;
	# print FSDBFH qq{$value};
	close FSDBFH;
	rename "$rootpath TMP$rnd" , "$rootpath$key" or
	  croak
	     " could not rename temp file to [$rootpath$key]: $!";
};
};

sub FETCHMETA {
	my $ref = shift;
	defined (my $rootpath = $$ref) or croak "undefined rootpath";
	my $key = ' '.shift;
	-e "$rootpath$key" or return undef;
	if(-d "$rootpath$key"){

		confess "Complex metadata not supported in DirDB version $VERSION";	

	};

	local $/ = undef;
	open FSDBFH, "<$rootpath$key"
	   or croak "cannot open $rootpath$key: $!";
	my $result = <FSDBFH>;
	close FSDBFH;
	$result;
};

sub STOREMETA {
	my $rootpath = ${+shift}; # RTFM! :)
	my $key = ' '.shift;
	my $value = shift;
	ref $value and croak "DirDB does not support storing references in metadata at version $VERSION";
	open FSDBFH,">$rootpath${$}TEMP$key" or croak $!;
	defined $value and syswrite FSDBFH, $value;
	# print FSDBFH $value;
	close FSDBFH;
	rename "$rootpath${$}TEMP$key", "$rootpath$key" or croak $!;
};

sub DELETE {
	my $ref = shift;
	my $rootpath = ${$ref};
	my $key = shift;
	my $value;
	$key =~ s/^ /  /; #escape leading space into two spaces
	$key eq '' and $key = ' EMPTY';

	-e "$rootpath$key" or return undef;
#warn "DELETING $rootpath$key";
	-d "$rootpath$key" and do {
#warn "DELETING directory $rootpath$key";

	  rename "$rootpath$key", "$rootpath DELETIA$key" or die "rename: $!";

	  if(defined wantarray){

		my %rethash;
		tie my %tmp, ref($ref), "$rootpath DELETIA$key";
		my @keys = keys %tmp;
		my $k;
		for $k (@keys){
			$rethash{$k} = delete $tmp{$k};
		};
		
		eval {recursive_delete "$rootpath DELETIA$key"};
		$@ and croak "could not delete directory $rootpath$key: $@";
		return \%rethash;
		
	  }else{
		eval {recursive_delete "$rootpath DELETIA$key"};
		$@ and croak "could not delete directory $rootpath$key: $@";
		return {};
	  };
	};

	if(defined wantarray){
		local $/ = undef;
		open FSDBFH, "<$rootpath$key";
		$value = <FSDBFH>;
		close FSDBFH;
	};
	unlink "$rootpath$key" or die "could not unlink $rootpath$key: $!";
	$value;
};

sub CLEAR{
	my $ref = shift;
	my $path = $$ref;
	opendir FSDBFH, $path or croak "opendir $path: $!";
	my @ents = (readdir FSDBFH );
	while(defined(my $entity = shift @ents )){
		$entity =~ /^\.\.?\Z/ and next;
		$entity = join('',$path,$entity);
		if(-d $entity){
		   eval {recursive_delete $entity};
		   $@ and  croak "could not delete (sub-container?) directory $entity: $@";
		};
		unlink $entity;
	};
};

{

   my %IteratorListings;

   sub FIRSTKEY {
	my $ref = shift;
	my $path = $$ref;
	opendir FSDBFH, $path or croak "opendir $path: $!";
	$IteratorListings{$ref} = [ grep { defined $_ and !($_ =~ /^\.\.?\Z/)} readdir FSDBFH ];

	#print "Keys in path <$path> will be shifted from <@{$IteratorListings{$ref}}>\n";
	
	$ref->NEXTKEY;
   };

   sub NEXTKEY{
	my $ref = shift;
	#print "next key in path <$$ref> will be shifted from <@{$IteratorListings{$ref}}>\n";
	@{$IteratorListings{$ref}} or return undef;
	# warn join '|','BEGIN',@{$IteratorListings{$ref}},"END";
	my $key = shift @{$IteratorListings{$ref}};
	# warn "key: <$key>";
	if ($key =~ s/^ //){
		# warn "key: <$key>";
		if ($key =~ m/^ /){
			# we have unescaped a leading space.
		}elsif ($key eq 'EMPTY'){
			$key = ''
		#}elsif($key eq 'REF'){
		# 	return $ref->NEXTKEY();	# next
		#}elsif($key =~ m/^ARRAY){
		# 	return $ref->NEXTKEY();	# next
		}else{
			# per-container metadata does not
			# appear in iterations through data.
			return $ref->NEXTKEY();	# next
		}
	};
	wantarray or return $key;
	return @{[$key, $ref->FETCH($key)]};
   };
   
   sub DESTROY{
       delete $IteratorListings{$_[0]};
       delete $ArrayImpl{$_[0]};
   };
 
}; # end visibility of %IteratorListings

sub lock{
	my $path = ${shift @_};
	my $key= '';
	if(@_){
		$key = shift;
		length $key or $key = ' EMPTY';
	};
	return obtain DirDB::lock "$path$key";
};

package DirDB::lock;
use Carp;
my %OldLocks;
sub obtain{
	my $path = shift;
	while(!mkdir "$path LOCK",0777){
		select(undef,undef,undef,0.2); 
	};
	bless \$path;
};
sub release{
	rmdir "$$_[0] LOCK" or croak "failure releasing $$_[0]: $!";
	$OldLocks{"$_[0]"} = 1;
};
sub DESTROY{
	delete $OldLocks{"$_[0]"} or
	rmdir "$$_[0] LOCK" or croak "failure releasing $$_[0]: $!";
};

1;
__END__

=head1 NAME

DirDB - use a directory as a persistence back end for (multi-level) (blessed) hashes (that may contain array references) (and can be advisorialy locked)

=head1 SYNOPSIS

  use DirDB;
  tie my %session, 'DirDB', "./data/session";
  $session{$sessionID}{email} = get_emailaddress();
  $session{$sessionID}{objectcache}{fribble} ||= new fribble;
  #
  use Tie::File; # see below -- any array-in-a-filesystem representation
                 # is supported
  push @{$session{$sessionID}{events}}, $event;

=head1 DESCRIPTION

DirDB is a package that lets you access a directory
as a hash. The final directory will be created, but not
the whole path to it. It is similar to Tie::Persistent, but different
in that all accesses are immediately reflected in the file system,
and very little is kept in perl memory. (your OS's file cacheing
takes care of that -- DirDB only hits the disk a lot on poorly
designed operating systems without file system caches, which isn't
any of them any more.)

The empty string, used as a key, will be translated into
' EMPTY' for purposes of storage and retrieval.  File names
beginning with a space are reserved for metadata for subclasses,
such as object type or array size or whatever.  Key names beginning
with a space get an additional space prepended to the name
for purposes of naming the file to store that value.

As of version 0.05, DirDB can store hash references. references
to tied hashes are recursively copied, references to plain
hashes are first tied to DirDB and then recursively copied. Storing
a circular hash reference structure will cause DirDB to croak.

As of version 0.06, DirDB now recursively copies subdirectory contents
into an in-memory hash and returns a reference to that hash when
a previously stored hash reference is deleted in non-void context.

As of version 0.07, non-HASH references are stored using L<Storable>

As of version 0.08, non-HASH references cause croaking again: the
Storable functioning has been moved to L<DirDB::Storable>

Version 0.10 will store and retrieve blessed hash-references and
blesses them back into what they were when they were stored.

Version 0.12 closes some directory handles which were not
being closed automatically on cygwin, interfering with tests
passing.

=head2 ARRAY tie-time argument

Version 0.11 allows storing and retrieval of references to arrays
through taking an 'ARRAY' tie-time argument, which is an arrayref
of the args used to tie the array before returning it. A token that
is string-equal to 'DATAPATH' will be replaced with a place in the
file system for the array tieing implementation to do it's thing.
At this version, the default array implementation is

     ['Tie::File' => DATAPATH => recsep => "\0"]

but this may change, perhaps when a DirDB::Array package that 
gracefully handles references is devised.  Forwards-compatibility is
maintained by storing the array implementation details with
each stored arrayref.

=head2 lock method (package DirDB::lock)

Version 0.11 also introduces a C<lock> method that obtains
an advisory mkdir lock on either a whole tied hash or on a key in it.

     tie %P, DirDB=>'/home/aurora/persistentdata';
     ...
     my $advisory_lock1 = tied(%P)->lock; # on the whole hash
     my $advisory_lock2 = tied(%P)->lock('birdy'); # on the key 'birdy'
     {
        my $advisory_lock3 = tied(%P)->lock(''); # on the null key 

these locks last until they are C<DESTROY>ed by the garbage collctor
or until the C<release> method is called on them.

	$advisory_lock1->release;
	release $advisory_lock2;
     };

=head2 croaking on permissions problems

DirDB will croak if it can't open an existing file system
entity.

 tie my %d => DirDB, '/tmp/foodb';
 
 $d{ref1}->{ref2}->{ref3}->{ref4} = 'something'; 
 # 'something' is now stored in /tmp/foodb/ref1/ref2/ref3/ref4
 
 my %e = (1 => 2, 2 => 3);
 $d{e} = \%e;
 # %e is now tied to /tmp/foodb/e, and 
 # /tmp/foodb/e/1 and /tmp/foodb/e/2 now contain 2 and 3, respectively

 $d{f} = \%e;
 # like `cp -R /tmp/foodb/e /tmp/foodb/f`

 $e{destination} = 'Kashmir';
 # sets /tmp/foodb/e/destination
 # leaves /tmp/foodb/f alone
 
 my %g = (1 => 2, 2 => 3);
 $d{g} = {%g};
 # %g has been copied into /tmp/foodb/g/ without tying %g.
 
Pipes and so on are opened for reading and read from
on FETCH, and clobbered on STORE. 

The underlying object is a scalar containing the path to 
the directory.  Keys are names within the directory, values
are the contents of the files.

STOREMETA and FETCHMETA methods are provided for subclasses
who which to store and fetch metadata (such as array size)
which will not appear in the data returned by NEXTKEY and which
cannot be accessed directly through STORE or FETCH. Currently
one metadatum, 'BLESS' is used to indicate what package to
bless a tied hashref into.

=head2 storing and retrieving blessed objects

blessed objects can now be stored, as long as their underlying representation
is a hash.  This may change. The root of a DirDB tree will not get blessed
but all blessed hashreference branches will be blessed on fetch into the package
they were in when stored. 

=head2 storing and retrieving array references

at this version, Tie::File is used for an array implementation.  The
array implementation can be specified with an ARRAY tie-time argument,
like so:

	use Array::Virtual;
	use DirDB 0.11;
	tie my %Persistent, DirDB => './data',
 		ARRAY => ["Array::Virtual", DATAPATH => 0664];



=head2 RISKS

=head3 stale lock risk

"mkdir locking" is used to protect incomplete directories
from being accessed while they are being written, and is
now used as well for advisory locking. It is conceivable
that your program might catch a
signal and die while inside a critical section.  If this happens,
a simple 

    find /your/data -type d -name '* LOCK*'

at the command line will identify what you need to delete.

Only the very end of the write operation is protected by the locking:
during a write, other processes will be able to read the old data. They
will also be able to start their own overwrites. 

DirDB attempts to guarantee that written data is complete (not partial.)

DirDB does not attempt to guarantee atomicity of updates.

=head3 unexpected persistence

Untied hash references assigned into a DirDB tied hash will become
tied to the file system at the point they are first assigned.  This
has the potential to cause confusion.

=head3 unexpected copy instead of link

Tied hash references are recursively copied. This includes hash references
tied due to being assigned into a DirDB tied hash.


=head2 EXPORT

None by default.

=head1 AUTHOR

David Nicol, davidnicol@cpan.org

=head1 Assistance

version 0.04 QA provided by members of Kansas City Perl Mongers, including
Andrew Moore and Craig S. Cottingham.

=head1 LICENSE

GPL/Artistic (the same terms as Perl itself)

=head1 SEE ALSO

better read L<perltie> before trying to extend this

L<DirDB::Storable> uses Storable for storing and retrieving arbitrary types

L<DirDB::FTP> provides complete DirDB function over the FTP protocol

L<Tie::Dir> is concerned with accessing C<stat> information, not file contents

=cut

