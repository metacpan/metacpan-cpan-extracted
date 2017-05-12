# NATools - Package with parallel corpora tools
# Copyright (C) 2002-2012  Alberto Simões
#
# This package is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

package Lingua::NATools::CGI;

our $VERSION = '0.7.10';

use 5.006;
use strict;
use warnings;
use CGI qw/:standard/;
use locale;


sub my_header {

  my %args = @_;

  my $JSCRIPT = $args{jscript} || undef;

  my $CSS = <<EOCSS;
 a.link {
   color: #000000;
   text-decoration: none;
 }
 a.link:hover {
   text-decoration: underline;
 }
 form.main {
   text-align: center;
   background-color: #ffffdd;
   border-bottom: solid 1px #000000;
   padding: 3px;
   margin: 0px;
 }
 input {
   border: solid 1px #000000;
 }
 input[type=submit] {
   background-color: #eeeeee;
 }
 input[type=submit]:hover {
   border: solid 1px #ff7700;
   color: #ff0000;
   background-color: #ffff88;
 }
 input[type=text] {
   padding-left: 3px;
   padding-right: 3px;
 }
 th {
   background-color: #ffeedd;
   color: #ff7700;
   padding: 2px;
   border-top: solid 1px #ff7700;
   border-bottom: solid 1px #ff7700;
   border-right: solid 1px #ff7700;
 }
 th.first {
   background-color: #ffeedd;
   color: #ff7700;
   padding: 2px;
   border: solid 1px #ff7700;
 }
 table.results {
   border-left: dotted 1px #999999;
   margin-left: 5%;
   margin-right: 5%;
   width: 90%;
   padding: 0px;
 }
 td.entry1 {
   border-right: dotted 1px #999999;
   padding: 3px;
   background-color: #ffffff;
   border-bottom: dotted 1px #999999;
 }
 td.entry2 {
   border-right: dotted 1px #999999;
   padding: 3px;
   background-color: #ffffee;
   border-bottom: dotted 1px #999999;
 }
 h1 {
   border-bottom: solid 1px #000000;
   margin: 0px;
   padding: 3px;
   padding-top: 5px;
   background-color: wheat;
   text-align: center;
   font-size: 140%;
   color: #990000;
 }
 address {
   margin-right: 4px;
   font-size: 80%;
   color #999999;
   text-align: right;
   padding-top: 3px;
 }
 span.searched {
   font-weight: bold;
   color: #0000AA;
 }
 span.guessed30 {
   font-weight: bold;
   color: #AA0000;
 }
 span.guessed60 {
	font-weight: bold;
	color: #555500;
 }
 span.guessed100 {
	font-weight: bold;
	color: #008800;
 }
 div.hlpbt {
   float: right;
   border: solid 1px #000000;
   color: #000000;
   background-color: #eeeeee;
   padding: 2px;
   padding-left: 12px;
   padding-right: 12px;
   margin: 4px;
 }
 div.hlpbt:hover {
   float: right;
   border: solid 1px #ff7700;
   color: #ff0000;
   background-color: #ffff88;
   cursor: default;
 }
 body {
   margin: 0px;
 }
EOCSS

  my %conf = (
	      -title => "NATools Corpora Query Interface",
	      -style => {-verbatim => $CSS }
	     );
  $conf{-script} = $JSCRIPT if $JSCRIPT;

  return header(-charset=>'utf-8'),start_html(%conf);
}

sub close_window {
  return <<"EOT";
 <div class="hlpbt" onClick="window.close();">Close</div><br/>
EOT
}

sub my_footer {
  return address("&copy;2005-2014 NATools"),end_html;
}


1;
__END__

=head1 NAME

Lingua::NATools::CGI - Utility functions for NATools CGI tools

=head1 SYNOPSIS

  use Lingua::NATools::CGI;

  print Lingua::NATools::CGI::my_header;

	print Lingua::NATools::CGI::close_window;

  print Lingua::NATools::CGI::my_footer;

=head1 DESCRIPTION

This module is used by all NATools CGIs to create standard headers and
footers on all webpages. It includes other utility methods.

=head2 C<my_header>

Returns the HTML header for a standard NATools CGI file.

=head2 C<my_footer>

Returns the HTML header for a standard NATools CGI file.

=head2 C<close_window>

Returns an HTML button with JavaScript to close a browser window.

=head1 SEE ALSO

See perl(1) and NATools documentation.

=head1 AUTHOR

Alberto Manuel Brandao Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by Natura Project
http://natura.di.uminho.pt

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut
