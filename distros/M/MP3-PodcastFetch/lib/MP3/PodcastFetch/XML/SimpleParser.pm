package MP3::PodcastFetch::XML::SimpleParser;
use HTML::Parser;

=head1 XML::SimpleParser -- a simple sax-based parser

=head1 SYNOPSIS

 package MyFooParser;
 use base 'MP3::PodcastFetch::XML::SimpleParser';

 # process <foo> tags
 sub t_foo {
   my $self  = shift;
   my $attrs = shift;
   if ($attrs) {  # tag is starting
       # do something
   }
   else {
       # do something else
   }
 }

 my $parser = MyFooParser->new();
 $parser->parse_file('/path/to/an/XML/file')
 my @results = $parser->results;

=head1 DESCRIPTION

This package provides a very simple stream-based XML parser. It
handles open and close tags and attributes. It does not handle
namespaces very well. It was written to support a variety of projects
that do not need sophisticated processing, including
MP3::PodcastFetch.

Do not confuse this with XML::SimpleParser, which is a DOM-based
parser.

To use this module, create a new subclass of
MP3::PodcastFetch::XML::SimpleParser, and define a new method for each
tag that you wish to process (all other tags will be ignored). The
method should be named t_method_name, where "method_name" should be
replaced by the name of the tag you wish to handle. Tag names are case
sensitive. For exammple, if the XML file you wish to parse looks like
this:

  <foo size="2">
     <bar>Some char data</bar>
     <bar>Some more char data</bar>
  </foo>

You could define a t_foo() and a t_bar() method to handle each of
these tags. If a tag name has a funny character in it, such as "-",
use a method that has an underscore there instead. The same goes for
namespace tags: for a tag like <podcast:foo>, define a method named
podcast_foo(). Sorry, but dynamic resolution of namespaces is not
supported.

Methods should look like this:

 sub t_foo {
   my $self  = shift;
   my $attrs = shift;
   if ($attrs) {
      # do something to handle the start tag
   }
   else {
      # do something to handle the end tag
   }
 }

When the <foo> start tag is encountered, a hash reference containing
the start tag's attributes are passed as the second argument (if there
are no attributes, then an empty hash is provided). When the end tag
is encountered, $attrs will be undef. This allows you to distinguish
between start and end tags.

Ordinarily you will want to set up objects when encountering the start
tag and close and clean them up when encountering the end tag. The
following example shows how to transform the snippet of XML shown
above into the following data structure:

 { size      => 3,
   bar_list  => ['Some char data','Some more char data']
 }

Here's the code:

 sub t_foo {
   my $self  = shift;
   my $attrs = shift;
   if ($attrs) { # starting
      $self->{current} = { size     => $attrs->{size}
                           bar_list => []
                         }
   }
   else {
      $self->add_object($self->{current});
      undef $self->{current};
   }
 }

 sub t_bar {
    my $self  = shift;
    my $attrs = shift;
    if ($attrs) { # starting
    }
    else {
      my $list = $self->{current}{bar_list};
      die "ERROR: got a <bar> without an enclosing <foo>" unless $list;
      my $data = $self->char_data; # get contents
      push @$list,@data;
    }
 }

When t_foo() encounters the start of the <foo> tag, it creates a new
hash and stores it in a temporary hash key called "current". When it
encounters the </foo> tag (indicated by an undefined $attrs argument),
it fetches this hash and calls the inherited add_object() method to
add this result to the list of results to return at the end of the
parse. It then undefs the {current} key.

The t_bar method does nothing when the opening <bar> is encountered,
but when </bar> is seen, it fetches the array ref pointed to by
$self->{current}{bar_list} and adds the text content of the
<bar></bar> section to the list. The inherited char_data() method
makes it possible to get at this data. It then pushes the character
data onto the end of the list.

When working with this subclass, you would call parse_file() to parse
an entire file at once or parse() to parse a data stream a bit at a
time. When the parse is finished, you'd call result() to get the list
of data objects (in this case, a single hash) added by add_object().

You can also define a callback that will be invoked each time
add_object() is called in order to process each object as it comes in,
rather than storing it for later retrieval.

You may also override the do_tag() method in order to process
unexpected tags that do not have a named method to process them.

=head1 METHODS

=over 4

=cut

use warnings;
use strict;

=item $parser = MyParserSubclass->new()

This method creates a new parser object in the current subclass. It takes no arguments.

=cut

sub new {
  my $class  = shift;
  my $self   = bless {},ref $class || $class;
  my $parser = HTML::Parser->new(api_version => 3,
				 start_h       => [ sub { $self->tag_starts(@_) },'tagname,attr' ],
				 end_h         => [ sub { $self->tag_stops(@_)  },'tagname' ],
				 text_h        => [ sub { $self->char_data(@_)  },'dtext' ]);
  $parser->xml_mode(1);
  eval { $parser->utf8_mode(1); };
  $self->parser($parser);
  return $self;
}

