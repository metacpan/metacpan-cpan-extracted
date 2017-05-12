package HTML::Widget::SideBar;

use strict; # Or get downvoted at Perl Monks :)

use CGI;
use Tree::Numbered;
use base 'Tree::Numbered';
use constant DEFAULT_STYLES => {bar => 'sidebar', list => 'list', 
				item => 'item'};

our $VERSION = '1.02';

# package stuff:
my $cgi = CGI->new;    # Just for HTML shortcuts.

#############################################################
# Actions - callbacks that generate javascript for onClick events.
# See POD below for use.

# A default action generator. See the args passed to it:
my $default_action = sub {
    my $self = shift;
    my ($level, $unique) = @_;

    return '';
};

# A show/hide (toggle) action:
my $toggle_action = sub {
    my $self = shift;
    my ($level, $unique) = @_;

    return "sb_toggle($level, 'sub_" . $self->getUniqueId . "')";
};

##################################################
# Constructors:

# <new> constructs a new tree or node.
# Arguments: By name: 
#     value - the value to be stored in the node. Used as caption.
#     action - a perl sub that is responsible for generating Javascript
#              code to be executed on click. The sub will be called as 
#              a method ($self->generator) so you have access to the
#              object data when you construct the action (optional).
#     URL - a url to navigate to on click (optional).
#     render_hidden - Should submenus be rendered at all? If true,
#                     The submenus will be rendered and set to hidden via CSS.
# Returns: The tree object.

sub new {
    my $parent = shift;
    my %args = @_;

    my $parent_serial;
    my $class;
    
    my %nargs = (Value => $args{value});
    # has URL propagation:
    $nargs{URL} = $args{URL} if (exists $args{URL});
    # no active propagation:
    $nargs{Active} = (exists $args{active}) ? $args{active} : 0;

    $nargs{RenderHidden} = 
        (exists $args{render_hidden}) ?
                $args{render_hidden} :
                1;

    my $properties = $parent->SUPER::new(%nargs);

    my $action = $args{action};
    if ($class = ref($parent)) {
	$properties->{_Parent} = $parent->{_Serial};
	$action = $parent->getAction unless (defined $action);
    } else {
	$class = $parent;
	$properties->{_Parent} = 0;
    }

	# Add basic set of fields:
	$properties->addField(Changed => 'yes');
	$properties->addField('Action'); # Does nothing if exists.
	$properties->addField(HTML => undef);
	$properties->addField(Script => undef);
	
    	return $properties;
}

# <convert> takes a Tree::Numbered and makes it a HTML::Widget::SideBar.
# Arguments: By name:
#     tree - the tree to be converted to a sidebar.
#     action - an action generator, as described in <new>.
#     active_num - the number of the active item (if any).
#     parent - (internal use only) sets the _Parent property.
#     base_URL - a url that will be appended later by a relative one. 
# Returns: the tree, modified and re-blessed as a HTML::Widget::SideBar.

sub convert {
    my $parent = shift;
    my $class = (ref($parent) or $parent);

    my %args = @_;
    my ($tree, $parent_num, $active_num) = 
	@args{'tree', 'parent', 'active_num'};
    my $def_action = (exists $args{action}) ? $args{action} : $default_action;
    # remove undef:
    $parent_num ||= 0;
    $active_num ||= 0;

    # Won't change existing setting of 'Action' and 'URL' if it's there.
    $tree->addField(Changed => 'yes');
    $tree->addField(HTML => undef);
    $tree->addField(Script => undef);
    $tree->addField('Action', $def_action);
    $tree->addField('URL', $args{base_URL}) if (exists $args{'base_URL'});
    $tree->addField('Active');
    $tree->addField('RenderHidden', 1);
    $tree->setField('Active', 1) if ($active_num == $tree->getNumber);
    $tree->{_Parent} = $parent_num;

    for (@{ $tree->{Items} }) {
	my %inargs = (tree => $_, action => $def_action, 
		      parent => $tree->getNumber,
		      active_num => $args{active_num});
	$inargs{base_URL} = $args{base_URL} if (exists $args{'base_URL'});
	$parent->convert(%inargs);
    }
    return bless $tree, $class;
}

