#FEATURE: rss export of a tag search string

=head1 NAME

Konstrukt::Plugin::tags - Tagging plugin

=head1 SYNOPSIS
	
=head2 Tag interface

B<Usage:>

	<!-- display all tags as a cloud -->
	<& tags template="/tags/cloud.template" limit="30" order="alpha|count" / &>
	
	<!-- display all tags for a specified plugin.
	     limit, order and template are also applicable here -->
	<& tags plugin="blog|image|..." / &>
	
	<!-- list tags for a specified entry only.
	     show, limit, order are ignored. the template attribute is applicable -->
	<& tags plugin="blog" entry="42" / &>

B<Result:>

	Tags: <a href="?action=filter;tags=bar">bar</a>,
	<a href="?action=filter;tags=foo">foo</a>, ...

=head2 Perl interface

	my $tags = use_plugin 'tags';
	
	#get all tags
	my $all_tags = $tags->get();
	
	#get all tags for a specified plugin
	my $all_blog_tags = $tags->get('blog');
	
	#get tags for a specified content entry (blog entry #42)
	my $all_entry_tags = $tags->get('blog', 42);
	
	#get all entries for a specified tag query
	my $entries = $tags->get_entries('must have all this tags');
	
	#get all blog entries matching the query
	my $entries = $tags->get_entries('must have all this tags', 'blog');
	
	#simple OR sets are also possible
	my $entries = $tags->get_entries('must have all this tags {and one of those}');
	
	#set tags
	$tags->set('blog', 42, 'some tags here');
	
	#delete all tags for a specified entry
	$tags->delete('blog', 42);

=head1 DESCRIPTION

This plugin offers easy content tagging and tag managements for other plugins.
You can add tagging to your plugin in an instant.

#TODO: devdoc

=head1 CONFIGURATION

You may do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Default:

	#backend
	tags/backend                  DBI

	#layout
	tags/template_path            /templates/tags/
	tags/default_style            cloud #may be "cloud" or "list"
	tags/default_order            count #may be "count" or "alpha"
	
	#user levels
	tags/userlevel_write          1 #TODO: needed or done by each plugin?
	
See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::tags::DBI/CONFIGURATION>) for their configuration.
	
=cut

package Konstrukt::Plugin::tags;

use strict;
use warnings;

use base 'Konstrukt::SimplePlugin';
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;

=head1 METHODS

=head2 init

Initializes this object. Sets $self->{backend} and $self->{template_path}.
init will be called by the constructor.

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("tags/backend"       => 'DBI');
	$Konstrukt::Settings->default("tags/template_path" => '/templates/tags/');
	$Konstrukt::Settings->default("tags/default_style" => 'cloud');
	$Konstrukt::Settings->default("tags/default_order" => 'alpha');
#	$Konstrukt::Settings->default("tags/userlevel_write",  1); #TODO: needed?
	
	$self->{backend}       = use_plugin "tags::" . $Konstrukt::Settings->get('tags/backend') or return undef;
	$self->{template_path} = $Konstrukt::Settings->get("tags/template_path");
	
	return 1;
}
#= /init

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 get

Returns the tags for the given criteria. You may optionally specify the plugin
and the identifier of a content entry to which the tags belong.

B<Parameters>:

=over

=item * $plugin - Optional: Only return tags of this plugin.

=item * $entry  - Optional: Only return tags of this entry (of the specified plugin).

=item * $order  - Optional: The order of the tags. May be "alpha" or "count".
Defaults to the Settings C<tags/default_order>. Doesn't apply, when only retrieving
the tags of a specified plugin and entry where the list will always be sorted
alphabetically.

=item * $limit  - Optional: Only return a specified number of the most popular tags.

=back

=head3 No plugin and no entry specified
If you don't specify the plugin and the entry, a list of all tags will be
returned as an array reference of hash references. The tag will be unique
in this list. Additionally a count for each tag will be returned:

	[
		{ title => 'tag title', count => 23 },
		{ title => 'foo',       count => 42 },
		...
	]

=head3 Only plugin specified

If you only specify the plugin, the same output as above will be returned.
But only the tags of the specified plugin will be returned (and counted).

=head3 Plugin and entry specified.

