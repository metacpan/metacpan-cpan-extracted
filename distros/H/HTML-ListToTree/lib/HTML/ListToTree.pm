=pod

=begin classdoc

Converts an HTML nested list document to a Javascripted
tree widget.<p>

Copyright&copy; 2007, Dean Arnold, Presicient Corp., USA. All rights reserved.<p>

Excluding the dtree widget software and components included in the 
L<HTML::ListToTree::DTree> package, permission is granted to use this software 
under the same terms as Perl itself. Refer to the L<Perl Artistic License|perlartistic> for details.

@author Dean Arnold
@since 2007-Jun-10
@self $self

=end classdoc

=cut

package HTML::ListToTree;

use HTML::TreeBuilder;
use HTML::ListToTree::DTree;

use strict;
use warnings;

our $VERSION = '0.10';

our %tags_accepted = qw(a 1 li 1 ul 1 ol 1 /a 1 /li 1 /ul 1 /ol 1);
#
#	have to use class variable for unlink action, due to
#	recursive structure
#
our %unlinks = ( 'include' => 1, 'warn' => 1, 'ignore' => 1 );
our $onUnlink;

=pod

=begin classdoc

Create an HTML::ListToTree object with specified text label and link url,
optionally setting an initial set of child nodes and/or extracting
children from a source document.

@constructor
@param Text		a text label for the node
@param Link		a link URL for the node.
@optional Children	an arrayref of HTML::ListToTree objects
@optional Source	a document from which to collect child nodes
@optional Widget	either a Perl object, or the name of a Perl package, providing browser widget construction methods;
	default 'HTML::ListToTree::DTree'
@optional UnlinkedLeaves	string specifying disposition of unlinked leaf nodes; valid values are
					<ul>
					<li>include (the default) - include in three
					<li>warn - emit warning, but include in tree
					<li>ignore - don't include, and don't warn
					</ul>

@return	an HTML::ListToTree object

=end classdoc

=cut

sub new {
	my $class = shift;
	my %args = @_;

	$args{Children} ||= [];
	my $widget;
	if ($args{Widget}) {
		if (ref $args{Widget}) {
			$widget = $args{Widget};
		}
		else {
			eval "
				require $args{Widget};
				\$widget = $args{Widget}->new();
			";
			return undef if $@;
		}
	}
	else {
		$widget = HTML::ListToTree::DTree->new();
	}
#
#	if an unlink action is specified, update it
#
	$onUnlink = $unlinks{lc $args{UnlinkedLeaves}} ? lc $args{UnlinkedLeaves} : 'include'
		if exists $args{UnlinkedLeaves};

	$onUnlink ||= 'include';
	my $self = bless {
		_text => $args{Text},
		_link => $args{Link},
		_children => $args{Children},
		_widget => $widget,
	}, $class;

	push @{$self->{_children}}, $self->extractTree($args{Source})
		if exists $args{Source};

	return $self;
}

=pod

=begin classdoc

Add a set of sibling nodes to the tree as a child of this node.
The nodes are appended to any existing list of immediate children
of this node.

@param @nodes 		a list of nodes. Nodes are specified as either 2-tuples of
					Text => Link, or as an HTML::ListToTree object

@returnlist HTML::ListToTree objects added as children of this object

=end classdoc

=cut

