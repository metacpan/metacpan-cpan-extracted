#!/usr/bin/perl -w
#-----------------------------------------------------------------
# GenerateRDF.cgi
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: GenerateRDF.cgi,v 1.1 2008/02/21 00:21:27 kawas Exp $
#
# NOTES:
# 	1. This script assumes that a BioMOBY registry is properly
#	   installed and that SetEnv commands have been added to
#      the servers environment (e.g. httpd.conf)
#-----------------------------------------------------------------

use strict;
use CGI qw/:standard/;
use MOBY::RDF::Ontologies::Objects;
use MOBY::RDF::Ontologies::ServiceTypes;
use MOBY::RDF::Ontologies::Namespaces;
use MOBY::RDF::Ontologies::Services;
use MOBY::Client::Central;


my $url = url( -relative => 1, -path_info => 1 );

my $form = new CGI;

my %p = $form->Vars unless param('keywords');
%p = ($form->param('keywords') => '') if param('keywords');

my $service   = $p{'service'} || '';
my $authority = $p{'authority'} || '';

if ($service and $authority) {
	
	my $name = $p{'service'};
	$name =~ s/ //g;
	$name = $p{'authority'} unless $name;
	
	
	print "Content-type: application/rdf+xml\n";
	print "Content-Disposition: attachment; filename=". $name . ".rdf\n";
	print "Content-Description: Service Instance RDF\n\n";
	
	my $x = MOBY::RDF::Ontologies::Services->new;
	# get pretty printed RDF/XML for one service
	print $x->findService({ 
		serviceName => $p{'service'},
		isAlive => 'no',
		authURI => $p{'authority'} 
	});
	
} elsif ($authority and not $service) {
	
	print "Content-type: application/rdf+xml\n";
	print "Content-Disposition: attachment; filename=". $p{'authority'} . ".rdf\n";
	print "Content-Description: Service Instance RDF\n\n";
	
	my $x = MOBY::RDF::Ontologies::Services->new;
	# get unformatted RDF/XML for a bunch of services from a single provider
	print $x->findService({ 
		authURI => $p{'authority'},
		isAlive => 'no' 
	});
} else {
	print "Content-type: text/html\n\n";
	print &GENERATE_FORM();
}


sub GENERATE_FORM {
	
my $values = "";

my $m = MOBY::Client::Central->new();
my @URIs = $m->retrieveServiceProviders();
foreach my $uri (@URIs) {
	next if $uri eq '127.0.0.1';
	$values .= "<option value='$uri'>$uri</option>\n"
}


my $msg =<<EOF;

   <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<head>
<title>Generate RDF</title>
<style type="text/css">
<!--
body { background: #ffffcd;
       color: #000000;
       font-family: Arial, Helvetica, sans-serif;
       font-size: 12pt;
       font-weight: normal;
       margin-top: 110px;
       margin-right: 1em;
       margin-bottom: 1em;
       margin-left: 1em;
       background-position: left top;
       background-repeat: no-repeat;
     }

.indent {
     margin-left: 5em;
   }

td.text { background: #ffffcd;
       color: #000000;
       font-family: Arial, Helvetica, sans-serif;
       font-size: 12pt;
       font-weight: normal;
       margin-top: 110px;
       margin-right: 1em;
       margin-bottom: 1em;
       margin-left: 1em;
     }

h1 { border: solid; 
     text-align:center;
     background-color:yellow;
     color: navy;
   }
h2 { border: ridge;
     padding: 5px;
     background-color:yellow;
     color: navy;
   }
h3 { border: none;
     padding: 5px;
     background-color:yellow;
     color: navy;
   }

.subtitle { border: none;
     padding: 5px;
     background-color:yellow;
     color: navy;
   }

a:link    { color: #0000ff; font-family: Arial, Helvetica, sans-serif; font-weight: normal; text-decoration: underline}
a:visited { color: #0099ff; font-family: Arial, Helvetica, sans-serif; font-weight: normal; text-decoration: underline}
a:active  { color: #0000ff; font-family: Arial, Helvetica, sans-serif; font-weight: normal; text-decoration: underline}
a:hover   { color: #336666; font-family: Arial, Helvetica, sans-serif; font-weight: normal; text-decoration: underline}

li { list-style-type: square;
     margin: 1em;
     list-style-image: url(b_yellow.gif);
   }
li.tiny { list-style-type: square;
          margin: 0;
          list-style-image: none;
        }
li.count { list-style-type: upper-roman;
           list-style-image: none;
           margin: 0;
         }
li.dcount { list-style-type: decimal;
           list-style-image: none;
           margin: 0;
         }

dd { margin-bottom: 0.5em }

.address { font-size: 5pt; margin-right:1em }
.smaller { font-size: 8pt }

.note { font-style: italic;
	padding-left: 5em;
        margin: 1em;
      }

.update {
        background-color:#ccffcd;
      }

pre.code { border: ridge;
     padding: 5px;
     background-color:#FFFF99;
     color: navy;
   }

pre.script {
     padding: 5px;
     background-color: white;
     color: navy;
   }

pre.script2 {
     padding: 5px;
     background-color: white;
     color: navy;
     margin-left: 5em;
   }


pre.sscript {
     padding: 5px;
     background-color: white;
     color: navy;
     font-size: 8pt;
   }
pre.ssscript {
     padding: 5px;
     background-color: white;
     color: navy;
     font-size: 6pt;
   }

tr.options {
     background-color: #FFFF99;
     color: navy;
   }

b.step {
     background-color: white;
     color: navy;     
     font-size: 8pt;
   }
.motto {
     text-align: right;
     font-style: italic;
     font-size: 10pt;
   }
.motto-signature {
     text-align: right;
     font-style: normal;
     font-size: 8pt;
   }

.sb {
     font-weight: bold;
     font-size: 8pt;
}
.sbred {
     font-weight: bold;
     font-size: 8pt;
     color: red;
}
.mail {font-size: medium}
-->
</style>
</head>
<body>
<h1>Generate RDF </h1>
<p>This for can be used to generate RDF for a specific service or a group of services registered by a service provider.</p>
<form name="form1" method="post" action="">
  <label>Choose a service provider
  <select name="authority" id="authority">
  $values
  </select>
  </label>
  <p>
    <label>Enter an optional service name
    <input name="service" type="text" id="service" size="75">
    </label>
  </p>
  <p>
    <label>
    <input type="submit" name="submit" id="submit" value="Generate RDF">
    </label>
  </p>
</form>
<p></p>
<hr>
<div align=right class="address">
  <address>
  <A HREF="mailto:ekawas\@mrl.ubc.ca" class="mail">Edward A Kawas</A><BR>
  </address>
  <!-- hhmts start -->
  <!-- hhmts end -->
</div>
</body>
</html>

EOF

return $msg;
}