package Froody;

use strict;
use warnings;

# okay, you got me.  This doesn't really do anything but hold the universal
# VERSION for Froody so you can say "use Froody 42.1" and it'll go bang if it's
# not installed.  Which it will, 'cos we ain't written it yet
our $VERSION = "42.034";

=head1 NAME

Froody - Yet another XML web API framework

=head1 SYNOPSIS

  bash$ lwp-request 'http://127.0.0.1:4242/?method=froody.demo.localtime&time=258244200'
  <?xml version="1.0" encoding="utf-8"?>
  <rsp stat="ok">
	<time now="Wed Mar  8 22:30:00 1978">
	  <day>8</day>
	  <daylight>0</daylight>
	  <dow>3</dow>
	  <doy>66</doy>
	  <hour>22</hour>
	  <minute>30</minute>
	  <month>2</month>
	  <second>0</second>
	  <year>78</year>
	</time>
  </rsp>

See L<Froody::QuickStart> for a better introduction.

=head1 DESCRIPTION

Froody is a framework that can be used to easily create both a server and a
client for making remote API calls across the web.

Froody communicates by the AJAX friendly calling convention of passing
parameters to methods via CGI parameters and returning XML data structures as a
response.  The Froody framework handles all the nastyness of dealing with the
CGI and XML for you, so all you really have to worry about in your Perl code is
actually getting the job done.  In particular, it lets you define a strict spec
for what will be returned simply by example, making new methods quick and easy
to write.

=head2 What Documentation Is There?

First, before you do anything else, you want to read L<Froody::QuickStart>.
This is the basic tutorial which'll get you up and running and give you
and idea of what Froody is all about.

Once you've read that you probably want to read one of the following

=over

=item Froody::API::XML

How to quickly write an XML specification for Froody Methods.

=item Froody::Implementation

What you need to know in order to implement the methods you
specified reading the above.

=item Froody::DataFormats

A quick review of the data formats used by Froody

=item Froody::Server

Setting up a Froody Server

=back

=head1 BUGS

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

This module has been worked on by the following people:

  Stig Brautaset   <stig@brautaset.org>
  Nicholas Clark   <nclark@fotango.com>
  Mark Fowler      <mark@twoshortplanks.com>
  Chia-liang Kao   <clkao@fotango.com>
  Tom Insam        <tinsam@fotango.com>
  Norman Nunley    <nnunley@fotango.com>

You can reach the current maintainers by emailing us at C<cpan@fotango.com>,
but if you're reporting bugs I<please> use the RT system mentioned above so
we can track the issues you report.

=head1 SEE ALSO

The C<examples> directory that ships with this distribution.

=cut

# return true to keep perl happy
'"This must be Thursday," said Arthur to himself, sinking low over his beer, "I never could get the hang of Thursdays."' 
