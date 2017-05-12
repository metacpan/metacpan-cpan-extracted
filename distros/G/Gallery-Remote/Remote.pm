package Gallery::Remote;

# An implementation of the gallery remote protocol as defined by
# http://gallery.menalto.com/modules.php?op=modload&name=GalleryDocs&file=index&page=gallery-remote.protocol.php
#
# Copyright (C) 2004, Tanner Lovelace <lovelace@cpan.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this perl module; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

use strict;
use Carp;
use vars qw(
	$VERSION
	$REVISION
	@ISA
	@EXPORT
	@EXPORT_OK
	@configs
);

require Exporter;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
#use HTTP::Response;

use constant PROTOCOL_VERSION => '2.7';
use constant PROTOCOL_MAJOR   => '2';
use constant PROTOCOL_MINOR   => '7';
use constant RESPONSE_BEGINNING => '#__GR2PROTO__\n';

# Response Status Codes
#
# Status name
# Code
# Description
#
# GR_STAT_SUCCESS
# 0
# The command the client sent in the request completed
# successfully. The data (if any) in the response should be considered
# valid.
#
# GR_STAT_PROTO_MAJ_VER_INVAL
# 101
# The protocol major version the client is using is not supported.
#
# GR_STAT_PROTO_MIN_VER_INVAL
# 102
# The protocol minor version the client is using is not supported.
#
# GR_STAT_PROTO_VER_FMT_INVAL
# 103
# The format of the protocol version string the client sent in the
# request is invalid.
#
# GR_STAT_PROTO_VER_MISSING
# 104
# The request did not contain the required protocol_version key.
#
# GR_STAT_PASSWD_WRONG
# 201
# The password and/or username the client send in the request is
# invalid.
#
# GR_STAT_LOGIN_MISSING
# 202
# The client used the login command in the request but failed to
# include either the username or password (or both) in the request.
#
# GR_STAT_UNKNOWN_CMD
# 301
# The value of the cmd key is not valid.
#
# GR_STAT_NO_ADD_PERMISSION
# 401
# The user does not have permission to add an item to the gallery.
#
# GR_STAT_NO_FILENAME
# 402
# No filename was specified.
#
# GR_STAT_UPLOAD_PHOTO_FAIL
# 403
# The file was received, but could not be processed or added to the
# album.
#
# GR_STAT_NO_WRITE_PERMISSION
# 404
# No write permission to destination album.
#
# GR_STAT_NO_CREATE_ALBUM_PERMISSION
# 501
# A new album could not be created because the user does not have
# permission to do so.
#
# GR_STAT_CREATE_ALBUM_FAILED
# 502
# A new album could not be created, for a different reason (name
# conflict).
use constant GR_STAT_SUCCESS                    => '0';
use constant GR_STAT_PROTO_MAJ_VER_INVAL        => '101';
use constant GR_STAT_PROTO_MIN_VER_INVAL        => '102';
use constant GR_STAT_PROTO_VER_FMT_INVAL        => '103';
use constant GR_STAT_PROTO_VER_MISSING          => '104';
use constant GR_STAT_PASSWD_WRONG               => '201';
use constant GR_STAT_LOGIN_MISSING              => '202';
use constant GR_STAT_UNKNOWN_CMD                => '301';
use constant GR_STAT_NO_ADD_PERMISSION          => '401';
use constant GR_STAT_NO_FILENAME                => '402';
use constant GR_STAT_UPLOAD_PHOTO_FAIL          => '403';
use constant GR_STAT_NO_WRITE_PERMISSION        => '404';
use constant GR_STAT_NO_CREATE_ALBUM_PERMISSION => '501';
use constant GR_STAT_CREATE_ALBUM_FAILED        => '502';


@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION  = '0.2';
$REVISION = (qw$Rev: 13 $)[-1];

# Preloaded methods go here.

sub new {
    my $classname = shift;
    my $self      = {};
    bless($self, $classname);
    $self->_init(@_);
    return $self;
}

