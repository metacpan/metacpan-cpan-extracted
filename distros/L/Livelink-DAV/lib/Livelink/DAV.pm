package Livelink::DAV;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.0013';

use namespace::autoclean; #code hygene,
use HTTP::DAV;
use Moose;
use MooseX::NonMoose; #requires separate install from Moose
use Data::Dumper;
use Carp();
use File::Basename;

extends 'CopyTree::VendorProof';

has 'llddav' =>(
   is=>'rw',
);
has 'lldsite' =>(
   is=>'rw',
);

has 'lldusern' =>(
   is=>'rw',
);
has 'llduserp' =>(
   is=>'rw',
);
has 'enodav' =>(
   is =>'rw',
   #isa =>'LWP::UserAgent',
   lazy=>1,
   required=>1,
   #default => sub {LWP::UserAgent->new(cookie_jar =>{},timeout=>10,);},
   builder =>'_init_davnocookies',

);
sub BUILD{
   my $self=shift;
   my $args=shift;
   #ugly tricky code.  non-moose parent's constructor 'new' has these
   #entries that we don't need here.  the result of calling 
   #Livelink::DAV->new 
   #gives a Livelink::DAV obj, even though it uses CopyTree::VendorProof's new 
   #constructor.  This is a Moosism, since the point here is to use methods from
   #the parent, but not use the constructor.
   #technically, there's nothing wrong with omitting this step;
   #it just makes the object cleaner looking
   delete $self->{'source'};
   delete $self->{'destination'};


}
sub _init_davnocookies{
   my $self =shift;
   my $davobj = HTTP::DAV ->new ();
	if ($self->lldsite =~m/[^\/]$/){ #just in case the site is provided without ending slash, we will add it
		$self->lldsite($self->lldsite.'/');
	}	
	if ($self->llddav =~m/[^\/]$/){ #add ending slash to llddav
		$self->llddav($self->llddav.'/');
	}	
	if ($self->llddav =~m/^\//){ #remove starting slash  to llddav
		my $newllddav=$self->llddav;
		$newllddav=~s/^\///;
		$self->llddav($newllddav);
	}	

   $davobj -> credentials(-url=>$self->lldsite.$self->llddav,-user=> $self-> lldusern , -pass => $self ->llduserp, );
   $davobj-> open(-url => $self->lldsite.$self->llddav) or print STDERR $davobj ->message." dav open err $!\n";
   #print Dumper $davobj ->get_user_agent;   
   $self ->enodav($davobj);
}
sub fdls{
   my $self=shift;
   my $lsoption=shift;
   my $startpath=shift;
   #removes trailing slashes to be consistant   
   $startpath='' if (!$startpath);
   $startpath =~s/\/$//;


   my ( @files, @dirs);
   my $davobj = $self->enodav();
   my $rstatus=0;  #0 is bad status, 1 is success
   my $r=$davobj -> propfind($startpath) and $rstatus=1 ;
   if (!$rstatus){
      Carp::cluck ( "propfind error [resource name is probably incorrect] err msg [".$davobj->message."]\n");
   }
   elsif ( $r->is_collection){
      print "[you are probably looking at a populated dir]\n";
#     print Dumper $r;
      if ($r->get_resourcelist){
   #     print $r->get_resourcelist ."\n";
   #     print $r->get_resourcelist ->as_string ."\n";
         #print Dumper $r->get_resourcelist ;
         for my $resource ( @{$r->get_resourcelist->{'_resources'}}){

            if ($resource ->get_property("resourcetype") eq 'collection'){
               push @dirs, $startpath.'/'.$resource->get_property('displayname');
            }
            elsif (! $resource ->get_property("resoucetype") ){
               push @files, $startpath.'/'.$resource->get_property('displayname');
            }
            #print   "- ".$resource->{'_properties'}->{'displayname'}      . "\n" if ($resource->{'_properties'}->{'displayname'} );
            #print "\tcreated  ".$resource->{'_properties'}->{'creationdate'}     . "\n" if ($resource->{'_properties'}->{'creationdate'});
            #print "\tmodified ".$resource->{'_properties'}->{'getlastmodified'}  . "\n" if ($resource->{'_properties'}->{'getlastmodified'} );
            #print "\tbytes    ".$resource->{'_properties'}->{'getcontentlength'} . "\n" if ($resource->{'_properties'}->{'getcontentlength'});
            #print "\tcreater  ".$resource->{'_properties'}->{'createdby'}        . "\n" if ($resource->{'_properties'}->{'createdby'}       );
            #print "\trestype  ".$resource->{'_properties'}->{'resourcetype'}     . "\n" if ($resource->{'_properties'}->{'resourcetype'}       );
            #print "\tprop  s  ".$resource->{'_properties'}->{'short_props'}      . "\n" if ($resource->{'_properties'}->{'short_props'}       );
         }
      } #end if ($r->get_resourcelist)
      else {
         print "[no resource list, you're probably looking at an empty dir]\n";
      }#end else of if $r->get_resourcelist
   } #end if ($r ->is_collection)
   else {
      print "[propfind is not a collection. you're probably looking at a file]\n";
      print $r->get_property("getcontentlength") . "\n";
   }

   return $self->fdls_ret( $lsoption,\@files, \@dirs);

}
sub is_fd{
	my $self=shift;
	my $query = shift;
	my $queryparent;
  	my $davobj = $self->enodav();
	if ($query =~m/\/$/){
		Carp::cluck("no sense querying with an ending slash, removing it for you\n");
		$query=~s/\/$//;
	}
	my $rstatus=0;  #0 is bad status, 1 is success
   my $r=$davobj -> propfind($query) and $rstatus=1 ;
   if (!$rstatus){
   	   #Carp::cluck ( "propfind error [resource name is probably incorrect] err msg [".$davobj->message."]\n");

		#in case the $query has a parent/child format:
		if ($query =~m/\//){
			#only do this if we're sure there's a slash in the middle,
			#since dirname() returns '.' on a non-slash item
			$queryparent=File::Basename::dirname($query);
				if ($davobj ->propfind($queryparent)){
	   	   	#Carp::cluck ( "dir or file does not exist, but has valid parent\n");
					return ('pd');
				}
				else {
					return (0);
						#or no valid parent and file doesn't exist
				}
		}#end if (query =~m/\//)  case where there's a dir slash
		else {
			#no slash in file name, must be right after webdav dir, which gets auto 'pd' 
			#status, though chances of anything working are small, unless admin
			return ('pd');
		}
	}
	elsif ( $r->is_collection){
		print "[you are probably looking at a populated dir]\n";
		return ('d');
#		if ($r->get_resourcelist){
#		   print $r->get_resourcelist ."\n";
#		   print $r->get_resourcelist ->as_string ."\n";
#		   #print Dumper $r->get_resourcelist ;
#		} #end if ($r->get_resourcelist)
#		else {
#		   print "[no resource list, you're probably looking at an empty dir]\n";
#		}#end else of if $r->get_resourcelist
	} #end elsif ($r ->is_collection)
	else {
		print "[propfind is not a collection. you're probably looking at a file]\n";
		print "size [".$r->get_property("getcontentlength") . "]bytes\n";
		return ('f');
	}

}

