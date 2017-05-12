package HTML::LinkList;
$HTML::LinkList::VERSION = '0.1701';
use strict;
use warnings;

=head1 NAME

HTML::LinkList - Create a 'smart' list of HTML links.

=head1 VERSION

version 0.1701

=head1 SYNOPSIS

    use HTML::LinkList qw(link_list);

    # default formatting
    my $html_links = link_list(current_url=>$url,
			       urls=>\@links_in_order,
			       labels=>\%labels,
			       descriptions=>\%desc);

    # paragraph with ' :: ' separators
    my $html_links = link_list(current_url=>$url,
	urls=>\@links_in_order,
	labels=>\%labels,
	descriptions=>\%desc,
	links_head=>'<p>',
	links_foot=>'</p>',
	pre_item=>'',
	post_item=>''
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	item_sep=>" :: ");

    # multi-level list
    my $html_links = link_tree(
	current_url=>$url,
	link_tree=>\@list_of_lists,
	labels=>\%labels,
	descriptions=>\%desc);


=head1 DESCRIPTION

This module contains a number of functions for taking sets of URLs and
labels and creating suitably formatted HTML.  These links are "smart"
because, if given the url of the current page, if any of the links in
the list equal it, that item in the list will be formatted as a special
label, not as a link; this is a Good Thing, since the user would be
confused by clicking on a link back to the current page.

While many website systems have plugins for "smart" navbars, they are
specialized for that system only, and can't be reused elsewhere, forcing
people to reinvent the wheel. I hereby present one wheel, free to be
reused by anybody; just the simple functions, a backend, which can be
plugged into whatever system you want.

The default format for the HTML is to make an unordered list, but there
are many options, enabling one to have a flatter layout with any
separators you desire, or a more complicated list with differing
formats for different levels.

The "link_list" function uses a simple list of links -- good for a
simple navbar.

The "link_tree" function takes a set of nested links and makes the HTML
for them -- good for making a table of contents, or a more complicated
navbar.

The "full_tree" function takes a list of paths and makes a full tree of
all the pages and index-pages in those paths -- good for making a site
map.

The "breadcrumb_trail" function takes a url and makes a "breadcrumb trail"
from it.

The "nav_tree" function creates a set of nested links to be
used as a multi-level navbar; one can give it a list of paths
(as for full_tree) and it will only show the links related
to the current URL.

=cut

=head1 FUNCTIONS

To export a function, add it to the 'use' call.

    use HTML::LinkList qw(link_list);

To export all functions do:

    use HTML::LinkList ':all';

=cut

use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter);


# Items which are exportable.
#
# This allows declaration	use HTML::LinkList ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	link_list
	link_tree
	full_tree
	breadcrumb_trail
	nav_tree
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT = qw(
	
);

=head2 link_list

    $links = link_list(
	current_url=>$url,
	urls=>\@links_in_order,
	labels=>\%labels,
	descriptions=>\%desc,
	pre_desc=>' ',
	post_desc=>'',
	links_head=>'<ul>',
	links_foot=>'</ul>',
	pre_item=>'<li>',
	post_item=>'</li>'
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	item_sep=>"\n");

Generates a simple list of links, from list of urls
(and optional labels) taking into account of the "current" URL.

This provides a large number of options to customize the appearance
of the list.  The default setup is for a simple UL list, but setting
the options can enable you to make it something other than a list
altogether, or add in CSS styles or classes to make it look just
like you want.

Required:

=over

=item urls

The urls in the order you want them displayed.  If this list
is empty, then nothing will be generated.

=back

Options:

=over

=item current_url

The link to the current page.  If one of the links equals this,
then that is deemed to be the "active" link and is just displayed
as a label rather than a link.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the urls.

=item hide_ext

If a site is hiding link extensions (such as using MultiViews with
Apache) you may wish to hide the extensions (while using the full URLs
to check various things). (default: 0 (false))

=item item_sep

String to put between items.

=item labels

A hash whose keys are links and whose values are labels.
These are the labels for the links; if no label
is given, then the last part of the link is used
for the label, with some formatting.

=item links_head

String to begin the list with.

=item links_foot

String to end the list with.

=item pre_desc

String to prepend to each description.

=item post_desc

String to append to each description.

=item pre_item

String to prepend to each item.

=item post_item

String to append to each item.

=item pre_active_item

An additional string to put in front of each "active" item, after pre_item.
The "active" item is the link which matches 'current_url'.

=item pre_item_active

INSTEAD of the "pre_item" string, use this string for active items

=item post_active_item

An additional string to append to each active item, before post_item.

=item prefix_url

A prefix to prepend to all the links. (default: empty string)

=back

=cut
sub link_list {
    my %args = (
		current_url=>'',
		prefix_url=>'',
		labels=>undef,
		urls=>undef,
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		hide_ext=>0,
		@_
	       );

    my @link_order = @{$args{urls}};
    if (!defined $args{urls}
	or !@{$args{urls}})
    {
	return '';
    }
    my %format = (exists $args{format}
	? %{$args{format}}
	: make_default_format(%args));
    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my %current_parents = extract_current_parents(%args);
    my @items = ();
    foreach my $link (@link_order)
    {
	my $label = (exists $args{labels}->{$link}
	    ? $args{labels}->{$link} : '');
	my $item = make_item(%args,
	    format=>\%format,
	    current_parents=>\%current_parents,
	    this_link=>$link,
	    this_label=>$label);
	push @items, $item;
    }
    my $list = join($format{item_sep}, @items);
    return ($list
	? join('', $args{links_head}, $list, $args{links_foot})
	: '');
} # link_list

