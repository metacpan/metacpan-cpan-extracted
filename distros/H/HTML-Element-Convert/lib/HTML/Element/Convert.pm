package HTML::Element::Convert;

use warnings;
use strict;

=head1 NAME

HTML::Element::Convert - Monkeypatch content conversion methods into HTML::Element

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

  use HTML::TreeBulder;
  use HTML::Element::Convert;

  my $tree = HTML::TreeBuilder->new_from_content($html);

  # Search for some JSON-encoded meta-data embedded in the document and extract it:
  my $element = $tree->look_down(...);
  my $hash = $element->extract_content;

  # This time extract the YAML data and delete the containing element from the tree:
  $element = $tree->look_down(...);
  $hash = $element->pull_content;

  # Convert the content of any <div> with a 'lang="markdown"' attribute into HTML:
  $tree->convert_content;

=over 4

=item $element->convert_content

Look for every div below $element containing a C<lang> attribute. If it recognizes C<lang>, it
will convert and replace the div's content.

Currently, only markdown is supported.

=item $content = $element->extract_content([TYPE])

Extract and parse the content of $element. If C<TYPE> is given, then this method will assume the content is of the given type, and try to parse it accordingly. Otherwise it will use the C<lang> attribute of $element to detemine the type.

=item $content = $element->pull_content([TYPE])

Like C<extract_content>, extract and parse the content of $element. It will also delete $element from the tree.

=back

=cut

use Carp;

our %PARSE_FUNC;
our %EXTRACT_FUNC;
BEGIN {
	1 and			do { eval { require Text::Markdown };	$PARSE_FUNC{markdown} = \&Text::Markdown::markdown unless $@ };
	1 and			do { eval { require JSON };		$PARSE_FUNC{JSON} = \&JSON::jsonToObj unless $@ };
	1 and			do { eval { require YAML::Syck };	$PARSE_FUNC{YAML} = \&YAML::Syck::Load unless $@ };
	$PARSE_FUNC{YAML} or	do { eval { require YAML };		$PARSE_FUNC{YAML} = \&YAML::Load unless $@ };
}


sub _as_text($) { return shift->as_text }
sub _as_raw_HTML($) { return join '', map { if (ref $_) { $_ = $_->as_XML; chomp $_; $_ =~ s/"/'/g } $_ } shift->content_list }

sub _extract_text { return _as_text shift }
$EXTRACT_FUNC{text} = \&_extract_text;

sub _extract_YAML { return $PARSE_FUNC{YAML}->(_as_raw_HTML(shift) . "\n") }
$EXTRACT_FUNC{YAML} = \&_extract_YAML;

sub _extract_JSON { return $PARSE_FUNC{JSON}->(_as_raw_HTML shift) }
$EXTRACT_FUNC{JSON} = \&_extract_JSON;

sub _extract_markdown { return HTML::TreeBuilder->new_from_content($PARSE_FUNC{markdown}->(_as_text shift)) }
$EXTRACT_FUNC{markdown} = \&_extract_markdown;

sub _extract {
	my $element = shift;
	my $type = shift;

	$type = "plain" if $type eq "text";
	my $func;
	for (qw(plain JSON YAML markdown)) {
		if ($type =~ m/^$_$/i) {
			$func = $_;
			last;
		}
	}

	return unless $func;
	return $EXTRACT_FUNC{$func}->($element);
}

package HTML::Element;

use Carp;
use UNIVERSAL;

sub extract_content {
	my $self = shift;
	my $type = shift;
	$type ||= $self->attr("lang");
	$type ||= "text";
	my $content;
	if	(! $type)	{}
	else 			{ $content = HTML::Element::Convert::_extract($self, $type) }
	return $content;
}

sub convert_content {
	my $self = shift;
	for (qw(markdown)) {
		my @elements = $self->look_down("_tag", "div", "lang", qr/$_/i);
		for my $element (@elements) {
			my $content = $element->extract_content;
			if (UNIVERSAL::can($content, "guts")) {
				my $new_element = $content->guts;
				if ($element eq $self) {
					$self->delete_content;
					$self->push_content($new_element->content_list);
					$self->attr("lang", undef);
					$new_element->delete;
				}
				else {
					$element->replace_with($new_element)->delete;
				}
			}
		}
	}
}

sub pull_content {
	my $self = shift;
	my $content = $self->extract_content(@_);
	$self->delete;
	return $content;
}

# TODO Check to see if we're using HTML::TreeBuilder::Select first...

# Alpha function
sub _extract_child_content {
	my $self = shift;
	if (UNIVERSAL::can($self, "select")) {
		my $query = shift or croak "Need a query (a CSS selector or XPath)";
		return $self->select($query => 'extract-content');
	}
}

# Alpha function
sub _pull_child_content {
	my $self = shift;
	if (UNIVERSAL::can($self, "select")) {
		my $query = shift or croak "Need a query (a CSS selector or XPath)";
		return $self->select($query => 'pull-content');
	}
}


=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-element-convert at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Element-Convert>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Element::Convert

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Element-Convert>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Element-Convert>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Element-Convert>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Element-Convert>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::Element::Convert
