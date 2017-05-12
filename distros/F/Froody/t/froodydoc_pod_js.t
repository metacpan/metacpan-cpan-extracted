#!/usr/bin/perl -w

#########################################################################
# This tests loads an xml based API (Testobject::API) and makes sure that 
# the right things are set up in the repository
#########################################################################

use strict;
use warnings;
use Test::More;
use Test::Differences;
use FindBin qw/$Bin/;
use File::Spec::Functions 'catfile';

eval { require JavaScript::Standalone };
plan skip_all => "froodydoc.js needs JavaScript::Standalone" if $@; 

plan tests => 1;

my $bin_script = catfile($Bin, qw/.. bin froodydoc.js/);

# ./lib needs to be in the inc path - FOR THE $bin_script process. so set $ENV{PERL5LIB}
$ENV{PERL5LIB} = join(":", $ENV{PERL5LIB}||'', catfile($Bin, qw/.. lib/) );

open POD, "$bin_script Froody::API::Reflection|" or die "Unable to open froodydoc.js pipe for reading: $!";

{ local $/;
eq_or_diff <POD>, <DATA>, "Pod matches";
}

__DATA__
=head1 NAME

Froody::API::Reflection

=head1 METHODS

=head2 froody.reflection.getMethodInfo

Returns information for a given froody API method. As long as there is a method matching the given method_name, returns description and usage of that method in xml. 

=head3 Arguments

=over

=item method_name

The name of the method to fetch information for.

=back

=head3 Response


  <response>
    <method name="froody.fakeMethod" needslogin="1">
      <description>A fake method</description>
      <response>xml-response-example</response>
      <arguments>
        <argument name="color" optional="1" type="scalar">Your favorite color.</argument>
        <argument name="fleece" optional="0" type="csv">Your happy fun clothing of choice.</argument>
      </arguments>
      <errors>
        <error code="1" message="it would be bad">Don't cross the streams.</error>
        <error code="1" message="it would be bad">Don't cross the streams.</error>
      </errors>
    </method>
  </response>

=head3 Errors

=over

=item froody.error.notfound.method - Method not found

The requested method was not found.

=back

=head2 froody.reflection.getMethods

Returns a list of available froody API methods.

=head3 Arguments

None.

=head3 Response


  <response>
    <methods>
      <method>froody.reflection.getMethods</method>
      <method>froody.reflection.getMethodInfo</method>
      <method>bar.baz.blargle</method>
      <method>heartofgold.towel.location</method>
    </methods>
  </response>

=head2 froody.reflection.getErrorTypes

Returns a list of all available froody error types for this repository.

=head3 Arguments

None.

=head3 Response


  <response>
    <errortypes>
      <errortype>froody.error</errortype>
      <errortype>froody.error.blog</errortype>
    </errortypes>
  </response>

=head2 froody.reflection.getErrorTypeInfo

Request information about an Error Type

=head3 Arguments

=over

=item code

The code of the error type whose information is being requested.

=back

=head3 Response


  <response>
    <errortype code="mycode">Internal structure of your error type goes here (including XML)</errortype>
  </response>

=head3 Errors

=over

=item froody.error.notfound.errortype - Error Type not Found

=back

=head2 froody.reflection.getSpecification

Request the full public specification for a froody endpoint.

=head3 Arguments

None.

=head3 Response


  <response>
    <spec>
      <methods>
        <method name="froody.fakeMethod" needslogin="1">
          <description>A fake method</description>
          <response>xml-response-example</response>
          <arguments>
            <argument name="color" optional="1" type="scalar">Your favorite color.</argument>
            <argument name="fleece" optional="0" type="csv">Your happy fun clothing of choice.</argument>
          </arguments>
          <errors>
            <error code="1" message="it would be bad">Don't cross the streams.</error>
            <error code="1" message="it would be bad">Don't cross the streams.</error>
          </errors>
        </method>
        <method name="froody.fakeMethod" needslogin="1">
          <description>A fake method</description>
          <response>xml-response-example</response>
          <arguments>
            <argument name="color" optional="1" type="scalar">Your favorite color.</argument>
            <argument name="fleece" optional="0" type="csv">Your happy fun clothing of choice.</argument>
          </arguments>
          <errors>
            <error code="1" message="it would be bad">Don't cross the streams.</error>
            <error code="1" message="it would be bad">Don't cross the streams.</error>
          </errors>
        </method>
      </methods>
      <errortypes>
        <errortype code="mycode">Internal structure of your error type goes here (including XML)</errortype>
        <errortype code="mycode">Internal structure of your error type goes here (including XML)</errortype>
      </errortypes>
    </spec>
  </response>

