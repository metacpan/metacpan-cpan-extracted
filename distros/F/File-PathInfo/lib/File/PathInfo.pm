package File::PathInfo;
use Cwd;
use Carp;
use strict;
use warnings;
require Exporter;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION $DEBUG);
@ISA = qw(Exporter);
@EXPORT_OK = qw(abs_path_n);
%EXPORT_TAGS = (
	all => \@EXPORT_OK,
);
$VERSION = sprintf "%d.%02d", q$Revision: 1.27 $ =~ /(\d+)/g;

$DEBUG =0;

sub DEBUG : lvalue { $File::PathInfo::DEBUG }
$file::PathInfo::RESOLVE_SYMLINKS=1; 
sub RESOLVE_SYMLINKS : lvalue { $File::PathInfo::RESOLVE_SYMLINKS }
$File::PathInfo::TIME_FORMAT = 'yyyy/mm/dd hh::mm'; 
sub TIME_FORMAT : lvalue { $File::PathInfo::TIME_FORMAT }

___make_get_premethod( '_stat' => qw(is_binary is_dir is_text is_file filesize size ctime 
   atime ctime_pretty atime_pretty mtime_pretty filesize_pretty mtime ino rdev gid uid 
   dev blocks blksize mode nlink));

___make_get_premethod( _abs => qw(abs_path filename abs_loc ext filename_only));


sub new {
	my ($class, $self) = (shift, shift);
	$self ||= {};		
	
	my $arg;
	unless( ref $self ){
		print STDERR "arg is not a ref, treating as arg\n" if $DEBUG; # assume to be path argument
		$arg = $self;
		$self = {};	
	}	
	bless $self, $class;			

	if ($arg){ $self->set($arg) or Carp::cluck("failed set() $arg") }	
		
	$self;	
}


sub set {
	my $self= shift;
	$self->{_data} = undef;	
   my $arg = shift;
	$self->{_data}->{_argument} = $arg;	
   
	unless( $self->_abs){
      Carp::cluck("set() '$arg' is not on disk.");
      $self->{_data}->{exists} = 0 ;
      return 0;
   }  
   $self->{_data}->{exists} = 1 ;
	$self->abs_path;
}

sub _argument {
	my $self = shift;
	$self->{_data}->{_argument} or confess("you must call set() before any other methods");
	return $self->{_data}->{_argument};
}


sub _abs {
	my $self = shift;	

#	croak($self->errstr) if $self->errstr;	

	unless( defined $self->{_data}->{_abs} ){

		my $_abs = {
         abs_loc => undef,
         filename => undef,
         abs_path => undef,
         filename_only => undef,
         ext => undef,       
      };	
	   $self->{_data}->{_abs} = $_abs;
      
		my $abs_path;		
		my $argument = $self->_argument;

		
		
		# IS ARGUMENT ABS PATH ?
		if ( $argument =~/^\// ) {			

			if (RESOLVE_SYMLINKS){		
				$abs_path = Cwd::abs_path($argument);
			}

			else {
				$abs_path = abs_path_n($argument);
			}
				
			unless($abs_path){ 
				print STDERR "argument : '$argument', cant resolve with Cwd::abs_path\n" if $DEBUG;
				 return ;
			}	
		}



		# IS ARG REL TO CWD ?
		# if starts with dot.. resolve to cwd
		elsif ( $argument =~/^\.\// ){
			unless( $abs_path = Cwd::abs_path(cwd().'/'.$argument) ){
					print STDERR "argument: '$argument', "
					."cant resolve as path rel to current working dir with Cwd abs_path\n" if $DEBUG;
					return 0 ;
			}	
		}


		# IS ARG REL TO DOC ROOT ?
		else {
			### assume to be rel path then	
			unless( $self->DOCUMENT_ROOT ){
				print STDERR "argument: '$argument'- DOCUMENT_ROOT "
				."is not set, needed for an argument starting with a dot\n" if $DEBUG
				and return 0;
			}	
	
			unless( $abs_path = Cwd::abs_path($self->DOCUMENT_ROOT .'/'.$argument) ){
            print STDERR 
               "argument: '$argument' cant resolve as relative to DOCUMENT ROOT either\n" 
               if $DEBUG;
            return 0 ;
			}	
	
		}




		# set main vars
	
		$_abs->{abs_path} = $abs_path or return 0; 

	   unless (defined $self->{check_exist}){
         $self->{check_exist} = 1;
      } 
		if ($self->{check_exist}){
			unless( -e $_abs->{abs_path} ){ 
				print STDERR "'$$_abs{abs_path}' is not on disk\n" if $DEBUG;
				#$self->_error( $_abs->{abs_path} ." is not on disk.");
            ### $abs_path 
            ### is explicitely !-e on disk            
            return 0; 
			}					
		}

		$abs_path=~/^(\/.+)\/([^\/]+)$/ 
			or die("problem matching abs loc and filename in [$abs_path], ".
			"argument was [$argument] - maybe you are trying to use a path like /etc,"
			."bad juju."); # should not happen
		$_abs->{abs_loc} = $1;
		$_abs->{filename} = $2;
		if ($_abs->{filename}=~/^(.+)\.(\w{1,4})$/){
			$_abs->{filename_only} =$1;
			$_abs->{ext} = $2;
		}
		else { #may be a dir
			$_abs->{filename_only} = $_abs->{filename};	
		}
		
		$self->{_data}->{_abs} = $_abs;	
	}
	
	$self->{_data}->{_abs};
}


