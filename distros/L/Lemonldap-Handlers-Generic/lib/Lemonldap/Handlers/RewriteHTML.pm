package Lemonldap::Handlers::RewriteHTML;
use strict;
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.1.0';
our $VERSION_LEMONLDAP = "3.1.0";
our $VERSION_INTERNAL  = "3.1.0";
sub get               
{
    my $class =shift;
    my %_param= @_;
    my $html =$_param{'html'};
    my $https =$_param{'https'} ;
    my $host = $_param{'host'};
    my $target = $_param{'target'};

$html =~ s/http:\/\//http:\/\/$host\//gi;
   # href tag
$html=~ s/href="([^\/h])/href="\/$1/ig;
$html=~ s/(href="\/)/href="\/$target\//ig;
# src tag
$html=~ s/src="([^\/h])/src="\/$1/ig;
$html=~ s/(src="\/)/src="\/$target\//ig;
# action tag
$html=~ s/(action=\/)/action=\/$target\//ig;
# base tag
$html =~ s/(\<base\b(.+?))href[^\s]+/$1/i;  
# feuille de style 
$html =~ s/url\('/url\('\/$target\//gi;  
$html =~ s/url\(/url\(\/$target\//gi;  
$html=~ s/http:/https:/g if $https;
return $html;   
       }
	   1;
=pod

=for html <center> <H1> Lemonldap::Handlers::RewriteHTML </H1></center> 


=head1 NAME

    Lemonldap::Handlers::RewriteHTML  - Plugin  for Lemonldap sso system

=head1 DESCRIPTION

 RewriteHTML is the default rewriter manager  of lemonldap  websso framework .
 This module rewrite on fly html response
 
 see http://lemonldap.sf.net for more infos .

=head2 Overlay

 If you wat use your own rewriter  method you must use REWRITEHTMLPLUGIN parameter like this :
 in httpd.conf : perlsetvar lemonldappluginhtml MyModule 

 Your module must accept  4 parameters : host :(the virtual host actived) ,target (the host target) 
 https (true if https request )  and  html (the source page in html ) 
 Your module must provide the 'get' method  and return a html string. 

=head1 SEE ALSO

Lemonldap(3), Lemonldap::Portal::Standard

http://lemonldap.sourceforge.net/

"Writing Apache Modules with Perl and C" by Lincoln Stein E<amp> Doug
MacEachern - O'REILLY

=over 1

=item Eric German, E<lt>germanlinux@yahoo.frE<gt>

=item Isabelle Serre, E<lt>isabelle.serre@justice.gouv.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Eric German E<amp> Isabelle Serre

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.

=item Portage under Apache2 is made with help of : Ali Pouya and 
Shervin Ahmadi (MINEFI/DGI) 

=back

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; version 2 dated June, 1991.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  A copy of the GNU General Public License is available in the source tree;
  if not, write to the Free Software Foundation, Inc.,
  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

