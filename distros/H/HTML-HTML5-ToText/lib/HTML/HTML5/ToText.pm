package HTML::HTML5::ToText;

use 5.010;
use common::sense;
use utf8;

BEGIN {
	$HTML::HTML5::ToText::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::ToText::VERSION   = '0.004';
}

use Moose;
with 'MooseX::Traits';

has '+_trait_namespace' => (
	default => join('::', __PACKAGE__, 'Trait'),
);

use HTML::HTML5::Parser;
use XML::LibXML::PrettyPrint;

BEGIN
{
	my @noshow = qw[base basefont bgsound meta param script style];
	my @empty  = qw[br canvas col command embed frame hr
	                img is index keygen link];
	my @inline = qw[a abbr area b bdi bdo big button cite code dfn em font i
	                input kbd label mark meter nobr progress q rp rt ruby s
	                samp small span strike strong sub sup time tt u var wbr];
	my @block  = qw[address applet article aside audio blockquote body caption
	                center colgroup datalist del dir div dd details dl dt
	                fieldset figcaption figure footer form frameset h1 h2 h3
	                h4 h5 h6 head header hgroup html iframe ins legend li
	                listing map marquee menu nav noembed noframes noscript
	                object ol optgroup option p pre select section source summary
	                table tbody td tfoot th thead title tr track ul video];
	
	{
		no strict 'refs';
		*{ uc $_ } = sub { (shift)->_inline($_, @_) }
			foreach @inline;
		*{ uc $_ } = sub { (shift)->_block($_, @_) }
			foreach @block;
		*{ uc $_ } = sub { (shift)->_empty($_, @_) }
			foreach @empty;
		*{ uc $_ } = sub { (shift)->_noshow($_, @_) }
			foreach @noshow;
	}
}

sub process
{
	my ($self, $node, $no_clone) = @_;
	$self = $self->new unless ref $self;
	
	if ($node->nodeName eq '#document')
	{
		$node = $node->documentElement;
	}
	
	unless ($no_clone)
	{
		$node = $node->cloneNode(1);
	}
	
	if ($node->isa('XML::LibXML::Element'))
	{
		XML::LibXML::PrettyPrint->new_for_html->strip_whitespace($node);
		my $elem = uc $node->nodeName;
		my $str  = $self->$elem($node);
		$str =~ s{ (^\n+) | (\n+$) }{}gx;
		return "$str\n";
	}
	elsif ($node->nodeName eq '#text')
	{
		return $node->data;
	}
}

sub process_string
{
	shift->process(
		HTML::HTML5::Parser->load_html(string => shift, URI => shift),
		'no_clone',
	);
}

sub textnode
{
	my ($self, $node, %args) = @_;
	return $node->data;
}

sub _inline
{
	my ($self, $func, $node, %args) = @_;
	
	my $return = '';
	foreach my $kid ($node->childNodes)
	{
		if ($kid->nodeName eq '#text')
		{
			$return .= $self->textnode($kid, %args);
		}
		elsif ($kid->isa('XML::LibXML::Element'))
		{
			my $elem = uc $kid->nodeName;
			$return .= $self->$elem($kid, %args);
		}
	}
	
	$return;
}

sub _block
{
	my ($self, $func, $node, %args) = @_;
	
	my $return = "\n";
	foreach my $kid ($node->childNodes)
	{
		if ($kid->nodeName eq '#text')
		{
			$return .= $self->textnode($kid, %args);
		}
		elsif ($kid->isa('XML::LibXML::Element'))
		{
			my $elem = uc $kid->nodeName;
			my $str  = $self->$elem($kid, %args);
			
			if ($str =~ m{^\n} and not $kid->previousSibling)
			{
				$str =~ s{^\n}{};
			}
			
			if ($str =~ m{\n$} and not $kid->nextSibling)
			{
				$str =~ s{\n$}{};
			}
			
			$return .= $str;
		}
	}
	$return .= "\n";
	
	$return;
}

sub _empty
{
	return '';
}

sub _noshow
{
	return '';
}

around BR => sub { "\n" };
around HR => sub { "\n" . ("-" x 8) . "\n" };

__PACKAGE__
__END__

=head1 NAME

HTML::HTML5::ToText - convert HTML to plain text

=head1 SYNOPSIS

 my $dom = HTML::HTML5::Parser->load_html(IO => \*STDIN);
 print HTML::HTML5::ToText
     ->with_traits(qw/ShowLinks ShowImages RenderTables/)
     ->new()
     ->process($dom);

=head1 DESCRIPTION

The L<HTML::HTML5::ToText> module itself produces a pretty boring conversion
of HTML to text, but thanks to L<Moose> and L<MooseX::Traits> it can easily
be composed with "traits" that improve the output.

