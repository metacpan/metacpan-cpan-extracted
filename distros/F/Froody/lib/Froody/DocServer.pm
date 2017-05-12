=head1 NAME

Froody::DocServer

=head1 DESCRIPTION

Froody::DocServer

=head2 Methods

=over

=cut

package Froody::DocServer;
use warnings;
use strict;
use base qw( Froody::Server );
use Encode;
use Template;

eval q{ use Apache::Constants qw( OK ); };

=item template()

returns a TT template for displaying the methods in

=cut

my $template;
{ local $/; $template ||= <DATA>; }
sub template {
  return $template;
}

=item get_methods()

If you want your own DocServer, override this to return a list of methods
to display the docs for. By default, this will return the methods of the
default repository.

=cut

sub get_methods {
  use Froody::Dispatch;
  my @methods = grep { $_->full_name !~ /^froody\./ }
                Froody::Dispatch->new->repository->get_methods;
}

=item html()

returns the HTML version fo the docs, suitable for sending to the user

=cut

my $tt = Template->new();
sub html {
  my $class = shift;
  my @methods = $class->get_methods;
  my $output;
  $tt->process( \$template, { methods => \@methods }, \$output ) or die $tt->error;
  return $output;
}

sub handler : method {
  my ($class, $r) = @_;
  $r->send_http_header("text/html; encoding=utf-8");
  $r->print( Encode::encode_utf8($class->html) );
  return OK();
}

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

L<Froody>, L<Froody::Request>

=cut

1;

__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
<html>
<!-- this document is auto-generated. Do not edit. -->
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<title>Froody Server Documentation</title>
<style>
    body {
      font-family: Verdana, Arial, Helvetica, sans-serif;
      background-color: #FFFFFF;
      margin: 10px;
      padding: 0;
    }
    
    p, td, th, div, li {
      font-family: Verdana, Arial, Helvetica, sans-serif;
      font-size: 11px;
      line-height: normal;
      text-decoration: none;
      color: #000000;
      margin: 0;
      padding: 0;
    }
    
    p, pre, ul {
      margin-left: 20px;
      margin-bottom: 10px;
    }
    
    h1, h2, h3 {
      font-family: Verdana, Arial, Helvetica, sans-serif;
      line-height: normal;
      font-weight: bold;
    }
    
    h1 {
      color: #ED252A;
    }
    
    h2 {
      border-top: 1px solid black;
      color: #000000;
    }
    
    h3 {
      border-top: 1px dashed black;
      color: #ED252A;
    }
    
    
    a {
        text-decoration: none;
        font-weight: bold;
        color: #666666; }
    
    a:hover {
        text-decoration: underline;
        font-weight: bold;
        color: #ED252A; }
    
    
    table {
      border: 1px solid black;
    }
    td,th {
      padding: 3px 10px 3px 10px;
      text-align: left;
    }
    th {
      border-bottom: 1px solid black;
      background-color: #cccccc;
    }
    /* alternating table rows */
    .odd  { background-color: #eeeeee }
    .even { background-color: #dddddd }
</style>
</head>
<body>

<h2>Methods</h2>
<ul>
[% FOR method IN methods.sort('full_name') %]
<li><a href="#[% method.full_name %]">[% method.full_name %]</a>
[% END %]
</ul>

<h2>Method specifications</h2>

[% FOR method IN methods.sort('full_name') %]

  <h3><a name="[% method.full_name %]" href="#[% method.full_name %]">&raquo;</a>
    [% method.full_name %]
  </h3>
  
  <p>[% method.description %]</p>
  
  <h4>Arguments</h4>
  <table cellspacing="0" cellpadding="0" width="600px">
  <tr>
    <th width="90px">name</th>
    <th width="60px">type</ty>
    <th>description</th>
    <th width="80px">required</th>
  </tr>

  [% SET class = 0; SET other_attrib = 0; %]
  [% FOR arg_name IN method.arguments.keys.sort %]
    [% SET arg = method.arguments.$arg_name %]
    [% IF arg %]
      <tr>
      <td valign="top" class="[% class % 2 ? 'odd' : 'even' %]">[% arg_name %]</td>
      <td valign="top" class="[% class % 2 ? 'odd' : 'even' %]">[% arg.type.join(', ') %]</td>
      <td valign="top" class="[% class % 2 ? 'odd' : 'even' %]">[% arg.doc %]</td>
      <td valign="top" class="[% class % 2 ? 'odd' : 'even' %]">[% arg.optional ? "optional" : "required" %]</td>
      </tr>
      [% SET class = class + 1 %]
    [% ELSE %][% SET other_attrib = 1 %][% END %]
  [% END %]
  [% IF other_attrib %]
      <tr>
      <td valign="top" class="[% class % 2 ? 'odd' : 'even' %]" colspan="4"><center><i>remaining arguments are passed to the method directly</i></center></td>
      </tr>
  [% END %]
  </table>
  
  <h4>Example response</h4>
  <pre>
[% ( method.example_response.as_xml.render(1) || 'empty response' ) | html %]
  </pre>

[% END %]

<h2>COPYRIGHT</h2>
<p>This document copyright 2006 Fotango</p>
</body>
</html>