# 
# Intenal methods
#
sub _init
{
    my $self = shift;

    $self->{LOGGEDIN} = 0;

    if (@_) {
	my %extra = @_;
	@$self{keys %extra} = values %extra;
    }
    if ($self->{URL}) {
	$self->{REMOTE_URL} = $self->{URL} . "gallery_remote2.php";
    }
}

sub _check_response
{
    my $self     = shift;
    my $response = shift;
    my $url      = shift;

    my $response_code = $response->code;
    my $response_text = $self->_get_response_text($response);

    # Error!
    if ($response_code != 200) { 
	if ($response_code == 404) {
	    die "Remote gallery not found at " . $url ."\n" . 
		"Code   : " . $response_code . "\n" .
		"Message: " . $response_text . "\n";
	} else {
	    die "Could not log in to remote gallery at " . $url ."\n" . 
		"Code   : " . $response_code . "\n" .
		"Message: " . $response_text . "\n";
	}
    }
    return 1;
}

sub _get_response_text
{
    my $self     = shift;
    my $response = shift;
    if ($response->is_error) {
	return $response->error_as_HTML;
    }
    return $response->content;
}

sub _fill_in_response_fields
{
    my $self         = shift;
    my $field_string = shift;

    my $fields = {};

    print STDERR "Response string:\n$field_string\n" if ($self->{DEBUG});

    # Strip off the the stuff before responses.
    my $resp_beg = RESPONSE_BEGINNING;
    $field_string =~ s/.*$resp_beg//s;
    print STDERR "Response string (header stripped off):\n$field_string\n" if ($self->{DEBUG});
    my @field_lines = split('\n',$field_string);
    foreach my $line (@field_lines) {
	#print STDERR "Response line: $line\n" if ($self->{DEBUG});
	my ($field_key, $field_value) = split('=', $line);
	print STDERR "Response field: $field_key = $field_value\n" if ($self->{DEBUG});
	$fields->{$field_key} = $field_value if ($field_value ne "");
    }

    return $fields;
}

sub _fill_in_album_data
{
    my $self            = shift;
    my $response_fields = shift;
    # Array reference for returning album data
    my $album_data = ();

    for (my $i = 1; $i <= $response_fields->{album_count}; $i++) {
	my $album_entry = {};
	$album_entry->{name}       = $response_fields->{"album.name.$i"};
	$album_entry->{title}      = $response_fields->{"album.title.$i"};
	$album_entry->{parent}     = $response_fields->{"album.parent.$i"};
	$album_entry->{add}        = ($response_fields->{"album.perms.add.$i"} eq 'true' ? 1 : 0);
	$album_entry->{write}      = ($response_fields->{"album.perms.write.$i"} eq 'true' ? 1 : 0);
	$album_entry->{del_item}   = ($response_fields->{"album.perms.del_item.$i"} eq 'true' ? 1 : 0);
	$album_entry->{del_alb}    = ($response_fields->{"album.perms.del_alb.$i"} eq 'true' ? 1 : 0);
	$album_entry->{create_sub} = ($response_fields->{"album.perms.create_sub.$i"} eq 'true' ? 1 : 0);

	print STDERR "Response fields: \n" .
	             " album.name.$i             = " . $response_fields->{"album.name.$i"} . "\n" .
	             " album.title.$i            = " . $response_fields->{"album.title.$i"} . "\n" .
	             " album.parent.$i           = " . $response_fields->{"album.parent.$i"} . "\n" .
		     " album.perms.add.$i        = " . $response_fields->{"album.perms.add.$i"} . "\n" .
		     " album.perms.write.$i      = " . $response_fields->{"album.perms.write.$i"} . "\n" .
		     " album.perms.del_item.$i   = " . $response_fields->{"album.perms.del_item.$i"} . "\n" .
		     " album.perms.del_alb.$i    = " . $response_fields->{"album.perms.del_alb.$i"} . "\n" .
		     " album.perms.create_sub.$i = " . $response_fields->{"album.perms.create_sub.$i"} . "\n"
		     if ($self->{DEBUG});
		     
	push @$album_data, $album_entry;
    }
    
    return $album_data;
}

