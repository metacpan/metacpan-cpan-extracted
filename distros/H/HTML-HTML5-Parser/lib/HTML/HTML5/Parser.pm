package HTML::HTML5::Parser;

## skip Test::Tabs
use 5.008001;
use strict;
use warnings;

our $AUTOLOAD;
our $VERSION = '0.992';

use Carp;
use HTML::HTML5::Parser::Error;
use HTML::HTML5::Parser::TagSoupParser;
use Scalar::Util qw(blessed);
use URI::file;
use Encode qw(encode_utf8);
use XML::LibXML;

BEGIN {
	croak "Please upgrade to XML::LibXML 1.94"
		if XML::LibXML->VERSION =~ /^1\.9[12]/;
}

sub new
{
	my $class = shift;
    my %p = @_;
	my $self  = bless {
		errors => [],
        parser => HTML::HTML5::Parser::TagSoupParser->new(%p),
		}, $class;
	return $self;
}

sub parse_file
{
	require HTML::HTML5::Parser::UA;
	
	my $self   = shift;
	my $file   = shift;
	my $opts   = shift || {};
	
	unless (blessed($file) and $file->isa('URI'))
	{
		if ($file =~ /^[a-z][a-z0-9_\.\+-]+:\S+$/i)
			{ $file = URI->new($file); }
		else
			{ $file = URI::file->new_abs($file); }
	}
	
	my $response = HTML::HTML5::Parser::UA->get($file, $opts->{user_agent});
	croak "HTTP response code was not 200 OK. (Set \$opts{ignore_http_response_code} to ignore this error.)"
		unless ($response->{success} || $opts->{ignore_http_response_code});
	
	my $content = $response->{decoded_content};
	my $c_type  = $response->{headers}{'content-type'};
	
	$opts->{'response'} = $response;
	
	if ($c_type =~ /xml/i and not $opts->{'force_html'})
	{
		$opts->{'parser_used'} = 'XML::LibXML::Parser';
		my $xml_parser = XML::LibXML->new;
		$xml_parser->validation(0);
		$xml_parser->recover(2);
		$xml_parser->base_uri($response->base);
		$xml_parser->load_catalog($opts->{'xml_catalogue'})
			if -r $opts->{'xml_catalogue'};
		return $xml_parser->parse_string($content);
	}
	
	return $self->parse_string($content, $opts);
}
*parse_html_file = \&parse_file;

sub parse_fh
{
	my $self   = shift;
	my $handle = shift;
	my $opts   = shift || {};
	
	my $string = '';
	while (<$handle>)
	{
		$string .= $_;
	}
	
	return $self->parse_string($string, $opts);
}
*parse_html_fh = \&parse_fh;

sub parse_string
{
	my $self = shift;
	my $text = shift;
	my $opts = shift || {};

	$self->{'errors'} = [];
	$opts->{'parser_used'} = 'HTML::HTML5::Parser';
	my $dom = XML::LibXML::Document->createDocument;

	if (defined $opts->{'encoding'}||1)
	{
        # XXX AGAIN DO THIS TO STOP ENORMOUS MEMORY LEAKS
        if (utf8::is_utf8($text)) {
            $text = encode_utf8($text);
        }
        my ($errh, $errors) = @{$self}{qw(error_handler errors)};
        $self->{parser}->parse_byte_string(
            $opts->{'encoding'}, $text, $dom,
            sub {
                my $err = HTML::HTML5::Parser::Error->new(@_);
                $errh->($err) if $errh;
                push @$errors, $err;
			});
	}
	else
	{
		$self->{parser}->parse_char_string($text, $dom, sub{
			my $err = HTML::HTML5::Parser::Error->new(@_);
			$self->{error_handler}->($err) if $self->{error_handler};
			push @{$self->{'errors'}}, $err;
			});
	}
	
	return $dom;
}
*parse_html_string = \&parse_string;