=head2 link_tree

    $links = link_tree(
	current_url=>$url,
	link_tree=>\@list_of_lists,
	labels=>\%labels,
	descriptions=>\%desc,
	pre_desc=>' ',
	post_desc=>'',
	links_head=>'<ul>',
	links_foot=>'</ul>',
	subtree_head=>'<ul>',
	subtree_foot=>'</ul>',
	pre_item=>'<li>',
	post_item=>'</li>'
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	item_sep=>"\n",
	tree_sep=>"\n",
	formats=>\%formats);

Generates nested lists of links from a list of lists of links.
This is useful for things such as table-of-contents or
site maps.

By default, this will return UL lists, but this is highly
configurable.

Required:

=over

=item link_tree

A list of lists of urls, in the order you want them displayed.
If a url is not in this list, it will not be displayed.

=back

Options:

=over

=item current_url

The link to the current page.  If one of the links equals this,
then that is deemed to be the "active" link and is just displayed
as a label rather than a link.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the urls.

=item exclude_root_parent

If this is true, then the "current_parent" display options are
not used for the "root" ("/") path, it isn't counted as a "parent"
of the current_url.

=item formats

A reference to a hash containing advanced format settings. For example:

    my %formats = (
	       # level 1 and onwards
	       '1' => {
	       tree_head=>"<ol>",
	       tree_foot=>"</ol>\n",
	       },
	       # level 2 and onwards
	       '2' => {
	       tree_head=>"<ul>",
	       tree_foot=>"</ul>\n",
	       },
	       # level 3 and onwards
	       '3' => {
	       pre_item=>'(',
	       post_item=>')',
	       item_sep=>",\n",
	       tree_sep=>' -> ',
	       tree_head=>"<br/>\n",
	       tree_foot=>"",
	       }
	      );

The formats hash enables you to control the formatting on a per-level basis.
Each key of the hash corresponds to a level-number; the sub-hashes contain
format arguments which will apply from that level onwards.  If an argument
isn't given in the sub-hash, then it will fall back to the previous level
(or to the default, if there is no setting for that format-argument
for a previous level).

The only difference between the names of the arguments in the sub-hash and
in the global format arguments is that instead of 'subtree_head' and subtree_foot'
it uses 'tree_head' and 'tree_foot'.

=item hide_ext

If a site is hiding link extensions (such as using MultiViews with
Apache) you may wish to hide the extensions (while using the full URLs
to check various things). (default: 0 (false))

=item item_sep

The string to separate each item.

=item labels

A hash whose keys are links and whose values are labels.
These are the labels for the links; if no label
is given, then the last part of the link is used
for the label, with some formatting.

=item links_head

The string to prepend the top-level tree with.
(default: <ul>)

=item links_foot

The string to append to the top-level tree.
(default: </ul>)

=item pre_desc

String to prepend to each description.

=item post_desc

String to append to each description.

=item pre_item

String to prepend to each item.
(default: <li>)

=item post_item

String to append to each item.
(default: </li>)

=item pre_active_item

An additional string to put in front of each "active" item, after pre_item.
The "active" item is the link which matches 'current_url'.
(default: <em>)

=item pre_item_active

INSTEAD of the "pre_item" string, use this string for active items

=item post_active_item

An additional string to append to each active item, before post_item.
(default: </em>)

=item pre_current_parent

An additional string to put in front of a link which is a parent
of the 'current_url' link, after pre_item.

=item pre_item_current_parent

INSTEAD of the "pre_item" string, use this for links which are parents
of the 'current_url' link.

=item post_current_parent

An additional string to append to a link which is a parent
of the 'current_url' link, before post_item.

=item prefix_url

A prefix to prepend to all the links. (default: empty string)

=item subtree_head

The string to prepend to lower-level trees.
(default: <ul>)

=item subtree_foot

The string to append to lower-level trees.
(default: </ul>)

=item tree_sep

The string to separate each tree.

=back