#
# External methods
#
sub set_server
{
    my $self = shift;

    if ($self->{LOGGEDIN}) { $self->logout(); }

    # Setup values.
    $self->{URL}      = shift;
    $self->{USERNAME} = shift;
    $self->{PASSWORD} = shift;

    $self->{REMOTE_URL} = $self->{URL} . "gallery_remote2.php";
}

sub login
{
    my $self = shift;

    die "URL must be set to login to remote gallery" unless $self->{REMOTE_URL};
    die "USERNAME must be set to login to remote gallery" unless $self->{USERNAME};
    die "PASSWORD must be set to login to remote gallery" unless $self->{PASSWORD};

    $self->{_UA} = LWP::UserAgent->new;
    $self->{_UA}->cookie_jar(HTTP::Cookies->new(file => 'cookie_jar', autosave => 1));

    my $response  = $self->{_UA}->request(POST $self->{REMOTE_URL},
					  Content_Type => 'form-data',
					  Content      => [ protocol_version => PROTOCOL_VERSION,
							    cmd => "login",
							    uname => $self->{USERNAME},
							    password => $self->{PASSWORD}
							  ] );

    my $response_text = $self->_get_response_text($response);

    $self->_check_response($response,$self->{URL});

    # Ok, the file was there.  Parse the response codes.
    my $response_fields = $self->_fill_in_response_fields($response_text);

    print STDERR "Response status: $response_fields->{status}\n" if ($self->{DEBUG});

    if ($response_fields->{status} eq GR_STAT_SUCCESS) {
	# Make sure our version number is high enough
	my ($major, $minor) = split('\.', $response_fields->{server_version});
	if ($major != PROTOCOL_MAJOR) {
	    die "Major protocol mismatch.  Was expecting " . PROTOCOL_MAJOR . ".  Got: $major";
	}
	if ($minor < PROTOCOL_MINOR) {
	    die "Need a minor protocol of at least " . PROTOCOL_MINOR . ". Got: $minor";
	}
	$self->{LOGGEDIN} = 1;
	print "Login successful\n" if ($self->{VERBOSE});
    } else {
	die "Could not log in to remote gallery at " . $self->{URL} ."\n" . 
	    "Status: " . $response_fields->{status} . "\n" .
	    "Text  : " . $response_fields->{status_text} . "\n";
    }
}

sub logout
{
    my $self = shift;

    # No specific logout command, so reset variables

    $self->{LOGGEDIN} = 0;
    $self->{_UA} = undef;
}