sub cust_mkdir{
	my $self=shift;
	my $newdir=shift;
	#remove leading and training slashes of dir
	$newdir =~s/^\///;
	$newdir =~s/\/$//;
	return unless $self->pathcheck($newdir);

   my $davobj = $self->enodav();
	#creates a dav dir 
	my $fdstatus= $self->is_fd($newdir);
	if ($newdir =~/\//){ #dir has a slash in it, test if parent exists, then create:
		if ($fdstatus eq 'pd'){
			$davobj -> mkcol(-url => $newdir) or Carp::cluck("cannot create $newdir\n".$davobj-> message );
		}
		elsif ($fdstatus eq 'd') {Carp::cluck("$newdir already exists, doing nothing\n")}
	}
	else {
		if ($fdstatus eq 'd') {
			Carp::cluck("$newdir already exists, doing nothing\n");
			return;
		}
		Carp::cluck("no dir separator, assuming you are creating dir right under webdav folder, which usually doesn't work unless you have special privs\n");
		
		$davobj -> mkcol(-url => $newdir) or Carp::cluck("cannot create $newdir\n".$davobj-> message );
	}

}
sub cust_rmdir{
	my $self=shift;
	my $deldir=shift;
	#remove leading and training slashes of dir
	$deldir =~s/^\///;
	$deldir =~s/\/$//;
	return unless $self->pathcheck($deldir);
   my $davobj = $self->enodav();
	#creates a dav dir 
	my $fdstatus= $self->is_fd($deldir);
	if ($deldir =~/\//){ #dir has a slash in it, test if parent exists, then create:
		if ($fdstatus eq 'd'){
			$davobj -> delete(-url => $deldir) or Carp::cluck("cannot delete $deldir and its contents\n".$davobj-> message );
		}
		elsif ($fdstatus eq 'f') {Carp::cluck("$deldir is a file, not deleting.\n")}
	}
	else {
		Carp::cluck("no dir separator, assuming you are deleting dir right under webdav folder, which usually doesn't work unless you have special privs\n");
		if ($fdstatus eq 'd') {
			$davobj -> delete(-url => $deldir) or (
				Carp::cluck("cannot delete $deldir and its contents\n".$davobj-> message )
				and return 0);
			return 1;
		}
		elsif ($fdstatus eq 'f') {
			Carp::cluck("$deldir is a file, not deleting.\n");
			return 0;	
		}
	}

}
sub pathcheck{
	my $self=shift;
	my $path=shift;
	#$site and $dav should all contain trailing '/', as set up by enodav init.
	my $site=$self->lldsite;
	my $dav=$self->llddav;
	# use \Q \E because we don't want 'an additional level of interpretation as a regular expression' (perldoc perlop) 
	if ($path =~m/^\Q$site\E/){ 
		Carp::cluck("it seems like you are using a full site path\nplease use path (starting from directly under your webdav dir)\n");
		return 0;
	}
	elsif ( $path =~m/^\Q$dav\E/){
		Carp::cluck ("it seems like you are starting your dir with your webdav folder.\nPlease start with the level under it.\n");
		return 0;
	}
	else {return 1;}

}

