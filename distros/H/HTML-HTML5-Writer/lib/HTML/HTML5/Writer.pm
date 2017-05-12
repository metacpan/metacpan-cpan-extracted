package HTML::HTML5::Writer;

use 5.010;
use base qw[Exporter];
use strict;
use HTML::HTML5::Entities 0.001 qw[];
use XML::LibXML qw[:all];

use constant {
	DOCTYPE_NIL              => '',
	DOCTYPE_HTML32           => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">',
	DOCTYPE_HTML4            => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
	DOCTYPE_HTML5            => '<!DOCTYPE html>',
	DOCTYPE_LEGACY           => '<!DOCTYPE html SYSTEM "about:legacy-compat">',
	DOCTYPE_XHTML1           => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
	DOCTYPE_XHTML11          => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
	DOCTYPE_XHTML_BASIC      => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
	DOCTYPE_XHTML_RDFA       => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">',
	DOCTYPE_HTML2            => '<!DOCTYPE html PUBLIC "-//IETF//DTD HTML 2.0//EN">',
	DOCTYPE_HTML40           => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/1998/REC-html40-19980424/strict.dtd">',
	DOCTYPE_HTML40_STRICT    => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/1998/REC-html40-19980424/strict.dtd">',
	DOCTYPE_HTML40_LOOSE     => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/1998/REC-html40-19980424/loose.dtd">',
	DOCTYPE_HTML40_FRAMESET  => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Frameset//EN" "http://www.w3.org/TR/1998/REC-html40-19980424/frameset.dtd">',
	DOCTYPE_HTML401          => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
	DOCTYPE_HTML401_STRICT   => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
	DOCTYPE_HTML401_LOOSE    => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">',
	DOCTYPE_HTML401_FRAMESET => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
	DOCTYPE_XHTML1_STRICT    => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
	DOCTYPE_XHTML1_LOOSE     => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
	DOCTYPE_XHTML1_FRAMESET  => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
	DOCTYPE_XHTML_MATHML_SVG => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" "http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">',
	DOCTYPE_XHTML_BASIC_10   => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.0//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd">',
	DOCTYPE_XHTML_BASIC_11   => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
	DOCTYPE_HTML4_RDFA       => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/html401-rdfa11-1.dtd">',
	DOCTYPE_HTML401_RDFA11   => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/html401-rdfa11-1.dtd">',
	DOCTYPE_HTML401_RDFA10   => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/html401-rdfa-1.dtd">',
	DOCTYPE_XHTML_RDFA10     => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">',
	DOCTYPE_XHTML_RDFA11     => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">',
};

our $VERSION = '0.201';

our %EXPORT_TAGS = (
	doctype => [qw(DOCTYPE_NIL DOCTYPE_HTML32 DOCTYPE_HTML4 DOCTYPE_HTML5
		DOCTYPE_LEGACY DOCTYPE_XHTML1 DOCTYPE_XHTML11 DOCTYPE_XHTML_BASIC
		DOCTYPE_XHTML_RDFA DOCTYPE_HTML2 DOCTYPE_HTML40 DOCTYPE_HTML40_STRICT
		DOCTYPE_HTML40_LOOSE DOCTYPE_HTML40_FRAMESET DOCTYPE_HTML401
		DOCTYPE_HTML401_STRICT DOCTYPE_HTML401_LOOSE DOCTYPE_HTML401_FRAMESET
		DOCTYPE_XHTML1_STRICT DOCTYPE_XHTML1_LOOSE DOCTYPE_XHTML1_FRAMESET
		DOCTYPE_XHTML_MATHML_SVG DOCTYPE_XHTML_BASIC_10 DOCTYPE_XHTML_BASIC_11
		DOCTYPE_HTML4_RDFA DOCTYPE_HTML401_RDFA11 DOCTYPE_HTML401_RDFA10
		DOCTYPE_XHTML_RDFA10 DOCTYPE_XHTML_RDFA11)]
	);