# TODO: noembed, noframes, noscript
my %within = (
	html       => [qw/html/],
	frameset   => [qw/html frameset/],
	frame      => [qw/html frameset frame/],
	head       => [qw/html head/],
	title      => [qw/html head title/],
	style      => [qw/html head style/],
	(map { $_  => undef }
		qw/base link meta basefont bgsound/),
	body       => [qw/html body/],
	script     => [qw/html body script/],
	div        => [qw/html body div/],
	(map { $_  => [qw/html body div/, $_] }
		qw/a abbr acronym address applet area article aside big blockquote
		button center code details dir dl em fieldset figure font
		footer form h1 h2 h3 h4 h5 h6 header hgroup i iframe
		listing marquee menu nav nobr object ol p plaintext pre
		ruby s section small strike strong tt u ul xmp/),
	(map { $_  => undef }
		qw/br col command datagrid embed hr img input keygen
		param wbr/),
	dd         => [qw/html body dl dd/],
	dd         => [qw/html body dl dt/],
	figcaption => [qw/html body figure/],
	li         => [qw/html body ul li/],
	ul__li     => [qw/html body ul li/],
	ol__li     => [qw/html body ol li/],
	optgroup   => [qw/html body form div select/],
	option     => [qw/html body form div select/],
	rp         => [qw/html body div ruby/],
	rt         => [qw/html body div ruby/],
	select     => [qw/html body form div select/],
	summary    => [qw/html body div details/],
	table      => [qw/html body table/],
	(map { $_  => [qw/html body table/, $_] }
		qw/thead tfoot tbody tr caption colgroup/),
	(map { $_  => [qw/html body table tbody tr/, $_] }
		qw/td th/),	
	textarea   => [qw/html body form div textarea/],
);

sub parse_balanced_chunk
{
	my ($self, $chunk, $o) = @_;
	my %options = %{ $o || {} };
	
	$options{as} = 'default' unless defined $options{as};
	
	my $w = $options{force_within} || $options{within} || 'div';
	my $ancestors = $within{ lc $w };
	croak "Cannot parse chunk as if within $w."
		if !defined $ancestors;
	
	my $parent = $ancestors->[-1];
	my $n      = scalar(@$ancestors) - 2;
	my @a      = $n ? @$ancestors[0 .. $n] : ();
	
	my $uniq = sprintf('rand_id_%09d', int rand 1_000_000_000);
	my $document = 
		"<!doctype html>\n".
		(join q{}, map { "<$_>" } @a).
		"<$parent id='$uniq'>".
		$chunk.
	''.#	"</$parent>".
	'';#	(join q{}, map { "</$_>" } reverse @a);
	
	my $dom = $self->parse_html_string($document);
	$parent = $dom->findnodes("//*[\@id='$uniq']")->get_node(1);
	
	if ($options{debug})
	{
		if (exists &Test::More::diag)
		{
			Test::More::diag($document);
			Test::More::diag($dom->toString);
		}
		else
		{
			warn $document."\n";
			warn $dom->toString."\n";
		}
	}
	
	my @results = $parent->childNodes;
	
	unless ($options{force_within})
	{
		while ($parent)
		{
			my $sibling = $parent->nextSibling;
			while ($sibling)
			{
				unless ($sibling->nodeName =~ /^(head|body)$/)
				{
					$sibling->setAttribute('data-perl-html-html5-parser-outlier', 1)
						if $options{mark_outliers}
						&& $sibling->can('setAttribute');
					push @results, $sibling;
				}
				$sibling = $sibling->nextSibling;
			}
			
			$sibling = $parent->previousSibling;
			while ($sibling)
			{
				unless ($sibling->nodeName =~ /^(head|body)$/)
				{
					$sibling->setAttribute('data-perl-html-html5-parser-outlier', 1)
						if $options{mark_outliers}
						&& $sibling->can('setAttribute');
					unshift @results, $sibling;
				}
				$sibling = $sibling->previousSibling;
			}
			
			$parent = $parent->parentNode;
		}
	}
	
	my $frag = XML::LibXML::DocumentFragment->new;
	$frag->appendChild($_) foreach @results;
	
	if (lc $options{as} eq 'list')
	{
		return wantarray ? @results : XML::LibXML::NodeList->new(@results);
	}
	
	return wantarray ? @results : $frag;
}

