package DirDB::FTP;

require 5.005;
use strict;
# use warnings;
use Carp;

use Net::FTP;
use Net::FTP::blat;

use vars '$VERSION';

$VERSION = '0.03';

sub new{
# DirDB::FTP -> new ( $hostname, $user, $pass );
	shift; # we don't need the package name
	my $f = Net::FTP->new( $_[0] , timeout => 300 ) or croak
	   "cannot connect to $_[0]";
	my $pl = 0+length $_[2];
	$f->login($_[1], $_[2]) or croak
	   "cannot login with username $_[1] and $pl char passwd";
	$f->binary();
	$f;
};


sub TIEHASH {
	my ($self, $ftp, $rootpath) = @_;
	ref($ftp) eq 'Net::FTP' or croak <<'EOSYNTAX';
Syntax:
tie my %hash, DirDB::FTP => $ftp_object [, "/some/directory"];
EOSYNTAX

    if(defined $rootpath){
	$rootpath =~ s#/+$##; # lose trailing slash(es)
	if (length $rootpath){
	  $ftp->cwd($rootpath) or $ftp->mkdir($rootpath,'recurse')   
	   or
	     croak "could not change to or create dir $rootpath: "
	     . $ftp->message;
	};
    }else{
    	$rootpath = $ftp->pwd();
    };
	bless [$ftp,"$rootpath/"], $self;
};

sub TIEARRAY {
	confess "DirDB does not support arrays yet";
};

sub TIESCALAR {
	confess "DirDB does not support scalars yet -- try Tie::Slurp";
};


sub EXISTS {
	my ($ftp,$rootpath) = @{+shift};
	my $key = shift;
	$key =~ s/^ /  /; #escape leading space into two spaces
	$key eq '' and $key = ' EMPTY';
	my $mdtm = $ftp->mdtm("$rootpath$key");
	$ftp->message =~ m/no such/i and return 0;
	return 1;

	# my @mdtm = $ftp->ls("$rootpath$key");
	# print "Debug: $mdtm\n";
	defined $mdtm and return 1;
	$ftp->message =~ m/ not a plain file/ and return 1;
	0;
};

sub FETCH {
	my $ref = shift;
	my ($ftp,$rootpath) = @{$ref};
	my $key = shift;
	$key =~ s/^ /  /; #escape leading space into two spaces
	$key eq '' and $key = ' EMPTY';
# FIXME
# Our goal here is to mimic the DirDB semantics, using
# commands defined in Net::FTP, plus slurp and blat.
# We are allowing some error message reading but want
# to keep that down to as little as possible.

	
	sleep 1 while $ftp->ls( "$rootpath LOCK$key");
	my $result = $ftp->slurp( "$rootpath$key" );
	# print "DEBUG: ",$ftp->message(),"\n";
	
	defined $result and return $result;

	$ftp->message =~ /no such/i and return undef;
	
	# assume a directory, ...
	tie my %newhash, ref($ref),$ftp,"$rootpath$key"
	  or croak "Could not fetch [$rootpath$key]: ".$ftp->message;
 	return \%newhash;
};

{
my %CircleTracker;
sub STORE {
	my ($ref , $key, $value) = @_;
	my ($ftp,$rootpath) = @{$ref};
	
	my $rnd = rand(10000).{}.$$;
	$rnd =~ tr/a-zA-Z0-9//cd;
	$key =~ s/^ /  /; #escape leading space into two spaces
	$key eq '' and $key = ' EMPTY';
	my $refvalue = ref $value;
	if ($refvalue){

		if ( $CircleTracker{$value}++ ){
	          croak "$ref version $VERSION cannot store circular structures\n";
		};

		$refvalue eq 'HASH' or	
	          croak 
		   "$ref version $VERSION only stores references to HASH, not $refvalue\n";

		if (tied (%$value)){
			# recursive copy
		   tie my %tmp, ref($ref), $ftp, "$rootpath TMP$rnd" or
		   die "tie failed";
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
		    eval {$ftp->rmdir( "$rootpath TMP$rnd", 1)};
		    croak "trouble writing [$value] to [$rootpath$key]: $message";

		};
	
		# print "lock (tied)";
		 sleep 1 while !$ftp->mkdir( "$rootpath LOCK$key");
		 {
		  # no warnings;
		  $ftp->rename( "$rootpath$key", "$rootpath GARBAGE$rnd"); 
		 };
		 $ftp->rename( "$rootpath TMP$rnd", "$rootpath$key");

		}else{
			# cache, bless, restore
			my @cache = %$value;
			%$value = ();
		# print "lock (untied)";
			while( !$ftp->mkdir( "$rootpath LOCK$key")){
				# print "lock conflivt: $!";
				sleep 1;
			};
			{
			 # no warnings;
		         $ftp->rename( "$rootpath$key","$rootpath GARBAGE$rnd");
		        };
		        tie %$value, ref($ref), $ftp, "$rootpath$key" or
		          warn "tie to [$rootpath$key] failed: ".$ftp->message;
		# print "assignment";
			%$value = @cache;
		};
		
		$ftp->rmdir( "$rootpath LOCK$key");
		delete $CircleTracker{$value};
		
		# print "GC";
		 eval {$ftp->rmdir( "$rootpath GARBAGE$rnd",'recurse')};
		 if($@){
			croak "GC problem: $@";
		 };
		 return;

	};

	# store a scalar using write-to-temp-and-rename
	$ftp->blat($value,"$rootpath TMP$rnd") or croak $ftp->message;
	$ftp->rename( "$rootpath TMP$rnd" , "$rootpath$key") or
	  croak
	     " could not rename temp file to [$rootpath$key]: ".$ftp->message;
};
};