sub _rel {
	my $self = shift;

	croak($self->errstr) if $self->errstr;	

	unless( defined $self->{_data}->{_rel}){
		my $_rel = {
         rel_path => undef,
         rel_loc => undef,         
      };
	   $self->{_data}->{_rel} = $_rel;
      $self->DOCUMENT_ROOT or warn('cant use rel methods because DOCUMENT ROOT is not set')
			and return $_rel;
      
		my $doc_root = $self->DOCUMENT_ROOT;
		my $abs_path = $self->abs_path or return $_rel;

		if ($doc_root eq $abs_path){
			$_rel->{rel_path} = '';
			$_rel->{rel_loc} = '';			
		}

		else {
         
         unless( $self->is_in_DOCUMENT_ROOT ){ 
				warn("cant use rel methods because this file [$abs_path] is "
				."NOT WITHIN DOCUMENT ROOT:".$self->DOCUMENT_ROOT) if $DEBUG;
				return $_rel;
			}	
         
			my $rel_path = $abs_path; #  by now if it was the same as document root, should have been detected
			$rel_path=~s/^$doc_root\/// or croak("abs path [$abs_path] is NOT within DOCUMENT ROOT [$doc_root]");
	
			$_rel->{rel_path} = $rel_path;

			if ($rel_path=~/^(.+)\/([^\/]+)$/){
				my $rel_loc = $1;
				my $filename = $2;

				$filename eq $self->filename or 
					die("filename from abs path not same as filename from init rel regex, why??");
		
				$_rel->{rel_loc} = $1;	
			}
			else {
				$_rel->{rel_loc} = ''; # file is in topmost dir in doc root	
			}
		}

		$self->{_data}->{_rel} = $_rel;	
	}
	
	return $self->{_data}->{_rel};
}

___make_get_premethod( _rel => qw(rel_path rel_loc) );

sub is_topmost {
	my $self = shift;
	defined $self->DOCUMENT_ROOT or return 0;
	$self->abs_loc eq $self->DOCUMENT_ROOT or return 0;
	return 1;
}

sub is_DOCUMENT_ROOT {
	my $self = shift;	
	defined $self->DOCUMENT_ROOT or return 0;	
	$self->abs_path eq $self->DOCUMENT_ROOT or return 0;
	return 1;
}
sub is_in_DOCUMENT_ROOT {
	my $self = shift;
   $self->exists or return;
	my $abs_path = $self->abs_path;
	my $document_root = $self->DOCUMENT_ROOT;

	$abs_path=~/^$document_root\// or return 0; # the trailing slash is imperative

	return 1;
}

sub DOCUMENT_ROOT_set {
   my ($self,$abs)=@_;
   defined $abs or confess("missing argument");
   -d $abs or warn("[$abs] not a dir");
   
   $self->{_data}->{DOCUMENT_ROOT} = $abs;
   return 1;
}




