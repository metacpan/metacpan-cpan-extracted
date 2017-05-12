package Froody::API::Reflection;
use strict;
use warnings;

use base "Froody::API::XML";

=head1 NAME

Froody::API::Reflection - the froody reflection api spec

=head1 SYNOPSIS

  use Froody::API::Reflection

=head1 DESCRIPTION

Froody's reflection system allow you to introspect your methods, and access the
API spefication for methods using Froody calls to the Froody server itself.

All repositories support two standard methods which are used for reflection,
C<froody.reflection.getMethodInfo> and C<froody.reflection.getMethods>.  This
class defines the API for those methods.

See Froody::Reflection for more details

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

L<Froody>, L<Froody::Reflection>

=cut

sub xml {
  my $METHOD_INFO = q{
      <method name="froody.fakeMethod" needslogin="1">
        <description>A fake method</description> 
        <response>xml-response-example</response> 
        <arguments>
            <argument name="color" optional="1" type="scalar"> Your favorite color.</argument>
            <argument name="fleece" optional="0" type="csv">Your happy fun clothing of choice.</argument>
        </arguments>
        <errors>
          <error code="1" message="it would be bad">Don't cross the streams.</error>
          <error code="1" message="it would be bad">Don't cross the streams.</error>
        </errors>
      </method>
  };
  my $ERROR_INFO = q{
        <errortype code="mycode">
          Internal structure of your error type goes here (including XML)
        </errortype>
  };
  return <<"XML";
<spec>
<methods>
  <method name="froody.reflection.getMethodInfo">
    <description>Returns information for a given froody API
      method.  As long as there is a method matching the given
      method_name, returns description and usage of that method in
      xml.
    </description>
    <response>
      $METHOD_INFO
    </response>
    <arguments>
      <argument name="method_name" optional="0">The name of the method to fetch information for.</argument>
    </arguments>
    <errors>
      <error code="froody.error.notfound.method" message="Method not found">
        The requested method was not found.
      </error>
    </errors>
  </method>
  <method name="froody.reflection.getMethods">
    <description>Returns a list of available froody API methods.</description>
      <response>
        <methods>
          <method>froody.reflection.getMethods</method>
          <method>froody.reflection.getMethodInfo</method>
          <method>bar.baz.blargle</method>
          <method>heartofgold.towel.location</method>
        </methods>
      </response>
    </method>
    <method name="froody.reflection.getErrorTypes">
      <description>Returns a list of all available froody error types for this repository.</description>
      <response>
        <errortypes>
          <errortype>froody.error</errortype>
          <errortype>froody.error.blog</errortype>
        </errortypes>
      </response>
    </method>
    <method name="froody.reflection.getErrorTypeInfo">
      <description>Request information about an Error Type</description>
      <arguments>
        <argument name="code" optional="0">The code of the error type whose information is being requested.</argument>
      </arguments>
      <response>
        $ERROR_INFO
      </response>
      <errors>
        <error code="froody.error.notfound.errortype" message="Error Type not Found"/>
      </errors>
    </method>
    <method name="froody.reflection.getSpecification">
      <description>Request the full public specification for a froody endpoint.</description>
      <response>
        <spec>
          <methods>
            $METHOD_INFO
            $METHOD_INFO
          </methods>
          <errortypes>
            $ERROR_INFO
            $ERROR_INFO
          </errortypes>
        </spec>
      </response>
    </method>
  </methods>
  <errortypes>
    <errortype code="perl.methodcall.param">
      <error name="foo">Problem</error>
      <error name="bar">Problem</error>
    </errortype>
  </errortypes>
</spec>
XML
}

1;
