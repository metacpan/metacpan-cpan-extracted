package Kwiki::TableOfContents;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
use IO::All;
use JSON;
our $VERSION = '0.01';

const class_title => 'Table of Contents';
const class_id => 'toc';
const javascript_file => 'jstree.js';
const css_file => 'jstree.css';

sub register {
	my $registry = shift;
	$registry->add(prerequisite => 'prototype');
	$registry->add(prerequisite => 'scriptaculous');
	$registry->add(prerequisite => 'json');
	$registry->add(preload => 'toc');
	$registry->add(action => 'save_toc');
}

sub save_toc {
	CGI::param('structure') > $self->structure_file;
	return 'success';
}

sub structure_file {
	my $path = $self->plugin_directory;
	io($path)->mkpath unless io($path)->exists;
	$path = io->catfile($path, 'structure');
	unless($path->exists) {
		'[]' > $path;
		$path->close;
		$path->open;
	}
	return $path;
}

sub html {
	my $wrap = defined $_[0]
		? sub { return $_[0]; }
		: sub { return qq{<ul id="toc" class="jstree"
				style="display: none">$_[0]</ul>}};
	return $wrap->(join('', map {
		my $link = $_->{data}->{href};
		$link = '#' if $link eq '';
		my $class = $link eq '#' ? ' class="category"' : '';
		my $text = $_->{data}->{text};
		my $subtree = @{$_->{subtree}} > 0
			? '<ul>'.$self->html($_->{subtree}).'</ul>'
			: '';
		qq{<li><a href="$link"$class>$text</a>$subtree</li>};
	} defined $_[0] ?@{$_[0]}:@{jsonToObj($self->structure_file->slurp)}));
}

1; # End of Kwiki::TableOfContents
__DATA__
=head1 NAME

Kwiki::TableOfContents - Provides a Table of Contents feature that a template
can use to make a wiki work as a manual.

=head1 SYNOPSIS

This module tries to be very Web 2.0/Ajax/<pick your buzzword> by using a
Javascript-based tree to both use and edit the table of contents. All changes
are transmitted immediately using Ajax. Most every action is based around
drag-and-drop. To add a new link to the TOC simply drag the header of the page
to the place in the menu you want to add it. Any link can also act as a
category so you can place links inside it. To do this either expand the subtree
and drag and drop inside that subtree or drop on the actual link when it
becomes bold.

To remove a link simply drag to the trash can. If you want to create a new
category that is not a link simply drag the "New Folder" icon to the location
you want to add the new folder. To rename any link or folder simply click the
edit icon next to the node and a in-place editor will appear allowing you to
edit that item.

=head1 TODO

This plugin is fairly complex Javascript code using libraries that have not
been worked with extensively. Therefore it may not behave as well as desired
although it seems to work decent. The following are known issues I would like
to resolve:

=over

=item Template Interaction

Right now installing the menu doesn't really do anything because whatever
template is installed must know about it to make a place for it. So the template
must be TOC compatible. The only TOC compatible theme is BlueOcean (a
modification of GreenHouse). I would like establish independence between TOC
and the themes.

=item Slow Performance on Firefox

Drag and drop on firefox is slow when inside a scrollable pane. This is because
the implementation of the drag and drop features of Script.aculo.us. They do a
great job of making drag and drop work but they are fighting an uphill battle
since they are doing stuff I imagine the web browser developers would not
have imagined someone would try. :)

=item Stability problems

Sometimes the operations are just not as stable as desired. For example if you
delete an item sometimes the alert() dialog will throw things out of wack when
you attempt to click ok. Or sometimes it is difficult to place an object
where you want. It would be nice to really get this component rock solid.

=cut

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/toc_setup.html__
<script type="text/javascript">
	function save_toc(structure) {
		var arguments = $H({
			action:         'save_toc'
		});
		new Ajax.Request('?'+arguments.toQueryString(), {
			parameters:     $H({
				structure: structure.toJSONString()
			}).toQueryString(),
			onComplete:     function(transport, json) {
				// FIXME: Provide some feedback info
				//alert(transport.responseText);
			}
		});
	}
	JSTree.addLoadEvent(function() {
		JSTree.options({
			onEdit:         function(link, structure) {
				save_toc(structure);
			},
			onUpdate:       function(structure) {
				save_toc(structure);
			},
			onRemove:       function(li, structure) {
				var msg = 'Are you sure?';
				if( confirm(msg) ) {
					save_toc(structure);
					return true;
				}
				return false;
			}
		});
	});