our @EXPORT_OK = @{ $EXPORT_TAGS{doctype} };

our @VoidElements = qw(area base br col command embed hr
	img input keygen link meta param source track wbr);
our @BooleanAttributes = qw(
	hidden
	audio@autoplay audio@preload audio@controls audio@loop
	button@autofocus button@disabled button@formnovalidate 
	command@checked command@disabled
	details@open
	dl@compact
	fieldset@disabled
	form@novalidate
	hr@noshade
	iframe@seamless
	img@ismap
	input@autofocus input@checked input@disabled input@formnovalidate
		input@multiple input@readonly input@required
	keygen@autofocus keygen@disabled
	ol@reversed
	optgroup@disabled
	option@disabled option@selected
	script@async script@defer
	select@autofocus select@disabled select@multiple select@readonly
		select@required
	style@scoped
	textarea@autofocus textarea@disabled textarea@required
	time@pubdate
	track@default
	video@autoplay video@preload video@controls video@loop
	);
our @OptionalStart = qw(html head body tbody);
our @OptionalEnd = qw(html head body tbody dt dd li optgroup
	option p rp rt td th tfoot thead tr);

sub new
{
	my ($class, %opts) = @_;
	my $self = bless \%opts => $class;
	
	$self->{'markup'}   //= 'html';
	$self->{'charset'}  //= 'utf8';
	$self->{'refs'}     //= 'hex';
	$self->{'doctype'}  //= ($self->is_xhtml? DOCTYPE_LEGACY : DOCTYPE_HTML5);
	$self->{'polyglot'} //= !!$self->is_xhtml;
	
	return $self;
}

sub is_xhtml
{
	my ($self) = @_;
	return ($self->{'markup'} =~ m'^(xml|xhtml|application/xml|text/xml|application/xhtml\+xml)$'i);
}

sub is_polyglot
{
	my ($self) = @_;
	return $self->{'polyglot'};
}

sub should_quote_attributes
{
	my ($self) = @_;
	return $self->{'quote_attributes'} if exists $self->{'quote_attributes'};
	return $self->is_xhtml || $self->is_polyglot;
}

sub should_slash_voids
{
	my ($self) = @_;
	return $self->{'voids'} if exists $self->{'voids'};
	return $self->is_xhtml || $self->is_polyglot;
}

sub should_force_end_tags
{
	my ($self) = @_;
	return $self->{'end_tags'} if exists $self->{'end_tags'};
	return $self->is_xhtml || $self->is_polyglot;
}

sub should_force_start_tags
{
	my ($self) = @_;
	return $self->{'start_tags'} if exists $self->{'start_tags'};
	return $self->is_xhtml || $self->is_polyglot;
}

sub document
{
	my ($self, $document) = @_;
	my @childNodes = $document->childNodes;
	return $self->doctype
		. join '', (map { $self->_element_etc($_); } @childNodes);
}

sub doctype
{
	my ($self) = @_;
	return $self->{'doctype'};
}

sub _element_etc
{
	my ($self, $etc) = @_;

	if ($etc->nodeName eq '#text')
		{ return $self->text($etc); }
	elsif ($etc->nodeName eq '#comment')
		{ return $self->comment($etc); }
	elsif ($etc->nodeName eq '#cdata-section')
		{ return $self->cdata($etc); }
	elsif ($etc->isa('XML::LibXML::PI'))
		{ return $self->pi($etc); }
	else
		{ return $self->element($etc); }			
}

