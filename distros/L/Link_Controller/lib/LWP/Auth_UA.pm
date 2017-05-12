package LWP::Auth_UA;
$REVISION=q$Revision: 1.5 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );
use LWP::UserAgent;
@ISA=qw(LWP::UserAgent);

use strict;
use warnings;

=head1 NAME

LWP::Auth_UA.pm - a user agent which knows some authorisation tokens

=head1 SYNOPSIS

  use LWP::Auth_UA.pm
  credentials ( {
    my_realm => { uri_re => "https://myhost.example.com",
                  credential => "my_secret" }
  } );

  $ua = LWP::Auth_UA->new;
  $request = HTTP::Request->new('GET', 'file://localhost/etc/motd');
  $response = $ua->request($request);
  etc...

=head1 DESCRIPTION

This is a LWP user agent which is almost identical to the normal user
agent (LWP::UserAgent) except that if it reaches a situation where it
needs an authentication token then it will send a token which it has
stored.

Storing authentication tokens in a file is inherently a security
issue.  This risk may, however, not be much higher than the one that
you are currently carrying, so this can be useful.

This page describes how this works and how to ensure that the security
risks you are taking on are not greater than are acceptable to you.

As with the rest of LinkController, there is no warantee.  If you have
an environment in which this might be a problem, you should definitely
find someone to look over your installation and ensure that everything
is done correctly.  Of course, this is true of every piece of software
you install.

=head1 SECURITY RISKS

The fundamental security problem with this system is that the
authentication token must be stored somewhere where the program can
access it.  This is because link-controller has to send the actual
authentication token over the link to authenticate.  Since it's very
easy to monitor the inputs and outputs of a program, it's very easy to
monitor this password.

This applies even if we keep the password in some encrypted form,
since we then have to store the decryption key in the program which
can then be found and used to decrypt the key.

So there are only two possible defenses:

=over 4

=item *

make sure that the program data remains secret

=item *

make sure that the passwords the program has can't do any real damage

=back

We demand permissions on our files which protect against accidental
disclosure by encouraging the user to be more secure.

Making sure that the program can't do any damage is normally achieved
by giving it a dedicated account which has only read only privilages
and, preferably, can only use it's privilages from a specified system
which will be the host on which the link checking is run.

=head2 Accidental Sending of Tokens

Another authentication risk is that the system will send it to a
server which is trying to trick it.  This is again difficult to
protect against.  The only solution in this case is to ensure that the
regular expression used for limiting the URI matches only host names
which are under the control of the body responsible for handing out
the authentication token.

The security of this system is not of course perfect.  If we can
pretend to be the host that we are meant to send the authentication
token to then we will can trick the user agent into sending the token.
Remember that the hostname being used is the one in the URL we are
trying to examine, so the protection against this is having a secure
and correct DNS system and ensuring that we have a secure IP
connection to the end host.

=head2 Sending of Tokens over Insecure protocols

If an insecure protocol like HTTP is used for sending an
authentication token, then it is possible for someone to listen to the
transaction and record the token for later use.

The protection against this is to switch over to only using secure
protocols and hard wire the protocol name into the URI regular expression.

=cut

sub get_basic_credentials {
  my $self=shift;
  my $realm=shift;
  my $uri=shift;
  my $proxy=shift;
  my $credentials=$self->{"Auth_UA-credentials"};
  return undef unless defined $credentials;
  my $rec=$credentials->{$realm};
  return undef unless defined $rec;
  my $re=$rec->{uri_re};
  return undef unless $uri =~ m/$re/;
  return $rec->{credential}
}

sub auth_ua_credentials {
  my $self=shift;
  return $self->{"Auth_UA-credentials"} unless @_;
  my $cred=shift;
  $self->{"Auth_UA-credentials"} = $cred;
  return $cred;
}

sub delete_brain_dead_credentials {
  my $self=shift;
  my $cred=shift;
  $cred=$self->{"Auth_UA-credentials"} unless defined $cred;
  return undef unless defined $cred;
  foreach my $key ( keys %$cred ) {
    my $rec=$cred->{$key};
    my $re=$rec->{uri_re};
    ( "http://3133t3hax0rs.rhere.com" =~ m/$re/
      or "http://3133t3hax0rs.rhere.com/secretstuff/www.goodplace.com/" =~ m/$re/ )
	and do {
	  warn "Deleting credential with dangerous URI RE $re in Auth_UE for real $key";
	  delete $cred->{$key};
	};
  }
  return $cred;
}


#  sub aua_load_credentials {
#    my $self=shift;
#    my $file=$self->{Auth_UA-authfile};
#    open my $cred, $file;
#    while ( <$cred> ) {
#      my ($realm, $auth, $uri_re) = m/
#    };
#  }

#  sub aua_authfile {
#    my $self=shift;
#    return $self->{Auth_UA-authfile} unless @_;
#    $self->{Auth_UA-authfile} = shift;
#  }
