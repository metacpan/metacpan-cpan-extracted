#!perl

###########################################################################
# This does some fairly high level tests on Method and the associated XML
# parsing code.  We create some XML, feed it to Froody::API::XML and then
# check to see if the Method contains the right stuff
###########################################################################

use strict;
use warnings; 

use Test::More tests => 14;
use Test::Exception;
use Test::Differences;
use Froody::API::XML;
use Froody::Response::XML;
use Froody::Response::Terse;
use Data::Dumper;

use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

sub _spec {
    "<spec><methods>$_[0]</methods></spec>"
}
my $message = <<'END';
<method name="my.test.method" needslogin="1">
  <description>This is a test method</description>
  <arguments>
    <argument name="foo" optional="1">The optional foo argument</argument>
    <argument name="bar" optional="0" type="text">The non-optional bar argument</argument>
    <argument name="baz" type="multipart">This is required, too</argument>
    <argument name="shizzle" type="csv">Arguments are the shizniz</argument>
  </arguments>
  <response>
    <book>
    <spell name="rezrov">
      <target>book</target>
      <target>stove</target>
      <description></description>
    </spell>
    <spell/>
    </book>
  </response>
  <errors>
  </errors>
</method>
END

my ($method) = Froody::API::XML->load_spec(_spec($message));

is($method->full_name, 'my.test.method', 'full name');
is($method->service, 'my', 'service');
is($method->object,'Test', 'object');
is($method->name, 'method', 'name');
is($method->module, 'My::Test', "full module");
is($method->description, 
  'This is a test method',
  'description is correct');

is($method->source, 'unbound: my.test.method', 
  "Source looks right for an unbound method");

my $arguments;

my $actual_arguments = $method->arguments;
is_deeply($method->arguments, $arguments = {
   'bar' => {
            'doc' => 'The non-optional bar argument',
            'optional' => '0',
            'type' => ['text']
          },
   'baz' => {
            'doc' => 'This is required, too',
            'optional' => 0,
            'multiple' => 1,
            'type' => ['multipart']
          },
   'foo' => {
            'doc' => 'The optional foo argument',
            'optional' => '1',
            'type' => ['text']
          },
   'shizzle' => {
                'doc' => 'Arguments are the shizniz',
                'optional' => 0,
                'multiple' => 1,
                'type' => ['csv']
              }
}, "arguments with docs.") or diag Dumper $method->arguments;
  
my $errors;
is_deeply($method->errors, $errors = {
  }, "errors") or diag Dumper $method->errors;

my $structure;
eq_or_diff($method->structure, $structure = +{
   '' => {
           'elts'  => [
                        'book'
                      ],
           'text'  => 0,
           'multi' => 0,
           'attr'  => []
         },
   'book/spell/description' => {
                          'elts' => [],
                          'text' => 1,
                          'attr' => [],
                          multi => 0
                        },
   'book/spell/target' => {
                     'elts' => [],
                     'text' => 1,
                     'multi' => 1,
                     'attr' => []
                   },
   'book/spell' => {
              'elts' => [ 'description', 'target' ],
              'attr' => [ 'name' ],
              'multi' => 1,
              'text' => 0,
            },
   'book' => {
              'elts' => [ 'spell' ],
              'attr' => [ ],
              'multi' => 0,
              'text' => 0,
            },
});

my $example_response = $method->example_response->as_terse->content;
{ local $TODO = "Text nodes of examples aren't flattened as they are with the walker";
eq_or_diff($example_response, {
        spell => [
            {
               'target' => [
                           'book',
                           'stove'
                         ],
               'name' => 'rezrov',
               'description' => ''
            }, 
            {}
        ]});
}

($method) = Froody::API::XML->load_spec(_spec(<<XML));
<method name="text.object.method" needslogin="0">
  <arguments></arguments>
  <description></description>
  <response>
    <value>0</value>
  </response>
  <errors></errors>
</method>
XML

eq_or_diff($method->structure, {
   '' => {
           'elts'  => [
                       'value'
                      ],
           'text'  => 0,
           'multi' => 0,
           'attr'  => []
         },
  value => { elts => [], text => 1, attr => [], multi => 0}
  },
  "When there is a top level element which only has CDATA, we have proper XPath.");
throws_ok {
# XXX: This is as clear as mud.
($method) = Froody::API::XML->load_spec(_spec(<<XML));
<method name="text,method" needslogin="0">
  <arguments></arguments>
  <description></description>
  <response>
    <value>0</value>
  </response>
  <errors></errors>
</method>
XML
} "Froody::Error";

ok Froody::Error::err("perl.methodcall.param"), "method right type";
