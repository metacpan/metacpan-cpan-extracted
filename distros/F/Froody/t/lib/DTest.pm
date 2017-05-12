package DTest;
use strict;
use warnings;

use base 'Froody::API::XML';

1;


sub xml {
<<'XML';
<spec><methods>
<method name='foo.test.sloooow' needslogin='0' />

<method name="foo.test.add" needslogin="0">
  <description>Add</description>
  <arguments>
    <argument name="values" type="csv" optional="1" />
  </arguments>
  <response>
    <value>1</value>
  </response>
  <errors/>
</method>

<method name="foo.test.getGroups" needslogin="0">
  <description>getGroups</description>
  <arguments/>
  <response>
    <value>1</value>
  </response>
  <errors/>
</method>

<method name="foo.test.echo" needslogin="0">
  <description>getGroups</description>
  <arguments>
    <argument name="echo" />
  </arguments>
  <response>
    <value>1</value>
  </response>
  <errors/>
</method>

<method name="foo.test.thunktest" needslogin="0">
  <description>thunktest</description>
  <arguments> 
    <argument name="foo" optional="1" />
  </arguments>
  <response>
    <value>1</value>
  </response>
  <errors/>
</method>

<method name="foo.test.empty" needslogin="0">
</method>

<method name="foo.test.haltandcatchfire" needslogin="0">
  <errors>
    <error code="test.error"/>
  </errors>
</method>

<method name="foo.test.badhandler" needslogin="0">
  <errors>
    <error code="test.error"/>
  </errors>
</method>

<method name="foo.test.badspec" needslogin="0">
  <response>
    <foo><bar /></foo>
  </response>
</method>

</methods>
<errortypes>
  <errortype code="test.error">
    <fire>
      Bad
    </fire>
    <napster>
      good
    </napster>
  </errortype>
</errortypes>
</spec>
XML
}
