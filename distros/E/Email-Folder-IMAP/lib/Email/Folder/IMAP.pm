use strict;
use warnings;
package Email::Folder::IMAP;
# ABSTRACT: Email::Folder Access to IMAP Folders
$Email::Folder::IMAP::VERSION = '1.105';
use parent qw[Email::Folder::Reader];
use Net::IMAP::Simple 0.95; # :port support
use URI;

sub _imap_class {
  'Net::IMAP::Simple';
}

sub _uri {
  my $self = shift;
  return $self->{_uri} ||= URI->new($self->{_file});
}

sub _server {
  my $self = shift;
  return $self->{_server} if $self->{_server};

  my $uri = $self->_uri;

  my $host   = $uri->host_port;
  my $server = $self->_imap_class->new($host);

  my ($user, $pass) = @{$self}{qw[username password]};
  ($user, $pass) = split ':', $uri->userinfo, 2 unless $user;

  $server->login($user, $pass) if $user;

  my $box = substr $uri->path, 1;
  $server->select($box) if $box;

  $self->{_next} = 1;
  return $self->{_server} = $server;
}

sub next_message {
  my $self    = shift;
  my $message = $self->_server->get($self->{_next});
  if ($message) {
    ++$self->{_next};
    return join '', @{$message};
  }
  $self->{_next} = 1;
  return;
}

1;

#pod =head1 SYNOPSIS
#pod
#pod   use Email::Folder;
#pod   use Email::FolderType::Net;
#pod   
#pod   my $folder = Email::Folder->new('imap://example.com'); # read INBOX
#pod   
#pod   print $_->header('Subject') for $folder->messages;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This software adds IMAP functionality to L<Email::Folder|Email::Folder>.
#pod Its interface is identical to the other
#pod L<Email::Folder::Reader|Email::Folder::Reader> subclasses.
#pod
#pod =head2 Parameters
#pod
#pod C<username> and C<password> parameters may be sent to C<new()>. If
#pod used, they override any user info passed in the connection URI.
#pod
#pod =head2 Folder Specification
#pod
#pod Folders are specified using a simplified form of the IMAP URL Scheme
#pod detailed in RFC 2192. Not all of that specification applies. Here
#pod are a few examples.
#pod
#pod Selecting the INBOX.
#pod
#pod   imap://foo.com
#pod
#pod Selecting the INBOX using URI based authentication. Remember that the
#pod C<username> and C<password> parameters passed to C<new()> will override
#pod anything set in the URI.
#pod
#pod   imap://user:pass@foo.com
#pod
#pod Selecting the p5p list.
#pod
#pod   imap://foo.com/perl/perl5-porters
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Email::Folder>,
#pod L<Email::Folder::Reader>,
#pod L<Email::FolderType::Net>,
#pod L<URI::imap>,
#pod L<Net::IMAP::Simple>.

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::Folder::IMAP - Email::Folder Access to IMAP Folders

=head1 VERSION

version 1.105

=head1 SYNOPSIS

  use Email::Folder;
  use Email::FolderType::Net;
  
  my $folder = Email::Folder->new('imap://example.com'); # read INBOX
  
  print $_->header('Subject') for $folder->messages;

=head1 DESCRIPTION

This software adds IMAP functionality to L<Email::Folder|Email::Folder>.
Its interface is identical to the other
L<Email::Folder::Reader|Email::Folder::Reader> subclasses.

=head2 Parameters

C<username> and C<password> parameters may be sent to C<new()>. If
used, they override any user info passed in the connection URI.

=head2 Folder Specification

Folders are specified using a simplified form of the IMAP URL Scheme
detailed in RFC 2192. Not all of that specification applies. Here
are a few examples.

Selecting the INBOX.

  imap://foo.com

Selecting the INBOX using URI based authentication. Remember that the
C<username> and C<password> parameters passed to C<new()> will override
anything set in the URI.

  imap://user:pass@foo.com

Selecting the p5p list.

  imap://foo.com/perl/perl5-porters

=head1 SEE ALSO

L<Email::Folder>,
L<Email::Folder::Reader>,
L<Email::FolderType::Net>,
L<URI::imap>,
L<Net::IMAP::Simple>.

=head1 AUTHOR

Casey West <casey@geeknest.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Casey West <casey@geeknest.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