</script>
__template/tt2/toc.html__
[%- hub.toc.html -%]
__javascript/jstree.js__
Position.includeScrollOffsets = true;
debug = Prototype.emptyFunction;
jslog = new Object();
$A(['debug', 'info', 'warning', 'error', 'text']).each(function(func) {
	jslog[func] = Prototype.emptyFunction;
});
if (location.href.match(/jslog\=enable/)) {
	Scriptaculous.require('javascript/jslog.js');
}

/**
 * A mixin that can be mixed into any object to allow observable methods to be
 * easily created.
 */
var ObservableMethodProvider = {
	/**
	 * Will return an observable function on the method given (as a string)
	 * bound to the called instance and will return the same observable
	 * function everytime so the observation can be removed without having
	 * to store the return value given by this function.
	 */
	observable_method:function(method) {
		this.observables = $H(this.observables);
		this.observables[method] = this.observables[method] ||
			(function(event) {
				this[method]();
				return false;
			}).bindAsEventListener(this);
		return this.observables[method];
	}
}

/**
 * Class to manage a javascript-based tree built on a unordered list.
 */
var JSTree = Class.create();

/**
 * Class methods for JSTree
 */
Object.extend(JSTree, {

	/**
	 * Will configure all elements passed in to be dropable on a JSTree
	 */
	_nodable:	[],
	nodable:	function(/*elements...*/) {
		debug('Making '+arguments.length+' elements nodable');
		$A(arguments).flatten().each(function(e) {
			new Draggable(e, {revert: true});
			Element.addClassName(e, 'nodable');
			JSTree._nodable.push(e);
		});
	},

	/**
	 * Getter/Setter that will determine what the start node is. This is
	 * the node that should be navigated to when the tree is first
	 * displayed. If this is not set then it default to location.href
	 */
	start_node:	function(start_node) {
		if( start_node != null ) { JSTree._start_node = start_node; }
		return JSTree._start_node || location.href;
	},

	/**
	 * Will set options on all JSTree's on the page.
	 */
	options:	function(options, override, defaults) {
		override = override == null ? false : override;
		defaults = defaults == null ? true : defaults;
		debug('Setting options: '+Object.inspect($H(options))+
			' with override set to '+(override ? 'true' : 'false')+
			' and defaults set to '+(defaults ? 'true' : 'false'));

		// NOTE: Attempt to preload images
		$H(options).reject(function(item) {
			return item.key.indexOf('img') == -1;
		}).each(function(option) {
			var preload = new Image;
			debug('Preloading image '+preload.src);
			preload.src = option.value;
		});

		JSTree.trees().each(function(tree) {
			tree.options(options, override);
		});
		if( defaults ) {
			JSTree._options = Object.extend(JSTree._options || {}, options);
		}
	},

	/**
	 * Will return all tree objects on the page. This will not return tree
	 * objects that were created but do not have their HTML representation
	 * on the page.
	 */
	trees:		function() {
		return JSTree.html_trees().reject(function(tree) {
			return !tree.backend;
		}).collect(function(tree) {
			return tree.backend;
		});
	},

	/**
	 * Will return an existing tree object given the HTML id of the
	 * HTML representation.
	 */
	tree:		function(tree) {
		return $(tree).backend;
	},

	/**
	 * Will return the HTML representation of all trees on the page.
	 */
	html_trees:	function() {
		return $A(document.getElementsByClassName('jstree'));
	},

	/**
	 * Called to register the initialization of the tree objects.
	 */
	start:		function(options) {
		debug('Starting Tree initialization');
		if( options ) {
			debug('Starter has options');
			JSTree.addLoadEvent(function(){
				JSTree.options(options);
			});
		}
		JSTree.addLoadEvent(function(){
			JSTree.apply();
		});
		if( options && options.afterStart ) {
			debug('Starter has an afterStart callback');
			JSTree.addLoadEvent(options.afterStart);
		}
	},

	/**
	 * Will actually initialize all tree objects on the page.
	 */
	apply:		function() {
		debug('Initializing '+JSTree.html_trees().length+' trees');
		JSTree.html_trees().each(function(tree) {
			tree_obj = new JSTree(tree, JSTree._options);
			Element.show(tree);
			tree_obj.navigate(JSTree.start_node());
		});
	},

	/**
	 * Will add a function to the page load handler
	 */
	_load_event_added:	false,
	addLoadEvent:		function(func){
	if( !JSTree._load_event_added ) {
		debug('Setting up window load handler');
		var old_load = window.onload;
		window.onload =  function() {
			if( old_load )
				old_load();
			JSTree.executeLoadEvents();
		}
		JSTree._load_event_added = true;
	}
	debug('Adding window load event callback');
	JSTree._load_events.push(func);
	},

	_load_events:		$A([window.onload]),
	executeLoadEvents:	function() {
		if( typeof JSTree._load_events[0] == 'function' ) {
			debug('Executing load callback');
			JSTree._load_events[0]();
		}
		if( JSTree._load_events.length > 0 ) {
			JSTree._load_events.shift();

			// NOTE: Give IE a second to handle anything from last
			// action (like loading images!)
			setTimeout(function() { JSTree.executeLoadEvents() },10);
		}
	}
});