sub DELETE {
	my ($ref , $key) = @_;
	my ($ftp,$rootpath) = @{$ref};
	
	my $retval = undef;
	
	if(defined wantarray){
		$retval = FETCH( $ref,$key );
		if (ref $retval) {
			my %hash;
			my @keys = keys %$retval;
			my $k;
			foreach $k (@keys) {
				$hash{$k} = delete $retval->{$k};
			};
			$retval = \%hash;
		};
	};

	$key =~ s/^ /  /; #escape leading space into two spaces
	$key eq '' and $key = ' EMPTY';

	# -e "$rootpath$key" or return undef;
	$ftp->delete( "$rootpath$key" ) or 
	$ftp->rmdir( "$rootpath$key", 'recurse' );
	
	return $retval;
};

sub CLEAR{
	my ($ref , $key, $value) = @_;
	my ($ftp,$rootpath) = @{$ref};
	
	# maybe we can delete the whole thing? 
	# we will check to make sure this succeeds because we
	# want to support clearing a whole directory that we
	# have been issued by an administrator
	
	$ftp->rmdir($rootpath, 'recurse')
	and	
	$ftp->mkdir($rootpath)
	and
	return;

	my @dirents = $ftp->ls($rootpath);
	for my $ent (@dirents){
		$ftp->delete("$rootpath$ent")
		or
		$ftp->rmdir("$rootpath$ent",1)
	};
		
};

{

   my %IteratorListings;

   sub FIRSTKEY {
	my ($ref , $key, $value) = @_;
	my ($ftp,$rootpath) = @{$ref};
	# opendir FSDBFH, $path or croak "opendir $path: $!";
	# $IteratorListings{$ref} = [ grep {!($_ =~ /^\.\.?\Z/)} readdir FSDBFH ];
	$IteratorListings{$ref} = [ $ftp->ls ];

	$ref->NEXTKEY;
   };

   sub NEXTKEY{
	my $ref = shift;
	my ($ftp,$rootpath) = @{$ref};
	#print "next key in path <$$ref> will be shifted from <@{$IteratorListings{$ref}}>\n";
	@{$IteratorListings{$ref}} or return undef;
	my $key = shift @{$IteratorListings{$ref}};
	if ($key =~ s/^ //){
		if ($key = m/^ /){
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
       # no warnings;
       delete $IteratorListings{$_[0]};
   };
 
};




1;
__END__

=head1 NAME

DirDB::FTP - Perl extension to use a remote directory as a database

=head1 SYNOPSIS

  use DirDB::FTP;
  my $ftp = DirDB::FTP->new('some.host.name',$username,$password);
  tie my %entries, DirDB::FTP, $ftp, => "/blog_entries";
  $entries{'entry for '.localtime} = $entry_text;

=head1 DESCRIPTION

DirDB::FTP is a package that lets you access a DirDB
hash on a remote machine, through the FTP server.

The semantics of DirDB (version 0.06) are followed, including
directory locking and recursive memory loading on directory deletion.

Net::FTP is used for the connection, including the Net::FTP::blat
extensions.

Most actions can be done with ftp method return values, but
differentiating between directories and non=existent files is
done by parsing the C<message> for the phrase 'no such file'
so if you are using DirDB::FTP against a FTP server that issues
a different errore message when there is no such file, you
will have to edit your copy of the module.

The underlying object is an array containing the Net::FTP
connection object and the absolute path to 
the directory, modulo any chrooting the FTP server might do
based on the provided credentials, of course.

Keys are names within the directory, values
are the contents of the files.

A leading space is used as an escape character, the empty
string as a key becomes ' EMPTY' just like in DirDB.

=head2 RISKS

"mkdir locking" is used to protect incomplete directories
from being accessed while they are being written. It is conceivable
that your program might catch a
signal and die while inside a critical section. 


=head2 EXPORT

None by default.


=head1 AUTHOR

David Nicol, davidnicol@cpan.org

=head1 LICENSE

GPL

=head1 SEE ALSO

L<DirDB>

L<Net::FTP::blat>

GPL

=cut