sub element
{
	my ($self, $element) = @_;
	
	return $element->toString
		unless $element->namespaceURI eq 'http://www.w3.org/1999/xhtml';
	
	my $rv = '';
	my $tagname  = $element->nodeName;
	my %attrs    = map { $_->nodeName => $_ } $element->attributes;
	my @kids     = $element->childNodes;

	if ($tagname eq 'html' && !$self->is_xhtml && !$self->is_polyglot)
	{
		delete $attrs{'xmlns'};
	}

	my $omitstart = 0;
	if (!%attrs and !$self->should_force_start_tags and grep { $tagname eq $_ } @OptionalStart)
	{
		$omitstart += eval "return \$self->_check_omit_start_${tagname}(\$element);";
	}

	my $omitend = 0;
	if (!$self->should_force_end_tags and grep { $tagname eq $_ } @OptionalEnd)
	{
		$omitend += eval "return \$self->_check_omit_end_${tagname}(\$element);";
	}

	unless ($omitstart)
	{
		$rv .= '<'.$tagname;
		foreach my $a (sort keys %attrs)
		{
			$rv .= ' '.$self->attribute($attrs{$a}, $element);
		}
	}
	
	if (!@kids and grep { $tagname eq $_ } @VoidElements and !$omitstart)
	{
		$rv .= $self->should_slash_voids ? ' />' : '>';
		return $rv;
	}
	
	$rv .= '>' unless $omitstart;
	
	foreach my $kid (@kids)
	{
		$rv .= $self->_element_etc($kid);			
	}
	
	unless ($omitend)
	{
		$rv .= '</'.$tagname.'>';
	}
	
	return $rv;
}

sub attribute
{
	my ($self, $attr, $element) = @_;
	
	my $minimize  = 0;
	my $quote     = 1;
	my $quotechar = '"';
	
	my $attrname = $attr->nodeName;
	my $elemname = $element ? $element->nodeName : '*';
	
	unless ($self->should_quote_attributes)
	{
		if (($attr->value eq $attrname or $attr->value eq '')
		and grep { $_ eq $attrname or $_ eq sprintf('%s@%s',$elemname,$attrname) } @BooleanAttributes)
		{
			return $attrname;
		}
		
		if ($attr->value =~ /^[A-Za-z0-9\._:-]+$/)
		{
			return sprintf('%s=%s', $attrname, $attr->value);
		}
	}
	
	my $encoded_value;
	if ($attr->value !~ /\"/)
	{
		$quotechar     = '"';
		$encoded_value = $self->encode_entities($attr->value);
	}
	elsif ($attr->value !~ /\'/)
	{
		$quotechar     = "'";
		$encoded_value = $self->encode_entities($attr->value);
	}
	else
	{
		$quotechar     = '"';
		$encoded_value = $self->encode_entities($attr->value,
			characters => "\"");
	}
	
	return sprintf('%s=%s%s%s', $attrname, $quotechar, $encoded_value, $quotechar);
}

sub comment
{
	my ($self, $text) = @_;
	return '<!--' . $self->encode_entities($text->nodeValue) . '-->';
}

sub pi
{
	my ($self, $pi) = @_;
	if ($pi->nodeName eq 'decode')
	{
		return HTML::HTML5::Entities::decode($pi->textContent);
	}
	return $pi->toString;
}

sub cdata
{
	my ($self, $text) = @_;
	if ($self->is_polyglot && $text->parentNode->nodeName =~ /^(script|style)$/i)
	{
		return '/* <![CDATA[ */' . $text->nodeValue . '/* ]]> */';
	}
	elsif (!$self->is_xhtml && $text->parentNode->nodeName =~ /^(script|style)$/i)
	{
		return $text->nodeValue;
	}
	elsif(!$self->is_xhtml)
	{
		return $self->text($text);
	}
	else
	{
		return '<![CDATA[' . $text->nodeValue . ']]>';
	}
}
	
sub text
{
	my ($self, $text) = @_;
	if ($self->is_polyglot && $text->parentNode->nodeName =~ /^(script|style)$/i)
	{
		return '/* <![CDATA[ */' . $text->nodeValue . '/* ]]> */';
	}
	elsif (!$self->is_xhtml && $text->parentNode->nodeName =~ /^(script|style)$/i)
	{
		return $text->nodeValue;
	}
	elsif ($text->parentNode->nodeName =~ /^(script|style)$/i)
	{
		return '<![CDATA[' . $text->nodeValue . ']]>';
	}
	return $self->encode_entities($text->nodeValue,
		characters => "<>");
}
	
sub encode_entities
{
	my ($self, $string, %options) = @_;
	
	my $characters = $options{'characters'};
	$characters   .= '&';
	$characters   .= '\x{0}-\x{8}\x{B}\x{C}\x{E}-\x{1F}\x{26}\x{7F}';
	$characters   .= '\x{80}-\x{FFFFFF}' unless $self->{'charset'} =~ /^utf[_-]?8$/i;
	
	my $regexp = qr/[$characters]/;
	
	local $HTML::HTML5::Entities::hex = ($self->{'refs'} !~ /dec/i);
	return HTML::HTML5::Entities::encode_entities($string, $regexp);
}

sub encode_entity
{
	my ($self, $char) = @_;

	local $HTML::HTML5::Entities::hex = ($self->{'refs'} !~ /dec/i);
	return HTML::HTML5::Entities::encode_entities($char, qr/./);
}

sub _check_omit_end_body
{
	my ($self, $element) = @_;
	my $next = $element->nextSibling;
	unless (defined $next && $next->nodeName eq '#comment')
	{
		return 1 if $element->childNodes || !$self->_check_omit_start_body($element);
	}
}

sub _check_omit_end_head
{
	my ($self, $element) = @_;
	my $next = $element->nextSibling;
	return 0 unless defined $next;
	return 0 if $next->nodeName eq '#comment';
	return 0 if $next->nodeName eq '#text' && $next->nodeValue =~ /^\s/;
	return 1;
}

sub _check_omit_end_html
{
	my ($self, $element) = @_;
	
	my @bodies = $element->getChildrenByTagName('body');
	if ($bodies[-1]->childNodes || $bodies[-1]->attributes)
	{
		return !defined $element->nextSibling;
	}
}

sub _check_omit_end_dd
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( dd | dt )$/x;
}

*_check_omit_end_dt = \&_check_omit_end_dd;

sub _check_omit_end_li
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( li )$/x;
}

