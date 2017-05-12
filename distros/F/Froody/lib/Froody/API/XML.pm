package Froody::API::XML;
use strict;
use warnings;
use XML::LibXML;
use Froody::Method;
use Froody::ErrorType;
use Froody::Response::String;
use Froody::Logger;
my $logger = get_logger("froody.api.xml");

use base qw(Froody::API);
use Scalar::Util qw(weaken);

=head1 NAME

Froody::API::XML - Define a Froody API with xml

=head1 SYNOPSIS

  package MyAPI;
  use base qw{Froody::API::XML};
  
  sub xml { 
    return q{
      <spec>
        <methods>
          <method name="foo">....</method>
        </methods>
      </spec>
    };
   }
   
   1;

=head1 DESCRIPTION

This class is a helper base class for Froody::API.  It can parse a standard
format of XML and turn it into a bunch of Froody::Method objects.

=head1 METHODS

=over

=item xml

Subclasses must override this method to provide an XML specification.

=cut

sub xml {
  Froody::Error->throw("perl.use", "Please override the abstract method Froody::API::XML::xml()");
}

=item load( xml )

Calls C<load_spec()> with the return value of the C<xml> method.

=cut

sub load {
  my $class = shift;
  return $class->load_spec($class->xml);
}

=item load_spec($xml_string)

Turns a method spec xml string into an array of
C<Froody::Method> objects.

=cut

sub load_spec {
  my ($class, $xml) = @_;
  unless ($xml)
   { Froody::Error->throw("perl.methodcall.param", "No xml passed to load_spec!") }
  
  my $parser = $class->parser;
  my $doc = UNIVERSAL::isa($xml, 'XML::LibXML::Node') ? $xml 
          : eval { $parser->parse_string($xml) };
  Froody::Error->throw("froody.xml.invalid", "Invalid xml passed: $@")
    if $@;
  $doc->indexElements;
  
  my $method_node_path = '/spec/methods/method';
  my $error_node_path = '/spec/errortypes/errortype';
  if  ($doc->documentElement->nodeName eq 'rsp') {
    $method_node_path = '/rsp'.$method_node_path;
    $error_node_path = '/rsp'.$error_node_path;
  }

  my @methods = map { $class->load_method($_) }
    $doc->findnodes($method_node_path)
      or Froody::Error->throw('froody.xml.nomethods', "no methods found in spec!");
    
  my @errortypes = map { $class->load_errortype($_) }
    $doc->findnodes($error_node_path);

  return (@methods, @errortypes);
}

=item load_method($element)

Passed an XML::LibXML::Element that represents a <method>...</method>,
this returns an instance of Froody::Method that represents that method.

=cut

sub load_method {
  my ($class, $method_element) = @_;
  unless (UNIVERSAL::isa($method_element, 'XML::LibXML::Element')) {
    Froody::Error->throw("perl.methodcall.param",
                          "we were expected to be passed a XML::LibXML::Element!");
  }
  
  # work out the name of the element
  my $full_name = $method_element->findvalue('./@name')
    or Froody::Error->throw("froody.xml",
       "Can't find the attribute 'name' for the method definition within "
       .$method_element->toString);


  # create a new method
  my $method = Froody::Method->new()
                  ->full_name($full_name)
                  ->arguments($class->_arguments($method_element))
                  ->errors($class->_errors($method_element))
                  ->needslogin($class->_needslogin($method_element));
  my ($response_element) = $class->_extract_response($method_element, $full_name);
  if ($response_element) {
    my ($structure, $example_data) = $class->_extract_structure($response_element);
    $method->structure($structure);
    my $example = Froody::Response::String->new;
    $example->set_string("<rsp status='ok'>".$response_element->toString(1)."</rsp>");
    $example->structure($method);
    
    $method->example_response($example);
    weaken($example->{structure});
  } else {
    $method->structure({})
  }

  my $desc = $method_element->findvalue("./description");
  $desc =~ s/^\s+//;
  $desc =~ s/\s+$//;
  $method->description($desc);

  return $method;
}

# okay, we're parsing this
#  <arguments>
#    <argument name="sex">male or female</argument>
#    <argument name="hair" optional="1">optionally list hair color</argument>
#    <argument name="hair" optional="1">optionally list hair color</argument>
#  </arguments>