# <readDB> constructs a new HTML::Widget::SideBar from a table in a DB using 
#  Tree::Numbered::DB.
# Arguments: By name:
#     source_name - table name.
#     source - a DB handle to work with.
#     action - an action generator, as described in <new>.
#     cols - ref to a hash with mappings (see Tree::Numbered::DB).
#     URL_col - shortcut to add the URL column to the cols.
#     active_num - number of the active item if any.
# Returns: the tree, modified and re-blessed as an HTML::Widget::SideBar.

sub readDB {
    my $parent = shift;
    my $class = (ref($parent) or $parent);
    my %args = @_;

    my ($table, $dbh) = @args{'source_name', 'source'};
    return undef unless ($table && $dbh);

    # Make shure there's always an action, even a void one.
    my $def_action = (exists $args{action}) ? $args{action} : $default_action;
    my $cols = $args{cols} || {};
    $cols->{URL_col} = $args{URL_col} if ($args{URL_col});
    # Default creation of Value is no longer used because we request a field.
    $cols->{Value_col} ||= 'name';

    require Tree::Numbered::DB 1.01; 
    my @args = ($table, $dbh, $cols);
    #read -> revert -> convert: construct a DB tree, loose DBness, make sidebar
    my $tree = Tree::Numbered::DB->read(@args);
    $tree->revert;
    return $class->convert(tree => $tree, 
			   action => $def_action, 
			   active_num => $args{active_num});
}


# <_generate> creates the HTML that shows the sidebar.
# Arguments: By name:
#     styles - alternative set of styles. Default will be used if this isn't
#              supplied or malformed.
#     caption - a starting caption. Optional.
#     expand - if true, all branches will be displayed.
#     no_ie - if false you'll get some extra code to make IE6 comply.
# Returns: nothing, works on the object; called from either <getHTML> or <getScript>.



sub _generate {
    my $self = shift;
    my %args = @_;

    my $caption = (exists $args{caption}) ? $args{caption} : $self->getValue;
    $caption = $self->getFullCap($args{no_ie}, $caption);

    my $styles = $args{styles};
    $styles = {} unless (ref $styles eq 'HASH');
    my $def = DEFAULT_STYLES;
    foreach (keys %$def) {
	$styles->{$_} ||= $def->{$_}
    }

    my $unique = $self->getUniqueId;
    my $action = $self->getAction()->($self, -1, $unique);
    $action =~ s/([^;])\s*$/$1;/; # Always end with ';' for future appends.
    my @html; # return value.

    push @html, $cgi->start_div({-id => $styles->{bar}}), $caption;
    my $js_buffer = "";
    # Here comes the smart recursive stuff:
    $self->buildList(
        level => 0,
        expand => $args{expand}, 
        no_ie => $args{no_ie}, 
        unique => $unique, 
        html => \@html, 
        styles => \%$styles,
        js_code => \$js_buffer,
        );
    push @html, $cgi->end_div;

    # return @html if (wantarray);
    # return (\@html, $js_buffer);
	$self->setHTML(\@html);
	$self->setScript($js_buffer);
	$self->allProcess( sub { $_[0]->setChanged(0) } );
}

# <buildList> Helper for <getHTML> (actually does the real work).
#  Recursively builds lists for each submenu and pushes the HTML into
#  @html which is used as a stack.
# Arguments: $level - the submenu's level (main is 0),
#            $expand - should all nodes be expanded or active branch only?
#            $unique - the menu's unique identifier. This is an argument so 
#                      changing the uniquifing rule, will only be in <getHTML>.
#            $html - a reference to the stack.
#            %styles - a hash of style names.
# Returns: Nothing. Modifies stack directly.

