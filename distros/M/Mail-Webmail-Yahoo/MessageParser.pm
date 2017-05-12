#  (C)  Simon Drabble  2002,2003
#  sdrabble@cpan.org  2002/10/23

#  $Id: MessageParser.pm,v 1.14 2003/10/10 02:39:27 simon Exp $
#

use strict;
use warnings;

package Mail::Webmail::MessageParser;

use base 'HTML::TreeBuilder';

our $VERSION = 0.2;

# This results in false positives, for example on lines like
# From somebody you know HH:MM:SS dd:mm:yy
# Which is why a futher check is made against mail_header_names..
our $LOOKS_LIKE_A_HEADER = qr{\b[-\w]+:};


our @mail_header_names = qw(
		To From Reply-To Subject
		Date X- Received Content-

);
#		qr{^To}, qr{From}, qr{Reply-To}, qr{Subject},
#		qr{Date}, qr{X-[-\w]+}, qr{Received}, qr{Content-[-\w]+},


# Tags that "shouldn't" appear in the message body.
our $disallow = {
	xbody => 1,
	html  => 1,
	head  => 1,
	meta  => 1,
	xmeta => 1,
	body  => 1,
};



# Fix some crappiness introduced by our fiends in Redmond. 
# These come from the chart at
#   http://www.pemberley.com/janeinfo/latin1.html#unicode
our $ms_to_unicode = {
	"\x82"   => "&#8218",   #    Single Low-9 Quotation Mark
	"\x83"   => "&#402",    #    Latin Small Letter F With Hook
	"\x84"   => "&#8222",   #    Double Low-9 Quotation Mark
	"\x85"   => "&#8230",   #    Horizontal Ellipsis
	"\x86"   => "&#8224",   #    Dagger
	"\x87"   => "&#8225",   #    Double Dagger
	"\x88"   => "&#710",    #    Modifier Letter Circumflex Accent
	"\x89"   => "&#8240",   #    Per Mille Sign
	"\x8a"   => "&#352",    #    Latin Capital Letter S With Caron
	"\x8b"   => "&#8249",   #    Single Left-Pointing Angle Quotation Mark
	"\x8c"   => "&#338",    #    Latin Capital Ligature OE
	"\x91"   => "&#8216",   #    Left Single Quotation Mark
	"\x92"   => "&#8217",   #    Right Single Quotation Mark
	"\x93"   => "&#8220",   #    Left Double Quotation Mark
	"\x94"   => "&#8221",   #    Right Double Quotation Mark
	"\x95"   => "&#8226",   #    Bullet
	"\x96"   => "&#8211",   #    En Dash
	"\x97"   => "&#8212",   #    Em Dash
	"\x98"   => "&#732",    #    Small Tilde
	"\x99"   => "&#8482",   #    Trade Mark Sign
	"\x9a"   => "&#353",    #    Latin Small Letter S With Caron
	"\x9b"   => "&#8250",   #    Single Right-Pointing Angle Quotation Mark
	"\x9c"   => "&#339",    #    Latin Small Ligature OE
	"\x9f"   => "&#376",    #    Latin Capital Letter Y With Diaeresis
};


our $unicode_to_text = {
	"&#8218"   => "'",   #    Single Low-9 Quotation Mark
	"&#402"    => '',    #    Latin Small Letter F With Hook
	"&#8222"   => "'",   #    Double Low-9 Quotation Mark
	"&#8230"   => '..',  #    Horizontal Ellipsis
	"&#8224"   => '',    #    Dagger
	"&#8225"   => '',    #    Double Dagger
	"&#710"    => '',    #    Modifier Letter Circumflex Accent
	"&#8240"   => '',    #    Per Mille Sign
	"&#352"    => '',    #    Latin Capital Letter S With Caron
	"&#8249"   => '<',   #    Single Left-Pointing Angle Quotation Mark
	"&#338"    => 'OE',  #    Latin Capital Ligature OE
	"&#8216"   => '`',   #    Left Single Quotation Mark
	"&#8217"   => "'",   #    Right Single Quotation Mark
	"&#8220"   => '"',   #    Left Double Quotation Mark
	"&#8221"   => '"',   #    Right Double Quotation Mark
	"&#8226"   => 'o',   #    Bullet
	"&#8211"   => '--',  #    En Dash
	"&#8212"   => '---', #    Em Dash
	"&#732"    => '~',   #    Small Tilde
	"&#8482"   => 'TM',  #    Trade Mark Sign
	"&#353"    => '',    #    Latin Small Letter S With Caron
	"&#8250"   => ">",   #    Single Right-Pointing Angle Quotation Mark
	"&#339"    => 'oe',  #    Latin Small Ligature OE
	"&#376"    => '',    #    Latin Capital Letter Y With Diaeresis
};



