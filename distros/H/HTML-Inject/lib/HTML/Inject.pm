package HTML::Inject;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$HTML::Inject::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Inject::VERSION   = '0.004';
}

use constant {
	true       => !!1,
	false      => !!0,
	read_only  => 'ro',
	read_write => 'rw',
};

use Carp;
use HTML::HTML5::Parser;
use IO::Detect qw( is_filehandle is_filename );
use Scalar::Does 0.002 qw( blessed reftype -constants );
use XML::LibXML 1.94;

sub must_do {
	my $role = shift;
	return sub { does($_[0], $role) or confess "Does not do role $_[0]" };
}

use Moo;
use namespace::sweep -also => [qw(
	must_do
	true false read_only read_write
)];

has target => (
	is         => read_only,
	isa        => must_do( 'XML::LibXML::Document' ),
	coerce     => \&_coerce_dom,
	required   => true,
);

has missing_nodes => (
	is         => read_write,
	isa        => must_do( ARRAY ),
	default    => sub { [] },
);

has head_element_test => (
	is         => read_only,
	isa        => must_do( CODE ),
	default    => sub { sub { no warnings; $_[0]->nodeName ~~ [qw(title link meta style)] } },
);

has body_element_test => (
	is         => read_only,
	isa        => must_do( CODE ),
	default    => sub { sub { no warnings; $_[0]->nodeName ~~ [qw(script map)] } },
);