sub buildList {
    my $self = shift;
    my $serial = $self->{_Serial};
    my %args = (@_);
    my $level = $args{level};
    my $expand = $args{expand};
    my $no_ie = $args{no_ie};
    my $unique = $args{unique};
    my $html = $args{html};
    my %styles = %{$args{styles}};
    my $js_code = $args{js_code};
    # my ($level, $expand, $no_ie, $unique, $html, %styles) = @_;
    
    my $next_level = $level + 1; # why recalculate this again and again?

    my @list;
    my $selfId = $self->getUniqueId;
    my ($start_tag, $end_tag) = genListCode($styles{list}, $selfId,
					    ($expand ||$self->isActiveBranch));
    push @$html, $start_tag;
    # Code for active sidebar. see POD.
    $$js_code .= "openLists.push(getCrossBrowser('sub_$selfId'));\n"
	if (!$expand && $self->isActiveBranch && $level);

    $self->savePlace;
    $self->reset;

    while (my $item = $self->nextNode) {
		my $onClick = $item->getAction()->($item, $level, $unique);
		my $caption = $item->getFullCap('no_ie');

		# start finding the list-item's HTML attributes:
		my $attr = {};
		if ($onClick) {
		    $onClick =~ s/([^;])\s*$/$1;/;
	    	$attr->{-onClick} = $onClick;
		}

		my $style = $styles{item};
		if ($styles{"level$level"}) {
	    	$style = $styles{"level$level"};
		}
		
		# Active items get their own class, always.
		$style .= 'Active' if ($item->getActive);
		my $styleOver = $styles{"${style}Over"} || 
	    	$styles{"level${level}Over"} || $styles{itemOver};
		if ($styleOver) {
	    	# Dynamically change class on mouseover. On Mozilla you can just
	    	# Create a :hover CSS pseudo-class.
	    	$attr->{-onMouseOver} = "this.className='$styleOver'";
	    	$attr->{-onMouseOut} = "this.className='$style'";
		}
		$attr->{-class} = $style;

		push @$html, ($no_ie) ? $cgi->start_li($attr) : $cgi->start_li();                
	    
    	push @$html, ($no_ie) ? $caption : $cgi->span($attr, $caption);
		
		# recursive stuff again: Renders sub-lists if needed.
		if ($item->childCount() && ($item->getRenderHidden() || $expand || $item->isActiveBranch()) ) {
		    push @$html, $cgi->br();
	    	$item->buildList(
            	    level => $next_level, 
                	expand => $expand, 
                	no_ie => $no_ie, 
                	unique => $unique,
                	html => $html,
                	styles => \%styles,
                	js_code => $js_code,
            );
		}
    	push @$html, $cgi->end_li();
    }
	
    $self->restorePlace;
    push @$html, $end_tag;
}

# <getFullCap> generates a caption that is a link if a link is wanted.
# Arguments: $no_ie - if force will force a link (useful for using :hover CSS).
#            $caption - bare caption to optionally override a node's value.
# Returns: a string containing the ready HTML caption.
sub getFullCap {
    my $self = shift;
    my ($no_ie, $caption) = @_;
    my $value = $caption || $self->getValue;
    my $href = $self->getURL || '"javascript:void(0)"';
    if ($no_ie && !$self->getURL) { return $value; }
    else { return "<a href=$href>$value</a>";}
}

# <genListCode> generates openning and closing tags for a main/nested list.
# Arguments: $class - the list's CSS class.
#            $unique - the sidebar's unique identifier - see POD.
#            $expand - true if the list is visible.
# Returns: a two item list with start and end tags for a list. push items 
#   between the two to create a full list.
sub genListCode {
    my ($class, $unique, $expand) = @_;
    my $args = {};
    $args->{-style} = 'display: none' unless ($expand);
    $args->{-class} = $class;
    $args->{-id} = "sub_$unique";
    return ($cgi->start_ul($args), $cgi->end_ul);
}

# <getUniqueId> returns the html suffix id of the menu.
# Arguments: None.
# Returns: A unique suffix for HTML names which includes the lucky number and
#          the node's serial number.

sub getUniqueId {
    my $self = shift;
    return "$self->{_LuckyNumber}__$self->{_Serial}";
}

# <setField> adds the handling of the 'changed' flag to the inherited sub.
# Arguments and return value are the same as the inherited sub.

sub setField {
	my $self = shift;
	my $field = shift;

	my $rv = $self->SUPER::setField($field, @_);
	if ($rv && $field ne 'Changed') { 
		$self->setChanged('yes') ; 
	}

	return $rv;
}

# <getHTML> will return the HTML code for the sidebar, generating it if necessary.
# Arguments: same as for <_generate>.
#In list context returns a list of HTML lines to print. In scalar
#     context returns a reference to same list.

sub getHTML {
	my $self = shift;

	# Do we need to regenerate?
	my $regen = $self->getChanged;
	unless ($regen) {
		$self->deepProcess (sub { $$_[1] = 1 if $_[0]->getChanged }, \$regen);
		# Yeah, this isn't very efficient, we need a recursive sub that can 
		# stop at a condition. I'll modify Tree::Numbered to do that after the
		# exam in differential equations, maybe :)
	}

	$self->_generate(@_) if $regen;
	my $html = $self->getField('HTML');
	
	# Backwards compatibility issues prompted this:
	return @$html if wantarray;
	return $html;
}
	
