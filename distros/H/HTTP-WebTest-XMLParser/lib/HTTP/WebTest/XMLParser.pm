package HTTP::WebTest::XMLParser;
use strict;
use XML::SAX;

use vars qw($VERSION);

$VERSION = '1.00';

my $webtest_definition_version = '1.0';  # NOTE: file lexical scope 

=head1 NAME

HTTP::WebTest::XMLParser - Parse wtscript in XML representation.

=head1 SYNOPSIS

    use HTTP::WebTest::XMLParser;
    my ($tests, $opts) = HTTP::WebTest::XMLParser->parse($xmldata);

    use HTTP::WebTest;
    my $wt = new HTTP::WebTest;
    $wt->run_tests($tests, $opts);

    HTTP::WebTest::XMLParser->as_xml($tests, $opts, { nocode => 1 });

=head1 DESCRIPTION

Parses a wtscript file in XML format and converts it to a set of test objects.

=head2 VERSION

 $Revision: $

=head1 XML SYNTAX

The xml format follows wtscript closely, with the following rules:

 - the root element is <WebTest/>
 - global paramters are in a <params/> element
 - test definitions are in <test/> elements
 - a list is represented by a <list/> element
 - a scalar param. is represented by a <param/> element
 - a code segment is represented by a <code/> element
 - named parameters are named throug a 'name' attribute