sub write_from_memory{
	my $self=shift;
	my $binref=shift; #refernce to a scala already
	my $dest=shift;
	return unless $self->pathcheck($dest);
	unless ($self->is_fd($dest) eq 'f' or 'pd'){
		Carp::carp("write_from_memory should have 'f' or 'pd' destination\n");
		return;
	}
	my $dav=$self->enodav;
	$dav->put(-local=>$binref, -url=>$dest) or Carp::carp("HTTP::DAV put failed, [".$dav->message()."]\n");
}

sub read_into_memory{
	my $self=shift;
	my $srcurl=shift;
	return unless $self->pathcheck($srcurl);
	my $binscalar;
	my $dav=$self->enodav;
	$dav->get(-url=>$srcurl, -to=>\$binscalar);
	return (\$binscalar);

}

sub copy_local_files{
	my $self=shift;
	my $source=shift;
	my $dest=shift;
	my $dav=$self->enodav;
	if ($self->pathcheck($source) + $self->pathcheck($dest) !=2){
		Carp::cluck("please do double check your Livelink::DAV file names\n");
		return;
	}
	my $sourcetest = $self->is_fd($source);
	#do not handle dir copies
	#need to explicitly state this since DAV module is powerful enough to handle this,
	#but we are writing methods for the weakest system
	return if ($sourcetest ne 'f');		
	my $test = $self->is_fd($dest);
	if ($test ne 'pd') {
	#contains case of '0', 'f' or 'd'
		if ($test eq '0'){
			if ($dest=~m/\//){
				Carp::cluck("cannot copy to $dest whose parent does not exist, does nothing\n");
			}
			else{
				Carp::cluck("chances are you are copying to right under the webdev folder, which has a small\nchance of success unless you are some kinda admin\n");
				$dav->copy(-url=>$source, -dest=>$dest, -overwrite=>1) or Carp::cluck("cannot perform Livelink::DAV copy_local_files, ".$dav->message); 
				return;
			}
		}
		elsif ($test eq 'd') {
			Carp::cluck("dest is 'd', not handling this case. does nothing\n");
			return;
		}
		elsif ($test eq 'f'){
			Carp::carp("dest exists as file, overwriting\n");
			$dav->copy(-url=>$source, -dest=>$dest, -depth=>0, -overwrite=>1) or Carp::cluck ("Livelink::DAV move local files failed\n".$dav->message); 

		}
	}
	#$test is 'pd'
	else {
		$dav->copy(-url=>$source, -dest=>$dest, -depth=>0,-overwrite=>1) or Carp::cluck ("Livelink::DAV move local files failed\n".$dav->message); 
	}	

	
}