=item $low_level_parser = $parser->parser([$new_low_level_parser])

MP3::PodcastFetch::XML::SimpleParser uses HTML::Parser (in xml_mode)
to do its low-level parsing. This method sets or gets that parser.

=cut

sub parser {
  my $self = shift;
  my $d    = $self->{'XML::SimpleParser::parser'};
  $self->{'XML::SimpleParser::parser'} = shift if @_;
  $d;
}

=item $parser->parse_file($path)

This method fully parses the file given at the indicated path.

=cut

sub parse_file {
  shift->parser->parse_file(@_);
}

=item $parser->parse($partial_data)

This method parses the partial XML data given by the string
$partial_data. This allows incremental parsing of web data using,
e.g., the LWP library. Call this method with each bit of partial data,
then call eof() at the end to allow the parser to clean up its
internal data structures.

=cut

sub parse {
  shift->parser->parse(@_);
}

=item $parser->eof()

Tell the parser to finish the parse. Use at the end of a series of
parse() calls.

=cut

sub eof {
  shift->parser->eof;
}

=item $parser->tag_starts

This method is called during the parse to handle a start tag. It
should not ordinarily be overridden or called directly.

=cut

# tags will be handled by a method named t_TAGNAME
sub tag_starts {
  my $self = shift;
  my ($tag,$attrs) = @_;
  $tag =~ s/[^\w]/_/g;
  my $method = "t_$tag";
  $self->{'XML::SimpleParser::char_data'} = '';  # clear char data
  $self->can($method)
    ? $self->$method($attrs) 
    : $self->do_tag($tag,$attrs);
}

=item $parser->tag_stops

This method is called during the parse to handle a stop tag. It should
not ordinarily be overridden or called directly.

=cut

# tags will be handled by a method named t_TAGNAME
sub tag_stops {
  my $self = shift;
  my $tag = shift;
  $tag =~ s/[^\w]/_/g;
  my $method = "t_$tag";
  $self->can($method)
    ? $self->$method()
    : $self->do_tag($tag);
}

=item $parser->char_data

This method is called internally during the parse to handle character
data.  It should not ordinarily be overridden or called directly.

=cut

sub char_data {
  my $self = shift;
  if (@_ && length(my $text = shift)>0) {
    $self->{'XML::SimpleParser::char_data'} .= $text;
  } else {
    $self->trim($self->{'XML::SimpleParser::char_data'});
  }
}

=item $parser->cleanup

This method is provided to be called at the end of the parse to handle
any cleanup that is needed.  The default behavior is to do nothing,
but it can be overridden by a subclass to provide more sophisticated
processing.

=cut

sub cleanup {
  my $self = shift;
}

=item $parser->clear_results

This method is called internally at the start of the parse to clear
any accumulated results and to get ready for a new parse.

=cut

sub clear_results {
  shift->{'XML::SimpleParser::results'} = [];
}

=item $parser->add_object(@objects)

This method can be called during the parse to add one or more objects
to the results list.

=cut

# add one or more objects to our results list
sub add_object {
  my $self = shift;
  if (my $cb = $self->callback) {
    eval {$cb->(@_)};
    warn $@ if $@;
  } else {
    push @{$self->{'XML::SimpleParser::results'}},@_;
  }
}

=item @results = $parser->results

In a list context this method returns the accumulated results from the
parse.

In a scalar context, this method will return an array reference.

=cut

sub results {
  my $self = shift;
  my $r = $self->{'XML::SimpleParser::results'} or return;
  return wantarray ? @$r : $r;
}

=item $parser->do_tag

This method is called whenver the parse encounters a tag that does not
have a specific method to handle it. The call signature is identical
to t_TAGNAME methods. By default, it does nothing.

=cut

sub do_tag {
  my $self = shift;
  my ($tag,$attrs) = @_;
  # do nothing
}

=item $callback = $parser->callback([$new_callback])

This accessor allows you to get or set a callback code that will be
used to process objects generated by the parse. If a callback is
defined, then add_object() will not add the object to the results
list, but will instead pass it to the callback for processing. If
multiple objects are passed to add_object, then they will be passed to
the callback as one long argument list.

=cut

# get/set callback
sub callback {
  my $self = shift;
  my $d = $self->{'XML::SimpleParser::callback'};
  $self->{'XML::SimpleParser::callback'} = shift if @_;
  $d;
}

=item $trimmed_string = $parser->trim($untrimmed_string)

This internal method strips leading and trailing whitespace from a
string.

=cut

# utilities
sub trim {
  my $self = shift;
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string;
}

1;

=back

=head1 SEE ALSO

L<podcast_fetch.pl>,
L<MP3::PodcastFetch>,
L<MP3::PodcastFetch::Feed>,
L<MP3::PodcastFetch::Feed::Channel>,
L<MP3::PodcastFetch::Feed::Item>,
L<MP3::PodcastFetch::TagManger>,

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2006 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