=cut
sub link_tree {
    my %args = (
		current_url=>'',
		prefix_url=>'',
		link_tree=>undef,
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my %current_parents = extract_current_parents(%args);

    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    if (defined $args{link_tree}
	and @{$args{link_tree}})
    {
	my %default_format = make_default_format(%args);
	my %formats = make_extra_formats(%args);
	my @link_tree = @{$args{link_tree}};
	my $list = traverse_lol(\@link_tree,
				%args,
				formats=>\%formats,
				current_format=>\%default_format,
				current_parents=>\%current_parents);
	return $list if $list;
    }
    return '';
} # link_tree

=head2 full_tree

    $links = full_tree(
	paths=>\@list_of_paths,
	labels=>\%labels,
	descriptions=>\%desc,
	hide=>$hide_regex,
	nohide=>$nohide_regex,
	start_depth=>0,
	end_depth=>0,
	top_level=>0,
	preserve_order=>0,
	preserve_paths=>0,
	...
	);

Given a set of paths this will generate a tree of links in the style of
I<link_tree>.   This will figure out all the intermediate paths and construct
the nested structure for you, clustering parents and children together.

The formatting options are as for L</link_tree>.

Required:

=over

=item paths

A reference to a list of paths: that is, URLs relative to the top
of the site.

For example, if the full URL is http://www.example.com/foo.html
then the path is /foo.html

If the full URL is http://www.example.com/~frednurk/foo.html
then the path is /foo.html

This does not require that every possible path be given; all the intermediate
paths will be figured out from the list.

=back

Options:

=over

=item append_list

Array of paths to append to the top-level links.  They are used
as-is, and are not part of the processing done to the "paths" list
of paths. (see L</prepend_list>)

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the paths.

=item end_depth

End your tree at this depth.  If zero, then go all the way.
(see L</start_depth>)

=item exclude_root_parent

If this is true, then the "current_parent" display options are
not used for the "root" ("/") path, it isn't counted as a "parent"
of the current_url.

=item hide

If the path matches this string, don't include it in the tree.

=item hide_ext

If a site is hiding link extensions (such as using MultiViews with
Apache) you may wish to hide the extensions (while using the full URLs
to check various things). (default: 0 (false))

=item labels

Hash containing replacement labels for one or more paths.
If no label is given for '/' (the root path) then 'Home' will
be used.

=item last_subtree_head

The string to prepend to the last lower-level tree.
Only used if end_depth is not zero.

=item last_subtree_foot

The string to append to the last lower-level tree.
Only used if end_depth is not zero.

=item nohide

If the path matches this string, it will be included even if it matches
the 'hide' string.

=item prefix_url

A prefix to prepend to all the links. (default: empty string)

=item prepend_list

Array of paths to prepend to the top-level links.  They are used
as-is, and are not part of the processing done to the "paths" list
of paths.

=item preserve_order

Preserve the ordering of the paths in the input list of paths;
otherwise the links will be sorted alphabetically.  Note that if
preserve_order is true, the structure is at the whims of the order
of the original list of paths, and so could end up odd-looking.
(default: false)

=item preserve_paths

Do not extract intermediate paths or reorder the input list of paths.
This speeds things up, but assumes that the input paths are complete
and in good order.
(default: false)

=item start_depth

Start your tree at this depth.  Zero is the root, level 1 is the
files/sub-folders in the root, and so on.
(default: 0)

=item top_level

Decide which level is the "top" level.  Useful when you
set the start_depth to something greater than 1.

=back

=cut
sub full_tree {
    my %args = (
		paths=>undef,
		current_url=>'',
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		hide=>'',
		nohide=>'',
		preserve_order=>0,
		preserve_paths=>0,
		labels=>{},
		start_depth=>0,
		end_depth=>0,
		top_level=>0,
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my %current_parents = extract_current_parents(%args);

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }
    my @path_list = ();
    if ($args{preserve_paths})
    {
	@path_list = filter_out_paths(%args, paths=>$args{paths});
    }
    else
    {
	@path_list = extract_all_paths(paths=>$args{paths},
				       preserve_order=>$args{preserve_order});
	@path_list = filter_out_paths(%args, paths=>\@path_list);
    }
    my @list_of_lists = build_lol(%args, paths=>\@path_list,
				  depth=>0);
    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    my %default_format = make_default_format(%args);
    my %formats = make_extra_formats(%args);
    my $list = traverse_lol(\@list_of_lists,
			    %args,
			    formats=>\%formats,
			    current_format=>\%default_format,
			    current_parents=>\%current_parents);
    return $list if $list;

    return '';
} # full_tree

=head2 breadcrumb_trail

    $links = breadcrumb_trail(
		current_url=>$url,
		labels=>\%labels,
		descriptions=>\%desc,
		links_head=>'<p>',
		links_foot=>"\n</p>",
		subtree_head=>'',
		subtree_foot=>"\n",
		pre_item=>'',
		post_item=>'',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		item_sep=>"\n",
		tree_sep=>' &gt; ',
	...
	);

Given the current url, make a breadcrumb trail from it.
By default, this is laid out with '>' separators, but it can
be set up to give a nested set of UL lists (as for L</full_tree>).

The formatting options are as for L</link_tree>.

Required:

=over

=item current_url

The current url to be made into a breadcrumb-trail.

=back

Options:

=over

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the urls.

=item exclude_root_parent

If this is true, then the "current_parent" display options are
not used for the "root" ("/") path, it isn't counted as a "parent"
of the current_url.

=item hide_ext

If a site is hiding link extensions (such as using MultiViews with
Apache) you may wish to hide the extensions (while using the full URLs
to check various things). (default: 0 (false))

=item labels

Hash containing replacement labels for one or more URLS.
If no label is given for '/' (the root path) then 'Home' will
be used.

=back

=cut
sub breadcrumb_trail {
    my %args = (
		current_url=>'',
		links_head=>'<p>',
		links_foot=>"\n</p>",
		subtree_head=>'',
		subtree_foot=>'',
		last_subtree_head=>'{',
		last_subtree_foot=>'}',
		pre_item=>'',
		post_item=>'',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>' &gt; ',
		hide=>'',
		nohide=>'',
		labels=>{},
		paths=>[],
		start_depth=>0,
		end_depth=>undef,
		top_level=>0,
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }

    # make a list of paths consisting only of the current_url
    my @paths = ($args{current_url});
    my @path_list = extract_all_paths(paths=>\@paths);
    @path_list = filter_out_paths(%args, paths=>\@path_list);
    my @list_of_lists = build_lol(%args, paths=>\@path_list,
				  depth=>0);
    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    my %default_format = make_default_format(%args);
    my %formats = make_extra_formats(%args);
    my $list = traverse_lol(\@list_of_lists,
			    %args,
			    formats=>\%formats,
			    current_format=>\%default_format,
			    );
    return $list if $list;

    return '';
} # breadcrumb_trail

=head2 nav_tree

    $links = nav_tree(
	paths=>\@list_of_paths,
	labels=>\%labels,
	current_url=>$url,
	hide=>$hide_regex,
	nohide=>$nohide_regex,
	preserve_order=>1,
	descriptions=>\%desc,
	...
	);

This takes a list of links, and the current URL, and makes a nested navigation
tree, consisting of (a) the top-level links (b) the links leading to the
current URL (c) the links on the same level as the current URL,
(d) the related links just above this level, depending on whether
this is an index-page or a content page.

Optionally one can hide links which match match the 'hide' option.

The formatting options are as for L</link_tree>, with some additions.

Required:

=over

=item current_url

The link to the current page.  If one of the links equals this, then that
is deemed to be the "active" link and is just displayed as a label rather
than a link.  This is also used to determine which links to show and which
ones to filter out.

=item paths

A reference to a list of paths: that is, URLs relative to the top
of the site.

For example, if the full URL is http://www.example.com/foo.html
then the path is /foo.html

This does not require that every possible path be given; all the intermediate
paths will be figured out from the list.

=back

Options:

=over

=item append_list

Array of paths to append to the top-level links.  They are used
as-is, and are not part of the processing done to the "paths" list
of paths. (see L</prepend_list>)

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the paths.

=item end_depth

End your tree at this depth.  If zero, then go all the way.
By default this is set to the depth of the current_url.

=item exclude_root_parent

If this is true, then the "current_parent" display options are
not used for the "root" ("/") path, it isn't counted as a "parent"
of the current_url.

=item hide

If a path matches this string, don't include it in the tree.

=item hide_ext

If a site is hiding link extensions (such as using MultiViews with
Apache) you may wish to hide the extensions (while using the full URLs
to check various things). (default: 0 (false))

=item labels

Hash containing replacement labels for one or more paths.
If no label is given for '/' (the root path) then 'Home' will
be used.

=item last_subtree_head

The string to prepend to the last lower-level tree.

=item last_subtree_foot

The string to append to the last lower-level tree.

=item nohide

If the path matches this string, it will be included even if it matches
the 'hide' string.

=item prefix_url

A prefix to prepend to all the links. (default: empty string)

=item prepend_list

Array of paths to prepend to the top-level links.  They are used
as-is, and are not part of the processing done to the "paths" list
of paths.

=item preserve_order

Preserve the ordering of the paths in the input list of paths;
otherwise the links will be sorted alphabetically.
(default: true)

=item preserve_paths

Do not extract intermediate paths or reorder the input list of paths.
This speeds things up, but assumes that the input paths are complete
and in good order.
(default: false)

=item start_depth

Start your tree at this depth.  Zero is the root, level 1 is the
files/sub-folders in the root, and so on.
(default: 1)

=item top_level

Decide which level is the "top" level.  Useful when you
set the start_depth to something greater than 1.

=back

=cut
sub nav_tree {
    my %args = (
		paths=>undef,
		current_url=>'',
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		hide=>'',
		nohide=>'',
		preserve_order=>1,
		preserve_paths=>0,
		include_home=>0,
		labels=>{},
		start_depth=>1,
		end_depth=>undef,
		top_level=>1,
		navbar_type=>'normal',
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my $current_is_index = ($args{current_url} =~ m!/$!o);
    my %current_parents = extract_current_parents(%args);

    # set the end depth if is not already set
    # if this is an index-page, then make the depth its depth + 1
    # if this is a content-page, make the depth its depth
    my $current_url_depth = path_depth($args{current_url});
    $args{end_depth} = ($current_is_index
	? $current_url_depth + 1 : $current_url_depth)
	    if (!defined $args{end_depth});

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }
    my @path_list = ();
    if ($args{preserve_paths})
    {
	@path_list = filter_out_paths(%args, paths=>$args{paths});
    }
    else
    {
	@path_list = extract_all_paths(paths=>$args{paths},
				       preserve_order=>$args{preserve_order});
	@path_list = filter_out_paths(%args, paths=>\@path_list);
    }
    my @list_of_lists = build_lol(%args, paths=>\@path_list,
				  depth=>0);
    $args{tree_depth} = 0;

    my %default_format = make_default_format(%args);
    my %formats = make_extra_formats(%args);
    my $list = traverse_lol(\@list_of_lists,
			    %args,
			    formats=>\%formats,
			    current_format=>\%default_format,
			    current_parents=>\%current_parents);
    return $list if $list;

    return '';
} # nav_tree

=head1 Private Functions

These functions cannot be exported.

=head2 make_item

$item = make_item(
	this_label=>$label,
	this_link=>$link,
	hide_ext=>0,
	current_url=>$url,
	current_parents=>\%current_parents,
	descriptions=>\%desc,
	format=>\%format,
    );

%format = (
	pre_desc=>' ',
	post_desc=>'',
	pre_item=>'<li>',
	post_item=>'</li>'
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	pre_current_parent=>'<em>',
	post_current_parent=>'</em>',
	item_sep=>"\n");
);

