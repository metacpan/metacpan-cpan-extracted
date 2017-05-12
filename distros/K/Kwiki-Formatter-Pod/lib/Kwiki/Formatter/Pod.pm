package Kwiki::Formatter::Pod;
use Spoon::Formatter -Base;
use Kwiki::Installer -base;
our $VERSION = '0.11';

const top_class => 'Kwiki::Formatter::Pod::Top';
const class_title => 'Pod Formatter';

package Kwiki::Formatter::Pod::Top;
use base 'Spoon::Formatter::Unit';

sub parse {
    $self->hub->css->add_file('formatter.css');
    return $self;
}

sub to_html {
    require Pod::Simple::HTML;
    my $source = $self->text;
    my $result;
    my $parser = Kwiki::Formatter::Pod::Simple::HTML->new;
    $parser->kwiki_hub($self->hub);
    $parser->output_string(\$result); 
    eval {
        $parser->parse_string_document($source);
    };
    return "<pre>\n$source\n$@\n</pre>\n"
      if $@ or not $result;
    $result =~ s/.*<body.*?>(.*)<\/body>.*/$1/s;
    return qq{<div class="formatter_pod">\n$result</div>};
}

package Kwiki::Formatter::Pod::Simple::HTML;
use base 'Pod::Simple::HTML';
use base 'Kwiki::Base';
use Kwiki ':char_classes';

field 'kwiki_hub';

sub do_link {
    my $token = shift;
    my $link = $token->attr('to');
    return super unless $link =~ /^[$WORD]+$/;
    my $section = $token->attr('section');
    $section = "#$section"
      if defined $section and length $section;
    $self->kwiki_hub->config->script_name . "?$link$section";
}

package Kwiki::Formatter::Pod;
__DATA__

=head1 NAME 

Kwiki::Formatter::Pod - Kwiki Formatter Subclass for Pod

=head1 SYNOPSIS

In C<config.yaml>:

    formatter_class: Kwiki::Formatter::Pod

=head1 DESCRIPTION

Use Pod as your Kwiki formatting language.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/formatter.css__
/*
BODY, .logo { background: white; }

BODY {
  color: black;
  font-family: arial,sans-serif;
  margin: 0;
  padding: 1ex;
}
*/

div.formatter_pod TABLE {
  border-collapse: collapse;
  border-spacing: 0;
  border-width: 0;
  color: inherit;
}

div.formatter_pod IMG { border: 0; }
div.formatter_pod FORM { margin: 0; }
div.formatter_pod input { margin: 2px; }

div.formatter_pod .logo {
  float: left;
  width: 264px;
  height: 77px;
}

div.formatter_pod .front .logo  {
  float: none;
  display:block;
}

div.formatter_pod .front .searchbox  {
  margin: 2ex auto;
  text-align: center;
}

div.formatter_pod .front .menubar {
  text-align: center;
}

div.formatter_pod .menubar {
  background: #006699;
  margin: 1ex 0;
  padding: 1px;
} 

div.formatter_pod .menubar A {
  padding: 0.8ex;
  font: bold 10pt Arial,Helvetica,sans-serif;
}

div.formatter_pod .menubar A:link, .menubar A:visited {
  color: white;
  text-decoration: none;
}

div.formatter_pod .menubar A:hover {
  color: #ff6600;
  text-decoration: underline;
}

div.formatter_pod A:link, A:visited {
  background: transparent;
  color: #006699;
}

div.formatter_pod A[href="#POD_ERRORS"] {
  background: transparent;
  color: #FF0000;
}

div.formatter_pod TD {
  margin: 0;
  padding: 0;
}

div.formatter_pod DIV {
  border-width: 0;
}

div.formatter_pod DT {
  margin-top: 1em;
}

div.formatter_pod .credits TD {
  padding: 0.5ex 2ex;
}

div.formatter_pod .huge {
  font-size: 32pt;
}

div.formatter_pod .s {
  background: #dddddd;
  color: inherit;
}

div.formatter_pod .s TD, .r TD {
  padding: 0.2ex 1ex;
  vertical-align: baseline;
}

div.formatter_pod TH {
  background: #bbbbbb;
  color: inherit;
  padding: 0.4ex 1ex;
  text-align: left;
}

div.formatter_pod TH A:link, TH A:visited {
  background: transparent;
  color: black;
}

div.formatter_pod .box {
  border: 1px solid #006699;
  margin: 1ex 0;
  padding: 0;
}

div.formatter_pod .distfiles TD {
  padding: 0 2ex 0 0;
  vertical-align: baseline;
}

div.formatter_pod .manifest TD {
  padding: 0 1ex;
  vertical-align: top;
}