sub inject
{
	my ($self, $content) = @_;
	my %content = $self->_find_content($content);
	my $dom     = $self->target->cloneNode(true);
	
	@{ $self->missing_nodes } = ();
	while (my ($id, $el) = each %content)
	{
		if ($id =~ /^-inject/)
		{
			if ($self->head_element_test->($el))
				{ $dom->getElementsByTagName('head')->get_node(1)->appendChild($el) }
			elsif ($self->body_element_test->($el))
				{ $dom->getElementsByTagName('body')->get_node(1)->appendChild($el) }
			else
				{ push @{ $self->missing_nodes }, $el }
		}
		else
		{
			my $target = $dom->findnodes(qq{//*[\@id="$id"]});
			if ($target->size)
			{
				$target->foreach(sub {
					my $t = $_;
					$t->{$_} = $el->{$_} for keys %$el;
					$t->appendChild($_->cloneNode(1)) for $el->childNodes;
				});
			}
			else
			{
				push @{ $self->missing_nodes }, $el;
			}
		}
	}
	
	return $dom;
}

sub inject_and_new
{
	my ($self, $content) = @_;
	my $class = ref $self;
	$class->new( target => $self->inject($content) );
}

sub _find_content
{
	my ($self, $content) = @_;
	my %rv;
	
	if (does($content, ARRAY))
	{
		for my $c (@$content)
		{
			my %tmp = $self->_find_content($c);
			$rv{$_} //= $tmp{$_} for keys %tmp;
		}
		return %rv;
	}
	
	my $i;
	_coerce_dom($content)
		-> findnodes('/*/*/*')
		-> foreach(sub {
			$rv{ $_->{id} ? $_->{id} : sprintf('-inject_%d', ++$i) } = $_;
		});
	return %rv;
}

sub _coerce_dom
{
	my ($it) = @_;
	
	return $it
		if does($it, 'XML::LibXML::Document');
	
	return HTML::HTML5::Parser::->load_html(IO => $it)
		if is_filehandle $it;
	
	return HTML::HTML5::Parser::->load_html(location => $it)
		if is_filename $it;
	
	return HTML::HTML5::Parser::->load_html(location => "$it")
		if blessed $it && $it->isa('URI');
	
	return HTML::HTML5::Parser::->load_html(location => "$it")
		if !blessed $it && $it =~ /^(https?|file):\S+$/i;
	
	return HTML::HTML5::Parser::->load_html(string => $it)
}

1;

__END__

=head1 NAME

HTML::Inject - inject content from one HTML file into another

=head1 SYNOPSIS

 use HTML::Inject;
 
 my $template = HTML::Inject::->new(dom => <<'TARGET');
 <!doctype html>
 <html>
    <head></head>
    <body>
       <div id="content"></div>
       <p class="copyright">&copy; 2012 Acme Inc</p>
    </body>
 </html>
 TARGET
 
 my $result = $template->inject(<<'SOURCE');
 <!doctype html>
 <html>
    <head>
       <title>Hello World</title>
    </head>
    <body>
       <div id="content">A greeting to the planet!</div>
    </body>
 </html>
 SOURCE
 
 print $result->toString;
 # <!doctype html>
 # <html>
 #    <head>
 #       <title>Hello World</title>
 #    </head>
 #    <body>
 #       <div id="content">A greeting to the planet!</div>
 #       <p class="copyright">&copy; 2012 Acme Inc</p>
 #    </body>
 # </html>

=head1 DESCRIPTION

C<HTML::Inject> is a "template system lite". It allows you to inject content
from one HTML file (the "source") into another HTML file (the "target") that
has placeholders for that content.

=head2 Constructor

=over

=item C<< new(%attr) >>

Moose-style constructor, accepting a hash of attributes. (Actually this
package uses L<Moo>.)

=back

=head2 Attributes

=over

=item C<< target >>

The target HTML to inject. May be provided as an L<XML::LibXML::Document>
object, a file handle, a URL, a filename or a plain string of HTML. (To
disambiguate between a string of HTML, and a filename/URL which is also a
string, strings of HTML must contain at least one line break character!!)
Whatever is provided, it will be coerced into an L<XML::LibXML::Document>.

=item C<< head_element_test >>

A coderef which takes an L<XML::LibXML::Element> object and returns a
boolean. The default is probably fairly sane, matching all C<< <title> >>,
C<< <link> >>, C<< <meta> >> and C<< <style> >> elements.

See L</"Injection Technique"> for an explanation of the head element test.

=item C<< body_element_test >>

A coderef which takes an L<XML::LibXML::Element> object and returns a
boolean. The default is probably fairly sane, matching all C<< <script> >>
and C<< <map> >> elements.

See L</"Injection Technique"> for an explanation of the body element test.

=item C<< missing_nodes >>

An arrayref of XML::LibXML::Node objects. You should probably not set
this attribute in the constructor, or indeed at all. It's intended as
a place for HTML::Inject to pass back problem nodes to the caller.

=back

=head2 Methods

=over

=item C<< inject($source) >>

Injects content from the source into the target returning an
L<XML::LibXML::Document> as the result. The result is generated
by deep cloning the target, thus the same target can be reused
again and again with different source data.

Like the target passed to the constructor, the source data can be
provided as an L<XML::LibXML::Document> object, a file handle, a URL, a
filename or a plain string of HTML. It may also be an arrayref of any
of the above.

See L</"Injection Technique"> for more details.

=item C<< inject_and_new($source) >>

As per C<inject>, but returns the result as a new HTML::Inject target.
That is, this:

 my $template2 = $template->inject_and_new($content);

is equivlent to:

 my $template2 = HTML::Inject::->new(
    $template->inject($content),
 );

This is vaguely useful for some chanined operations.

=back

=head2 Injection Technique

Before beginning the injection, the C<missing_nodes> list is cleared.

As a first step, HTML::Inject finds a list of potentially injectable nodes
in the source document. Potentially injectable things are any nodes which
are direct children of the HTML C<< <head> >> and C<< <body> >> elements.

It then loops through the potentially injectable nodes.

For elements which have an C<< @id >> attribute, the injection technique
is to find the element with the corresponding C<< @id >> in the target
document, and then clone the source element's contents and attributes
onto the target element. If the target element already has contents, these
will not be removed, and the new content is added after the existing content.

Nodes without an C<< @id >> attribute are handled differently: they are
added to the I<end> of the target document's HTML C<< <head> >> or
C<< <body> >> element, but only if the element passes the C<head_element_test>
or C<body_element_test>. (Elements which pass both tests will be added to
the C<< <head> >>.) This allows certain elements from the source document
like C<< <meta> >>, C<< <title> >> and C<< <script> >> to be injected to the
target document without having to worry too much about exactly where they're
injected. They won't be injected in any especially predictable order.

Any potentially injectable nodes which have not been injected will be
pushed onto the C<missing_nodes> list. You may wish to loop through
this list yourself, adding them to the result document using some sort
of logic of your choice.

=head2 HTML Parsing

HTML parsing is via L<HTML::HTML5::Parser> which supports some nicely
idiomatic HTML. The example in the L</"SYNOPSIS"> could have used:

 my $result = $template->inject(<<'SOURCE');
 <title>Hello World</title>
 <div id="content">A greeting to the planet!</div>
 SOURCE

That is, for the source content, you only really need to include the
actual elements that you wish to inject. You can ignore the "skeletal
parts" of the HTML.

=head2 HTML Output

The result of C<inject> is an XML::LibXML::Document element. This can
be stringified using its C<toString> method. See L<XML::LibXML::Node> for
details.

If serving the output as C<< text/html >>, then you may be better off
stringifying it using L<HTML::HTML5::Writer> which makes special effort
to stringify documents in a way browsers can actually cope with.

If you want your HTML nicely indented, try L<XML::LibXML::PrettyPrint>.
(Indenting is nice when you're debugging, but you may wish to switch it
off for deployment, as it imposes a performance penalty.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-Inject>.

=head1 SEE ALSO

L<Cindy>, L<Apache2::Layout>, L<Template::Semantic>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