sub _check_omit_end_optgroup
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( optgroup )$/x;
}

sub _check_omit_end_option
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( option | optgroup )$/x;
}

sub _check_omit_end_p
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( address | article | aside | blockquote | dir
			| div | dl | fieldset | footer | form | h[1-6]
			| header | hr | menu | nav | ol | p | pre | section
			| table | ul )$/x;
}

sub _check_omit_end_rp
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( rp | rt )$/x;
}

*_check_omit_end_rt = \&_check_omit_end_rp;

sub _check_omit_end_td
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( td | th )$/x;
}

*_check_omit_end_th = \&_check_omit_end_td;

sub _check_omit_end_tbody
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( tbody | tfoot )$/x;
}

sub _check_omit_end_tfoot
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( tbody )$/x;
}

sub _check_omit_end_thead
{
	my ($self, $element) = @_;
	
	return 0 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( tbody | tfoot )$/x;
}

sub _check_omit_end_tr
{
	my ($self, $element) = @_;
	
	return 1 unless defined $element->nextSibling;
	return 1 if $element->nextSibling->nodeName
		=~ /^( tr )$/x;
}

sub _check_omit_start_body
{
	my ($self, $element) = @_;
	my @kids = $element->childNodes;
	my $next = $kids[0];
	return 0 unless defined $next;
	return 0 if $next->nodeName eq '#comment';
	return 0 if $next->nodeName eq '#text' && $next->nodeValue =~ /^\s/;
	return 0 if $next->nodeName eq 'style';
	return 0 if $next->nodeName eq 'script';
	return 1;
}

sub _check_omit_start_head
{
	my ($self, $element) = @_;
	my @kids = $element->childNodes;
	return (@kids and $kids[0]->nodeType==XML_ELEMENT_NODE);
}