/**
 * Instance methods for JSTree
 */

Object.extend(JSTree.prototype, ObservableMethodProvider);
Object.extend(JSTree.prototype, {

	/**
	 * Called when a new JSTree object is created. Initializes a tree
	 */
	initialize:	function(tree, options) {
		debug('Initializing Tree');
		tree.backend = this;
		this.tree = tree;
		this.editable = false;
		this.options(options);

		this.nodes = $A(this.tree.getElementsByTagName('li')).collect(
			(function(li) {
				return new JSTree.ListItem(li, this);
			}).bind(this));
		this.add_function_bar();
		Draggables.addObserver(new JSTree.NewNodeObserver(this));
	},

	/**
	 * Will set the options for this tree.
	 */
	options:	function(options, override) {
		override = override == null ? true : override;
		if( options != null ) {
			debug('Setting options '+Object.inspect($H(options))+
				' with override set to '+(override ? 'true' : 'false'));
			this._options = this._options || new Object();
			var dst = override ? this._options : options;
			var src = override ? options : this._options;
			Object.extend(dst, src);
			this._options = dst;
		}
		return this._options;
	},

	/**
	 * Getter/Setter for a specific option. Return null if the option is
	 * not set.
	 */
	option:		function(key, value) {
		if( value != null ) {
			debug('Setting option '+key+' to '+value);
			var new_values = new Object();
			new_values[key] = value;
			this.options(new_options);
		} else {
			debug('Getting option '+key);
		}
		if( this.options() == null )
			return null;
		return this.options()[key];
	},

	/**
	 * Will naviagate to a specific node in a tree. Basically this means
	 * expanding all parent nodes and scolling to make this node visible.
	 * FIXME: Make this more capable so that something beside the href can be provided
	 * FIXME: Make it scroll to item even when hidden (make reappear quickly?)
	 */
	navigate:	function(item) {
		debug('Navigating to '+item);
		this.collapse_all();
		this.nodes.each((function(node) {
			if( node.link.href == item ) {
				node.select();
				node.expand();
				setTimeout((function() {
					debug('Scrolling to '+item);
					this.tree.parentNode.scrollTop =
						Position.positionedOffset(node.element)[1];
				}).bind(this), 10);
				return true;
			}
		}).bind(this));
		return false;
	},

	/**
	 * Will collapse all nodes
	 */
	collapse_all:	function() {
		debug('Collapsing All');
		this.nodes_with_subtrees().each(function(n) { n.collapse(); });
	},

	/**
	 * Will expand all nodes
	 */
	expand_all:	function() {
		debug('Expanding All');
		this.nodes_with_subtrees().each(function(n) { n.expand(); });
	},

	unselect_all:	function() {
		debug('Unselecting All');
		this.nodes.each(function(node) {
			node.unselect();
		});
	},

	/**
	 * Will put this tree in edit mode which means that nodes can be
	 * added/edited/removed/moved.
	 */
	toggle_edit:	function() {
		debug('Switch between editable and non-editable');
		this.editable = !this.editable;
		if( this.editable ) {
			this.make_editable();
			Element.addClassName(this.tree, 'editable');
		} else {
			this.make_readonly();
			Element.removeClassName(this.tree, 'editable');
		}
	},

	/**
	 * Will add the function bar at the bottom of the list. This bar gives
	 * some components for the user to interact with when editing.
	 */
	add_function_bar:function() {
		debug('Adding function bar to tree');
		this.function_bar = $E('div', {}, {display: 'none'},
			['functionbar']);

		debug('Adding trash can');
		this.trash = $E('span', {}, {}, ['trash'],
			this.option('delete_img') ?
				$image(this.option('delete_img')) :
				$T('Trash'));
		Droppables.add(this.trash, {
			onDrop: (function(drag, drop) {
				var edit_cb = this.option('onRemove') ||
					function() {
						return true;
					};
				this.reparent();
				if(edit_cb(drag,this.structure())) {
					Element.remove(drag);

					Sortable.clear_indicator(this);
					this._last_indicated = null;
					this._last_indicated_type = null;
					this._last_dragged = null;
				}
			}).bind(this)
		});
		this.function_bar.appendChild(this.trash);

		debug('Adding New Category');
		this.new_category = $E('a', {href: '#'}, {},
			['new_category', 'nodable'],
			this.option('newcat_img') ?
				$image(this.option('newcat_img')) :
				$T('New Category'));
		this.new_category.onclick = function() { return false; }
		new Draggable(this.new_category, {revert: true});
		this.function_bar.appendChild(this.new_category);

		this.tree.parentNode.insertBefore(this.function_bar,
			this.tree.nextSibling);
	},

	/**
	 * Actually do all the changes to the interface when we enter edit mode
	 */
	make_editable:	function() {
		debug('Making tree editable');
		Element.show(this.function_bar);
		this.nodes.each(function(n) {
			n.make_editable();
		});

		// FIXME: Ghosting is busted in tree mode. Someone fix it! :)
		Sortable.create(this.tree, {
			tree:	   true,   // Hope we got this working!
			containment:    false,  // So we can drag to trash can
			constraint:     false,  // So we can accept new items
			scroll:	 this.tree.parentNode,
			onUpdate:       (function(tree) {
				debug('They dropped the item');
				Sortable.clear_indicator(this);
				if( this._last_indicated ) {
					switch( this._last_indicated_type ) {
						case 'above':
							this._last_indicated.parentNode.insertBefore(this._last_dragged, this._last_indicated);
							break;
						case 'below':
							this._last_indicated.parentNode.insertBefore(this._last_dragged, this._last_indicated.nextSibling);
							break;
						case 'nested':
							this.add_nested_element(this._last_indicated.backend, this._last_dragged);
							break;
					}
					this._last_indicated = null;
					this._last_indicated_type = null;
					this._last_dragged = null;
				}
				this.reparent();
				if( this.option('onUpdate') ) {
					debug('Infom the app about the update');
					this.option('onUpdate')(this.structure())
				}
			}).bind(this)
		});

		// NOTE: Prepare nodable links
		debug('Turning '+JSTree._nodable.length+
			' elements into draggable items');
		JSTree._nodable.each(function(e) {
			e._backup_href = e.getAttribute('href');
			e._backup_onclick = e.onclick;

			e.setAttribute('href', '#');
			e.onclick = function() { return false; };
		});
	},

	/**
	 * Actually do all the changes to the interface when we are done editing
	 */
	make_readonly:	function() {
		debug('Making the tree read only');
		Element.hide(this.function_bar);
		this.nodes.each(function(n) {
			n.make_readonly();
		});
		Sortable.destroy(this.tree);

		// NOTE: Restore nodable links
		debug('Turning '+JSTree._nodable.length+
			' elements into clickable items');
		JSTree._nodable.each(function(e) {
			e.setAttribute('href', e._backup_href);
			e.onclick = e._backup_onclick;

			e._backup_href = null;
			e._backup_onclick = null;
		});
	},

	/**
	 * Return all nodes that have subtrees
	 */
	nodes_with_subtrees:function() {
		return this.nodes.reject(function(n) {
			return !n.has_subtree();
		});
	},

	add_nested_element:function(subtree, new_element) {
		debug('Moving an element inside another element.');
		if( !subtree.has_subtree() ) {
			debug('They do not already have a subtree');
			subtree.element.appendChild($E('ul'));
			Element.remove(subtree.element.firstChild);
			subtree.add_subtree_control(subtree.close_control_content(),
				subtree.observable_method('collapse'));
			subtree.expand();
		}
		document.getDirectChildrenByTagName('ul',
			subtree.element)[0].appendChild(new_element);
	},

	/**
	 * Will reinit the parent relationships after a change has occured
	 * in the tree. Must be called after every structure change!
	 */
	reparent:	function() {
		this.nodes.each(function(node) {
			node.reparent();
		});
	},

	/**
	 * Will return the structure of the current tree. Useful snapshotting
	 * the current tree state. Used when the "update" function is called.
	 * The format of the structure is an array of nodes. A node has two
	 * keys. "data" and "subtree". A subtree is a array of nodes.
	 * If multiple subtrees are found in a node then it will be merged into
	 * one subtree. Data is a object that contains a "href" attribute and a
	 * "text" attribute for the for the node link in the node. If the nodes
	 * evolve to be more complex in the future we may have to change the
	 * structure of this but it will work for now. :)
	 */
	structure:	function() {
		if( !arguments[0] )
			debug('Turning tree into data structure');
		var group = arguments[0] ? arguments[0] : this.tree;
		return $A(document.getDirectChildrenByTagName('li', group)).collect((function(li) {
			var backend = li.backend;
			var href = backend.link.getAttribute('href') == '#' ?
				backend.link_backup_href :
				backend.link.getAttribute('href');
			return $H({
				data:	   $H({
					text:   backend.link.innerHTML,
					href:   href
				}),
				subtree:	$A(document.getDirectChildrenByTagName('ul', li)).collect((function(subtree) {
					return this.structure(subtree)
				}).bind(this)).flatten()
			});
		}).bind(this));
	}
});

