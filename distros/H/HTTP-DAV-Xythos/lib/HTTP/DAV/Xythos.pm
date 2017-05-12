package HTTP::DAV::Xythos;
BEGIN {
  $HTTP::DAV::Xythos::VERSION = '1.101180';
}

use strict;
use warnings;

use base qw(HTTP::DAV);

my  @xythos_args = qw(ticket);

sub new
{
    my ($class, %args) = @_;

    # save the original args 
    my %orig_args = %args;

    for ( @xythos_args ) {
        # make sure that we have the Xythos args
        die "arg '$_' is required\n" unless defined $orig_args{$_};

        # remove the Xythos args from the call to the HTTP::DAV constructor
        delete $args{$_};
    }

    # create the HTTP::DAV object
    my $self = $class->SUPER::new( %args );

    # login to the Xythos ticket
    if ( $orig_args{ticket} ) {
        unless ( $self->_login_ticket(%orig_args) ) {
            die "failed to login\n";;
        }
    }
    
    return $self;
}

sub _login_ticket {
    my ($self, %args) = @_;

    my ($xythos_uri, $webui_uri) = $args{ticket} =~ m#^(https?://.*?)(/.*)/#;
    return $self->err( '', "unable to parse ticket\n" ) unless ( $xythos_uri and $webui_uri );

    # add the cookie jar to the user agent
    $self->get_user_agent()->cookie_jar({});

    # access the ticket
    my $req = HTTP::Request->new(GET => $args{ticket});
    my $res = $self->get_user_agent()->request($req);

    # authenticate to ticket
    if ( defined $args{pass} and length $args{pass} ) {

        return $self->err( '', "Unable to connect to ticket URL: ".$res->status_line."\n" ) unless ($res->is_success);

        my ($server2) = $res->content =~ m#($webui_uri/.*?)'#;
        return $self->err( '', "Problem logging in to ticket (invalid ticket url, or invalid password?)\n") unless ( $server2 );

        $server2 = "$xythos_uri$server2";

        $req = HTTP::Request->new(POST => $server2);
        $req->content_type('application/x-www-form-urlencoded');
        $req->content("password=$args{pass}&action=invitationalGroup&subaction=joinGroup");
        $res = $self->get_user_agent()->request($req);

        return $self->err( '', "Unable to login to ticket (wrong password?)\n") unless ( $res->code eq "302" );

        # page redirects
        $req = HTTP::Request->new(GET => $res->headers->{location});
        $res = $self->get_user_agent()->request($req);
        return $self->err( '', "Unable to login to ticket (wrong password?)\n") unless ( $res->code eq "302" );
    }
    else {
        return $self->err( '', "Unable to access ticket (is the ticket URL valid?)\n") unless ( $res->code eq "302" );

        # page redirects
        $req = HTTP::Request->new(GET => $res->headers->{location});
        $res = $self->get_user_agent()->request($req);
        return $self->err( '', "Unable to login to ticket (wrong password?)\n") unless ( $res->code eq "302" );
    }

    # process the final redirect
    $req = HTTP::Request->new(GET => $res->headers->{location});
    $res = $self->get_user_agent()->request($req);
    return $self->err( '', "Unable to redirect: ".$res->status_line."\n") unless ($res->is_success);

    # gather information needed for upload
    my ($posturi) = $res->content =~ m#id="filesForm" action="(.*?)"#;
    return $self->err( '', "unable to upload (is the ticket to a file instead of a directory?)\n") unless ( $posturi );
    ($self->{webdav_url}) = $posturi =~ m#$webui_uri(.*)#; 
    return $self->err( '', "failed to parse information needed for upload\n") unless ( $self->{webdav_url} );

    # set the webdav_url variable
    $self->{webdav_url} = $xythos_uri.$self->{webdav_url};

    return 1;
}
1;
__END__

=head1 NAME

HTTP::DAV::Xythos - Subclass of HTTP::DAV which adds support for Xythos Ticket authentication.

=head1 VERSION

version 1.101180

=head1 SYNOPSIS

  use HTTP::DAV::Xythos;

  my $d = HTTP::DAV::Xythos->new (
      ticket  => "https://xythos.wisc.edu/xythoswfs/webui/_xy-32583927_2-y_4hFtiGEt",
      pass    => "foobar",  
  );

  # $d->{webdav_url} contains the full URL to the WebDAV location where the
  # Ticket is rooted (e.g. https://xythos.wisc.edu/buckybadger/ftw/images)
  my $location = $d->{webdav_url};

  # Use L<HTTP::DAV> as you would normally 
  # (you do not need to authenticate with a user/pass)

  # Example - recursively download files
  my $d = HTTP::DAV::Xythos->new (
      ticket => $ticket,
      pass   => $pass,
  );
  get($d, $d->{webdav_url}, '/tmp');
  sub get {
      my ($d, $url, $dir) = @_;
      $d->open( -url => $url );
      my $r = $d->propfind( -url=>$url, -depth=>1);
      if ( $r->is_collection ) {
          $url =~ s/(.*[^\/])$/$1\//;
          $dir =~ s/(.*[^\/])$/$1\//;
          mkdir $dir unless ( -d $dir );
          my $rl = $r->get_resourcelist;
          for ( $rl->get_resources ) {
              my $rel_uri = $_->get_property('rel_uri');
              get($d, $url.$rel_uri, $dir.$rel_uri);
          }
      }
      else {
          $d->get( -url=>$url, -to=>$dir);
          print "$url ---> $dir\n";
      }
  }

=head1 DESCRIPTION

Xythos is an enterprise web-based document management server that supports WebDAV.  

Tickets are a feature of Xythos that allow users to share content with 
only a URL and an optional password.  You cannot authenticate directly to Xythos'
WebDAV locations using a Ticket - you must first login using the web interface.

HTTP::DAV::Xythos implements the login process so that you can effectively login to a 
Xythos WebDAV server using a Ticket for authentication.

Once you create the HTTP::DAV::Xythos object, passing in the ticket (and optional pass) 
to the contructor, you are successfully authenticated to the WebDAV server
and can proceed to interact with the server using all of the functionality 
that is built into HTTP::DAV.

HTTP::DAV::Xythos adds session cookie functionality to the LWP user agent, since
cookies are required for maintaining authorized (Ticket) access to the Xythos WebDAV server.

=head1 SUPPORT

This module is not an official Xythos service.

=head1 AUTHOR

  Jesse Thompson
  CPAN ID: MODAUTHOR
  Division of Information Technology, University of Wisconsin-Madison
  jesse.thompson@doit.wisc.edu
  http://www.doit.wisc.edu

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<http://xythos.com>

L<HTTP::DAV>

=cut