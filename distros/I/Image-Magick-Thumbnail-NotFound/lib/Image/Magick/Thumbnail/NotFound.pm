package Image::Magick::Thumbnail::NotFound;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)/g;

use Image::Magick::Thumbnail;
use Image::Magick::Square;
use File::Path;
use Carp;

# PUBLIC METHODS
sub new { #{{{
	my $class = shift;
	my $self = shift;
	$self ||= {};
	
	$self->{ thumbnails_directory } ||= '/.thumbnails'; # relative to $ENV{DOCUMENT_ROOT}/index.html	
	
	$self->{ size }					||= 80;

	# auto mode will do whole process up to printing to output and exiting.
	# you want to set this to 0 if you want to do something to the thumb object before saving it
	defined $self->{ auto } or $self->{ auto } = 1; 
	
	# if 1 then it will square it in the end
	$self->{ square }					||= 0; 	
	$self->{ quality }				||= 80; 
		
	$self->{ errors }					= undef; # stays undef if no errors

	$self->{ debug }					||= 0;	

	$self->{ status } = {

		steps							=> [qw(requested source_image_exists thumbnail_created
														thumbnail_path_exists thumbnail_saved)],
	
		# 1 if request to generate, 0 if some other filetype
		# request produced 404
		requested					=> undef, 

		# if it seems a request for a thumbnail failed, does the corresponding source (large) image
		# exist on disk ?
		source_image_exists					=> undef,

		# was a thumbnail object created ?
		thumbnail_created			=> 0, 

		# used file::path to make sure destination dir exists?
		thumbnail_path_exists	=> undef,

		thumbnail_saved			=> 0,

		# any errors detected?
		errors						=> undef,	
		
	};

	
	bless $self, $class;


	# just in case.. make sure that we can't be overriting our real files..
	$self->{ thumbnails_directory } =~m/\w/ or (
		$self->_error("funny thumbnails_dir rel=".$self->{thumbnails_directory}." : won't proceed")
		and return $self 
	);


	# STEP 1
	# does the 404 request uri suggest we want a thumbnail?	
	$self->_requested() or return $self; 


	# STEP 2
	# does the source image exist? (the corresponding large image we want a thumbnail for)
	$self->_source_image_exists() or return $self; # make sure source image exists


	# STEP 3
	# ok, make the thumbnail
	$self->_create_thumbnail() or return $self; # make thumbnail, save to disk (to requested uri address)
	

	# STEP 4 
	# save the thumbnail ?
	if ($self->{auto}){
		$self->save_thumbnail();
	}


	# STEP 5 display and exit?
	if ($self->{auto}){	
		$self->display_and_exit() or return $self; # unless we set do_not_display flag, display to browser and exit
	}
	
	if ($self->{debug}){
		$self->_debug(); # status to stderr
	}
		
	return $self;

	
} #}}}


sub save_thumbnail { #{{{
	my $self = shift;

	$self->{status}->{thumbnail_created} or die ('thumbnail was not created.');

	$self->_assure_destination_directory() 
		or die ('could not assure destination_directory, problem with File::Path::mkpath ?');

	
	$self->{status}->{thumbnail_path_exists} or die ('thumbnail path not checked.');
	
	$self->{thumb}->Write($self->{out});		

	$self->{thumbnail_saved} = 1;

	return;
} #}}}


sub display { #{{{
	my $self= shift; 
	# TODO: is it ok to spit out jpeg? what if the src is png?
	# will it matter that the real one was png and we are showing the browser a jpg
	# the first time around (on fail)?
	print "Content-Type: image/jpeg\n\n";	
	binmode STDOUT;
	$self->{thumb}->Write('jpeg:-');
	return;
} #}}}


sub get_status { #{{{
	my $self = shift;
	no warnings;
	my $what = shift;
	defined $what or return $self->{status};
	return $self->{status}->{$what};	
} #}}}


