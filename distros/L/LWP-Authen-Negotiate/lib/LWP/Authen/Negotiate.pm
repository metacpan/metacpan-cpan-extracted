package LWP::Authen::Negotiate;

use strict;
use warnings;

use LWP::Debug;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use LWP::Authen::Negotiate ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.08';


use MIME::Base64 "2.12";
use GSSAPI 0.18;


sub authenticate
  {
    LWP::Debug::debug("authenticate() version $VERSION called");
    my ($class,$ua,$proxy,$auth_param,$response,$request,$arg,$size) = @_;

    my $uri = URI->new($request->uri);
    my $targethost = $request->uri()->host();

    my $otoken;
    my $status;
    TRY: {
        my ($target, $tname);

	# import the servername from LWP request
	# to a GSSAPI tokenname. Import can fail
	# in case of broken DNS or /etc/hosts
	# or missing Kerberosprincipal for target system
	#
        LWP::Debug::debug("target hostname $targethost");
        $status  = GSSAPI::Name->import(
                      $target,
                      join( '@', 'HTTP', $targethost ),
		      GSSAPI::OID::gss_nt_hostbased_service
		 );
	last TRY if  ( $status->major != GSS_S_COMPLETE );
        $status  = $target->display( $tname );
	last TRY if  ( $status->major != GSS_S_COMPLETE );

        LWP::Debug::debug("GSSAPI servicename $tname");
        my $auth_header = $proxy ? 'Proxy-Authorization'
	                :          'Authorization';

        my $itoken = q{};
        foreach ($response->header('WWW-Authenticate')) {
          last if /^Negotiate (.+)/ && ($itoken=decode_base64($1));
        }

	# Preload gss_init_security_context parameters
	# see RFC 2744 5.19. gss_init_sec_context
	#
        my $ctx = GSSAPI::Context->new();
        my $imech = GSSAPI::OID::gss_mech_krb5;

        my $iflags = GSS_C_REPLAY_FLAG;
	if ( $ENV{LWP_AUTHEN_NEGOTIATE_DELEGATE} ) {
	   $iflags =    $iflags
	              | GSS_C_MUTUAL_FLAG
		      | GSS_C_DELEG_FLAG;
	}
        my $bindings = GSS_C_NO_CHANNEL_BINDINGS;
        my $creds    = GSS_C_NO_CREDENTIAL;
        my $itime    = 0;
	#
	# let's go with init_security_context!
	#
	$status = $ctx->init( $creds, $target,
	                      $imech, $iflags, $itime , $bindings,$itoken,
	                      undef, $otoken, undef, undef);
        if  (    $status->major == GSS_S_COMPLETE
	      or $status->major == GSS_S_CONTINUE_NEEDED   ) {
            LWP::Debug::debug( 'successfull $ctx->init()');
	    my $referral = $request->clone;
	    $referral->header( $auth_header => "Negotiate ".encode_base64($otoken,""));
	    return $ua->request( $referral, $arg, $size, $response );
	}
    }
    #
    # this is the errorhandler,
    # the try block is normally leaved via return
    #
    LWP::Debug::debug( $status->generic_message());
    LWP::Debug::debug( $status->specific_message() );
    return $response;

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

LWP::Authen::Negotiate - GSSAPI based Authentication Plugin for LWP

=head1 SYNOPSIS





   #! /usr/bin/perl -w

   use strict;
   require LWP::UserAgent;

   # uncomment if you want see what is going wrong messages
   #
   #use LWP::Debug qw(+);

   my $ua = LWP::UserAgent->new;
   my $response = $ua->get('http://testwurst.grolmsnet.lan:8090/geheim/');
   if ($response->is_success) {
      print $response->content;  # or whatever
   }
   else {
       die $response->status_line;
   }


just install LWP::Authen::Negotiate, LWP uses it as authentication plugin.
Use your LWP::UserAgent Scripts as usual.
Authentication is done transparent based on your GSSAPI
installation (MIT Kerberos or Heimdal)

WWW-Negotiate Webservers are IIS or Apache with
mod_auth_kerb for example.

=head1 DESCRIPTION

To see what ist going on add

   use LWP::Debug qw(+);

to yor LWP using Scripts.

(e.g. too see what is going wrong with GSSAPI...)

=head1 DEBUGGING

To see what ist going on (and going wrong) add

   use LWP::Debug qw(+);

to yor LWP using Scripts.

(e.g. too see what is going wrong with GSSAPI...)

the output will look like this:

   LWP::UserAgent::new: ()
   LWP::UserAgent::request: ()
   LWP::UserAgent::send_request: GET http://testwurst.grolmsnet.lan:8090/geheim/
   LWP::UserAgent::_need_proxy: Not proxied
   LWP::Protocol::http::request: ()
   LWP::Protocol::collect: read 478 bytes
   LWP::UserAgent::request: Simple response: Unauthorized
   LWP::Authen::Negotiate::authenticate: authenticate() called
   LWP::Authen::Negotiate::authenticate: target hostname testwurst.grolmsnet.lan
   LWP::Authen::Negotiate::authenticate: GSSAPI servicename     HTTP/moerbsen.grolmsnet.lan@GROLMSNET.LAN
   LWP::Authen::Negotiate::authenticate:  Miscellaneous failure (see text)
   LWP::Authen::Negotiate::authenticate: open(/tmp/krb5cc_1000): file not found

In this case the credentials cache was empty.
Run kinit first ;-)

=head1 ENVIRONMENT

=over

=item LWP_AUTHEN_NEGOTIATE_DELEGATE

Define to enable ticket forwarding to webserver.

=back

=head1 SEE ALSO

=over

=item http://www.kerberosprotocols.org/index.php/Draft-brezak-spnego-http-03.txt

Description of WWW-Negotiate protol

=item http://modauthkerb.sourceforge.net/

the Kerberos and SPNEGO Authentication module for Apache mod_auth_kerb


=item http://perlgssapi.sourceforge.net/

Module Homepage

=item http://www.kerberosprotocols.org/index.php/Web

Sofware and APIs related to WWW-Negotiate

=item http://www.grolmsnet.de/kerbtut/

describes how to let mod_auth_kerb play together
with Internet Explorer and Windows2003 Server

=back


=head1 BUGS

As default Kerberos 5 is selected as GSSAPI mechanism.
a later veriosn will make that configureable.

=head1 AUTHOR

Achim Grolms, E<lt>achim@grolmsnet.deE<gt>

http://perlgssapi.sourceforge.net/

Thanks to

=over

=item Leif Johansson

who has conributed a lot of code from his
implementation of the module and
send a lot of input, ideas and feedback

=item Harald Joerg

helped with Kerberos knowledge and does testing on cygwin
against IIS and mod_auth_kerb

=item Christopher Odenbach

does a lot of testing on Linux and Solaris

=item Dax Kelson

does a lot of testing on Linux

=item Karsten Kuenne

helped with advice

=back




=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Achim Grolms <perl@grolmsnet.de>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