/**
 * Class to represent the individual nodes on the JSTree
 */
JSTree.ListItem = Class.create();
Object.extend(JSTree.ListItem.prototype, ObservableMethodProvider);
Object.extend(JSTree.ListItem.prototype, {

	/**
	 * Will take an existing node in a list item and create a object that
	 * manages that node.
	 */
	initialize:	function(li, tree) {
		debug('Initializing tree node');
		this.tree	       = $(tree);
		this.element	    = $(li);
		this.element.backend    = this;
		this.reparent();
		this.link = document.getDirectChildrenByTagName('a',$(li))[0];

		this.has_subtree() ?
			this.add_subtree_control(this.open_control_content(),
				this.observable_method('expand')) :
			this.add_subtree_control_spacer();
	},

	reparent:	function() {
		debug('Reparenting');
		if( this.element.parentNode &&
			this.element.parentNode.parentNode &&
			this.element.parentNode.parentNode.backend) {
			debug('Node has parent node');
			this.parent = this.element.parentNode.parentNode.backend;
			debug('Finished reparenting');
		}
	},

	/**
	 * Indicates if this node contains a subtree
	 */
	has_subtree:	function() {
		return $A(this.element.getElementsByTagName('ul')).length > 0;
	},

	/**
	 * Will expand this node. Only works if the node contains a subtree
	 */
	expand:		function() {
		debug('Expanding node');
		if( this.parent ) {
			this.parent.expand();
		}
		if( !this.has_subtree() )
			return;
		document.getDirectChildrenByTagName('ul', this.element).each(
			function(child) {
				if( !Element.visible(child) )
					Element.show(child);
			});
		Element.remove(this.subtree_control);
		this.add_subtree_control(this.close_control_content(),
			this.observable_method('collapse'));
	},

	/**
	 * Will collapse this node. Only works if the node contains a subtree
	 */
	collapse:	function() {
		debug('Collapsing node');
		document.getDirectChildrenByTagName('ul',this.element).each(
			function(child) {
				if( Element.visible(child) )
					Element.hide(child);
			});
		Element.remove(this.subtree_control);
		this.add_subtree_control(this.open_control_content(),
			this.observable_method('expand'));
	},

	select:		function() {
		debug('Selecting node');
		this.tree.unselect_all();
		Element.addClassName(this.link, 'selected');
	},

	unselect:	function() {
		debug('Unselecting node');
		Element.removeClassName(this.link, 'selected');
	},

	/**
	 * Will enable editing mode for this list item
	 */
	make_editable:	function() {
		debug('Making tree node editable');
		if( !this.edit_control ) {
			debug('Edit control does not exist...Adding');
			this.add_edit_control();
		}

		// NOTE: Save current state for restoring
		this.link_backup_href = this.link.getAttribute('href');
		this.link_backup_onclick = this.link.onclick;

		// NOTE: Make link not clickable
		this.link.setAttribute('href', '#');
		this.link.onclick = function() { return false; }

		// NOTE: Enable in-place editor
		this.link_editor = new Ajax.InPlaceEditor(this.link, {
			cols:		   15,
			externalControl:	this.edit_control,
			saveText_Callback:      (function(form, value,
				onSuccess, onFailure) {
				onSuccess(value);
				if( this.tree.option('onEdit') ) {
					this.tree.option('onEdit')(this.link,
						this.tree.structure());
				}
			}).bind(this)
		});
	},

	/**
	 * Will disable editing mode for this list item
	 */
	make_readonly:	function() {
		debug('Making tree readonly');
		if( this.link_backup_href ) {
			this.link.setAttribute('href', this.link_backup_href);
			this.link.onclick = this.link_backup_onclick;
		}
		this.link_editor.dispose();

		this.link_editor = this.link_backup_href =
			this.link_backup_onclick = null;
	},

	/**
	 * Will add a subtree control to this list item. Used when initializing
	 * this object.
	 */
	add_subtree_control:function(content, observer) {
		debug('Add an open or close subtree control');
		this.subtree_control = content
		Element.addClassName(this.subtree_control, 'subtree_control');
		Event.observe(this.subtree_control, 'click', observer);
		this.element.insertBefore(this.subtree_control,
			this.element.firstChild);
	},

	/**
	 * Will add the edit control right after the nodes link
	 */
	add_edit_control:function() {
		debug('Add edit button for in-place editor');
		this.edit_control = JSTree.ListItem._edit_control ?
			JSTree.ListItem._edit_control.cloneNode(true) :
			(this.tree.option('edit_img') ?
				$image(this.tree.option('edit_img')) :
				$button('Edit'));
		if( !JSTree.ListItem._edit_control )
			JSTree.ListItem._edit_control =
				this.edit_control.cloneNode(true);
		Element.addClassName(this.edit_control, 'edit_control');
		this.link.parentNode.insertBefore(this.edit_control,
			this.link.nextSibling);
	},

	/**
	 * Will add a subtree control spacer for nodes that have no subtree
	 */
	add_subtree_control_spacer:function() {
		debug('Adding spacer for node without subtree');
		var spacer = JSTree.ListItem._subtree_control_spacer ?
			JSTree.ListItem._subtree_control_spacer.cloneNode(true) :
			$E('span',{},{},['spacer'],this.open_control_content());
		if( !JSTree.ListItem._subtree_control_spacer )
			JSTree.ListItem._subtree_control_spacer =
				spacer.cloneNode(true);
		this.element.insertBefore(spacer, this.element.firstChild);
	},

	/**
	 * Will get the content for an open subtree control
	 */
	open_control_content:function() {
		var e = JSTree.ListItem._open_control_content ?
			JSTree.ListItem._open_control_content.cloneNode(true) :
			(this.tree.option('open_img') ?
				$image(this.tree.option('open_img'), {}, {marginRight: '5px'}) :
				$button('+', {}, {width: '25px', marginRight: '5px'}));
		if( !JSTree.ListItem._open_control_content )
			JSTree.ListItem._open_control_content = e.cloneNode(true);
		return e;
	},

	/**
	 * Will get the content for an open subtree control
	 */
	close_control_content:function() {
		var e = JSTree.ListItem._close_control_content ?
			JSTree.ListItem._close_control_content.cloneNode(true) :
			(this.tree.option('close_img') ?
				$image(this.tree.option('close_img'), {}, {marginRight: '5px'}) :
				$button('-', {}, {width: '25px', marginRight: '5px'}));
		if( !JSTree.ListItem._close_control_content )
			JSTree.ListItem._close_control_content =
				e.cloneNode(true);
		return e;
	}
});