sub cust_rmfile{
	my $self=shift;
	my $delfile=shift;
	#remove leading and training slashes of dir
	$delfile =~s/^\///;
	$delfile =~s/\/$//;
	return unless $self->pathcheck($delfile);
   my $davobj = $self->enodav();
	#creates a dav dir 
	my $fdstatus= $self->is_fd($delfile);
	if ($delfile =~/\//){ #dir has a slash in it, test if parent exists, then create:
		if ($fdstatus eq 'f'){
			$davobj -> delete(-url => $delfile) or Carp::cluck("cannot delete $delfile\n".$davobj-> message );
		}
		elsif ($fdstatus eq 'd') {Carp::cluck("$delfile is a dir, not deleting.\n")}
	}
	else {
		Carp::cluck("no dir separator, assuming you are deleting dir right under webdav folder, which usually doesn't work unless you have special privs\n");
		if ($fdstatus eq 'f') {
			$davobj -> delete(-url => $delfile) or (
				Carp::cluck("cannot delete $delfile\n".$davobj-> message )
				and return 0);
			return 1;
		}
		elsif ($fdstatus eq 'd') {
			Carp::cluck("$delfile is a dir, not deleting.\n");
			return 0;	
		}
	}


}

no Moose; #from MooseX::NonMoose
Livelink::DAV -> meta->make_immutable;#speed up but no longer able to change class definition

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Livelink::DAV - Perl extension for providing a Opentext Livelink EWS WebDAV connecter instance for CopyTree::VendorProof.

This module provides a new [sic.] contructor and necessary subclass methods for CopyTree::VendorProof in order to deal with remote Livelink EWS WebDAV file operations.

What?

Oh, yes.  You've probabaly stumbled across this module because you wanted to copy something recursively.  Did you want to move some files into or off your SharePoint file server?  Did you buy Opentext's Livelink EWS and wish to automate some file transfers?  Well, this is kinda the right place, but it gets righter. Check out the documentation on my CopyTree::VendorProof module, where I have a priceless drill and screw analogy for how these modules all work together.  The information on this page is a tad too technical if all you're trying to decide is whether this is the module you need.


=head1 SYNOPSIS

  use Livelink::DAV;

To create a Livelink::DAV connector instance:

   my $llobj = Livelink::DAV->new;
	

To set up connection parameters:

first, define the livelink server location:

	$llobj->lldsite('http://www.livelink.server.org/');

second, find out the root directory of your webdav resource, for example, if it's at 

http://www.livelink.server.org/somedir/webdav_dir/

then for llddav use:

	'somedir/webdav_dir'

	$llobj->llddav('somedir/webdav_dir');

	#then enter your user account name:

	$llobj->lldusern('username');

	#then, enter your password:

	$llobj->llduserp('password');

As of this writing, only simple authentication has been tested, though with great imagination, simple authentication over ssl (https) should work too.

To add a source or destination item to a CopyTree::VendorProof instance:
   my $ctvp_inst = CopyTree::VendorProof ->new;

Add a Livelink::DAV source, which always starts with the dir / file right underneath the webdav_dir.  Do not include the webdav_dir itself, or any leading slashes.

   $ctvp_inst ->src ('~username/path to your source', $llobj);

	#create a new directory in Livelink:

	$llobj->cust_mkdir('~username/newdir');

	#set the destination to be in the new directory:

	$ctvp_inst -> dst ('~username/newdir',$llobj);

	#copies the file / dir

	$ctvp_inst->cp;
	


=head1 DESCRIPTION	

Livelink::DAV provides different types of methods.  

First, it provides connection methods to allow us to connect to Livelink EWS's WebDAV.  These connection methods that you see in the SYNOPSIS are pretty self explanatory. 

Second, Livelink::DAV provides methods for its parent class (CopyTree::VendorProof), which includes

   new
   fdls           
   is_fd
   read_info_memory
   write_from_memory
   copy_local_files
   cust_mkdir
   cust_rmdir
   cust_rmfile

The functionality of these methods are described in 

perldoc CopyTree::VendorProof 

It is worth nothing that fdls comes in quite handy for testing whether you can actually connect to your livelink resource using this module.  Simply open up your web browser and go to your livelink site, and fdls any resource that has a webdav property.  If you do a Dumper print, you should get something back.

   use Data::Dumper;
   print Dumper $llobj -> fdls('', '~username/');



=head2 EXPORT

None by default.

=head1 SEE ALSO

CopyTree::VendorProof
CopyTree::VendorProof::LocalFileOp 
SharePoint::SOAPHandler

=head1 AUTHOR

dbmolester, dbmolester de gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by dbmolester

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
