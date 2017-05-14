package Fern;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(tag empty_element_tag render_tag render_tag_and_metadata);

sub _parse_attributes_and_content {
    my $attributes = shift;
    my @content = @_;

    if (!ref($attributes) || (ref($attributes) ne 'HASH' && ref($attributes) ne 'ARRAY')) {
        if (defined $attributes) {
            unshift @content, $attributes;
        }
        $attributes = {};
    }

    return ($attributes, @content);
}

sub render_tag_and_metadata {
    my ($atom, @params) = @_;
    return ref($atom) && ref($atom) eq 'CODE' ? ($atom->(@params)) : ($atom);
}

sub render_tag {
    my ($atom, @params) = @_;
    return (render_tag_and_metadata($atom, @params))[0];
}

sub _stringify_key_value_pair {
    my ($key, $value, @params) = @_;
    return $key . '="' . render_tag($value, @params) . '"';
}

sub _stringify_attribute_hash {
    my ($attribute_hash, @params) = @_;
    return '' if (!keys %$attribute_hash);
    return ' ' . join(' ', map { _stringify_key_value_pair($_, $attribute_hash->{$_}, @params) } keys %$attribute_hash);
}

sub _stringify_attribute_array {
    my ($attribute_array, @params) = @_;
    return '' if !@$attribute_array;
    return ' ' . join(' ', map { _stringify_key_value_pair($attribute_array->[2 * $_], $attribute_array->[2 * $_ + 1], @params) } (0 .. @$attribute_array / 2 - 1));
}

sub _stringify_attributes {
    my ($attributes, @params) = @_;
    if (ref($attributes) eq 'HASH') {
        return _stringify_attribute_hash($attributes, @params);
    }
    else {
        return _stringify_attribute_array($attributes, @params);
    }
}

