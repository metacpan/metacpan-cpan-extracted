package Lemonldap::Handlers::Memsession;
use strict;
use Apache::Session::Memorycached;
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.1.0';
our $VERSION_LEMONLDAP = "3.1.0";
our $VERSION_INTERNAL  = "3.1.0";
sub get               
{
    my $class =shift;
    my %_param= @_;
    
    my $id =$_param{'id'};
     return 0 unless $id;;

    my $config =$_param{'config'};

my $SERVERS = $config->{SERVERS};

my %session ;
   tie %session, 'Apache::Session::Memorycached', $id,$SERVERS;
 unless ($session{dn}) {  ##  the cookie is present but i can't  retrieve session
                         ##  three causes : Too many connection are served.              
                         ##                the server of session was restarted                
                         ##                It's time out                 
 
     untie %session ;

# I say it's time out 
                    }
    my %_session = %session;
  untie %session ;
     my $self = \%_session;
    bless $self,$class;
  return $self;
}
1;

=pod

=for html <center> <H1> Lemonldap::Handlers::Memsession </H1></center> 


=head1 NAME

    Lemonldap::Handlers::Memsession  - Plugin  for Lemonldap sso system

=head1 DESCRIPTION

 Memsession is the default session backend manager  of lemonldap  websso framework .
 This module uses memcached  in order to store information.
 
 see http://lemonldap.sf.net for more infos .

=head2 Overlay

If you wat use your own session backend  method you must use SESSIONSTOREPLUGIN parameter like this :
  in httpd.conf : perlsetvar lemonldappluginbackend MyModule 

 Your module must accept  2 parameters : config (all the hash of config ) and id (collect in the cookie )
 Your module must provide the 'get' method  and return a reference on hash of session.

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

