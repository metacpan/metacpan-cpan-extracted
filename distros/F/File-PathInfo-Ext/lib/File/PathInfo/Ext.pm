package File::PathInfo::Ext;
use base 'File::PathInfo';
use strict;
use warnings;
use Carp;
use vars qw($VERSION $META_HIDDEN $META_EXT);
$VERSION = sprintf "%d.%02d", q$Revision: 1.30 $ =~ /(\d+)/g;

$META_HIDDEN = 1; 
$META_EXT = 'meta'; 



sub rename {
	my ($self, $newname) =(shift, shift);
   $newname=~/\// and Carp::cluck("newname cannot contain slashes") and return;
   $self->move($self->abs_loc ."/$newname");
}


sub copy {
   my ($self,$to) = @_;

   my $went;
   if (-d $to){
      $went = "$to/".$self->filename;
   }
   elsif ($to!~/\//){
      $went = $self->abs_loc."/$to";
   }
   else {
      $went = $to;
   }
   -e $went and Carp::cluck("Cannot copy to '$to', destination exists") and return;
   
   #my $abs_to = $self->_resolve_arg_to($to) or return;

   require File::Copy;
   File::Copy::cp($self->abs_path, $went )
      or Carp::cluck("Could not copy to '$went', $!") and return;

   $self->set($went)
}


sub _resolve_arg_to { 
   # just resolves where user wants to move thing to, does not check anything else
   my ($self,$to) = @_;
   $to or confess;

   # I) 
   # resolve it
   my $abs_to;

   # filename.ext
   if( $to=~/^\.\w|^\w/ ){
      $abs_to = $self->abs_loc . '/'.$to;
      #### via ./ or \w
   }

   # ./filename.ext
   elsif( $to=~s/^\.\/// ){
      $abs_to = Cwd::cwd().'/'.$to;
      #### via cwd
   }
   
   # MUST HAPPEN BEFORE ^/ test
   # /path/ dir to move to?
   elsif( $to=~s/\/+$// ){
      $abs_to =  $to.'/'.$self->filename;
      #### via dir/
   }

   # /path/filename.ext
   elsif( $to=~/^\// ){
      $abs_to = $to;
      #### via /
   }
   

   else {
      # ../ ???? etc 
      $self->errstr("Can't resolve arg $to.") and return;
   }

   $abs_to = Cwd::abs_path($abs_to);
   ( defined $abs_to and $abs_to )
      or $self->errstr("Can't resolve arg $to") 
      and return;

   #### $abs_to

   

   # II)
   # check it
   $abs_to=~/^(.+)\// or die;
   my $abs_loc = $1; 
   #### $abs_loc
   -d $abs_loc 
      or $self->errstr("Can't set destination to '$abs_to', dir '$abs_loc' does not exist.")
      and return;

   -e $abs_to
      and $self->errstr("Can't set destination to '$abs_to', already exists.")
      and return;

   $abs_to;
}









sub move {
	my ($self, $to) =(shift, shift);
	### move called: $to
	require File::Copy; 
		# using this in the package headers was causing a warning,
		# move redefined.. bla bla.. it is quite annoying to export by default
   

   my $abs_from = $self->abs_path;
   my $meta_from = __abs_meta_correct( $abs_from );

   

   # is destination a dir
   if (-d $to){ #
      my $abs_to = "$to/".$self->filename;

      -e $abs_to and Carp::cluck("Can't move to '$abs_to', destination already exists") and return;
      

      # meta too..
      if ( -f $meta_from ){
         File::Copy::move( $meta_from, $to ) or confess("Cant move $meta_from to $to, $!");
      }

      File::Copy::move( $abs_from, $abs_to) or confess("Cant move to $abs_to, $!");
         
      return $self->set($abs_to) or confess("cant set() $abs_to");
   }

   

	if (-e $to){
		Carp::cluck("Can't move '$abs_from' to '$to', already exists.");
		return;
	}

   # meta too..
   if ( -f $meta_from ){
      my $newname = __abs_meta_correct($to);
      File::Copy::move( $meta_from, $newname ) or confess("Cant move $meta_from to $newname, $!");
      
   }

   # move the file
   File::Copy::move($abs_from, $to) or confess("Can't move '$abs_from' to '$to',$!");
   
   # we alreadytested if the destination was a dir.. so we know this is a filepath
   $self->set($to) or confess("Can't set to new destination '$to',$!");
}



# list 

sub ls {
	my $self = shift;
	$self->is_dir or return;

	unless(defined $self->{_data}->{ls}){
		printf STDERR "ls for [%s]\n", $self->abs_path;
		opendir(DIR, $self->abs_path);
		my @ls = grep { !/^\.+$/ } readdir DIR;
		close DIR;
		### @ls
		$self->{_data}->{ls}  = \@ls;
	}
	return $self->{_data}->{ls};
}

sub lsa {
	my $self = shift;
	$self->is_dir or return;	
	my @ls; for (@{$self->ls}){ push @ls, $self->abs_path.'/'.$_;	}
	return \@ls;
}