sub _stringify_content {
    my ($content, @params) = @_;
    my @all_content = map { [render_tag_and_metadata($_, @params)] } @$content;
    return (
        @all_content ? join('', map {$_->[0]} @all_content) : '',
        map {@$_[1..$#$_]} @all_content,
    );
}

sub empty_element_tag {
    my $tag_name = shift;
    my ($attributes, @content) = _parse_attributes_and_content(@_);

    return sub {
        my ($stringified_content, @metadata) = _stringify_content(\@content, @_);
        if ($stringified_content) {
            return +("<$tag_name" .  _stringify_attributes($attributes, @_) .  ">$stringified_content</$tag_name>", @metadata);
        }
        else {
            return +("<$tag_name" .  _stringify_attributes($attributes, @_) .  " />", @metadata);
        }
    };
}

sub tag {
    my $tag_name = shift;
    my ($attributes, @content) = _parse_attributes_and_content(@_);

    return sub {
        my ($stringified_content, @metadata) = _stringify_content(\@content, @_);
        return +(
            "<$tag_name" .  _stringify_attributes($attributes, @_) .  ">" .
            $stringified_content .
            "</$tag_name>",
            @metadata
        );
    };
}

1;

__END__

=pod

=head1 NAME

Fern - XML tree creator

=head1 SYNOPSIS

  # <div random="lala"></div>
  $xml = render_tag(tag('div', {random => 'lala'}));
  
  # <div class="foo"><div class="bar"><div></div></div></div>
  $xml = render_tag(
      tag('div', {class => 'foo'},
          tag('div', {class => 'bar'},
              tag('div'))));
  
  # <div class="foo" name="foofoo">Test</div>
  $xml = render_tag(
      tag('div', [class => 'foo', name => 'foofoo'],
          'Test')
  );
  
  # <bar />
  $xml = render_tag(empty_element_tag('bar'));
  
  # $xml eq '<bar />', and @metadata is undef
  ($xml, @metadata) = empty_element_tag('bar')->();
  
  # tag() returns a function
  my $template = tag('div',
                     tag('span', sub { $_[0] } ),
                     tag('span', sub { $_[1] } ));
  
  # <div><span>Hello</span><span>World</span></div>
  $xml = render_tag($template->('Hello', 'World'));
  
  # <div><span>Goodbye</span><span>Cave</span></div>
  $xml = render_tag($template->('Goodbye', 'Cave'));
  
  # Custom Template
  sub custom_tag {
      my ($obj, $p1, $p2) = @_;
      return sub {
          return (
              render_tag(
                  tag('span',
                      'Class (' . $obj->{class} . ') and Param 1 (' . $p1 . ') and Param 2 (' . $p2 . ')'),
                  @_),
              {data => 5}
          );
      };
  }
  
  # $xml = <div><span>Class (this-class) and Param 1 (3) and Param 2 (test)</span></div>
  # @metadata = ({data => 5})
  ($xml, @metadata) = tag('div',
                          custom_tag({class => 'this-class'}, 3, 'test'));

=head1 DESCRIPTION

Fern is a protocol for XML generation using a pure functional approach, where
nested XML tags are equivalent to nested functions.  Any language that
supports first-class functions can implement Fern, and Fern's approach to
generation is extensible.

Since an XML tree is represented in Fern as a function, you can write parts of
your XML in your own functions, use native looping constructs, and so on.

=head1 MOTIVATION

A typical templating approach is that of creating a string template with
special escape tags and its own language, similar to PHP.  Examples in Perl
include Template::Toolkit and Mason.  The drawback is having to learn another
language, and it is often a language with amazing limitations compared to
general languages.  Some web developers claim that this is okay, that you do
not want a lot of messy logic in the middle of your HTML construction.  I like
to construct web pages as a system of nested components, so I have moved away
from the simplistic template approach.  I have found nothing but difficulty
when trying to modularize my template code in large applications with these
approaches.

I was then strongly attracted to template engines such as Common Lisp's
CL-WHO.  Lisp and other compiling languages make these DSLs fast, but they
have the problem of requiring special symbols to break out or to break back
into the DSL (CL-WHO's symbols: str, fmt, esc, htm).  In interpreted
languages, the special language DSLs tend to be slow and restrictive.  For
example, modules using Perl's Template::Declare do not mix nicely with Moose,
and the only means of abstraction is more templates that you have to register.

Other options basically boil down to string concatenation/replace tricks.

Finally, I have run into only one unpolished templating engine in the Lisp
world that dared to tackle the metadata problem.  What is metadata?  When you
use a particular component, it may require special JavaScript.  Unless you use
that component, you do not need to include the JavaScript.  In a complex
enough dynamic web page, you need a convenient way to communicate requirements
to a root site wrapper, such as JavaScript, additional CSS, meta keywords and
configurations, and page title.

I wanted something elegant, something minimal, something that does not require
me to join a religion, something without the problems above, and something I
can use in my server as well as in JavaScript.  Fern is that vision.

=head1 CUSTOM TAGS OR TEMPLATES

Fern does not come with a predefined set of known tags; instead, you can use
any tag with any case you want, even those which might break XML standards.

You can create custom templates by writing a function that generates a
function that returns the display string and a list of metadata.  For example:

  sub custom_tag {
      my ($obj, $p1, $p2) = @_;
      return sub {
          return (
              render_tag(
                  tag('span',
                      'Class (' . $obj->{class} . ') and Param 1 (' . $p1 . ') and Param 2 (' . $p2 . ')'),
                  @_),
              {data => 5}
          );
      };
  }
  
  # $xml = <div><span>Class (this-class) and Param 1 (3) and Param 2 (test)</span></div>
  # @metadata = ({data => 5})
  ($xml, @metadata) = tag('div',
                          custom_tag({class => 'this-class'}, 3, 'test'));


Because we honored the ($xml, @metadata) return convention for our generated
function, we can nest our function within other Fern tags.

=head1 METADATA

When you use a particular component, it may require special JavaScript.
Unless you use that component, you do not need to include the JavaScript
linkage.  In a complex enough dynamic web page, you need a convenient way to
communicate requirements to a root site wrapper, such as JavaScript links,
additional CSS, meta keywords and configurations, and page title.

Fern leaves it up to you how you want to handle arbitrary metadata, how to
construct your root site wrapper with that information.  However, it will
happily pass along your arbitrary metadata from nested children components to
the toplevel.

=head1 FUNCTIONS

=over 4

=item B<$tag_function = tag($name, $attributes_ref, @content)>

The I<tag> function generates a function (I<$tag_function>) that, when called,
will return I<($xml)>.  The I<$attributes_ref> is optional.

  my $tag_function = tag('div', 'hello');
  my ($xml) = $tag_function->();
  $xml eq '<div>hello</div>';

You may pass parameters to the I<$tag_function> call.

  $tag_function->('foo', 4)

Here is how to use the passed parameters:

  my $tag_function = tag('div', tag('span', sub{ $_[0] }, ' and ', sub { $_ [1] }));
  my ($xml) = $tag_function->('foo', 4);
  $xml eq '<div><span>foo and 4</span></div>';

One advantage of embedding functions is that we can apply additional
transformations to the passed-in parameters.  The functions may be custom
template functions.

=over 4

=item B<$name>

The name of the tag, case sensitive.

  render_tag(tag('foo')) eq '<foo></foo>'

=item B<$attributes_ref>

An optional reference to a hash or array of key-value pairs that will be
attributes of a tag element.  Hashes of attributes are closer to how XML is
intended to work in that attributes may be in any order, but for those times
you need explicit control over attribute ordering, you can use an array.

  render_tag(tag('foo', { color => 'red', size => 4 }))
  # <foo size="4" color="red"></foo>
  
  render_tag(tag('foo', [ color => 'red', size => 4 ]))
  # <foo color="red" size="4"></foo>

=item B<@content>

An optional array of content that appears between the start and end tags.  You
may pass in strings, numbers, and Fern-style functions.

  render_tag(tag('foo', 4, 5, 'and'))
  # <foo>45and</foo>

=item B<$tag_function>

The function generated by the I<tag> function.  When executed,
I<$tag_function> returns ($xml, @metadata).  You can use the utility
I<render_tag> to only return the XML string.

  my ($xml, @metadata) = $tag_function->('foo', 4);
  my $just_the_xml = render_tag($tag_function, 'foo', 4);

You may pass parameters to the I<$tag_function> call.

  $tag_function->('foo', 4)

Here is how to use the passed parameters:

  my $tag_function = tag('div', tag('span', sub{ $_[0] }, ' and ', sub { $_ [1] }));
  my ($xml) = $tag_function->('foo', 4);
  $xml eq '<div><span>foo and 4</span></div>';

=back

=item B<$tag_function = empty_element_tag($name, $attributes_ref, @content)>

The I<empty_element_tag> function is in every way the same as the I<tag>
function, except when no content is passed in, the resulting XML string is in
empty element form.

  my $tag_function = empty_element_tag('div', 'hello');
  my ($xml) = $tag_function->();
  $xml eq '<div>hello</div>';
  
  render_tag(empty_element_tag('div')) eq '<div />';
  render_tag(empty_element_tag('div', {id => 'foo'})) eq '<div id="foo" />';

=item B<render_tag($tag_function, @extra_parameters)>

Returns the XML string from the I<$tag_function>.

  my ($xml) = tag('div')->();
  $xml eq render_tag(tag('div'));
  $xml eq '<div></div>';

=over 4

=item B<$tag_function>

The function generated by the I<tag> function.

=item B<@extra_parameters>

Optional arguments for the I<$tag_function>.

  my $tag_function = tag('div', tag('span', sub{ $_[0] }, ' and ', sub { $_ [1] }));
  my $xml = render_tag($tag_function->('foo', 4));
  $xml eq ($tag_function->('foo', 4))[0];
  $xml eq '<div><span>foo and 4</span></div>';

=back

=item B<render_tag_and_metadata($tag_function, @extra_parameters)>

Returns the XML string and metadata from the I<$tag_function>.

  my ($xml, @metadata) = render_tag_and_metadata(tag('div'));
  
  # This returns the same thing.
  tag('div')->();

=over 4

=item B<$tag_function>

The function generated by the I<tag> function.

=item B<@extra_parameters>

Optional arguments for the I<$tag_function>.  Note the use of metadata in this
example:

  my $tag_function = tag('div', tag('span', sub{ $_[0], 'apple' }, ' and ', sub { $_ [1], 'banana' }));
  my ($xml, @metadata) = render_tag_and_metadata($tag_function->('foo', 4));
  $xml eq ($tag_function->('foo', 4))[0];
  $xml eq '<div><span>foo and 4</span></div>';
  $metadata[0] eq 'apple';
  $metadata[1] eq 'banana';

=back

=back

=head1 AUTHOR

Fern, the design specification and implementation, are creations of William
Schroeder during work at The Genome Institute at Washington University School
of Medicine (Richard K. Wilson, PI).

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2002-2013 Washington University in St. Louis, MO.

This sofware is licensed under the same terms as Perl itself.

=cut