# Getting a list of albums
#
# The fetch-albums command asks the server to return a list of all
# albums (visible with the client's logged in user permissions).
#
# Context
#
# A request with the login command must be made before the
# fetch-albums command is used.
#
# Form data
#
# cmd=fetch-albums
# protocol_version=2.0
#
# Results
#
#           #__GR2PROTO__
#          status=result-code
#          status_text=explanatory-text
#         /album.name.ref-num=album-url-name
#         |album.title.ref-num=album-display-name
#         |album.summary.ref-num=album-summary [since 2.8]
#         |album.parent.ref-num=parent-ref-num
#         |album.resize_size.ref-num=image-resize-size [since 2.8]
#   0...n |album.perms.add.ref-num=boolean
#         |album.perms.write.ref-num=boolean
#         |album.perms.del_item.ref-num=boolean
#         |album.perms.del_alb.ref-num=boolean
#         |album.perms.create_sub.ref-num=boolean
#         \album.info.extrafields.ref-num=extra-fields [since 2.3]
#          album_count=number-of-albums
#          can_create_root=yes/no [since 2.11]
#
# If the result-code is equal to GR_STAT_SUCCESS, the album data was
# fetched successfully.
#
# If successful, a response to the fetch-albums command returns
# several keys for each album in the gallery, where
#
# ref-num is a reference number,
#
# album-url-name is the name of the partial URL for the gallery,
#
# album-display-name is the gallery's visual name,
#
# album-summary is the summary of the album,
#
# parent-ref-num refers to some other album's ref-num. A
#   parent-ref-num of 0 (zero) indicates that the album is a "top-level"
#   album (it has no parent).
#
# image-resize-size is the intermediate size of images created when a
#   large image is added to an album,
#
# extra-fields is a comma-separated list of extra fields names, and
#   boolean represents a boolean value. true is considered true, any
#   other value false.
#
# Several "permissions" are reported for each album. The reported
# permissions are the effective permissions of the currently logged in
# user:
#
# the add permission allows the user to add a picture to the album.
#
# the write permission allows the user to add and change pictures in
# the album.
#
# the del_item permission allows the user remove pictures from the
# album.
#
# the del_alb permission allows the user to delete the album.
#
# the create_sub permission allows the user to create nested albums in
# the album.
#
# The number of albums in the response is returned as
# number-of-albums.
#
# can_create_root will be set to either yes or no depending on the
# user's permissions to create albums at the root level.
sub fetch_albums
{
    my $self = shift;

    die "Must log in before fetching albums" unless ($self->{LOGGEDIN});

    my $response  = $self->{_UA}->request(POST $self->{REMOTE_URL},
					  Content_Type => 'form-data',
					  Content      => [ protocol_version => PROTOCOL_VERSION,
							    cmd => "fetch-albums",
							  ] );

    my $response_text = $self->_get_response_text($response);

    $self->_check_response($response,$self->{URL});

    # Ok, the file was there.  Parse the response codes.
    my $response_fields = $self->_fill_in_response_fields($response_text);

    if ($response_fields->{status} ne GR_STAT_SUCCESS) {
	die "Could not fetch-albums from remote gallery at " . $self->{URL} ."\n" . 
	    "Status: " . $response_fields->{status} . "\n" .
	    "Text  : " . $response_fields->{status_text} . "\n";
    }

    return($self->_fill_in_album_data($response_fields));
}


# Getting a list of albums v2, more efficient [since 2.2]
#
# The fetch-albums-prune command asks the server to return a list of
# all albums that the user can either write to, or that are visible to
# the user and contain a sub-album that is writable (including
# sub-albums several times removed).
#
# The reason for this slightly altered version of fetch-albums is
# two-fold: the previous version was slow on the server-side, because
# of the way it was structured, and limitation in the Gallery mode of
# operation; it returns all albums the the user can read, even if
# writing is not allowed. This new version is faster, because it uses
# a more efficient algorithm to find albums; it is more efficient
# because it only sends albums that are useful to the client. It also
# doesn't parse the pictures database, which makes it run much faster
# on the server.
#
# Context
#
# A request with the login command must be made before the
# fetch-albums-prune command is used.
#
# Form data
#
# cmd=fetch-albums-prune
# protocol_version=2.2
# check_writeable=yes/no [since 2.13]
#
# Results
#
#           #__GR2PROTO__
#          status=result-code
#          status_text=explanatory-text
#         /album.name.ref-num=album-url-name
#         |album.title.ref-num=album-display-name
#         |album.summary.ref-num=album-summary [since 2.8]
#         |album.parent.ref-num=parent-ref-num
#         |album.resize_size.ref-num=image-resize-size [since 2.8]
#         |album.thumb_size.ref-num=image-thumb-size [since 2.9]
#   0...n |album.perms.add.ref-num=boolean
#         |album.perms.write.ref-num=boolean
#         |album.perms.del_item.ref-num=boolean
#         |album.perms.del_alb.ref-num=boolean
#         |album.perms.create_sub.ref-num=boolean
#         \album.info.extrafields.ref-num=extra-fields [since 2.3]
#          album_count=number-of-albums
#          can_create_root=yes/no [since 2.11]
#
# If the result-code is equal to GR_STAT_SUCCESS, the album data was
# fetched successfully.
#
# If successful, a response to the fetch-albums-prune command returns
# several keys for each album in the gallery, where
#
# ref-num is a reference number,
#
# album-url-name is the name of the partial URL for the gallery,
#
# album-display-name is the gallery's visual name,
#
# album-summary is the summary of the album,
#
# parent-ref-num refers to some other album's ref-num. A
# parent-ref-num of 0 (zero) indicates that the album is a "top-level"
# album (it has no parent).
#
# image-resize-size is the intermediate size of images created when a
# large image is added to an album,
#
# extra-fields is a comma-separated list of extra fields names,
#
# and boolean represents a boolean value. true is considered true, any
# other value false.
#
# Several "permissions" are reported for each album. The reported
# permissions are the effective permissions of the currently logged in
# user:
#
# the add permission allows the user to add a picture to the album.
#
# the write permission allows the user to add and change pictures in
# the album.
#
# the del_item permission allows the user remove pictures from the
# album.
#
# the del_alb permission allows the user to delete the album.
#
# the create_sub permission allows the user to create nested albums in
# the album.
#
# The number of albums in the response is returned as number-of-albums.
#
# can_create_root will be set to either yes or no depending on the
# user's permissions to create albums at the root level.
sub fetch_albums_prune
{
    my $self = shift;

    die "Must log in before fetching albums" unless ($self->{LOGGEDIN});

    my $response  = $self->{_UA}->request(POST $self->{REMOTE_URL},
					  Content_Type => 'form-data',
					  Content      => [ protocol_version => PROTOCOL_VERSION,
							    cmd => "fetch-albums-prune",
							  ] );

    my $response_text = $self->_get_response_text($response);

    $self->_check_response($response,$self->{URL});

    # Ok, the file was there.  Parse the response codes.
    my $response_fields = $self->_fill_in_response_fields($response_text);

    if ($response_fields->{status} ne GR_STAT_SUCCESS) {
	die "Could not fetch-albums-prune from remote gallery at " . $self->{URL} ."\n" . 
	    "Status: " . $response_fields->{status} . "\n" .
	    "Text  : " . $response_fields->{status_text} . "\n";
    }

    return($self->_fill_in_album_data($response_fields));
}

