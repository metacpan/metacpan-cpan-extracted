#
# $Id$
#
# email::send Brik
#
package Metabrik::Email::Send;
use strict;
use warnings;

use base qw(Metabrik::Network::Smtp);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable smtp) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         from => [ qw(from) ],
         to => [ qw(to) ],
         cc => [ qw(cc) ],
         bcc => [ qw(bcc) ],
         subject => [ qw(subject) ],
         server => [ qw(server) ],
         port => [ qw(port) ],
         hello => [ qw(hello) ],
         auth_mechanism => [ qw(none|GSSAPI) ],
         use_starttls => [ qw(0|1) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
      },
      attributes_default => {
         from => 'from@example.com',
         to => 'to@example.com',
         subject => 'My subject',
         server => 'localhost',
         port => 25,
         use_starttls => 0,
      },
      commands => {
         send => [ qw(email from|OPTIONAL to|OPTIONAL subject|OPTIONAL) ],
      },
      require_modules => {
         'DateTime' => [ ],
         'DateTime::Format::Mail' => [ ],
      },
   };
}

sub send {
   my $self = shift;
   my ($email, $from, $to, $subject) = @_;

   $from ||= $self->from;
   $to ||= $self->to;
   $subject ||= $self->subject;
   $self->brik_help_run_undef_arg('send', $email) or return;
   $self->brik_help_run_invalid_arg('send', $email, 'Email::Simple') or return;
   $self->brik_help_run_undef_arg('send', $from) or return;
   $self->brik_help_run_undef_arg('send', $to) or return;
   $self->brik_help_run_undef_arg('send', $subject) or return;

   my $cc = $self->cc;
   my $bcc = $self->bcc;

   my $ct = $email->header('Content-Type');
   my $cl = $email->header('Content-Length');
   my $ce = $email->header('Content-Transfer-Encoding');
   my $lc = $email->header('Lines');

   my $dt = DateTime->now;
   my $date = DateTime::Format::Mail->format_datetime($dt);

   $self->log->verbose("send: From [$from]");
   $self->log->verbose("send: To [$to]");
   $self->log->verbose("send: Date [$date]");
   $self->log->verbose("send: Subject [$subject]");
   #print "Content-Type [$ct]\n\n";
   #print $email->body,"\n";

   my $smtp = $self->open or return;

   $smtp->mail($from);
   $smtp->to($to);

   if (defined($cc)) {
      $smtp->cc($cc);
   }

   if (defined($bcc)) {
      $smtp->bcc($bcc);
   }

   $smtp->data;
   $smtp->datasend("Content-Type: $ct\r\n") if defined($ct);
   $smtp->datasend("Content-Length: $cl\r\n") if defined($cl);
   $smtp->datasend("Content-Transfer-Encoding: $ce\r\n") if defined($ce);
   $smtp->datasend("Lines: $lc\r\n") if defined($lc);
   $smtp->datasend("Date: $date\r\n");
   $smtp->datasend("From: $from\r\n");
   $smtp->datasend("To: $to\r\n");
   if (defined($cc)) {
      $smtp->datasend("Cc: $cc\r\n");
   }
   $smtp->datasend("Subject: $subject\r\n\r\n");
   $smtp->datasend($email->body);
   $smtp->dataend;

   $self->log->verbose("send: message sent");

   $self->close;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Email::Send - email::send Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
