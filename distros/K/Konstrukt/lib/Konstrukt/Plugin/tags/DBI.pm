#TODO: remove tag_string code
#TODO: expand string length of plugin and entry to 255. MySQL complains that
#      a key can only have a max length of 500 bytes

=head1 NAME

Konstrukt::Plugin::tags::DBI - Tagging DBI backend

=head1 SYNOPSIS
	
	#TODO
	
=head1 DESCRIPTION

Tagging DBI Backend driver.

=head1 CONFIGURATION

Note that you have to create the table C<tag>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

You may define the source of this backend:

	#backend
	blog/backend/DBI/source       dbi:mysql:database:host
	blog/backend/DBI/user         user
	blog/backend/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

=head1 LIMITATIONS

The current data model has a max length for the tag title of 255 chars, for the
plugin name of 64 chars and for the entry identifier of 128 chars.
The identifier is a string, not a number (but of course can also contain numbers).

=cut

package Konstrukt::Plugin::tags::DBI;

use base 'Konstrukt::Plugin';

use strict;
use warnings;

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('tags/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('tags/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('tags/backend/DBI/pass');
	
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

=head2 set

Sets the tags for a specified entry.

B<Parameters>:

=over

=item * $plugin - The plugin the entry belongs to

=item * $entry  - The identifier of the entry

=item * @tags   - List of B<all> (not only new ones) tags for this entry.

=back

=cut
sub set {
	my ($self, $plugin, $entry, @tags) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#lowercase all tags
	@tags = map { lc } @tags;
	
	#quote plugin and entry
	my $pluginq = $dbh->quote($plugin);
	my $entryq  = $dbh->quote($entry);
	
	#update tags in the "tag" table
	#create an "index" over the old and new tags
	my @old = @{$self->get($plugin, $entry)};
	my @new = @tags;
	my %old = map { $_ => 1 } @old;
	my %new = map { $_ => 1 } @new;
	#determine tags that have been deleted (i.e. all tags that were in the old list but aren't in the new one)
	my @deleted = map { exists $new{$_} ? () : $_ } @old;
	#determine tags that have been added (i.e. all tags that are in the new list but weren't in the old one)
	my @created = map { exists $old{$_} ? () : $_ } @new;
	#delete removed tags
	if (@deleted) {
		my $query = "DELETE FROM tag WHERE plugin = $pluginq AND entry = $entryq AND title IN (" . join(", ", map { $dbh->quote($_) } @deleted) . ")";
		$dbh->do($query) or return;
	}
	#insert added tags
	if (@created) {
		my $query = "INSERT INTO tag (title, plugin, entry) VALUES " .
			(join ", ", map { "(" . $dbh->quote($_) . ", $pluginq, $entryq)" } @created);
		$dbh->do($query) or return;
	}
	
	#update tags in the "tag_string" table
	#if (@deleted or @created) {
	#	my $tags = $dbh->quote('"' . join('"', @tags) . '"');
	#	$dbh->do("REPLACE tag_string (tags, plugin, entry) VALUES ($tags, $pluginq, $entryq)") or return;
	#}
	
	return 1;
}
#= /set

=head2 get

Implementation of the L<get method|Konstrukt::Plugin::tags/get> of the plugin.

=cut
sub get {
	my ($self, $plugin, $entry, $order, $limit) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $rv;
	$order ||= 'alpha';
	$limit += 0;
	#aggregate over multiple plugins/entries?
	if (defined $plugin and defined $entry) {
		my $query = "SELECT title FROM tag WHERE plugin = " . $dbh->quote($plugin) . " AND entry = " . $dbh->quote($entry) . " ORDER BY title ASC" . ($limit > 0 ? " LIMIT $limit" : "");
		$rv = $dbh->selectcol_arrayref($query);
	} else {
		#build query
		my $query = "SELECT title, COUNT(title) AS count FROM tag ";
		my $where = '';
		if (defined $plugin) {
			$where .= "WHERE plugin = " . $dbh->quote($plugin);
			$where .= " AND entry = " . $dbh->quote($entry) if defined $entry;
			$where .= " ";
		}
		#the results will _always_ be ordered by count to allow getting the N most popular tags
		#the results will then be optionally sorted by name
		$query .= $where . "GROUP BY title ORDER BY count DESC, title ASC" .
			($limit > 0 ? " LIMIT $limit" : "");
		$rv = $dbh->selectall_arrayref($query, { Columns=>{} }) || [];
		#optionally order by name
		if ($order eq 'alpha') {
			$rv = [ sort { $a->{title} cmp $b->{title} } @{$rv} ];
		}
	}
	
	return $rv;
}
#= /get

=head2 get_entries

Returns the entries, that match a specified tag query string and optionally
belong to a specified plugin.

If a plugin is specified the identifiers (strings or numbers) of the entries
will be returned in an arrayref:

	[ 'someentry', 'someother', 23, 42, ... ]

Otherwise the entries will be returned as a reference to an array containing
hash references with the identifier and the plugin for each entry:

	[
		{ entry => 'someentry', plugin => 'someplugin' },
		...
	]

B<Parameters>:

=over

=item * $tagquery  - Reference to an array containing the tags that each entry must
have to match.

	["sometag", "some other tag", "foo", "bar"]
	->
	WHERE title = "sometag" AND title = "some other tag" AND title = "foo" AND title = "bar"

There may also be additional arrayref entries inside the list
which represent an OR-combined set of tags.

	["sometag", [qw/one of these seven tags is enough/], "baz"]
	->
	WHERE title = "sometag" AND title IN ("one", "of", "these", "seven", "tags", "is", "enough") AND title = "baz"

=item * $plugin - Optional: Only return entries of this plugin.

=back

=cut
sub get_entries {
	my ($self, $tagquery, $plugin) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my @query = @{$tagquery};

#	#variant 1 with tag_string
#	my $rv_a;
#	if (@query) {
#		my $query = defined $plugin
#			? "SELECT entry FROM tag_string WHERE plugin = " . $dbh->quote($plugin) . " AND "
#			: "SELECT plugin, entry FROM tag_string WHERE ";
#		$query .= join " AND ",
#			map {
#				ref $_ eq 'ARRAY'
#				? "(" . join(" OR ", map { "tags LIKE " . $dbh->quote("%\"$_\"%") } @{$_}) . ")"
#				: "tags LIKE " . $dbh->quote("%\"$_\"%")
#			} @query;
#		$query .= defined $plugin
#			? " ORDER BY entry ASC"
#			: " ORDER BY plugin ASC, entry ASC";
#		my $rv = defined $plugin
#			? $dbh->selectcol_arrayref($query)
#			: $dbh->selectall_arrayref($query, { Columns=>{} });
#		$rv_a =  $rv;
#	} else {
#		#no (valid) query
#		#TODO: throw error?
#		return [];
#	}
	
	#variant 2 with tag
	my $rv_b;
	if (@query) {
		#first step: select all entries that match the AND-combined tags and
		#save them in a temporary table.
		#we're doing this by selecting all tags that match the needed tags
		#and count if a an entry has all tags.
		$dbh->do("DROP TABLE IF EXISTS tag_temp0") or return;
		
		my $query = "CREATE TEMPORARY TABLE tag_temp0 ";
		$query .= defined $plugin
			? "SELECT entry FROM tag WHERE plugin = " . $dbh->quote($plugin) . " AND "
			: "SELECT plugin, entry FROM tag WHERE ";
		#extract AND-combined tags and groups of OR-combined tags
		my (@ands, @ors);
		foreach my $entry (@query) {
			if (ref $entry eq 'ARRAY') {
				push @ors, $entry;
			} else {
				push @ands, $entry;
			}
		}
		$query .= join " OR ", (map { "title = " . $dbh->quote($_) } @ands);
		$query .= " GROUP BY " . (defined $plugin ? "entry" : "plugin, entry") . " HAVING COUNT(entry) = " . scalar(@ands);
		$dbh->do($query) or return;
		
		#second step: for each or-group narrow the selected entries down by
		#selecting only those that already have been selected and additionally
		#match the OR-combined tags
		my $from_table = 0;
		my $to_table   = 1;
		foreach my $group (@ors) {
			#again use temporary tables to save the entries
			$dbh->do("DROP TABLE IF EXISTS tag_temp$to_table") or return;
			
			$query = "CREATE TEMPORARY TABLE tag_temp$to_table ";
			$query .= defined $plugin
				? "SELECT DISTINCT tag.entry FROM tag, tag_temp$from_table WHERE tag.entry = tag_temp$from_table.entry "
				: "SELECT DISTINCT tag.plugin, tag.entry FROM tag, tag_temp$from_table WHERE tag.plugin = tag_temp$from_table.plugin AND tag.entry = tag_temp$from_table.entry ";
			$query .= "AND title IN (" . join(", ", map { $dbh->quote($_) } @{$group}) . ")";
			$dbh->do($query) or return;
			
			#swap temp tables
			($from_table, $to_table) = ($to_table, $from_table);
		}
		#retrieve the results from the last created table
		$query = "SELECT * FROM tag_temp$from_table";
		$query .= defined $plugin
			? " ORDER BY entry ASC"
			: " ORDER BY plugin ASC, entry ASC";
		my $rv = defined $plugin
			? $dbh->selectcol_arrayref($query)
			: $dbh->selectall_arrayref($query, { Columns=>{} });
		$rv_b =  $rv;
	} else {
		#no (valid) query
		#TODO: throw error?
		return [];
	}
	
#	#is the result of both variants identical?
#	use Data::Compare;
#	use Data::Dump 'dump';
#	unless (Compare($rv_a, $rv_b)) {
#		$Konstrukt::Debug->error_message("Varianten liefern nicht das gleiche!'\ntag_string:\n" . dump($rv_a) . "\ntag:\n" . dump($rv_b)) if Konstrukt::Debug::ERROR;
#	}
	
	return $rv_b;
}
#= /get_entries

=head2 delete

Implementation of L<Konstrukt::Plugin::tags/delete>.

=cut
sub delete {
	my ($self, $plugin, $entry) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#delete tags
	my $where = join " AND ", (map { defined $_->[0] ? "$_->[1] = " . $dbh->quote($_->[0]) : () } ([$plugin, 'plugin'], [$entry, 'entry']));
	#delete from tag
	$dbh->do("DELETE FROM tag" . ($where ? " WHERE $where" : "")) or return;
	#delete from tag_string
	#$dbh->do("DELETE FROM tag_string" . ($where ? " WHERE $where" : "")) or return;
	
	return 1;
}
#= /delete

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

CREATE TABLE IF NOT EXISTS tag
(
	title     VARCHAR(192)  NOT NULL,
	plugin    VARCHAR(32)   NOT NULL,
	entry     VARCHAR(255)  NOT NULL,
	
	PRIMARY KEY(title, plugin, entry),
	INDEX(title),
	INDEX(plugin),
	INDEX(entry)
);

#CREATE TABLE IF NOT EXISTS tag_string
#(
#	tags      TEXT          NOT NULL,
#	plugin    VARCHAR(32)   NOT NULL,
#	entry     VARCHAR(255)  NOT NULL,
#	
#	PRIMARY KEY(plugin, entry),
##	INDEX(tags),
#	INDEX(plugin),
#	INDEX(entry)
#);