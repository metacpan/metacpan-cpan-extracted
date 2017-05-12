package Email::Folder::Exchange::WebDAV;
use strict;

# vim: ft=perl fdm=marker ts=4 sw=4

our $VERSION = '1.10';

use base qw(Email::Folder);
use Email::Folder;
use URI;
use URI::Escape;
use LWP::UserAgent;

use Carp qw(carp croak);

sub _ua { # {{{
    my ($self, $ua) = @_;
    $self->{_ua} = $ua if @_ == 2;
    return $self->{_ua};
} # }}}

sub uri { # {{{
    my ($self, $uri) = @_;
    $self->{uri} = $uri if @_ == 2;
    return $self->{uri};
} # }}}

sub _login { # {{{
    my ($self, $uri, $username, $password) = @_;
    my $scheme = $uri->scheme;
    my $host = $uri->host;
    my $ua = $self->_ua;

    # login using FBA (forms-based authentication)
    my $auth_uri = $uri->clone;
    $auth_uri->path('exchweb/bin/auth/owaauth.dll');
    my $login_req = HTTP::Request->new(
        POST => $auth_uri->as_string,
    );
    $login_req->content_type('application/x-www-form-urlencoded');
    $login_req->content(
        'destination=' . uri_escape($uri->as_string) . 
        '&username=' . uri_escape($username) . 
        '&password=' . uri_escape($password)
    );

    my $login_res = $ua->request($login_req);
    croak $login_res->message if $login_res->code >= 400 and $login_res->code < 500;

    return 1;
} # }}}

sub new { # {{{
    my ($self, $class, $url, $username, $password) = ({}, @_);
    bless $self, $class;

    croak "URI required" unless $url;

    # create user agent
    my $ua = LWP::UserAgent->new( keep_alive => 1, cookie_jar => {} );
    $self->_ua($ua);

    # create uri object
    my $uri = URI->new($url);
    $self->uri($uri);

		# guess path
		if(! $uri->path || $uri->path =~ m{^/$}) {
		  my $path_user = $username;
			$path_user =~ s/.*\\//;

			$uri->path("/exchange/$path_user/Inbox");
		}


    # get credentials from url if specified
    my $credentials = $uri->userinfo;
    $uri->userinfo(undef);

    if($credentials && !($username || $password)) {
        ($username, $password) = split(/:/, uri_unescape($credentials), 2);
    }
    croak "Credentials required" unless $username;

    $self->_login($uri, $username, $password);
    
    return $self;
} # }}}

sub _message_urls { # {{{
    my ($self) = @_;
    return $self->{_message_urls} if $self->{_message_urls};

    my $req = HTTP::Request->new(
        SEARCH => $self->uri->as_string,
    );
    $req->content_type('text/xml');
    $req->header(Depth => 1);


    my $folder_path = $self->uri->path;
    $req->content(qq{
        <?xml version='1.0' ?>
        <a:searchrequest xmlns:a='DAV:'><a:sql>
        SELECT "DAV:ishidden"
          FROM scope('shallow traversal of "$folder_path"')
         WHERE "DAV:ishidden"=False AND "DAV:isfolder"=False
        </a:sql></a:searchrequest>
    });

    my $ua = $self->_ua;

    my @message_urls;
    my $buf = "";

    my $res = $ua->request($req, sub {
        my $chunk = shift;
        $buf .= $chunk;

        while($buf =~ m#<a:href>(.*?)</a:href>#g) {
            push @message_urls, $1;

        }
        $buf = substr($buf, (pos $buf || 0));
    });
    croak $res->message unless $res->code >= 200 and $res->code < 300;

    $self->{_message_urls} = \@message_urls;

    return $self->{_message_urls};
} # }}}

sub messages { # {{{
    my $self = shift;

    my @messages;
    while(my $message = $self->next_message) {
        push @messages, $message;
    }

    return @messages;
} # }}}
 
sub next_message { # {{{
    my $self = shift;
    my $message_url = shift @{ $self->_message_urls };
    return undef unless defined $message_url;

    my $req = HTTP::Request->new( GET => $message_url );
    $req->header(Translate => 'f');
    my $res = $self->_ua->request($req);
    croak $res->message unless $res->code >= 200 and $res->code < 300;

    return $self->bless_message($res->content);
} # }}}