sub load_html
{
	my $class_or_self = shift;
	
	my %args = map { ref($_) eq 'HASH' ? (%$_) : $_ } @_;
	my $URI = delete($args{URI});
	$URI = "$URI" if defined $URI; # stringify in case it is an URI object
	my $parser = ref($class_or_self)
		? $class_or_self
		: $class_or_self->new;
		
	my $dom;
	if ( defined $args{location} )
		{ $dom = $parser->parse_file( "$args{location}" ) }
	elsif ( defined $args{string} )
		{ $dom = $parser->parse_string( $args{string}, $URI ) }
	elsif ( defined $args{IO} )
		{ $dom = $parser->parse_fh( $args{IO}, $URI ) }
	else
		{ croak("HTML::HTML5::Parser->load_html: specify location, string, or IO"); }
	
	return $dom;
}

sub load_xml
{
	my $self = shift;
	my $dom;
	eval {
		$dom = XML::LibXML->load_xml(@_);
	};
	return $dom if blessed($dom);
	return $self->load_html(@_);
}

sub AUTOLOAD
{
	my $self = shift;
	my $func = $AUTOLOAD;
	$func =~ s/.*://;
	
	# LibXML Push Parser.
	if ($func =~ /^( parse_chunk | start_push | push | finish_push )$/xi)
	{
		croak "Push parser ($func) not implemented by HTML::HTML5::Parser.";
	}
	
	# Misc LibXML functions with no compatible interface provided.
	if ($func =~ /^( parse_balanced_chunk | parse_xml_chunk |
		process_?xincludes | get_last_error )$/xi)
	{
		croak "$func not implemented by HTML::HTML5::Parser.";
	}
	
	# Fixed options which are true.
	if ($func =~ /^( recover | recover_silently | expand_entities |
		keep_blanks | no_network )$/xi)
	{
		my $set = shift;
		if ((!$set) && defined $set)
		{
			carp "Option $func cannot be switched off.";
		}
		return 1;
	}

	# Fixed options which are false.
	if ($func =~ /^( validation | pedantic_parser | line_numbers 
		load_ext_dtd | complete_attributes | expand_xinclude |
		load_catalog | base_uri | gdome_dom | clean_namespaces )$/xi)
	{
		my $set = shift;
		if (($set) && defined $set)
		{
			carp "Option $func cannot be switched on.";
		}
		return 0;
	}

	carp "HTML::HTML5::Parser doesn't understand '$func'." if length $func;
}

sub error_handler
{
	my $self = shift;
	$self->{error_handler} = shift if @_;
	return $self->{error_handler};
}

sub errors
{
	my $self = shift;
	return @{ $self->{errors} };
}

sub compat_mode
{
	my $self = shift;
	my $node = shift;
	
	return $self->{parser}->_data($node)->{'manakai_compat_mode'};
}

sub charset
{
	my $self = shift;
	my $node = shift;
	
	return $self->{parser}->_data($node)->{'charset'};
}

sub dtd_public_id
{
	my $self = shift;
	my $node = shift;
	
	return $self->{parser}->_data($node)->{'DTD_PUBLIC_ID'};
}

sub dtd_system_id
{
	my $self = shift;
	my $node = shift;
	
	return $self->{parser}->_data($node)->{'DTD_SYSTEM_ID'};
}

sub dtd_element
{
	my $self = shift;
	my $node = shift;
	
	return $self->{parser}->_data($node)->{'DTD_ELEMENT'};
}