Format a link item.

See L</link_list> for the formatting options.

=over

=item this_label

The label of the required link.  If there is no label,
this uses the base-name of the last part of the link,
capitalizing it and replacing underscores and dashes with spaces.

=item this_link

The URL of the required link.

=item current_url

The link to the current page.  If one of the links equals this,
then that is deemed to be the "active" link and is just displayed
as a label rather than a link.

=item current_parents

URLs of the parents of the current item.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the links (not the labels).

=item defer_post_item

Don't add the 'post_item' string if this is true.
(needed for nested lists)
(default: false)

=item no_link

Don't make a link for this, just a label.

=back

=cut
sub make_item {
    my %args = (
		this_link=>'',
		this_label=>'',
		hide_ext=>0,
		current_url=>'',
		current_parents=>{},
		prefix_url=>'',
		defer_post_item=>0,
		no_link=>0,
		@_
	       );
    my $link = $args{this_link};
    my $prefix_url = $args{prefix_url};
    my $label = $args{this_label};
    my %format = %{$args{format}};

    if (!$label)
    {
	$label = $link if !$label;
	if ($link =~ /([-\w]+)\.\w+$/o) # file
	{
	    $label = $1;
	}
	elsif ($link =~ /([-\w]+)\/?$/o) # dir
	{
	    $label = $1;
	}
	else # give up
	{
	    $label = $link;
	    $label =~ s#/# :: #go;
	}
	
	# prettify
	$label =~ s#_# #go;
	$label =~ s#-# #go;
	$label =~ s/(\b[a-z][-\w]+)/\u\L$1/go;
    }
    # if we are hiding the extensions of files
    # we need to display an extensionless link
    # while doing checks with the original link
    my $display_link = $link;
    if ($args{hide_ext})
    {
	if ($link =~ /(.*)\.[-\w]+$/o) # file
	{
	    $display_link = $1;
	}
    }
    my $item = '';
    my $desc = '';
    if (exists $args{descriptions}->{$link}
	and defined $args{descriptions}->{$link}
	and $args{descriptions}->{$link})
    {
	$desc = join('', $format{pre_desc},
		     $args{descriptions}->{$link},
		     $format{post_desc});
    }
    if (link_is_active(this_link=>$link,
	current_url=>$args{current_url}))
    {
	$item = join('', $format{pre_item_active},
		     $format{pre_active_item},
		     $label,
		     $format{post_active_item},
		     $desc,
		     );
    }
    elsif ($args{no_link})
    {
	$item = join('', $format{pre_item},
		     $label,
		     $desc);
    }
    elsif ($args{current_url}
	and exists $args{current_parents}->{$link}
	and $args{current_parents}->{$link})
    {
	$item = join('', $format{pre_item_current_parent},
		     $format{pre_current_parent},
		     '<a href="', $prefix_url, $display_link, '">',
		     $label, '</a>',
		     $format{post_current_parent},
		     $desc);
    }
    else
    {
	$item = join('', $format{pre_item},
		     '<a href="', $prefix_url, $display_link, '">',
		     $label, '</a>',
		     $desc);
    }
    if (!$args{defer_post_item})
    {
	$item = join('', $item, $format{post_item});
    }
    return $item;
} # make_item