sub addChildren {
	my $self = shift;
	my ($text, $link);
	my @nodes = ();
	my @args = (ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_;
	push(@{$self->{_children}},
		ref $args[0] ? shift @args : HTML::ListToTree->new(Text => shift @args, Link => shift @args)),
	push(@nodes, $self->{_children}[-1])
		while (@args);
	return @nodes;
}

=pod

=begin classdoc

Extract a tree from a nested lists of the input document, and
add it as a child of this node.

@param $html 		the source HTML document

@returnlist HTML::ListToTree objects extracted from the document

=end classdoc

=cut

sub addFromDocument {
	my ($self, $html) = @_;
	my @nodes = $self->extractTree($html);
	push @{$self->{_children}}, @nodes;
	return @nodes;
}

=pod

=begin classdoc

Return the child nodes of this node as a list.
The list is in the order in which the nodes were added
to this node.

@returnlist the child nodes aHTML::ListToTree objects

=end classdoc

=cut

sub getChildren {
	my $self = shift;

	return @{$self->{_children}};
}

=pod

=begin classdoc

Scans this node's children to locate a node with the specified text label.
The scan is breadth first (i.e., siblings are scanned before children).

@return	if a match is found, an HTML::ListToTree object; otherwise, undef.

=end classdoc

=cut

sub getNodeByText {
	my ($self, $text) = @_;

	foreach (@{$self->{_children}}) {
		return $_
			if ($_->{_text} eq $text);
	}
	foreach (@{$self->{_children}}) {
		my $node = $_->getNodeByText($text);
		return $node if $node;
	}
	return undef;
}

=pod

=begin classdoc

Scans this node's children to locate a node with the specified URL link.
The scan is breadth first (i.e., siblings are scanned before children).

@return	if a match is found, an HTML::ListToTree object; otherwise, undef.

=end classdoc

=cut

sub getNodeByLink {
	my ($self, $link) = @_;

	my $offset = -1 * length($link);
	foreach (@{$self->{_children}}) {
		return $_
			if (substr($_->{_link}, $offset) eq $link);
	}
	foreach (@{$self->{_children}}) {
		my $node = $_->getNodeByLink($link);
		return $node if $node;
	}
	return undef;
}

=pod

=begin classdoc

Return the text label of this node.

@return	the text label of this node

=end classdoc

=cut

sub getText {
	return $_[0]->{_text};
}

=pod

=begin classdoc

Set the text label of this node.

@param $text	the text label to set

@return	this node

=end classdoc

=cut

sub setText {
	$_[0]->{_text} = $_[1];
	return $_[0];
}

=pod

=begin classdoc

Return the link URL of this node.

@return	the link URL of this node

=end classdoc

=cut

sub getLink {
	return $_[0]->{_link};
}

=pod

=begin classdoc

Set the link URL of this node.

@param $link	the link URL to set

@return	this node

=end classdoc

=cut

sub setLink {
	$_[0]->{_link} = $_[1];
	return $_[0];
}

=pod

=begin classdoc

Render this HTML::ListToTree object into an HTML document containing Javascript
required for <a href=''>dtree</a>, and suitable for use as a frame
within a frameset. Subclasses may override this method to provide
alternate renderings of the tree.

@constructor
@optional Additions HTML text to be appended to the generated tree
@optional BasePath  the base directory path for all local hyperlinks
@optional CloseIcon name of icon used for closed tree nodes; default 'closedbook.gif'
@optional CSSPath path to the stylesheet file dtree.css used by dtree; default './css'
@optional IconPath path to the location of icons used by dtree; default './img'
@optional JSPath path to the Javascript file dtree.js; default '.js'
@optional UseIcons when set to a true value, tree nodes are decorated with icons; default true
@optional OpenIcon name of icon used for open tree nodes; default 'openbook.gif'
@optional RootIcon name of icon used for the root tree node; default is same as OpenIcon
@optional Target the name of an HTML frame to contain the document being navigated; default 'mainframe'

@return	an HTML document

=end classdoc

=cut

sub render {
	my $self = shift;
	my %args = @_;

	$args{CloseIcon} ||= 'closedbook.gif';
	$args{OpenIcon} ||= 'openbook.gif';
	$args{IconPath} ||= './img';
	$args{CSSPath} ||= './css/dtree.css';
	$args{JSPath} ||= './js/dtree.js';
	$args{RootIcon} ||= $args{OpenIcon};
	$args{Target} ||= 'mainframe';
	$args{Additions} ||= '';

	$args{UseIcons} = 1 unless exists $args{UseIcons};
	
	my ($openimg, $closeimg, $rootimg) = $args{UseIcons} ?
		("$args{IconPath}/$args{OpenIcon}",
			"$args{IconPath}/$args{CloseIcon}",
			"$args{IconPath}/$args{RootIcon}") :
		('', '', '');
#
#	adjust paths for css/javascript/images
#
	if ($args{BasePath}) {
		$args{$_} = _pathAdjust($args{BasePath}, $args{$_})
			foreach (qw(JSPath CSSPath IconPath));
		$self->{_link} = _pathAdjust($args{BasePath}, $self->{_link})
			if $self->{_link};
	}
#
#	save path info if needed later
#
	$self->{_jspath} = $args{JSPath};
	$self->{_iconpath} = $args{IconPath};
	$self->{_csspath} = $args{CSSPath};
	$self->{_widget}->start(
		IconPath => $args{IconPath},
		CSSPath => $args{CSSPath},
		JSPath => $args{JSPath}, 
		UseIcons => $args{UseIcons} || 0, 
		RootIcon => $rootimg, 
		RootText => $self->{_text},
		RootLink => $self->{_link},
		Target => $args{Target}, 
		OpenIcon => $openimg,
		CloseIcon => $closeimg,
		);
#
#	sort current tree into levels
#
	my @levels =  ( [ $self ] );
	_sort_tree([ $self ], \@levels);
#
#	draw root level first
#
	my ($close, $open);
	shift @levels;
	foreach (@{$self->{_children}}) {
		$_->{_text}=~s/'/\\'/g;
		$_->{_link} = _pathAdjust($args{BasePath}, $_->{_link})
			if $args{BasePath};
		(($#{$_->{_children}} >= 0) && $args{UseIcons}) ?  
			$self->{_widget}->add($_->{_node}, 0, $_->{_text}, $_->{_link}) :
			$self->{_widget}->addLeaf($_->{_node}, 0, $_->{_text}, $_->{_link});
	}
#
#	then draw succeding levels
#
	my $offset = scalar @{$levels[0]};
	foreach my $i (1..$#levels) {
		foreach (@{$levels[$i]}) {
			$_->{_node} += $offset;
			$_->{_text}=~s/'/\\'/g;
			$_->{_link} = _pathAdjust($args{BasePath}, $_->{_link})
				if $args{BasePath};
			(($#{$_->{_children}} >= 0) && $args{UseIcons}) ? 
				$self->{_widget}->add($_->{_node}, $levels[$i-1][$_->{_parent}]->{_node}, $_->{_text}, $_->{_link}) :
				$self->{_widget}->addLeaf($_->{_node}, $levels[$i-1][$_->{_parent}]->{_node}, $_->{_text}, $_->{_link});
		}
		$offset += scalar @{$levels[$i]};
	}

	return $self->{_widget}->getWidget($args{Additions});
}

sub _pathAdjust {
	my ($path, $jspath) = @_;
	return $jspath
		unless (substr($jspath, 0, 2) eq './') && (substr($path, 0, 2) eq './');
#
#	relative path, adjust as needed from current base
#
	my @parts = split /\//, $path;
	my @jsparts = split /\//, $jspath;
	shift @parts;
	shift @jsparts;	# and the relative lead
	my $prefix = '';
	shift @parts, 
	shift @jsparts
		while @parts && @jsparts && ($parts[0] eq $jsparts[0]);
	return ('../' x scalar @parts) . join('/', @jsparts)
}

=pod

=begin classdoc

Extract the nested list from the supplied HTML document and convert it
to an HTML::ListToTree object. Subclasses may override this method
to provide alternate list extraction logic.

@param $html	the source document

@return	an HTML::ListToTree object

=end classdoc

=cut

sub extractTree {
	my ($self, $src) = @_;
#
#	enforce some canonical form: only start with a list,
#	remove all comments, and insert list items between
#	consecutive list elements
#
	$src=~s/<!--[^>]+>//gs;
	$src=~s!<(/?\w+)([^>]*)>!{ $tags_accepted{lc $1} ? "<$1$2>" : '' }!egs; 
	$src=~s/<\s*(ol|ul|li)(?:\s+[^>]*)?>/<$1>/igs;
	$src=~s/(<(?:ol|ul)>)\s*(<(?:ol|ul)>)/$1<li>$2/igs;
	die "Not valid source: must start with list element"
		unless ($src=~/^\s*<(?:ul|ol)>/is);

#open OUTF, ">fuckinghsit.html";
#print OUTF $src, "\n";
#close OUTF;

	my $tree = HTML::TreeBuilder->new_from_content($src);

	my @nodes = $tree->guts();
	my $root;
	my $ultree;
#
#	get root of index tree
#
	foreach (@nodes) {
		$root = $_,
		last
			if ($_->tag eq 'ul') || ($_->tag eq 'ol');
	}

	$root->dump() if $self->{_debug};
#
#	recursively scan list for links/embeded lists
#
	return @{_proc_ul($root, $self->{_unlinked})};
}

sub _proc_ul {
	my $node = shift;

	my @tree = ();
	foreach ($node->content_list) {
		die "UNEXPECTED TAG " . $_->tag . "\n"
			unless ($_->tag eq 'li');
		push @tree, _proc_tree($_);
	}
#
#	cleanup any overindented lists
#
	my $i;
	for ($i = $#tree; $i >= 0; $i--) {
		unless (($#{$tree[$i]{_children}} >= 0) || $tree[$i]{_link}) {
			if ($onUnlink eq 'warn') {
				warn "\"$tree[$i]{_text}\" is an unlinked leaf node\n";
			}
			elsif ($onUnlink eq 'ignore') {
				splice @tree, $i, 1;
				next;
			}
		}
		splice @tree, $i, 1, @{$tree[$i]{_children}}
			unless $tree[$i]{_text};
	}
	return \@tree;
}

sub _pure_text {
	my $node = shift;
	my $out = '';
	$out .= (ref $_) ? ($_->content())[0] : $_
		foreach ($node->content_list);
#	print STDERR "*** $out\n";
	return $out;
}

sub _proc_tree {
	my $node = shift;

	my $elem;
	foreach ($node->content_list) {
#
#	intermediate nodes may not be links
#
		$elem = HTML::ListToTree->new(Text => $_, Link => ''),
		next
			unless (ref $_);

		if ($_->tag eq 'a') {
			$elem = HTML::ListToTree->new(Text => _pure_text($_), Link => $_->attr('href'));
		}
		elsif (($_->tag eq 'ul') || ($_->tag eq 'ol')) {
#
#	assumes prior entry was a link/header; if not, create dummy entry
#
			$elem = HTML::ListToTree->new(Text => '', Link => '')
				unless $elem;

			$elem->addChildren(_proc_ul($_));
		}
		else {
			die "UNEXPECTED LIST TAG " . $_->tag . "\n";
#				unless ($_->tag eq 'br');
		}
	}
	return $elem;
}

sub _sort_tree {
	my ($level, $levels) = @_;

	my @nextlevel = ();
	my $entry = 0;
	my $node;
#
#	cascade the root document to all children that don't have a root
#
	foreach my $i (0..$#$level) {
		$node = $level->[$i];
		die "UNEXPECTED ARRAY"
			if (ref $node eq 'ARRAY');
		my $root = ($node->{_link} && ($node->{_link}=~/^([^\#]+)/)) ? $1 : '';
		$level->[$i]->{_node} = $i + 1;
		if (exists $node->{_children}) {
			foreach (@{$node->{_children}}) {
				$_->{_parent} = $node->{_node} - 1;
				$_->{_link} = $root . $_->{_link}
					if (substr($_->{_link}, 0, 1) eq '#');
				push @nextlevel, $_;
			}
		}
	}
	push(@$levels, \@nextlevel),
	_sort_tree(\@nextlevel, $levels)
		if scalar @nextlevel;
}

=pod

=begin classdoc

Return the current widget's Javascript.

@return	the Javascript as a string.

=end classdoc

=cut

sub getJavascript { return $_[0]->{_widget}->getJavascript(); }

=pod

=begin classdoc

Return the current widget's CSS stylesheet.

@return	the CSS stylesheet as a string.

=end classdoc

=cut

sub getCSS { return $_[0]->{_widget}->getCSS(); }

=pod

=begin classdoc

Return the specified icon image data for the current widget.

@return	the widget icon image data.

=end classdoc

=cut

sub getIcon { return $_[0]->{_widget}->getIcon($_[1]); }

=pod

=begin classdoc

Return the all icon images for the current widget.

@returnlist	the widget icon images as a hash mapping icon file names to the image data

=end classdoc

=cut

sub getIcons { return $_[0]->{_widget}->getIcons(); }

=pod

=begin classdoc

Write out the current widget's Javascript.

@optional $path full path name of file to be written; default is JSPath specified at render()

@return	1 on success, -1 if no Javascript was written, or undef on failure with the error message in $@

=end classdoc

=cut

sub writeJavascript { 
	my $js = $_[0]->{_widget}->getJavascript() or return -1;
	return _writeFile($js, $_[1] || $_[0]->{_jspath});
}

=pod

=begin classdoc

Write out the current widget's CSS stylesheet.

@optional $path full path name of file to be written; default is CSSPath specified at render()

@return	1 on success, -1 if CSS was written, or undef on failure with the error message in $@

=end classdoc

=cut

sub writeCSS { 
	my $css = $_[0]->{_widget}->getCSS() or return -1;
	return _writeFile($css, $_[1] || $_[0]->{_csspath});
}

=pod

=begin classdoc

Write out the specified icon image data for the current widget.

@param $icon	name of icon to write
@optional $path full path name of file to be written; default is IconPath specified at render(),
	with specified icon name

@return	1 on success, -1 if no icon was written, or undef on failure with the error message in $@

=end classdoc

=cut

sub writeIcon {
	my $icon = $_[0]->{_widget}->getIcon($_[1]) or return -1;
	return _writeFile($icon, ($_[2] || $_[0]->{_iconpath}) . "/$_[1]", 1);
}

=pod

=begin classdoc

Write out all icon images for the current widget.

@optional $path path name of files to be written; default is IconPath specified at render()

@return	1 on success, -1 if no icons were written, or undef on failure with the error message in $@

=end classdoc

=cut

sub writeIcons { 
	my %icons = $_[0]->{_widget}->getIcons();
	return -1 unless %icons;
	my ($k, $v);
	while (($k, $v) = each %icons) {
		return undef
			unless _writeFile($v, ($_[1] || $_[0]->{_iconpath}) . "/$k", 1);
	}
	return 1;
}

sub _writeFile {
	my ($content, $path, $binary) = @_;
	$@ = "Can't open $path: $!",
	return undef
		unless open(OUTF, ">$path");
	binmode OUTF if $binary;
	print OUTF $content;
	close OUTF;
	return 1;
}

1;