sub source_line
{
	my $self = shift;
	my $node = shift;

    my $data = ref $self ? $self->{parser}->_data($node) :
        HTML::HTML5::Parser::TagSoupParser::DATA($node);
	my $line = $data->{'manakai_source_line'};

	if (wantarray)
	{
		return (
			$line,
			$data->{'manakai_source_column'},
			($data->{'implied'} || 0),
			);
	}
	else
	{
		return $line;
	}
}

sub DESTROY {}

__END__

=pod

=encoding utf8

=begin stopwords

XML::LibXML-like
XML::LibXML-Compatible
'utf-8')
foobar
doctype:
html
implictness

=end stopwords

=head1 NAME

HTML::HTML5::Parser - parse HTML reliably

=head1 SYNOPSIS

  use HTML::HTML5::Parser;
  
  my $parser = HTML::HTML5::Parser->new;
  my $doc    = $parser->parse_string(<<'EOT');
  <!doctype html>
  <title>Foo</title>
  <p><b><i>Foo</b> bar</i>.
  <p>Baz</br>Quux.
  EOT
  
  my $fdoc   = $parser->parse_file( $html_file_name );
  my $fhdoc  = $parser->parse_fh( $html_file_handle );

=head1 DESCRIPTION

This library is substantially the same as the non-CPAN module Whatpm::HTML.
Changes include:

=over 8

=item * Provides an XML::LibXML-like DOM interface. If you usually use XML::LibXML's DOM parser, this should be a drop-in solution for tag soup HTML.

=item * Constructs an XML::LibXML::Document as the result of parsing.

=item * Via bundling and modifications, removed external dependencies on non-CPAN packages.

=back

=head2 Constructor

=over 8

=item C<new>

  $parser = HTML::HTML5::Parser->new;
  # or
  $parser = HTML::HTML5::Parser->new(no_cache => 1);

The constructor does nothing interesting besides take one flag
argument, C<no_cache =E<gt> 1>, to disable the global element metadata
cache. Disabling the cache is handy for conserving memory if you parse
a large number of documents, however, class methods such as
C</source_line> will not work, and must be run from an instance of
this parser.

=back

=head2 XML::LibXML-Compatible Methods

=over

=item C<parse_file>, C<parse_html_file>

  $doc = $parser->parse_file( $html_file_name [,\%opts] );
  
This function parses an HTML document from a file or network;
C<$html_file_name> can be either a filename or an URL.

Options include 'encoding' to indicate file encoding (e.g.
'utf-8') and 'user_agent' which should be a blessed C<LWP::UserAgent>
(or L<HTTP::Tiny>) object to be used when retrieving URLs.

If requesting a URL and the response Content-Type header indicates
an XML-based media type (such as XHTML), XML::LibXML::Parser
will be used automatically (instead of the tag soup parser). The XML
parser can be told to use a DTD catalogue by setting the option
'xml_catalogue' to the filename of the catalogue.

HTML (tag soup) parsing can be forced using the option 'force_html', even
when an XML media type is returned. If an options hashref was passed,
parse_file will set $options->{'parser_used'} to the name of the class used
to parse the URL, to allow the calling code to double-check which parser
was used afterwards.

If an options hashref was passed, parse_file will set $options->{'response'}
to the HTTP::Response object obtained by retrieving the URI.

=item C<parse_fh>, C<parse_html_fh>

  $doc = $parser->parse_fh( $io_fh [,\%opts] );
  
C<parse_fh()> parses a IOREF or a subclass of C<IO::Handle>.

Options include 'encoding' to indicate file encoding (e.g.
'utf-8').

=item C<parse_string>, C<parse_html_string>

  $doc = $parser->parse_string( $html_string [,\%opts] );

This function is similar to C<parse_fh()>, but it parses an HTML
document that is available as a single string in memory.

Options include 'encoding' to indicate file encoding (e.g.
'utf-8').