Will return a reference to an array containing only the tags for the specified
entry of the specified plugin:

	[
		'tag1',
		'tag2',
		...
	]

=cut
sub get {
	my ($self, $plugin, $entry, $order, $limit) = @_;
	return $self->{backend}->get($plugin, $entry, $order, $limit);
}
#= /get

=head2 get_entries

Returns the entries, that match a specified tag query string and optionally
belong to a specified plugin.

If a plugin is specified the identifier of entries will be returned in
an arrayref:

	[ 'someentry', 'someother', 23, 42, ... ]

Otherwise the entries will be returned as a reference to an array containing
hash references with the identifier and the plugin for each entry:

	[
		{ entry => 'someentry', plugin => 'someplugin' },
		...
	]

B<Parameters>:

=over

=item * $tagquery  - Tag query string. Multiple, space separated tags will be
AND-combined and parsed into an arrayref:

	sometag "some other tag" foo bar
	->
	["sometag", "some other tag", "foo", "bar"]

To get an OR-combination, put multiple tags into curly brackets, which will
be parsed in a nested array ref:

	sometag {one of these seven tags is enough} baz
	->
	["sometag", [qw/one of these seven tags is enough/], "baz"]

More complex (nested AND/OR-groups) are not supported.

=item * $plugin - Optional: Only return entries of this plugin.

=back

