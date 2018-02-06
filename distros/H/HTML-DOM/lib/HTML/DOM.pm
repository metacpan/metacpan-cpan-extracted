package HTML::DOM;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).


use 5.008003;

use strict;
use warnings;

use Carp 'croak';
use HTML::DOM::Element;
use HTML::DOM::Exception 'NOT_SUPPORTED_ERR';
use HTML::DOM::Node 'DOCUMENT_NODE';
use Scalar::Util 'weaken';
use URI;

our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Node';

require    HTML::DOM::Collection;
require         HTML::DOM::Comment;
require HTML::DOM::DocumentFragment;
require  HTML::DOM::Implementation;
require HTML::DOM::NodeList::Magic;
require             HTML::DOM::Text;
require                 HTML::Tagset;
require      HTML::DOM::_TreeBuilder;

use overload fallback => 1,
'%{}' => sub {
	my $self = shift;
#return $self; # for debugging
	$self->isa(scalar caller) || caller->isa('HTML::DOM::_TreeBuilder')
		and return $self;
	$self->forms;
};


=head1 NAME

HTML::DOM - A Perl implementation of the HTML Document Object Model

=head1 VERSION

Version 0.058 (alpha)

B<WARNING:> This module is still at an experimental stage.  The API is 
subject to change without
notice.

=head1 SYNOPSIS

  use HTML::DOM;
  
  my $dom_tree = new HTML::DOM; # empty tree
  $dom_tree->write($source_code);
  $dom_tree->close;
  
  my $other_dom_tree = new HTML::DOM;
  $other_dom_tree->parse_file($filename);
  
  $dom_tree->getElementsByTagName('body')->[0]->appendChild(
           $dom_tree->createElement('input')
  );
  
  print $dom_tree->innerHTML, "\n";

  my $text = $dom_tree->createTextNode('text');
  $text->data;              # get attribute
  $text->data('new value'); # set attribute
  
=head1 DESCRIPTION

This module implements the HTML Document Object Model by extending the
HTML::Tree modules.  The HTML::DOM class serves both as an HTML parser and
as the document class.

The following DOM modules are currently supported:

  Feature         Version (aka level)
  -------         -------------------
  HTML            2.0
  Core            2.0
  Events          2.0
  UIEvents        2.0
  MouseEvents     2.0
  MutationEvents  2.0
  HTMLEvents      2.0
  StyleSheets     2.0
  CSS             2.0 (partially)
  CSS2            2.0
  Views           2.0

StyleSheets, CSS and CSS2 are actually provided by L<CSS::DOM>.  This list
corresponds to CSS::DOM versions 0.02 to 0.14.

=for comment
Level 2 interfaces not yet included: Range, Traversal

=head1 METHODS

=head2 Construction and Parsing

=over 4

=item $tree = new HTML::DOM %options;

This class method constructs and returns a new HTML::DOM object.  The
C<%options>, which are all optional, are as follows:

=over 4

=item url

The value that the C<URL> method will return.  This value is also used by
the C<domain> method. 

=item referrer

The value that the C<referrer> method will return

=item response

An HTTP::Response object.  This will be used for information needed for 
writing cookies.  It is expected to have a reference to a request object
(accessible via its C<request> method--see L<HTTP::Response>).  Passing a 
parameter to the 'cookie' method will be a no-op 
without this.

=item weaken_response

If this is passed a true value, then the HTML::DOM object will hold a weak
reference to the response.

=item cookie_jar

An HTTP::Cookies object.  As with C<response>, if you omit this, arguments 
passed to the 
C<cookie> method will be ignored.

=item charset

The original character set of the document.  This does not affect parsing
via the C<write> method (which always assumes Unicode).  C<parse_file> will
use this, if specified, or L<HTML::Encoding> otherwise.
L<HTML::DOM::Form>'s C<make_request> method uses this to encode form data
unless the form has a valid 'accept-charset' attribute.

=back

If C<referrer> and C<url> are omitted, they can be inferred from 
C<response>.

=cut

