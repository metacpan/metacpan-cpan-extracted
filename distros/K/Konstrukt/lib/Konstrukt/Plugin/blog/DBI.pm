=head1 NAME

Konstrukt::Plugin::blog::DBI - Konstrukt blogging DBI backend

=head1 SYNOPSIS
	
	#TODO
	
=head1 DESCRIPTION

Konstrukt blogging DBI Backend driver.

=head1 CONFIGURATION

Note that you have to create the tables C<blog_entry> and C<blog_comment>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

You may define the source of this backend:

	#backend
	blog/backend/DBI/source       dbi:mysql:database:host
	blog/backend/DBI/user         user
	blog/backend/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

=cut

package Konstrukt::Plugin::blog::DBI;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use strict;
use warnings;

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('blog/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('blog/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('blog/backend/DBI/pass');
	
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
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_dbi_install_helper($self->{db_settings});
}
# /install

=head2 add_entry

Adds a new blog entry and returns its ID.

B<Parameters>:

=over

=item * $title - The title of this entry

=item * $description - A short abstract of this entry

=item * $content - The entry's content (usually wiki "source code")

=item * $author - The entry's author

=item * $private - Is this entry only visible to the author?

=back

=cut
sub add_entry {
	my ($self, $title, $description, $content, $author, $private) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title       = $dbh->quote($title       || '');
	$description = $dbh->quote($description || '');
	$content     = $dbh->quote($content     || '');
	$author      = $dbh->quote($author      ||  0);
	$private     = $dbh->quote($private     ||  0);
	
	#insert blog entry
	my $query = "INSERT INTO blog_entry (title, description, content, author, private, date) VALUES ($title, $description, $content, $author, $private, NOW())";
	$dbh->do($query) or return;
	
	#id of added entry
	return $dbh->last_insert_id(undef, undef, undef, undef) || undef;
}
#= /add_entry

=head2 update_entry

Updates an existing blog entry.

B<Parameters>:

=over

=item * $id          - The id of the entry, which should be updated

=item * $title       - The title of this entry

=item * $description - A short abstract of this entry

=item * $content     - The entry's content

=item * $private     - Is this entry only visible to the author?

=item * $update      - Update the publication date to "now"

=back

=cut
sub update_entry {
	my ($self, $id, $title, $description, $content, $private, $update) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title       = $dbh->quote($title       || '');
	$description = $dbh->quote($description || '');
	$content     = $dbh->quote($content     || '');
	$private     = $dbh->quote($private     ||  0);
	
	$update = ($update ? ", date = NOW()" : "");
	
	#update blog entry
	my $query = "UPDATE blog_entry SET title = $title, description = $description, content = $content, private = $private $update WHERE id = " . int($id);
	return $dbh->do($query);
}
#= /update_entry

=head2 get_entry

Returns the requested blog entry as an hash reference with the keys id, title,
description, content, author, year, month, day, hour, minute, private,
comment_count and trackback_count.

Returns C<undef> if the entry does not exist.

B<Parameters>:

=over

=item * $id - The id of the entry

=back

=cut
sub get_entry {
	my ($self, $id) = @_;
	
	my $rv = $self->get_entries({id => $id});
	
	return (@{$rv} ? $rv->[0] : undef);
}
#= /get_entry

=head2 get_entries_count

Returns the count of the entries.

=cut
sub get_entries_count {
	my ($self) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return -1;
	return $dbh->selectrow_array('SELECT COUNT(id) FROM blog_entry');
}
#= /get_entries_count

=head2 get_entries

Returns the blog entries as an array reference of hash references:
	{ id => .., title => .., description => .., content => .., author => ..,
	  year => .., month => .., day => .., hour => .., minute => ..,
	  private => .., comment_count => .., trackback_count => .. }

B<Parameters>:

=over