sub display_and_exit {  #{{{
	my $self = shift;
	$self->{status}->{thumbnail_created} or die('cant display until we have created a thumbnail');
	$self->display();
	exit;
}  #}}}


# INTERNAL METHODS
#  {{{

sub _debug {  
	my $self = shift;
	no warnings;	
	for (@{ $self->{status}->{steps} }){	
			print STDERR "$_ ".$self->{status}->{$_}."\n";
		}
	
	return;
}  



sub _requested { 
	my $self = shift;
	my $req_uri = _decode($ENV{REQUEST_URI});
	
	# if we defined that the thumbnails are in (htdocs) /.thumbnails, and the 
	# failed request uri does not have /.thumbnails in it, then we assume we were
	# not asked for a thumbnail, and this is a normal 404 error.
	if ( $req_uri=~m/^$self->{thumbnails_directory}(\/.+\.(jpg$|jpeg$|png$|gif$))$/i ){	
	
		$self->{in}		= _cleanpath($ENV{DOCUMENT_ROOT}.'/'. $1); # image source file
		$self->{out}	= _cleanpath($ENV{DOCUMENT_ROOT}.'/'.$req_uri); # file to create, thumbnail
	
		$self->{status}->{requested} = 1;
		return 1;
	}

	$self->{status}->{requested} = 0;
	return 0;
} 


sub _source_image_exists { 
	my $self = shift;

	-f $self->{in} or do {	
		$self->{status}->{source_image_exists}=0;
		return 0;	
	};
	
	$self->{status}->{source_image_exists}=1;

	return 1;	
} 


sub _assure_destination_directory { 
	my $self = shift;

	$self->{out}=~m/^([^\|\;\:\=\%\^\<\>]+)$/;
	my $mkpath = $1; 
	$mkpath =~s/\/[^\/]+\.[^\/\.]{3,4}$//; # take out filename

	unless (-d $mkpath){ 
		# TODO: is testing if $mkpath already exists needlessly taxing cpu?
		# TODO: and what if File:::Path::mkpath fails? 
		File::Path::mkpath($mkpath); #also returns 0 on already exits. 
		# is mkpath more expensive then -d ?
	}

	$self->{status}->{thumbnail_path_exists}=1;

	return 1;
} 


# attempt to create thumb and save to disk
sub _create_thumbnail { 
	my $self= shift;

	my $src = new Image::Magick;
	$src->Read($self->{in}); 
	my $side= undef;

	if ($self->{square}){
		($src, $side) = Image::Magick::Square::create($src);
	}	
		
	my ($x,$y);

	# thumb and src are the same thing
	($self->{thumb},$x,$y) = Image::Magick::Thumbnail::create( $src, $self->{size}) 
			or $self->_error( $! . ' - Image::Magick::Thumbnail::create failed') and return $self;

	$self->{status}->{thumbnail_created} = 1;
	
	return 1;	
} 


# helper subs _error, _decode, _cleanpath 

# push errors in to array
sub _error {
	my $self= shift;
	my $error = shift;
	$error ||= 'error, cant make thumb';
	 
	#push @{$self->{errors}}= $error; 
	return;
}


# ENV{QUERY_STRING_UNENCODED} needs to be .. .decoded.
sub _decode {
	my $string = shift;
	$string=~s/%([0-9a-f]{2})/pack("c",hex($1))/gie;
	return $string;
}



# make /paths///like/these// into /paths/like/these
sub _cleanpath {
	my $path = shift;
	$path =~s/\/{2,}/\//;
	$path =~s/^\s+|\s+$//g;
	return $path;
}

#}}}

1;
__END__

=head1 NAME

Image::Magick::Thumbnail::NotFound - Create thumbnails as http requests for them fail