=item C<load_xml>, C<load_html>

Wrappers for the parse_* functions. These should be roughly compatible with
the equivalently named functions in L<XML::LibXML>.

Note that C<load_xml> first attempts to parse as real XML, falling back to
HTML5 parsing; C<load_html> just goes straight for HTML5.

=item C<parse_balanced_chunk>

  $fragment = $parser->parse_balanced_chunk( $string [,\%opts] );

This method is roughly equivalent to XML::LibXML's method of the same
name, but unlike XML::LibXML, and despite its name it does not require
the chunk to be "balanced". This method is somewhat black magic, but
should work, and do the proper thing in most cases. Of course, the
proper thing might not be what you'd expect! I'll try to keep this
explanation as brief as possible...

Consider the following string:

  <b>Hello</b></td></tr> <i>World</i>

What is the proper way to parse that? If it were found in a document like
this:

  <html>
    <head><title>X</title></head>
    <body>
      <div>
        <b>Hello</b></td></tr> <i>World</i>
      </div>
    </body>
  </html>

Then the document would end up equivalent to the following XHTML:

  <html>
    <head><title>X</title></head>
    <body>
      <div>
        <b>Hello</b> <i>World</i>
      </div>
    </body>
  </html>

The superfluous C<< </td></tr> >> is simply ignored. However, if it
were found in a document like this:

  <html>
    <head><title>X</title></head>
    <body>
      <table><tbody><tr><td>
        <b>Hello</b></td></tr> <i>World</i>
      </td></tr></tbody></table>
    </body>
  </html>

Then the result would be:

  <html>
    <head><title>X</title></head>
    <body>
      <i>World</i>
      <table><tbody><tr><td>
        <b>Hello</b></td></tr>
      </tbody></table>
    </body>
  </html>

Yes, C<< <i>World</i> >> gets hoisted up before the C<< <table> >>. This
is weird, I know, but it's how browsers do it in real life.

So what should:

  $string   = q{<b>Hello</b></td></tr> <i>World</i>};
  $fragment = $parser->parse_balanced_chunk($string);

actually return? Well, you can choose...

  $string = q{<b>Hello</b></td></tr> <i>World</i>};
  
  $frag1  = $parser->parse_balanced_chunk($string, {within=>'div'});
  say $frag1->toString; # <b>Hello</b> <i>World</i>
  
  $frag2  = $parser->parse_balanced_chunk($string, {within=>'td'});
  say $frag2->toString; # <i>World</i><b>Hello</b>

If you don't pass a "within" option, then the chunk is parsed as if it
were within a C<< <div> >> element. This is often the most sensible
option. If you pass something like C<< { within => "foobar" } >>
where "foobar" is not a real HTML element name (as found in the HTML5
spec), then this method will croak; if you pass the name of a void
element (e.g. C<< "br" >> or C<< "meta" >>) then this method will
croak; there are a handful of other unsupported elements which will
croak (namely: C<< "noscript" >>, C<< "noembed" >>, C<< "noframes" >>).

Note that the second time around, although we parsed the string "as
if it were within a C<< <td> >> element", the C<< <i>Hello</i> >>
bit did not strictly end up within the C<< <td> >> element (not
even within the C<< <table> >> element!) yet it still gets returned.
We'll call things such as this "outliers". There is a "force_within"
option which tells parse_balanced_chunk to ignore outliers:

  $frag3  = $parser->parse_balanced_chunk($string,
                                          {force_within=>'td'});
  say $frag3->toString; # <b>Hello</b>

There is a boolean option "mark_outliers" which marks each outlier
with an attribute (C<< data-perl-html-html5-parser-outlier >>) to
indicate its outlier status. Clearly, this is ignored when you use
"force_within" because no outliers are returned. Some outliers may
be XML::LibXML::Text elements; text nodes don't have attributes, so
these will not be marked with an attribute.