JSTree.NewNodeObserver = Class.create();
Object.extend(JSTree.NewNodeObserver.prototype, {
	initialize:	function(tree) {
		debug('Setting up tree observer');
		this.tree = tree;
	},
	onStart:	function(eventName, draggable, event) {
		// NOTE: Ignore elements that are not ours
		if(!Element.hasClassName(draggable.element,'nodable')) {return;}

		debug('Start dragging of new category or link');

		// NOTE: Clone element and leave clone behind
		var clone = draggable.element.cloneNode(true);
		clone._backup_href = draggable.element._backup_href;
		clone._backup_onclick = draggable.element._backup_onclick;
		JSTree._nodable.push(clone);
		new Draggable(clone, {revert: true});
		draggable.element.parentNode.insertBefore(clone, draggable.element);
		debug('Clone created');

		// NOTE: Special handling for new category
		if( Element.hasClassName(draggable.element, 'new_category') ) {
			debug('Turn category icon into real link');
			Element.removeClassName(draggable.element, 'new_category');
			Element.removeClassName(draggable.element, 'button');
			Element.addClassName(draggable.element, 'category');
			Element.clear(draggable.element);
			draggable.element.appendChild($T('New Category'));
		}

		// NOTE: Wrap element in ListItem and initialize
		debug('Turn link into real node');
		var li = new JSTree.ListItem($E('li', {}, {},
			[], draggable.element), this.tree);
		this.tree.tree.appendChild(li.element);
		debug('Link finished converting to node');
		if( draggable.element._backup_href ) {
			draggable.element.href = draggable.element._backup_href;
			draggable.element.onclick = draggable.element._backup_onclick;
		}

		debug('Add new node to sortable list and make editable');
		var sortable_options = Sortable.options(this.tree.tree);
		Droppables.add(li.element, {
			overlap:	'vertical',
			containment:    false,
			onHover:	sortable_options.onHover,
			greedy:	 true
		});
		this.tree.nodes.push(li);
		li.make_editable();
		draggable.element = li.element;
		sortable_options.draggables.push(draggable);
		sortable_options.droppables.push(li.element);
	},
	onEnd:	function(eventName, draggable, event) {
		// NOTE: Ignore elements that are not ours
		if( !draggable.element.backend ) {
			debug('Ignoring');
			return;
		}

		debug('Dropped new node on tree');
		var link = draggable.element.backend.link;
		Element.removeClassName(link, 'nodable');
		JSTree._nodable = JSTree._nodable.without(link);
		debug('Link made unnodable');
	}
});