sub _arguments {
  my ($class, $method_element) = @_;

  # get all of the argument elements
  my @argument_elements = $method_element->findnodes('./arguments/argument');

  # convert them into a big old hash
  my %arguments;
  foreach my $argument_element (@argument_elements)
  {
    # pull our the attributes
    
    my $name     = $argument_element->findvalue('./@name');
    my $optional = $argument_element->findvalue('./@optional') || 0;
    my $type     = $argument_element->findvalue('./@type') || 'text';

    # Ugh.  Track this down.
    $type = 'text' if $type eq 'scalar';
    my @types = split /,/, $type;

    # extract the contents of <argument>...</argument> as the description
    my $description = $argument_element->findvalue('./text()');

    $arguments{$name}{multiple} = 1 unless $type eq 'text';
    $arguments{$name}{optional} = $optional;
    $arguments{$name}{doc}      = $description;
    $arguments{$name}{type} = \@types;

    # XXX: compose the list in Froody::Argument
    require Froody::Argument;
    my @TYPES = keys %{ Froody::Argument->_types() };
    push @TYPES, 'remaining'; # a special case.
    for my $_type (@types) {
      Froody::Error->throw("froody.api.unsupportedtype", "The type '$_type' is unsupported")
        unless grep { $_type eq $_ } @TYPES;
      if ($_type eq 'remaining') {
        $arguments{$name}{optional} = 1;
      }
    }

  }

  return \%arguments;
}

# get the response element from the XML
sub _extract_response {
  my ($class, $dom, $full_name) = @_;
  my ($structure) = $dom->findnodes("./response");
  return unless $structure;  # we don't *have* to have a structure

  return $class->_extract_children($structure, $full_name);
}

sub _extract_children {
  my ($class, $structure, $full_name) = @_;

  my @child_nodes = grep { $_->isa('XML::LibXML::Element') } $structure->childNodes;
  unless (@child_nodes) {
    my $structure_xml = '<rsp>' . $structure->textContent . '</rsp>';

    my $structure_doc = $class->parser->parse_string($structure_xml);
    @child_nodes = grep { $_->isa('XML::LibXML::Element') } $structure_doc->documentElement->childNodes();
  }
  Froody::Error->throw("froody.xml", "Too many top level elements in the structure for $full_name")
    unless @child_nodes <= 1;

  return @child_nodes;
}

sub _extract_structure {
  my ($class, $dom) = @_;

  return unless $dom;
  return _xml_to_structure_hash($dom);
}

sub _text_only {
  my $entry = shift;
  return if exists $entry->{attr};
  return if exists $entry->{elts};
  return if exists $entry->{multi};
  return 1 if $entry->{text};
}

sub _xml_to_structure_hash {
  my $node = shift;

  # Each element is explained in the top level results hash.
  my $spec = {};
  my $name = $node->nodeName;
  $spec->{''}{elts}{ $name }++;
  
  
  # Create the specification using a breadth-first iteration
  my @list = ( $node, $name );
  my %visited;
  for(my $i = 0; $i < @list; $i += 2 ) {
    my ($node, $path) = @list[$i..$i+1]; 
    # Add all non text child nodes to the end of the list.
    my $name = $node->nodeName;
    my @elements;

    my $has_non_text_nodes = 0;
    my $child_spec = $spec->{$path}{elts} ||= {};

    my $prefix = $path ? "$path/" : "";
    for my $child ($node->childNodes) {
        # Check if there's any text in the element we're looking at
        if ($child->isa('XML::LibXML::Text')) {
            next;
        } else {
            $has_non_text_nodes = 1;
        }
        my $nn = $child->nodeName;
        # Mark each child element seen as being a child element of our spec list
        $child_spec->{$nn}++ unless $visited{$path};
        push @list, ($child, $prefix.$nn);
    }
    
    # We've been here. Move along.
    if ($visited{$path}++) {
      $spec->{$path}{multi}++;
      next;
    }
    
    # Gather all attributes
    foreach ($node->attributes) {
      my $aname = $_->nodeName;
      $spec->{$path}{attr}{$aname}++;
    }
    
    my $is_nonempty_root = !length($prefix) && $spec->{$path};
    $spec->{$path}{text} = 1 
      unless $has_non_text_nodes || $is_nonempty_root;
  }
  
  _flatten_specification($spec);

  # TODO: Flatten the text nodes.

  return $spec;
      # TODO: Handling types is a Service level detail.
}

sub _flatten_specification {
    my $spec = shift;
    
    # Flatten element and attribute names, and make
    # sure that the multiplicity flag is correctly set.
    foreach my $key (keys %$spec) {
    # Flatten the list of names
    my $prefix = $key;
    $prefix .= $prefix ? '/' : '';
    foreach my $name (qw{attr elts}) {
      my @names = sort keys %{ $spec->{$key}{$name} };
      if ($name eq 'elts') {
        for my $cpath (@names) {
            $spec->{$prefix.$cpath}{multi} = ($spec->{$key}{$name}{$cpath} > 1) 
                                           ? 1
                                           : 0
                                           ;
        }
      }
      $spec->{$key}{$name} = \@names;
    }
    $spec->{$key}{multi} ||= 0;
    $spec->{$key}{text}  ||= 0;
    }
}