sub message_start
{
	my ($self, @gubbins) = @_;
	$self->{_message_start} = \@gubbins;
}



sub parse_header
{
	my ($self, $field, $val) = @_;

# We could only look for HEADER fields in the textual contents of <td>'s (or
# whatever we have in $field). However, to do that would require searching the
# entire tree in $self. It's probably quicker to run the regexp for each
# (longer) item than to parse the tree and /then/ run the regexp on the
# (shorter) parsed output. It does mean that the regexp for checking cannot
# be anchored at the beginning of the text :(
# TODO: test this assumption.

	my $found = 0;
	if ($field =~ /$LOOKS_LIKE_A_HEADER/) {
		$self->parse($field);
		$self->eof();
		for (@mail_header_names) {
			if ($self->as_text =~ /^($_[-\w]*:)/i) {
				$found = $1;
				last;
			}
		}
		if ($found) {
			$val =~ s/&nbsp;//g; #Stupid yahboo.
			if ($self->{_debug}) { print "sdd 050; Header: ($found)=($val)\n" }
			$self->parse($val);
			$self->eof();
		}
	}
	if ($self->{_debug}) {
		print "sdd 051a; Header: ($found)=(", $self->as_trimmed_text, ")\n" if $found;
	}
	return $found ? $self->as_trimmed_text : undef;
}



sub message_read
{
	my ($self, $html) = @_;
	if ($self->{_debug}) {
		print "sdd 024; ------------------------------------------------\n";
		print $html, "\n";
	}

	$self->parse($html);
	$self->eof();

	if ($self->{_debug}) {
		print "sdd 025; ------------------------------------------------\n";
		print $self->as_HTML(undef, "\t"), "\n";
	}


# Normalise content
	my $page = new HTML::Element('html');
	my $head = $page->push_content(new HTML::Element('head'));
	my $body = new HTML::Element('body');
	$page->push_content($body);
	my $msg = $self->look_down(@{$self->{_message_start}});
	$body->push_content($msg);
	$self->{_message_element} = $page;

	if ($self->{_debug}) {
		print "sdd 026a; ------------------------------------------------\n";
		print $page->as_HTML(undef, "\t"), "\n";
		print "sdd 026b; ------------------------------------------------\n";
	}

	return 1;
}



sub body_as_html  { body(@_, 'html')  }
sub body_as_plain { body(@_, 'plain') }
sub body_as_text  { body(@_, 'plain') }
sub body_as_appropriate { body(@_) }   # Guess html or text based on contents


# FIXME: Remove in version 0.3
sub parse_body_as_html { warn "parse_body_as_xxx is deprecated; please use body_as_xxx instead\n"; body_as_html(@_) }
sub parse_body_as_text { warn "parse_body_as_xxx is deprecated; please use body_as_xxx instead\n"; body_as_text(@_) }
sub parse_body
{
	warn "parse_body is deprecated; please use body instead.\n";
	body(@_);
}



# removes extra tags from around the message body, drilling down through @args
# bread (array of arrayrefs to pass to look_down) until meat is encountered.
sub extract_body
{
	my ($self, @args) = @_;


	my $page = $self->{_message_element};
	unless ($page) {
		warn "No message content found - has message been read?\n";
		return undef;
	}
#	my $e = $page->look_down(@{shift @args});
	my $e = $page;
	my $save = $e;
	if ($e) {
# TODO: Check $e in the below loop, and use page text if look_down fails
JULIE:
		for (@args) {
			$e = $e->look_down(@$_);
			last JULIE if !$e;
			$save = $e;
		}
		if (!$e) { $e = $save } # restore last 'good' element 
		my $text = join '', map { ref($_) ? $_->as_HTML : $_ } $e->content_list;
		if ($self->{_debug}) {
			print "sdd 028a; ------------------------------------------------\n";
			print $text, "\n";
			print "sdd 028b; ------------------------------------------------\n";
		}
		my $el = new HTML::TreeBuilder();
# even though this is set to false, TreeBuilder adds an implicit HTML tag.
# Bah. Just have to live with that for now.
		$el->implicit_tags(0);
		$el->parse($text);
		$el->eof();
		if ($self->{_debug}) {
			print "sdd 029a; ------------------------------------------------\n";
			print $el->dump, "\n";
			print "sdd 029b; ------------------------------------------------\n";
			print $el->as_HTML(undef, "\t"), "\n";
			print "sdd 029c; ------------------------------------------------\n";
		}
		$self->{_body_content} = $text;
# Ahaha! extract_body might be called serially!
		$self->{_message_element} = $el;

		return 1; # Notify caller something was changed
	}
	return 0; # No change made to settings
}