A last note is to mention what gets returned by this method. Normally
it's an L<XML::LibXML::DocumentFragment> object, but if you call the
method in list context, a list of the individual node elements is
returned. Alternatively you can request the data to be returned as an
L<XML::LibXML::NodeList> object:

 # Get an XML::LibXML::NodeList
 my $list = $parser->parse_balanced_chunk($str, {as=>'list'});

The exact implementation of this method may change from version to
version, but the long-term goal will be to approach how common
desktop browsers parse HTML fragments when implementing the setter 
for DOM's C<innerHTML> attribute.

=back

The push parser and SAX-based parser are not supported. Trying
to change an option (such as recover_silently) will make
HTML::HTML5::Parser carp a warning. (But you can inspect the
options.)

=head2 Error Handling

Error handling is obviously different to XML::LibXML, as errors are
(bugs notwithstanding) non-fatal.

=over

=item C<error_handler>

Get/set an error handling function. Must be set to a coderef or undef.

The error handling function will be called with a single parameter, a
L<HTML::HTML5::Parser::Error> object.

=item C<errors>

Returns a list of errors that occurred during the last parse.

See L<HTML::HTML5::Parser::Error>.

=back

=head2 Additional Methods

The module provides a few methods to obtain additional, non-DOM data from
DOM nodes.

=over

=item C<dtd_public_id>

  $pubid = $parser->dtd_public_id( $doc );
  
For an XML::LibXML::Document which has been returned by
HTML::HTML5::Parser, using this method will tell you the
Public Identifier of the DTD used (if any).

=item C<dtd_system_id>

  $sysid = $parser->dtd_system_id( $doc );
  
For an XML::LibXML::Document which has been returned by
HTML::HTML5::Parser, using this method will tell you the
System Identifier of the DTD used (if any).

=item C<dtd_element>

  $element = $parser->dtd_element( $doc );

For an XML::LibXML::Document which has been returned by
HTML::HTML5::Parser, using this method will tell you the
root element declared in the DTD used (if any). That is,
if the document has this doctype:

  <!doctype html>

... it will return "html".

This may return the empty string if a DTD was present but
did not contain a root element; or undef if no DTD was
present.

=item C<compat_mode>

  $mode = $parser->compat_mode( $doc );
  
Returns 'quirks', 'limited quirks' or undef (standards mode).

=item C<charset>

  $charset = $parser->charset( $doc );

The character set apparently used by the document.

=item C<source_line>

  ($line, $col) = $parser->source_line( $node );
  $line = $parser->source_line( $node );

In scalar context, C<source_line> returns the line number of the
source code that started a particular node (element, attribute or
comment).

In list context, returns a tuple: $line, $column, $implicitness.
Tab characters count as one column, not eight.

$implicitness indicates that the node was not explicitly marked
up in the source code, but its existence was inferred by the parser.
For example, in the following markup, the HTML, TITLE and P elements
are explicit, but the HEAD and BODY elements are implicit.

 <html>
  <title>I have an implicit head</title>
  <p>And an implicit body too!</p>
 </html>

(Note that implicit elements do still have a line number and column
number.) The implictness indicator is a new feature, and I'd appreciate
any bug reports where it gets things wrong.

L<XML::LibXML::Node> has a C<line_number> method. In general this
will always return 0 and HTML::HTML5::Parser has no way of influencing
it. However, if you install L<XML::LibXML::Devel::SetLineNumber> on
your system, the C<line_number> method will start working (at least for
elements).

=back

=head1 SEE ALSO

L<http://suika.fam.cx/www/markup/html/whatpm/Whatpm/HTML.html>.

L<HTML::HTML5::Writer>,
L<HTML::HTML5::Builder>,
L<XML::LibXML>,
L<XML::LibXML::PrettyPrint>,
L<XML::LibXML::Devel::SetLineNumber>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2007-2011 by Wakaba

Copyright (C) 2009-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