=head2 make_canonical

my $new_url = make_canonical($url);

Make a URL canonical; remove the 'index.*' and add on a needed
'/' -- this assumes that directory names never have a '.' in them.

=cut
sub make_canonical {
    my $url = shift;

    return $url if (!$url);
    if ($url =~ m{^/index\.\w+$}o)
    {
	$url = '/';
    }
    elsif ($url =~ m{^(.*/)index\.\w+$}o)
    {
	$url = $1;
    }
    elsif ($url =~ m{/[-\w]+$}o) # no dots; a directory
    {
	$url = join('', $url, '/'); # add the slash
    }
    return $url;
} # make_canonical
 
=head2 get_index_path

my $new_url = get_index_path($url);

Get the "index" part of this path.  That is, if this path
is not for an index-page, then get the parent index-page
path for this path.
(Removes the trailing slash).

=cut
sub get_index_path {
    my $url = shift;

    return $url if (!$url);
    $url = make_canonical($url);
    if ($url =~ m{^(.*)/[-\w]+\.\w+$}o)
    {
	$url = $1;
    }
    elsif ($url ne '/' and $url =~ m{/$}o)
    {
	chop $url;
    }
    return $url;
} # get_index_path

=head2 get_index_parent

my $new_url = get_index_parent($url);

Get the parent of the "index" part of this path.
(Removes the trailing slash).