sub _errors {
  my ($class, $method_element) = @_;

  # extract out the error methods
  my @error_elements = $method_element->findnodes('./errors/error');

  # build them into a hash
  my %errors;
  foreach my $error_element (@error_elements) { 
  
    # extract the attributes
    my $code    = $error_element->findvalue('./@code') || '';
    my $message = $error_element->findvalue('./@message');

    # convert them into a a hash that has the error number as the
    # key, and contains a hashref with a message and description in it
    my $description = $error_element->textContent;
    $description =~ s/^\s+//;
    $description =~ s/\s+$//;
    $errors{ $code } = {
      message     => $message || '',
      description => $description
    };
  }

  return \%errors;
}

# returns true if the method element passed needs a login, i.e. has
# an attribute <method needslogin="1">.  Returns false in all other cases
sub _needslogin {
  my ($class, $method_element) = @_;
  return $method_element->findvalue('./@needslogin') || 0;
}

=item load_errortype

Passed an XML::LibXML::Element that represents an <errortype>...</errortype>,
this returns an instance of Froody::ErrorType that represents that error type.

=cut

sub load_errortype  {
  my ($class, $et_element) = @_;
  
  unless (UNIVERSAL::isa($et_element, 'XML::LibXML::Element')) {
    Froody::Error->throw("perl.methodcall.param",
                          "we were expected to be passed a XML::LibXML::Element!");
  }
  
  # work out the name of the element
  my $code = $et_element->findvalue('./@code') || '';
  Carp::cluck "no code in ".$et_element->toString(1) unless defined $code;

  my $et = Froody::ErrorType->new;
  $et->name($code);


  unless (grep { !UNIVERSAL::isa($_, "XML::LibXML::Text") } $et_element->childNodes) {
    my $et_str = $et_element->textContent;
    local $@;
    eval { 
      my $new_et = $class->parser()->parse_string(qq{<errortype code="$code">$et_str</errortype>}); 
      $et_element = $new_et->documentElement();
    };
    if ($@) {
      $logger->warn($@);
    }
  }

  my ($spec, $example_data) = $class->_extract_structure($et_element);
  foreach (keys %$spec) {
    my $val = delete $spec->{$_};
    s{^errortype}{err};  # 'errortype's are really 'err's
    $spec->{$_} = $val;
  }
  $spec->{''}{elts} = [ 'err' ];
  
  # enforce msg (code is already in here!)
  push @{ $spec->{err}{attr} }, "msg";
  
  $et->structure($spec);

  my $example = Froody::Response::String->new;
  $et_element->setNodeName("err");
  my $text = "<rsp status='fail'>".$et_element->toString(1)."</rsp>";
  $example->set_bytes($text);
  $example->structure($et);
  weaken($example->{structure});
  
  $et->example_response($example);

  return $et;
}

=item parser

This method returns the parser we're using.  It's an instance of XML::LibXML.

=cut

{
  my $parser = XML::LibXML->new;
  $parser->expand_entities(1);
  $parser->keep_blanks(0);
  sub parser { $parser }
}

=back

=head1 SPEC OVERVIEW

The specs handed to C<register_spec()> should be on this form:

  <spec>
    <methods>
      <method ...> </method>
      ...
    </methods>
    <errortypes>
       <errortype code="error.subtype">...</errortype>
       ...
    </errortypes>
  </spec>


=head2 <method>

Each method take this form:

  <method name="foo.bar.quux" needslogin="1">
    <description>Very short description of method's basic behaviour</description>
    <keywords>...</keywords>
    <arguments>...</arguments>
    <response>...</response>
    <errors>...</errors>
  </method>

=over

=item <keywords>

A space-separated list of keywords of the concepts touched upon
by this method. As an example, clockthat.events.addTags would
have "events tags" as its keywords. This way we can easily list
all methods that deals with tags, no matter where in the
namespace they live.

=item <arguments>

Each argument has two mandatory attributes: "name" and
"optional". The name is the name of the argument, and optional is
"1" if the argument is optional, or "0" otherwise.

  <argument name="api_key" optional="0">A non-optional argument</argument>
  <argument name="quux_id" optional="1">An optional argument</argument>

You can specify that your argument should accept a comma-separated list of values:

  <argument name="array_val" type="csv" optional="1">Don't
    worry about description for argument type deduction now.</argument>

=item <response>

A well-formed XML fragment (excluding the <rsp> tag) describing
by example how this method will respond. This section can be
empty if the method does not return. When a list of elements are
expected, your example response B<must contain at least two>
elements of the same name.

  <photoset page="1" per_page="10" pages="9" total="83">
    <name>beyond repair</name>
    <photo photo_id="1123" />
    <photo photo_id="2345" />
  </photos>

Currently we accept both a well-formed XML fragment and an
entity-encoded string that can be decoded to an XML fragment.

=item <errors>

A list of errors of this form:

  <error code="1" message="Short message">Longer error message</error>

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>

=cut

1;
