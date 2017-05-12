#TODO: update CONFIGURATION docs and quote the right sql tables

=head1 NAME

Konstrukt::Plugin::wiki::backend::image::DBI - Image backend driver for storage
inside a database that can be accessed through DBI.

=head1 SYNOPSIS
	
	my $image_backend = use_plugin 'Konstrukt::Plugin::wiki::backend::image::DBI' or die;
	$image_backend->do_stuff(); #see the methods description
	
=head1 DESCRIPTION

This image backend implements the storage in a database that will be accessed
through perl DBI.

Actually this one was implemented using a MySQL database. But as the queries
don't use special MySQL-functions it is very likely that it will run on other
databases without modification.

This one is very similar to L<Konstrukt::Plugin::wiki::backend::file::DBI> but adds
some image-specific funtionality.

=head1 CONFIGURATION

You have to create the tables C<wiki_image>, C<wiki_image_content> and C<wiki_image_description>,
which will be used to store the data.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

Furtheron you have to define those settings to use this backend:

	#backend
	wiki/backend_type       DBI
	wiki/backend/DBI/source dbi:mysql:database:host
	wiki/backend/DBI/user   user
	wiki/backend/DBI/pass   pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

=cut

package Konstrukt::Plugin::wiki::backend::image::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin::wiki::backend::image';

use Image::Magick;

=head1 METHODS

=head2 new

=head2 init

Initialization of this class. Loads the settings.