/**
 * Will create an element with the given attributes. This is a wrapper around
 * document.createElement designed to make the code a bit smaller.
 * attributes and styles are hashes and if not specified will be ignored.
 * The children will be appended inside the new element
 */
function $E(tag, attributes, styles, classes /*, children...*/) {
	debug('Creating '+tag+' element');
	var e = $H(attributes).inject(document.createElement(tag),
		function(e, attr) {
			e.setAttribute(attr.key, attr.value);
			return e;
		});
	e = $H(styles).inject(e, function(e, style) {
			e.style[style.key] = style.value;
			return e;
		});
	e = $A(classes).inject(e, function(e, cls) {
		Element.addClassName(e, cls);
		return e;
	});
	var children = $A(arguments).slice(4);
	return $A(children).inject(e, function(e, child) {
		if( typeof(child) == 'string' ) {
			child = $T(child);
		}
		e.appendChild(child);
		return e;
	});
}

/**
 * Simple wrapper around document.createTextNode() to save a few characters.
 */
function $T(text) {
	debug('Creating text node with "'+text+'" text node');
	return document.createTextNode(text);
}

/**
 * A wrapper around $E which will create a button with the given text
 */
function $button(text, attributes, styles, classes) {
	debug('Creating button with "'+value+'" text');
	return $E('input',
		Object.extend({type: 'button', value: text}, attributes),
		Object.extend({margin: '0px', padding: '0px'}, styles),
		classes);
}