# TODO: allow trimming of yahoo banner/ footer
# $style can be 'html', 'plain', or 'both'.
# TODO: complicated rules described here
# If only one style is provided, use it. If no styles, and no multipart/alt
# header, try and guess at the type by looking for html tags in the
# content.
# TODO: Allow override of Content-Type. Some messages have an html body even
# though the message Content-Type is text/plain. It's kept as-is for now but
# it might be nice in future to allow the user to specify that the
# Content-Type be re-written if HTML is detected.
sub body
{
	my ($self, $message, $style) = @_;

	my $msg = $self->{_body_content};
	my $body = $self->{_message_element};
# TODO: call read_body ourselves here ? no tag info.. assume "none".
	unless ($msg && $body) {
		warn "No message content found - has message been read?\n";
		return undef;
	}

	my @mesg = (); # will store the message body as we build it.

# If no style provided, see if we can figure it out from the MIME type. If
# not able to, check the message contents themselves.
	my $boundary = '';
	my $ct = $message->get('Content-Type');

	my $style_src = '';

	if (!$style) {
		if ($self->{_debug}) { print "sdd 070a; ($ct)\n" }
		if ($ct) {
			if ($ct =~ m{multipart/alternative;?\s*(?:boundary=)"?([^"]*)"?}i) { #"
				$style = 'both';
				$boundary = $1;
				$style_src = 'content-type (multipart/alternative)';
			} elsif ($ct =~ m:text/(\w+):i) {
				$style = lc $1;
				$style_src = "content-type (text/$style)";
			} elsif ($ct =~ m{multipart/mixed;?\s*(?:boundary=)"?([^"]*)"?}i) { #"
				$style = ''; # Figure out later what content type to use.
				$boundary = $1;
			}
		}
	}
	if (!$style) {
		$style = $self->might_be_html($message, $msg);
# If html was found in the message body, and Content-Type is
# empty, we can add a multipart/alternative Content-Type. 
# TODO: requires 'make_message_boundary'.
#		if ($style eq 'html') {
#			$style = 'both';
#			if (!$ct) {
#				my $bdry = $self->make_message_boundary($message);
#				$message->add('Content-Type', "multipart/alternative; boundary=$bdry");
#			}
#		}

		$style_src = "guessed ($style)";
	}

	my $text = '';

	if ($style eq 'both' ||
			($style eq 'html' && $ct =~ m:multipart/(alternative|mixed):i)) {
		if ($style ne 'both' && $ct !~ /alternative/i) {
			$text .= "This is a multi-part message in MIME format.\n",
		}
		$message->replace('MIME-Version', '1.0');

		$text .= join "\n",
			"--$boundary",
			"Content-Type: text/html\n\n"
			;
	}

	if ($style eq 'html' || $style eq 'both') { $text .= $msg }

	if ($style eq 'both' ||
			($style eq 'plain' && $ct =~ m:multipart/(alternative|mixed):i)) {
		if ($style ne 'both' && $ct !~ /alternative/i) {
			$text .= "This is a multi-part message in MIME format.\n\n",
		}
		$message->replace('MIME-Version', '1.0');
		$text .= join "\n",
			"--$boundary",
			"Content-Type: text/plain\n\n",
			;
	}
	if ($style eq 'plain' || $style eq 'both') {
# $body->as_text might not be sufficient..
		$text .= $self->html2text($body);
	}

	$text =~ s/$_/$ms_to_unicode->{$_}/g for (keys %$ms_to_unicode);
	if ($text =~ /\&#/) {
# HTML::Entities_decode_entities does not seem to know about chars above 255,
# although Unicode support is claimed in perl > 5.7. So we have to decode
# those ourselves using the ms_to_unicode_to_text tables.
		$text =~ s/$_/$unicode_to_text->{$_}/g for (keys %$unicode_to_text);
	}
	if ($self->{_debug}) {
		print "sdd 085; Final '$style' text=($text)\n-=-=-=-=-=-=-=-=-=-=-=-=\n";
		$message->add('X-WMY-Style', $style);
		$message->add('X-WMY-Style-Source', $style_src);
	}

	return $text;
}