# <getScript> will return the JavaScript code for the sidebar, generating it if necessary.
# Arguments: same as for <_generate>.
# In list context returns a list of HTML lines to print. In scalar
#     context returns a reference to same list.

sub getScript {
	my $self = shift;

	# Do we need to regenerate?
	my $regen = $self->getChanged;
	unless ($regen) {
		$self->deepProcess (sub { $$_[0] = 1 if $_[0]->getChanged }, \$regen);
	}

	$self->_generate(@_) if $regen;
	return $self->getField('Script');
}

# <setAction> sets the action on an item. if no action is given, the default 
#  do-nothing action is used.
# Arguments: $action - an action, or nothing - implies default.
# Returns: Nothing.

sub setAction {
    my $self = shift;
    my $action = shift;
    
    $action ||= $default_action;
    $self->setField('Action', $action);
}

# <setToggleAction> sets the action to the stock toggle action.
sub setToggleAction {
    my $self = shift;
    $self->setField('Action', $toggle_action);
}

# <set/getURL> are here to make sure nobody dies when they're called even if
#   the field doesn't exist.

sub getURL {
    my $self = shift;
    return $self->getField('URL');
}

sub setURL {
    my $self = shift;
    return $self->setField('URL', @_);
}

# <setActive> Supplies a default value to the Active field.
# Arguments: $arg - optional value for Active. default is 1.
# Returns: the new value of Active.
sub setActive {
    my $self = shift;
    my $arg = @_ ? shift : 1;
    return $self->setField('Active', $arg);
}

# <isActiveBranch> returns true if any decendant of a node is active.
sub isActiveBranch {
    my $self = shift;
    return 1 if $self->getActive;
    
    foreach (@{$self->{Items}}) { # Yes, it's ugly.
	return 1 if $_->isActiveBranch;
    }
    return 0;
}

# <baseJS> spits out some useful JS for toggling menus on/of. See POD.
# Arguments: None.
# Returns: A huge multiline string containing some good JS.
sub baseJS {
    return <<EndJS;
function getCrossBrowser(name) {
	return document.getElementById(name); //Now it works on all of them...

}

var openLists = new Array();	//A stack of open menus.

function sb_toggle (level, name) {
	var smenu = getCrossBrowser(name);

	if (smenu.style.display != "block") {
	    hideLists(level);
	    smenu.style.display = "block";
	    openLists.push(smenu);	
	} else {
	    hideLists(level);
	}
}

function hideLists(level) {
	for (i = openLists.length - 1; i >= level; i--) {
		openLists[i].style.display = "none";
		openLists.pop();
	}
}

EndJS

}

# <deepBlueCSS> is an example for the CSS used to format a real nice sidebar.
#   It's taken from a real production site I made. Pass it through buildCSS
#   (below) after you tweaked it a bit to fit your needs.
# Arguments: None.
# Returns: a hash of hashes. See buildCSS.
sub deepBlueCSS {
    return {
	'#nav' => {	
	    position => 'absolute',
	    overflow => 'auto',
	    'z-index' => '1',
	    top => '0px',
	    right => '0px',
	    background => '#527BA5',
	    color => '#527BA5',
	    width => '19.1%',
	    height => '100%'},
	list => {	
	    'list-style-position' => 'outside',
	    'list-style-type' => 'none',
	    'text-align' => 'center',
	    'padding-top' => '0px',
	    'margin-right' => '0px',
	    'padding-left' => '0px',
	    'margin-left' => '0px',
	    display => 'block',
	    background => '#527BA5',
	    color => 'black',
	    'font-weight' => 'bold',
	    border => 'none',
	    width => '100%' }, 
	ul => {
	    'margin-right' => '20px',
	    'padding-left' => '0px' },
	navlink => {
	    display => 'block',
	    'text-align' => 'center',
	    background => '#2772BE',
	    color => 'black',
	    'font-weight' => 'bold',
	    border => 'solid 2px black',
	    margin => '5px 0% 5px 0%',
	    width => '93%',
	    'min-height' => '26px',
	    'line-height' => '26px'},
	navover => {
	    display => 'block',
	    'text-align' => 'center',
	    background => '#5298E0',
	    color => 'black',
	    'font-weight' => 'bold',
	    border => 'solid 2px black',
	    margin => '5px 0% 5px 0%',
	    width => '93%',
	    'min-height' => '26px',
	    'line-height' => '26px'}
    };
}

