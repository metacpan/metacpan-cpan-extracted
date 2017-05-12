#TODO: Synopsis
#TODO: Configuration doc

=head1 NAME

Konstrukt::Plugin::bookmarks::DBI - Konstrukt bookmarks DBI backend driver

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

Konstrukt bookmarks DBI backend driver.

=head1 CONFIGURATION

Note that you have to create the tables C<bookmarks_item> and C<bookmarks_category>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

You may define those settings to use this backend.

	#Backend
	bookmarks/backend/DBI/source       dbi:mysql:database:host
	bookmarks/backend/DBI/user         user
	bookmarks/backend/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

=cut

package Konstrukt::Plugin::bookmarks::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('bookmarks/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('bookmarks/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('bookmarks/backend/DBI/pass');
	$self->{db_settings} = [$db_source, $db_user, $db_pass];
	
	#set default settings
	$Konstrukt::Settings->default("bookmarks/root_title", "root");
	
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

Adds a new bookmark.

B<Parameters>:

=over

=item * $category - The category under which the bookmark should be added

=item * $url - The URL of this bookmark

=item * $title - The title of this bookmark

=item * $private - Is this entry only visible to the author?

=item * $author - The entry's author

=back

=cut
sub add_entry {
	my ($self, $category, $url, $title, $private, $author) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title = $dbh->quote($title || '');
	$url = $dbh->quote($url   || '');
	$private ||= 0;
	
	#insert bookmark
	my $query = "INSERT INTO bookmark_item (category, url, title, private, author, visits, last_visit) VALUES ($category, $url, $title, $private, $author, 0, NOW())";
	return $dbh->do($query);
}
#= /add_entry

=head2 get_entry

Returns the requested bookmark as an hash reference with the keys id, url, title,
category, private, visits, author, year, month, day, hour and minute.

B<Parameters>:

=over

=item * $id - The id of the entry

=back

=cut
sub get_entry {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT id, url, title, category, private, visits, author, YEAR(last_visit) AS year, MONTH(last_visit) AS month, DAYOFMONTH(last_visit) AS day, HOUR(last_visit) AS hour, MINUTE(last_visit) AS minute FROM bookmark_item WHERE id = $id";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	if (@{$rv}) {
		return $rv->[0];
	} else {
		return {};
	}
}
#= /get_entry

=head2 get_entries

Returns the requested category and its sub-categories and -bookmarks visible
to the specified author as an hash reference:
{
  id      => ..,
  title   => ..,
  author  => ..,
  private => ..,
  categories =>
    [
      { id => .. },
      { id => .. },
      ...
    ],
  bookmarks =>
    [
      { id => .., url => "..", title => "..", author => .., private => .., category => .., visits => .., year => .., month => .., ... },
      ...
    ]
}

B<Parameters>:

=over

=item * $category - The category whose entries should be returned. All entries
will be returned, when $category is 0 (root).

=item * $author   - The author who will read the entries. All private entries, whose
author not equals to the specified author won't be shown

=back

=cut
sub get_entries {
	my ($self, $id, $author) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my ($query, $rv);
	
	#get all items that are visible to the specified author
	$id     ||= 0;
	$author ||= 0;
	#special case: root category
	my $result;
	if ($id == 0) {
		$result = { is_root => 1, title => $Konstrukt::Settings->get('bookmarks/root_title'), private => 0, id => 0, author => -1 };
	} else {
		$query = "SELECT id, title, author, private FROM bookmark_category WHERE id = $id AND (author = $author OR private = 0)";
		$rv = $dbh->selectall_arrayref($query, { Columns=>{} });
		if (@{$rv}) {
			$result = $rv->[0];
		} else {
			return {};
		}
	}
	
	#get sub-categories
	#$query = "SELECT id, title, author, private, parent FROM bookmark_category WHERE parent = $id AND (author = $author OR private = 0) ORDER BY title ASC";
	$query = "SELECT id FROM bookmark_category WHERE parent = $id AND (author = $author OR private = 0) ORDER BY title ASC";
	$rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	$result->{categories} = $rv;
	
	#get sub-bookmarks
	$query = "SELECT id, url, title, category, private, visits, author, YEAR(last_visit) AS year, MONTH(last_visit) AS month, DAYOFMONTH(last_visit) AS day, HOUR(last_visit) AS hour, MINUTE(last_visit) AS minute FROM bookmark_item WHERE category = $id AND (author = $author OR private = 0) ORDER BY title ASC";
	$rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	$result->{bookmarks} = $rv;
	
	return $result;
}
#= /get_entries

=head2 update_entry

Updates an existing bookmark.

B<Parameters>:

=over