=head1 SYNOPSIS

	# 1) in your .htaccess file, add/modify this line:
	
	ErrorDocument 404 /cgi-bin/error.cgi
	
	
	# 2) in /cgi-bin/error.cgi:
	
	use Image::Magick::Thumbnail::NotFound;
		
	new Image::Magick::Thumbnail::NotFound; # used as auto, no need to receive object.

	# if this is a normal 404 response.. 	
	print "Content-type: text/html\n\n";
	print "The requested resource returned a 404, File Not Found error.";

	exit;
	

	# 3) Try it out, in your html 

	<a href="/images/1.jpg">
		<img src="/.thumbnails/images/1.jpg">
	</a>

	# on in your web browser
	
	http://yoursiteaddress/.thumbnails/images/1.jpg
	

=cut



=head1 DESCRIPTION

This was written to create thumbnails on a I<per request> basis. That is, create a thumbnail
on an Apache 404 error.

To be more specific, it makes thumbnails as http requests for them I<fail>,
and I<only> when they fail.

Thumbnails are stored mirroring the structure of your website, under 
the thumbnails directory (/.thumbnails by default).
A mirror tree structure of a website is created.

=cut




=head1 METHODS

Only method new() can be made use of if C<auto> is set to 0.
See EXAMPLES. 

=head2 new()

Parameters are supplied in an anonymous hash.
There are no required parameters. Optional parameters follow.


thumbnails_directory

	Let's you change where your thumbnails will be. This is I<relative> 
	to $ENV{DOCUMENT_ROOT}/index.html, default is /.thumbnails/

size
	
	If a thumbnail is made, this is the maximum pixel height or width that it will be

square
	
	This will make square thumbnails- Undistorted, sides chopped accordingly.
	Default is 0, uses C<Image::Magick::Square>.

auto

	by default a thumbnail is creted from the source image, given to the request, and
	saved to disk. If you want to do something else with the thumbnail object before
	you save it, or some for some reason you don't even want to save it.. set this to
	auto => 0 and the o 	
	ater, the
	default is 0, so if a failed thumbnail request is detected, the thumbnail
	is made and output to browser (to the request caller, your html, whatever)
	

quality

	jpeg quality of thumbnail

debug
	
	print status data to STDERR


=head2 save_thumbnail()

Saves thumbnail, accepts no arguments.	Called inernally if auto is left on default.


=head2 display()

Displays to requesting entity, accepts no arguments.


=head2 get_status()

Returns status anonymous hash. Key 'steps' contains an anonymous array with the order of 
the events (request, thumbnail_created, etc). Which are also the rest of the keys
in the status anon hash.


=head2 display_and_exit()

Display and exit script. Accepts no arguments. Called inernally if auto is left on default.

=cut





=head1 USAGE

After installing this module you will need two things to create thumbnails on the fly.
A line in a I<.htaccess> file, and a script to handle your 404 responses (referred to in this
document as I<error.cgi> ).

=head2 .htaccess

In your $ENV{DOCUMENT_ROOT} make sure you have an .htaccess file
In it must be this line:

	ErrorDocument 404 /cgi-bin/error.cgi

This is what makes apache call error.cgi when a request for a resource fails.
In turn, error.cgi will examine the request uri to see if the failed request seems to be for a thumbnail.

=head2 error.cgi

In your error.cgi file you must have this:

	#!/usr/bin/perl 
	use Image::Magick::Thumbnail::NotFound;

	new Image::Magick::Thumbnail::NotFound; # will exit on success

	print "Content-Type: text/html\n\n";
	print "That resource is missing.";
	exit;

=cut



=head1 EXAMPLES

The following examples are error.cgi examples.

=head2 EXAMPLE A

Use a directory that will reside in (htdocs) /.thumbs instead
(will be created). Also make the thumbnails 125px squares.
And show debug info (status steps).
In your error.cgi: 
	
	use strict;

	use Image::Magick::Thumbnail::NotFound;

	new Image::Magick::Thumbnail::NotFound ({
		thumbnails_directory	=> '/.thumbs', 		
		size		=> 125, 		
		square	=> 1,	
		debug		=> 1,
	});

	# if a failed request for a thumbnail was not made, continue..	
	print "Content-type: text/html\n\n";
	print "That resource is not here.";
	exit;