sub _check_omit_start_html
{
	my ($self, $element) = @_;
	my @kids = $element->childNodes;
	return (@kids and $kids[0]->nodeName ne '#comment');
}

sub _check_omit_start_tbody
{
	my ($self, $element) = @_;
	
	my @kids = $element->childNodes;
	return 0 unless @kids;
	return 0 unless $kids[0]->nodeName eq 'tr';
	return 1 unless defined $element->previousSibling;
	
	return 1
		if $element->previousSibling->nodeName eq 'tbody'
		&& $self->_check_omit_end_tbody($element->previousSibling);

	return 1
		if $element->previousSibling->nodeName eq 'thead'
		&& $self->_check_omit_end_thead($element->previousSibling);

	return 1
		if $element->previousSibling->nodeName eq 'tfoot'
		&& $self->_check_omit_end_tfoot($element->previousSibling);
}

1;

__END__

=head1 NAME

HTML::HTML5::Writer - output a DOM as HTML5

=head1 SYNOPSIS

 use HTML::HTML5::Writer;
 
 my $writer = HTML::HTML5::Writer->new;
 print $writer->document($dom);

=head1 DESCRIPTION

This module outputs XML::LibXML::Node objects as HTML5 strings.
It works well on DOM trees that represent valid HTML/XHTML
documents; less well on other DOM trees.

=head2 Constructor

=over 4

=item C<< $writer = HTML::HTML5::Writer->new(%opts) >>

Create a new writer object. Options include:

=over 4

=item * B<markup>

Choose which serialisation of HTML5 to use: 'html' or 'xhtml'.

=item * B<polyglot>

Set to true in order to attempt to produce output which works as both
XML and HTML. Set to false to produce content that might not.

If you don't explicitly set it, then it defaults to false for HTML, and
true for XHTML. 

=item * B<doctype>

Set this to a string to choose which <!DOCTYPE> tag to output. Note, this
purely sets the <!DOCTYPE> tag and does not change how the rest of the
document is output. This really is just a plain string literal...

 # Yes, this works...
 my $w = HTML::HTML5::Writer->new(doctype => '<!doctype html>');

The following constants are provided for convenience:
B<DOCTYPE_HTML2>,
B<DOCTYPE_HTML32>,
B<DOCTYPE_HTML4> (latest stable strict HTML 4.x),
B<DOCTYPE_HTML4_RDFA> (latest stable HTML 4.x+RDFa),
B<DOCTYPE_HTML40> (strict),
B<DOCTYPE_HTML40_FRAMESET>,
B<DOCTYPE_HTML40_LOOSE>,
B<DOCTYPE_HTML40_STRICT>,
B<DOCTYPE_HTML401> (strict),
B<DOCTYPE_HTML401_FRAMESET>,
B<DOCTYPE_HTML401_LOOSE>,
B<DOCTYPE_HTML401_RDFA10>,
B<DOCTYPE_HTML401_RDFA11>,
B<DOCTYPE_HTML401_STRICT>,
B<DOCTYPE_HTML5>,
B<DOCTYPE_LEGACY> (about:legacy-compat),
B<DOCTYPE_NIL> (empty string),
B<DOCTYPE_XHTML1> (strict),
B<DOCTYPE_XHTML1_FRAMESET>,
B<DOCTYPE_XHTML1_LOOSE>,
B<DOCTYPE_XHTML1_STRICT>,
B<DOCTYPE_XHTML11>,
B<DOCTYPE_XHTML_BASIC>,
B<DOCTYPE_XHTML_BASIC_10>,
B<DOCTYPE_XHTML_BASIC_11>,
B<DOCTYPE_XHTML_MATHML_SVG>,
B<DOCTYPE_XHTML_RDFA> (latest stable strict XHTML+RDFa),
B<DOCTYPE_XHTML_RDFA10>,
B<DOCTYPE_XHTML_RDFA11>.

Defaults to DOCTYPE_HTML5 for HTML and DOCTYPE_LEGACY for XHTML.

=item * B<charset>