sub DOCUMENT_ROOT {
	my $self = shift;	

	croak($self->errstr) if $self->errstr;

	
	unless ( defined $self->{_data}->{DOCUMENT_ROOT}){	
	
		my $abs_document_root;

		if( $self->{DOCUMENT_ROOT} ){
			$abs_document_root = Cwd::abs_path(	$self->{DOCUMENT_ROOT} ) or 
				$self->_error(" DOCUMENT_ROOT [$$self{DOCUMENT_ROOT}] does not resolve to disk") and return;
		}	

		elsif ( $ENV{DOCUMENT_ROOT} ){
			$abs_document_root = Cwd::abs_path(	$ENV{DOCUMENT_ROOT} ) or 
				$self->_error(" ENV DOCUMENT_ROOT [$ENV{DOCUMENT_ROOT}] does not resolve to disk") and return;		
		}
		
		$self->{_data}->{DOCUMENT_ROOT} = $abs_document_root;
	}	
	return $self->{_data}->{DOCUMENT_ROOT};
}


# init stat
sub _stat {
	my $self = shift;
   unless( $self->exists ){
		Carp::cluck('File::PathInfo : no file is set(). Use set().');
		return {};
	}	
	croak($self->errstr) if $self->errstr;

	unless( defined $self->{_data}->{_stat}){	

	
		my @stat =  stat $self->abs_path or die("$! - cant stat ".$self->abs_path);

		my $data = {
			is_file				=> -f _ ? 1 : 0,
			is_dir				=> -d _ ? 1 : 0,
			is_binary			=> -B _ ? 1 : 0,
			is_text				=> -T _ ? 1 : 0,		
         is_topmost			=> $self->is_topmost,
         is_document_root	=> $self->DOCUMENT_ROOT ? $self->is_DOCUMENT_ROOT : undef,
         is_in_document_root =>  $self->DOCUMENT_ROOT ? $self->is_in_DOCUMENT_ROOT : undef,		
		};
		
		my @keys = qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);
		#map { $data->{ shift @keys } = $_ } @stat; 
		for (@stat) {
		 	my $v= $_;
		 	my $key = shift @keys;		
			$data->{$key} = $v;		
		}
		
		$data->{ filesize_pretty }	= ( sprintf "%d",($data->{size} / 1024 )).'k';

      require Time::Format;      
      for my $v (qw(ctime atime mtime)){
         $data->{$v.'_pretty'} = Time::Format::time_format($self->_time_format, $data->{$v} );
      }
         
		$data->{ filesize }		= $data->{size};
	
		$self->{_data}->{_stat} = $data;		
	}

	return $self->{_data}->{_stat};	
}

sub _time_format {
   my $self = shift;
   $self->{time_format} ||= 'yyyy/mm/dd hh:mm';
   return $self->{time_format};
}


# this is to replace 
# all these :
# sub is_binary {
#	my $self = shift;
#	return $self->_stat->{is_binary};
# }
sub ___make_get_premethod {
   my $method_data = shift;   
   no strict 'refs';
   for my $method_name ( @_ ){
      *{"File\:\:PathInfo\:\:$method_name"} = sub { return $_[0]->$method_data->{$method_name} };
   }
   return;
}


sub get_datahash {
	my $data = {};	
   for my $method ( qw(_abs _rel _stat) ){      
      KEY: while( my ($k,$v) = each %{$_[0]->$method} ){
         defined $v or next KEY;
         $data->{$k} =$v;
      }
   }
	$data;	
}

sub _error { $_[0]->{_data}->{_errors}.="File::Info, $_[1]\n" }
sub errstr {
	my $self = shift;
   ($self->{_data}->{_errors} = $_[0]) if $_[0];
	$self->{_data}->{_errors}
}

sub exists {
   my $self = shift;
   defined $self->{_data}->{exists} or confess('must call set() first');      
   $self->{_data}->{exists};
}


# NON OO

sub abs_path_n {
	my $absPath = shift;
	return $absPath if $absPath =~ m{^/$};
   my @elems = split m{/}, $absPath;
   my $ptr = 1;
   while($ptr <= $#elems)
    {
        if($elems[$ptr] eq q{})
        {
            splice @elems, $ptr, 1;
        }
        elsif($elems[$ptr] eq q{.})
        {
            splice @elems, $ptr, 1;
        }
        elsif($elems[$ptr] eq q{..})
        {
            if($ptr < 2)
            {
                splice @elems, $ptr, 1;
            }
            else
            {
                $ptr--;
                splice @elems, $ptr, 2;
            }
        }
        else
        {
            $ptr++;
        }
    }
    return $#elems ? join q{/}, @elems : q{/};

	# by JohnGG 
	# http://perlmonks.org/?node_id=603442	
}




1;

# see lib/File/PathInfo.pod