# <buildCSS> turns the datastructure provided by the previous two subs into 
#   valid CSS. Hash keys are converted into classes, and hash keys preceded 
#   with an underscore are converted into the "class:hover" syntax. For each 
#   one of these, the subhash is used for CSS property-value pairs.
# Arguments: $raw_css - The datastructure described above.
# Returns: A string containing the CSS.

sub buildCSS {
    my $self = shift; # Never used - class method.
    my $raw_css = shift;
    my $css = '';
    
    for my $class (keys %$raw_css) {
	my %props = %{ $raw_css->{$class} };
	my $hover = ($class =~ s/^_//) ? 1 : 0;

	$css .= ($class =~ /^\#/) ? $class : ".$class";
	$css .= "$:hover" if ($hover);
	$css .= " {\n";
	$css .= join "\n", 
	  map {my $under=$_; s/^_//; "\t$_: $props{$under};"}
	  keys %props;
	$css .= "\n}\n\n";
    }
    return $css;
}

1;

=head1 NAME

HTML::Widget::SideBar - Creates the HTML (and possibly some Javascript) for a navigational or otherwise active (hierarchical) sidebar for a web page.

=head1 SYNOPSYS

 use HTML::Widget::SideBar;
 use CGI; # Or something like that.

 # We are going to create a sidebar in which only the active (clicked) branch
 # is visible.
 my $tree = HTML::Widget::SideBar->new;
 $tree->setToggleAction;

 foreach (1..3) {
     my $list = $tree->append(value => "list$_");
     $list->append(value => "aaa$_", URL => "http://localhost/$_");
     $list->append(value => "bbb$_");
     $list->append(value => "ccc$_");
 }
 $tree->getSubTree(3)->setActive;

 print header, start_html(-style => $tree->buildCSS($tree->deepBlueCSS), 
                          -script => $tree->baseJS);
 print join "\n", $tree->getHTML(styles => {bar => 'nav',
                                            level0 => 'navlink',
                                            level0Over => 'navover'},
                                 expand => 1
                                 );
 print end_html;

=head1 DESCRIPTION

HTML::Widget::SideBar creates the HTML, and possibly some Javascript and CSS for a hirarchical side menu bar. It is very flexible, and allows you to create both simple navigational menus and complex dynamic sidebars with Javascript actions associated with items on the menu.

This module started as a hack on my Javascript::Menu, which makes them very similar, so if you got one of them, you'll use the other with no sweat, I think.

The module supports the notion of an 'active item' (usually the item denoting the page the user is viewing) and gives such item special treatment by marking it with a special CSS class and making it visible initially. It also has special support for selection menus where opening a branch closes all others.

=head2 What should you expect to see?

This depends greatly on your style definitions and action assignment (if you use that feature). Basically you'll have a vertical bar (which will take up as much of the screen as your CSS will allow). Inside that bar you'll have a tree of nested lists, and you can define the style for each level. When an item is clicked - its action is performed. A special predefined action allows you to show/hide child lists. 

By default only the active branch (the branch containing the active item) and the top level list will be visible. You can override this (see I<getHTML>).

=head2 Some naming rules

The sidebar will get an HTML id attribute. The default is 'sidebar' but this is changeable through I<getHTML>, as other naming rules.

Every list will be of class 'list' unless another class is given through I<getHTML>.

Every item in every list will be of the same class as all other items on the same level. The default is 'item' for all items, but you can set each level separately through I<getHTML>.

The active item's class name is its level's class name, appended with 'Active'.

Optionally, you may also set a mouseover style. For those of you who design for Mozilla, you really don't need that, just use the CSS pseudo-class :hover. For others, this will set the onMouseOver and onMouseOut attributes of an item to switch to and from that class.

=head2 Setting up the supporting code.

The sidebar created by this menu is formatted by CSS only. This means you'll have to supply it. I included a class method called buildCSS which takes a datastructure (described below) and turns it into CSS, and an example of a sidebar design in such datastructure (I used this design in production).

You may also want to use the toggling support (described below), and in this case you'll need some Javascript. This is given directly through I<baseJS>. You can use it straight or dump to a file and tweak it to suit you best.

=head2 But what are these actions and how do I generate them?

An action is basically a piece of Javascript code that is executed when the user clicks on an item. It is added to the onClick attribute of the item. However, actions in this module are not plain strings. Instead, an action is a subroutine reference that is called when the item's HTML code is being processed. It does what it does, then returns a string containing the Javascript code. In order for this sub to be able to do anything useful, it gets 3 arguments passed to it:

=over 4

=item 1 

A reference to the node being processed, so you can get information on the node via object methods.

=item 2 

The item's level in the hierarchy - the main menu is at level 0, the caption is at level -1.

=item 3 

The menu's unique suffix.

=back 

To make an item do nothing at all, use $item->I<setAction> with no parameters.

An important feature is that actions are inherited by new nodes from their parents. This allows you to set the beaveiour when you create the root element and not worry about it later on.

B<I18n alert!> What this all means is that you supply some of the strings the module will be working with. This means you could, by mistake, send strings that are mixed utf8 (perl's internal encoding) and your encoding. This might break things, so if something breaks, see that your strings are in one encoding. A bitch, eh? That's the way it is when you're not in an English-speaking country.

=head2 But I don't need all this stuff! I just want a navigational menu!

Cool. Just set the URL property of an object either in the constructor call or using I<setURL>. Menu items will be created with that URL. You can also combine a URL with an action.

=head2 Toggling a menu on/off.

As a convenience, a stock action is supplied that closes any list but the one clicked, and shows the clicked item's sublist if it has any. You can set this action on an item by the I<setToggleAction> method.

=head2 Building the tree

To get the tree that represents the structure of the sidebar, you have 3 ways:

=over 4

=item The hard way: HTML::Widget::SideBar->new

This builds the root node, with your desired value and action, URL or both (which will be the default for all children of this node). You add nodes with $tree->I<append>, and descend the hierarchy using methods found in the parent class - Tree::Numbered. For each element you supply the value (what is shown on the screen) and possibly an action.

=item The easier way: HTML::Widget::SideBar->convert

This just takes an existing Tree::Numbered and blesses it as a SideBar, adding an action to each node. This is easier if you already have the data structure for something else, and you want to make a menu out of it.

=item A nice shortcut: HTML::Widget::SideBar->readDB

If you have the module Tree::Numbered::DB (another one of mine) and you use it to store trees in a database, this method allows you to read such table directly and convert it to a menu. This is extremely useful, trust me :)

=back

=head2 Printing the code

Now all you have to do is $tree->getHTML. this will return an array so you can shift out the caption and locate it inside some div while the rest of the menu is located outside, avoiding width constraints. You can also push other stuff inside and create a widget for your script.

At any time you can also call $tree->getScript which will get you any Javascript code that was generated for the script. You won't get that code in the HTML array, which is new in version 1.02.

Calling any of the above methods after changing the tree (setting a field or adding a node but still not deleting one) will regenerate both the HTML and the script! Pay attention to their concurrency.

=head1 METHODS

This section only describes methods that are not the same as in Tree::Numbered. Obligatory arguments are marked.

=head2 Constructors

There are three of them:

=over 4

=item new (I<value> => $value, action => $action, URL => $url, render_hidden => $yes_or_not)

Creates a new tree with one root element, whose text is specified by the value argument. If an action is not supplied, the package's default do-nothig action will be used. You'll have to add nodes manually via the I<append> method.

If a URL is supplied, the node will be an anchor reffering to that URL.

If render_hidden is false, no sub-menus will appear unless the active item is inside a sub menu, in which case said sub-menu will appear.

=item convert (I<tree> => $tree, action => $action, base_URL => $url)

Converts a tree (given in the I<tree> argument) into an instance of Javascript::Menu. You will lose the original tree of course, so if you still need it, first use $tree->clone (see Tree::Numbered).

Giving a value to base_URL will copy that value to the URL field of every node in the tree. you can add to this using I<deepProcess>.

As in new, if action is not specified, one will be created for you. 

=item readDB (I<source_name> => $table, I<source> => $dbh, cols => $cols, action => $action, URL_col => $urlcol);

Creates a new menu from a table that contains tree data as specified in Tree::Numbered::DB. Arguments are the same as to I<new>, except for the required source_name, which specifies the name of the table to be read, and source, which is a DBI database handle. 

The cols argument allows you to supply field mappings for the tree (see Tree::Numberd::DB). URL_col is a shortcut for giving a mapping to a collumn containing the URLs of nodes (if that's what you need). If you provide this argument, it will override any collision in the $cols hashref.

=back

=head2 append (value => I<$value>, action => $action, URL => $url, render_hidden => $yes_or_not)

Adds a new child with the value (caption) $value. An action or a URL are optional, as described in I<new>. If one of those is not given, the value is taken from its parent (if its parent has one).

=head2 getHTML (styles => $styles, caption => 'altCaption', no_ie => true, expand => false)

This method returns the HTML for a sidebar whose caption is the node the method was invoked on. The sidebar's caption will be the root element's value unless the caption argument is given. All arguments are optional if the tree was not changet since the last call to either I<getHTML> or I<getScript>.

The expand argument, if true, will cause all nodes to be shown. Otherwise only the active branch us shown.

Unless you specify no_ie as true, the sidebar's caption will be wrapped up in a link so you cn use the :hover CSS pseudo-class on it.

the optional styles argument allows you to change default style names described above. This should be a hash reference, with a key for each style, specifying the new name. Like:

 styles => {bar => 'nav',
            level0 => 'navlink',
            level0Over => 'navover'}

You can give values to 'bar' (sidebar name), 'list' (list style) and 'item' (list item class). You can also give a certain level N its own class by giving a pair: levelB<N> => 'someclass'. A hover style for this property can be given either with 'levelB<N>Over', or the level's class appended with 'Over'. The first level is level 0. if a style called 'itemOver' is given, it will apply to all items regardless of their class, unless they already have some other mouseover setting.

In aray context will return the array as said, in scalar context will return a ref to that array.

=head2 getScript (styles => $styles, caption => 'altCaption', no_ie => true, expand => false)

Returns the script generated for the sidebar. All arguments are ignored if the tree was not changed since the last call to either I<getHTML> or I<getScript>. If the arguments are used, they mean the same as described under I<getHTML>

=head2 Accessors

HTML::Widget::SideBar adds to the methods of its base class the following accessors:

=over 4

=item getUniqueId

Returns the unique Id that the menu will recieve when built with this node as root.

=item getAction / setAction ($action)

Gets and sets the item's action. If no action is given to setAction, the default do-nothing action is used.

=item setToggleAction

Sets the item's action to the stock toggle action described above.

=item getURL / setURL ($url)

Gets and sets the item's URL.

=item getActive / setActive ($status)

Gets and sets the item's active status. if the argument for setActive is ommitted, 1 is assumed.

=back

=head2 Class methods

The following class methods help you generate supporting code for your menus:

=over 4

=item baseJS 

Returns the basic Javascript code for use with this module's toggle feature.

=item deepBlueCSS

Returns a datastructure for buildCSS. Using the properties provided by this function will result in a sidebar in shades of blue. You can tweak this to your satisfaction.

=item buildCSS ($css)

Takes a data structure and returns a string with valid CSS you can incorporate into your document. 

The data structure is as follows:

A main hash with one key for each element of the sidebar (bar, list, item etc). The value for each key is again a hash with CSS property - value pairs, like top => 1, left => 1 etc. If a key is preceded by an underscore, it is converted into the :hover definition for the class of that name (this should be a name given to one of the other classes).

=back

=head1 METHOD SUMMARY (NEW + INHERITED)

The following is a categorized list of all available meyhods, for quick reference. Methods that do not appear in the source of this module are marked:

=over 4

=item Object lifecycle:

new, readDB, *delete, *append.

=item Iterating and managing children:

*nextNode, *reset, *savePlace, *restorePlace, *childCount, *getSubTree, *follow

=item Generating code:

deepBlueCSS, buildCSS, baseJS, getHTML

=item Fields:

*addField, *removeField, setField, *setFields, *getField, *getFields, *hasField.

=back


=head1 BROWSER COMPATIBILITY

Tested on IE6 and Firefox 1.0PR and worked. On Konqueror it's OK too but not thoroughly tested. If you test it on other browsers, please let me know what is the result.

=head1 EXAMPLES

testbar.pl in the examples directory shows how it's done.
perl-begin.css in the same place is a full style sheet taken from a site that uses this module.

=head1 BUGS

Directly to the author, please.

=head1 SEE ALSO

Tree::Numbered, Tree::Numbered::Tools, Tree::Numbered::DB, Javascript::Menu

=head1 AUTHOR

Yosef Meller, E<lt>mellerf@netvision.net.ilE<gt>

=head1 CREDITS

Shlomi Fish added the render_hidden attribute, and some of the code that separates the script from the HTML. Also supplied the CSS for examples/perl-begin.css

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Yosef Meller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

Exception: the file examples/perl-begin.css is not by me and uses a different license. See the head of that file for details.

=cut