# Uploading a photo to an album
#
# The add-item command asks the server to add a photo to a specified
# album.
#
# Context
#
# A request with the login command must be made before the add-item
# command is used.
#
# Form data
#
# cmd=add-item
# protocol_version=2.0
# set_albumName=album name
# userfile=form-data-encoded image data [since 2.0] or URL of image [since 2.12]
# userfile_name=file name (usually inserted automatically by HTTP library, which is why we also have force_filename
# caption=caption (optional) [since 2.0]
# force_filename=name of the file on the server (optional) [since 2.0]
# auto_rotate=yes/no (optional) [since 2.5]
# extrafield.fieldname=value of the extra field fieldname (optional) [since 2.3]
#
# Multiple extrafield lines with different fieldname values can be
# used.
#
# Only gallery administrators can specify a URL as the userfile.
#
# Results
#
# #__GR2PROTO__
# status=result-code
# status_text=explanatory-text
#
# If the result-code is equal to GR_STAT_SUCCESS, the file upload
# succeeded.
sub add_item
{
    my $self = shift;

    die "Must log in before getting album properties" unless ($self->{LOGGEDIN});

    my %params = @_;

    if (!$params{set_albumName}) {
	die "Must specify album to add items to it.";
    }
    if (!$params{userfile}) {
	die "Must specify an image file or url for add_item.";
    }
    if (!$params{userfile_name}) {
	die "Must specify an image file name or url for add_item.";
    }

    my $content = { protocol_version => PROTOCOL_VERSION,
		    cmd => "add-item",
		  };

    # Set everything at once.
    @$content{keys %params} = values %params;

    my $response  = $self->{_UA}->request(POST $self->{REMOTE_URL},
					  Content_Type => 'form-data',
					  Content      => $content );

    my $response_text = $self->_get_response_text($response);

    $self->_check_response($response,$self->{URL});

    # Ok, the file was there.  Parse the response codes.
    my $response_fields = $self->_fill_in_response_fields($response_text);

    if ($response_fields->{status} ne GR_STAT_SUCCESS) {
	die "Could not execute album-properties command on remote gallery at " . $self->{URL} ."\n" . 
	    "Status: " . $response_fields->{status} . "\n" .
	    "Text  : " . $response_fields->{status_text} . "\n";
    }

    # XXX - Do we want to return this for all methods?
    return $response_fields;
}