=item * $id - The id of the bookmark, which should be updated

=item * $url - The URL of this bookmark

=item * $title - The title of this bookmark

=item * $private - Is this entry only visible to me?

=item * $category - To which category does this entry belong?

=back

=cut
sub update_entry {
	my ($self, $id, $url, $title, $private, $category) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title     = $dbh->quote($title    || '');
	$url       = $dbh->quote($url      || '');
	$private ||= 0;
	$category ||= 0;
	
	#update bookmark
	my $query = "UPDATE bookmark_item SET url = $url, title = $title, private = $private, category = $category WHERE id = $id";
	return $dbh->do($query);
}
#= /update_entry

=head2 delete_entry

Removes an existing bookmark.

B<Parameters>:

=over

=item * $id - The id of the bookmark, which should be removed

=back

=cut
sub delete_entry {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("DELETE FROM bookmark_item WHERE id = $id");
}
#= /delete_entry

=head2 add_category

Adds a new category.

B<Parameters>:

=over

=item * $parent  - ID of the parent category

=item * $title   - The title of this category

=item * $author  - The category's author

=item * $private - Private flag

=back

=cut
sub add_category {
	my ($self, $parent, $title, $author, $private) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title = $dbh->quote($title || '');
	
	#add category
	my $query = "INSERT INTO bookmark_category (parent, title, author, private) VALUES ($parent, $title, $author, $private)";
	return$dbh->do($query);
}
#= /add_category

=head2 get_category

Returns the requested category as an hash reference:
{ id => .., title => .., author => .., private => .., parent => ..}

B<Parameters>:

=over

=item * $id - The id of the category

=back

=cut
sub get_category {
	my ($self, $id) = @_;
	
	return { is_root => 1, title => $Konstrukt::Settings->get('bookmarks/root_title'), private => 0, id => 0, author => -1 } if $id == 0;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT id, title, author, private, parent FROM bookmark_category WHERE id = $id";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	if (@{$rv}) {
		return $rv->[0];
	} else {
		return {};
	}
}
#= /get_category

=head2 update_category

Updates an existing category.

B<Parameters>:

=over

=item * $id - The id of the category, which should be updated

=item * $title - The new title

=item * $private - The new private flag

=item * $parent - To which parent category does this category belong?

=back

=cut
sub update_category {
	my ($self, $id, $title, $private, $parent) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title = $dbh->quote($title || '');
	
	#is this category private?
	my $was_private = $self->get_category($id)->{private};
	#prohibit a category to be set private, if it wasn't
	$private &= $was_private;
	
	#update category
	return $dbh->do("UPDATE bookmark_category SET title = $title, private = $private, parent = $parent WHERE id = $id");
}
#= /update_category

=head2 delete_category

Recursively deletes an existing category and all sub-categories and -items.

B<Parameters>:

=over

=item * $id - The id of the category, which should be removed

=back

=cut
sub delete_category {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#get sub-categories
	my $query = "SELECT id FROM bookmark_category WHERE parent = $id ORDER BY title ASC";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	foreach my $cat (@{$rv}) {
		$self->delete_category($cat->{id});
	}
	
	#delete category
	$dbh->do("DELETE FROM bookmark_category WHERE id = $id") or return;
	#delete entries
	$dbh->do("DELETE FROM bookmark_item WHERE category = $id") or return;
	
	return 1;
}
#= /delete_category

=head2 visit

Increates the visits counter and updates the last_visit timestamp for a specified bookmark.

B<Parameters>:

=over

=item * $id - The id of the bookmark, which will be visited

=back

=cut
sub visit {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("UPDATE bookmark_item SET visits = visits + 1, last_visit = NOW() WHERE id = $id");
}
#= /visit

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::bookmarks>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS bookmark_category
(
	id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
	
	#entry
	title       VARCHAR(255)     NOT NULL,
	parent      INT UNSIGNED     NOT NULL,
	author      INT UNSIGNED     NOT NULL,
	private     TINYINT UNSIGNED NOT NULL,
	
	PRIMARY KEY(id),
	INDEX(parent), INDEX(author), INDEX(private)
);

CREATE TABLE IF NOT EXISTS bookmark_item
(
	id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
	
	#entry
	url         VARCHAR(255)     NOT NULL,
	title       VARCHAR(255)     NOT NULL,
	category    INT UNSIGNED     NOT NULL,
	author      INT UNSIGNED     NOT NULL,
	private     TINYINT UNSIGNED NOT NULL,
	visits      INT UNSIGNED     NOT NULL,
	last_visit  DATETIME         NOT NULL,
	
	PRIMARY KEY(id),
	INDEX(category), INDEX(author), INDEX(private)
);