sub _folder_urls { # {{{
    my ($self) = @_;
    return $self->{_folder_urls} if $self->{_folder_urls};

    my $req = HTTP::Request->new(
        SEARCH => $self->uri->as_string,
    );
    $req->content_type('text/xml');
    $req->header(Depth => 1);

    my $folder_path = $self->uri->path;
    $req->content(qq{
        <?xml version='1.0' ?>
        <a:searchrequest xmlns:a='DAV:'><a:sql>
        SELECT "DAV:ishidden"
          FROM scope('shallow traversal of "$folder_path"')
         WHERE "DAV:ishidden"=False AND "DAV:isfolder"=True
        </a:sql></a:searchrequest>
    });

    my $ua = $self->_ua;

    my @folder_urls;
    my $buf = "";

    my $res = $ua->request($req, sub {
        my $chunk = shift;
        $buf .= $chunk;

        while($buf =~ m#<a:href>(.*?)</a:href>#g) {
            push @folder_urls, $1;

        }

        $buf = substr($buf, (pos $buf || 0));
    });
    croak $res->message unless $res->code >= 200 and $res->code < 300;

    $self->{_folder_urls} = \@folder_urls;

    return $self->{_folder_urls};
} # }}}

sub folders { # {{{
    my $self = shift;

    my @folders;
    while(my $folder = $self->next_folder) {
        push @folders, $folder;
    }

    return @folders;
} # }}}

sub next_folder { # {{{
    my $self = shift;

    my $folder_url = shift @{ $self->_folder_urls };
    return unless defined $folder_url;

    my $folder = $self->clone;
    $folder->uri(URI->new($folder_url));

    return $folder;
} # }}}

sub clone { # {{{
    my $self = shift;

    my $clone = bless {
        uri => $self->uri->clone,
        _ua => $self->_ua->clone,
    }, ref $self;

    # copy cookie jar
    $clone->_ua->{cookie_jar} = $self->_ua->{cookie_jar};

    return $clone;
} # }}}

1;
__END__
=head1 NAME

Email::Folder::Exchange::WebDAV - Email::Folder access to exchange folders via WebDAV

=head1 SYNOPSIS

  use Email::Folder::Exchange::WebDAV;

  my $folder = Email::Folder::Exchange::WebDAV->new('http://owa.myorg.com/user/Inbox', 'user', 'password');

  for my $message ($folder->messages) {
    print "subject: " . $subject->header('Subject');
  }

  for my $folder ($folder->folders) {
    print "folder uri: " . $folder->uri->as_string;
    print " contains " . scalar($folder->messages) . " messages";
    print " contains " . scalar($folder->folders) . " folders";
  }


=head1 DESCRIPTION

Add access to Microsoft Exchange to L<Email::Folder>. Contains API enhancements
to allow folder browsing.

Utilizes FBA (forms-based authentication) to login. Therefore, OWA (Outlook Web
Access) must be installed and enabled on target server.

=head2 new($url, [$username, $password])

Create Email::Folder::Exchange::WebDAV object and login to OWA site.

=over

=item url

URL of the target folder, usually in the form of server/user/Inbox. May contain
authentication information, I.E.
'http://domain\user:password@owa.myorg.com/user/Inbox'.

=item username

Username to authenticate as. Generally in the form of 'domain\username'.
Overrides URL-supplied username if given.

=item password

Password to authenticate with. Overrides URL-supplied password.

=back

=head2 messages()

Return a list containing all of the messages in the folder. Can only be called
once as it drains the iterator.

=head2 next_message()

Return next message as L<Email::Simple> object from folder. Acts as iterator.
Returns undef at end of folder contents.

=head2 folders()

Return a list of L<Email::Folder::Exchange::WebDAV> objects contained within base
folder. Can only be called once as it drains the iterator.

=head2 next_folder()

Return next folder under base folder as L<Email::Folder::Exchange::WebDAV> object. Acts
as iterator. Returns undef at end of list.

=head2 uri()

Return L<URI> locator object for current folder.

=head1 CAVEATS

  Can't locate object method "new" via package "LWP::Protocol::https::Socket"

Install the Crypt::SSLeay module in order to support SSL URLs


=head1 SEE ALSO

L<Email::Folder::Exchange>, L<Email::Folder>, L<URI>, L<Email::Simple>, L<Crypt::SSLeay>

=head1 AUTHOR

Warren Smith <lt>wsmith@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Warren Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
