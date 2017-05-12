package Lemonldap::Federation::Shibboleth;

use 5.008005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lemonldap::Federation::Shibboleth ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.0.1' ;


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lemonldap::Federation::Shibboleth - Perl extension for lemonldap websso and Shibboleth IDP 

=head1 SYNOPSIS

  use Lemonldap::Federation::ShibbolethRequestMap ;
  my $requestmap = Lemonldap::Federation::ShibbolethRequestMap->new( xml_host => $extrait_de_xml ,
                                  xml_application=> $extrait_de_xml2 ,
                                  uri => $full_uri , ) ;
  my $re= $requestmap->application_id;
  my  $redirection = $requestmap->redirection ;


=head1 DESCRIPTION

There are two pieces of code :

=over 4

=item *
 Lemonldap::Federation::SplitURI

=item *
Lemonldap::Federation::ShibbolethRequestMap

=back

First (Lemonldap::Federation::SplitURI) is used in order to split  uri in scheme , host , port and path . 
 
 eg :   https://sp.example.org/secure/admin/index.html must be splited into 



=over 4

=item *
 https 

=item *
 443

=item *
 sp.example.org

=item *
 secure

=item *
 admin

=item *
 index.html

=back

The second compoment is the RequestMap . It job is to find and return  the applicationID for URI. 
For this it uses an XML configuration file like this : 
    
   <Host  scheme="https" port="443"  name="sp.example.org" >
		<Path name="secure" 
                      authType="shiboleth" 
                      requireSession="true"
                      exportAssertion="true">
                 <Path name="admin" applicationId ="foo-admin" />
                </Path>

  </Host>

=head1 METHODS:

=head2  Constructor 
  $requestmap = Lemonldap::Federation::ShibbolethRequestMap->new( xml_host => $extrait_de_xml ,
                                  xml_application=> $extrait_de_xml2 ,
                                  uri => $full_uri , ) ;
 
  with:


=over 4

=item *
  xml_host : XML  piece of <RequestMapProvider>..</RequestMapProvider> 

=item *
  xml_application : XML piece  of <Applications> ..</Applications> 

=back 

=head2 Application_id 

    return the application id for an URI .
  
=head2  redirection
    
    return entire line of redirection to IPD  :

   eg :
 
https://idp.exemple.org/sso?target=http%3A%2F%2Fauthen.demo.net%2Fshibe&shire=http%3A%2F%2Fsp.example.org%2Fshire&providerId=http%3A%2F%2Fsp.example.org

   see GenericSHIB.pm in example directory


=head1 SEE ALSO

 https://spaces.internet2.edu/display/SHIB/WebHome
 http://shibboleth.internet2.edu/
  

=head1 AUTHOR

eric German, E<lt>germanlinux@yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by lemonasso

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
