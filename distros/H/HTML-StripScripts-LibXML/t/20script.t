
use strict;
BEGIN { $^W = 1 }

use Test::More tests => 2;
use HTML::StripScripts::LibXML;

my $filt = HTML::StripScripts::LibXML->new( { Context => 'Document' } );

is( $filt->filter_html(<<IN)->toString, <<OUT, 'scripts handled correctly' );
<html>
 <head>
  <title>script test page</title>
 </head>
 <body>
  foo
 </body>
</html>
IN
<?xml version="1.0"?>
<html>
 <head>
  <title>script test page</title>
 </head>
 <body>
  foo
 </body>
</html>


OUT

is( $filt->filter_html(<<IN)->toString, <<OUT, 'scripts handled correctly' );
<html>
 <head>
  <title>script test page</title>
  <script>
     this.is.javascript.and("<this> isn't a tag.  Nor is <b>");
  </script>
  <script>
   <!--
     // script in comments
     foo.foo
   -->
  </script>
 </head>
 <body>
  foo<!--filtered--><!--filtered-->
  <b>baz</b>
 </body>
</html>
IN
<?xml version="1.0"?>
<html>
 <head>
  <title>script test page</title>
  <!--filtered--><!--filtered-->
  <!--filtered--><!--filtered-->
 </head>
 <body>
  foo<!--filtered--><!--filtered-->
  <b>baz</b>
 </body>
</html>


OUT