This module always returns strings in Perl's internal utf8 encoding, but
you can set the 'charset' option to 'ascii' to create output that would
be suitable for re-encoding to ASCII (e.g. it will entity-encode characters
which do not exist in ASCII).

=item * B<quote_attributes>

Set this to a true to force attributes to be quoted. If not explicitly
set, the writer will automatically detect when attributes need quoting.

=item * B<voids>

Set this to true to force void elements to always be terminated with '/>'.
If not explicitly set, they'll only be terminated that way in polyglot or
XHTML documents.

=item * B<start_tags> and B<end_tags>

Except in polyglot and XHTML documents, some elements allow their
start and/or end tags to be omitted in certain circumstances. By
setting these to true, you can prevent them from being omitted.

=item * B<refs>

Special characters that can't be encoded as named entities need
to be encoded as numeric character references instead. These
can be expressed in decimal or hexadecimal. Setting this option to
'dec' or 'hex' allows you to choose. The default is 'hex'.

=back

=back

=head2 Public Methods

=over 4

=item C<< $writer->document($node) >>

Outputs (i.e. returns a string that is) an XML::LibXML::Document as HTML.

=item C<< $writer->element($node) >>

Outputs an XML::LibXML::Element as HTML.

=item C<< $writer->attribute($node) >>

Outputs an XML::LibXML::Attr as HTML.

=item C<< $writer->text($node) >>

Outputs an XML::LibXML::Text as HTML.

=item C<< $writer->cdata($node) >>

Outputs an XML::LibXML::CDATASection as HTML.

=item C<< $writer->comment($node) >>

Outputs an XML::LibXML::Comment as HTML.

=item C<< $writer->pi($node) >>

Outputs an XML::LibXML::PI as HTML.

=item C<< $writer->doctype >>

Outputs the writer's DOCTYPE.

=item C<< $writer->encode_entities($string, characters=>$more) >>

Takes a string and returns the same string with some special characters
replaced. These special characters do not include any of '&', '<', '>'
or '"', but you can provide a string of additional characters to treat as
special:

 $encoded = $writer->encode_entities($raw, characters=>'&<>"');

=item C<< $writer->encode_entity($char) >>

Returns $char entity-encoded. Encoding is done regardless of whether 
$char is "special" or not.

=item C<< $writer->is_xhtml >>

Boolean indicating if $writer is configured to output XHTML.

=item C<< $writer->is_polyglot >>

Boolean indicating if $writer is configured to output polyglot HTML.

=item C<< $writer->should_force_start_tags >>

=item C<< $writer->should_force_end_tags >>

Booleans indicating whether optional start and end tags should be forced.

=item C<< $writer->should_quote_attributes >>

Boolean indicating whether attributes need to be quoted.

=item C<< $writer->should_slash_voids >>

Boolean indicating whether void elements should be closed in the XHTML style.

=back

=head1 BUGS AND LIMITATIONS

Certain DOM constructs cannot be output in non-XML HTML. e.g.

 my $xhtml = <<XHTML;
 <html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>Test</title></head>
  <body><hr>This text is within the HR element</hr></body>
 </html>
 XHTML
 my $dom    = XML::LibXML->new->parse_string($xhtml);
 my $writer = HTML::HTML5::Writer->new(markup=>'html');
 print $writer->document($dom);

In HTML, there's no way to serialise that properly in HTML. Right
now this module just outputs that HR element with text contained
within it, a la XHTML. In future versions, it may emit a warning
or throw an error.

In these cases, the HTML::HTML5::{Parser,Writer} combination is
not round-trippable.

Outputting elements and attributes in foreign (non-XHTML)
namespaces is implemented pretty naively and not thoroughly
tested. I'd be interested in any feedback people have, especially
on round-trippability of SVG, MathML and RDFa content in HTML.

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::HTML5::Parser>,
L<HTML::HTML5::Builder>,
L<HTML::HTML5::ToText>,
L<XML::LibXML>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 by Toby Inkster.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