=item * $select = { tags => "tag query string", id => 23, author => 42, year => 1234, month => 5, day => 23, text => fulltext } (optional).
This argument is OPTIONAL. If not passed, all entries will be retrieved.
It is an hash reference which determines which entries will be retrieved.
For each set hash-key only the matching entries will be returned
Note that these options are "and"-linked.
The tag query string is passed to the L<Konstrukt::Plugin::tags/get_entries> method.

=item * $start - The first entry to display. starts with 0

=item * $count - The number of entries to display

=back

=cut
sub get_entries {
	my ($self, $select, $start, $count) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my @tags;
	if (exists($select->{tags}) and $select->{tags} and not (exists($select->{id}) and $select->{id})) {
		my $tags = use_plugin 'tags';
		@tags = @{$tags->get_entries($select->{tags}, 'blog')};
		return [] unless @tags;
	}
	
	#put together the appropriate query
	my @wheres = ();
	my ($from, $where) = ('FROM blog_entry', '');
	if (defined($select)) {
		push @wheres, 'blog_entry.id IN (' . join(", ", map { $dbh->quote($_) } @tags) .')' if exists($select->{tags}) and $select->{tags} and not (exists($select->{id}) and $select->{id});
		push @wheres, 'blog_entry.id = '      . $dbh->quote($select->{id})     if exists($select->{id})     and $select->{id};
		push @wheres, 'blog_entry.author  = ' . $dbh->quote($select->{author}) if exists($select->{author}) and $select->{author};
		push @wheres, 'YEAR(blog_entry.date) = '       . $dbh->quote($select->{year})  if exists($select->{year})  and $select->{year};
		push @wheres, 'MONTH(blog_entry.date) = '      . $dbh->quote($select->{month}) if exists($select->{month}) and $select->{month};
		push @wheres, 'DAYOFMONTH(blog_entry.date) = ' . $dbh->quote($select->{day})   if exists($select->{day})   and $select->{day};
		if (exists($select->{text}) and $select->{text}) {
			$select->{text} = $dbh->quote("%$select->{text}%");
			push @wheres, "(blog_entry.title LIKE $select->{text} OR blog_entry.description LIKE $select->{text} OR blog_entry.content LIKE $select->{text})";
		}
	}
	if (@wheres) {
		$where = ' WHERE ' . join(' AND ', @wheres) . ' ';
	}
	my $limit = (defined $start and defined $count ? " LIMIT $start, $count" : "");
	
	#get entry
	my $query = "SELECT blog_entry.id AS id, blog_entry.title AS title, blog_entry.description AS description, blog_entry.content AS content, blog_entry.author AS author, blog_entry.private AS private, YEAR(blog_entry.date) AS year, MONTH(blog_entry.date) AS month, DAYOFMONTH(blog_entry.date) AS day, HOUR(blog_entry.date) AS hour, MINUTE(blog_entry.date) AS minute $from $where ORDER BY blog_entry.date DESC" . $limit;
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	
	if (@{$rv}) {
		foreach my $entry (@{$rv}) {
			#get comment count
			my $rv2 = $dbh->selectall_arrayref("SELECT COUNT(id) AS count FROM blog_comment WHERE entry = $entry->{id}", { Columns=>{} });
			$entry->{comment_count} = $rv2->[0]->{count} || 0;
			#get trackback count
			$rv2 = $dbh->selectall_arrayref("SELECT COUNT(id) AS count FROM blog_trackback WHERE entry = $entry->{id}", { Columns=>{} });
			$entry->{trackback_count} = $rv2->[0]->{count} || 0;
		}
	}
	
	return $rv;
}
#= /get_entries

=head2 delete_entry

Removes an existing blog entry.

B<Parameters>:

=over

=item * $id - The id of the entry, which should be removed

=back

=cut
sub delete_entry {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	$id = int($id);
	
	#remove blog entry
	$dbh->do("DELETE FROM blog_entry WHERE id = $id") or return;
	#remove comments of this entry
	$dbh->do("DELETE FROM blog_comment WHERE entry = $id") or return;
	
	return 1;
}
#= /delete_entry

=head2 get_authors