# Getting information about an album [since 2.0]
#
# The album-properties command asks the server for information about
# an album.
#
# Context
#
# A request with the login command must be made before the
# album-properties command is used.
#
# Form data
#
# cmd=album-properties
# protocol_version=2.0
# set_albumName=album name
#
# Results
#
# #__GR2PROTO__
# status=result-code
# status_text=explanatory-text
# auto_resize=resize-dimension
# add_to_beginning=yes/no
#
# If the result-code is equal to GR_STAT_SUCCESS, the request
# succeeded.
#
# If an image is uploaded such that its largest dimension is greater
# than resize-dimension, the server will resize it. Otherwise, the
# server will use the original image that was uploaded for both the
# full-sized and the resized size. In all cases a thumbnail-sized
# image will be created. The creation of a thumbnail is highly
# dependant on the size of the image that was uploaded.
#
# If the value is 0 (zero), the Gallery server does not intend to
# resize uploaded images.
#
# add_to_beginning will contain yes or no based on whether the album
# will add images to the beginning or the end of the album. [since
# 2.10]
sub album_properties
{
    my $self = shift;

    die "Must log in before getting album properties" unless ($self->{LOGGEDIN});

    my %params = @_;

    if (!$params{set_albumName}) {
	die "Must specify album to get its properties";
    }

    my $content = { protocol_version => PROTOCOL_VERSION,
		    cmd => "album-properties",
		  };

    # Set everything at once.
    @$content{keys %params} = values %params;

    my $response  = $self->{_UA}->request(POST $self->{REMOTE_URL},
					  Content_Type => 'form-data',
					  Content      => $content );

    my $response_text = $self->_get_response_text($response);

    $self->_check_response($response,$self->{URL});

    # Ok, the file was there.  Parse the response codes.
    my $response_fields = $self->_fill_in_response_fields($response_text);

    if ($response_fields->{status} ne GR_STAT_SUCCESS) {
	die "Could not execute album-properties command on remote gallery at " . $self->{URL} ."\n" . 
	    "Status: " . $response_fields->{status} . "\n" .
	    "Text  : " . $response_fields->{status_text} . "\n";
    }

    # XXX - Do we want to return this for all methods?
    return $response_fields;
}

# Creating a new album [since 2.1]
#
# The new-album command asks the server to add a new album to the
# gallery installation.
#
# Context
#
# A request with the login command must be made before the new-album
# command is used.
#
# Form data
#
# cmd=new-album
# protocol_version=2.1
# set_albumName=parent-album-name
# newAlbumName=album-name (optional)
# newAlbumTitle=album-title (optional)
# newAlbumDesc=album-description (optional)
#
# parent-album-name is the name of the gallery that the new album
# should be created under, or 0 to create the album at the top-level;
#
# album-name is the new album's desired name. The name must be unique
# within the Gallery. If it is not, then Gallery will assign an
# automatically-generated name. An automatically generated name will
# also be used if this parameter is not provided or is empty;
#
# album-title is the new album's desired title;
#
# album-description is the new album's desired description.
#
# Results
#
# #__GR2PROTO__
# status=result-code
# status_text=explanatory-text
# album_name=actual-name [since 2.5]
#
# If the result-code is equal to GR_STAT_SUCCESS, the request
# succeeded.
#
# If the result-code is equal to GR_STAT_NO_CREATE_ALBUM_PERMISSION,
# the logged-in user doesn't have permission to create an album in the
# specified location.
#
# If an album is created with the same name as an already existing
# album or album-title is left blank, gallery will automatically
# generate an album name. actual-name will return the name of the
# newly created album.
sub new_album
{
    my $self = shift;

    die "Must log in before creating albums" unless ($self->{LOGGEDIN});

    my %params = @_;

    my $content = { protocol_version => PROTOCOL_VERSION,
		    cmd => "new-album",
		  };

    # Set everything at once.
    @$content{keys %params} = values %params;

    my $response  = $self->{_UA}->request(POST $self->{REMOTE_URL},
					  Content_Type => 'form-data',
					  Content      => $content );

    my $response_text = $self->_get_response_text($response);

    $self->_check_response($response,$self->{URL});

    # Ok, the file was there.  Parse the response codes.
    my $response_fields = $self->_fill_in_response_fields($response_text);

    if ($response_fields->{status} ne GR_STAT_SUCCESS) {
	die "Could not execute new-album command on remote gallery at " . $self->{URL} ."\n" . 
	    "Status: " . $response_fields->{status} . "\n" .
	    "Text  : " . $response_fields->{status_text} . "\n";
    }

    return $response_fields->{album_name};
}

