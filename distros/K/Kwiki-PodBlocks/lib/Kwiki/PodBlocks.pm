package Kwiki::PodBlocks;
use Kwiki::Plugin -Base;
use Kwiki::Installer -base;
our $VERSION = '0.11';

const class_id => 'pod_blocks';
const css_file => 'pod_blocks.css';

sub register {
    my $registry = shift;
    $registry->add(wafl => pod => 'Kwiki::PodBlocks::Wafl');
}

package Kwiki::PodBlocks::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    return join '',
      qq{<div class="pod_blocks">\n},
      $self->pod2html($self->units->[0]),
      qq{</div>\n};
}

sub pod2html {
    require Pod::Simple::HTML;
    my $source = shift;
    my $result;
    my $parser = Pod::Simple::HTML->new;
    $parser->output_string(\$result); 
    eval {
        $parser->parse_string_document($source);
    };
    $result = $source if $@;
    $result =~ s/.*<body.*?>(.*)<\/body>.*/$1/s;
    return $result;
}

package Kwiki::PodBlocks;
__DATA__

=head1 NAME 

Kwiki::PodBlocks - Kwiki Pod Blocks Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/pod_blocks.css__
/*
BODY, .logo { background: white; }

BODY {
  color: black;
  font-family: arial,sans-serif;
  margin: 0;
  padding: 1ex;
}
*/

div.pod_blocks TABLE {
  border-collapse: collapse;
  border-spacing: 0;
  border-width: 0;
  color: inherit;
}

div.pod_blocks IMG { border: 0; }
div.pod_blocks FORM { margin: 0; }
div.pod_blocks input { margin: 2px; }

div.pod_blocks .logo {
  float: left;
  width: 264px;
  height: 77px;
}

div.pod_blocks .front .logo  {
  float: none;
  display:block;
}

div.pod_blocks .front .searchbox  {
  margin: 2ex auto;
  text-align: center;
}

div.pod_blocks .front .menubar {
  text-align: center;
}

div.pod_blocks .menubar {
  background: #006699;
  margin: 1ex 0;
  padding: 1px;
} 

div.pod_blocks .menubar A {
  padding: 0.8ex;
  font: bold 10pt Arial,Helvetica,sans-serif;
}

div.pod_blocks .menubar A:link, .menubar A:visited {
  color: white;
  text-decoration: none;
}

div.pod_blocks .menubar A:hover {
  color: #ff6600;
  text-decoration: underline;
}

div.pod_blocks A:link, A:visited {
  background: transparent;
  color: #006699;
}

div.pod_blocks A[href="#POD_ERRORS"] {
  background: transparent;
  color: #FF0000;
}

div.pod_blocks TD {
  margin: 0;
  padding: 0;
}

div.pod_blocks DIV {
  border-width: 0;
}

div.pod_blocks DT {
  margin-top: 1em;
}

div.pod_blocks .credits TD {
  padding: 0.5ex 2ex;
}

div.pod_blocks .huge {
  font-size: 32pt;
}

div.pod_blocks .s {
  background: #dddddd;
  color: inherit;
}

div.pod_blocks .s TD, .r TD {
  padding: 0.2ex 1ex;
  vertical-align: baseline;
}

div.pod_blocks TH {
  background: #bbbbbb;
  color: inherit;
  padding: 0.4ex 1ex;
  text-align: left;
}

div.pod_blocks TH A:link, TH A:visited {
  background: transparent;
  color: black;
}

div.pod_blocks .box {
  border: 1px solid #006699;
  margin: 1ex 0;
  padding: 0;
}

div.pod_blocks .distfiles TD {
  padding: 0 2ex 0 0;
  vertical-align: baseline;
}

div.pod_blocks .manifest TD {
  padding: 0 1ex;
  vertical-align: top;
}

div.pod_blocks .l1 {
  font-weight: bold;
}

div.pod_blocks .l2 {
  font-weight: normal;
}

div.pod_blocks .t1, .t2, .t3, .t4  {
  background: #006699;
  color: white;
}
div.pod_blocks .t4 {
  padding: 0.2ex 0.4ex;
}
div.pod_blocks .t1, .t2, .t3  {
  padding: 0.5ex 1ex;
}