sub remove_matching
{
	my ($self, @args) = @_;

	my $body = $self->{_message_element};

	if ($self->{_debug}) {
		print "sdd 027a; ------------------------------------------------\n";
		print $body->as_HTML(undef, "\t"), "\n";
		print "sdd 027b; ------------------------------------------------\n";
		print $body->dump, "\n";
		print "sdd 027c; ------------------------------------------------\n";
	}

	my @s = $body->look_down(@args);
	for (@s) { $_->delete() }
}




sub might_be_html
{
	my ($self, $message, $text) = @_;
# Here all we care about is the message body itself. For Yahoo, this is
# defined inside a '<div id="message"></div>' block.. but Yahoo adds extra
# HTML inside this div (as of 2003/08/12, a table is added). What we'd like to
# do is remove this extraneous HTML and focus only on the text actually
# delivered by the sender.. which may or may not include HTML tags itself.
# To achieve this, we rely on the caller to have filtered out any stuff not
# interesting to MessageParser.
# TODO: Move this comment block to where it came from (where?)

# If the message text contains a <tag> with a matching </tag>, consider it
# HTML.  This is not very robust, or complete, but should be adequate for our
# purposes.

	if ($self->{_debug}) {
		print "sdd 086a; text=($text)\n-=-=-=-=-=-=-=-=-=-=-=-=\n";
	}
	
	if ($text =~ /<([a-z]+)>/is) {
		if ($self->{_debug}) { print "sdd 086b; match=($1)\n" }
		if ($text =~ m:</($1)>:is) {
			if ($self->{_debug}) {
				print "sdd 090; Set message type to html on the basis of '$1'\n";
				$message->add('X-Body-Conversion-Trigger', "<$1>");
			}
			$message->add('X-Body-Converted-To', 'html');
			return 'html';
		}
	}
	return 'plain';
}


sub html2text
{
	my ($self, $html) = @_;

	if (ref($self) !~ /Mail::Webmail::MessageParser/) {
		$html = $self;
	}

	if (ref($html) =~ /HTML::(Tree|Element)/) {
# Very cheap'n'cheerful converter. Simply replaces <br>s with newlines.
		my $h = $html->as_HTML(undef, "\t");
		my $repl = '##!BR!##';
		while ($h =~ /$repl/) {
			$repl = chr(ord('a') + (rand 65)) . $repl . chr(ord('a') + (rand 65));
		}
		$h =~ s/<br>/$repl/ig;
		my $parser = new HTML::TreeBuilder;
		$parser->parse($h);
		$parser->eof();
		$html = $parser->as_text;
		$html =~ s/$repl/\n/g;
		return $html;
	}

	return $html;
}




sub start
{
	my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

# Messages are generally embedded inside a nominally valid HTML doc. Sometimes
# they will have their own html/ body tags - unfortunately, these cause
# HTML::TreeBuilder problems since they are invalid.
	if ($tagname eq 'html') {
		$tagname = 'pre';
		$origtext =~ s/html/pre/g;
	}

	return if exists $disallow->{$tagname};
	$self->SUPER::start($tagname, $attr, $attrseq, $origtext);
}


sub end
{
	my ($self, $tagname) = @_;
	if ($tagname eq 'html') {
		$tagname = 'pre';
	}
	return if exists $disallow->{$tagname};
	shift;
	$self->SUPER::end(@_);
}


1;


__END__


=head1 NAME

Mail::Webmail::MessageParser -- class to parse HTML webmail messages.

=head1 SYNOPSIS

	$p = new Mail::Webmail::MessageParser();

	$p->message_start(_tag => 'div', id => 'message');

	$body_text = $p->parse_body($html, $style);

	while (($field, $data) = each @html_fields_from_somewhere) {
		$header = $p->parse_header($field, $data);
		push @headers, $header if $header;
	}


=head1 DESCRIPTION

Parses header and body HTML and converts both to text, or optionally (for body
text) to simpler fully-formed HTML. 

The package extends HTML::TreeBuilder to include functionality for parsing
email elements from an HTML string.

