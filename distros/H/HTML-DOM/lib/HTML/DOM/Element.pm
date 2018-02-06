package HTML::DOM::Element;

use strict;
use warnings;

use HTML::DOM::Exception qw 'INVALID_CHARACTER_ERR 
                             INUSE_ATTRIBUTE_ERR NOT_FOUND_ERR SYNTAX_ERR';
use HTML::DOM::Node 'ELEMENT_NODE';
use HTML'Entities;
use Scalar::Util qw'refaddr blessed weaken';

require HTML::DOM::Attr;
require HTML::DOM::Element::Form;
require HTML::DOM::Element::Table;
require HTML::DOM::NamedNodeMap;
require HTML::DOM::Node;
require HTML::DOM::NodeList::Magic;

our @ISA = qw'HTML::DOM::Node';
our $VERSION = '0.058';


{
	 # ~~~ Perhaps I should make class_for into a class method, rather
	 # than a function, so Element.pm can be subclassed. Maybe I'll
	 # wait until someone tries to subclass it. (Applies to Event.pm
	 # as well.) If a potential subclasser is reading this, will he
	 # please give me a holler?

	my %class_for = (
		'~text' => 'HTML::DOM::Text',
		 html   => 'HTML::DOM::Element::HTML',
		 head   => 'HTML::DOM::Element::Head',
		 link   => 'HTML::DOM::Element::Link',
		 title  => 'HTML::DOM::Element::Title',
		 meta   => 'HTML::DOM::Element::Meta',
		 base   => 'HTML::DOM::Element::Base',
		 isindex=> 'HTML::DOM::Element::IsIndex',
		 style  => 'HTML::DOM::Element::Style',
		 body   => 'HTML::DOM::Element::Body',
		 form   => 'HTML::DOM::Element::Form',
		 select => 'HTML::DOM::Element::Select',
		 optgroup=> 'HTML::DOM::Element::OptGroup',
		 option  => 'HTML::DOM::Element::Option',
		 input   => 'HTML::DOM::Element::Input',
		 textarea=> 'HTML::DOM::Element::TextArea',
		 button  => 'HTML::DOM::Element::Button',
		 label   => 'HTML::DOM::Element::Label',
		 fieldset=> 'HTML::DOM::Element::FieldSet',
		 legend  => 'HTML::DOM::Element::Legend',
		 ul      => 'HTML::DOM::Element::UL',
		 ol      => 'HTML::DOM::Element::OL',
		 dl      => 'HTML::DOM::Element::DL',
		 dir     => 'HTML::DOM::Element::Dir',
		 menu    => 'HTML::DOM::Element::Menu',
		 li      => 'HTML::DOM::Element::LI',
		 div     => 'HTML::DOM::Element::Div',
		 p       => 'HTML::DOM::Element::P',
		 map((
		   "h$_" => 'HTML::DOM::Element::Heading'
		 ), 1..6),
		 q       => 'HTML::DOM::Element::Quote',
		 blockquote=> 'HTML::DOM::Element::Quote',
		 pre       => 'HTML::DOM::Element::Pre',
		 br        => 'HTML::DOM::Element::Br',
		 basefont  => 'HTML::DOM::Element::BaseFont',
		 font      => 'HTML::DOM::Element::Font',
		 hr        => 'HTML::DOM::Element::HR',
		 ins       => 'HTML::DOM::Element::Mod',
		 del       => 'HTML::DOM::Element::Mod',
		 a         => 'HTML::DOM::Element::A',
		 img       => 'HTML::DOM::Element::Img',
		 object    => 'HTML::DOM::Element::Object',
		 param     => 'HTML::DOM::Element::Param',
		 applet    => 'HTML::DOM::Element::Applet',
		 map       => 'HTML::DOM::Element::Map',
		 area      => 'HTML::DOM::Element::Area',
		 script    => 'HTML::DOM::Element::Script',
		 table   => 'HTML::DOM::Element::Table',
		 caption => 'HTML::DOM::Element::Caption',
		 col     => 'HTML::DOM::Element::TableColumn',
		 colgroup=> 'HTML::DOM::Element::TableColumn',
		 thead   => 'HTML::DOM::Element::TableSection',
		 tfoot   => 'HTML::DOM::Element::TableSection',
		 tbody   => 'HTML::DOM::Element::TableSection',
		 tr      => 'HTML::DOM::Element::TR',
		 th      => 'HTML::DOM::Element::TableCell',
		 td      => 'HTML::DOM::Element::TableCell',
		 frameset=> 'HTML::DOM::Element::FrameSet',
		 frame   => 'HTML::DOM::Element::Frame',
		 iframe  => 'HTML::DOM::Element::IFrame',
	);
	sub class_for {
		$class_for{lc$_[0]} || __PACKAGE__
	}
}


=head1 NAME

HTML::DOM::Element - A Perl class for representing elements in an HTML DOM tree

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $elem = $doc->createElement('a');

  $elem->setAttribute('href', 'http://www.perl.org/');
  $elem->getAttribute('href');
  $elem->tagName;
  # etc

=head1 DESCRIPTION

This class represents elements in an HTML::DOM tree. It is the base class
for other element classes (see
L<HTML::DOM/CLASSES AND DOM INTERFACES>.) It implements the Element and
HTMLElement DOM interfaces.

=head1 METHODS

=head2 Constructor

You should normally use HTML::DOM's C<createElement> method. This is listed
here only for completeness:

  $elem = new HTML::DOM::Element $tag_name;

C<$elem> will automatically be blessed into the appropriate class for
C<$tag_name>.

=cut 