# Getting the list of photos in an album [since 2.4]
#
# The fetch-album-images command asks the server to return information
# about all the images in an album. It ignores sub-albums.
#
# Context
#
# A request with the login command can be made before the
# fetch-album-images command is used, but since viewing photos in an
# album is generally (but not always) open to non logged-in users, a
# login is not always necessary.
#
# Form data
#
# cmd=fetch-album-images
# protocol_version=2.4
# set_albumName=album-name
# albums_too=yes/no [since 2.13]
#
# If set_albumName empty, the root albums are listed. Of course, this
# only works if albums_too is also used [since 2.13]
#
# Results
#
#          #__GR2PROTO__
#          status=result-code
#          status_text=explanatory-text
#         /image.name.ref_num=filename of the image
#         |image.raw_width.ref_num=the width of the full-sized image
#         |image.raw_height.ref_num=the height of the full-sized image
#         |image.resizedName.ref_num=filename of the resized image, if there is one
#         |image.resized_width.ref_num=the width of the resized image, if there is one [since 2.9]
#         |image.resized_height.ref_num=the height of the resized image, if there is one [since 2.9]
#         |image.thumbName.ref_num=filename of the thumbnail [since 2.9]
#         |image.thumb_width.ref_num=the width of the thumbnail [since 2.9]
#         |image.thumb_height.ref_num=the height of the thumbnail [since 2.9]
#         |image.raw_filesize.ref_num=size of the full-sized image
#         |image.caption.ref_num=caption associated with the image
#   0...n |image.extrafield.fieldname.ref_num=value of the extra field of key fieldname
#         |image.clicks.ref_num=number of clicks on the image
#         |image.capturedate.year.ref_num=date of capture of the image (year)
#         |image.capturedate.mon.ref_num=date of capture of the image (month)
#         |image.capturedate.mday.ref_num=date of capture of the image (day of the month)
#         |image.capturedate.hours.ref_num=date of capture of the image (hour)
#         |image.capturedate.minutes.ref_num=date of capture of the image (minute)
#         \image.capturedate.seconds.ref_num=date of capture of the image (second)
#   OR     album.name.ref_num=name of the album [since 2.13]
#          image_count=total number of images in the album
#          baseurl=URL of the album
#
# If the result-code is equal to GR_STAT_SUCCESS, the request
# succeeded.
#
# The baseurl contains a fully-qualified URL. A URL to each image can
# be obtained by appending the filename of the image to this.
#
# The name and resizedName include the type (extension), but do not
# include any path information.
#
# Multiple extrafield lines with different fieldname values can be
# used.
#
# If albums_too is yes, the list of results can contain album
# references. In this case, none of the image.*.ref_num fields will be
# present. Instead, album.name.ref_num will provide the reference to
# the sub-album. This allows reursive getting of all images in an
# album hierarchy.
sub fetch_album_images
{
    my $self = shift;

    die "XXX - fetch_album_images not implemented yet!";
}

