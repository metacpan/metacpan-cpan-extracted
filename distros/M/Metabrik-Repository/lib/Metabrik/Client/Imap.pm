#
# $Id: Imap.pm,v 246044148483 2017/03/18 14:13:18 gomor $
#
# client::imap Brik
#
package Metabrik::Client::Imap;
use strict;
use warnings;

use base qw(Metabrik::String::Uri);

sub brik_properties {
   return {
      revision => '$Revision: 246044148483 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(imap_uri) ],
         as_array => [ qw(0|1) ],
         strip_crlf => [ qw(0|1) ],
         _imap => [ qw(INTERNAL) ],
         _id => [ qw(INTERNAL) ],
         _count => [ qw(INTERNAL) ],
      },
      attributes_default => {
         as_array => 0,
         strip_crlf => 1,
      },
      commands => {
         open => [ qw(imap_uri|OPTIONAL) ],
         reset_current => [ ],
         total => [ ],
         read => [ ],
         read_next => [ ],
         read_next_with_subject => [ qw(subject) ],
         read_next_with_an_attachment => [ qw(regex|OPTIONAL) ],
         parse => [ qw(message) ],
         save_attachments => [ qw(message) ],
         close => [ ],
      },
      require_modules => {
         'Metabrik::Email::Message' => [ ],
         'Net::IMAP::Simple' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_set_undef_arg('input', $input) or return;

   my $parsed = $self->SUPER::parse($input) or return;
   my $host = $parsed->{host};
   my $port = $parsed->{port};
   my $user = $parsed->{user};
   my $password = $parsed->{password};
   my $path = $parsed->{path} || 'INBOX';
   $path =~ s{^/*}{};

   if (! defined($user) || ! defined($password) || ! defined($host)) {
      return $self->log->error("open: invalid uri [$input] ".
         "missing connection information");
   }

   my $use_ssl = $self->is_imaps_scheme($parsed) ? 1 : 0;

   my $imap = Net::IMAP::Simple->new("$host:$port", use_ssl => $use_ssl);
   if (! defined($imap)) {
      return $self->log->error("open: can't connect to IMAP: $Net::IMAP::Simple::errstr");
   }

   my $r = $imap->login($user, $password);
   if (! defined($r)) {
      return $self->log->error("open: login failed [".$imap->errstr."]");
   }

   my $count = $imap->select($path);
   $self->_count($count);
   $self->_id($count);

   return $self->_imap($imap);
}

sub reset_current {
   my $self = shift;

   $self->_id($self->_count);

   return 1;
}

sub total {
   my $self = shift;

   my $imap = $self->_imap;
   $self->brik_help_run_undef_arg('open', $imap) or return;

   return $self->_count;
}

sub read_next {
   my $self = shift;

   my $imap = $self->_imap;
   $self->brik_help_run_undef_arg('open', $imap) or return;

   my $current = $self->_id;

   my $lines = $imap->get($current--);

   $self->_id($current);

   if ($self->as_array) {
      if ($self->strip_crlf) {
         for (@$lines) {
            s{[\r\n]*$}{};
         }
      }
      return [ @$lines ];  # unbless it
   }

   return join('', @$lines);
}

sub read_next_with_subject {
   my $self = shift;
   my ($subject) = @_;

   my $imap = $self->_imap;
   $self->brik_help_run_undef_arg('open', $imap) or return;
   $self->brik_help_run_undef_arg('read_next_with_subject', $subject) or return;

   my $total = $self->total;

   for (1..$total) {
      my $next = $self->read_next or return;
      my $message = $self->parse($next) or return;
      my $headers = $message->[0];

      if ($headers->{Subject} =~ m{$subject}i) {
         return $next;
      }
   }

   return $self->log->error("read_next_with_subject: no message found with that subject ".
      "in last $total messages.");
}

sub read_next_with_an_attachment {
   my $self = shift;
   my ($regex) = @_;

   my $imap = $self->_imap;
   $self->brik_help_run_undef_arg('open', $imap) or return;
   $regex ||= qr/^.*$/;

   my $total = $self->total;

   for (1..$total) {
      my $next = $self->read_next or return;
      my $message = $self->parse($next) or return;
      my $headers = $message->[0];

      for my $part (@$message) {
         if (exists($part->{filename}) && length($part->{filename})
         &&  $part->{filename} =~ $regex) {
            return $next;
         }
      }
   }

   return $self->log->error("read_next_with_an_attachment: no message found with ".
      "an attachment in last $total messages.");
}

sub parse {
   my $self = shift;
   my ($message) = @_;

   $self->brik_help_run_undef_arg('parse', $message) or return;

   my $em = Metabrik::Email::Message->new_from_brik_init($self) or return;

   return $em->parse($message);
}

sub save_attachments {
   my $self = shift;
   my ($message) = @_;

   $self->brik_help_run_undef_arg('save_attachments', $message) or return;

   my $em = Metabrik::Email::Message->new_from_brik_init($self) or return;
   $em->datadir($self->datadir);

   return $em->save_attachments($message);
}

sub close {
   my $self = shift;

   my $imap = $self->_imap;
   if (defined($imap)) {
      $imap->quit;
      $self->_imap(undef);
      $self->_id(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Imap - client::imap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
