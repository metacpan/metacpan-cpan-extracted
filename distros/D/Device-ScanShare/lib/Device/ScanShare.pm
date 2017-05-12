package Device::ScanShare;
use vars qw($VERSION $DEBUG);
use File::Path;
use Cwd;
use strict;
use Carp;
$VERSION = sprintf "%d.%03d", q$Revision: 1.14 $ =~ /(\d+)/g;
$DEBUG = 0;


sub DEBUG : lvalue { $DEBUG }
sub debug { $DEBUG and printf "@_\n"; 1 }

sub debog { $DEBUG and printf STDERR "# %s(), @_\n", (caller(1))[3] ; 1 }

sub new {
	my ($class, $self ) = (shift, shift);
	$self ||= {};

	$self->{userdirs_abs_path} 
      or croak('missing "userdirs_abs_path" argument to constructor.');
	
	bless $self, $class;

   my $b = $self->base_path;
   debug("base_path() $b");
		
	return $self;
}

sub base_path {
   my $self = shift;
   my $arg = shift;
   $self->{base_path} = $arg if defined $arg;

   unless( defined $self->{base_path} ){
   
      $self->{base_path} = $self->{userdirs_abs_path};
	   $self->{base_path}=~s/\/[^\/]+txt$//i 
         or die($!." cant etablish basepath for $self->{base_path}");
   }
   $self->{base_path};
}


sub to_abs_unixpath     { _to_abs_unixpath( $_[0]->base_path, $_[1] ) }
sub to_rel_unixpath     { _to_rel_unixpath( $_[0]->base_path, $_[1] ) }
sub to_rel_windowspath  { _to_rel_windowspath( $_[0]->base_path, $_[1] ) }
   

# helper subs - NOT YET IMPLEMENTED


sub _to_rel_windowspath {
   my ($basepath, $arg )= @_;
   $arg or die('missing arg');

   # could be username, windows path. unix path, rel path, whatever
   # we need to resolve to windows path to match into the entries

   _is_windowspath($arg) 
      and return $arg;

   my $rel = _to_rel_unixpath($basepath,$arg) 
      or warn("cant resolve $arg to rel unixpath") 
      and return;

	$rel=~s/\//\\/g;
   $rel;
}

sub _is_windowspath {
   my $arg = shift;
   $arg or confess("missing arg");
   $arg=~/\\/ or return 0;
   $arg=~/\// and return 0;
   1;
}

sub _is_unixpath {
   my($arg) = @_;
   $arg or confess('missing arg');

   $arg=~/\\/ and return 0;

   $arg=~/^\// and return 1;
}

sub _to_abs_unixpath {
   my($basepath,$arg) = @_;
   $arg or confess('missing arg');

   $arg=~s/\\/\//g;

   if( -d "$basepath/$arg" ){
      debug("exists when we add basepath '$arg'");
      return Cwd::abs_path("$basepath/$arg");
   }
   my $a = Cwd::abs_path($arg) or return;
   -d $a and return $a;
   debug("'$a' is not dir");

   return;
}

sub _to_rel_unixpath {
   my ($basepath,$arg) = @_;
   $arg or die('missing arg');

   _is_unixpath($arg) or
      $arg = _to_abs_unixpath($basepath, $arg)
         or return;
   $arg=~s/^$basepath\/// or warn("Cant match $basepath into $arg") and return;

   $arg;
}

# end helpersubs - NOT YET IMPLEMENTED




# METHODS
sub user_delete {
	my ($self, $windowspath) = (shift, shift);
	$windowspath or croak("missing path argument for entry to remove in user_delete_by_path()");
	$windowspath=~s/\//\\/g;

   my $basepath = $self->base_path;
   $basepath=~s/\//\\/g;
   $windowspath=~s/^\Q$basepath\E\\//; # just in case

	my $unixpath = $windowspath;
	$unixpath=~s/\\/\//g;	

   debug("deleting user windowspath '$windowspath'");

	exists $self->_data->{$windowspath} or return;		
	delete $self->_data->{$windowspath};  

	#rmdir($self->{base_path}."/$unixpath") or print STDERR "removed $windowspath from USERDIRS.TXT but could not delete directory ($$self{base_path}$/unixpath) because it is not empty? $!";

	$self->save;
	return 1;
}