sub new {
	my $tagname = $_[1];

	# Hack to make parsing comments work
	$tagname eq '~comment'
	 and require HTML'DOM'Comment, return new HTML'DOM'Comment;

	# ~~~ The DOM spec does not specify which characters are invaleid.
	#     I think I need to check the HTML spec. For now, I'm simply
	#     letting HTML::Element do the insanity checking, and I'm turn-
	#     ing its errors into HTML::DOM::Exceptions. 
	my $ret;
	eval {
		$ret = bless shift->SUPER::new(@_), class_for $tagname;

		# require can sometimes fail if it’s part of a tainted
		# statement. That’s why it’s in a do block.
		$tagname =~ /^html\z/i
		 and do { require HTML'DOM }; # paranoia
	};
	$@ or return $ret;
	die HTML::DOM::Exception->new( INVALID_CHARACTER_ERR, $@);
}


=head2 Attributes

The following DOM attributes are supported:

=over 4

=item tagName

Returns the tag name.

=item id

=item title

=item lang

=item dir

=item className

These five get (optionally set) the corresponding HTML attributes. Note
that C<className> corresponds to the C<class> attribute.

=cut

sub tagName {
	uc $_[0]->tag;
}

sub id { shift->_attr(id => @_) }

sub title { shift->_attr(title => @_) }
sub lang  { shift->_attr(lang  => @_) }
sub dir   { lc shift->_attr(dir   => @_) }
sub className { shift->_attr(class => @_) }

=item style

This returns a L<CSS::DOM::Style> object, representing the contents
of the 'style' HTML attribute.

=cut

sub style {
	my $self = shift;
	($self->getAttributeNode('style') || do {
		$self->setAttribute('style','');
		$self->getAttributeNode('style');
	}) -> style;
}

=back

And there is also the following non-DOM attribute:

=over 4

=item content_offset

This contains the offset (in characters) within the HTML source of the
element's first child node, if it is a text node. This is set (indirectly)
by HTML::DOM's C<write> method. You can also set it yourself.

=back

=cut

sub content_offset {
	my $old = (my $self = shift)->{_HTML_DOM_offset};
	@_ and $self->{_HTML_DOM_offset} = shift;
	$old;
}


=head2 Other Methods

=over 4

=item getAttribute ( $name )

Returns the attribute's value as a string.

=item setAttribute ( $name, $value )

Sets the attribute named C<$name> to C<$value>.

=item removeAttribute ( $name )

Deletes the C<$name>d attribute.

=item getAttributeNode ( $name )

Returns an attribute node (L<HTML::DOM::Attr>).

=item setAttributeNode ( $attr )

Sets the attribute whose name is C<< $attr->nodeName >> to the attribute
object itself. If it replaces another attribute object, the latter is
returned.

=item removeAttributeNode ( $attr )

Removes and returns the C<$attr>.

=item getElementsByTagName ( $tagname)

This finds all elements with that tag name under the current element,
returning them as a list in list context or a node list object in scalar
context.

=item getElementsByClassName ( $names )

This finds all elements whose class attribute contains all the names in
C<$names>, which is a space-separated list; returning the elements as a
list in list context or a node list object in scalar
context.

=item hasAttribute ( $name )

Returns true or false, indicating whether this element has an attribute
named C<$name>, even one that is implied.

=item click() (HTML 5)

This triggers a click event on the element; nothing more.

=item trigger_event

This overrides L<HTML::DOM::Node>'s method to trigger a DOMActivate event
after a click.

=back

=cut

my %attr_defaults = (
	br => { clear => 'none' },
	td => { colspan => '1', rowspan=>1},
	th => { colspan =>  1,  rowspan=>1},
	form => {
		enctype => 'application/x-www-form-urlencoded',
		method => 'GET',
	},
	frame =>{frameborder  => 1,scrolling=> 'auto'},
	iframe=> {frameborder => 1,scrolling=>'auto'},
	'area'=> {'shape'         => 'rect',},
	'a' =>{'shape'            => 'rect',},
	'col'=>{ 'span'           =>  1,},
	'colgroup'=>{ 'span'      =>  1,},
	'input',{ 'type'         => 'TEXT',},
	'button' =>{'type'        => 'submit',},
	'param' =>{'valuetype'    => 'DATA'},
);
# Note: The _HTML_DOM_unspecified key used below points to a hash that
#       stores Attr objects for implicit attributes in this list.

sub getAttribute {
	my $ret = $_[0]->attr($_[1]);
	defined $ret ? "$ret" : do{
		my $tag = $_[0]->tag;
if(!$_[0]->tag){warn $_[0]->as_HTML; Carp::cluck}
		return '' unless exists $attr_defaults{$tag}
			and exists $attr_defaults{$tag}{$_[1]}
			or $tag eq 'html' and $_[1] eq 'version'
			   and exists $_[0]->{_HTML_DOM_version};
		$_[1] eq 'version'
			? $_[0]->{_HTML_DOM_version}
			: $attr_defaults{$tag}{$_[1]}
	};
}

sub setAttribute {
# ~~~ INVALID_CHARACTER_ERR
	my $self = shift;

	# If the current value is an Attr object, we have to modify that
	# instead of just assigning to the attribute.
	my $attr = $self->attr($_[0]);
	if(defined blessed $attr && $attr->isa('HTML::DOM::Attr')){
		$attr->value($_[1]);
	}else{
		my($name,$val) = @_;
		my $str_val = "$val";
		my $old = $self->attr($name,$str_val);
		no warnings 'uninitialized';
		$old ne $str_val
		 and $self->trigger_event('DOMAttrModified',
			auto_viv => sub {
				require HTML'DOM'Event'Mutation;
				attr_name => $name,
				attr_change_type =>
				  defined $old
				  ? &HTML'DOM'Event'Mutation'MODIFICATION
				  : &HTML'DOM'Event'Mutation'ADDITION,
				prev_value => $old,
				new_value => $val,
				rel_node => $self->getAttributeNode($name),
			}
		);
	}

	# possible event handler
	if ($_[0] =~ /^on(.*)/is and my $listener_maker = $self->
	     ownerDocument->event_attr_handler) {
		my $eavesdropper = &$listener_maker(
			$self, my $name = lc $1, $_[1]
		);
		defined $eavesdropper and $self-> event_handler(
			$name, $eavesdropper
		);
	}

	return # nothing;
}

# This is just like attr, except that it triggers events.
sub _attr {
	my($self,$name) = (shift,shift);
# ~~~ Can we change getAttribute to attr, to make it faster, or will attr reject a reference? (Do we have to stringify it?)
	my $old = $self->getAttribute($name) if defined wantarray;
	@_
	 and defined $_[0]
	      ? $self->setAttribute($name, shift)
	      : $self->removeAttribute($name);
	$old;
}


sub removeAttribute {
	my $old = (my $self = shift)->attr(my $name = shift);
	$self->attr($name => undef);
	if(defined blessed $old and $old->isa('HTML::DOM::Attr')) {
		# So the attr node can be reused:
		$old->_element(undef);

		$self->trigger_event('DOMAttrModified',
			attr_name => $name,
			attr_change_type => 3,
			 prev_value =>
			(new_value => ($old->value) x 2)[-1..1],
			rel_node => $old,
		);
	}
	else {
		return unless defined $old;
		$self->trigger_event('DOMAttrModified',
			auto_viv => sub {
				(my $attr =
					$self->ownerDocument
						->createAttribute($name)
				)->value($old);
				attr_name => $name,
				attr_change_type => 3,
				prev_value => $old,
				new_value => $old,
				rel_node => $attr,
			}
		);
	}

	return # nothing;
}

sub getAttributeNode {
	my $elem = shift;
	my $name = lc shift;

	my $attr = $elem->attr($name);
	unless(defined $attr
	) { # check to see whether it has a default value
		my $tag = $elem->tag;
		return $elem->{_HTML_DOM_unspecified}{$name} ||= do{
			return unless exists $attr_defaults{$tag}
				and exists $attr_defaults{$tag}{$name}
				or $tag eq 'html' and $name eq 'version'
				   and exists $elem->{_HTML_DOM_version};
			my $attr = HTML::DOM::Attr->new($name);
			$attr->_set_ownerDocument($elem->ownerDocument);
			$attr->_element($elem);
			$attr->value($name eq 'version'
				? $elem->{_HTML_DOM_version}
				: $attr_defaults{$tag}{$name});
			$attr;
		};
	}

	if(!ref $attr) {
		$elem->attr($name, my $new_attr =
			HTML::DOM::Attr->new($name, $attr));
		$new_attr->_set_ownerDocument($elem->ownerDocument);
		$new_attr->_element($elem);
		return $new_attr;
	}
	$attr;
}

sub setAttributeNode {
	my $doc = $_[0]->ownerDocument;

	# Even if it’s already the same document, it’s actually
	# quicker just to set it than to check first.
	$_[1]->_set_ownerDocument($doc);

	my $e;
	die HTML::DOM::Exception->new(INUSE_ATTRIBUTE_ERR,
		'The attribute passed to setAttributeNode is in use')
		if defined($e = $_[1]->_element) && $e != $_[0];

	my $old = $_[0]->attr(my $name = $_[1]->nodeName, $_[1]);
	$_[1]->_element($_[0]);

	# possible event handler
	if ($name =~ /^on(.*)/is and my $listener_maker = $_[0]->
	     ownerDocument->event_attr_handler) {
		# ~~~ Is there a possibility that the listener-maker
		#     will have a reference to the old attr node, and
		#     that calling it when that attr still has an
		#    'owner' element when it shouldn't will cause any
		#     problems? Yet I don't want to intertwine this
		#     section of code with the one below.
		my $eavesdropper = &$listener_maker(
			$_[0], $name = lc $1, $_[1]->nodeValue
		);
		defined $eavesdropper and $_[0]-> event_handler(
			$name, $eavesdropper
		);
	}

	my $ret;
	if(defined $old) {
		if(defined blessed $old and $old->isa("HTML::DOM::Attr")) {
			$old->_element(undef);
			$ret = $old;
		} else {
			$ret =
				HTML::DOM::Attr->new($name);
			$ret->_set_ownerDocument($doc);
			$ret->_element($_[0]);
			$ret->value($old);
		}			
	}

	defined $ret and $_[0]->trigger_event('DOMAttrModified',
		attr_name => $name,
		attr_change_type => 3,
		 prev_value =>
		(new_value => ($ret->value) x 2)[-1..1],
		rel_node => $ret,
	);
	$_[0]->trigger_event('DOMAttrModified',
		attr_name => $_[1]->name,
		attr_change_type => 2,
		 prev_value =>
		(new_value => ($_[1]->value) x 2)[-1..1],
		rel_node => $_[1],
	);

	return $ret if defined $ret;

	return # nothing;
}

sub removeAttributeNode {
	my($elem,$attr) = @_;

	my $old_val = $elem->attr(my $name = $attr->nodeName);
	defined($old_val)
		? ref$old_val && refaddr $attr == refaddr $old_val
		: exists $elem->{_HTML_DOM_unspecified}{$name}
	or die HTML::DOM::Exception->new(NOT_FOUND_ERR,
		"The node passed to removeAttributeNode is not an " .
		"attribute of this element.");

	$elem->attr($name, undef);
	delete $elem->{_HTML_DOM_unspecified}{$name};
	$attr->_element(undef);

	$elem->trigger_event('DOMAttrModified',
		attr_name => $name,
		attr_change_type => 3,
		 prev_value =>
		(new_value => ($attr->value) x 2)[-1..1],
		rel_node => $attr,
	);


	return $attr
}


sub getElementsByTagName {
	my($self,$tagname) = @_;
	if (wantarray) {
		return $tagname eq '*'
			? grep tag $_ !~ /^~/, $self->descendants
			: (
			     ($tagname = lc $tagname)[()],
			     grep tag $_ eq $tagname, $self->descendants
			  );
	}
	else {
		my $list = HTML::DOM::NodeList::Magic->new(
			$tagname eq '*'
			  ? sub { grep tag $_ !~ /^~/, $self->descendants }
			  : (
			     $tagname = lc $tagname,
			     sub {
			      grep tag $_ eq $tagname, $self->descendants
			     }
			    )[1]
		);
		$self->ownerDocument-> _register_magic_node_list($list);
		$list;
	}
}

sub getElementsByClassName {
	splice @_, 2; # Remove extra elements
	goto &_getElementsByClassName;
}
sub _getElementsByClassName {
	my($self,$names,$is_doc) = @_;

	my $cref;
	if(defined $names) {
	 no warnings 'uninitialized';
	 # The DOM spec says to skip *ASCII* whitespace, and defines it as:
	 #   U+0009, U+000A, U+000C, U+000D, and U+0020
	 #      \t      \n      \f      \r
 	 $names
	  = join ".*", map " $_ ", sort split /[ \t\n\f\r]+/, $names;
	 $cref = sub {
	  (" ".join("  ", sort split /[ \t\n\f\r]+/, $_[0]->attr('class'))
	      ." ")
	   =~ $names
	 };
	}
	else { $cref = sub {} }

	if (wantarray) {
		return $self->look_down($cref);
	}
	else {
		my $list = HTML::DOM::NodeList::Magic->new(
			  sub { $self->look_down($cref); }
		);
		($is_doc ? $self : $self-> ownerDocument)
		  ->_register_magic_node_list($list);
		$list;
	}
}

sub hasAttribute {
	my ($self,$attrname)= (shift, lc shift);
	my $tag;
	defined $self->attr($attrname)
		or exists $attr_defaults{$tag = $self->tag}
			and exists $attr_defaults{$tag}{$attrname}
		or $tag eq 'html' and $attrname eq 'version'
			and exists $self->{_HTML_DOM_version}
}

sub _attr_specified { defined shift->attr(shift) }

sub click { shift->trigger_event('click') }

# used by innerHTML and insertAdjacentHTML
sub _html_fragment_parser {
		require HTML'DOM; # paranoia
		(my $tb = new HTML::DOM::Element::HTML:: no_magic_forms=>1)
		  ->_set_ownerDocument(shift->ownerDocument);
		$tb->parse(shift);
		$tb->eof();
		$_->implicit(1) for $tb, $tb->content_list; # more paranoia
		$tb;
}

use constant _html_element_adds_newline =>
 new HTML::DOM::_Element 'foo' =>->as_HTML =~ /\n/;

sub innerHTML {
	my $self = shift;
	my $old = join '', map $_->nodeType==ELEMENT_NODE
			? _html_element_adds_newline
			    ? substr(
			       $_->as_HTML((undef)x2,{}),0,-1
			      )
			    : $_->as_HTML((undef)x2,{})
			: encode_entities($_->data),$self->content_list
	  if defined wantarray;
	if(@_) {
		my $tb = _html_fragment_parser($self,shift);
		$self->delete_content;
		$self->push_content($tb->guts);
		{($self->ownerDocument||last)->_modified}
	}
	$old;
}

{
 my %mm # method map
  = qw(
   beforebegin preinsert
   afterend    postinsert
   afterbegin  unshift_content
   beforeend   push_content
  );

 sub insertAdjacentHTML {
  my $elem = shift;
 
  die new HTML::DOM::Exception:: SYNTAX_ERR,
   "$_[0]: invalid first argument to insertAdjacentHTML"
    unless exists $mm{ my $where = lc $_[0] };
 
  my $tb = _html_fragment_parser($elem,$_[1]);
  $elem->${\$mm{$where}}(guts $tb);

  {($elem->ownerDocument||last)->_modified}

  ()
 }
 
 sub insertAdjacentElement {
  my $elem = shift;
 
  die new HTML::DOM::Exception:: SYNTAX_ERR,
   "$_[0]: invalid first argument to insertAdjacentElement"
    unless exists $mm{ my $where = lc $_[0] };
 
  $elem->${\$mm{$where}}($_[1]);

  {($elem->ownerDocument||last)->_modified}

  ()
 }
}

sub innerText {
	my $self = shift;
	my $old = $self->as_text
	  if defined wantarray;
	if(@_) {
		# The slow way (with removeChild instead of delete_content)
		# in order to trigger mutation events. (This may change if
		# there is a spec one day for innerText.)
		$self->removeChild($_) for $self->childNodes;
		$self->appendChild(
		 $self->ownerDocument->createTextNode(shift)
		);
	}
	$old;
}

sub starttag {
	my $self = shift;
	my $tag = $self->SUPER::starttag(@ _);
	$tag =~ s/ \/>\z/>/;
	$tag
}

# ------- OVERRIDDEN NODE METHDOS ---------- #

*nodeName = \&tagName;
*nodeType = \& ELEMENT_NODE;

sub attributes {
	my $self = shift;
	$self->{_HTML_DOM_Element_map} ||=
		HTML::DOM::NamedNodeMap->new($self);
}


sub cloneNode { # override of HTML::DOM::Node’s method
	my $clown = shift->SUPER::cloneNode(@_);

	unless(shift) { # if it’s shallow
		# Flatten attr nodes, effectively cloning them:
		$$clown{$_} = "$$clown{$_}" for grep !/^_/, keys %$clown;
		delete $clown->{_HTML_DOM_Element_map};
	} # otherwise clone takes care of this, so we don’t need to here
	$clown;
}

sub clone { # override of HTML::Element’s method; this is called
            # recursively during a deep clone
	my $clown = shift->SUPER::clone;
	$$clown{$_} = "$$clown{$_}" for grep !/^_/, keys %$clown;
	delete $clown->{_HTML_DOM_Element_map};
	$clown;
}

sub trigger_event {
	my ($a,$evnt) = (shift,shift);
	$a->SUPER::trigger_event(
		$evnt,
		click_default =>sub {
			$_[0]->target->trigger_event(DOMActivate =>
				detail => eval{$_[0]->detail}
			);;
		},
		# We check magic_forms before adding this for efficiency’s
		# sake:  so as not to burden well-formed documents with
		# the extra overhead of auto-vivving an event object
		# unnecessarily.
		$a->ownerDocument->magic_forms ? (
			DOMNodeRemoved_default => sub {
				my $targy = $_[0]->target;
				for($targy, $targy->descendants) {
					eval { $_->form(undef) };
				}
				return; # give the eval void context
			},
		) : (),
		@_,
	);
}


=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Node>

L<HTML::Element>

All the HTML::DOM::Element subclasses listed under
L<HTML::DOM/CLASSES AND DOM INTERFACES>

=cut


# ------- HTMLHtmlElement interface ---------- #
# This has been moved to DOM.pm.

# ------- HTMLHeadElement interface ---------- #

package HTML::DOM::Element::Head;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub profile { shift->_attr('profile' => @_) }

# ------- HTMLLinkElement interface ---------- #

package HTML::DOM::Element::Link;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
use Scalar::Util 'blessed';
sub disabled {
	if(@_ > 1) {
		my $old = $_[0]->{_HTML_DOM_disabled};
		$_[0]->{_HTML_DOM_disabled} = $_[1];
		return $old;
	}
	else { $_[0]->{_HTML_DOM_disabled};}
}
sub charset  { shift->_attr('charset' => @_) }
sub href     { shift->_attr('href'    => @_) }
sub hreflang { shift->_attr( hreflang => @_) }
sub media    { shift->_attr('media'   => @_) }
sub rel      { shift->_attr('rel'     => @_) }
sub rev      { shift->_attr('rev'     => @_) }
sub target   { shift->_attr('target'  => @_) }
sub type     { shift->_attr('type'    => @_) }

sub sheet {
	my $self = shift;
		no warnings 'uninitialized';
	$self->attr('rel') =~ 
		/(?:^|\p{IsSpacePerl})stylesheet(?:\z|\p{IsSpacePerl})/i
	 or return;

	my $old = $$self{_HTML_DOM_sheet};
	@_ and $self->{_HTML_DOM_sheet} = shift;
	$old||();}

# I need to override these four to update the document’s style sheet list.
# ~~~ These could be made more efficient if they checked the attribute
#     name first, to avoid unnecessary method calls.
sub setAttribute {
	for(shift) {
		$_->SUPER::setAttribute(@_);
		$_->ownerDocument->_populate_sheet_list;
	}
	return # nothing;
}
sub removeAttribute {
	for(shift) {
		$_->SUPER::removeAttribute(@_);
		$_->ownerDocument->_populate_sheet_list
	}
	return # nothing;
}
sub setAttributeNode {
	(my $self  = shift)->SUPER::setAttributeNode(@_);
	$self->ownerDocument->_populate_sheet_list;
	return # nothing;
}
sub removeAttributeNode {
	my $self = shift;
	my $attr = $self->SUPER::removeAttributeNode(@_);
	$self->ownerDocument->_populate_sheet_list;
	$attr
}

sub trigger_event {
 # ~~~ This defeats the purpose of having an auto-viv sub. I need to do
 #     some rethinking....
 my $elem = shift;
 if(defined blessed $_[0] and $_[0]->isa("HTML::DOM::Event")) {
  return $elem->SUPER::trigger_event(@_)
   unless $_[0]->type =~ /^domattrmodified\z/i;
  my $attr_name = $_[0]->attrName;
  if($attr_name eq 'href') { _reset_style_sheet($elem) }
 }
 elsif($_[0] !~ /^domattrmodified\z/i) {
  return $elem->SUPER::trigger_event(@_);
 }
 else {
  my($event,%args) = @_;
  $args{auto_viv} and %args = &{$args{auto_viv}}, @_ = ($event, %args);
  $args{attr_name} eq 'href' and _reset_style_sheet($elem);
 }
 SUPER'trigger_event $elem @_;
}

sub _reset_style_sheet {
 my $elem = shift;
 return
  unless ($elem->attr('rel')||'')
           =~ /(?:^|\p{IsSpacePerl})stylesheet(?:\z|\p{IsSpacePerl})/i;
 my $doc = $elem->ownerDocument;
 return unless my $fetcher = $doc->css_url_fetcher;
 my $base = $doc->base;
 my $url = defined $base
  ? new_abs URI
     $elem->href, $doc->base
  : $elem->href;
 my ($css_code, %args)
  = $fetcher->($url);
 return unless defined $css_code;
 require CSS'DOM;
 VERSION CSS'DOM 0.03;
 my $hint
  = $doc->charset || 'iso-8859-1';
              # default HTML charset
 $elem->sheet(
  # ’Tis true we create a new clo-
  #  sure for each style sheet, but
  #  what if the charset changes?
  # ~~~ Is that even possible?
  CSS'DOM'parse(
   $css_code,
   url_fetcher => sub {
    my @ret = $fetcher->(shift);
    @ret
     ? (
        $ret[0],
        encoding_hint => $hint,
        @ret[1..$#ret]
     ) : ()
   },
   encoding_hint => $hint,
   %args
  )
 );
}

# ------- HTMLTitleElement interface ---------- #

package HTML::DOM::Element::Title;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
# This is what I call FWP (no lexical vars):
sub text {
	($_[0]->firstChild or
		@_ > 1 && $_[0]->appendChild(
			shift->ownerDocument->createTextNode(shift)
		),
		return '',
	)->data(@_[1..$#_]);
}

# ------- HTMLMetaElement interface ---------- #

package HTML::DOM::Element::Meta;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub content   { shift->_attr('content'    => @_) }
sub httpEquiv { shift->_attr('http-equiv' => @_) }
sub name      { shift->_attr('name'       => @_) }
sub scheme    { shift->_attr('scheme'     => @_) }

# ------- HTMLBaseElement interface ---------- #

package HTML::DOM::Element::Base;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*href =\& HTML::DOM::Element::Link::href;
*target =\& HTML::DOM::Element::Link::target;

# ------- HTMLIsIndexElement interface ---------- #

package HTML::DOM::Element::IsIndex;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub form     { (shift->look_up(_tag => 'form'))[0] || () }
# ~~~ Should this be the same as Select::form? I.e., should isindex ele-
#     ments get magic form associations?
sub prompt   { shift->_attr('prompt'  => @_) }

# ------- HTMLStyleElement interface ---------- #

package HTML::DOM::Element::Style;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*disabled = \&HTML::DOM::Element::Link::disabled;
*media =\& HTML::DOM::Element::Link::media;
*type =\& HTML::DOM::Element::Link::type;

sub sheet {
	my $self = shift;
	$self->{_HTML_DOM_sheet} ||= do{
		my $first_child = $self->firstChild;
		local *@;
		require CSS::DOM;
		VERSION CSS::DOM .03;
		CSS::DOM::parse($first_child?$first_child->data:'');
	};
}

# ------- HTMLBodyElement interface ---------- #

package HTML::DOM::Element::Body;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub aLink      { shift->_attr( aLink      => @_) }
sub background { shift->_attr( background => @_) }
sub bgColor    { shift->_attr('bgcolor'   => @_) }
sub link       { shift->_attr('link'      => @_) }
sub text       { shift->_attr('text'      => @_) }
sub vLink      { shift->_attr('vlink'     => @_) }
sub event_handler {
 my $self = shift;
 my $target = $self->ownerDocument->event_parent;
 $target
  ? $target->event_handler(@_)
  : $self->SUPER::event_handler(@_);
}

# ------- HTMLFormElement interface ---------- #

# See Element/Form.pm

# ~~~ list other form things here for reference

# ------- HTMLUListElement interface ---------- #

package HTML::DOM::Element::UL;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub compact { shift->_attr( compact => @_ ? $_[0]?'compact': undef : () ) }
sub type { lc shift->_attr( type => @_) }

# ------- HTMLOListElement interface ---------- #

package HTML::DOM::Element::OL;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub start { shift->_attr( start => @_) }
*compact=\&HTML::DOM::Element::UL::compact;
* type = \ & HTML::DOM::Element::Link::type ;

# ------- HTMLDListElement interface ---------- #

package HTML::DOM::Element::DL;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*compact=\&HTML::DOM::Element::UL::compact;

# ------- HTMLDirectoryElement interface ---------- #

package HTML::DOM::Element::Dir;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*compact=\&HTML::DOM::Element::UL::compact;

# ------- HTMLMenuElement interface ---------- #

package HTML::DOM::Element::Menu;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*compact=\&HTML::DOM::Element::UL::compact;

# ------- HTMLLIElement interface ---------- #

package HTML::DOM::Element::LI;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*type =\& HTML::DOM::Element::Link::type;
sub value { shift->_attr( value => @_) }

# ------- HTMLDivElement interface ---------- #

package HTML::DOM::Element::Div;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub align { lc shift->_attr( align => @_) }

# ------- HTMLParagraphElement interface ---------- #

package HTML::DOM::Element::P;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*align =\& HTML::DOM::Element::Div::align;

# ------- HTMLHeadingElement interface ---------- #

package HTML::DOM::Element::Heading;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*align =\& HTML::DOM::Element::Div::align;

# ------- HTMLQuoteElement interface ---------- #

package HTML::DOM::Element::Quote;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub cite { shift->_attr( cite => @_) }

# ------- HTMLPreElement interface ---------- #

package HTML::DOM::Element::Pre;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub width { shift->_attr( width => @_) }

# ------- HTMLBRElement interface ---------- #

package HTML::DOM::Element::Br;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub clear { lc shift->_attr( clear => @_) }

# ------- HTMLBaseFontElement interface ---------- #

package HTML::DOM::Element::BaseFont;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub color { shift->_attr( color => @_) }
sub face  { shift->_attr( face  => @_) }
sub size  { shift->_attr( size  => @_) }

# ------- HTMLBaseFontElement interface ---------- #

package HTML::DOM::Element::Font;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*color =\& HTML::DOM::Element::BaseFont::color;
*face =\& HTML::DOM::Element::BaseFont::face;
*size =\& HTML::DOM::Element::BaseFont::size;

# ------- HTMLHRElement interface ---------- #

package HTML::DOM::Element::HR;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*align =\& HTML::DOM::Element::Div::align;
sub noShade { shift->_attr( noshade => @_ ? $_[0]?'noshade':undef : () ) }

*size =\& HTML::DOM::Element::BaseFont::size;
*width =\& HTML::DOM::Element::Pre::width;

# ------- HTMLModElement interface ---------- #

package HTML::DOM::Element::Mod;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*cite =\& HTML::DOM::Element::Quote::cite;
sub dateTime  { shift->_attr( datetime  => @_) }

# ------- HTMLAnchorElement interface ---------- #

package HTML::DOM::Element::A;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub accessKey  { shift->_attr(               accesskey  => @_) }
*   charset    =\&HTML::DOM::Element::Link::charset           ;
*   coords     =\&HTML::DOM::Element::Area::coords            ;
*   href       =\&HTML::DOM::Element::Link::href              ;
*   hreflang   =\&HTML::DOM::Element::Link::hreflang          ;
*   name       =\&HTML::DOM::Element::Meta::name              ;
*   rel        =\&HTML::DOM::Element::Link::rel               ;
*   rev        =\&HTML::DOM::Element::Link::rev               ;
sub shape      { shift->_attr(               shape      => @_) }
*   tabIndex   =\&HTML::DOM::Element::Object::tabIndex        ;
*   target     =\&HTML::DOM::Element::Link::target            ;
*   type       =\&HTML::DOM::Element::Link::type              ;

sub blur  { shift->trigger_event('blur') }
sub focus { shift->trigger_event('focus') }

sub trigger_event {
	my ($a,$evnt) = (shift,shift);
	$a->SUPER::trigger_event(
		$evnt,
		DOMActivate_default => 
			$a->ownerDocument->
				default_event_handler_for('link')
		,
		@_,
	);
}

sub _get_abs_href {
	my $elem = shift;
	my $uri = new URI $elem->attr('href');
	if(!$uri->scheme) {
		my $base = $elem->ownerDocument->base;
		return unless $base;
		$uri = $uri->abs($base);
		return unless $uri->scheme;
	}
	$uri
}

sub hash {
	my $elem = shift;
	defined(my $uri = _get_abs_href $elem) or return '';
	my $old;
	if(defined wantarray) {
		$old = $uri->fragment;
		$old = "#$old" if defined $old;
	}
	if (@_){
		shift() =~ /#?(.*)/s;
		$uri->fragment($1);
		$elem->_attr(href => $uri);
	}
	$old||''
}

sub host {
	my $elem = shift;
	defined(my $uri = _get_abs_href $elem) or return '';
	my $old = $uri->host_port if defined wantarray;
	if (@_) {
		$uri->port("");
		$uri->host_port(shift);
		$elem->attr(href => $uri);
	}
	$old
}

sub hostname {
	my $elem = shift;
	defined(my $uri = _get_abs_href $elem) or return '';
	my $old = $uri->host if defined wantarray;
	if (@_) {
		$uri->host(shift);
		$elem->attr(href => $uri);
	}
	$old
}

sub pathname {
	my $elem = shift;
	defined(my $uri = _get_abs_href $elem) or return '';
	my $old = $uri->path if defined wantarray;
	if (@_) {
		$uri->path(shift);
		$elem->attr(href => $uri);
	}
	$old
}

sub port {
	my $elem = shift;
	defined(my $uri = _get_abs_href $elem) or return '';
	my $old = $uri->port if defined wantarray;
	if (@_) {
		$uri->port(shift);
		$elem->attr(href => $uri);
	}
	$old
}

sub protocol {
	my $elem = shift;
	defined(my $uri = _get_abs_href $elem) or return '';
	my $old = $uri->scheme . ':' if defined wantarray;
	if (@_) {
		shift() =~ /(.*):?/s;
		$uri->scheme("$1");
		$elem->attr(href => $uri);
	}
	$old

}

sub search {
	my $elem = shift;
	defined(my $uri = _get_abs_href $elem) or return '';
	my $old;
	if(defined wantarray) {
		my $q = $uri->query;
		$old = defined $q ? "?$q" : "";
	}
	if (@_){
		shift() =~ /(\??)(.*)/s;
		$uri->query(
			$1||length$2 ? "$2" : undef
		);
		$elem->attr(href => $uri);
	}
	$old
}


# ------- HTMLImageElement interface ---------- #

package HTML::DOM::Element::Img;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub lowSrc  { shift->attr(               lowsrc  => @_) }
*   name  = \&HTML::DOM::Element::Meta::name            ;
*   align = \&HTML::DOM::Element::Div::align            ;
sub alt     { shift->_attr(               alt     => @_) }
sub border  { shift->_attr(               border  => @_) }
sub height  { shift->_attr(               height  => @_) }
sub hspace  { shift->_attr(               hspace  => @_) }
sub isMap   { shift->_attr(  ismap => @_ ? $_[0] ? 'ismap' : undef : () ) }
sub longDesc { shift->_attr(              longdesc => @_) }
sub src      { shift->_attr(              src      => @_) }
sub useMap   { shift->_attr(              usemap   => @_) }
sub vspace   { shift->_attr(              vspace   => @_) }
*   width = \&HTML::DOM::Element::Pre::width             ;

# ------- HTMLObjectElement interface ---------- #

package HTML::DOM::Element::Object;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*form=\&HTML::DOM::Element::Select::form;
sub code  { shift->_attr(               code  => @_) }
*   align = \&HTML::DOM::Element::Div::align            ;
sub archive  { shift->_attr(               archive  => @_) }
sub border  { shift->_attr(               border  => @_) }
sub codeBase     { shift->_attr(               codebase     => @_) }
sub codeType     { shift->_attr(               codetype     => @_) }
sub data  { shift->_attr(               data  => @_) }
sub declare { shift->_attr( declare => @_ ? $_[0]?'declare':undef : () ) }
*   height = \&HTML::DOM::Element::Img::height             ;
*   hspace = \&HTML::DOM::Element::Img::hspace             ;
*   name  = \&HTML::DOM::Element::Meta::name            ;
sub standby { shift->_attr(              standby => @_) }
sub tabIndex      { shift->_attr(              tabindex      => @_) }
*type =\& HTML::DOM::Element::Link::type;
*useMap =\& HTML::DOM::Element::Img::useMap;
*vspace =\& HTML::DOM::Element::Img::vspace;
*   width = \&HTML::DOM::Element::Pre::width             ;
sub contentDocument{}

# ------- HTMLParamElement interface ---------- #

package HTML::DOM::Element::Param;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*name=\&HTML::DOM::Element::Meta::name;
*type=\&HTML::DOM::Element::Link::type;
*value=\&HTML::DOM::Element::LI::value;
sub valueType{lc shift->_attr(valuetype=>@_)}

# ------- HTMLAppletElement interface ---------- #

package HTML::DOM::Element::Applet;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
* align    = \ & HTML::DOM::Element::Div::align       ;
* alt      = \ & HTML::DOM::Element::Img::alt         ;
* archive  = \ & HTML::DOM::Element::Object::archive  ;
* code     = \ & HTML::DOM::Element::Object::code     ;
* codeBase = \ & HTML::DOM::Element::Object::codeBase ;
* height   = \ & HTML::DOM::Element::Img::height      ;
* hspace   = \ & HTML::DOM::Element::Img::hspace      ;
* name     = \ & HTML::DOM::Element::Meta::name       ;
sub object { shift -> _attr ( object => @_ ) }
* vspace   = \ & HTML::DOM::Element::Img::vspace      ;
* width    = \ & HTML::DOM::Element::Pre::width       ;

# ------- HTMLMapElement interface ---------- #

package HTML::DOM::Element::Map;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub areas { # ~~~ I need to make this cache the resulting collection obj
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'area', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'area', $self->descendants }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
* name     = \ & HTML::DOM::Element::Meta::name       ;

# ------- HTMLAreaElement interface ---------- #

package HTML::DOM::Element::Area;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
* alt       = \ & HTML::DOM::Element::Img::alt         ;
sub coords { shift -> _attr ( coords => @_ ) }
* href      = \ & HTML::DOM::Element::Link::href       ;
sub noHref { shift->attr ( nohref => @_ ? $_[0] ? 'nohref' : undef : () ) }
* tabIndex  = \ & HTML::DOM::Element::Object::tabIndex ;
* target    = \ & HTML::DOM::Element::Link::target     ;
{
 no strict 'refs';
 *$_ = \&{"HTML::DOM::Element::A::$_"}
  for qw(accessKey shape hash host hostname pathname port protocol search
         trigger_event);
}

# ------- HTMLScriptElement interface ---------- #

package HTML::DOM::Element::Script;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
* text    = \ &HTML::DOM::Element::Title::text   ;
sub htmlFor { shift -> _attr ( for   => @_ )      }
sub event   { shift -> _attr ( event => @_ )      }
* charset = \ &HTML::DOM::Element::Link::charset ;
sub defer { shift -> _attr ( defer => @_ ? $_[0] ? 'defer' : undef : () ) }
* src     = \ &HTML::DOM::Element::Img::src      ;
* type    = \ &HTML::DOM::Element::Link::type    ;

# ------- HTMLFrameSetElement interface ---------- #

package HTML::DOM::Element::FrameSet;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub rows { shift -> _attr ( rows   => @_ )      }
sub cols   { shift -> _attr ( cols => @_ )      }

# ------- HTMLFrameElement interface ---------- #

package HTML::DOM::Element::Frame;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub frameBorder { lc shift -> _attr ( frameBorder  => @_ )      }
sub longDesc    { shift -> _attr ( longdesc     => @_ )      }
sub marginHeight{ shift -> _attr ( marginheight => @_ )      }
sub marginWidth { shift -> _attr ( marginwidth  => @_ )      }
* name    = \ &HTML::DOM::Element::Meta::name   ;
sub noResize { shift->_attr(noresize => @_ ? $_[0]?'noresize':undef : ()) }
sub scrolling   { lc shift -> _attr ( scrolling    => @_ )      }
* src     = \ &HTML::DOM::Element::Img::src     ;
sub contentDocument{ (shift->{_HTML_DOM_view} || return)->document }
sub contentWindow {
	my $old = (my $self = shift)->{_HTML_DOM_view};
	@_ and $self->{_HTML_DOM_view} = shift;
	defined $old ? $old : ()
};

# ------- HTMLIFrameElement interface ---------- #

package HTML::DOM::Element::IFrame;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*align  = \&HTML::DOM::Element::Div::align;
*frameBorder = \&HTML::DOM::Element::Frame::frameBorder;
*height = \&HTML::DOM::Element::Img::height;
*longDesc = \&HTML::DOM::Element::Frame::longDesc;
* marginHeight = \&HTML::DOM::Element::Frame::marginHeight;
*marginWidth = \&HTML::DOM::Element::Frame::marginWidth;
*name   = \&HTML::DOM::Element::Meta::name;
*scrolling = \&HTML::DOM::Element::Frame::scrolling;
*src    = \&HTML::DOM::Element::Img::src;
*width  = \&HTML::DOM::Element::Pre::width;
*contentDocument = \&HTML::DOM::Element::Frame::contentDocument;
*contentWindow = \&HTML::DOM::Element::Frame::contentWindow;

1