sub lsf {
	my $self = shift;	
	$self->is_dir or return;	
	unless( defined $self->{_data}->{_lsf_}){
		@{$self->{_data}->{_lsf_}} = grep { -f $self->abs_path .'/'. $_ } @{$self->ls};
	}
	return $self->{_data}->{_lsf_};	
}

sub lsfa {
	my $self = shift;	
	$self->is_dir or return;	
	my @ls; for (@{$self->lsf}){ push @ls, $self->abs_path.'/'.$_;	}
	return \@ls;
}

sub lsd {
	my $self = shift;	
	$self->is_dir or return;	
	unless( defined $self->{_data}->{_lsd_}){
		@{$self->{_data}->{_lsd_}} = grep { -d $self->abs_path .'/'. $_ } @{$self->ls};
	}
	return $self->{_data}->{_lsd_};	
}

sub lsda {
	my $self = shift;	
	$self->is_dir or return;	
	my @ls; for (@{$self->lsd}){ push @ls, $self->abs_path.'/'.$_;	}
	return \@ls;
}

sub ls_count {
	my $self = shift;
	$self->is_dir or return;
	my $count = scalar @{$self->ls};
	return $count;
}

sub lsd_count {
	my $self = shift;
	$self->is_dir or return;
	my $count = scalar @{$self->lsd};
	return $count;
}

sub lsf_count {
	my $self = shift;
	$self->is_dir or return;
	my $count = scalar @{$self->lsf};
	return $count;
}


sub meta { $_[0]->{meta} ||= (get_meta(__abs_meta_correct($_[0]->abs_path)) || {}) }

sub meta_save { set_meta( $_[0]->abs_path, $_[0]->meta) }

sub meta_delete {
	my $self = shift;

   delete_meta($self->abs_path);
	
   # try to delete all of them if present   
	$self->{meta} = {};
	return 1;
}






sub is_empty_dir {
	my $self = shift;
	$self->is_dir or return;	
	(scalar @{$self->ls}) ? 0 : 1 
}


sub get_datahash {
	my $self = shift;	
	my $hash = $self->SUPER::get_datahash;
	$hash->{is_empty_dir} = $self->is_empty_dir;
	return $hash;
	
}

sub md5_hex {
	my $self = shift;
	$self->is_file 
      or warn(sprintf "md5() doesnt worlk for dirs: %s",$self->abs_path) 
      and return;
	
	unless( exists $self->{_data}->{md5_hex}){
		require Digest::MD5;
		my $file = $self->abs_path;

		my $sum = Digest::MD5::md5_hex($file);

		$sum ||=undef;
		$sum or warn("cant get md5sum of $file");
		$self->{_data}->{md5_hex} = $sum;
		
	}
	return $self->{_data}->{md5_hex};
}

sub mime_type {
   my $self = shift;
   unless( exists $self->{_data}->{mime_type} ){
      require File::Type;
      my $mm = new File::Type;

      my $res = $mm->checktype_filename($self->abs_path);
      #my $res = $mm->mime_type($self->abs_path);
      $self->{_data}->{mime_type} = $res;

   }
   return $self->{_data}->{mime_type};

}



# PROCEDURAL
#
#
#


sub get_meta {
	my $abs_path = shift; 	
	$abs_path or croak('get_meta() needs abs path as argument');

   for my $a ( __abs_meta_possible($abs_path) ){
      -f $a or next;
      return YAML::LoadFile( $a );
   }
   return;
}

sub set_meta {
	my ($abs_path, $meta) = (shift,shift);
	$abs_path or croak('set_meta() needs abs path as argument');
	ref $meta eq 'HASH'
		or croak('second argument to set_meta() must be a hash ref');	

	unless( keys %$meta){
		delete_meta($abs_path);
		return 1;
	}

   my $abs_meta = __abs_meta_correct($abs_path);

   require YAML;
	YAML::DumpFile( $abs_meta, $meta ) or warn("could not save meta, $!");
	1;
}

sub delete_meta {    
   my $abs_path = shift;
   for my $a ( __abs_meta_possible($abs_path) ){
      -f $a or next;
      unlink $a or confess("Can't delete '$a', $!");
   }   
   1;
}

# returns where for a path, the hidden and seen meta paths would be
sub __abs_meta_possible {
   my ($abs_path) = @_;

   $META_EXT or confess('missing $META_EXT in File::PathInfo');
   my $abs_normal = "$abs_path.$META_EXT";
   my $abs_hidden = $abs_path;
   $abs_hidden=~s/([^\/]+)$/.$1.$META_EXT/ or confess("cant match into");
   ($abs_normal, $abs_hidden);
}

# returns what abs meta is for a path, if on disk, otherwise what it should be
sub __abs_meta_correct {
   my $abs = shift;

   my ($normal, $hidden ) = __abs_meta_possible($abs);
   my $correct = $META_HIDDEN ? $hidden : $normal;

   for($normal,$hidden){
      -f $_ and return $_;
   }
   $correct;
}



1;