div.formatter_pod .l1 {
  font-weight: bold;
}

div.formatter_pod .l2 {
  font-weight: normal;
}

div.formatter_pod .t1, .t2, .t3, .t4  {
  background: #006699;
  color: white;
}
div.formatter_pod .t4 {
  padding: 0.2ex 0.4ex;
}
div.formatter_pod .t1, .t2, .t3  {
  padding: 0.5ex 1ex;
}

/* IE does not support  .box>.t1  Grrr */
div.formatter_pod .box .t1, .box .t2, .box .t3 {
  margin: 0;
}

div.formatter_pod .t1 {
  font-size: 1.4em;
  font-weight: bold;
  text-align: center;
}

div.formatter_pod .t2 {
  font-size: 1.0em;
  font-weight: bold;
  text-align: left;
}

div.formatter_pod .t3 {
  font-size: 1.0em;
  font-weight: normal;
  text-align: left;
}

/* width: 100%; border: 0.1px solid #FFFFFF; */ /* NN4 hack */

div.formatter_pod .datecell {
  text-align: center;
  width: 17em;
}

div.formatter_pod .cell {
  padding: 0.2ex 1ex;
  text-align: left;
}

div.formatter_pod .label {
  background: #aaaaaa;
  color: black;
  font-weight: bold;
  padding: 0.2ex 1ex;
  text-align: right;
  white-space: nowrap;
  vertical-align: baseline;
}

div.formatter_pod .categories {
  border-bottom: 3px double #006699;
  margin-bottom: 1ex;
  padding-bottom: 1ex;
}

div.formatter_pod .categories TABLE {
  margin: auto;
}

div.formatter_pod .categories TD {
  padding: 0.5ex 1ex;
  vertical-align: baseline;
}

div.formatter_pod .path A {
  background: transparent;
  color: #006699;
  font-weight: bold;
}

div.formatter_pod .pages {
  background: #dddddd;
  color: #006699;
  padding: 0.2ex 0.4ex;
}

div.formatter_pod .path {
  background: #dddddd;
  border-bottom: 1px solid #006699;
  color: #006699;
 /*  font-size: 1.4em;*/
  margin: 1ex 0;
  padding: 0.5ex 1ex;
}

div.formatter_pod .menubar TD {
  background: #006699;
  color: white;
}

div.formatter_pod .menubar {
  background: #006699;
  color: white;
  margin: 1ex 0;
  padding: 1px;
}

div.formatter_pod .menubar .links     {
  background: transparent;
  color: white;
  padding: 0.2ex;
  text-align: left;
}

div.formatter_pod .menubar .searchbar {
  background: black;
  color: black;
  margin: 0px;
  padding: 2px;
  text-align: right;
}

div.formatter_pod A.m:link, A.m:visited {
  background: #006699;
  color: white;
  font: bold 10pt Arial,Helvetica,sans-serif;
  text-decoration: none;
}

div.formatter_pod A.o:link, A.o:visited {
  background: #006699;
  color: #ccffcc;
  font: bold 10pt Arial,Helvetica,sans-serif;
  text-decoration: none;
}

div.formatter_pod A.o:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}

div.formatter_pod A.m:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}

div.formatter_pod table.dlsip     {
  background: #dddddd;
  border: 0.4ex solid #dddddd;
}

div.formatter_pod PRE     {
  background: #eeeeee;
  border: 1px solid #888888;
  color: black;
  padding: 1em;
  white-space: pre;
}

div.formatter_pod H1      {
  background: transparent;
  color: #006699;
  font-size: large;
}

div.formatter_pod H2      {
  background: transparent;
  color: #006699;
  font-size: medium;
}

div.formatter_pod IMG     {
  vertical-align: top;
}

div.formatter_pod .toc A  {
  text-decoration: none;
}

div.formatter_pod .toc LI {
  line-height: 1.2em;
  list-style-type: none;
}

div.formatter_pod .faq DT {
  font-size: 1.4em;
  font-weight: bold;
}

div.formatter_pod .chmenu {
  background: black;
  color: red;
  font: bold 1.1em Arial,Helvetica,sans-serif;
  margin: 1ex auto;
  padding: 0.5ex;
}

div.formatter_pod .chmenu TD {
  padding: 0.2ex 1ex;
}

div.formatter_pod .chmenu A:link, .chmenu A:visited  {
  background: transparent;
  color: white;
  text-decoration: none;
}

div.formatter_pod .chmenu A:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}

div.formatter_pod .column {
  padding: 0.5ex 1ex;
  vertical-align: top;
}

div.formatter_pod .datebar {
  margin: auto;
  width: 14em;
}

div.formatter_pod .date {
  background: transparent;
  color: #008000;
}
