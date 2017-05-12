package Lemonldap::Portal::Cda;
use strict;
use CGI;
use warnings;
use MIME::Base64;
our $VERSION = '0.02';

# Preloaded methods go here.
sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = bless {}, ref($class) || $class;
    $self->{controlUrlOrigin} = \&__controlUrlOrigin;
    my $mess = { 8 => 'CDA requested', };
    $self->{msg} = $mess;

    foreach ( keys %args ) {
        $self->{$_} = $args{$_};
    }
    $self->{controlCDA} = \&__controlCDA_MASTER;
    $self->{controlCDA} = \&__controlCDA_SLAVE if ( $self->{type} eq 'slave' );
    return $self;
}

sub __none {    #does ...nothing .. like me eg;

}
##------------------------------------------------------------------
## method controlUrlOrigin
## This method looks at param cgi 'urlc'  in order to determine if
## the request comes with  a vip url (redirection)  or for the menu
##------------------------------------------------------------------
sub __controlCDA_MASTER {
    my $self      = shift;
    my $operation = $self->{param}->{'op'};
    $self->{operation} = $operation;
    my $opx;
    $opx = 1 if ( ( $operation eq 'c' ) or ( $operation eq 't' ) );
    if ( defined($operation) and $opx == 1 ) {

        $self->{'message'} = $self->{msg}{8};
        $self->{'error'}   = 1;
        $self->{cda}       = 1;

    }
}

sub getAllRedirection {
    my $self = shift;
    return ( $self->{urlc}, $self->{urldc} );
}

sub message {
    my $self = shift;
    return ( $self->{message} );
}

sub error {
    my $self = shift;
    return ( $self->{error} );
}

sub __controlCDA_SLAVE {
    my $self      = shift;
    my $operation = $self->{param}->{'op'};
    $self->{operation} = $operation;
    if ( defined($operation) ) {
        $self->{session}   = $operation;
        $self->{'message'} = $self->{msg}{8};
        $self->{'error'}   = 1;
        $self->{cda}       = 1;

    }
}

sub __controlUrlOrigin {
    my $urldc;
    my $self = shift;
    my $urlc = $self->{param}->{'url'};
    if ( defined($urlc) ) {
        $urldc = decode_base64($urlc);

        #  $urldc =~ s#:\d+/#/#;   # Suppress  port number in  URL
        $urlc = encode_base64( $urldc, '' );
        $self->{'urlc'}  = $urlc;
        $self->{'urldc'} = $urldc;
    }
}

sub getSession {
    my $self = shift;
    return ( $self->{session} ) if $self->{session};
    return (0);

}

sub process {
    my $self = shift;
    my %args = @_;
    foreach ( keys %args ) {
        $self->{$_} = $args{$_};
    }
    &{ $self->{controlUrlOrigin} }($self);    # no error avaiable in this step
    &{ $self->{controlCDA} }($self);
    return ($self) if $self->{'error'};       ## it's not necessary to go next.

}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Lemonldap::Portal::Cda - Cross Domain Authentification Perl extension for Lemonldap SSO 

=head1 SYNOPSIS

  use Lemonldap::Portal::Cda;
  my $stack_user= Lemonldap::Portal::Cda->new(type=> 'master');

or  
  my $stack_user= Lemonldap::Portal::Cda->new(type=> 'slave');
 
=head1 DESCRIPTION


Lemonldap is a SSO system under GPL. 
Sometimes you have two or more domains (.bar.foo  and .bar.foo2)  
The CDA :Cross Domain Authentification manages and centralize all credentials on all domains .
CDA works with redirection in order to catch the credential cookie.

You may  use  an objet "master" domain with a "slave" domain .
All authentification needed  for the "slave" domain will be  redirected on the "master" domain
 
=head1 METHODS

=head2 new (type => 'master'|'slave');

=head2 process (param =>  \%params, 
                 bar  =>  foo );

The process method  alway return an  error '8' (message = 'CDA requested') .

The master CDA just do a redirection with the id_session in the params of url GET .
The slave CDA uses the id_session send by master for put on fly a cookie on slave domain. 

see  directory examples.

=head2  (url_encoded,url_decoded)  :  getAllRedirection  

return the initial request encoded in Base64 and plaintext url 

=head2 string : getSession      
   
return the id_session or false .

=head2 string : message() ;
 
  return the text of error 

=head2 int : error() ;
 
  return the  number of error 


=head1 SEE ALSO

Lemonldap(3), Lemonldap::Portal::Standard

http://lemonldap.sourceforge.net/

"Writing Apache Modules with Perl and C" by Lincoln Stein E<amp> Doug
MacEachern - O'REILLY

=over 1

=item Eric German, E<lt>germanlinux@yahoo.frE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Eric German E<amp> Xavier Guimard

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.


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