Returns the user IDs of all blog authors as an array reference:
[5, 7, 1, 6]

=cut
sub get_authors {
	my ($self) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT DISTINCT author FROM blog_entry";
	my $rv = $dbh->selectcol_arrayref($query);
	
	return $rv;
}
#= /get_authors

=head2 get_comment

Returns the comments with the specified id as an hash reference:
{ id => .., entry => .., user => .., author => .., text => ..,
  email => .., email_public => .., email_notify => ..,
  year => .., month => .., day => .., hour => .., minute => .. }

B<Parameters>:

=over

=item * $id - The comment's id

=back

=cut
sub get_comment {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT id, entry, user, author, email, email_public, email_notify, text, YEAR(timestamp) AS year, MONTH(timestamp) AS month, DAYOFMONTH(timestamp) AS day, HOUR(timestamp) AS hour, MINUTE(timestamp) AS minute FROM blog_comment WHERE id = " . int($id);
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	
	return (@{$rv} ? $rv->[0] : {});
}
#= /get_comment

=head2 get_comments

Returns the comments of a specified blog entry as an array reference of hash references:
{ id => .., entry => .., user => .., author => .., text => ..,
  email => .., email_public => .., email_notify => ..,
  year => .., month => .., day => .., hour => .., minute => .. }

The entries should be ordered by ascending date (earliest post first).

B<Parameters>:

=over

=item * $id - The entry's id

=back

=cut
sub get_comments {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT id, entry, user, author, email, email_public, email_notify, text, YEAR(timestamp) AS year, MONTH(timestamp) AS month, DAYOFMONTH(timestamp) AS day, HOUR(timestamp) AS hour, MINUTE(timestamp) AS minute FROM blog_comment WHERE entry = " . int($id) . " ORDER BY timestamp ASC";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	
	return $rv;
}
#= /get_comments

=head2 add_comment

Adds a new comment.

B<Parameters>:

=over

=item * $id     - The ID of the article where this comment belongs to.

=item * $userid - The user ID of the author, if registered.

=item * $author - The comment's author.

=item * $email  - Author's email address.

=item * $email_public  - Shall the email address be published?

=item * $email_notify  - Shall the comment's author's get a notification on new comments?

=item * $text   - The comment itself.

=back

=cut
sub add_comment {
	my ($self, $id, $userid, $author, $email, $email_public, $email_notify, $text) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	map { $_ = '' unless $_ } ($author, $email, $text);
	map { $_ = 0  unless $_ } ($email_public, $email_notify);
	map { $_ = $dbh->quote($_) } ($author, $email, $email_public, $email_notify, $text);
	
	#add comment
	my $query = "INSERT INTO blog_comment (entry, user, author, email, email_public, email_notify, text) VALUES ($id, $userid, $author, $email, $email_public, $email_notify, $text)";
	return $dbh->do($query);
}
#= /add_comment

=head2 delete_comment

Deletes an existing comment.

B<Parameters>:

=over

=item * $id - The id of the comment, which should be removed

=back

=cut
sub delete_comment {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("DELETE FROM blog_comment WHERE id = " . int($id));
}
#= /delete_comment


=head2 get_trackback

Returns the trackback with the specified id as an hash reference:
{ id => .., entry => .., url => .., title => .., excerpt => .., blog_name => ..,
  year => .., month => .., day => .., hour => .., minute => .. }

B<Parameters>:

=over

=item * $id - The trackback's id

=back

=cut
sub get_trackback {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT id, entry, url, title, excerpt, blog_name, YEAR(timestamp) AS year, MONTH(timestamp) AS month, DAYOFMONTH(timestamp) AS day, HOUR(timestamp) AS hour, MINUTE(timestamp) AS minute FROM blog_trackback WHERE id = " . int($id);
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	
	return (@{$rv} ? $rv->[0] : {});
}
#= /get_trackback


=head2 get_trackbacks

