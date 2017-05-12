#!/usr/bin/perl

use warnings;
use strict;

=head1 SIMPLE TIME SERVER DEMO

This module bundles everything that you might need in order to implement
a Froody service.

=head1 THE API

To start with, we provide an API definition in L<Time::API>.  We have to provide
an XML description of the publicly facing methods for our service.  In this case, our
API methods are:

  froody.demo.hostname
  froody.demo.localtime
  froody.demo.uptime

=cut

package Time::API;

use base qw{
  Froody::API::XML
};

sub xml {
  return << 'XML';
<spec>
  <!-- Our very simple time server -->
  <methods>
    <method name="froody.demo.localtime">
      <description>Tell the time using localtime</description>
      <arguments>
        <argument name="time" optional="1">You may provide the actual time in seconds from the epoch
        </argument>
      </arguments>
      <response>
        <time now="Thu Sep 22 15:49:13 2005">
          <dow>3</dow>
          <doy></doy>
          <month>8</month>
          <day>22</day>
          <hour>15</hour>
          <minute>49</minute>
          <second>13</second>
          <year>2005</year>
          <daylight>1</daylight>
        </time>
      </response>
    </method>
    <method name="froody.demo.uptime">
      <description>Reports the system uptime, if possible.</description>
      <arguments>
      </arguments>
      <response>
        <uptime>
         Random stuff goes here. 
        </uptime>
      </response>
    </method>
    <method name="froody.demo.hostname">
      <description>Reports the system's host name.</description>
      <arguments>
      </arguments>
      <response>
        <hostname>
          heartofgold
        </hostname>
      </response>
    </method>
  </methods>
</spec>
XML
}

package Time::Implementation;

use Sys::Hostname;

use base qw{
  Froody::Plugin
  Froody::Implementation;
};

=head1 THE IMPLEMENTATION

We implement all the methods in the froody.demo namespace, as defined with Time::API

As per the documentation in L<Froody::Quickstart>, you can see that for simple
values, we can just return a scalar, which will be magicly placed inside the top
level node of our response. More complex structures require returning a C<HASHREF>
populated with the secondary elements and attributes of the top level XML node.

=cut

sub implements { 'Time::API' => 'froody.demo.*' }

sub localtime {
  my $invoker = shift;
  my $args    = shift;

  my $time = defined $args->{'time'} ? $args->{'time'} : time;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
  return {
    now => scalar(CORE::localtime($time)),
    second => $sec,
    minute => $min,
    hour => $hour,
    day => $mday,
    month => $mon,
    year => $year,
    dow => $wday,
    doy => $yday,
    daylight => $isdst,
  }
}

sub uptime {
  `uptime` || "I don't know.  Use a unix box, or remember when you turned it on.";
}

# Please note that nothing needed to be done to implement hostname - it was exported
# directly into the Time::Implementation namespace, and its return value can be used by
# froody directly.

package main;

use Froody::Server::Standalone;

use Froody::Plugin;

use Froody::Implementation;

# Mess with the include path because we have everything in the same file.

$INC{'Time/Implementation.pm'} = 'Time.pm'; #Normally, we would 'use Time::Implementation'
$INC{'Time/API.pm'} = 'Time.pm';  #Normally, this would be pulled in automaticly by using 
                                  #Time::Implementation.

=head1 

After we've loaded the implementation, we can start the standalone server.  The current
implementation of the standalone server will walk @INC to discover all L<Froody::Implementation>
subclasses, and register all required implementations.

Once the server has started, you can test the functionality of the server by using the
froody script to connect to the server:

  froody -u'http://localhost:4242/' froody.demo.localtime

to get the current time.

=cut

my $server = Froody::Server::Standalone->new;
$server->port(4242);
$server->run();

1;