=cut
sub init {
	my $self = shift;
	
	#initialization of the base class
	$self->SUPER::init(@_);
	
	my $db_source = $Konstrukt::Settings->get('wiki/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('wiki/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('wiki/backend/DBI/pass');
	
	$self->{db_settings} = [$db_source, $db_user, $db_pass];
	
	return 1;
}
#= /init

=head2 install

Installs the backend (e.g. create tables).

B<Parameters:>

none

=cut
sub install {
	my $self = shift;
	return (
		$Konstrukt::Lib->plugin_dbi_install_helper($self->{db_settings}) and
		$self->SUPER::install(@_)
	);
}
# /install

=head2 exists

See L<Konstrukt::Plugin::wiki::backend::image/exists>

=cut
sub exists {
	my ($self, $title, $revision) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title    = $dbh->quote($self->normalize_link($title));
	$revision = $dbh->quote($revision) if defined $revision;
	
	#query
	my $query = "SELECT 1 FROM wiki_image WHERE title = $title" . (defined $revision ? " AND revision = $revision" : " LIMIT 1");
	return ($dbh->selectrow_array($query)) ? 1 : undef;
}
#= /exists

=head2 revision

See L<Konstrukt::Plugin::wiki::backend::image/revison>

=cut
sub revision {
	my ($self, $title) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#query
	my $query = "SELECT MAX(revision) AS revision FROM wiki_image WHERE title = " . $dbh->quote($self->normalize_link($title)) . " LIMIT 1";
	return ($dbh->selectrow_array($query));
}
#= /revision

=head2 revisions

See L<Konstrukt::Plugin::wiki::backend::image/revisons>

=cut
sub revisions {
	my ($self, $title) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#get all revisions
	my $query = "SELECT title, revision, description_revision, content_revision, author, host, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(date) AS hour, MINUTE(date) AS minute FROM wiki_image WHERE title = " . $dbh->quote($self->normalize_link($title)) . " ORDER BY revision ASC";
	my $result = $dbh->selectall_arrayref($query, { Columns=>{} });
	
	#get description for each revision, if exists
	#TODO: replace with a LEFT JOIN on wiki_image.title = wiki_image_description.title AND wiki_image.revision = wiki_image_description.revision
	foreach my $revision (@{$result}) {
		if ($revision->{description_revision}) {
			my $query = "SELECT description FROM wiki_image_description WHERE title = " . $dbh->quote($self->normalize_link($title)) . " AND revision = " . $dbh->quote($revision->{description_revision});
			$revision->{description} = ($dbh->selectrow_array($query));
		} else {
			$revision->{description} = undef;
		}
	}
	
	return @{$result} ? $result : undef;
}
#= /revisions

=head2 get_info

See L<Konstrukt::Plugin::wiki::backend::image/get_info>

=cut
sub get_info {
	my ($self, $title, $revision) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	$title = $dbh->quote($self->normalize_link($title));
	
	#get main entry
	my $query;
	if (defined $revision) {
		$revision = $dbh->quote($revision) if defined $revision;
		$query = "SELECT title, revision, description_revision, content_revision, author, host, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(date) AS hour, MINUTE(date) AS minute FROM wiki_image WHERE title = $title AND revision = $revision";	
	} else {
		$query = "SELECT title, revision, description_revision, content_revision, author, host, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(date) AS hour, MINUTE(date) AS minute FROM wiki_image WHERE title = $title ORDER BY revision DESC LIMIT 1";
	}
	my $result = $dbh->selectall_arrayref($query, { Columns=>{} });
	
	if (@{$result}) {
		my $entry = $result->[0];
		
		#get description
		if ($entry->{description_revision}) {
			$query = "SELECT description FROM wiki_image_description WHERE title = $title AND revision = ".$dbh->quote($entry->{description_revision});
			$entry->{description} = ($dbh->selectrow_array($query));
		} else {
			$entry->{description} = undef;
		}
		
		#get content info
		if ($entry->{content_revision}) {
			$query = "SELECT width, height, mimetype FROM wiki_image_content WHERE title = $title AND original = 1 AND revision = ".$dbh->quote($entry->{content_revision});
			($entry->{width}, $entry->{height}, $entry->{mimetype}) = ($dbh->selectrow_array($query));
		}

		return $entry;
	} else {
		return undef;
	}
}
#= /get

=head2 get_content

See L<Konstrukt::Plugin::wiki::backend::image/get_content>

=cut
sub get_content {
	my ($self, $title, $revision, $width) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	$title = $self->normalize_link($title);
	my $qtitle = $dbh->quote($title);
	
	#get latest revision, if not specified
	$revision = $self->revision($title) unless defined $revision;
	my $qrevision = $dbh->quote($revision);
	
	#get current content revision
	my $query = "SELECT content_revision FROM wiki_image WHERE title = $qtitle AND revision = $qrevision";
	my ($content_revision) = ($dbh->selectrow_array($query));
	
	#is there any content yet?
	if (defined $content_revision and $content_revision > 0) {
		#get original width
		my $qcontent_revision = $dbh->quote($content_revision);
		my $query = "SELECT width FROM wiki_image_content WHERE title = $qtitle AND revision = $qcontent_revision AND original = 1";
		my ($original_width) = ($dbh->selectrow_array($query));
		
		#adjust requested width. width must not be < 0 or > original width
		$width = $original_width if not defined $width or $width < 0 or $width > $original_width;
		my $qwidth = $dbh->quote($width);
		my $qoriginal_width = $dbh->quote($original_width);
		 
		#get (resized) image
		$query = "SELECT content, mimetype, width, height, original FROM wiki_image_content WHERE title = $qtitle AND revision = $qcontent_revision AND width = $qwidth";
		my $result = $dbh->selectall_arrayref($query, { Columns=>{} });
		
		#does a (resized) image with that resolution exist?
		if (@{$result}) {
			return $result->[0];
		} else {
			#get original image, resize the image, save the resized image
			$query = "SELECT content, mimetype, width, height, original FROM wiki_image_content WHERE title = $qtitle AND revision = $qcontent_revision AND width = $qoriginal_width";
			$result = $dbh->selectall_arrayref($query, { Columns=>{} });
			if (@{$result}) {
				#resize the image
				my $image = $result->[0];
				#load image
				my $im = Image::Magick->new();
				$im->BlobToImage($image->{content});
				#resize
				my ($old_width, $old_height) = $im->Get('width', 'height');
				my $aspect = $old_width / $old_height;
				my $height = $width / $aspect;
				$im->Resize(width => $width, height => $height, blur => 0.8);
				$image->{content} = $im->ImageToBlob(quality => $Konstrukt::Settings->get("wiki/image_quality"));
				if (defined $image->{content}) {
					$image->{width} = $width;
					$image->{height} = $height;
					
					#store image
					my $query = "INSERT INTO wiki_image_content(title, revision, content, mimetype, width, height) values (?, ?, ?, ?, ?, ?)";	
					my $sth = $dbh->prepare($query);
					my $rv = $sth->execute($title, $content_revision, $image->{content}, $image->{mimetype} || '', $image->{width}, $image->{height});
					
					#return the resized image
					return $image;
				} else {
					#error
					$Konstrukt::Debug->error_message("Could not resize image") if Konstrukt::Debug::ERROR;
					return undef;
				}
			} else {
				$Konstrukt::Debug->debug_message("Could not get original image") if Konstrukt::Debug::DEBUG;
				return undef;
			}
		}
	} else {
		$Konstrukt::Debug->debug_message("Could not determine content revision") if Konstrukt::Debug::DEBUG;
		return undef;
	}
}
#= /get_content

=head2 store

See L<Konstrukt::Plugin::wiki::backend::image/store>

=cut
sub store {
	my ($self, $title, $store_description, $description, $store_content, $content, $mimetype, $author, $host) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#we need at least a title
	if (defined $title) {
		#normalize title
		$title = $self->normalize_link($title);
		
		#the description and the content are stored in separate tables
		my ($description_revision, $content_revision);
		
		#get latest image info
		my $latest = $self->get_info($title);
		
		#modify description?
		if (defined $store_description) {
			#new description?
			if (defined $description) {
				#get current entry and check if the new entry differs
				my $current = $self->get_info($title);
				if (not defined $current->{description} or $current->{description} ne $description) {
					#create entry
					my $query = "INSERT INTO wiki_image_description(title, description) values (?, ?);";	
					my $sth = $dbh->prepare($query);
					my $rv = $sth->execute($self->normalize_link($title), $description);
					#get new revision
					$query = "SELECT MAX(revision) AS revision FROM wiki_image_description WHERE title = " . $dbh->quote($title) . " LIMIT 1";
					$description_revision = ($dbh->selectrow_array($query));
				} else {
					#don't store new description
					$store_description = undef;
				}
			} else {
				#reset description
				$description_revision = 0;
			}
		} else {
			#use latest description revision
			$description_revision = defined $latest ? $latest->{description_revision} : 0;
		}
		
		#modify image content?
		if (defined $store_content) {
			#new image content?
			if (defined $content) {
				#get current entry and check if the new entry differs
				my $current = $self->get_content($title);
				if (not defined $current->{content} or $current->{content} ne $content) {
					#load image
					my $im = Image::Magick->new();
					$im->BlobToImage($content);
					#successfully loaded?
					if (defined $im->[0]) {
						#get mimetype if not defined
						$mimetype = $im->Get('MIME') unless defined $mimetype;
						#get size
						my($width, $height) = $im->Get('width', 'height');
						#create entry
						my $query = "INSERT INTO wiki_image_content(title, content, width, height, mimetype, original) values (?, ?, ?, ?, ?, 1);";	
						my $sth = $dbh->prepare($query);
						my $rv = $sth->execute($title, $content, $width, $height, $mimetype);
						#get new revision
						$query = "SELECT MAX(revision) AS revision FROM wiki_image_content WHERE title = " . $dbh->quote($title) . " LIMIT 1";
						$content_revision = ($dbh->selectrow_array($query));
					} else {
						#invalid image
						return -2;
					}
				} else {
					#don't store new content
					$store_content = undef;
				}
			} else {
				#reset content
				$content_revision = 0;
			}
		} else {
			#use latest content revision
			$content_revision = defined $latest ? $latest->{content_revision} : 0;
		}
		
		#don't create new revision if neither a description nor a image content is specified and an entry already exists
		my $exists = $self->revision($title);
		if (not $exists or defined $store_description or defined $store_content) {
			#create entry
			my $query = "INSERT INTO wiki_image(title, description_revision, content_revision, author, date, host) values (?, ?, ?, ?, NOW(), ?);";	
			my $sth = $dbh->prepare($query);
			return $sth->execute($title, $description_revision, $content_revision, $author, $host);
		} else {
			#no change
			return -1;
		}
	} else {
		$Konstrukt::Debug->error_message("Cannot store image. No title specified!") if Konstrukt::Debug::ERROR;
		return undef;
	}
}
#= /store

=head2 restore

See L<Konstrukt::Plugin::wiki::backend::image/restore_description>

=cut
sub restore {
	my ($self, $title, $revision, $restore_description, $restore_content, $author, $host) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;

	#we need at least a title, a revision and one field to restore
	if (defined $title and defined $revision and ($restore_description or $restore_content)) {
		#normalize title
		$title = $self->normalize_link($title);
		
		#get info of the latest entry and the entry from which we want to restore the description
		my $cur_info = $self->get_info($title);
		my $old_info = $self->get_info($title, $revision);
		
		if (defined $old_info) {
			#is there any change?
			if (
				defined $restore_description and $cur_info->{description_revision} != $old_info->{description_revision} or
				defined $restore_content     and $cur_info->{content_revision}     != $old_info->{content_revision}
			   ) {
			   my ($description_revision, $content_revision) = ($cur_info->{description_revision}, $cur_info->{content_revision});
			   $description_revision = $old_info->{description_revision} if $restore_description;
			   $content_revision     = $old_info->{content_revision}     if $restore_content;
				#create new entry
				my $query = "INSERT INTO wiki_image(title, description_revision, content_revision, author, date, host) values (?, ?, ?, ?, NOW(), ?);";	
				my $sth = $dbh->prepare($query);
				return $sth->execute($title, $description_revision, $content_revision, $author, $host);
			} else {
				#no change
				return -1;
			}
		} else {
			$Konstrukt::Debug->error_message("Cannot restore. The specified revision $revision does not exist!") if Konstrukt::Debug::ERROR;
			return undef;
		}
	} else {
		$Konstrukt::Debug->error_message("Cannot restore. Title, revision and at least one field to restore must specified!") if Konstrukt::Debug::ERROR;
		return undef;
	}
}
#= /restore

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS wiki_image
(
	title                  VARCHAR(255)  NOT NULL,
	description_revision   INT UNSIGNED  NOT NULL,
	content_revision       INT UNSIGNED  NOT NULL,
	
	revision               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
	author                 INT UNSIGNED  NOT NULL,
	date                   DATETIME      NOT NULL,
	host                   VARCHAR(15)   ,
	
	PRIMARY KEY(title, revision)
);

CREATE TABLE IF NOT EXISTS wiki_image_content
(
	title       VARCHAR(255)     NOT NULL,
	content     MEDIUMBLOB       NOT NULL,
	width       INT UNSIGNED     NOT NULL,
	height      INT UNSIGNED     NOT NULL,
	original    TINYINT UNSIGNED,
	mimetype    VARCHAR(255),
	revision    INT UNSIGNED     NOT NULL AUTO_INCREMENT,
	
	PRIMARY KEY(title, revision, width)
);

CREATE TABLE IF NOT EXISTS wiki_image_description
(
	title       VARCHAR(255)  NOT NULL,
	description TEXT          ,
	revision    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
	
	PRIMARY KEY(title, revision)
);