sub get_user { 
	my ($self,$windowspath) = (shift,shift);
   $windowspath or confess('missing arg');
	$windowspath=~s/\//\\/g;	
   exists $self->_data->{$windowspath} or return;
   
      
	my $h = $self->_data->{$windowspath};
   
   $h->{abs_unixpath} ||= $self->to_abs_unixpath($h->{path});
   $h->{rel_unixpath} ||= $self->to_rel_unixpath($h->{path});

   $h;
}


sub user_add {
	my ($self, $argv) = (shift, shift);

	$argv->{label} or  confess('provide label for this new entry - user_add()');
	$argv->{path}  or  confess('provide path to this entry - user_add()'); # this is coming in windows\like
	$argv->{host}  ||= $self->{default_host};

   debug("user_add() label:$argv->{label} path:$argv->{path} host: $argv->{host}");



   # PATH ARG IS FULL PATH?
   if ($argv->{path}=~/^\//){
      debug("user_add() provided full path as argument '$argv->{path}'");

      my $abs = Cwd::abs_path($argv->{path})
         or warn("path $argv->{path} is not on disk")
         and return 0;
         
      my $base = Cwd::abs_path($self->base_path)
         or warn("base $argv->{base} is not on disk")
         and return 0;
    
      $abs=~s/^$base\/// 
         or warn("can't resolve [$abs] to within [$base]?") 
         and return 0;
      $argv->{path} = $abs;
      debug("resolved to '$abs'");
   }

	my $unixpath = $argv->{path};
	my $windowspath = $argv->{path};

	$windowspath=~s/\//\\/g;
	$unixpath=~s/\\/\//g; # we need to convert so that if
		# path/is/here
		# path\is\here 
		# either way we get the unix/path and the windows\path

   debug("unixpath    $unixpath");
   debug("windowspath $windowspath");


	if( exists $self->_data->{$windowspath}){ 
      warn("path '$windowspath' is already present.");
      return 0;
   } 	
	### user exists



   $self->exists_label($argv->{label})
      and warn("Cannot add label:$argv->{label} path:$argv->{path} host: $argv->{host}, label is being used.")
      and return 0;


   my $b = $self->base_path;
	unless( -d "$b/$unixpath"){
		File::Path::mkpath("$b/$unixpath") 
         or die($!." cannot create $b/$unixpath for user_add() ");
		debug("note $b/$unixpath did not exist and was created.");	
	}

	$self->_data->{$windowspath} = {
		label	=>	$argv->{label},
		path	=>	$windowspath,
	};	

	$self->save;
	return 1;
}

sub create {
	my $self = shift;      
   ! $self->exists 
      or warn("Cannot create, already on disk: ".$self->userdirs_abs_path)
      and return 0;
   $self->save;
}

sub exists_label {
   my ($self,$arg)= @_;
   defined $arg or croak("missing arg");
   
   for my $h ( @{$self->get_users} ){
      return 1 if ( $h->{label} eq $arg );
   }
   0;  
}

*exists_path = \&get_user;


# HELPERS
sub _arg_is_path { $_[0]=~/\/|\\/ }
sub _arg_is_label { $_[0]!~/\/|\\/ }



sub save {
	my $self = shift;
	# must re sort by label on save only, entry could have been made that needs new sorting

	#reset id, count
	$self->{id} =0;

	#start output, get the header
	my $savefile = $self->_get_header or die('no header?'); # start with that

	# has to turn them into line numbers etc 	
	for (@{$self->get_users}){
		$savefile.= $self->_hash_to_line($_)."\n";
	}

	my $l = length($savefile) or die("savefile has nothing?");

   my $temp = $self->userdirs_abs_path.".tmp";
   my $abs  = $self->userdirs_abs_path;


   debug("opening $temp for writing $l chars");

	open(SVF, '>', $temp)
      or confess("$!, cannot open file for writing: $temp");
	print SVF $savefile."\n";
	close SVF;	
   
   debug("Saved $temp");
   
	
	rename($temp, $abs) 
      or die("cannot rename $temp to $abs, $!"); 
   if ($DEBUG){
      -f $abs or die("not on disk! $abs");
      warn("Saved $abs\n");
   }
	
	return 1;
}





