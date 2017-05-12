# -*-perl-*-
#
# Copyright (c) 1997-1998 Kevin Johnson <kjj@pobox.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: NNTP.pm,v 1.3 1998/04/05 17:21:53 kjj Exp $

require 5.00397;
package Mail::Folder::NNTP;
use strict;
use vars qw($VERSION @ISA);
use Net::NNTP;
use Mail::Header;

@ISA = qw(Mail::Folder);
$VERSION = '0.07';

Mail::Folder->register_type('news');

=head1 NAME

Mail::Folder::NNTP - An NNTP folder interface for Mail::Folder.

B<WARNING: This code is in alpha release.  Expect the interface to change.>

=head1 SYNOPSIS

C<use Mail::Folder::NNTP;>

=head1 DESCRIPTION

This module provides an interface to newsgroups accessible via the
NNTP protocol.

=cut

use Mail::Folder;
use Mail::Internet;
use Mail::Header;
use MIME::Head;

use Carp;

=head1 METHODS

=head2 open($foldername)

Populates the C<Mail::Folder> object with information about the folder.

The given foldername can be given one of two formats.  Either
C<news://NEWSHOST/NEWSGROUP> where C<NEWSHOST> is the nntp host and
C<NEWSGROUP> is the news group of interest, or C<#news:NEWSGROUP> in
which case the C<NNTPSERVER> environment variable is referenced to
determine the news host to connect to.

Please note that it opens an NNTP connection for each open NNTP
folder.

If no C<Timeout> option is specified, it defaults to a timeout of 120
seconds.

=over 2

=item * Call the superclass C<open> method.

=item * Make sure it is a valid NNTP foldername.

=item * Connect to the NNTP server referenced in $foldername.

=item * Perform an NNTP C<group> command to determine quantity and
range of articles available.

=item * Loop through available article numbers, retrieve and cache the
headers.

=item * Set C<current_message> to C<first_message>.

=back

=cut

sub open {
  my $self = shift;
  my $foldername = shift;

  return 0 unless $self->SUPER::open($foldername);

  is_valid_folder_format($foldername)
    or croak "$foldername isn't valid for an news folder";

  # these two extractions should never be fatal since is_valid_folder_format
  # should have detected any structural problems with the folder name
  $self->{NNTP_Host} = _extract_hostname($foldername)
    or croak "can't extract hostname from $foldername";
  $self->{NNTP_Newsgroup} = _extract_newsgroup_name($foldername)
    or croak "can't extract newsgroup from $foldername";

  my $timeout = $self->get_option('Timeout');
  $timeout ||= 120;		# default it if no Timeout option specified
  $self->{NNTP_Connection} = new Net::NNTP($self->{NNTP_Host},
					   Timeout => $timeout)
    or return 0;

  return 0 if (!defined($self->_absorb_folder($foldername)));

  $self->current_message($self->first_message);

  return 1;
}

=head2 close

Calls the superclass C<get_message> method and shuts down the
connection to the NNTP server.

=cut

sub close {
  my $self = shift;

  $self->{NNTP_Connection}->quit;
  return $self->SUPER::close;
}

=head2 sync

Currently a no-op and returns C<0>.

Eventually will expunge articles marked as seen, look for new
articles, update the C<.newsrc> (or equivalent) file, and return the
number of new articles found.

=cut

sub sync {
  my $self = shift;

  return 0;
}

=head2 pack

Since the association between article and article number is determined
by the server, this method is a no-op.

It return C<1>.

=cut

sub pack {
  my $self = shift;

  return 1;
}

=head2 get_message($msg_number)

Calls the superclass C<get_message> method.

Retrieves the contents of the news article pointed to by the given
C<$msg_number> into a B<Mail::Internet> object reference, caches the
header, marks the message as 'C<seen>', and returns the reference.

It returns C<undef> on failure.

=cut

sub get_message {
  my $self = shift;
  my $key = shift;

  return undef unless $self->SUPER::get_message($key);

  my $article = $self->{NNTP_Connection}->article($key)
    or return undef;

  my $mref = new Mail::Internet($article,
				Modify => 0)
    or return undef;

  my $href = $mref->head;
  $self->cache_header($key, $href);
  $self->add_label($key, 'seen');

  return $mref;
}

=head2 get_message_file($msg_number)

Not currently implemented.  Returns C<undef>.

=cut

sub get_message_file {
  my $self = shift;
  my $key = shift;

  return undef;
}

=head2 get_header($msg_number)

If the particular header has never been retrieved then C<get_header>
retrieves the header for the given news article from the news server,
converts it into a C<Mail::Header> object and returns a reference to
the object.

If the header has already been retrieved in a prior call to
C<get_header>, then the cached entry is returned.

It returns C<undef> on failure.

=cut

sub get_header {
  my $self = shift;
  my $key = shift;

  my $hdr = $self->SUPER::get_header($key);
  return $hdr if defined($hdr);

  # return undef unless ($self->SUPER::get_header($key));

  # return $self->{Messages}{$key}{Header} if ($self->{Messages}{$key}{Header});

  if (my $header = $self->{NNTP_Connection}->head($key)) {
    my $href = new Mail::Header($header, Modify => 0) or return undef;
    $self->cache_header($key, $href);
    return $href;
  }

  return undef;
}

=head2 append_message($mref)

Not currently implemented.  Returns C<0>.

=cut

sub append_message {
  my $self = shift;
  my $mref = shift;

  return 0;
}

=head2 update_message($msg_number, $mref)

Not currently implemented.  Returns C<0>.

=cut

sub update_message {
  my $self = shift;
  my $key = shift;
  my $mref = shift;

  return 0;
}

=head2 is_valid_folder_format($foldername)

Returns C<1> if the foldername either starts with the string
'C<news://>' or starts with the string 'C<#news:>' and the
C<NNTPSERVER> environment variable is set, otherwise return 0;

=cut

sub is_valid_folder_format($foldername) {
  my $foldername = shift;

  return (($foldername =~ /^news:\/\//) ||
	  (($foldername =~ /^\#news:/) && defined($ENV{NNTPSERVER})));
}

=head2 create($foldername)

Not currently implemented.  Returns C<0>.

=cut

sub create {
  my $self = shift;
  my $foldername = shift;

  return 0;
}
###############################################################################
sub _absorb_folder {
  my $self = shift;
  my $foldername = shift;

  my $qty_new_articles = 0;

  my @group = $self->{NNTP_Connection}->group($self->{NNTP_Newsgroup})
    or return undef;

  for my $msg ($group[1] .. $group[2]) {
    next if defined($self->{Messages}{$msg});
    $self->remember_message($msg);
    $self->get_header($msg);
    $qty_new_articles++;
  }

  return $qty_new_articles;
}

sub _extract_hostname {
  my $foldername = shift;

  return $1 if ($foldername =~ /^news:\/\/([^\/]+)\//);
  return $ENV{NNTPSERVER} if ($foldername =~ /^\#news:/);
  return undef;
}

sub _extract_newsgroup_name {
  my $foldername = shift;

  return $1 if ($foldername =~ /^news:\/\/[^\/]+\/(.+)$/);
  return $1 if ($foldername =~ /^\#news:(.*)$/);
  return undef;
}
###############################################################################

=head1 AUTHOR

Kevin Johnson E<lt>F<kjj@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1997-1998 Kevin Johnson <kjj@pobox.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