{
	# This  HTML::DOM::Element::HTML  package  represents  the
	# documentElement.  It  inherits  from
        # HTML::DOM::_TreeBuilder  and  acts
	# as the parser.  It is also  used  as  a  parser  for  innerHTML.

	# Note for potential developers: You can’t refer to ->parent in
	# this package and expect it to provide the document, because
	# that’s not the case with innerHTML.  Use ->ownerDocument.
	# Use ->parent only to distinguish between innerHTML and
	# the regular parser.

	# Concerning magic associations between forms and fields: To cope
	# with bad markup, an implicitly closed form (with no end tag) is
	# associated with any form fields that occur after that  are  not
	# inside any form. So when a start tag for a form is encountered,
	# we  make  that  the  ‘current form’,  by  pushing  it  on  to
	# @{ $$self{_HTML_DOM_cf} }.  When the element is closed, if it
	# is closed by an end tag, we simply pop it off the cf array. If
	# it is implicitly closed we pop it off  and  also  make  it  the
	# ‘magic form’  (_HTML_DOM_mg_f).  When we encounter a form field,
	# we give it a  magic  association  with  the  form  if  the  cf
	# stack is empty.


	package HTML::DOM::Element::HTML;
	our @ISA = qw' HTML::DOM::Element HTML::DOM::_TreeBuilder';

	use Scalar::Util qw 'weaken isweak';

	# I have to override this so it doesn't delete _HTML_DOM_* attri-
	# butes and so that it doesn’t rebless the object.
	sub elementify {
	  my $self = shift;
	  my %attrs = map /^[a-z_]*\z/ ? () : ($_ => $self->{$_}),
	    keys %$self;
	  my @weak = grep isweak $self->{$_}, keys %$self;
          $self->SUPER::elementify;
	  %$self = (%$self, %attrs); # this invigorates feeble refs
	  weaken $self->{$_} for @weak;
	}

	sub new {
		my $tb; # hafta declare it separately so the closures can
		        # c it
		($tb = shift->HTML::DOM::_TreeBuilder::new(
			element_class => 'HTML::DOM::Element',
			'tweak_~text' => sub {
				my ($text, $parent) = @_;
				# $parent->ownerDocument will be undef if
				# $parent is the doc.
				$parent->splice_content(  -1,1,
					($parent->ownerDocument || $parent)
					 ->createTextNode($text)  );
				$parent->content_offset(
					$$tb{_HTML_DOM_tb_c_offset}
				);
			 },
			'tweak_*' => sub {
				my($elem, $tag, $doc_elem) = @_;
				$tag =~ /^~/ and return;

				if(
				 $tag eq 'link'
				) {
				 HTML'DOM'Element'Link'_reset_style_sheet(
				  $elem
				 );
				}

				# If a  form  is  being  closed,  determine
				# whether it is closed implicitly and set
				# the  current  form  and  magic  form
				# accordingly.
				if($tag eq 'form') {
					pop
					 @{$$doc_elem{_HTML_DOM_cf}||[]};
				 	delete $$doc_elem{_HTML_DOM_etif}
					 or $$doc_elem{_HTML_DOM_mg_f}
					  = $elem
				}

				# If a formie is being closed, create a
				# magic association where appropriate.
				if(!$$doc_elem{_HTML_DOM_no_mg}
				   and $tag =~ /^(?:
				    button|(?:
				     fieldse|inpu|(?:obj|sel)ec
				    )t|label|textarea
				   )\z/x
				   and $$doc_elem{_HTML_DOM_mg_f}
				   and  !$$doc_elem{_HTML_DOM_cf}
				      ||!@{$$doc_elem{_HTML_DOM_cf}}) {
					$elem->form(
					 $$doc_elem{_HTML_DOM_mg_f}
					);
					$doc_elem->ownerDocument->
					 magic_forms(1);
				}

				my $event_offsets = delete
				    $elem->{_HTML_DOM_tb_event_offsets}
				  or return;
				_create_events(
					$doc_elem, $elem, $event_offsets
				);
			 },
		 ))
		   ->ignore_ignorable_whitespace(0); # stop eof()'s cleanup
		$tb->store_comments(1);                # from changing an
		$tb->unbroken_text(1); # necessary, con-  # elem_han-
		                     # sidering what        # dler's view
		                   # _tweak_~text does       # of the tree

		# Web browsers preserve whitespace, at least from the point
		# of view of the DOM; but the main reason we are using this
		# option is that  a  parser  for  innerHTML  doesn’t  know
		# whether the nodes will be inserted in a <pre>.
		no_space_compacting $tb 1;

		$tb->handler(text => "text",         # so we can get line
		    "self, text, is_cdata, offset"); # numbers for scripts
		$tb->handler(start => "start",
		  "self, tagname, attr, attrseq, offset, tokenpos");
		$tb->handler((declaration=>)x2,'self,tagname,tokens,text');

		$tb->{_HTML_DOM_tweakall} = $tb->{'_tweak_*'};

		my %opts = @_;
		$tb->{_HTML_DOM_no_mg} = delete $opts{no_magic_forms};
		  # used by an element’s innerHTML

		# We have to copy it like this, because our circular ref-
		# erence is thus:  $tb  ->  object  ->  closure  ->  $tb
		# We can’t weaken $tb without a copy of it, because it is
		# the only reference to the object.
		my $life_raft = $tb; weaken $tb; $tb;
	}

	sub start {
		return shift->SUPER::start(@_) if @_ < 6; # shirt-çorcuit
		
		my $tokenpos = pop;
		my $offset = pop;
		my %event_offsets;
		my $attr_names = pop;
		for(0..$#$attr_names) {
			$$attr_names[$_] =~ /^on(.*)/is
				and $event_offsets{$1} =
					$$tokenpos[$_*4 + 4] + $offset;
		}

		my $elem = (my $self = shift)->SUPER::start(@_);
		
		$_[0] eq 'form' and push @{ $$self{_HTML_DOM_cf} ||= [] },
		 $elem;

		return $elem unless %event_offsets;

		if(!$HTML::Tagset::emptyElement{$_[0]}) { # container
			$$elem{_HTML_DOM_tb_event_offsets} =
				\%event_offsets;
		} else {
			_create_events(
				$self,
				$elem,
				\%event_offsets,
			);
		}

		return $elem;
	}

	sub _create_events {
		my ($doc_elem,$elem,$event_offsets) = @_;
		defined(my $event_attr_handler =
		  $doc_elem->ownerDocument->event_attr_handler)
		  or return;
		for(keys %$event_offsets) {
			my $l =
			&$event_attr_handler(
				$elem,
				$_,
				$elem->attr("on$_"),
				$$event_offsets{$_}
			);
			defined $l and
			$elem->event_handler (
				$_, $l
			);
		}
	}

	sub text {
		$_[0]{_HTML_DOM_tb_c_offset} = pop;
		shift->SUPER::text(@_)
	}

	sub insert_element {
		my ($self, $tag) = (shift, @_);
		if((ref $tag ? $tag->tag : $tag) eq 'tr'
		   and $self->pos->tag eq 'table') {
			$self->insert_element('tbody', 1);
		}
		$self->SUPER::insert_element(@_);
	}

	sub end {
		my $self = shift;

		# If this is a form, record that we’ve seen an end tag, so
		# that this does not become a ‘magic form’.
		++$$self{_HTML_DOM_etif} # end tag is 'form'
		 if $_[0] eq 'form';

		# Make sure </t[hd]> cannot close a cell outside the cur-
		# rent table.
		$_[0] =~ /^t[hd]\z/ and @_ = (\$_[0], 'table');

		# HTML::TreeBuilder expects the <html> element to be the
		# topmost element, and gets confused when it’s inside the
		# ~doc. It sets _pos to the doc when it encounters </html>.
		# This works around that.
		my $pos = $self->{_pos};
		my @ret = $self->SUPER::end(@_);
		$self->{_pos} = $pos
			if ($self->{_pos}||return @ret)->{_tag} eq '~doc';
		@ret; # TB relies on this retval
	}

	sub declaration {
		my($self,$tagname,$tokens,$source) = @_;
		return
		 unless $tagname eq 'doctype'
		    and my $parent = $self->parent;
		package HTML::DOM; # bypass overloading
		$parent->{_HTML_DOM_doctype} = $source
			unless defined $parent->{_HTML_DOM_doctype};
		return unless @$tokens > 3;
		for ($self->{_HTML_DOM_version} = $tokens->[3]){
			s/^['"]// and s/['"]\z//;
		}
	}

	sub element_class { 'HTML::DOM::Element' }

	# HTMLHtmlElement interface
	sub version { shift->_attr('version' => @_) }

} # end of special TreeBuilder package

sub new {
	my $self = shift->SUPER::new('~doc');

	my %opts = @_;
	$self->{_HTML_DOM_url} = $opts{url}; # might be undef
	$self->{_HTML_DOM_referrer} = $opts{referrer}; # might be undef
	if($opts{response}) {
		$self->{_HTML_DOM_response} = $opts{response};
		if(!defined $self->{_HTML_DOM_url}) {{
			$self->{_HTML_DOM_url} =
				($opts{response}->request || last)
				 ->url;
		}}
		if(!defined $self->{_HTML_DOM_referrer}) {{
			$self->{_HTML_DOM_referrer} =
				($opts{response}->request || last)
				 ->header('Referer')
		}}
		if($opts{weaken_response}) {
			weaken $self->{_HTML_DOM_response}
		}
	}
	$self->{_HTML_DOM_jar} = $opts{cookie_jar}; # might be undef
	$self->{_HTML_DOM_cs} = $opts{charset};

	$self;
}

=item $tree->elem_handler($elem_name => sub { ... })

If you call this method first, then, when the DOM tree is in the 
process of
being built (as a result of a call to C<write> or C<parse_file>), the 
subroutine will be called after each C<$elem_name> element 
is
added to the tree.  If you give '*' as the element name, the subroutine
will be called for each element that does not have a handler.  The
subroutine's 
two arguments will be the tree itself
and the element in question.  The subroutine can call the DOM object's 
C<write>
method to insert HTML code into the source after the element.

Here is a lame example (which does not take Content-Script-Type headers
or security into account):

  $tree->elem_handler(script => sub {
      my($document,$elem) = @_;
      return unless $elem->attr('type') eq 'application/x-perl';
      eval($elem->firstChild->data);
  });

  $tree->write(
      '<p>The time is
           <script type="application/x-perl">
                $document->write(scalar localtime)
           </script>
           precisely.
       </p>'
  );
  $tree->close;

  print $tree->documentElement->as_text, "\n";

(Note: L<HTML::DOM::Element>'s
L<C<content_offset>|HTML::DOM::Element/content_offset> method might come in
handy for reporting line numbers for script errors.)

=cut

sub elem_handler {
	my ($self,$elem_name,$sub) = @_;

# ~~~ temporary; for internal use only:
	@_ < 3 and return $$self{_HTML_DOM_nih}{$elem_name}; 

	$$self{_HTML_DOM_nih}{$elem_name} = $sub; # nih = node inser-
	                                          # tion handler
	my $h = $self->{_HTML_DOM_elem_handlers}{$elem_name} = sub {
		# I can’t put $doc_elem outside the closure, because
		# ->open replaces it with another object, and we’d be
		# referring to the wrong one.
		my $doc_elem = $_[2];
		$doc_elem->{_HTML_DOM_tweakall}->(@_);
		$self->_modified; # in case there are node lists hanging
		                  # around that the handler references
		&$sub($self, $_[0]);

		# See the comment in sub write.
		(my $level = $$self{_HTML_DOM_buffered});
		if(  $level
		 and ($level -= 1, 1)
		 and $$self{_HTML_DOM_p}
		 and $$self{_HTML_DOM_p}[$level]
		  ) {
			 $$self{_HTML_DOM_p}[$level]->eof;
			 $level
			  ? --$#{$$self{_HTML_DOM_p}}
			  :  delete $$self{_HTML_DOM_p};
		}
	};
	if(my $p = $$self{_HTML_DOM_parser}) {
		$$p{"_tweak_$elem_name"} = $h
	}
	weaken $self;
	return;
}


=item css_url_fetcher( \&sub )

With this method you can provide a subroutine that fetches URLs referenced
by 'link' tags.  Its sole argument is the URL, which is made absolute based
on the HTML page's own base URL (it is assumed that this is absolute).  It 
should return C<undef> or an empty list on failure.  Upon
success, it should return just the CSS code, if it has been decoded (and is
in Unicode), or, if it has not been decoded, the CSS code followed by
C<< decode => 1 >>.  See L<CSS::DOM/STYLE SHEET ENCODING> for details on
when you should or should not decode it.  (Note that HTML::DOM
automatically
provides an encoding hint based on the HTML document.)

HTML::DOM passes the result of the url fetcher to L<CSS::DOM> and
turns
it into a style sheet object accessible via the link element's
L<C<sheet>|HTML::DOM::Element::Link/sheet> method.

=cut

sub css_url_fetcher {
 my $old = (my $self = shift)->{_HTML_DOM_cuf};
 $self->{_HTML_DOM_cuf} = shift if @_;
 $old||();
}

=item $tree->write(...) (DOM method)

This parses the HTML code passed to it, adding it to the end of 
the
document. It assumes that its input is a normal Perl Unicode string.  Like
L<HTML::TreeBuilder>'s
C<parse> method, it can take a coderef.

When it is called from an an element handler (see
C<elem_handler>, above), the value passed to it
will be inserted into the HTML code after the current element when the
element handler returns.  (In this case a coderef won't do--maybe that will
be added later.)

If the C<close> method has been called, C<write> will call C<open> before
parsing the HTML code passed to it.

=item $tree->writeln(...) (DOM method)

Just like C<write> except that it appends "\n" to its argument and does
not work with code refs.  (Rather
pointless, if you ask me. :-)

=item $tree->close() (DOM method)

Call this method to signal to the parser that the end of the HTML code has
been reached.  It will then parse any residual HTML that happens to be
buffered.  It also makes the next C<write> call C<open>.

=item $tree->open (DOM method)

Deletes the HTML tree, resetting it so that it has just an <html> element,
and a parser hungry for HTML code.

=item $tree->parse_file($file)

This method takes a file name or handle and parses the content,
(effectively) calling C<close> afterwards.  In the former case (a file 
name), L<HTML::Encoding> will be used to detect the encoding.  In the
latter (a file handle), you'll have to C<binmode> it yourself.  This could
be considered a bug.  If you have a solution to this (how to make
HTML::Encoding detect an encoding from a file handle), please let me know.

As of version 0.12, this method returns true upon success, or undef/empty
list on failure.

=item $tree->charset

This method returns the name of the character
set that was passed to C<new>, or, if that was not given, that which
C<parse_file> used.

It returns undef if C<new> was not given a charset and if C<parse_file> was 
not 
used or was
passed a file handle.

You can also set the charset by passing an argument, in which case the old
value is returned.


=cut

sub parse_file {
	my $file = $_[1];

	$_[0]->open;

	# This ‘if’ statement uses the same check that HTML::Parser uses.
	# We are not strictly checking to see whether it’s a handle,
	# but whether  HTML::Parser  would  consider  it  one.
	if (ref($file) || ref(\$file) eq "GLOB") {
		(my $a = shift->{_HTML_DOM_parser})
			->parse_file($file) || return;
		 $a	->elementify;
		return 1;
	}

	no warnings 'parenthesis'; # 5.8.3 Grrr!!
	if(my $charset = $_[0]{_HTML_DOM_cs}) {
		open my $fh, $file or return;
		$charset =~ s/^(?:x-?)?mac-?/mac/i;
		binmode $fh, ":encoding($charset)";
		$$_{_HTML_DOM_parser}->parse_file($fh) || return,
		$_->close
			for shift;
		return 1;
	}

	open my $fh, $file or return;
	local $/;
	my $contents = <$fh>;
	require HTML::Encoding;
	my $encoding = HTML::Encoding::encoding_from_html_document(
		$contents
	) || 'iso-8859-1';
	# Since we’ve already slurped the file, we might as well
	# avoid having HTML::Parser read it again, even if we could
	# use binmode.
	require Encode;
	$_->write(Encode::decode($encoding, $contents)), $_->close,
	$_->{_HTML_DOM_cs} = $encoding
		for shift;
	return 1;
}

sub charset {
	my $old = (my$ self = shift)->{_HTML_DOM_cs};
	$self->{_HTML_DOM_cs} = shift if @_;
	$old;
}

sub write {
	my $self = shift;
	if($$self{_HTML_DOM_buffered}) {
		# Although we call this buffered, it’s actually not. Before
		# version 0.040,  a recursive call to ->write  on the same
		# doc object would simply record the HTML code in a buffer
		# that was processed when the elem handler that  made  the
		# inner call to ->write finished. Every elem handler would
		# have a wrapper  (created in the elem_handler  sub above)
		# that took care of this after calling the handler, by cre-
		# ating a new, temporary, parser object that would call the
		# start/end, etc., methods of our tree builder.
		#
		# This approach stops JS code like this from working (yes,
		# there *are* websites with code like this!):
		#   document.write("<img id=img1>")
		#   document.getElementById("img1").src="..."
		#
		# So, now we take care of creating a new parser immedi-
		# ately. This does mean, however that we end up with mul-
		# tiple parser objects floating around  in  the  case  of
		# nested <scripts>. So we have to be careful to create and
		# delete them at the right time.

		# $$self{_HTML_DOM_buffered} actually contains a number
		# indicating the number of nested calls to ->write.
		my $level = $$self{_HTML_DOM_buffered};
		local $$self{_HTML_DOM_buffered} = $level + 1;

		my($doc_elem) = $$self{_HTML_DOM_parser};

		# These handlers delegate the handling to methods of
		# *another* HTML::Parser object.
		my $p = $$self{_HTML_DOM_p}[$level-1] ||=
		 HTML::Parser->new(
		  start_h => [ 
		    sub { $doc_elem->start(@_) },
		   'tagname, attr, attrseq'
		  ],
		  end_h => [ 
		    sub { $doc_elem->end(@_) },
		   'tagname, text'
		  ],
		  text_h => [ 
		    sub { $doc_elem->text(@_) },
		   'text, is_cdata'
		  ],
		 );

		$p->unbroken_text(1); # push_content, which is called by
		                     # H:TB:text, won't concatenate two
		                   # text portions if the  first  one
		                  # is a node.

		$p->parse(shift);

		# We can’t get rid of our parser at this point, as a subse-
		# quent ->write call from the same nested level (e.g., from
		# the same <script> block) will need the same one,  in case
		# what we are parsing ends with a partial token. But if the
		# calling elem handler  finishes  (e.g.,  if  we  reach  a
		# </script>),  then we need to remove  it,  so  we  have
		# elem_handler do that for us.
	}
	else {
		my $parser
		 = $$self{_HTML_DOM_parser}
		   || ($self->open, $$self{_HTML_DOM_parser});
		local $$self{_HTML_DOM_buffered} = 1;
		$parser->parse($_) for @_;
	}
	$self->_modified;
	return # nothing;
}

sub writeln { shift->write(@_,"\n") }

sub close {
	my $a = (my $self = shift)->{_HTML_DOM_parser};
	return unless $a;

	# We can’t use eval { $a->eof } because that would catch errors
	# that are meant to propagate  (a  nasty  bug  [the  so-called
	# ‘content—offset’ bug] was hidden because of an eval in ver-
	#  sion 0.010).
#	return unless $a->can('eof');
	                             
	$a->eof(@_);
	delete $$self{_HTML_DOM_parser};
	$a->elementify;
	return # nothing;
}

sub open {
	(my $self = shift)->detach_content;

	# We have to use push_content instead of simply putting it there
	# ourselves,  because push_content  takes care of weakening the
	# parent  (and that code  doesn’t  belong  in  this  package).
	$self->push_content(
	 my $tb = $$self{_HTML_DOM_parser} = new HTML::DOM::Element::HTML
	);

	delete @$self{<_HTML_DOM_sheets _HTML_DOM_doctype>};

	return unless $self->{_HTML_DOM_elem_handlers};
	for(keys %{$self->{_HTML_DOM_elem_handlers}}) {
		$$tb{"_tweak_$_"} =
			$self->{_HTML_DOM_elem_handlers}{$_}
	}

	return # nothing;
}

=back

=head2 Other DOM Methods

=over 4

=cut


#-------------- DOM STUFF (CORE) ---------------- #

=item doctype

Returns nothing

=item implementation

Returns the L<HTML::DOM::Implementation> object.

=item documentElement

Returns the <html> element.

=item createElement ( $tag )

=item createDocumentFragment

=item createTextNode ( $text )

=item createComment ( $text )

=item createAttribute ( $name )

Each of these creates a node of the appropriate type.

=item createProcessingInstruction

=item createEntityReference

These two throw an exception.

=for comment
=item createCSSStyleSheet
This creates a style sheet (L<CSS::DOM> object).

=item getElementsByTagName ( $name )

C<$name> can be the name of the tag, or '*', to match all tag names.  This
returns a node list object in scalar context, or a list in list context.

=item importNode ( $node, $deep )

Clones the C<$node>, setting its C<ownerDocument> attribute to the document
with which this method is called.  If C<$deep> is true, the C<$node> will
be
cloned recursively.

=cut

sub doctype {} # always null

sub implementation {
	no warnings 'once';
	return $HTML::DOM::Implementation::it;
}

sub documentElement {
	($_[0]->content_list)[0]
}

sub createElement {
	my $elem = HTML::DOM::Element->new($_[1]);
	$elem->_set_ownerDocument(shift);
	$elem;
}

sub createDocumentFragment {
	my $thing = HTML::DOM::DocumentFragment->new;
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createTextNode {
	my $thing = HTML::DOM::Text->new(@_[1..$#_]);
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createComment {
	my $thing = HTML::DOM::Comment->new(@_[1..$#_]);
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createCDATASection {
	die HTML::DOM::Exception->new( NOT_SUPPORTED_ERR,
		'The HTML DOM does not support CDATA sections' );
}

sub createProcessingInstruction {
	die HTML::DOM::Exception->new( NOT_SUPPORTED_ERR,
		'The HTML DOM does not support processing instructions' );
}

sub createAttribute {
	my $thing = HTML::DOM::Attr->new(@_[1..$#_]);
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createEntityReference {
	die HTML::DOM::Exception->new( NOT_SUPPORTED_ERR,
		'The HTML DOM does not support entity references' );
}

#sub createCSSStyleSheet {
# shift;
# require CSS'DOM;
# ~~~
#}

sub getElementsByTagName {
	my($self,$tagname) = @_;
	#warn "You didn't give me a tag name." if !defined $tagname;
	if (wantarray) {
		return $tagname eq '*'
			? grep tag $_ !~ /^~/, $self->descendants
			: $self->find($tagname);
	}
	else {
		my $list = HTML::DOM::NodeList::Magic->new(
			$tagname eq '*'
			  ? sub { grep tag $_ !~ /^~/, $self->descendants }
			  : sub { $self->find($tagname) }
		);
		$self-> _register_magic_node_list($list);
		$list;
	}
}

sub importNode {
	my ($self, $node, $deep) = @_;
	die HTML::DOM::Exception->new( NOT_SUPPORTED_ERR,
		'Documents cannot be imported.' )
		if $node->nodeType ==DOCUMENT_NODE;
	(my $clown = $node->cloneNode($deep))
		->_set_ownerDocument($self);
	if($clown->can('descendants')) { # otherwise it’s an Attr, so this
	for($clown->descendants) {       # isn’t necessary
		delete $_->{_HTML_DOM_owner};
	}}
	$clown;
}

#-------------- DOM STUFF (HTML) ---------------- #

=item alinkColor

=item background

=item bgColor

=item fgColor

=item linkColor

=item vlinkColor

These six methods return (optionally set) the corresponding attributes of 
the body element.  Note that most of the names do not map directly to the 
names of
the attributes.  C<fgColor> refers to the C<text> attribute.  Those that
end
with 'linkColor' refer to the attributes of the same name but without the
'Color' on the end.

=cut

sub alinkColor { (shift->body||return "")->aLink     (@_) }
sub background { (shift->body||return "")->background(@_) }
sub    bgColor { (shift->body||return "")->bgColor   (@_) }
sub    fgColor { (shift->body||return "")->text      (@_) }
sub  linkColor { (shift->body||return "")->link      (@_) }
sub vlinkColor { (shift->body||return "")->vLink     (@_) }

=item title

Returns (or optionally sets) the title of the page.

=item referrer

Returns the page's referrer.

=item domain

Returns the domain name portion of the document's URL.

=item URL

Returns the document's URL.

=item body

Returns the body element, or the outermost frame set if the document has
frames.  You can set the body by passing an element as an argument, in
which
case the old body element is returned.

=item images

=item applets

=item links

=item forms

=item anchors

These five methods each return a list of the appropriate elements in list
context, or an L<HTML::DOM::Collection> object in scalar context.  In this
latter case, the object will update automatically when the document is
modified.

In the case of C<forms> you can access those by using the HTML::DOM object
itself as a hash.  I.e., you can write C<< $doc->{f} >> instead of
S<< C<< $doc->forms->{f} >> >>.

=for comment
# ~~~ Why on earth did I ever put this in the docs?!
B<TO DO:> I need to make these methods cache the HTML collection objects
that they create. Once I've done this, I can make list context use those
objects, as well as scalar context.

=item cookie

This returns a string containing the document's cookies (the format may
still change).  If you pass an 
argument, it
will set a cookie as well.  Both Netscape-style and RFC2965-style cookie
headers are supported.

=cut

sub title {
	my $doc = shift;
	if(my $title_elem = $doc->find('title')) {
		$title_elem->text(@_);
	}
	else {
		return "" unless @_;
		( $doc->find('head')
		   || ( $doc->find('html')
		         || $doc->appendChild($doc->createElement('html'))
		      )->appendChild($doc->createElement('head'))
		)->appendChild(
			my $t = $doc->createElement('title')
		);
		$t->text(@_);
		return "";
	}
}

sub referrer {
	my $referrer = shift->{_HTML_DOM_referrer};
	defined $referrer ? $referrer : ();
}

sub domain { no strict;
	my $doc = shift;
	host {ref $doc->{_HTML_DOM_url} ? $doc->{_HTML_DOM_url}
	  : ($doc->{_HTML_DOM_url} = URI->new($doc->{_HTML_DOM_url}))};
}

sub URL {
	my $url = shift->{_HTML_DOM_url};
	defined $url ? "$url" : undef;
}

sub body { # ~~~ this needs to return the outermost frameset element if
            #     there is one (if the frameset is always the second child
            #     of <html>, then it already does).
	my $body = ($_[0]->documentElement->content_list)[1];
	if (!$body || $body->tag !~ /^(?:body|frameset)\z/) {
		$body = $_[0]->find('body','frameset');
	}
	if(@_>1) {
		my $doc_elem = $_[0]->documentElement;
		# I'm using the replaceChild rather than replace_with,
		# despite the former's convoluted syntax, since the former
		# has the appropriate error-checking code (or will), and
		# also because it triggers mutation events.
		$doc_elem->replaceChild($_[1],$body)
	}
	else {
		$body
	}
}

sub images {
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'img', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'img', $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub applets {
	my $self = shift;
	if (wantarray) {
		return grep $_->tag =~ /^(?:objec|apple)t\z/,
			$self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep $_->tag =~ /^(?:objec|apple)t\z/,
		        $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub links {
	my $self = shift;
	if (wantarray) {
		return grep {
			my $tag = tag $_;
			$tag eq 'area' || $tag eq 'a'
				&& defined $_->attr('href')
		} $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep {
		        my $tag = tag $_;
		        $tag eq 'area' || $tag eq 'a'
		            && defined $_->attr('href')
		    } $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub forms {
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'form', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'form', $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub anchors {
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'a' && defined $_->attr('name'),
			$self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'a' && defined $_->attr('name'),
		        $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}


sub cookie {
  my $self = shift;
  return '' unless defined (my $jar = $self->{_HTML_DOM_jar});
  my $return;
  if (defined wantarray) {
    # Yes, this is nuts (getting HTTP::Cookies to join the cookies, and
    # splitting them, filtering them, and joining them again[!]),  but
    # &HTTP::Cookies::add_cookie_header is long and complicated, and I
    # don't want to replicate it here.
    no warnings 'uninitialized';
    my $reqclone = $self->{_HTML_DOM_response}->request->clone;
    # Yes  this  is  a  bit  strange,  but  we  don’t  want  to  put
    # ‘use HTTP::Header 1.59’ in this file, as it would mean loading the
    #  module even for people who are not using this  feature  or  who  are
    # duck-typing.
    if (!$reqclone->can('header_field_names')
     && $reqclone->isa("HTTP::Headers")) { VERSION HTTP::Headers:: 1.59 }
    for($reqclone->header_field_names) {
     /cookie/i and remove_header $reqclone $_;
    }
    $return = join ';', grep !/\$/, 
      $jar->add_cookie_header(
        $reqclone
      )-> header ('Cookie')
      # Pieces of this regexp were stolen from HTTP::Headers::Util:
      =~ /\G\s* # initial whitespace
          (
            [^\s=;,]+ # name
            \s*=\s*   # =
            (?:
              \"(?:[^\"\\]*(?:\\.[^\"\\]*)*)\" # quoted value
                |
              [^;,\s]*  # unquoted value
            )
          )
          \s*;?
         /xg;
  }
  if (@_) {
    return unless defined $self->{_HTML_DOM_response};
    require HTTP::Headers::Util;
    (undef,undef, my%split) =
	@{(HTTP::Headers::Util::split_header_words($_[0]))[0]};
    my $rfc;
    for(keys %split){
      # I *hope* this always works! (NS cookies should have no version.)
      ++ $rfc, last if lc $_ eq 'version';
    }
    (my $clone = $self->{_HTML_DOM_response}->clone)
     ->remove_header(qw/ Set-Cookie Set-Cookie2 /);
    $clone->header('Set-Cookie' . 2 x!! $rfc => $_[0]);
    $jar->extract_cookies($clone);
  }
  $return||'';
}

=item getElementById

=item getElementsByName

=item getElementsByClassName

These three do what their names imply.  The last two
will return a list in list context, or a node list
object in scalar context.  Calling them in list
context is probably more efficient.

=cut

sub getElementById {
  my(@pile) = grep ref($_), @{shift->{'_content'}};
  my $id = shift;
  my $this;
  while(@pile) {
    no warnings 'uninitialized';
    $this = shift @pile;
    $this->id eq $id and return $this;
    unshift @pile, grep ref($_), $this->content_list;
  }
  return;
}

sub getElementsByName {
	my($self,$name) = @_;
	if (wantarray) {
		return $self->look_down(name => "$name");
	}
	else {
		my $list = HTML::DOM::NodeList::Magic->new(
			  sub { $self->look_down(name => "$name"); }
		);
		$self-> _register_magic_node_list($list);
		$list;
	}
}

sub getElementsByClassName {
	splice @_, 2, @_, 1; # Remove extra elements; add a true third elem
	goto &HTML'DOM'Element'_getElementsByClassName;
}

# ---------- DocumentEvent interface -------------- #

=item createEvent ( $category )

Creates a new event object, believe it or not.

The C<$category> is the DOM event category, which determines what type of
event object will be returned. The currently supported event categories
are MouseEvents, UIEvents, HTMLEvents and MutationEvents.

You can omit the C<$category> to create an instance of the event base class
(not officially part of the DOM).

=cut

sub createEvent {
	require HTML'DOM'Event;
	HTML'DOM'Event'create_event($_[1]||'');
}

# ---------- DocumentView interface -------------- #

=item defaultView

Returns the L<HTML::DOM::View> object associated with the document.

There is no such object by default; you have to put one there yourself:

Although it is supposed to be read-only according to the DOM, you can set
this attribute by passing an argument to it.  It I<is> still marked as 
read-only in
L<C<%HTML::DOM::Interface>|HTML::DOM::Interface>.

If you do set it, it is recommended that the object be a subclass of
L<HTML::DOM::View>.

This attribute holds a weak reference to the object.

=cut

sub defaultView {
	my $self = shift;
	my $old = $self->{_HTML_DOM_view};
	if(@_) {
		weaken($self->{_HTML_DOM_view} = shift);
	}
	return defined $old ? $old : ();
}

# ---------- DocumentStyle interface -------------- #

=item styleSheets

Returns a L<CSS::DOM::StyleSheetList> of the document's style sheets, or a
simple list in list context.

=cut

sub styleSheets {
	my $doc = shift;
	my $ret = (
		$doc->{_HTML_DOM_sheets} or
		$doc->{_HTML_DOM_sheets} = (
			require CSS::DOM::StyleSheetList,
			new CSS::DOM::StyleSheetList
		),
		$doc->_populate_sheet_list,
		$doc->{_HTML_DOM_sheets}
	);
	wantarray ? @$ret : $ret;
}

=item innerHTML

Serialises and returns the HTML document.  If you pass an argument, it will
set the contents of the document via C<open>, C<write> and C<close>,
returning a serialisation of the old contents.

=cut

sub innerHTML  {
	my $self = shift;
	my $old;
	$old = join '' , $self->{_HTML_DOM_doctype}||'',
		map
		 HTML'DOM'Element'_html_element_adds_newline
		  ? substr((
		     as_HTML $_ (undef)x2,{}
		    ), 0, -1)
		  : $_->as_HTML((undef)x2,{}),
		 $self->content_list
	  if defined wantarray;
	if(@_){
		$self->open();
		$self->write(shift);
		$self->close();
	}
	$old
}


=item location

=item set_location_object (non-DOM)

C<location> returns the location object, if you've put one there with
C<set_location_object>. HTML::DOM doesn't actually implement such an object
itself, but provides the appropriate magic to make
C<< $doc->location($foo) >> translate into
C<< $doc->location->href($foo) >>.

BTW, the location object had better be true when used as a boolean, or
HTML::DOM will think it doesn't exist.

=cut

sub location {
	my $self = shift;
	@_ and ($$self{_HTML_DOM_loc}||die "Can't assign to location"
	                  ." without a location object")->href(@_);
	$$self{_HTML_DOM_loc}||()
}

sub set_location_object {
	$_[0]{_HTML_DOM_loc} = $_[1];
}


=item lastModified

This method returns the document's modification date as gleaned from the
response object passed to the constructor, in MM/DD/YYYY HH:MM:SS format.

If there is no modification date, an empty string is returned, but this
may change in the future.

=begin comment

When there is no modification date, the return value is different in every
browser.
NS 2-4 and Opera 9 have the epoch (in GMT format).
Firefox 3 has the time the page was loaded.
Safari 4 has an empty string (it uses GMT format when there is a mod time).
IE, 6-8 the only one to comply with HTML 5, has the current time; but HTML
5 is illogical, since it makes no sense for the modification time to keep
ticking away.

I’ve opted to use the empty string for now, since we can’t *really* find
out the modification time--only what the server *says* it is. And if the
server doesn’t say, it’s no use pretending that it did say it.

=end comment

=cut

sub lastModified {
	my $time = ($_[0]{_HTML_DOM_response} || return '')->last_modified
	 or return '';
	require Date'Format;
	Date'Format'time2str("%d/%m/%Y %X", $time);
}


=back

=cut


# ---------- OVERRIDDEN NODE & EVENT TARGET METHODS -------------- #

sub ownerDocument {} # empty list
sub nodeName { '#document' }
{ no warnings 'once'; *nodeType = \& DOCUMENT_NODE; }

=head2 Other (Non-DOM) Methods

(See also L</EVENT HANDLING>, below.)

=over 4

=item $tree->base

Returns the base URL of the page; either from a <base href=...> tag, from
the response object passed to C<new>, or the
URL passed to C<new>.

=cut

sub base {
	my $doc = shift;
	if(
	 my $base_elem = $doc->look_down(_tag => 'base', href => qr)(?:\)))
	){
		return ''.$base_elem->attr('href');
	}
	elsif (my $r = $$doc{_HTML_DOM_response}) {
		my $base;
		($base) = $r->header('Content-Base')
		    or ($base) = $r->header('Content-Location')
		    or $base = $r->header('Base');
		# URI does not document $URI::scheme_re, but HTTP::Response
		# (which is in a separate distribution) uses it.  It seems
		# unlikely that it will go away in future URI versions, as
		# that would break existing versions of HTTP::Response.
		if ($base && $base =~ /^$URI::scheme_re:/o) {
			# already absolute
			return $base;
		}
		my $req = request $r;
		my $uri = $req ? uri $req : $doc->URL;
		return undef unless $uri;
		# Work around URI bug.
		if (!defined $base && $uri =~ /^[Dd][Aa][Tt][Aa]:/) {
			return $uri;
		}
		no warnings 'uninitialized';
		''.new_abs URI $base,$uri;
	}
	else {
		$doc->URL
	}
}

=item $tree->magic_forms

This is mainly for internal use.  It returns a boolean indicating whether
the parser needed to associate formies with a form that did not contain
them.  This happens when a closing </form> tag is missing and the form is
closed implicitly, but a formie is encountered later.

=cut

sub magic_forms { @_ and ++$_[0]{_HTML_DOM_mg_f}; $_[0]{_HTML_DOM_mg_f} }

=back

=head1 HASH ACCESS

You can use an HTML::DOM object as a hash ref to access it's form elements
by name.  So C<< $doc->{yayaya} >> is short for
S<< C<< $doc->forms->{yayaya} >> >>.

=head1 EVENT HANDLING

HTML::DOM supports both the DOM Level 2 event model and the HTML 4 event
model.

Throughout this documentation, we make use of HTML 5's distinction between
handlers and listeners: An event handler is the result of an HTML element
beginning with 'on', e.g. onsubmit.  These are also accessible via the DOM.
(We also use the word 'handler' in other contexts, such as the 'default
event handler'.)
Event listeners are registered solely with the C<addEventListener> method
and can be removed with C<removeEventListener>.

HTML::DOM accepts as an event handler a coderef, an object with a
C<call_with> method, or an object with C<&{}> overloading.  If the
C<call_with> method is present, it is called with the current event
target as the first argument and the event object as the second.
This is to allow for objects that wrap JavaScript functions (which must be called with the event target as the B<this> value).

An event listener is a coderef, an object with a C<handleEvent>
method or an object with C<&{}> overloading.  HTML::DOM does not implement
any classes that provide a C<handleEvent> method, but will support any
object that has one.

Listeners and handlers differ in one important aspect.  A listener has to
call C<preventDefault> on the event object to cancel the default action.  A
handler simply returns a defined false value (except for mouseover events,
which must return a true value to cancel the default).

=head2 Default Actions

Default actions that HTML::DOM is capable of handling internally (such as
triggering a DOMActivate event when an element is clicked, and triggering a
form's submit event when the submit button is activated) are dealt with
automatically.  You don't have to worry about those.  For others, read
on....

To specify the default actions associated with an event, provide a
subroutine (in this case, it not being part of the DOM, you can't use an
object with a C<handleEvent> method) via the C<default_event_handler_for> 
and 
C<default_event_handler> methods.

With the former, you can specify the
default action to be taken when a particular type of event occurs.  The
currently supported types are:

  submit         when a form is submitted
  link           called when a link is activated (DOMActivate event)

Pass the type of event as the first argument and a code ref as the second
argument.  When the code ref is called, its sole argument will
be the event object.  For instance:

  $dom_tree->default_event_handler_for( link => sub {
         my $event = shift;
         go_to( $event->target->href );
  });
  sub go_to { ... }

C<default_event_handler_for> with just one argument returns the 
currently 
assigned coderef.  With two arguments it returns the old one after
assigning the new one.

Use C<default_event_handler> (without the C<_for>) to specify a fallback
subroutine that will be used for events not in the list above, and for
events in the list above that do not have subroutines assigned to them.
Without any arguments it will return the currently 
assigned coderef.  With an argument it will return the old one after
assigning the new one.

=head2 Dispatching Events

HTML::DOM::Node's C<dispatchEvent> method triggers the appropriate event 
listeners, but does B<not> call any default actions associated with it.
The return value is a boolean that indicates whether the default action
should be taken.

H:D:Node's C<trigger_event> method will trigger the event for real. It will
call C<dispatchEvent> and, provided it returns true, will call the default
event handler.

=head2 HTML Event Attributes

The C<event_attr_handler> can be used to assign a coderef that will turn
text assigned to an event attribute (e.g., C<onclick>) into an event
handler. The
arguments to the routine will be (0) the element, (1) the name (aka
type) of 
the event (without the initial 'on'), (2) the value of the attribute and
(3) the offset within the source of the attribute's value. (Actually, if
the value is within quotes, it is the offset of the first quotation mark.
Also, it will be C<undef> for generated HTML [source code passed to the
C<write> method by an element handler].) 
As 
with C<default_event_handler>, you
can replace an existing handler with a new one, in which case the old
handler is returned. If you call this method without arguments, it returns
the current handler. Here is an example of its use, that assumes that
handlers are Perl code:

  $dom_tree->event_attr_handler(sub {
          my($elem, $name, $code, $offset) = @_;
          my $sub = eval "sub { $code }";
          return sub {
                  local *_ = \$elem;
                  &$sub;
          };
  });

The event attribute handler will be called whenever an element attribute 
whose name
begins with 'on' (case-tolerant) is modified. (For efficiency's sake, I may
change it to call the event attribute handler only when the event is
triggered, so it is not called unnecessarily.)

=head2 When an Event Handler Dies

Use C<error_handler> to assign a coderef that will be called whenever an
event listener (or handler) raises an error. The error will be contained in 
C<$@>.

=head2 Other Event-Related Methods

=over

=item $tree->event_parent

=item $tree->event_parent( $new_val )

This method lets you provide an object that is added to the top of the
event dispatch chain. E.g., if you want the view object (the value of
C<defaultView>, aka the window) to have event handlers called before the
document in the capture phase, and after it in the bubbling phase, you can
set it like this (see also L</defaultView>, above):

  $tree->event_parent( $tree->defaultView );

This holds a weak reference.

=item $tree->event_listeners_enabled

=item $tree->event_listeners_enabled( $new_val )

This attribute, which is true by default, can be used to disable event
handlers and listeners. (Default event handlers [see above] still run, 
though.)

=back

=cut


# ---------- NON-DOM EVENT METHODS -------------- #

sub event_attr_handler {
	my $old = $_[0]->{_HTML_DOM_event_attr_handler};
	$_[0]->{_HTML_DOM_event_attr_handler} = $_[1]  if @_ > 1;
	$old;
}
sub default_event_handler {
	my $old = $_[0]->{_HTML_DOM_default_event_handler};
	$_[0]->{_HTML_DOM_default_event_handler} = $_[1] if @_ > 1;
	$old;
}
sub default_event_handler_for {
	my $old = $_[0]->{_HTML_DOM_dehf}{$_[1]};
	$_[0]->{_HTML_DOM_dehf}{$_[1]} = $_[2] if @_ > 2;
	$old;
}
sub error_handler {
	my $old = $_[0]->{_HTML_DOM_error_handler};
	$_[0]->{_HTML_DOM_error_handler} = $_[1] if @_ > 1;
	$old;
}

sub event_parent {
	my $old = (my $self = shift) ->{_HTML_DOM_event_parent};
	weaken($self->{_HTML_DOM_event_parent} = shift) if @_;
	$old
}

sub event_listeners_enabled {
	my $old = (my $Self = shift)->{_HTML_DOM_doevents};
	@_ and $$Self{_HTML_DOM_doevents} = !!shift;
	defined $old ? $old : 1; # true by default
}


# ---------- NODE AND SHEET LIST HELPER METHODS -------------- #

sub _modified { # tells all it's magic nodelists that they're stale
                # and also rewrites the style sheet list if present
	my $list = $_[0]{_HTML_DOM_node_lists};
	my $list_is_stale;
	for (@$list) {
		defined() ? $_->_you_are_stale : ++$list_is_stale
	}
	if($list_is_stale) {
		@$list = grep defined, @$list;
		weaken $_ for @$list;
	}
	
	$_[0]->_populate_sheet_list
}

sub _populate_sheet_list { # called both by styleSheets and _modified
	for($_[0]->{_HTML_DOM_sheets}||return) {
		@$_ = map sheet $_,
			$_[0]->look_down(_tag => qr/^(?:link|style)\z/);
	}
}

sub _register_magic_node_list { # adds the node list to the list of magic
                                # node lists that get notified  automatic-
                                # ally whenever the doc structure changes
	push @{$_[0]{_HTML_DOM_node_lists}}, $_[1];
	weaken $_[0]{_HTML_DOM_node_lists}[-1];
}



1;
__END__

=head1 CLASSES AND DOM INTERFACES

Here are the inheritance hierarchy of HTML::DOM's various classes and the
DOM interfaces those classes implement. The classes in the left column all
begin with 'HTML::DOM::', which is omitted for brevity, except for
HTML::DOM itself, which is listed with its full name. Items in brackets
have
not yet been implemented. (See also L<HTML::DOM::Interface> for a
machine-readable list of standard methods.)

  Class Inheritance Hierarchy             Interfaces
  ---------------------------             ----------
  
  Exception                               DOMException, EventException
  Implementation                          DOMImplementation,
                                           [DOMImplementationCSS]
  Node                                    Node, EventTarget
      DocumentFragment                    DocumentFragment
      HTML::DOM                           Document, HTMLDocument,
                                            DocumentEvent, DocumentView,
                                            DocumentStyle, [DocumentCSS]
      CharacterData                       CharacterData
          Text                            Text
          Comment                         Comment
      Element                             Element, HTMLElement,
                                            ElementCSSInlineStyle
          Element::HTML                   HTMLHtmlElement
          Element::Head                   HTMLHeadElement
          Element::Link                   HTMLLinkElement, LinkStyle
          Element::Title                  HTMLTitleElement
          Element::Meta                   HTMLMetaElement
          Element::Base                   HTMLBaseElement
          Element::IsIndex                HTMLIsIndexElement
          Element::Style                  HTMLStyleElement, LinkStyle
          Element::Body                   HTMLBodyElement
          Element::Form                   HTMLFormElement
          Element::Select                 HTMLSelectElement
          Element::OptGroup               HTMLOptGroupElement
          Element::Option                 HTMLOptionElement
          Element::Input                  HTMLInputElement
          Element::TextArea               HTMLTextAreaElement
          Element::Button                 HTMLButtonElement
          Element::Label                  HTMLLabelElement
          Element::FieldSet               HTMLFieldSetElement
          Element::Legend                 HTMLLegendElement
          Element::UL                     HTMLUListElement
          Element::OL                     HTMLOListElement
          Element::DL                     HTMLDListElement
          Element::Dir                    HTMLDirectoryElement
          Element::Menu                   HTMLMenuElement
          Element::LI                     HTMLLIElement
          Element::Div                    HTMLDivElement
          Element::P                      HTMLParagraphElement
          Element::Heading                HTMLHeadingElement
          Element::Quote                  HTMLQuoteElement
          Element::Pre                    HTMLPreElement
          Element::Br                     HTMLBRElement
          Element::BaseFont               HTMLBaseFontElement
          Element::Font                   HTMLFontElement
          Element::HR                     HTMLHRElement
          Element::Mod                    HTMLModElement
          Element::A                      HTMLAnchorElement
          Element::Img                    HTMLImageElement
          Element::Object                 HTMLObjectElement
          Element::Param                  HTMLParamElement
          Element::Applet                 HTMLAppletElement
          Element::Map                    HTMLMapElement
          Element::Area                   HTMLAreaElement
          Element::Script                 HTMLScriptElement
          Element::Table                  HTMLTableElement
          Element::Caption                HTMLTableCaptionElement
          Element::TableColumn            HTMLTableColElement
          Element::TableSection           HTMLTableSectionElement
          Element::TR                     HTMLTableRowElement
          Element::TableCell              HTMLTableCellElement
          Element::FrameSet               HTMLFrameSetElement
          Element::Frame                  HTMLFrameElement
          Element::IFrame                 HTMLIFrameElement
  NodeList                                NodeList
      NodeList::Radio
  NodeList::Magic                         NodeList
  NamedNodeMap                            NamedNodeMap
  Attr                                    Node, Attr, EventTarget
  Collection                              HTMLCollection
      Collection::Elements
      Collection::Options
  Event                                   Event
      Event::UI                           UIEvent
          Event::Mouse                    MouseEvent
      Event::Mutation                     MutationEvent
  View                                    AbstractView, ViewCSS

The EventListener interface is not implemented by HTML::DOM, but is 
supported.
See L</EVENT HANDLING>, above.

Not listed above is L<HTML::DOM::EventTarget>, which is a base class both
for L<HTML::DOM::Node> and L<HTML::DOM::Attr>. The format I'm using above
doesn't allow for multiple inheritance, so I probably need to redo it.

HTML::DOM::Node also implements the L<HTML::Element> interface, but with a
few
differences. In particular:

=over

=item *

Any methods that expect text nodes to be just strings are unreliable. See
the note under L<HTML::Element/objectify_text>.

=item *

HTML::Element's tree-manipulation methods don't trigger mutation events.

=item *

HTML::Element's C<delete> method is not necessary, because
HTML::DOM uses weak references (for 'upward' references in the object
tree).

=back

=head1 IMPLEMENTATION NOTES

=over 4

=item *

Objects' attributes are accessed via methods of the same name. When the
method
is invoked, the current value is returned. If an argument is supplied, the
attribute is set (unless it is read-only) and its old value returned.

=item *

Where the DOM spec. says to use null, undef or an empty list is used.

=item *

Instead of UTF-16 strings, HTML::DOM uses Perl's Unicode strings (which
happen to be stored as UTF-8 internally). The only significant difference
this makes is to C<length>, C<substringData> and other methods of Text and
Comment nodes. These methods behave in a Perlish way (i.e., the offsets and
lengths are specified in Unicode characters, not in UTF-16 bytes). The
alternate methods C<length16>, C<substringData16> I<et al.> use UTF-16 for 
offsets
and are standards-compliant in that regard (but the string returned by
C<substringData16> is still a regular Perl string).

=begin for-me

# ~~~ These need to be documented in the man pages for Comment and Text
C<length16>, C<substringData16>
C<insertData16>, C<deleteData16>, C<replaceData16> and C<splitText16>.

=end for-me

=item *

Each method that returns a NodeList will return a NodeList
object in scalar context, or a simple list in list context. You can use
the object as an array ref in addition to calling its C<item> and 
C<length> methods.

=item *

In cases where a method is supposed to return something implementing
the DOMTimeStamp interface, a simple Perl scalar is returned, containing
the time as returned by Perl’s built-in C<time> function.

=back

=head1 ACKNOWLEDGEMENTS

Much of the code was stolen from HTML::Tree.  In fact, HTML::DOM used to
extend HTML::Tree, but the two were merged to allow a whole pile of
hacks to be removed.

=for comment
Actually, they haven’t been removed yet, but are still present.
HTML::Element and HTML::TreeBuilder have simply been forked so far. The
code still needs refactoring.

=head1 PREREQUISITES

L<perl> 5.8.3 or later

L<Exporter> 5.57 or later

L<URI.pm|URI>

L<LWP> 5.13 or later

L<CSS::DOM> 0.06 or later

L<Scalar::Util> 1.14 or later

L<HTML::Tagset> 3.02 or later

L<HTML::Parser> 3.46 or later

L<HTML::Encoding> is required if a file name is passed to 
C<parse_file>.

L<Tie::RefHash::Weak> 0.08 or higher, if you are using perl 5.8.x

=head1 BUGS

=for comment
(since I might use it as a template if I need it later)
(See also BUGS in 
L<HTML::DOM::Element::Option/BUGS|HTML::DOM::Element::Option>)

=over 4

=item -

Element handlers are not currently called during assignments to 
C<innerHTML>.

=item -

L<HTML::DOM::View>'s C<getComputedStyle> does not currently return a
read-only style object; nor are lengths converted to absolute values.
Currently there is no way to specify the medium. Any style rules that apply
to specific media are ignored.

=back

B<To report bugs,> please e-mail the author.

=head1 AUTHOR, COPYRIGHT & LICENSE

Copyright (C) 2007-16 Father Chrysostomos

  $text = new HTML::DOM ->createTextNode('sprout');
  $text->appendData('@');
  $text->appendData('cpan.org');
  print $text->data, "\n";

This program is free software; you may redistribute it and/or modify
it under the same terms as perl.

=head1 SEE ALSO

Each of the classes listed above L</CLASSES AND DOM INTERFACES>

L<HTML::DOM::Exception>, L<HTML::DOM::Node>, L<HTML::DOM::Event>,
L<HTML::DOM::Interface>

L<HTML::Tree>, L<HTML::TreeBuilder>, L<HTML::Element>, L<HTML::Parser>,
L<LWP>, L<WWW::Mechanize>, L<HTTP::Cookies>, 
L<WWW::Mechanize::Plugin::JavaScript>,
L<HTML::Form>, L<HTML::Encoding>

The DOM Level 1 specification at S<L<http://www.w3.org/TR/REC-DOM-Level-1>>

The DOM Level 2 Core specification at
S<L<http://www.w3.org/TR/DOM-Level-2-Core>>

The DOM Level 2 Events specification at
S<L<http://www.w3.org/TR/DOM-Level-2-Events>>

etc.