Returns the trackbacks of a specified blog entry as an array reference of hash references:
{ id => .., entry => .., url => .., title => .., excerpt => .., blog_name =>..,
  year => .., month => .., day => .., hour => .., minute => .. }

The entries should be ordered by ascending date (earliest post first).

B<Parameters>:

=over

=item * $id - The entry's id

=back

=cut
sub get_trackbacks {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT id, url, title, excerpt, blog_name, YEAR(timestamp) AS year, MONTH(timestamp) AS month, DAYOFMONTH(timestamp) AS day, HOUR(timestamp) AS hour, MINUTE(timestamp) AS minute FROM blog_trackback WHERE entry = $id ORDER BY timestamp ASC";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	
	return $rv;
}
#= /get_trackbacks


=head2 add_trackback

Adds a new trackback. Or replace it, if a trackback with that url already exists.

B<Parameters>:

=over

=item * $article - The ID of the article where this trackback belongs to.

=item * $url - The URL of the pinging article (required).

=item * $title - The title of the pinging article (optional). 

=item * $excerpt - An excerpt of the pinging article (optional).
 
=item * $blog_name - The name of the pinging blog (optional). 

=back

=cut
sub add_trackback {
	my ($self, $article, $url, $title, $excerpt, $blog_name) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	map { $_ = $dbh->quote($_) } ($article, $url, $title, $excerpt, $blog_name);
	
	#check if an entry with that url already exists
	my $query = "SELECT id FROM blog_trackback WHERE entry = $article AND url = $url";
	my $id = ($dbh->selectrow_array($query))[0]; 
	if ($id) {
		#entry exists! update.
		$query = "UPDATE blog_trackback SET title = $title, excerpt = $excerpt, blog_name = $blog_name WHERE id = $id";
	} else {
		#add trackback
		$query = "INSERT INTO blog_trackback (entry, url, title, excerpt, blog_name) VALUES ($article, $url, $title, $excerpt, $blog_name)";
	}
	
	return $dbh->do($query);
}
#= /add_trackback


=head2 delete_trackback

Deletes an existing trackback.

B<Parameters>:

=over

=item * $id - The id of the trackback entry, which should be removed

=back

=cut
sub delete_trackback {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("DELETE FROM blog_trackback WHERE id = " . int($id));
}
#= /delete_trackback

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::blog>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS blog_entry
(
  id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
	
  #entry
  title       VARCHAR(255)     NOT NULL,
  description TEXT             NOT NULL,
  content     TEXT             NOT NULL,
  formatted   TEXT             ,
  author      INT UNSIGNED     NOT NULL,
  private     TINYINT UNSIGNED NOT NULL,
  date        DATETIME         NOT NULL,
	
  PRIMARY KEY(id),
  INDEX(author), INDEX(date)
);

CREATE TABLE IF NOT EXISTS blog_comment
(
  id           INT UNSIGNED     NOT NULL AUTO_INCREMENT,
	
  #blog entry
  entry        INT UNSIGNED     NOT NULL,
  
  #comment
  text         TEXT             NOT NULL,
  user         INT UNSIGNED     NOT NULL,
  author       VARCHAR(64)      NOT NULL,
  email        VARCHAR(255)     NOT NULL,
  email_public TINYINT UNSIGNED ,
  email_notify TINYINT UNSIGNED ,
  timestamp    TIMESTAMP(14)    NOT NULL,
	
  PRIMARY KEY(id),
  INDEX(entry), INDEX(user), INDEX(timestamp)
);

CREATE TABLE IF NOT EXISTS blog_trackback
(
  id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
	
  #blog entry
  entry     INT UNSIGNED  NOT NULL,
  
  #trackback
  url       VARCHAR(255)  NOT NULL,
  title     VARCHAR(255)  ,
  excerpt   TEXT          ,
  blog_name VARCHAR(255)  ,
  timestamp TIMESTAMP(14) NOT NULL,
	
  PRIMARY KEY(id),
  INDEX(entry), UNIQUE(entry, url), INDEX(timestamp)
);