# Moving an album [since 2.7]
#
# The move-album command asks the server to move an album to a new
# location within the photo gallery.
#
# Context
#
# A request with the login command must be made before the move-album
# command is used.
#
# Form data
#
# cmd=move-album
# protocol_version=2.7
# set_albumName=source-album
# set_destalbumName=destination-album
#
# source-album is the name of the album that you intend to move;
#
# destination-album is the name of the album that the source-album
# will be moved into, or 0 if the source-album should be moved to the
# root level;
#
# Results
#
# #__GR2PROTO__
# status=result-code
# status_text=explanatory-text
#
# If the result-code is equal to GR_STAT_SUCCESS, the album move succeeded.
sub move_album
{
    my $self = shift;

    die "Must log in before creating albums" unless ($self->{LOGGEDIN});

    my %params = @_;

    if (!$params{set_albumName}) {
	die "Must specify album to move";
    }
    if (!$params{set_destalbumName}) {
	die "Must specify destination for move";
    }

    my $content = { protocol_version => PROTOCOL_VERSION,
		    cmd => "move-album",
		  };

    # Set everything at once.
    @$content{keys %params} = values %params;

    my $response  = $self->{_UA}->request(POST $self->{REMOTE_URL},
					  Content_Type => 'form-data',
					  Content      => $content );

    my $response_text = $self->_get_response_text($response);

    $self->_check_response($response,$self->{URL});

    # Ok, the file was there.  Parse the response codes.
    my $response_fields = $self->_fill_in_response_fields($response_text);

    if ($response_fields->{status} ne GR_STAT_SUCCESS) {
	die "Could not execute move-album command on remote gallery at " . $self->{URL} ."\n" . 
	    "Status: " . $response_fields->{status} . "\n" .
	    "Text  : " . $response_fields->{status_text} . "\n";
    }

    return $response_fields->{status};
}

1;
__END__
# This documentation is still incomplete and needs to be finished.

=head1 NAME

Gallery::Remote - Perl extension for interacting with the Gallery remote protocol.

=head1 SYNOPSIS

  use Gallery::Remote;

  # Instatiate a new Gallery::Remote object
  my $remote_gallery  = Gallery::Remote->new(URL => 'http://www.example.com/gallery/',
                                             USERNAME => 'admin',
                                             PASSWORD => 'password');

  $remote_gallery->login();

  # Get an array of hash information about remote albums.
  my $album_data = $remote_gallery->fetch_albums_prune();

  if ($album_data) {
    print "Albums found: " . scalar(@$album_data) . "\n";
  } else {
    print "No albums found.\n";
  }

  # Go through and find all album data.
  foreach my $album_entry (@$album_data) {
    foreach my $key (keys %$album_entry) {
      print "Found: album_entry{$key} = $$album_entry{$key}\n";
    }
  }

  my $parms = {};
  my $picparms = {};

  $$parms{name} = "test";
  $$parms{title} = "A test of Gallery::Remote";
  $$parms{desc} = "I'm testing out my perl script";

  my $parent_album = $remote_gallery->new_album( %$parms );

  $parms = {};
  $$parms{parent} = $parent_album;
  $$parms{title} = "Test Album";
  $$parms{desc} = "Sub album test";
  $$parms{name} = "test2";
  my $new_album_name = $remote_gallery->new_album( %$parms );
  print "Created new album: $new_album_name under parent album $parent_album\n";

  $$picparms{set_albumName} = $new_album_name;
  $$picparms{userfile} = [ "./example.jpg" ];
  $$picparms{userfile_name} = "example.jpg";
  $$picparms{caption} = "Testing Gallery::Remote";

  $remote_gallery->add_item( %$picparms );


=head1 DESCRIPTION

B<Gallery::Remote> is a perl module that allows remote access to
a remote gallery.

=head1 METHODS

=over 2

=item B<new( URL => "http://gallery.example.com/", USERNAME => "admin", PASSWORD => "password", VERBOSE => 0, DEBUG => 0, )>

The B<new()> method specifies the remote gallery and a username
and pasword combination to log in with. You can optionally
specify verbose operation or debug (which will print out a lot
of information).

=back

=head1 AUTHOR

Tanner Lovelace <lovelace@wayfarer.org>

=head1 SEE ALSO

Gallery - http://gallery.sf.net/

=cut