/* IE does not support  .box>.t1  Grrr */
div.pod_blocks .box .t1, .box .t2, .box .t3 {
  margin: 0;
}

div.pod_blocks .t1 {
  font-size: 1.4em;
  font-weight: bold;
  text-align: center;
}

div.pod_blocks .t2 {
  font-size: 1.0em;
  font-weight: bold;
  text-align: left;
}

div.pod_blocks .t3 {
  font-size: 1.0em;
  font-weight: normal;
  text-align: left;
}

/* width: 100%; border: 0.1px solid #FFFFFF; */ /* NN4 hack */

div.pod_blocks .datecell {
  text-align: center;
  width: 17em;
}

div.pod_blocks .cell {
  padding: 0.2ex 1ex;
  text-align: left;
}

div.pod_blocks .label {
  background: #aaaaaa;
  color: black;
  font-weight: bold;
  padding: 0.2ex 1ex;
  text-align: right;
  white-space: nowrap;
  vertical-align: baseline;
}

div.pod_blocks .categories {
  border-bottom: 3px double #006699;
  margin-bottom: 1ex;
  padding-bottom: 1ex;
}

div.pod_blocks .categories TABLE {
  margin: auto;
}

div.pod_blocks .categories TD {
  padding: 0.5ex 1ex;
  vertical-align: baseline;
}

div.pod_blocks .path A {
  background: transparent;
  color: #006699;
  font-weight: bold;
}

div.pod_blocks .pages {
  background: #dddddd;
  color: #006699;
  padding: 0.2ex 0.4ex;
}

div.pod_blocks .path {
  background: #dddddd;
  border-bottom: 1px solid #006699;
  color: #006699;
 /*  font-size: 1.4em;*/
  margin: 1ex 0;
  padding: 0.5ex 1ex;
}

div.pod_blocks .menubar TD {
  background: #006699;
  color: white;
}

div.pod_blocks .menubar {
  background: #006699;
  color: white;
  margin: 1ex 0;
  padding: 1px;
}

div.pod_blocks .menubar .links     {
  background: transparent;
  color: white;
  padding: 0.2ex;
  text-align: left;
}

div.pod_blocks .menubar .searchbar {
  background: black;
  color: black;
  margin: 0px;
  padding: 2px;
  text-align: right;
}

div.pod_blocks A.m:link, A.m:visited {
  background: #006699;
  color: white;
  font: bold 10pt Arial,Helvetica,sans-serif;
  text-decoration: none;
}

div.pod_blocks A.o:link, A.o:visited {
  background: #006699;
  color: #ccffcc;
  font: bold 10pt Arial,Helvetica,sans-serif;
  text-decoration: none;
}

div.pod_blocks A.o:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}

div.pod_blocks A.m:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}

div.pod_blocks table.dlsip     {
  background: #dddddd;
  border: 0.4ex solid #dddddd;
}

div.pod_blocks PRE     {
  background: #eeeeee;
  border: 1px solid #888888;
  color: black;
  padding: 1em;
  white-space: pre;
}

div.pod_blocks H1      {
  background: transparent;
  color: #006699;
  font-size: large;
}

div.pod_blocks H2      {
  background: transparent;
  color: #006699;
  font-size: medium;
}

div.pod_blocks IMG     {
  vertical-align: top;
}

div.pod_blocks .toc A  {
  text-decoration: none;
}

div.pod_blocks .toc LI {
  line-height: 1.2em;
  list-style-type: none;
}

div.pod_blocks .faq DT {
  font-size: 1.4em;
  font-weight: bold;
}

div.pod_blocks .chmenu {
  background: black;
  color: red;
  font: bold 1.1em Arial,Helvetica,sans-serif;
  margin: 1ex auto;
  padding: 0.5ex;
}

div.pod_blocks .chmenu TD {
  padding: 0.2ex 1ex;
}

div.pod_blocks .chmenu A:link, .chmenu A:visited  {
  background: transparent;
  color: white;
  text-decoration: none;
}

div.pod_blocks .chmenu A:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}

div.pod_blocks .column {
  padding: 0.5ex 1ex;
  vertical-align: top;
}

div.pod_blocks .datebar {
  margin: auto;
  width: 14em;
}

div.pod_blocks .date {
  background: transparent;
  color: #008000;
}
