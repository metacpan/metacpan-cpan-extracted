package Testproject::API;
use base 'Froody::API::XML';

1;
sub xml {
<<'XML';
<spec>
  <methods>
    <method name='testproject.object.text' needslogin='0' />

    <method name='testproject.object.get' needslogin='0'>
      <response><get>blah</get></response>
    </method>

    <method name='testproject.object.method' needslogin='0' />
    
    <method name='testproject.object.email' needslogin='0'>
      <arguments>
        <argument name="email_trim" optional="1" type="trim,email" />
        <argument name="email" optional="1" type="email" />
      </arguments>
    </method>
    
    <method name='testproject.object.sum' needslogin='0'>
      <arguments>
        <argument name="values" optional="0" type="csv,number">values to sum</argument>
      </arguments>
      <response>
        <sum>100</sum>
      </response>
    </method>
    <method name='testproject.object.session_test' needslogin='0'>
      <response>
        <session>session_id</session>
      </response>
    </method>
    
    <method name='testproject.object.range' needslogin='0'>
      <arguments>
        <argument name="base" optional="0">base value</argument>
        <argument name="offset" optional="0">offset</argument>
      </arguments>
      <response>
        <range>
          <value>80</value>
          <value>100</value>
        </range>
      </response>
    </method>
    
    <method name='testproject.object.range2' needslogin='0'>
      <arguments>
        <argument name="base" optional="0">base value</argument>
        <argument name="offset" optional="0">offset</argument>
      </arguments>
      <response>
        <range>
          <value num='80' />
          <value num='100' />
        </range>
      </response>
    </method>
    
    <method name='testproject.object.extra' needslogin='0'>
      <response>
        <range>
          <value num='80' />
          <value num='100' />
        </range>
      </response>
    </method>
    
    <method name='testproject.object.texttest' needslogin='0'>
      <response>
        <ranges>
          <next>100</next>
          <blah>foo</blah>
        </ranges>
      </response>
    </method>

    <method name='testproject.object.params' needslogin='0'>
      <arguments>
        <argument name="this_one" optional="1" />
        <argument name="the_rest" type="remaining" />
      </arguments>
      <response>
        <count>4</count>
      </response>
    </method>
    
    <method name='testproject.object.upload' needslogin='0'>
      <arguments>
        <argument name="file" type="multipart" />
      </arguments>
      <response>
        <filesize>23423</filesize>
      </response>
    </method>
    
    
  </methods>

  <errortypes>

    <errortype code="foo.fish">
      <foo>wibble</foo>
    </errortype>

    <errortype code="foo.fish.fred">
      <foo>wibble</foo>
      <bars>
         <bar>cheers</bar>
         <bar>moe's tavern</bar>
      </bars>
    </errortype>

  </errortypes>

</spec>
XML
}