/**
 * A wrapper around $E which will create an image with the given source
 */
function $image(src, attributes, styles, classes) {
	debug('Creating image with "'+src+'" source');
	return $E('img', Object.extend({src: src}, attributes), styles,
		classes);
}

/**
 * Will get only direct children that match the given tag name in the
 * parentElement. If no parent element is given then it assumes document.body
 */
document.getDirectChildrenByTagName = function(tagName, parentElement) {
	var children = ($(parentElement) || document.body).childNodes;
	return $A(children).inject([], function(elements, child) {
		if (child.tagName != null &&
			child.tagName.toLowerCase() == tagName)
			elements.push(child);
		return elements;
	});
};

Object.extend(Element, {
	clear:	  function(element) {
		element = $(element);
		while(element.childNodes.length > 0) {
			Element.remove(element.firstChild);
		}
	}
});

Object.extend(Sortable, {
	serialize:	function(element) {
		return element.innerHTML;
	},
	onHover:		function(element, dropon, overlap) {
		var jstree = Sortable.jstree(dropon);
		jstree._last_dragged = element;
		Sortable.clear_indicator(jstree);
		if( overlap > 0.66 ) {
			debug('We are above the item');
			Sortable.set_indicator(jstree, dropon, 'above');
		} else if( overlap < 0.33 ) {
			debug('We are below the item');
			Sortable.set_indicator(jstree, dropon, 'below');
		} else {
			debug('We are right on the item');
			Sortable.set_indicator(jstree, dropon, 'nested');
		}
	},
	set_indicator:	function(jstree, dropon, type) {
		jstree._last_indicated = dropon;
		jstree._last_indicated_type = type;
		switch(type) {
			case 'above':
				dropon.style.borderWidth = '0px';
				dropon.style.borderTopWidth = '2px';
				dropon.style.borderStyle = 'solid';
				dropon.style.borderColor = '#000000';
				break;
			case 'below':
				dropon.style.borderWidth = '0px';
				dropon.style.borderBottomWidth = '2px';
				dropon.style.borderStyle = 'solid';
				dropon.style.borderColor = '#000000';
				break;
			case 'nested':
				Element.addClassName(dropon.backend.link, 'nested_hover');
				break;
		}
	},
	clear_indicator:function(jstree) {
		if( jstree._last_indicated ) {
			Element.removeClassName(jstree._last_indicated.backend.link,'nested_hover');
			jstree._last_indicated.style.borderWidth = '0px';
		}
	},
	jstree:		function(node) {
		return Sortable._findRootElement(node).backend;
	}
});