=head2 METHODS

=over 4

=item $parser->message_start(@message_start_tokens);

Sets the tokens to watch for that denote the beginning of a message. This
allows email messages to be embedded within a DIV or other HTML enclosing tag,
or simply just follow a particular sequence of tags.

The @message_start_tokens array is passed verbatim to the HTML::TreeBuilder/
HTML::Element functions for traversing the HTML tree. This is typically a
list of items such as

  '_tag', 'a', 'href', 'http://foo.bar.com'

which is interpreted to mean "look for an 'anchor' tag with an 'href'
parameter of 'http://foo.bar.com".

Since this is a list or array, I typically use the slightly easier-to-read
notation of

  '_tag' => 'a', 'href' => 'http://foo.bar.com'


=item $hdr_text = $parser->parse_header($field, $data);

Attempts to find a valid Email header name in $field, and a corresponding
value in $data. Potential header names are compared to those in
@mail_header_names iff $field matches the $LOOKS_LIKE_A_HEADER regexp.

If a valid field name is found, the returned string contains the header in the
form 'Name: Value', for example 'To: "A User" <user@server.com>'. If no such
field name is found, undef is returned.


=item $parser->message_read($html);

Reads the body text out of $html, and stores it for later processing. This
method will probably be folded into something else at a future date. 

=item $parser->body_as_html($message);
=item $parser->body_as_plain($message);
=item $parser->body_as_text($message);
=item $parser->body_as_appropriate($message);

Reads the (parsed and stored) message body and returns it in the specified
format. Normally you would only want to call body_as_appropriate(), since this
will handle the message's Content-Type correctly. The other methods are just
wrappers for body().

=item $normalised_html = $parser->parse_body_as_html($html);
=item $text = $parser->parse_body_as_text($html);
=item $text = $parser->parse_body($html, $style);

Deprecated methods; will be removed in a future version.

=item $parser->extract_body(extraction criteria..);

Extracts the body from the currently stored message, removing the 'extraction
criteria' from around it. The extraction criteria is a series of arrayrefs
containing tags to pass verbatim to HTML::Element::look_down().
This method may be called serially with different criteria each time. It will
return 0 if the criteria were not found, 1 otherwise.

This method may be folded into something else at a future date. 

=item my $body = $parser->body($message, $style);

Returns the parsed-and-stored message body.

How the message is returned depends on the value (if any) in $style; the
message's Content-Type (if any), and the current parsing and rendering
capabilities of HTML::TreeBuilder, according to the following rules:

1. TODO: rules.

=item $parser->remove_matching(match criteria);

Removes the provided match criteria (in the form of a list to pass to
HTML::TreeBuilder) from the message content-body. This performs no processing
on the contents other than that. Note that any contained elements are removed
along with the matched criteria.


=item my $flag = $parser->might_be_html($message, $text);

Returns 'html' if $text looks like HTML, based on the presence of a matching
tag </foo> for any tag <foo>; 'plain' otherwise. If debugging is on, adds
conversion info 'X-' headers to $message (which should be of type
'Mail::Internet'), if conversion is performed.


=item my $text = $parser->html2text($html);
=item my $text = Mail::Webmail::MessageParser::html2text($html);

'Converts' the provided html into plain text. 'Converts' is in quotes because
the conversion is pretty simplistic - in the worst case, <br> tags are
replaced with newlines, and no other conversion is performed.


=item $parser->start($tagname, $attr, $attrseq, $origtext);
=item $parser->end($tagname);

Override the corresponding methods in HTML::TreeBuilder, which itself
override those in HTML::Parser. These methods should not be called directly
from an application. They are here mainly to remove surplus HTML tags from
around the message body; these tags confuse HTML::TreeBuilder and thus result
in poor behaviour. 


=back


=head2 EXPORTS

Nothing.

=head2 CAVEATS

o  There may be some issues with the HTML entities being decoded.
o  Message bodies should really be enclosed in container tags; I have not
tested what happens if a non-contained tag is passed to message_start().
o  Conversion from HTML to text in some cases produces very poor results.
Generally it's best to let the parser figure out the most desirable output
format (it gives very good results if the Content-Type is set correctly).


=head1 AUTHOR

  Simon Drabble  E<lt>sdrabble@cpan.orgE<gt>

=head1 SEE ALSO

  Mail::Webmail::Yahoo

=cut