sub get_users {
	my $self = shift;

	my @records = ();

	for ( sort { $self->_data->{$a}->{label} cmp $self->_data->{$b}->{label} } keys %{$self->_data} ){
		my $hash = $self->get_user($_);		
		push @records, $hash;		
	}
	
	#notes.. why not do this in _read? beacuse if you do and then make changes, they won't show up.

	return \@records;
}


sub count {
	my $self = shift;
	my $count = scalar keys %{$self->_data} ;
	$count ||=0;
	return $count;
}


sub exists { -f $_[0]->userdirs_abs_path ? 1 : 0 }
sub userdirs_abs_path { $_[0]->{userdirs_abs_path} }






# private methods....

sub _hash_to_line { 
  my ($self, $hash) = (shift, shift);
  $self->{id} ||= 0; # init  id marker to save each entry line if it has no value.



  $hash->{path}=~s/\//\\/g; # make into windowspath just in case it's not

  $self->{id}++; # increment id
  $hash->{host} ||= $self->{default_host};
  $hash->{end} ||= 0;	
	my $line = $hash->{label}.'='
		.$hash->{path}.','.$hash->{label}.','
		.$hash->{host}.','.$self->{id}
		.','.$hash->{end};

	return $line;
} 

sub _original_line_to_hash {
	my $line = shift;
	$line=~s/^\s+|\s+$//g;
	my $hash = {};

	$line=~s/^([^=]+)=// or die($line ." seems imporperly formatted?");
	$hash->{label} = $1;
	
	my @vals = split(/,/, $line);
	$hash->{path} = $vals[0];
	$hash->{label2} = $vals[1];
	$hash->{host} = $vals[2];
	$hash->{id} = $vals[3];
	$hash->{end} = $vals[4];
   

	return $hash;
}






# this is ONLY called when we are saving
# to auto generate the next id count, etc
sub _get_header { 
	my $self = shift;
	
	my $nextid = ( $self->count +1);	
	
	my $out=	 "[PreferredServer]\n"
				."Server=$$self{server}\n"
				."[RoutingID]\n"
				."NextID=$nextid\n"
				."[Users]\n";
	return $out;
}	



sub _data {
	my $self = shift;
	
	unless( defined $self->{data} ){

		if( !$self->exists ){
			warn("Not on disk yet: ".$self->userdirs_abs_path);
			return {};
		}
	
		# we just want the users from this, not header stuff
      
		my @lines = grep { $self->_is_user_line($_) } array_slurp($self->userdirs_abs_path); 

		scalar @lines 
         or warn("note: ".$self->userdirs_abs_path." has no user line entries.");

		my $data = {};	

		map {
			my $hash = _original_line_to_hash($_);
			$data->{ $hash->{path} } = $hash;	
         
		} @lines;
	
	
		$self->{data} = $data;	
	}
	return $self->{data};
}


sub _is_user_line {
	my $self = shift;
	my $line = shift;
	#hack to get "Server" from file
	if ($line=~/^Server\=([\d\.\w]+)$/i ){
		$self->{server} = $1;
		return 0;
	}	
	if ( $line =~/^\[\w+\]|^NextID=/i){ return 0; }	
	$line=~/^[^\[\]\/\\=]+=/ or return 0;
	return 1;	
}


sub array_slurp {
   my $abs = shift;
   $abs or confess("Missing argument");
   #local $/;
   open(FILE,'<',$abs) or warn("Cannot open file for reading: '$abs', $!") and return;
   my @lines = <FILE>;
   close FILE;
   return @lines;
}



1;