=head2 Compositor

=over

=item C<< with_traits(@traits) >>

This class method creates a new class that composes C<HTML::HTML5::ToText>
with each trait given, returning the name of that class. That class will
be a subclass of C<HTML::HTML5::ToText>.

Traits are taken to be in the "HTML::HTML5::ToText::Trait" namespace
unless overridden by prefixing the trait with "+".

=back

=head2 Constructors

=over

=item * C<< new(%attrs) >>

Creates a new instance of the class.

=item * C<< new_with_traits(traits => \@traits, %attrs) >>

Shortcut for:

 HTML::HTML5::ToText->with_traits(@traits)->new(%attrs)

=back

=head2 Attributes

As per usual for Moose classes, accessor methods are provided for each
attribute, and attributes may be set in the constructor.

C<HTML::HTML5::ToText> does not actually provide any attributes, but
some traits may.

=head2 Methods

=over

=item * C<< process($node) >>

Processes an L<XML::LibXML::Node> and returns a string. May be called as a
class or object method.

Because C<process> likes to perform some alterations to the DOM tree, as a
first stage it makes a clone of the DOM tree (so that it can leave the
original intact). If you don't care about any changes to the tree, and want
to save a bit of CPU, then you can suppress the cloning by passing a true
value as a second argument to C<process>.

 HTML::HTML5::ToText->process($node, 'no_clone')

=item * C<< process_string($string) >>

As per C<process>, but first parses the string with L<HTML::HTML5::Parser>.
The second argument (for cloning) does not exist as cloning is not needed in
this case.

=back

There are also methods named (in upper-case) after every element defined in
HTML5: C<< STRONG($node) >>, C<< DL($node) >>, C<< IMG($node) >> and so on,
which C<< process($node) >> delegates to; and a C<< textnode($node) >>
method which is the equivalent for text nodes. These are the methods which
traits tend to modify.

=head1 EXTENDING

L<MooseX::Traits> makes it pretty easy to cleanly extend this module. Say
for example, we want to add the feature where the HTML C<< <del> >> element
is output as the empty string. (The default behavious treats it rather like
C<< <div> >>.)

 {
   package Local::SkipDEL;
   use Moose::Role;
   override DEL => sub { '' };
 }
 
 print HTML::HTML5::ToText
   -> with_traits(qw/ShowLinks ShowImages +Local::SkipDEL/)
   -> process_string($html);

Or maybe we want to force C<< <big> >> elements into uppercase?

 {
   package Local::Embiggen;
   use Moose::Role;
   around BIG => sub
   {
     my ($orig, $self, $elem) = @_;
     return uc $self->$orig($elem);
   };
 }
 
 print HTML::HTML5::ToText
   -> with_traits(qw/+Local::Embiggen/)
   -> process_string($html);

Share your examples of extending HTML::HTML5::ToText at
L<https://bitbucket.org/tobyink/p5-html-html5-totext/wiki/Extending>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-ToText>.

=head1 SEE ALSO

L<HTML::HTML5::Parser>,
L<HTML::HTML5::Table>.

L<HTML::HTML5::ToText::Trait::RenderTables>,
L<HTML::HTML5::ToText::Trait::ShowImages>,
L<HTML::HTML5::ToText::Trait::ShowLinks>,
L<HTML::HTML5::ToText::Trait::TextFormatting>.

=head2 Similar Modules on CPAN

=over

=item * L<HTML::FormatText>

About 15 years old, and still maintained, this falls into the "mature"
category. This module is based on L<HTML::Tree>, so its HTML parser may
not behave as closely to modern browsers as HTML::HTML5::Parser's parsing,
but its conversion to text seems somewhat better than HTML::HTML5::ToText's
default output (i.e. with no traits applied).

At the time of writing, its bug queue on rt.cpan.org lists eight bugs, some
quite serious. However, since being taken over by its latest maintainer,
there seems to be progress being made on them.

Fairly extensible, but not in the mix-and-match traits way allowed by 
HTML::HTML5::ToText.

=item * L<HTML::FormatText::WithLinks>

An extension of HTML::FormatText.

=item * L<HTML::FormatText::WithLinks::AndTables>

An extension of HTML::FormatText::WithLinks.

The code that deals with tables is pretty crude compared with
HTML::HTML5::ToText::Trait::RenderTables. It doesn't support C<colspan>,
C<rowspan>, or the C<< <th> >> element. 

=item * L<LEOCHARRE::HTML::Text>

Very basic conversion; basically just tag stripping using regular expressions.

=item * L<HTML::FormatExternal>

Passes HTML through external command-line tools such as `lynx`. Obviously
this has limited portability.

=back

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

Everyone behind Moose. No way I could have done all this in a few hours 
without Moose's strange brand of meta-programming!

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