/**
 * Modifies the default behaviour to the in-place editor to simply make a
 * callback instead of doing the AJAX call itself. This gives more control to
 * JSTree allowing us to pass that control onto the client code. They can make
 * an AJAX call if they want.
 */
Object.extend(Ajax.InPlaceEditor.prototype, {
	/**
	 * Basically remove "url" from the arguments and make it an option. If
	 * it exists then use previous behavior. If not then use callback. Also
	 * will remove the "Click Here to Edit" functionality if an
	 * externalControl is available.
	 */
	old_initialize:	Ajax.InPlaceEditor.prototype.initialize,
	initialize:	function(element, options) {
		var url = null;
		if( typeof(options) == 'string' ) {
			url = options;
			options = arguments[2];
		} else {
			url = options.url;
		}
		options.url = null;
		this.old_initialize(element, url, options);

		if( options.externalControl ) {
			this.element.title = null;
			Event.stopObserving(this.element, 'click',
				this.onclickListener);
			Event.stopObserving(this.element, 'mouseover',
				this.mouseoverListener);
			Event.stopObserving(this.element, 'mouseout',
				this.mouseoutListener);
		}
	},

	/**
	 * If the saveText_Callback function is set we call it. Otherwise we
	 * use the old behaviour.
	 */
	old_onSubmit:	Ajax.InPlaceEditor.prototype.onSubmit,
	onSubmit:	function() {
		if( this.url == null ) {
			this.onLoading();
			if( this.options.saveText_Callback ) {
				this.options.saveText_Callback(this.form,
					this.editField.value,
					(function(value) {
						Element.update(this.element, value);
						this.onComplete();
					}).bind(this),
					this.onFailure.bind(this));
			}
			return false;
		} else {
			return this.old_onSubmit();
		}
	},

	/**
	 * Disable the retarded hover effects they assume we want (and which
	 * cause IE to barf, and seems to slow things down)
	 */
	enterHover:	Prototype.emptyFunction,
	leaveHover:	Prototype.emptyFunction
});
__css/jstree.css__
ul.jstree,
ul.jstree ul {
	list-style-type: none;
	width: 95%;
}

ul.jstree {
	padding: 0px;
	margin-left: 0px;
	margin-right: 0px;
}

ul.jstree li {
	white-space: nowrap;
}

ul.jstree form {
	display: inline;
}

ul.jstree .edit_control {
	margin-left: 10px;
	display: none;
}

ul.jstree a {
	color: black;
}

ul.editable a {
	text-decoration: none;
}

ul.editable a.node_link {
	cursor: move;
}

ul.editable .edit_control {
	display: inline;
	cursor: pointer;
}

ul.jstree a.subtree_control {
	text-decoration: none;
	cursor: pointer;
}

ul.jstree .selected {
	background-color: #ffff00;
}

.spacer {
	visibility: hidden;
}

.functionbar {
	margin-top: 5px;
	margin-bottom: 5px;
	text-align: center;
}

.functionbar span {
	padding: 25px;
	padding-bottom: 0px;
}

.button {
	border-width: 1px;
	border-color: #000000;
	border-style: outset;

	padding: 0px;

	background-color: #e4e4e4;
	color: #000000;
	text-decoration: none;
}

.category {
	text-decoration: none;
	cursor: default;
}

.nested_hover {
	font-weight: bold;
}

.functionbar img {
	padding: 2px;
	margin-left: 2px;
	margin-right: 2px;
	line-height: 300%;
}

a img {
	border-width: 0px;
}