=cut
sub get_entries {
	my ($self, $tagquery, $plugin) = @_;
	
	#parse query string into an array containing AND combined tags and sets.
	#the tags are represented by scalars, the sets by arrayrefs containing scalars.
	my @tokens = map { defined $_ ? $_ : () } split(/(\s+|[\{\}"])/, $tagquery);
	my @query;
	my $set_opened;
	my $quotes_opened;
	foreach my $token (@tokens) {
		next if not length($token) or $token =~ /^\s+$/; #skip empty tokens
		if ($token eq '{') {
			#create new set
			push @query, [];
			$set_opened = 1;
		} elsif ($token eq '}') {
			#close set
			$set_opened = 0;
			#TODO: throw error here?
			#$Konstrukt::Debug->error_message("Invalid query string: Unopened group closed with '}'") if Konstrukt::Debug::ERROR;
			#	unless ref($query[@query - 1]) eq 'ARRAY');
		} elsif ($token eq '"') {
			$quotes_opened = not $quotes_opened;
			push @query, '' if $quotes_opened;
		} else {
			#text
			if ($set_opened) {
				#add to set
				if ($quotes_opened) {
					#append text
					$query[-1]->[-1] .= length($query[-1]->[-1]) ? " $token" : $token;
				} else {
					#add text
					push @{$query[-1]}, $token;
				}
			} else {
				#not in a set
				if ($quotes_opened) {
					#append text
					$query[-1] .= length($query[-1]) ? " $token" : $token;
				} else {
					#add text
					push @query, $token;
				}
			}
		}
	}
	
	#retrieve data from backend
	return $self->{backend}->get_entries(\@query, $plugin);
}
#= /get_entries

=head2 set

Sets the tags for a specified entry.

B<Parameters>:

=over

=item * $plugin - The plugin the entry belongs to

=item * $entry  - The identifier of the entry

=item * $tags   - String containing all tags which should be set.
The tags are space separated. You may put a tag, which contains whitespaces,
into quotes:

	sometag "some other tag" last_tag

=back

=cut
sub set {
	my ($self, $plugin, $entry, $tags) = @_;
	
	my @tags = $Konstrukt::Lib->quoted_string_to_word($tags);
	return $self->{backend}->set($plugin, $entry, @tags);
}
#= /set

=head2 delete

Deletes the tags for a specified entry or all tags for a specified plugin or
even all tags.

B<Parameters>:

=over

=item * $plugin - Optional: The plugin the entry belongs to

=item * $entry  - Optional: The identifier of the entry

=back

=cut
sub delete {
	my ($self, $plugin, $entry) = @_;
	return $self->{backend}->delete($plugin, $entry);
}
#= /delete

=head2 default :Action

Default (and only) action for this plugin. Will display a list of tags according
to the attributes set in the C<<& tags / &>> tag.

The attributes can be almost freely combined where it makes sense and some will
have a default value if not set.

For some examples take a look at the L<synopsis|/SYNOPSIS>.

B<Tag attributes>:

=over

=item * template - Optional: The path to the template to display the tags.
Defaults to "C<tags/template_path> C<tags/default_style> .template", which can
be adjusted in the L<settings|/CONFIGURATION>. You probably want to use your
own template depending on the place/purpose you want to list the tags.
The template must have a list definition with the name C<tags> and list fields
named C<title> and C<count> (with count being optional depending on which tags
should be listed). There will also be field values with the names C<min_count>
and C<max_count> which may help you to create tag clouds.

=item * limit - Optional: Max. number of tags to display. Defaults to 0 = no limit.

=item * order - Optional: Order of the tags. Either by their total count
(C<count>) or alphabetically (C<alpha>). Defaults to the setting C<tags/default_order>.

=item * plugin - Optional: Only show tags of the specified plugin. When not
specified all tags will be shown.

=item * entry - Optional: Only show tags of the specified entry (of a specified
plugin). Only works, when the C<plugin> attribute is also supplied. 

=back

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=item * $content - The content below/inside the tag as a flat string.

=item * $params - Reference to a hash of the passed CGI parameters.

=back

=cut
sub default :Action {
	my ($self, $tag, $content, $params) = @_;
	
	my $template = use_plugin 'template';
	
	my $templ  = $tag->{tag}->{attributes}->{template} || $Konstrukt::Settings->get('tags/template_path') . $Konstrukt::Settings->get('tags/default_style') . ".template";
	my $limit  = $tag->{tag}->{attributes}->{limit} || 0;
	my $order  = $tag->{tag}->{attributes}->{order} || $Konstrukt::Settings->get('tags/default_order');
	my $plugin = $tag->{tag}->{attributes}->{plugin};
	my $entry  = $tag->{tag}->{attributes}->{entry};
	
	#get tags
	my $tags = $self->get($plugin, $entry, $order, $limit);
	
	#determine min and max count unless displaying tags for one entry only
	my ($min_count, $max_count) = (0, 0);
	unless (defined $plugin and defined $entry) {
		$min_count = 1_000_000;
		foreach my $tag (@{$tags}) {
			$min_count = $tag->{count} if $tag->{count} < $min_count;
			$max_count = $tag->{count} if $tag->{count} > $max_count;
		}
	}
	
	#prepare data
	my $data = {
		fields => { min_count => $min_count, max_count => $max_count },
		lists => {
			tags => [
				(defined $plugin and defined $entry)
				#only show tags for that specific entry
				? map { { fields => { title => $Konstrukt::Lib->html_escape($_) } } } @{$tags}
				#show all tags and their count
				: map { { fields => { title => $Konstrukt::Lib->html_escape($_->{title}), count => $_->{count} } } } @{$tags}
			]
		}
	};
	
	#put out the template node
	$self->add_node($template->node($templ, $data));
}
#= /default

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::tags::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: cloud.template -- >8 --

<script type="text/javascript">
var tagbox = document.getElementById("tags");
function add_tag (tag) {
	if (tagbox.value.length > 0 && tagbox.value.substr(tagbox.value.length - 1, 1) != " ")
		tagbox.value += " ";
	if (tag.indexOf(" ") > 0)
		tag = '"' + tag + '"';
	tagbox.value += tag + " ";
	tagbox.focus();
}
</script>
<& perl &>
	#calculate font sizes for tag cloud
	my ($min_size, $max_size) = (10, 16);
	my ($min_count, $max_count) = ($template_values->{fields}->{min_count}, $template_values->{fields}->{max_count});
	my $size_diff = $max_size - $min_size;
	my $count_diff = ($max_count - $min_count);
	my @font_size;
	
	foreach my $count ($min_count .. $max_count) {
		$font_size[$count] = 
			$count_diff > 0
			? int($min_size + (($count - $min_count) / $count_diff) * $size_diff)
			: $min_size;
	}
	my @tags = @{$template_values->{lists}->{tags}};
	
	print join "\n", (map { "<span style=\"font-size: $font_size[$_->{fields}->{count}]pt;\"><a href=\"javascript:add_tag('" . $Konstrukt::Lib->uri_encode($_->{fields}->{title}) . "')\">$_->{fields}->{title}</a></span>" } @tags);
<& / &> 