=cut
sub get_index_parent {
    my $url = shift;

    return $url if (!$url);
    $url = get_index_path($url);
    if ($url =~ m#^(.*)/[-\w]+$#o)
    {
	$url = $1;
    }
    return $url;
} # get_index_parent
 
=head2 path_depth

my $depth = path_depth($url);

Calculate the "depth" of the given path.

=cut
sub path_depth {
    my $url = shift;

    return 0 if ($url eq '/'); # root is zero
    if ($url =~ m!/$!o) # remove trailing /
    {
	chop $url;
    }
    return scalar ($url =~ tr!/!/!);
} # path_depth
 
=head2 link_is_active

    if (link_is_active(this_link=>$link, current_url=>$url))
    ...

Check if the given link is "active", that is, if it
matches the 'current_url'.

=cut
sub link_is_active {
    my %args = (
		this_link=>'',
		current_url=>'',
		@_
	       );
    # if there is no current link, is not active.
    return 0 if (!$args{current_url});

    my $link = make_canonical($args{this_link});

    return 1 if ($link eq $args{current_url});
    return 0;

} # link_is_active

=head2 traverse_lol

$links = traverse_lol(\@list_of_lists,
    labels=>\%labels,
    tree_depth=>$depth
    current_format=>\%format,
    ...
    );

Traverse the list of lists (of urls) to produce 
a nested collection of links.

This consumes the list_of_lists!

=cut
sub traverse_lol {
    my $lol_ref = shift;
    my %args = (
		current_url=>'',
		labels=>undef,
		prefix_url=>'',
		hide_ext=>0,
		@_
	       );

    my $tree_depth = $args{tree_depth};
    my %format = (
	%{$args{current_format}},
	(exists $args{formats}->{$tree_depth}
	? %{$args{formats}->{$tree_depth}}
	: ())
	);
    my @items = ();
    while (@{$lol_ref})
    {
	my $ll = shift @{$lol_ref};
	if (!ref $ll) # an item
	{
	    my $link = $ll;
	    my $label = (exists $args{labels}->{$link}
			 ? $args{labels}->{$link} : '');
	    my $item = make_item(this_link=>$link,
				 this_label=>$label,
				 defer_post_item=>1,
				 %args,
				 format=>\%format);

	    if (ref $lol_ref->[0]) # next one is a list
	    {
		$ll = shift @{$lol_ref};
		my $sublist = traverse_lol($ll, %args,
		    tree_depth=>$tree_depth + 1,
		    current_format=>\%format);
		$item = join($format{tree_sep}, $item, $sublist);
	    }
	    $item = join('', $item, $format{post_item});
	    push @items, $item;
	}
	else # a reference to a list
	{
	    if (defined $args{start_depth}
		&& $args{tree_depth} < $args{start_depth})
	    {
		return traverse_lol($ll, %args, current_format=>\%format);
	    }
	    else
	    {
		my $sublist = traverse_lol($ll, %args,
		    tree_depth=>$tree_depth + 1,
		    current_format=>\%format);
		my $item = join($format{tree_sep}, $format{pre_item}, $sublist);
		$item = join('', $item, $format{post_item});
		push @items, $item;
	    }
	}
    }
    my $list = join($format{item_sep}, @items);
    return join('',
	    (($args{end_depth} && $tree_depth == $args{end_depth} )
	    ? $args{last_subtree_head}
	    : $format{tree_head}),
	$list,
	    (($args{end_depth} && $tree_depth == $args{end_depth} )
	    ? $args{last_subtree_foot}
	    : $format{tree_foot})
	    );
} # traverse_lol

=head2 extract_all_paths

my @all_paths = extract_all_paths(paths=>\@paths,
    preserve_order=>0);

Extract all possible paths out of a list of paths.
Thus, if one has

/foo/bar/baz.html

then that would make

/
/foo/
/foo/bar/
/foo/bar/baz.html

If 'preserve_order' is true, this preserves the ordering of
the paths in the input list; otherwise the output paths
are sorted alphabetically.

=cut
sub extract_all_paths {
    my %args = (
	paths=>undef,
	preserve_order=>0,
	@_
    );
    
    my %paths = ();
    # keep track of the order of the paths in the list of paths
    my $order = 1;
    foreach my $path (@{$args{paths}})
    {
	my @path_split = split('/', $path);
	# first path as-is
	$paths{$path} = $order;
	pop @path_split;
	while (@path_split)
	{
	    # these paths are index-pages. should end in '/'
	    my $newpath = join('/', @path_split, '');
	    # give this path the same order-num as the full path
	    # but only if it hasn't already been added
	    $paths{$newpath} = $order if (!exists $paths{$newpath});
	    pop @path_split;
	}
	$order++ if ($args{preserve_order});
    }
    return sort {
	return $a cmp $b if ($paths{$a} == $paths{$b});
	return $paths{$a} <=> $paths{$b};
    } keys %paths;
} # extract_all_paths

=head2 extract_current_parents

    my %current_parents = extract_current_parents(current_url=>$url,
					      exclude_root_parent=>0);

Extract the "parent" paths of the current url

/foo/bar/baz.html

then that would make

/
/foo/
/foo/bar/

If 'exclude_root_parent' is true, then the '/' is excluded from the
list of parents.

=cut
sub extract_current_parents {
    my %args = (
	current_url=>undef,
	exclude_root_parent=>0,
	@_
    );
    
    my %paths = ();
    if ($args{current_url})
    {
	my $current_url = $args{current_url};
	my @path_split = split('/', $current_url);
	pop @path_split; # remove the current url
	    while (@path_split)
	    {
		# these paths are index-pages. should end in '/'
		my $newpath = join('/', @path_split, '');
		$paths{$newpath} = 1;
		pop @path_split;
	    }
	if ($args{exclude_root_parent})
	{
	    delete $paths{"/"};
	}
    }

    return %paths;
} # extract_current_parents

=head2 build_lol

    my @lol = build_lol(
	paths=>\@paths,
	current_url=>$url,
	navbar_type=>'',
    );

Build a list of lists of paths, given a simple list of paths.
Assumes that this list has already been filtered.

=over

=item paths

Reference to list of paths; this is consumed.

=back

=cut
sub build_lol {
    my %args = (
	paths=>undef,
	depth=>0,
	start_depth=>0,
	end_depth=>0,
	current_url=>'',
	navbar_type=>'',
	prepend_list=>undef,
	append_list=>undef,
	@_
    );
    my $paths_ref = $args{paths};
    my $depth = $args{depth};

    my @list_of_lists = ();
    while (@{$paths_ref})
    {
	my $path = $paths_ref->[0];
	my $can_path = make_canonical($path);
	my $path_depth = path_depth($can_path);
	my $path_is_index = ($can_path =~ m#/$#o);
	if ($path_depth == $depth)
	{
	    shift @{$paths_ref}; # use this path
	    push @list_of_lists, $path;
	}
	elsif ($path_depth > $depth)
	{
	    push @list_of_lists, [build_lol(
		%args,
		prepend_list=>undef,
		append_list=>undef,
		paths=>$paths_ref,
		depth=>$path_depth,
		navbar_type=>$args{navbar_type},
		current_url=>$args{current_url},
		)];
	}
	elsif ($path_depth < $depth)
	{
	    return @list_of_lists;
	}
    }
    # prepend the given list to the top level
    if (defined $args{prepend_list} and @{$args{prepend_list}})
    {
	# if the list of lists is a single item which is a list
	# then add the extra list to that item
	if ($#list_of_lists == 0
	    and ref($list_of_lists[0]) eq "ARRAY")
	{
	    unshift @{$list_of_lists[0]}, @{$args{prepend_list}};
	}
	else
	{
	    unshift @list_of_lists, @{$args{prepend_list}};
	}
    }
    # append the given list to the top level
    if (defined $args{append_list} and @{$args{append_list}})
    {
	# if the list of lists is a single item which is a list
	# then add the extra list to that item
	if ($#list_of_lists == 0
	    and ref($list_of_lists[0]) eq "ARRAY")
	{
	    push @{$list_of_lists[0]}, @{$args{append_list}};
	}
	else
	{
	    push @list_of_lists, @{$args{append_list}};
	}
    }
    return @list_of_lists;
} # build_lol

=head2 filter_out_paths

    my @filtered_paths = filter_out_paths(
	paths=>\@paths,
	current_url=>$url,
	hide=>$hide,
	nohide=>$nohide,
	start_depth=>$start_depth,
	end_depth=>$end_depth,
	top_level=>$top_level,
	navbar_type=>'',
    );

Filter out the paths we don't want from our list of paths.
Returns a list of the paths we want.

=cut
sub filter_out_paths {
    my %args = (
	paths=>undef,
	start_depth=>0,
	end_depth=>0,
	top_level=>0,
	current_url=>'',
	navbar_type=>'',
	hide=>'',
	nohide=>'',
	@_
    );
    my $paths_ref = $args{paths};
    my $hide = $args{hide};
    my $nohide = $args{nohide};

    my %canon_paths = ();
    my @wantedpaths1 = ();
    my %path_depth = ();

    # filter out common things
    # remember canonical paths and path depths
    foreach my $path (@{$paths_ref})
    {
	my $can_path = make_canonical($path);
	my $path_depth = path_depth($can_path);
	if ($hide and $nohide
	    and not($path =~ /$nohide/)
	    and $path =~ /$hide/)
	{
	    # skip this one
	}
	elsif ($hide and !$nohide and $path =~ /$hide/)
	{
	    # skip this one
	}
	elsif ($path_depth < $args{start_depth})
	{
	    # skip this one
	}
	elsif ($args{end_depth}
	    and $path_depth > $args{end_depth})
	{
	    # skip this one
	}
	else
	{
	    $path_depth{$path} = $path_depth;
	    $canon_paths{$path} = $can_path;
	    push @wantedpaths1, $path;
	}
    }

    my @wantedpaths = ();
    if ($args{current_url})
    {
	my $current_url = $args{current_url};
	my $current_url_depth = path_depth($args{current_url});
	my $current_url_is_index = ($args{current_url} =~ m{/$}o);

	my $parent = make_canonical($current_url_is_index
		      ? get_index_parent($args{current_url})
		      : get_index_path($args{current_url})
		     );
	my $parent_depth = path_depth($parent);
	my $grandparent = ($parent_depth == 1
			   ? '/'
			   : make_canonical(get_index_parent($parent)));
	my $greatgrandparent = ($parent_depth <= 1
				? ''
				: ($parent_depth == 2
				   ? '/'
				   : make_canonical(get_index_parent($grandparent))
				  )
			       );
	my $current_index_path = get_index_path($args{current_url});
	my $current_index_parent = get_index_parent($args{current_url});

	if ($args{navbar_type} eq 'breadcrumb')
	{
	    foreach my $path (@wantedpaths1)
	    {
		my $pd = $path_depth{$path};
		# a breadcrumb-navbar shows the parent, self,
		# and the children the parent
		if ($pd <= $current_url_depth
		    and $args{current_url} =~ /^$path/)
		{
		    push @wantedpaths, $path;
		}
		elsif ($path eq $args{current_url})
		{
		    push @wantedpaths, $path;
		}
		elsif ($pd >= $current_url_depth
		    and $path =~ m{^${current_url}})
		{
		    push @wantedpaths, $path;
		}
		elsif ($parent
		       and $pd >= $current_url_depth
		       and $path =~ m{^$parent})
		{
		    push @wantedpaths, $path;
		}
	    }
	}
	elsif ($args{navbar_type} or $args{do_navbar})
	{
	    # Rules for navbars:
	    # * if I am a leaf node, see my (great)uncles and siblings
	    # * if have children, use the same data as my parent,
	    #   plus my immediate children
	    foreach my $path (@wantedpaths1)
	    {
		my $pd = $path_depth{$path};
		if ($pd > $current_url_depth + 1)
		{
		    next;
		}
		if ($pd == $current_url_depth + 1
		    and $path =~ m{^${current_url}})
		{
		    push @wantedpaths, $path;
		}
		elsif ($pd == $current_url_depth
		       and $path =~ m{^${parent}})
		{
		    push @wantedpaths, $path;
		}
		elsif ($grandparent
		       and $pd == $parent_depth
		       and $path =~ m{^$grandparent})
		{
		    push @wantedpaths, $path;
		}
		elsif ($greatgrandparent
		    and $pd == $parent_depth - 1
		    and $path =~ m{^$greatgrandparent})
		{
		    push @wantedpaths, $path;
		}
	    }
	}
	else
	{
	    push @wantedpaths, @wantedpaths1;
	}
    }
    else
    {
	push @wantedpaths, @wantedpaths1;
    }
    return @wantedpaths;
} # filter_out_paths

=head2 make_default_format

    my %default_format = make_default_format(%args);

Make the default format hash from the args.
Returns a hash of format options.

=cut
sub make_default_format {
    my %args = (
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		@_
	       );
    my %default_format = (
			  pre_item=>$args{pre_item},
			  post_item=>$args{post_item},
			  pre_active_item=>$args{pre_active_item},
			  post_active_item=>$args{post_active_item},
			  pre_current_parent=>$args{pre_current_parent},
			  post_current_parent=>$args{post_current_parent},
			  pre_desc=>$args{pre_desc},
			  post_desc=>$args{post_desc},
			  item_sep=>$args{item_sep},
			  tree_sep=>$args{tree_sep},
			  tree_head=>$args{links_head},
			  tree_foot=>$args{links_foot},
			  pre_item_active=>($args{pre_item_active}
					    ? $args{pre_item_active}
					    : $args{pre_item}),
			  pre_item_current_parent=>
			  ($args{pre_item_current_parent}
			   ? $args{pre_item_current_parent}
			   : $args{pre_item}),
			 );
    return %default_format;
} # make_default_format

=head2 make_extra_formats

    my %formats = make_extra_formats(%args);

Transforms the subtree_head and subtree_foot into the "formats"
method of formatting.
Returns a hash of hashes of format options.

=cut
sub make_extra_formats {
    my %args = (
		formats=>undef,
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_item_active=>'<li>',
		pre_item_current_parent=>'<li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		@_
	       );
    my %formats = ();
    if (defined $args{formats})
    {
	%formats = %{$args{formats}};
    }
    if ($args{links_head} ne $args{subtree_head}
	|| $args{links_foot} ne $args{subtree_foot})
    {
	if (!exists $formats{1})
	{
	    $formats{1} = {};
	}
	$formats{1}->{tree_head} = $args{subtree_head};
	$formats{1}->{tree_foot} = $args{subtree_foot};
    }
    return %formats;
} # make_extra_formats

=head1 REQUIRES

    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules.

Therefore you will need to change the PERL5LIB variable to add
/home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com/tools/html_linklist/

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::LinkList
__END__
