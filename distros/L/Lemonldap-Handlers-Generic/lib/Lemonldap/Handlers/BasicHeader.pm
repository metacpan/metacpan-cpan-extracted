package Lemonldap::Handlers::BasicHeader;
use strict;
use Crypt::CBC;
use MIME::Base64;
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '2.00';
our $VERSION_LEMONLDAP = "2.0";
our $VERSION_INTERNAL  = "2.0";

sub get {
    my $class  = shift;
    my %_param = @_;
    my $profil = $_param{profil};
    my $dn     = $_param{dn};
   (my $uidu)  = $dn =~ /uid=(.+?),/;   

    my  $cipher = Crypt::CBC->new( -key    => $uidu,
                                   -cipher => 'Blowfish'
                                  );
    my $pac = decode_base64($profil);  
  
    my $plaintext  = $cipher->decrypt($pac);

    my $header = $_param{config}->{SENDHEADER} || 'Authorization';
    my $self;
    my $ligne_h;
    #print STDERR "HEADER_SAS->$plaintext<-\n";
    $ligne_h = $profil;
    $self->{decoded} = "Basic %b64%rumeaul:rumeaul%b64%";
    # $self->{decoded} = "Basic %b64%$plaintext%b64%";
    
    $self->{clair}   = "Basic $pac";
    bless $self, $class;
    return $self;
}

sub forge {
    my $class  = shift;
    my %_param = @_;
    my $line   = $_param{line};
    my $self;
    my $l=$line;
   print STDERR "ERIC BURNE $l\n";
$l =~ s/:.+$/:CLASSIFIED/;
   print STDERR "ERIC BURNES $l\n";
    $self->{decoded} = $l;
    my ($user) = $line =~ /(uid.+?),/;
    $self->{user} = $user;
    my $header = $_param{config}->{SENDHEADER} || 'Authorization';
    return 0 if ( $header eq 'NONE' );

    ( my $b, my $e ) = $line =~ /(.+)%b64%(.+)%b64%/;
    if ($e) {
        $e = encode_base64( $e, '' );
        $line =~ s/%b64%.+%b64%/$e/;
    }
    else {

        # for previous version
        ( my $b, my $e ) = $line =~ /(.+?)\s(.+)/;
        $e = encode_base64( $e, '' );
        $line =~ s/ (.+)$/ $e/;
    }

    $self->{content} = $line;
    $self->{header}  = $header;
    bless $self, $class;
    return $self;
}
1;

=pod

=for html <center> <H1> Lemonldap::Handlers::AuthorizationHeader </H1></center> 


=head1 NAME

    Lemonldap::Handlers::AuthorizationHeader  - Plugin  for Lemonldap sso system

=head1 DESCRIPTION

 AuthorizationHeader is the default header builder  manager  of lemonldap  websso framework .

 
 see http://lemonldap.sf.net for more infos .

=head2 Overlay

If you want use your own header  method you must use PLUGINHEADER parameter like this :
  in httpd.conf : perlsetvar lemonldappluginheader MyModule 

 Your module must accept  3 parameters : config (all the hash of config ) , dn and sting of role (profil) .

 Your module must provide the 'get' and 'forge'  methods .
 
 Those methods work with SENDHEADER parameter which tells what will be the  header (NONE value for no header)   

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