The DTD is available in 'scripts/webtest.dtd' from the distribition.
For examples see the test definitions in t/*xml from the distribution.

A conversion script from wtscript to XML is available in
'scripts/testconversion' from the distribution. This script
also converts XML definitions from earlier alpha versions of
this module.

=head2 Example

This example is the equivalent of the same example for HTTP::WebTest
 

The definition of tests and params from the original example:

  my $tests = [
                 { test_name    => 'Yahoo home page',
                   url          => 'http://www.yahoo.com',
                   text_require => [ '<a href=r/qt>Quotations</a>...<br>' ],
                   min_bytes    => 13000,
                   max_bytes    => 99000,
                 }
               ];
  my $params = { mail_server    => 'mailhost.mycompany.com',
                 mail_addresses => [ 'tester@mycompany.com' ],
                 mail           => 'all',
                 ignore_case    => 'yes',
               };

This Perl script tests Yahoo home page and sends full test
report to "tester@mycompany.com".
 
 use HTTP::WebTest;
 use HTTP::WebTest::XMLParser;
 
 my $XML = <<"EOXML";
 <WebTest version="1.0"> 
  <params>
    <param name="ignore_case">yes</param>
    <list name="mail_addresses">
      <param>tester@mycompany.com</param>
    </list>
    <param name="mail_server">mailhost.mycompany.com</param>
    <param name="mail">all</param>
  </params>
  <test>
    <param name="min_bytes">13000</param>
    <param name="max_bytes">99000</param>
    <param name="url">http://www.yahoo.com</param>
    <param name="test_name">Yahoo home page</param>
    <list name="text_require">
      <param><![CDATA[<a href=r/qt>Quotations</a>...<br>]]></param>
    </list>
  </test>
 </WebTest>
 EOXML
 
 my ($tests, $params) = HTTP::WebTest::XMLParser->parse($XML);

 my $webtest = new HTTP::WebTest;
 $webtest->run_tests($tests, $params);

=head1 CLASS METHODS

=head2 parse ($xmldata)

Parses wtscript in XML format passed in C<$xmldata> as string.

=head3 Returns

A list of two elements - a reference to an array that contains test
objects and a reference to a hash that contains test parameters.

=cut

sub parse {
  my $class = shift;
  my $data = shift;

  my $filter = new WebTestFilter(); # see below
  my $p = XML::SAX::ParserFactory->parser(Handler => $filter);
  $p->parse_string($data);
  #FIXME: add $p->parse_string("<foo/>") and $p->parse_uri("test.xml");
  my $cfg = $filter->finalize();

  return($cfg->{tests}, $cfg->{params});
}

=head2 as_xml ($tests, $params, $opts)

Given a set of test parameters and global parameters, returns the XML 
representation of the test script as a string.

The test definitions and parameters can be obtained from plain C<wtscript>
as parsed by L<HTTP::WebTest::Parser>.

=head3 Option nocode

Forces the replacement of C<CODE> sections by dummy subroutines.
Example:

 $xml = HTTP::WebTest::XMLParser->as_xml(
                                         $tests,
                                         $param,
                                         { nocode => 1 }
                                        );

=head3 Returns

The test defintion in XML format.

=head1 BUGS 

=head3 Method as_xml() 

Any C<CODE> references in the test object will be replaced by a 
dummy subroutine if L<B::Deparse> is missing from your installation.
In order to make this more predictable, you can force this 
behaviour by specifying option C<nocode>.

Lists of named parameters are internally stored as array with
an even number of elements, rather than a hash. 
This has the purpose of preserving order of the parameters and
also allow more than one parameter with the same name.
When such a list is serialized back into XML, the list element
contains a list of anonymous parameters, one for each key and
value.

Original test definition:

  <list name="http_headers">
    <param name="Accept">text/html,application/xml+html</param>
    <param name="Accept-Encoding">deflate,gzip</param>
  </list>

Output as:

  <list name="http_headers">
    <param>Accept</param>
    <param>text/html,application/xml+html</param>
    <param>Accept-Encoding</param>
    <param>deflate,gzip</param>
  </list>

Both versions are functionally equivalent (just like ',' 
and '=>' notation are equivalent for Perl hashes).

=cut

sub as_xml {
  my $class = shift;
  my ($tests, $params, $opt) = @_;
  
  my $writer = new WebTestWriter($opt);
  $writer->as_xml($tests, $params);
}

=head1 COPYRIGHT

Copyright (c) 2002 - 2003 Johannes la Poutre.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest>

L<HTTP::WebTest::Parser>

L<HTTP::WebTest::API>

Examples are in directory 't' from the distribution, the DTD and
utility scripts are in subdir 'scripts' from the distribution. 

=cut

################################################## SAX handler class ###
package WebTestFilter;
use strict;
use base qw(XML::SAX::Base);
use Carp qw(croak);
use HTTP::WebTest::Utils qw(eval_in_playground make_sub_in_playground);

sub new {
  my $class = shift;
  # my %opt = @_; # parser options 
  my $self = {};
  $self->{tests} = [()];   # test definitions
  $self->{params} = {};    # global params
  $self->{stack} = {};     # stack for current test node
  $self->{name} = '';      # current element name
  $self->{context} = [()]; # XML element stack
  return bless $self, $class;
}

sub characters {
  my $self = shift;
  my ($chars) = @_;
  $self->{charbuf} .= $chars->{Data};
}

sub start_element {
  my $self = shift;
  my ($elt) = @_;
  my $element = $elt->{Name};
  my $parent = $self->{context}->[-1] || '';
  if (($parent eq 'param') || ($parent eq 'code')) {
    $self->_croak(sprintf 'No child elements allowed for element "<%s/>"', $parent);
  }
  $self->{charbuf} = ''; # reset character buffer
  # we have 4 relevant events:
  # - param with name attribute
  #   - list context:   pair of 2 scalars (preserve list order)
  #   - scalar context: hash (key, value) pair
  # - param (unnamed)
  #   - list context:   single value 
  # - named list
  #   - scalar context: named array (hash key, value = arrayref)
  # - list (unnamed)
  #   - list context:   (anonymous) arrayref
  # character data is handled in end_element
  my $name = $elt->{Attributes}->{'{}name'}->{Value};
  #printf "Elt: %s, Name: %s, Context: %s\n", $element, $name || '-', join('/', @{$self->{context}});
  if (($element eq 'param') || ($element eq 'code')) {
    if (defined $name) {
      if ($parent eq 'list') {                   # named param, list context
        # push param name as list element
        # character data handled in end_element
        if (ref $self->{stack}->{$self->{name}}->[-1] eq 'ARRAY') {
          # Nested list (LoL):
          push @{ $self->{stack}->{$self->{name}}->[-1] }, $name;
          $self->{sp} = $self->{stack}->{$self->{name}}->[-1];
        } else {
          # plain (top level) list:
          push @{ $self->{stack}->{$self->{name}} }, $name;
          $self->{sp} = $self->{stack}->{$self->{name}};
        }
      } else {                                                  # named param, scalar context
        # keep track of last name (= hash key)
        $self->{name} = $name;
        $self->{sp} = $self->{stack}->{$self->{name}};
        # character data will be assigned to 
        # $self->{stack}->{$self->{name}} in end_element
      }
    } else {                                                    # unnamed param (list context)
      # character data only; handled in end_element
      if (! $parent eq 'list') {
        $self->_croak('Invalid unnamed param in scalar context');
      }
      $self->{sp} = $self->{stack}->{$self->{name}};
    }
  } elsif ($element eq 'list') {
    if (defined $name) {                                        # named list
      if ($parent eq 'list') {
        $self->_croak('Invalid named list in list context');
      }
      # create empty named list, hash key = name
      $self->{sp} = $self->{stack}->{$name} = [()];
      # keep track of last name (= hash key)
      $self->{name} = $name;
    } else {                                                    # unnamed list
      # anonymous list, push ref. to higher level list
      push @{ $self->{stack}->{$self->{name}} }, [()];
      $self->{sp} = $self->{stack}->{$self->{name}};
    }
  } elsif ($parent eq 'WebTest') {
    # create a new stack for each second level element (test or params)
    $self->{sp} = $self->{stack} = {};
  } elsif ($element eq 'WebTest') {
    # root element, validate version attribute
    my $version = $elt->{Attributes}->{'{}version'}->{Value} || '0';
    if ($version < $webtest_definition_version) {
      $self->_croak("WebTest definition should be version $webtest_definition_version or newer");
    }
  } else {
    # $self->_croak(sprintf('Unexpected element <%s>', $element));
  }
  push @{$self->{context}}, $element;
  return;
}

sub end_element {
  my $self = shift;
  my ($elt) = @_;
  my $element = $elt->{Name};
  if ($element eq 'code') {
    $self->{charbuf} = make_sub_in_playground($self->{charbuf});
  }
  if ($element eq 'test') {
    push @{ $self->{tests} }, $self->{stack};
  } elsif ($element eq 'params') {
    $self->{params} = $self->{stack};
  } elsif (($element eq 'param') || ($element eq 'code')) {
    if (ref $self->{sp}  eq 'ARRAY') {
      # list parameter: push character buffer on stack
      push @{ $self->{sp} }, $self->{charbuf};
    } else {
      # plain scalar parameter: assign character buffer
      $self->{stack}->{$self->{name}} = $self->{charbuf};
    }
  } elsif ($element eq 'list') {
    $self->_croak('Invalid character data in "list" element') if ($self->{charbuf} =~ /[^\s]/);
  }
  pop @{$self->{context}};
  $self->{charbuf} = '';
}

# initialize Locator (for error messages)
sub set_document_locator {
  my $self = shift;
  $self->{locator} = shift;
}

sub _croak {
  my $self = shift;
  my $msg = shift;
  croak sprintf("%s [Ln: %s, Col: %s]\n",
                $msg,
                $self->{locator}->{LineNumber} || 'N.A.',  # Expat: no set_document_locator()
                $self->{locator}->{ColumnNumber} || 'N.A.', 
               );
}

sub finalize {
  my $self = shift;
  return { params => $self->{params},  tests => $self->{tests} };
}

################################################## Webtest Writer ###
package WebTestWriter;
use strict;
use XML::Writer;
use IO::Scalar;
use Carp qw(croak carp);

sub new {
  my $class = shift;
  my $opt = shift;
  my $self = {};
  $self->{deparse} = 0 if $opt->{nocode};
  $self->{buffer} = '';
  my $out = new IO::Scalar(\$self->{buffer});
  $self->{xh} = new XML::Writer(OUTPUT => $out,
                                DATA_MODE => 1,
                                DATA_INDENT => 2
                               );
  return bless $self;
}

# as_xml: writes out test definitions and parameters as XML
# plain hash {key, val} is output as <param name="key">val</param>
# list ref: <list name="key"><param .../></list>
# anonymous params/lists lack name attribute
sub as_xml {
  my $self = shift;
  my ($tests, $params) = @_;
  $self->{xh}->xmlDecl();
  $self->{xh}->startTag('WebTest', version => $webtest_definition_version);
  $self->_serialize('params', $params);
  foreach my $test (@$tests) {
    $self->_serialize('test', $test);
  }
  $self->{xh}->endTag('WebTest');
  $self->{xh}->end();
  return $self->{buffer};
}

# take a hash ref and serialize to xml in element $elt
sub _serialize {
  my $self = shift;
  my ($elt, $ref)  = @_;
  $self->{xh}->startTag($elt);
  # sort hash to get more predictable output
  foreach my $key (sort keys %$ref) {
    my $val = $ref->{$key};
    if ((ref $val) && (ref $val eq 'ARRAY')) {     # list ref
      $self->_list($key, $val);
    } elsif ((ref $val) && (ref $val eq 'HASH')) { # only from parsed wtscipt
      $self->_hlist($key, $val);
    } else {
      $self->_param($key, $val);
    } 
  }
  $self->{xh}->endTag($elt);
}
 
# lists can be nested
sub _list {
  my $self = shift;
  my ($key, $val) = @_;
  if (defined $key) {
    $self->{xh}->startTag('list', name => $key); # named list
  } else {
    $self->{xh}->startTag('list');               # anon list
  }
  foreach my $elt (@$val) {
    if ((ref $elt) && (ref $elt eq 'ARRAY')) {
      $self->_list(undef, $elt);                 # nested anon list; recurse
    } else {
      # At this stage we don't know the difference
      # between a flattened hash or a list of scalar elements.
      # The latter is more safe (odd element count)...
      $self->_param(undef, $elt);                # anon param
    }
  }
  $self->{xh}->endTag('list');
}
 
# hash list; can contain list
sub _hlist {
  my $self = shift;
  my ($key, $val) = @_;
  if (defined $key) {
    $self->{xh}->startTag('list', name => $key); # named list
  } else {
    $self->{xh}->startTag('list');               # anon list
  }
  # sort hash to get more predictable output
  foreach my $lkey (sort keys %$val) {
    my $lval = $val->{$lkey};
    if ((ref $lval) && (ref $lval eq 'ARRAY')) {
      $self->_list($lkey, $lval);
    } else {
      $self->_param($lkey, $lval);
    }
  }
  $self->{xh}->endTag('list');
}

# params contain scalar data or code ref, no recursion
sub _param {
  my $self = shift;
  my ($key, $val) = @_;
  my $tag = 'param';
  if ($val && (ref $val eq 'CODE')) {
    $tag = 'code';
    if (! defined $self->{deparse}) {
      eval { 
        local $SIG{__DIE__};
        require B::Deparse; # as of Perl 5.6
        my $vers = $B::Deparse::VERSION || 0;
        die "B::Deparse 0.60 or newer needed, installed version is $vers" if ($vers < 0.60);
      };
      if ($@) {
        carp($@ . "Couldn't load B::Deparse, CODE blocks will be skipped");
        $self->{deparse} = 0;
      } else {
        $self->{deparse} = new B::Deparse; # initialize deparser
      }
    }
    $val = ($self->{deparse}) ? $self->{deparse}->coderef2text($val)
                              : "sub { 'CODE N.A.' }";
  }
  if (defined $key) {
    $self->{xh}->startTag($tag, name => $key); # named param
  } else {
    $self->{xh}->startTag($tag);               # anon param
  }
  $self->{xh}->characters($val || '');
  $self->{xh}->endTag($tag);
}


1;
__END__
