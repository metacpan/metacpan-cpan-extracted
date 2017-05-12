=head1 NAME

Konstrukt::Plugin::wiki::backend::article::DBI - Article backend driver for storage
inside a database that can be accessed through DBI.

=head1 SYNOPSIS
	
	my $article_backend = use_plugin 'Konstrukt::Plugin::wiki::backend::article::DBI' or die;
	$article_backend->do_stuff(); #see the methods description
	
=head1 DESCRIPTION

This article backend implements the storage in a database that will be accessed
through perl DBI.

Actually this one was implemented using a MySQL database. But as the queries
don't use special MySQL-functions it is very likely that it will run on other
databases without modification.

=head1 CONFIGURATION

You have to create the table C<wiki_article>, which will be used to store the
data.
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

package Konstrukt::Plugin::wiki::backend::article::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin::wiki::backend::article';

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

This method will return true, if a specified article exists. It will return
undef otherwise.

B<Parameters>:

=over

=item * $title - The title of the article

=item * $revision - Optional: A specific revision of an article

=back

=cut
sub exists {
	my ($self, $title, $revision) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$title    = $dbh->quote($self->normalize_link($title));
	$revision = $dbh->quote($revision) if defined $revision;
	
	#query
	my $query = "SELECT 1 FROM wiki_article WHERE title = $title" . (defined $revision ? " AND revision = $revision" : "");
	return ($dbh->selectrow_array($query)) ? 1 : undef;
}
#= /exists

=head2 revision

This method will return the latest revision number/number of revisions of a
specified article. It will return undef if the specified article does not
exist.

B<Parameters>:

=over

=item * $title - The title of the article

=back

=cut
sub revision {
	my ($self, $title) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#query
	my $query = "SELECT MAX(revision) AS revision FROM wiki_article WHERE title = " . $dbh->quote($self->normalize_link($title)) . " LIMIT 1";
	my $result = $dbh->selectall_arrayref($query, { Columns=>{} });
	return @{$result} ? $result->[0]->{revision} : undef;
}
#= /revision

=head2 revisions

This method will return all revisions of the specified article as an array of
hash references ordered by ascending revision numbers:

	[
		{ revision => 1, author => 'foo', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },
		{ revision => 2, ...},
		...
	]
	
Will return undef, if the file doesn't exist.

B<Parameters>:

=over

=item * $title - The title of the article

=back

=cut
sub revisions {
	my ($self, $title) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#query
	my $query = "SELECT revision, author, host, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(date) AS hour, MINUTE(date) AS minute FROM wiki_article WHERE title = " . $dbh->quote($self->normalize_link($title)) . " ORDER BY revision ASC";
	my $result = $dbh->selectall_arrayref($query, { Columns=>{} });
	return @{$result} ? $result : undef;
}
#= /revisions

=head2 get

This method will return the article as a hashref:

		{ revision => 1, content => '= wiki stuff', author => 'foo', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },


Will return undef, if the requested article doesn't exist.

B<Parameters>:

=over

=item * $title - The title of the article

=item * $revision - Optional: A specific revision of an article. When not
specified, the latest revision will be returned.

=back

=cut
sub get {
	my ($self, $title, $revision) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#query
	$title = $dbh->quote($self->normalize_link($title));
	my $query;
	if (defined $revision) {
		$revision = $dbh->quote($revision) if defined $revision;
		$query = "SELECT revision, content, author, host, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(date) AS hour, MINUTE(date) AS minute FROM wiki_article WHERE title = $title AND revision = $revision";	
	} else {
		$query = "SELECT revision, content, author, host, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(date) AS hour, MINUTE(date) AS minute FROM wiki_article WHERE title = $title ORDER BY revision DESC LIMIT 1";
	}
	my $result = $dbh->selectall_arrayref($query, { Columns=>{} });
	return @{$result} ? $result->[0] : undef;
}
#= /get

=head2 store

This method will add a new article (or new revision if the article already
exists) to the store.

Will return true on success and undef otherwise.

B<Parameters>:

=over

=item * $title - The title of the article

=item * $content - The content that should be stored

=item * $author - User id of the creator

=item * $host - Internet address of the creator

=back

=cut
sub store {
	my ($self, $title, $content, $author, $host) = @_;
	
	#get connection
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#new content?
	my $current = $self->get($title);
	if (not defined $current->{content} or $current->{content} ne $content) {
		#what's the current revision of this article?
		my $revision = $self->revision($title);
		$revision = defined $revision ? $revision + 1 : 1;
		
		#quoting
		($title, $content, $author, $host) = map { $dbh->quote($_ || '') } ($self->normalize_link($title), $content, $author, $host);
		
		#query
		my $query = "INSERT INTO wiki_article(title, content, revision, author, date, host) values ($title, $content, $revision, $author, NOW(), $host);";	
		return $dbh->do($query);
	} else {
		#same content. no update.
		return -1;
	}
}
#= /store

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

CREATE TABLE IF NOT EXISTS wiki_article
(
	title       VARCHAR(255)  NOT NULL,
	content     TEXT          NOT NULL,
	
	revision    INT UNSIGNED  NOT NULL,
	author      INT UNSIGNED  NOT NULL,
	date        DATETIME      NOT NULL,
	host        VARCHAR(15)   ,
	
	PRIMARY KEY(title, revision)
);