=head2 EXAMPLE B

Set auto off. Let's put a border around our thumbnail after it is created,
before we save it to disk. We will let it default to /.thumbnails directory.
We will also be using default size, etc.
Show debug info to STDERR.
In your error.cgi: 

	use strict;

	use Image::Magick::Thumbnail::NotFound;

	my $thumb = new Image::Magick::Thumbnail::NotFound ({
		auto => 0,	
	});

	# we have to check that the 404 error was for an image thumbnail
	if ($n->get_status('requested')){
	
		# we treat $n->{thumb} just like we do a regular Image::Magick loaded image 
		$n->{thumb}->Border(geometry=>'1x1', color=>'black');
		
		# save it - optional.. strongly encoluraged though! 
		$n->save_thumbnail();
		
		# show it and exit. 
		$n->display_and_exit();
	}	
	
	#  continue..	
	print "Content-type: text/html\n\n";
	print "That resource is not here.";
	exit;
	
=cut




=head1 LOCATION OF THUMBNAILS

If you have images in (htdocs) /tmp like so:

	tmp
	|-- a.jpg
	`-- one
	    `-- b.jpg

Your thumbnails (with default settings) will be in:

	.thumbnails/
	`-- tmp
	    |-- a.jpg
	    `-- one
	       `-- b.jpg

=cut



=head1 MOTIVATION

This really separates thumbnail 'management' from the rest of your website. This can be use stand alone with 
static html pages, as with scripts. All the rest of your website can make believe the thumbnails are there as if 
they were hand made and uploaded in photoshop. 

The edge in this system is that it uses the 404 error to call it. Thus, you do not call a thumbnail script
like 'thumbnail_please.cgi?thumb=/bla/bla.jpg', nor do you have to pre run anything to make them. 
As the thumbnails are requested, if they are not found on the server, they are made. No error to the end user is
reported. The next call for the same thumbnail will not go through the script, since the request will no 
longer generate a 404 (file not found) error.

By default this module needs little work on your part. It will detect if a request failed for a thumbnail and
if so create it, show it, and save it, so next time there is no 404 error.

But- This script does not hog the Image::Magick object, you can disable I<auto>, and make changes to the
thumbnail as you wish- before you save it to the disk, display, or both.

=cut



=head1 NOTES

Sample public_html/.htacces file and cgi-bin/error.cgi files are included in the download.

If only want a request in /.thumbnails/ to call this at all, then place your .htaccess file in
/.thumbnails/.htaccess

I've tried this software on quite differnt servers, Suse, Fedora, and FreeBSD. If you have any comments
bugs, etc. Please do contact me, and I will do the best I can to keep this code up to date.

=cut



=head1 TODO

A down of this system is that if a thumbnail is made for an image that is no longer there, you have to manually delete
the thumbnail, or you just have orphans lingering around. You will have to recreate the .htaccess file.
You can safely delete the whole thumbnails directory and have it automatically recreated, that's a present solution.

=cut




=head1 WISHLIST

Would if be of use to anyone to make an "orphans_reaper" script? Maybe a sample cron entry for that?

Per directory configuration files, with size, style (square?), and quality settings. The hesitation is the added overhead.

Have more thumbnail options? Too out of scope. 

=cut




=head1 BUGS

I had a query string encrypted with L<Crypt::CBC>, it generated an error and this took me to error.cgi, there was a problem
in parsing the query string to match a request (it looks to see if a failed request uri matches jpg, gif, etc in the end.

=head1 SEE ALSO

L<Image::Magick::Thumbnail>

=head1 AUTHOR

Leo Charre, E<lt>leo@leocharre.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Leo Charre

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
